import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'cli_args.dart';
import 'i18n/strings.dart';
import 'platform_specs.dart';
import 'scanner.dart';
import 'size_detector.dart';

/// 為 Flutter 專案生成各平台的圖示與啟動圖片。
///
/// [args] 為使用者提供的命令列參數。
/// [s] 為多語言字串集合。
Future<void> runGenerate(CliArgs args, AppStrings s) async {
  final hasFg = args.iconSourcePath != null;
  final hasBg = args.backgroundSourcePath != null;

  if (!hasFg && !hasBg) {
    print(s.noSourceImages);
    return;
  }

  // 載入來源圖片
  img.Image? fgImage;
  img.Image? bgImage;

  if (hasFg) {
    final bytes = await File(args.iconSourcePath!).readAsBytes();
    fgImage = img.decodeImage(bytes);
    if (fgImage == null) {
      print(s.decodeImageFailed(args.iconSourcePath!));
      return;
    }
  }

  if (hasBg) {
    final bytes = await File(args.backgroundSourcePath!).readAsBytes();
    bgImage = img.decodeImage(bytes);
    if (bgImage == null) {
      print(s.decodeImageFailed(args.backgroundSourcePath!));
      return;
    }
  }

  // 記錄成功生成的檔案數量
  var totalGenerated = 0;

  // 遍歷每個目標平台進行生成
  for (final platform in args.platforms) {
    final spec = getPlatformSpec(platform);
    if (spec == null) continue;

    print(s.procesandoPlatforma(platform));

    // 掃描現有檔案並建立輸出清單（合併預定義規格與掃描結果）
    final outputs = _scanAndBuildOutputs(
      args.flutterProjectPath, platform, spec, s,
    );

    // 處理一般 PNG 輸出
    for (final output in outputs) {
      // 判斷是否需要套用圓角：非 iOS 平台、非啟動圖片
      final bool aplicarRadio = platform != 'ios' && !output.isSplash;
      final double? radio = aplicarRadio
          ? _calcularRadio(args.radius, output.width, output.height)
          : null;

      // 計算前景邊距：僅合併圖層且（有背景圖或白底）時套用
      // 獨立前景圖層（如 Android 自適應前景）不套用邊距
      final minDim = output.width < output.height ? output.width : output.height;
      final margin = (output.layer == ImageLayer.merged &&
              (bgImage != null || spec.requiresOpaqueIcons))
          ? _calcularMargen(args, minDim)
          : 0.0;

      final generated = await _generarYGuardar(
        output, fgImage, bgImage, args.flutterProjectPath, s,
        whiteBase: spec.requiresOpaqueIcons,
        radio: radio,
        margin: margin,
      );
      if (generated) totalGenerated++;
    }

    // 處理多尺寸 ICO 輸出
    for (final entry in spec.icoOutputs.entries) {
      // ICO 僅用於非啟動畫面，且非 iOS 平台，直接傳遞 radius 參數
      final generated = await _generarIco(
        entry.key, entry.value, fgImage, bgImage,
        args.flutterProjectPath, s,
        whiteBase: spec.requiresOpaqueIcons,
        radius: args.radius,
        marginValue: args.marginValue,
        marginIsPercent: args.marginIsPercent,
      );
      if (generated) totalGenerated++;
    }

    // 處理多尺寸 ICNS 輸出
    for (final entry in spec.icnsOutputs.entries) {
      final generated = await _generarIcns(
        entry.key, entry.value, fgImage, bgImage,
        args.flutterProjectPath, s,
        radius: args.radius,
        marginValue: args.marginValue,
        marginIsPercent: args.marginIsPercent,
      );
      if (generated) totalGenerated++;
    }
  }

  print(s.generacionCompletada(totalGenerated));
}

