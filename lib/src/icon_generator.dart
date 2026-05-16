import 'dart:io' show Directory, File, stdout, stderr;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'cli_args.dart';
import 'concurrency.dart';
import 'i18n/strings.dart';
import 'image_ops.dart';
import 'platform_specs.dart';
import 'scanner.dart';
import 'size_detector.dart';

/// 為 Flutter 專案生成各平台的圖示與啟動圖片。
///
/// 使用多 isolate 並行處理圖片生成以提升速度。
Future<void> runGenerate(CliArgs args, AppStrings s) async {
  final hasFg = args.iconSourcePath != null;
  final hasBg = args.backgroundSourcePath != null;

  if (!hasFg && !hasBg) {
    stdout.writeln(s.noSourceImages);
    return;
  }

  // 載入來源圖片
  img.Image? fgImage;
  img.Image? bgImage;

  if (hasFg) {
    final bytes = await File(args.iconSourcePath!).readAsBytes();
    fgImage = img.decodeImage(bytes);
    if (fgImage == null) {
      stderr.writeln(s.decodeImageFailed(args.iconSourcePath!));
      return;
    }
  }

  if (hasBg) {
    final bytes = await File(args.backgroundSourcePath!).readAsBytes();
    bgImage = img.decodeImage(bytes);
    if (bgImage == null) {
      stderr.writeln(s.decodeImageFailed(args.backgroundSourcePath!));
      return;
    }
  }

  // 預編碼來源圖片為 PNG 位元組，供 isolate 傳遞使用
  final fgBytes = fgImage != null
      ? Uint8List.fromList(img.encodePng(fgImage))
      : null;
  final bgBytes = bgImage != null
      ? Uint8List.fromList(img.encodePng(bgImage))
      : null;

  // 建立信號量以限制並行度
  final semaphore = Semaphore(args.jobs);

  // ── 收集所有平台的 PNG 工作項 ──
  final pngTasks = <_PngTask>[];
  final icoTaskDefs = <_IcoTaskDef>[];
  final icnsTaskDefs = <_IcnsTaskDef>[];

  for (final platform in args.platforms) {
    final spec = getPlatformSpec(platform);
    if (spec == null) continue;

    stdout.writeln(s.procesandoPlatforma(platform));

    final outputs = _scanAndBuildOutputs(
      args.flutterProjectPath, platform, spec, s,
    );

    // 收集 PNG 輸出工作項
    for (final output in outputs) {
      // 判斷是否需要套用圓角：非 iOS 平台、非啟動圖片
      final bool aplicarRadio = platform != 'ios' && !output.isSplash;
      final double? radio = aplicarRadio
          ? calculateRadius(args.radius, output.width, output.height)
          : null;

      // 計算前景邊距
      final minDim =
          output.width < output.height ? output.width : output.height;
      final margin = (output.layer == ImageLayer.merged &&
              (bgImage != null || spec.requiresOpaqueIcons))
          ? _calcularMargen(args, minDim)
          : 0.0;

      // 檢查略過條件
      if (output.layer == ImageLayer.foreground && fgImage == null) {
        stdout.writeln('  ${s.skippingLayerFg(normalizarRuta(output.relativePath))}');
        continue;
      }
      if (output.layer == ImageLayer.background && bgImage == null) {
        stdout.writeln('  ${s.skippingLayerBg(normalizarRuta(output.relativePath))}');
        continue;
      }
      if (output.layer == ImageLayer.merged &&
          fgImage == null &&
          bgImage == null) {
        continue;
      }

      pngTasks.add(_PngTask(
        output: output,
        whiteBase: spec.requiresOpaqueIcons,
        projectPath: args.flutterProjectPath,
        radius: radio,
        margin: margin,
      ));
    }

    // 收集 ICO 工作項
    for (final entry in spec.icoOutputs.entries) {
      if (fgImage == null && bgImage == null) continue;
      icoTaskDefs.add(_IcoTaskDef(
        icoPath: entry.key,
        icoSpecs: entry.value,
        projectPath: args.flutterProjectPath,
        whiteBase: spec.requiresOpaqueIcons,
        radius: args.radius,
        marginValue: args.marginValue,
        marginIsPercent: args.marginIsPercent,
      ));
    }

    // 收集 ICNS 工作項
    for (final entry in spec.icnsOutputs.entries) {
      if (fgImage == null && bgImage == null) continue;
      icnsTaskDefs.add(_IcnsTaskDef(
        icnsPath: entry.key,
        icnsSpecs: entry.value,
        projectPath: args.flutterProjectPath,
        radius: args.radius,
        marginValue: args.marginValue,
        marginIsPercent: args.marginIsPercent,
      ));
    }
  }

  // ── 並行處理所有 PNG 工作項 ──
  var totalGenerated = 0;
  if (pngTasks.isNotEmpty) {
    final futures = pngTasks.map((task) => semaphore.withPermit(
          () => _procesarPngTask(task, fgBytes, bgBytes, s),
        ));
    final results = await Future.wait(futures);
    for (final r in results) {
      if (r) totalGenerated++;
    }
  }

  // ── 並行處理 ICO ──
  if (icoTaskDefs.isNotEmpty) {
    final futures = icoTaskDefs.map((def) => semaphore.withPermit(
          () => _generarIcoParalelo(
            def.icoPath, def.icoSpecs, fgBytes, bgBytes,
            def.projectPath, s,
            whiteBase: def.whiteBase,
            radius: def.radius,
            marginValue: def.marginValue,
            marginIsPercent: def.marginIsPercent,
          ),
        ));
    final results = await Future.wait(futures);
    for (final r in results) {
      if (r) totalGenerated++;
    }
  }

  // ── 並行處理 ICNS ──
  if (icnsTaskDefs.isNotEmpty) {
    final futures = icnsTaskDefs.map((def) => semaphore.withPermit(
          () => _generarIcnsParalelo(
            def.icnsPath, def.icnsSpecs, fgBytes, bgBytes,
            def.projectPath, s,
            radius: def.radius,
            marginValue: def.marginValue,
            marginIsPercent: def.marginIsPercent,
          ),
        ));
    final results = await Future.wait(futures);
    for (final r in results) {
      if (r) totalGenerated++;
    }
  }

  stdout.writeln(s.generacionCompletada(totalGenerated));
}

