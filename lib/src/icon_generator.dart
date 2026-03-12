import 'dart:io';

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

/// 生成多尺寸 ICO 檔案。
///
/// 將多個不同尺寸的圖片合併為單一 .ico 檔案後寫入磁碟。
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

  final icoImages = <img.Image>[];

  for (final spec in icoSpecs) {
    // 為每個 ICO 尺寸獨立計算圓角及邊距
    final radioForSize = _calcularRadio(radius, spec.width, spec.height);
    final minDim = spec.width < spec.height ? spec.width : spec.height;
    // 邊距僅在有背景圖或白底時套用，純透明背景不套用
    final marginForSize = (bgImage != null || whiteBase)
        ? _calcularMargenRaw(marginValue, marginIsPercent, minDim)
        : 0.0;

    final img.Image sized;
    if (fgImage != null && bgImage != null) {
      sized = _fusionar(fgImage, bgImage, spec.width, spec.height,
          whiteBase: whiteBase, margin: marginForSize);
    } else if (fgImage != null) {
      if (whiteBase) {
        sized = _fusionar(fgImage, null, spec.width, spec.height,
            whiteBase: true, margin: marginForSize);
      } else {
        sized = _escalarProporcional(fgImage, spec.width, spec.height,
            margin: marginForSize);
      }
    } else {
      if (whiteBase) {
        sized = _fusionar(null, bgImage, spec.width, spec.height,
            whiteBase: true);
      } else {
        sized = _estirar(bgImage!, spec.width, spec.height);
      }
    }

    icoImages.add(_aplicarBordeRedondo(sized, radioForSize));
  }

  // 使用 IcoEncoder 將多個尺寸合併為一個 ICO 檔案
  final encoder = img.IcoEncoder();
  final icoBytes = encoder.encodeImages(icoImages);

  final filePath = p.join(projectPath, icoPath);
  try {
    // 偵測舊檔案大小（若存在）
    final oldFile = File(filePath);
    final oldSize = oldFile.existsSync() ? oldFile.lengthSync() : null;

    final dir = Directory(p.dirname(filePath));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    await File(filePath).writeAsBytes(icoBytes);

    // 新檔案大小
    final newSize = File(filePath).lengthSync();

    // ICO 的圖層類型（取第一個規格的類型，所有 ICO 尺寸使用相同的 whiteBase/layer）
    final tipo = _layerTypeString(icoSpecs.first.layer, whiteBase, s);
    final oldSizeStr = oldSize != null ? _formatSize(oldSize) : s.newFileLabel;

    print(s.generandoIcoDetalle(normalizarRuta(icoPath), tipo, oldSizeStr, _formatSize(newSize)));
    return true;
  } catch (e) {
    print(s.writeError(normalizarRuta(filePath), e.toString()));
    return false;
  }
}

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