/// 掃描目標目錄中的現有圖片檔案，並與預定義規格合併為最終的輸出清單。
///
/// 對於掃描到的檔案：優先從檔名/目錄結構偵測目標尺寸，
/// 若無法偵測則讀取檔案本身的像素尺寸作為目標。
///
/// 對於預定義規格中存在但尚未存在的檔案，保留預定義尺寸作為兜底。
List<IconOutput> _scanAndBuildOutputs(
  String projectPath,
  String platform,
  PlatformSpec spec,
  AppStrings s,
) {
  // 以相對路徑為 key 的輸出清單，用於去重
  final outputMap = <String, IconOutput>{};

  // 第一步：加入預定義規格中的所有輸出（兜底）
  for (final o in [...spec.iconOutputs, ...spec.splashOutputs]) {
    outputMap[o.relativePath] = o;
  }

  // 第二步：掃描現有檔案，更新/補充輸出清單
  final scanResult = scanPlatform(projectPath, platform, s);

  // 處理掃描到的圖示檔案（非啟動畫面）
  for (final sf in scanResult.icons) {
    _updateOutputFromScanned(outputMap, sf, projectPath, platform, false);
  }

  // 處理掃描到的啟動畫面檔案
  for (final sf in scanResult.splash) {
    _updateOutputFromScanned(outputMap, sf, projectPath, platform, true);
  }

  return outputMap.values.toList();
}

/// 根據單一掃描到的檔案更新輸出清單中的項目。
void _updateOutputFromScanned(
  Map<String, IconOutput> outputMap,
  ScannedFile sf,
  String projectPath,
  String platform,
  bool isSplash,
) {
  final relativePath = p.relative(sf.file.path, from: projectPath);

  // 跳過 .ico 與 .icns 檔案，這些格式由專屬編碼器處理，不應建立 PNG 輸出
  final ext = p.extension(relativePath).toLowerCase();
  if (ext == '.ico' || ext == '.icns') return;

  // 動態偵測目標尺寸
  ({int width, int height})? size;
  final detected = detectTargetSize(sf.file.path, platform);
  if (detected != null) {
    size = detected;
  } else {
    // 無法從檔名/路徑偵測，讀取原始圖片尺寸
    final imgSize = _getFileImageSize(sf.file.path);
    if (imgSize != null) {
      size = imgSize;
    }
  }

  if (size == null) return; // 無法取得尺寸則略過

  // 決定圖層類型
  final layer = _tagToLayer(sf.tag);

  // 更新或新增輸出（以相對路徑去重）
  outputMap[relativePath] = IconOutput(
    relativePath: relativePath,
    width: size.width,
    height: size.height,
    layer: layer,
    isSplash: isSplash,
  );
}

/// 將掃描器的標籤轉換為 [ImageLayer] 列舉值。
ImageLayer _tagToLayer(String? tag) {
  if (tag == null) return ImageLayer.merged;
  // 掃描器標籤為 i18n 字串，需比對所有可能語言的「前景」與「背景」
  const fgValues = {'前景', 'Foreground'};
  const bgValues = {'背景', 'Background'};
  if (fgValues.contains(tag)) return ImageLayer.foreground;
  if (bgValues.contains(tag)) return ImageLayer.background;
  return ImageLayer.merged;
}

/// 讀取圖片檔案的實際像素尺寸作為備用尺寸偵測。
({int width, int height})? _getFileImageSize(String filePath) {
  try {
    final bytes = File(filePath).readAsBytesSync();
    final image = img.decodeImage(bytes);
    if (image != null) {
      return (width: image.width, height: image.height);
    }
  } catch (_) {
    // 讀取失敗則略過
  }
  return null;
}