// ─── 內部資料結構 ─────────────────────────────────────────────

class _PngTask {
  final IconOutput output;
  final bool whiteBase;
  final String projectPath;
  final double? radius;
  final double margin;

  _PngTask({
    required this.output,
    required this.whiteBase,
    required this.projectPath,
    required this.radius,
    required this.margin,
  });
}

class _IcoTaskDef {
  final String icoPath;
  final List<IconOutput> icoSpecs;
  final String projectPath;
  final bool whiteBase;
  final double? radius;
  final double? marginValue;
  final bool marginIsPercent;

  _IcoTaskDef({
    required this.icoPath,
    required this.icoSpecs,
    required this.projectPath,
    required this.whiteBase,
    required this.radius,
    required this.marginValue,
    required this.marginIsPercent,
  });
}

class _IcnsTaskDef {
  final String icnsPath;
  final List<IconOutput> icnsSpecs;
  final String projectPath;
  final double? radius;
  final double? marginValue;
  final bool marginIsPercent;

  _IcnsTaskDef({
    required this.icnsPath,
    required this.icnsSpecs,
    required this.projectPath,
    required this.radius,
    required this.marginValue,
    required this.marginIsPercent,
  });
}

// ─── PNG 工作項處理 ───────────────────────────────────────────

/// 在 isolate 中生成單張 PNG 並寫入檔案。
Future<bool> _procesarPngTask(
  _PngTask task,
  Uint8List? fgBytes,
  Uint8List? bgBytes,
  AppStrings s,
) async {
  final output = task.output;

  final pngBytes = await generatePngInIsolate(
    fgBytes: fgBytes,
    bgBytes: bgBytes,
    targetW: output.width,
    targetH: output.height,
    layer: _layerToString(output.layer),
    whiteBase: task.whiteBase,
    radius: task.radius,
    margin: task.margin,
  );

  if (pngBytes.isEmpty) {
    stdout.writeln(
        '  ${s.writeError(normalizarRuta(output.relativePath), '生成失敗')}');
    return false;
  }

  // 寫入檔案
  final filePath = p.join(task.projectPath, output.relativePath);
  try {
    final oldFile = File(filePath);
    final oldSize = oldFile.existsSync() ? oldFile.lengthSync() : null;

    final dir = Directory(p.dirname(filePath));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    await File(filePath).writeAsBytes(pngBytes);

    final newSize = File(filePath).lengthSync();
    final tipo = _layerTypeString(output.layer, task.whiteBase, s);
    final oldSizeStr = oldSize != null ? _formatSize(oldSize) : s.newFileLabel;

    stdout.writeln(s.generandoIconoDetalle(
      normalizarRuta(output.relativePath),
      output.width,
      output.height,
      tipo,
      oldSizeStr,
      _formatSize(newSize),
    ));
    return true;
  } catch (e) {
    stderr.writeln(s.writeError(normalizarRuta(filePath), e.toString()));
    return false;
  }
}

