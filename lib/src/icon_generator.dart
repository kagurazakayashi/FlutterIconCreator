import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'cli_args.dart';
import 'i18n/strings.dart';
import 'platform_specs.dart';

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

    // 處理一般 PNG 圖示輸出
    for (final output in spec.iconOutputs) {
      final generated = await _generarYGuardar(
        output, fgImage, bgImage, args.flutterProjectPath, s,
        whiteBase: spec.requiresOpaqueIcons,
      );
      if (generated) totalGenerated++;
    }

    // 處理一般 PNG 啟動圖片輸出
    for (final output in spec.splashOutputs) {
      final generated = await _generarYGuardar(
        output, fgImage, bgImage, args.flutterProjectPath, s,
        whiteBase: spec.requiresOpaqueIcons,
      );
      if (generated) totalGenerated++;
    }

    // 處理多尺寸 ICO 輸出
    for (final entry in spec.icoOutputs.entries) {
      final generated = await _generarIco(
        entry.key, entry.value, fgImage, bgImage,
        args.flutterProjectPath, s,
        whiteBase: spec.requiresOpaqueIcons,
      );
      if (generated) totalGenerated++;
    }
  }

  print(s.generacionCompletada(totalGenerated));
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
}) async {
  // 根據圖層類型決定需要哪些來源圖片
  // 合併圖層只需至少一張圖片即可，前景/背景圖層則嚴格要求對應圖片
  if (output.layer == ImageLayer.foreground && fgImage == null) {
    print('  ${s.skippingLayerFg(output.relativePath)}');
    return false;
  }
  if (output.layer == ImageLayer.background && bgImage == null) {
    print('  ${s.skippingLayerBg(output.relativePath)}');
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
      generated = _escalarProporcional(fgImage!, output.width, output.height);
    case ImageLayer.background:
      generated = _estirar(bgImage!, output.width, output.height);
    case ImageLayer.merged:
      generated = _fusionar(
        fgImage, bgImage, output.width, output.height,
        whiteBase: whiteBase,
      );
  }

  // 寫入檔案
  final filePath = p.join(projectPath, output.relativePath);
  try {
    final dir = Directory(p.dirname(filePath));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    await File(filePath).writeAsBytes(img.encodePng(generated));
    print(s.generandoIcono(
      output.relativePath, output.width, output.height,
    ));
    return true;
  } catch (e) {
    print(s.writeError(filePath, e.toString()));
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
}) async {
  if (fgImage == null && bgImage == null) return false;

  final icoImages = <img.Image>[];

  for (final spec in icoSpecs) {
    final img.Image sized;
    if (fgImage != null && bgImage != null) {
      sized = _fusionar(fgImage, bgImage, spec.width, spec.height,
          whiteBase: whiteBase);
    } else if (fgImage != null) {
      if (whiteBase) {
        sized = _fusionar(fgImage, null, spec.width, spec.height,
            whiteBase: true);
      } else {
        sized = _escalarProporcional(fgImage, spec.width, spec.height);
      }
    } else {
      if (whiteBase) {
        sized = _fusionar(null, bgImage, spec.width, spec.height,
            whiteBase: true);
      } else {
        sized = _estirar(bgImage!, spec.width, spec.height);
      }
    }
    icoImages.add(sized);
  }

  // 使用 IcoEncoder 將多個尺寸合併為一個 ICO 檔案
  final encoder = img.IcoEncoder();
  final icoBytes = encoder.encodeImages(icoImages);

  final filePath = p.join(projectPath, icoPath);
  try {
    final dir = Directory(p.dirname(filePath));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    await File(filePath).writeAsBytes(icoBytes);
    print(s.generandoIco(icoPath));
    return true;
  } catch (e) {
    print(s.writeError(filePath, e.toString()));
    return false;
  }
}

/// 將前景圖按比例縮放，使其剛好容納在目標尺寸內（保持寬高比）。
///
/// 多餘空間為透明，圖片置中於目標畫布中。
img.Image _escalarProporcional(img.Image src, int targetW, int targetH) {
  // 建立帶有 alpha 通道的畫布（numChannels: 4 = RGBA）
  final canvas = img.Image(
    width: targetW,
    height: targetH,
    numChannels: 4,
  );

  // 以透明色填滿整個畫布，確保多餘區域為透明而非黑色
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  // 計算縮放比例，使圖片剛好容納在目標尺寸內
  final scale = _calcularEscala(src.width, src.height, targetW, targetH);
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

  // 僅有前景：縮放後居中合成到基底上
  if (fgSrc != null && bgSrc == null) {
    final fgSized = _escalarProporcional(fgSrc, targetW, targetH);
    img.compositeImage(result, fgSized);
    return result;
  }

  // 僅有背景：拉伸後合成到基底上
  if (fgSrc == null && bgSrc != null) {
    final bgStretched = _estirar(bgSrc, targetW, targetH);
    img.compositeImage(result, bgStretched);
    return result;
  }

  // 兩者皆有：先合成拉伸後的背景，再合成前景
  final bgStretched = _estirar(bgSrc!, targetW, targetH);
  img.compositeImage(result, bgStretched);

  // 計算前景縮放比例，使其容納在目標尺寸內
  final scale = _calcularEscala(fgSrc!.width, fgSrc.height, targetW, targetH);
  final fgW = (fgSrc.width * scale).round();
  final fgH = (fgSrc.height * scale).round();

  // 縮放前景圖並居中合成
  final fgScaled = img.copyResize(
    fgSrc,
    width: fgW,
    height: fgH,
    interpolation: img.Interpolation.cubic,
  );
  final offsetX = ((targetW - fgW) / 2).round();
  final offsetY = ((targetH - fgH) / 2).round();
  img.compositeImage(result, fgScaled, dstX: offsetX, dstY: offsetY);

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