/// 根據圖層類型生成單一圖片並寫入檔案。
///
/// 回傳 `true` 表示成功生成，`false` 表示略過或失敗。
Future<bool> _generarYGuardar(
  IconOutput output,
  img.Image? fgImage,
  img.Image? bgImage,
  String projectPath,
  AppStrings s, {
  bool whiteBase = false,
  double? radio,
  double margin = 0,
}) async {
  // 根據圖層類型決定需要哪些來源圖片
  // 合併圖層只需至少一張圖片即可，前景/背景圖層則嚴格要求對應圖片
  if (output.layer == ImageLayer.foreground && fgImage == null) {
    print('  ${s.skippingLayerFg(normalizarRuta(output.relativePath))}');
    return false;
  }
  if (output.layer == ImageLayer.background && bgImage == null) {
    print('  ${s.skippingLayerBg(normalizarRuta(output.relativePath))}');
    return false;
  }
  // 合併圖層：若兩張都沒有則略過
  if (output.layer == ImageLayer.merged && fgImage == null && bgImage == null) {
    return false;
  }

  // 生成圖片
  final img.Image generated;
  switch (output.layer) {
    case ImageLayer.foreground:
      generated = _escalarProporcional(fgImage!, output.width, output.height, margin: margin);
    case ImageLayer.background:
      generated = _estirar(bgImage!, output.width, output.height);
    case ImageLayer.merged:
      generated = _fusionar(
        fgImage, bgImage, output.width, output.height,
        whiteBase: whiteBase,
        margin: margin,
      );
  }

  // 套用圓角（若有指定）
  final img.Image finalImage = _aplicarBordeRedondo(generated, radio);

  // 寫入檔案
  final filePath = p.join(projectPath, output.relativePath);
  try {
    // 偵測舊檔案大小（若存在）
    final oldFile = File(filePath);
    final oldSize = oldFile.existsSync() ? oldFile.lengthSync() : null;

    final dir = Directory(p.dirname(filePath));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    await File(filePath).writeAsBytes(img.encodePng(finalImage));

    // 新檔案大小
    final newSize = File(filePath).lengthSync();

    // 圖層類型顯示文字
    final tipo = _layerTypeString(output.layer, whiteBase, s);

    // 舊檔案大小顯示：若有舊檔案則顯示大小，否則顯示「新檔案」標籤
    final oldSizeStr = oldSize != null ? _formatSize(oldSize) : s.newFileLabel;

    print(s.generandoIconoDetalle(
      normalizarRuta(output.relativePath), output.width, output.height,
      tipo, oldSizeStr, _formatSize(newSize),
    ));
    return true;
  } catch (e) {
    print(s.writeError(normalizarRuta(filePath), e.toString()));
    return false;
  }
}

/// 為指定尺寸產生圖層合成後的圖片。
///
/// 統一的圖片生成邏輯，供 ICO、ICNS 等多格式共用。
img.Image _generarImagenParaTamanio(
  int width, int height,
  img.Image? fgImage, img.Image? bgImage, {
  bool whiteBase = false,
  double? radius,
  double margin = 0,
}) {
  final img.Image sized;
  if (fgImage != null && bgImage != null) {
    sized = _fusionar(fgImage, bgImage, width, height,
        whiteBase: whiteBase, margin: margin);
  } else if (fgImage != null) {
    if (whiteBase) {
      sized = _fusionar(fgImage, null, width, height,
          whiteBase: true, margin: margin);
    } else {
      sized = _escalarProporcional(fgImage, width, height, margin: margin);
    }
  } else {
    if (whiteBase) {
      sized = _fusionar(null, bgImage, width, height, whiteBase: true);
    } else {
      sized = _estirar(bgImage!, width, height);
    }
  }
  final radioForSize = _calcularRadio(radius, width, height);
  return _aplicarBordeRedondo(sized, radioForSize);
}

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