/// 將 [ImageLayer] 轉為字串標識，供 isolate 傳遞。
String _layerToString(ImageLayer layer) {
  switch (layer) {
    case ImageLayer.foreground:
      return 'foreground';
    case ImageLayer.background:
      return 'background';
    case ImageLayer.merged:
      return 'merged';
  }
}

// ─── ICO 並行生成 ─────────────────────────────────────────────

/// ICO 條目類型：PNG 格式（32-bit）或 BMP 格式（指定色深）。
enum _IcoEntryType { png32, bmp8, bmp4 }

/// 單一 ICO 條目的內部表示。
class _IcoEntry {
  final int width;
  final int height;
  final _IcoEntryType type;
  final Uint8List data;
  const _IcoEntry(this.width, this.height, this.type, this.data);
}

/// 並行生成多尺寸、多色深的 ICO 檔案。
Future<bool> _generarIcoParalelo(
  String icoPath,
  List<IconOutput> icoSpecs,
  Uint8List? fgBytes,
  Uint8List? bgBytes,
  String projectPath,
  AppStrings s, {
  bool whiteBase = false,
  double? radius,
  double? marginValue,
  bool marginIsPercent = false,
}) async {
  if (fgBytes == null && bgBytes == null) return false;

  // 收集所有獨特尺寸
  final uniqueSizes = <int>{};
  for (final spec in icoSpecs) {
    uniqueSizes.add(spec.width);
  }
  final sortedSizes = uniqueSizes.toList()..sort();

  // 並行生成所有尺寸的圖片
  final sizeImages = <int, img.Image>{};
  final sizeFutures = sortedSizes.map((size) async {
    final minDim = size;
    final marginForSize = (bgBytes != null || whiteBase)
        ? _calcularMargenRaw(marginValue, marginIsPercent, minDim)
        : 0.0;
    final pngBytes = await generateImageForSizeInIsolate(
      fgBytes: fgBytes,
      bgBytes: bgBytes,
      size: size,
      whiteBase: whiteBase,
      radius: radius,
      margin: marginForSize,
    );
    if (pngBytes.isNotEmpty) {
      final decoded = img.decodeImage(pngBytes);
      if (decoded != null) {
        sizeImages[size] = decoded;
      }
    }
  });

  await Future.wait(sizeFutures);

  // 建立 ICO 條目
  final entries = <_IcoEntry>[];
  for (final spec in icoSpecs) {
    final size = spec.width;
    final image = sizeImages[size];
    if (image == null) continue;

    entries.add(_IcoEntry(
        size, size, _IcoEntryType.png32,
        Uint8List.fromList(img.encodePng(image))));

    if (size <= 48) {
      final bmp8 = _encodeBmpIcoEntry(image, 8);
      if (bmp8 != null) {
        entries.add(_IcoEntry(size, size, _IcoEntryType.bmp8, bmp8));
      }
    }

    if (size <= 32) {
      final bmp4 = _encodeBmpIcoEntry(image, 4);
      if (bmp4 != null) {
        entries.add(_IcoEntry(size, size, _IcoEntryType.bmp4, bmp4));
      }
    }
  }

  if (entries.isEmpty) return false;

  final icoBytes = _encodeIcoCustom(entries);
  final filePath = p.join(projectPath, icoPath);

  try {
    final oldFile = File(filePath);
    final oldSize = oldFile.existsSync() ? oldFile.lengthSync() : null;

    final dir = Directory(p.dirname(filePath));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    await File(filePath).writeAsBytes(icoBytes);

    final newSize = File(filePath).lengthSync();
    final tipo = _layerTypeString(icoSpecs.first.layer, whiteBase, s);
    final oldSizeStr = oldSize != null ? _formatSize(oldSize) : s.newFileLabel;

    stdout.writeln(s.generandoIcoDetalle(
        normalizarRuta(icoPath), tipo, oldSizeStr, _formatSize(newSize)));
    return true;
  } catch (e) {
    stderr.writeln(s.writeError(normalizarRuta(filePath), e.toString()));
    return false;
  }
}