/// 生成多尺寸、多色深的 ICO 檔案。
///
/// 包含 Windows 標準所有尺寸（16～256），並且對小尺寸額外
/// 產生 8-bit（≤48px）與 4-bit（≤32px）色深版本。
Future<bool> _generarIco(
  String icoPath,
  List<IconOutput> icoSpecs,
  img.Image? fgImage,
  img.Image? bgImage,
  String projectPath,
  AppStrings s, {
  bool whiteBase = false,
  double? radius,
  double? marginValue,
  bool marginIsPercent = false,
}) async {
  if (fgImage == null && bgImage == null) return false;

  final entries = <_IcoEntry>[];
  final generatedImages = <int, img.Image>{};

  // 輔助：取得或生成指定尺寸的合成圖片（含緩存）
  img.Image _getOrGenerate(int size) {
    return generatedImages.putIfAbsent(size, () {
      final minDim = size;
      final marginForSize = (bgImage != null || whiteBase)
          ? _calcularMargenRaw(marginValue, marginIsPercent, minDim)
          : 0.0;
      return _generarImagenParaTamanio(
        size, size, fgImage, bgImage,
        whiteBase: whiteBase, radius: radius, margin: marginForSize,
      );
    });
  }

  for (final spec in icoSpecs) {
    final size = spec.width;
    final image = _getOrGenerate(size);

    // 32-bit PNG 條目（所有尺寸）
    entries.add(_IcoEntry(size, size, _IcoEntryType.png32, Uint8List.fromList(img.encodePng(image))));

    // 8-bit BMP 條目（≤48px）
    if (size <= 48) {
      final bmp8 = _encodeBmpIcoEntry(image, 8);
      if (bmp8 != null) {
        entries.add(_IcoEntry(size, size, _IcoEntryType.bmp8, bmp8));
      }
    }

    // 4-bit BMP 條目（≤32px）
    if (size <= 32) {
      final bmp4 = _encodeBmpIcoEntry(image, 4);
      if (bmp4 != null) {
        entries.add(_IcoEntry(size, size, _IcoEntryType.bmp4, bmp4));
      }
    }
  }

  // 使用自訂編碼器將所有條目寫入 ICO 檔案
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

    print(s.generandoIcoDetalle(normalizarRuta(icoPath), tipo, oldSizeStr, _formatSize(newSize)));
    return true;
  } catch (e) {
    print(s.writeError(normalizarRuta(filePath), e.toString()));
    return false;
  }
}

/// 自訂 ICO 編碼器：支援混合 PNG（32-bit）與 BMP（8-bit / 4-bit）條目。
Uint8List _encodeIcoCustom(List<_IcoEntry> entries) {
  final count = entries.length;
  // 計算各條目的偏移量
  final offsets = <int>[];
  var currentOffset = 6 + 16 * count; // 檔頭 + 目錄
  for (final entry in entries) {
    offsets.add(currentOffset);
    currentOffset += entry.data.length;
  }

  final buffer = BytesBuilder();

  // ICO 檔頭
  buffer.add(_uint16LE(0));   // reserved
  buffer.add(_uint16LE(1));   // type: ICO
  buffer.add(_uint16LE(count));

  // ICO 目錄條目
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
    buffer.addByte(0); // reserved
    buffer.add(_uint16LE(1));   // planes
    buffer.add(_uint16LE(bpp));
    buffer.add(_uint32LE(entry.data.length));
    buffer.add(_uint32LE(offsets[i]));
  }

  // 條目資料
  for (final entry in entries) {
    buffer.add(entry.data);
  }

  return buffer.takeBytes();
}