// ─── ICNS 並行生成 ────────────────────────────────────────────

/// ICNS 圖示類型代碼（4 字元 OSType）。
class _IcnsType {
  final String code;
  final int size;
  const _IcnsType(this.code, this.size);
}

/// 標準 ICNS 圖示類型代碼對應表（PNG 格式）。
const _icnsTypes = [
  _IcnsType('icp4', 16),
  _IcnsType('icp5', 32),
  _IcnsType('icp6', 64),
  _IcnsType('ic07', 128),
  _IcnsType('ic08', 256),
  _IcnsType('ic09', 512),
  _IcnsType('ic10', 1024),
];

/// 並行生成多尺寸 ICNS 檔案。
Future<bool> _generarIcnsParalelo(
  String icnsPath,
  List<IconOutput> icnsSpecs,
  Uint8List? fgBytes,
  Uint8List? bgBytes,
  String projectPath,
  AppStrings s, {
  double? radius,
  double? marginValue,
  bool marginIsPercent = false,
}) async {
  if (fgBytes == null && bgBytes == null) return false;

  // 收集需要生成的尺寸
  final neededTypes = <_IcnsType>[];
  for (final type in _icnsTypes) {
    final hasSize = icnsSpecs.any((s) => s.width == type.size);
    if (hasSize) {
      neededTypes.add(type);
    }
  }

  if (neededTypes.isEmpty) return false;

  // 並行生成所有尺寸的圖片
  final entries = <_IcnsType, Uint8List>{};
  final futures = neededTypes.map((type) async {
    final marginForSize = (bgBytes != null)
        ? _calcularMargenRaw(marginValue, marginIsPercent, type.size)
        : 0.0;
    final pngBytes = await generateImageForSizeInIsolate(
      fgBytes: fgBytes,
      bgBytes: bgBytes,
      size: type.size,
      whiteBase: false,
      radius: radius,
      margin: marginForSize,
    );
    if (pngBytes.isNotEmpty) {
      entries[type] = pngBytes;
    }
  });

  await Future.wait(futures);

  if (entries.isEmpty) return false;

  final icnsBytes = _encodeIcns(entries);
  final filePath = p.join(projectPath, icnsPath);

  try {
    final oldFile = File(filePath);
    final oldSize = oldFile.existsSync() ? oldFile.lengthSync() : null;

    final dir = Directory(p.dirname(filePath));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    await File(filePath).writeAsBytes(icnsBytes);

    final newSize = File(filePath).lengthSync();
    final tipo = _layerTypeString(icnsSpecs.first.layer, false, s);
    final oldSizeStr = oldSize != null ? _formatSize(oldSize) : s.newFileLabel;

    stdout.writeln(s.generandoIcnsDetalle(
        normalizarRuta(icnsPath), tipo, oldSizeStr, _formatSize(newSize)));
    return true;
  } catch (e) {
    stderr.writeln(s.writeError(normalizarRuta(filePath), e.toString()));
    return false;
  }
}

// ─── 檔案掃描與輸出建構 ────────────────────────────────────────

/// 掃描目標目錄中的現有圖片檔案，並與預定義規格合併為最終的輸出清單。
List<IconOutput> _scanAndBuildOutputs(
  String projectPath,
  String platform,
  PlatformSpec spec,
  AppStrings s,
) {
  final outputMap = <String, IconOutput>{};

  for (final o in [...spec.iconOutputs, ...spec.splashOutputs]) {
    outputMap[o.relativePath] = o;
  }

  final scanResult = scanPlatform(projectPath, platform, s);

  for (final sf in scanResult.icons) {
    _updateOutputFromScanned(outputMap, sf, projectPath, platform, false);
  }

  for (final sf in scanResult.splash) {
    _updateOutputFromScanned(outputMap, sf, projectPath, platform, true);
  }

  return outputMap.values.toList();
}

void _updateOutputFromScanned(
  Map<String, IconOutput> outputMap,
  ScannedFile sf,
  String projectPath,
  String platform,
  bool isSplash,
) {
  final relativePath = p.relative(sf.file.path, from: projectPath);

  final ext = p.extension(relativePath).toLowerCase();
  if (ext == '.ico' || ext == '.icns') return;

  ({int width, int height})? size;
  final detected = detectTargetSize(sf.file.path, platform);
  if (detected != null) {
    size = detected;
  } else {
    final imgSize = _getFileImageSize(sf.file.path);
    if (imgSize != null) {
      size = imgSize;
    }
  }

  if (size == null) return;

  final layer = _tagToLayer(sf.tag);

  outputMap[relativePath] = IconOutput(
    relativePath: relativePath,
    width: size.width,
    height: size.height,
    layer: layer,
    isSplash: isSplash,
  );
}

ImageLayer _tagToLayer(String? tag) {
  if (tag == null) return ImageLayer.merged;
  const fgValues = {'前景', 'Foreground'};
  const bgValues = {'背景', 'Background'};
  if (fgValues.contains(tag)) return ImageLayer.foreground;
  if (bgValues.contains(tag)) return ImageLayer.background;
  return ImageLayer.merged;
}

({int width, int height})? _getFileImageSize(String filePath) {
  try {
    final bytes = File(filePath).readAsBytesSync();
    final image = img.decodeImage(bytes);
    if (image != null) {
      return (width: image.width, height: image.height);
    }
  } catch (_) {}
  return null;
}

// ─── ICO 編碼器 ───────────────────────────────────────────────

Uint8List _encodeIcoCustom(List<_IcoEntry> entries) {
  final count = entries.length;
  final offsets = <int>[];
  var currentOffset = 6 + 16 * count;
  for (final entry in entries) {
    offsets.add(currentOffset);
    currentOffset += entry.data.length;
  }

  final buffer = BytesBuilder();

  buffer.add(_uint16LE(0));
  buffer.add(_uint16LE(1));
  buffer.add(_uint16LE(count));

  for (var i = 0; i < count; i++) {
    final entry = entries[i];
    final w = entry.width >= 256 ? 0 : entry.width;
    final h = entry.height >= 256 ? 0 : entry.height;
    int bpp;
    int colors;
    switch (entry.type) {
      case _IcoEntryType.png32:
        bpp = 32;
        colors = 0;
      case _IcoEntryType.bmp8:
        bpp = 8;
        colors = 256;
      case _IcoEntryType.bmp4:
        bpp = 4;
        colors = 16;
    }
    buffer.addByte(w & 0xFF);
    buffer.addByte(h & 0xFF);
    buffer.addByte(colors & 0xFF);
    buffer.addByte(0);
    buffer.add(_uint16LE(1));
    buffer.add(_uint16LE(bpp));
    buffer.add(_uint32LE(entry.data.length));
    buffer.add(_uint32LE(offsets[i]));
  }

  for (final entry in entries) {
    buffer.add(entry.data);
  }

  return buffer.takeBytes();
}