/// 將 RGBA 圖片編碼為 BMP DIB 格式，用於 ICO 內的 BMP 條目。
///
/// [bpp] 必須為 4 或 8。包含調色盤、XOR 像素資料與 AND 遮罩。
Uint8List? _encodeBmpIcoEntry(img.Image image, int bpp) {
  if (bpp != 4 && bpp != 8) return null;
  final w = image.width;
  final h = image.height;
  if (w < 1 || h < 1) return null;
  final paletteSize = 1 << bpp; // 16 or 256

  // 建構調色盤：採用頻率最高的 N 色
  final palette = _buildPalette(image, paletteSize);
  if (palette.isEmpty) return null;

  // 計算每行位元組數（對齊 4-byte 邊界）
  final xorRowBytes = ((w * bpp + 31) ~/ 32) * 4;
  final andRowBytes = ((w + 31) ~/ 32) * 4;

  // BITMAPINFOHEADER: biHeight = h * 2（上半 XOR，下半 AND）
  final header = BytesBuilder();
  header.add(_uint32LE(40));        // biSize
  header.add(_int32LE(w));
  header.add(_int32LE(h * 2));      // biHeight（含 XOR + AND）
  header.add(_uint16LE(1));         // biPlanes
  header.add(_uint16LE(bpp));       // biBitCount
  header.add(_uint32LE(0));         // biCompression: BI_RGB
  header.add(_uint32LE(0));         // biSizeImage
  header.add(_int32LE(0));          // biXPelsPerMeter
  header.add(_int32LE(0));          // biYPelsPerMeter
  header.add(_uint32LE(0));         // biClrUsed
  header.add(_uint32LE(0));         // biClrImportant

  // 調色盤（RGBQUAD: B, G, R, reserved, 各 1 byte）
  final paletteBytes = BytesBuilder();
  for (final c in palette) {
    paletteBytes.addByte(c.b);
    paletteBytes.addByte(c.g);
    paletteBytes.addByte(c.r);
    paletteBytes.addByte(0); // reserved
  }
  // 補齊至 paletteSize（不足部分填 0）
  for (var i = palette.length; i < paletteSize; i++) {
    paletteBytes.addByte(0);
    paletteBytes.addByte(0);
    paletteBytes.addByte(0);
    paletteBytes.addByte(0);
  }

  // XOR 像素資料（bottom-up）
  final xorData = BytesBuilder();

  // 查找表：將每個 RGBX 值對映到最近的調色盤索引
  final colorToIndex = <int, int>{};
  for (var i = 0; i < palette.length; i++) {
    final pc = palette[i];
    // 組合 r/g/b 為 24-bit key
    final key = (pc.r << 16) | (pc.g << 8) | pc.b;
    colorToIndex[key] = i;
  }

  for (var y = h - 1; y >= 0; y--) {
    // XOR row
    final xorRow = BytesBuilder();
    var bitBuf = 0;
    var bitCount = 0;

    for (var x = 0; x < w; x++) {
      final pixel = image.getPixel(x, y);
      final a = pixel.a.toInt();
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      // 完全透明像素：顏色設為黑色，AND 遮罩標記為透明
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

    // 刷新 XOR row 剩餘比特
    if (bpp == 4 && bitCount > 0) {
      bitBuf <<= (8 - bitCount);
      xorRow.addByte(bitBuf);
    }

    // XOR row padding 至 4-byte 對齊
    var xorRowOut = xorRow.takeBytes();
    while (xorRowOut.length < xorRowBytes) {
      xorRowOut = Uint8List.fromList([...xorRowOut, 0]);
    }
    xorData.add(xorRowOut);
  }

  // 使用 _buildAndMask 建立 AND 遮罩
  final andRows = _buildAndMask(image, w, andRowBytes);

  return Uint8List.fromList([
    ...header.takeBytes(),
    ...paletteBytes.takeBytes(),
    ...xorData.takeBytes(),
    ...andRows,
  ]);
}

/// 建立 AND 遮罩資料（bottom-up，每行對齊 4-byte）。
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
      // AND mask: 0 = opaque, 1 = transparent
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

/// 代表調色盤中的一個 RGB 顏色。
class _PaletteColor {
  final int r, g, b;
  const _PaletteColor(this.r, this.g, this.b);
}

/// 從圖片中選取最多 [maxColors] 個頻率最高的不透明顏色作為調色盤。
List<_PaletteColor> _buildPalette(img.Image image, int maxColors) {
  final histogram = <int, int>{};
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      if (pixel.a.toInt() < 128) continue; // 跳過透明像素
      final key = (pixel.r.toInt() << 16) | (pixel.g.toInt() << 8) | pixel.b.toInt();
      histogram[key] = (histogram[key] ?? 0) + 1;
    }
  }
  if (histogram.isEmpty) {
    // 全透明圖片：使用純黑單色調色盤
    return List.generate(maxColors, (i) {
      final v = (i * 255) ~/ (maxColors - 1 > 0 ? maxColors - 1 : 1);
      return _PaletteColor(v, v, v);
    });
  }

  // 按頻率降冪排序，取前 maxColors 個
  final sorted = histogram.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final selected = sorted.take(maxColors).toList();

  return selected.map((e) {
    final key = e.key;
    return _PaletteColor((key >> 16) & 0xFF, (key >> 8) & 0xFF, key & 0xFF);
  }).toList();
}

/// 在調色盤中尋找與目標 RGB 最接近的顏色索引（歐幾里得距離）。
int _findNearestPaletteIndex(int r, int g, int b, List<_PaletteColor> palette) {
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

// ─── ICNS 生成 ───────────────────────────────────────────────

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

/// 生成多尺寸 ICNS 檔案（macOS 用）。
///
/// 內含所有標準尺寸（16～1024），各以 PNG 格式封裝。
Future<bool> _generarIcns(
  String icnsPath,
  List<IconOutput> icnsSpecs,
  img.Image? fgImage,
  img.Image? bgImage,
  String projectPath,
  AppStrings s, {
  double? radius,
  double? marginValue,
  bool marginIsPercent = false,
}) async {
  if (fgImage == null && bgImage == null) return false;

  final entries = <_IcnsType, Uint8List>{};
  final generatedImages = <int, img.Image>{};

  // 輔助：取得或生成指定尺寸的圖片
  img.Image _getOrGenerate(int size) {
    return generatedImages.putIfAbsent(size, () {
      final marginForSize = (bgImage != null)
          ? _calcularMargenRaw(marginValue, marginIsPercent, size)
          : 0.0;
      return _generarImagenParaTamanio(
        size, size, fgImage, bgImage,
        whiteBase: false, radius: radius, margin: marginForSize,
      );
    });
  }

  // 為每個 ICNS 尺寸產生 PNG 資料
  for (final type in _icnsTypes) {
    // 檢查該尺寸是否在 spec 中
    final hasSize = icnsSpecs.any((s) => s.width == type.size);
    if (!hasSize) continue;
    final image = _getOrGenerate(type.size);
    entries[type] = Uint8List.fromList(img.encodePng(image));
  }

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

    print(s.generandoIcnsDetalle(normalizarRuta(icnsPath), tipo, oldSizeStr, _formatSize(newSize)));
    return true;
  } catch (e) {
    print(s.writeError(normalizarRuta(filePath), e.toString()));
    return false;
  }
}

/// 將 ICNS 條目編碼為 .icns 檔案格式。
///
/// 格式：'icns' 魔術字 + 總長度 + 逐條目（類型代碼 + 長度 + PNG 資料）。
Uint8List _encodeIcns(Map<_IcnsType, Uint8List> entries) {
  // 計算總長度
  var totalLength = 8; // magic + length header
  for (final entry in entries.entries) {
    totalLength += 8 + entry.value.length; // type(4) + length(4) + data
  }

  final buffer = BytesBuilder();

  // 檔頭魔術字
  buffer.add('icns'.codeUnits);
  buffer.add(_uint32BE(totalLength));

  // 各條目
  for (final entry in entries.entries) {
    final type = entry.key.code;
    final data = entry.value;
    buffer.add(type.codeUnits);
    buffer.add(_uint32BE(8 + data.length)); // 條目長度（含自身 8-byte 頭）
    buffer.add(data);
  }

  return buffer.takeBytes();
}

// ─── 位元組輔助函式 ──────────────────────────────────────────

/// 寫入 16-bit little-endian 無號整數。
List<int> _uint16LE(int v) => [v & 0xFF, (v >> 8) & 0xFF];

/// 寫入 32-bit little-endian 無號整數。
List<int> _uint32LE(int v) =>
    [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF];

/// 寫入 32-bit little-endian 有號整數（用於 BITMAPINFOHEADER）。
List<int> _int32LE(int v) => _uint32LE(v);