Uint8List? _encodeBmpIcoEntry(img.Image image, int bpp) {
  if (bpp != 4 && bpp != 8) return null;
  final w = image.width;
  final h = image.height;
  if (w < 1 || h < 1) return null;
  final paletteSize = 1 << bpp;

  final palette = _buildPalette(image, paletteSize);
  if (palette.isEmpty) return null;

  final xorRowBytes = ((w * bpp + 31) ~/ 32) * 4;
  final andRowBytes = ((w + 31) ~/ 32) * 4;

  final header = BytesBuilder();
  header.add(_uint32LE(40));
  header.add(_int32LE(w));
  header.add(_int32LE(h * 2));
  header.add(_uint16LE(1));
  header.add(_uint16LE(bpp));
  header.add(_uint32LE(0));
  header.add(_uint32LE(0));
  header.add(_int32LE(0));
  header.add(_int32LE(0));
  header.add(_uint32LE(0));
  header.add(_uint32LE(0));

  final paletteBytes = BytesBuilder();
  for (final c in palette) {
    paletteBytes.addByte(c.b);
    paletteBytes.addByte(c.g);
    paletteBytes.addByte(c.r);
    paletteBytes.addByte(0);
  }
  for (var i = palette.length; i < paletteSize; i++) {
    paletteBytes.addByte(0);
    paletteBytes.addByte(0);
    paletteBytes.addByte(0);
    paletteBytes.addByte(0);
  }

  final xorData = BytesBuilder();

  final colorToIndex = <int, int>{};
  for (var i = 0; i < palette.length; i++) {
    final pc = palette[i];
    final key = (pc.r << 16) | (pc.g << 8) | pc.b;
    colorToIndex[key] = i;
  }

  for (var y = h - 1; y >= 0; y--) {
    final xorRow = BytesBuilder();
    var bitBuf = 0;
    var bitCount = 0;

    for (var x = 0; x < w; x++) {
      final pixel = image.getPixel(x, y);
      final a = pixel.a.toInt();
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      if (a < 128) {
        final blackIndex = _findNearestPaletteIndex(0, 0, 0, palette);
        if (bpp == 8) {
          xorRow.addByte(blackIndex);
        } else {
          bitBuf = (bitBuf << 4) | (blackIndex & 0x0F);
          bitCount += 4;
          if (bitCount == 8) {
            xorRow.addByte(bitBuf);
            bitBuf = 0;
            bitCount = 0;
          }
        }
      } else {
        final index = _findNearestPaletteIndex(r, g, b, palette);
        if (bpp == 8) {
          xorRow.addByte(index);
        } else {
          bitBuf = (bitBuf << 4) | (index & 0x0F);
          bitCount += 4;
          if (bitCount == 8) {
            xorRow.addByte(bitBuf);
            bitBuf = 0;
            bitCount = 0;
          }
        }
      }
    }

    if (bpp == 4 && bitCount > 0) {
      bitBuf <<= (8 - bitCount);
      xorRow.addByte(bitBuf);
    }

    var xorRowOut = xorRow.takeBytes();
    while (xorRowOut.length < xorRowBytes) {
      xorRowOut = Uint8List.fromList([...xorRowOut, 0]);
    }
    xorData.add(xorRowOut);
  }

  final andRows = _buildAndMask(image, w, andRowBytes);

  return Uint8List.fromList([
    ...header.takeBytes(),
    ...paletteBytes.takeBytes(),
    ...xorData.takeBytes(),
    ...andRows,
  ]);
}

Uint8List _buildAndMask(img.Image image, int w, int andRowBytes) {
  final h = image.height;
  final andData = BytesBuilder();

  for (var y = h - 1; y >= 0; y--) {
    final row = BytesBuilder();
    var bitBuf = 0;
    var bitCount = 0;
    for (var x = 0; x < w; x++) {
      final pixel = image.getPixel(x, y);
      final a = pixel.a.toInt();
      bitBuf = (bitBuf << 1) | (a < 128 ? 1 : 0);
      bitCount++;
      if (bitCount == 8) {
        row.addByte(bitBuf);
        bitBuf = 0;
        bitCount = 0;
      }
    }
    if (bitCount > 0) {
      bitBuf <<= (8 - bitCount);
      row.addByte(bitBuf);
    }
    var rowOut = row.takeBytes();
    while (rowOut.length < andRowBytes) {
      rowOut = Uint8List.fromList([...rowOut, 0]);
    }
    andData.add(rowOut);
  }
  return andData.takeBytes();
}