/// 寫入 32-bit big-endian 無號整數。
List<int> _uint32BE(int v) =>
    [(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF];

/// 將前景圖按比例縮放，使其剛好容納在目標尺寸內（保持寬高比）。
///
/// [margin] 為前景距邊緣的最小距離（像素），預設 0 表示填滿。
/// 多餘空間為透明，圖片置中於目標畫布中。
img.Image _escalarProporcional(img.Image src, int targetW, int targetH, {double margin = 0}) {
  // 計算有效區域（扣除雙倍邊距），至少保留 1 像素
  final effectiveW = (targetW - 2 * margin).round().clamp(1, targetW);
  final effectiveH = (targetH - 2 * margin).round().clamp(1, targetH);

  // 建立帶有 alpha 通道的畫布（numChannels: 4 = RGBA）
  final canvas = img.Image(
    width: targetW,
    height: targetH,
    numChannels: 4,
  );

  // 以透明色填滿整個畫布，確保多餘區域為透明而非黑色
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  // 在有效區域內計算縮放比例，使圖片剛好容納
  final scale = _calcularEscala(src.width, src.height, effectiveW, effectiveH);
  final scaledW = (src.width * scale).round();
  final scaledH = (src.height * scale).round();

  // 縮放原始圖片
  final scaled = img.copyResize(
    src,
    width: scaledW,
    height: scaledH,
    interpolation: img.Interpolation.cubic,
  );

  // 將縮放後的圖片居中合成到透明畫布上
  final offsetX = ((targetW - scaledW) / 2).round();
  final offsetY = ((targetH - scaledH) / 2).round();
  img.compositeImage(canvas, scaled, dstX: offsetX, dstY: offsetY);

  return canvas;
}

/// 將背景圖拉伸至目標尺寸（不保持比例）。
img.Image _estirar(img.Image src, int targetW, int targetH) {
  return img.copyResize(
    src,
    width: targetW,
    height: targetH,
    interpolation: img.Interpolation.cubic,
  );
}

/// 合併前景與背景圖：背景拉伸填滿，前景居中並保持比例。
///
/// 若 [whiteBase] 為 true，則最底層會先放置白色不透明底色，
/// 確保輸出圖片無透明區域（iOS App Icon 要求）。
///
/// 若僅提供前景則放在透明（或白色）畫布上，若僅提供背景則直接拉伸。
img.Image _fusionar(
  img.Image? fgSrc,
  img.Image? bgSrc,
  int targetW,
  int targetH, {
  bool whiteBase = false,
  double margin = 0,
}) {
  // 需要白色底色的情況：建立白色畫布作為基底
  img.Image result;
  if (whiteBase) {
    // 建立不透明的白色基底畫布
    result = img.Image(
      width: targetW,
      height: targetH,
      numChannels: 4,
    );
    img.fill(result, color: img.ColorRgba8(255, 255, 255, 255));
  } else {
    // 無需白色底色：建立透明基底（前景層）
    result = img.Image(
      width: targetW,
      height: targetH,
      numChannels: 4,
    );
    img.fill(result, color: img.ColorRgba8(0, 0, 0, 0));
  }

  // 僅有前景：縮放後居中合成到基底上（套用邊距）
  if (fgSrc != null && bgSrc == null) {
    final fgSized = _escalarProporcional(fgSrc, targetW, targetH, margin: margin);
    img.compositeImage(result, fgSized);
    return result;
  }

  // 僅有背景：拉伸後合成到基底上（邊距不影響背景）
  if (fgSrc == null && bgSrc != null) {
    final bgStretched = _estirar(bgSrc, targetW, targetH);
    img.compositeImage(result, bgStretched);
    return result;
  }

  // 兩者皆有：先合成拉伸後的背景，再合成前景（套用邊距）
  final bgStretched = _estirar(bgSrc!, targetW, targetH);
  img.compositeImage(result, bgStretched);

  // 使用 _escalarProporcional 統一處理前景縮放與邊距
  final fgSized = _escalarProporcional(fgSrc!, targetW, targetH, margin: margin);
  img.compositeImage(result, fgSized);

  return result;
}

/// 計算縮放比例，使原始圖片剛好容納在目標尺寸內。
///
/// 取 min(widthRatio, heightRatio) 以確保圖片不超出目標範圍。
double _calcularEscala(int srcW, int srcH, int targetW, int targetH) {
  final wRatio = targetW / srcW;
  final hRatio = targetH / srcH;
  return wRatio < hRatio ? wRatio : hRatio;
}

/// iOS 圖示圓角比例常數（約 22.37%）。
const _iosCornerRadiusRatio = 0.2237;

/// 根據使用者指定的圓角值與目標尺寸計算實際圓角半徑。
///
/// [userRadius] 為使用者透過 -r 指定的像素值，null 表示自動計算。
/// [w] 與 [h] 為目標圖示的寬高。
///
/// 自動計算模式使用 iOS 圓角比例計算：[min(w, h) * 0.2237]。
/// 若計算結果為 0 或不需套用則回傳 null。
double? _calcularRadio(double? userRadius, int w, int h) {
  if (userRadius != null) {
    // 使用者指定了圓角值，直接使用（即使為 0 也套用）
    if (userRadius <= 0) return null;
    return userRadius;
  }

  // 自動計算模式：使用 iOS 圓角比例
  final r = (w < h ? w : h) * _iosCornerRadiusRatio;
  if (r < 1.0) return null; // 圓角太小則不套用

  return r;
}

/// 對圖片套用圓角裁剪。
///
/// [src] 為原始圖片。
/// [radio] 為圓角半徑（像素），若為 null 則直接回傳原圖。
/// 回傳圓角裁剪後的新圖片（圓角外區域為透明）。
img.Image _aplicarBordeRedondo(img.Image src, double? radio) {
  if (radio == null || radio <= 0) return src;

  final w = src.width;
  final h = src.height;

  // 確保半徑不超過圖片最短邊的一半
  final limite = (w < h ? w : h) / 2;
  final r = radio > limite ? limite : radio;

  // 建立帶 alpha 通道的輸出畫布
  final result = img.Image(width: w, height: h, numChannels: 4);

  // 逐像素檢查是否位於圓角矩形內部
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (_isInsideRoundedRect(x, y, w, h, r)) {
        final pixel = src.getPixel(x, y);
        result.setPixelRgba(x, y, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), pixel.a.toInt());
      }
      // 圓角外部保持透明（預設即為透明）
    }
  }

  return result;
}