class _PaletteColor {
  final int r, g, b;
  const _PaletteColor(this.r, this.g, this.b);
}

List<_PaletteColor> _buildPalette(img.Image image, int maxColors) {
  final histogram = <int, int>{};
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      if (pixel.a.toInt() < 128) continue;
      final key =
          (pixel.r.toInt() << 16) | (pixel.g.toInt() << 8) | pixel.b.toInt();
      histogram[key] = (histogram[key] ?? 0) + 1;
    }
  }
  if (histogram.isEmpty) {
    return List.generate(maxColors, (i) {
      final v = (i * 255) ~/ (maxColors - 1 > 0 ? maxColors - 1 : 1);
      return _PaletteColor(v, v, v);
    });
  }

  final sorted = histogram.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final selected = sorted.take(maxColors).toList();

  return selected.map((e) {
    final key = e.key;
    return _PaletteColor((key >> 16) & 0xFF, (key >> 8) & 0xFF, key & 0xFF);
  }).toList();
}

int _findNearestPaletteIndex(
    int r, int g, int b, List<_PaletteColor> palette) {
  var bestIndex = 0;
  var bestDist = 0x7FFFFFFF;
  for (var i = 0; i < palette.length; i++) {
    final pc = palette[i];
    final dr = r - pc.r;
    final dg = g - pc.g;
    final db = b - pc.b;
    final dist = dr * dr + dg * dg + db * db;
    if (dist < bestDist) {
      bestDist = dist;
      bestIndex = i;
    }
  }
  return bestIndex;
}

// ─── ICNS 編碼器 ──────────────────────────────────────────────

Uint8List _encodeIcns(Map<_IcnsType, Uint8List> entries) {
  var totalLength = 8;
  for (final entry in entries.entries) {
    totalLength += 8 + entry.value.length;
  }

  final buffer = BytesBuilder();

  buffer.add('icns'.codeUnits);
  buffer.add(_uint32BE(totalLength));

  for (final entry in entries.entries) {
    final type = entry.key.code;
    final data = entry.value;
    buffer.add(type.codeUnits);
    buffer.add(_uint32BE(8 + data.length));
    buffer.add(data);
  }

  return buffer.takeBytes();
}

// ─── 位元組輔助函式 ──────────────────────────────────────────

List<int> _uint16LE(int v) => [v & 0xFF, (v >> 8) & 0xFF];
List<int> _uint32LE(int v) =>
    [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF];
List<int> _int32LE(int v) => _uint32LE(v);
List<int> _uint32BE(int v) =>
    [(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF];

// ─── 工具函式 ─────────────────────────────────────────────────

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _layerTypeString(ImageLayer layer, bool whiteBase, AppStrings s) {
  if (whiteBase && layer == ImageLayer.merged) {
    return s.layerTypeWhiteBase;
  }
  switch (layer) {
    case ImageLayer.foreground:
      return s.layerTypeForeground;
    case ImageLayer.background:
      return s.layerTypeBackground;
    case ImageLayer.merged:
      return s.layerTypeMerged;
  }
}

const _defaultMarginRatio = 0.10;

double _calcularMargen(CliArgs args, int minDim) {
  if (args.marginValue == null) {
    return minDim * _defaultMarginRatio;
  }
  if (args.marginIsPercent) {
    return minDim * args.marginValue! / 100.0;
  }
  return args.marginValue!;
}

double _calcularMargenRaw(double? value, bool isPercent, int minDim) {
  if (value == null) return minDim * _defaultMarginRatio;
  if (isPercent) return minDim * value / 100.0;
  return value;
}