/// 判斷像素 (x, y) 是否在圓角矩形內部。
///
/// 四個角落為四分之一圓弧切割，圓心位於角落內側 [r] 像素處。
bool _isInsideRoundedRect(int x, int y, int w, int h, double r) {
  // 左上角
  if (x < r && y < r) {
    final dx = r - x;
    final dy = r - y;
    if (dx * dx + dy * dy > r * r) return false;
  }
  // 右上角
  if (x >= w - r && y < r) {
    final dx = x - (w - 1 - r);
    final dy = r - y;
    if (dx * dx + dy * dy > r * r) return false;
  }
  // 左下角
  if (x < r && y >= h - r) {
    final dx = r - x;
    final dy = y - (h - 1 - r);
    if (dx * dx + dy * dy > r * r) return false;
  }
  // 右下角
  if (x >= w - r && y >= h - r) {
    final dx = x - (w - 1 - r);
    final dy = y - (h - 1 - r);
    if (dx * dx + dy * dy > r * r) return false;
  }
  return true;
}

/// 格式化位元組大小為人類可讀字串（B／KB／MB）。
String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// 根據圖層類型與 whiteBase 旗標回傳對應的圖層類型顯示字串。
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

/// 預設前景邊距比例（10%）。
const _defaultMarginRatio = 0.10;

/// 根據命令列參數與圖示最小邊長計算前景邊距像素值。
///
/// [args] 為命令列參數，[minDim] 為圖示的 min(寬, 高)。
/// 未指定 -m 時預設為 minDim 的 10%。
double _calcularMargen(CliArgs args, int minDim) {
  if (args.marginValue == null) {
    // 預設 10%
    return minDim * _defaultMarginRatio;
  }
  if (args.marginIsPercent) {
    return minDim * args.marginValue! / 100.0;
  }
  return args.marginValue!;
}

/// 根據原始邊距設定值與圖示最小邊長計算邊距像素值。
///
/// [value] 為邊距數值（像素或百分比數值），null 表示使用預設 10%。
/// [isPercent] 指示是否為百分比模式。
/// [minDim] 為圖示的 min(寬, 高)。
double _calcularMargenRaw(double? value, bool isPercent, int minDim) {
  if (value == null) return minDim * _defaultMarginRatio;
  if (isPercent) return minDim * value / 100.0;
  return value;
}
