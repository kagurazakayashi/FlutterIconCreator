import 'package:image/image.dart' as img;

/// iOS 圖示圓角比例常數（約 22.37%）。
const iosCornerRadiusRatio = 0.2237;

/// 計算縮放比例，使原始圖片剛好容納在目標尺寸內。
///
/// 取 min(widthRatio, heightRatio) 以確保圖片不超出目標範圍。
double calculateScale(int srcW, int srcH, int targetW, int targetH) {
  final wRatio = targetW / srcW;
  final hRatio = targetH / srcH;
  return wRatio < hRatio ? wRatio : hRatio;
}

/// 根據使用者指定的圓角值與目標尺寸計算實際圓角半徑。
///
/// [userRadius] 為使用者指定的像素值，null 表示自動計算。
/// [w] 與 [h] 為目標圖示的寬高。
double? calculateRadius(double? userRadius, int w, int h) {
  if (userRadius != null) {
    if (userRadius <= 0) return null;
    return userRadius;
  }

  final r = (w < h ? w : h) * iosCornerRadiusRatio;
  if (r < 1.0) return null;

  return r;
}

/// 將前景圖按比例縮放，使其剛好容納在目標尺寸內（保持寬高比）。
///
/// [margin] 為前景距邊緣的最小距離（像素），預設 0 表示填滿。
img.Image scaleProportional(img.Image src, int targetW, int targetH,
    {double margin = 0}) {
  final effectiveW = (targetW - 2 * margin).round().clamp(1, targetW);
  final effectiveH = (targetH - 2 * margin).round().clamp(1, targetH);

  final canvas = img.Image(width: targetW, height: targetH, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  final scale = calculateScale(src.width, src.height, effectiveW, effectiveH);
  final scaledW = (src.width * scale).round();
  final scaledH = (src.height * scale).round();

  final scaled = img.copyResize(
    src,
    width: scaledW,
    height: scaledH,
    interpolation: img.Interpolation.cubic,
  );

  final offsetX = ((targetW - scaledW) / 2).round();
  final offsetY = ((targetH - scaledH) / 2).round();
  img.compositeImage(canvas, scaled, dstX: offsetX, dstY: offsetY);

  return canvas;
}

/// 將背景圖拉伸至目標尺寸（不保持比例）。
img.Image stretch(img.Image src, int targetW, int targetH) {
  return img.copyResize(
    src,
    width: targetW,
    height: targetH,
    interpolation: img.Interpolation.cubic,
  );
}

/// 合併前景與背景圖：背景拉伸填滿，前景居中並保持比例。
///
/// 若 [whiteBase] 為 true，則最底層會先放置白色不透明底色。
/// 若僅提供前景則放在透明（或白色）畫布上，若僅提供背景則直接拉伸。
img.Image merge(
  img.Image? fgSrc,
  img.Image? bgSrc,
  int targetW,
  int targetH, {
  bool whiteBase = false,
  double margin = 0,
}) {
  img.Image result;
  if (whiteBase) {
    result = img.Image(width: targetW, height: targetH, numChannels: 4);
    img.fill(result, color: img.ColorRgba8(255, 255, 255, 255));
  } else {
    result = img.Image(width: targetW, height: targetH, numChannels: 4);
    img.fill(result, color: img.ColorRgba8(0, 0, 0, 0));
  }

  if (fgSrc != null && bgSrc == null) {
    final fgSized = scaleProportional(fgSrc, targetW, targetH, margin: margin);
    img.compositeImage(result, fgSized);
    return result;
  }

  if (fgSrc == null && bgSrc != null) {
    final bgStretched = stretch(bgSrc, targetW, targetH);
    img.compositeImage(result, bgStretched);
    return result;
  }

  final bgStretched = stretch(bgSrc!, targetW, targetH);
  img.compositeImage(result, bgStretched);

  final fgSized = scaleProportional(fgSrc!, targetW, targetH, margin: margin);
  img.compositeImage(result, fgSized);

  return result;
}

/// 對圖片套用圓角裁剪。
///
/// [src] 為原始圖片，[radius] 為圓角半徑（像素）。
/// 若 [radius] 為 null 則直接回傳原圖。
img.Image applyRoundedCorners(img.Image src, double? radius) {
  if (radius == null || radius <= 0) return src;

  final w = src.width;
  final h = src.height;
  final limite = (w < h ? w : h) / 2;
  final r = radius > limite ? limite : radius;

  final result = img.Image(width: w, height: h, numChannels: 4);

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (_isInsideRoundedRect(x, y, w, h, r)) {
        final pixel = src.getPixel(x, y);
        result.setPixelRgba(
            x, y, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(),
            pixel.a.toInt());
      }
    }
  }

  return result;
}

/// 判斷像素 (x, y) 是否在圓角矩形內部。
bool _isInsideRoundedRect(int x, int y, int w, int h, double r) {
  if (x < r && y < r) {
    final dx = r - x;
    final dy = r - y;
    if (dx * dx + dy * dy > r * r) return false;
  }
  if (x >= w - r && y < r) {
    final dx = x - (w - 1 - r);
    final dy = r - y;
    if (dx * dx + dy * dy > r * r) return false;
  }
  if (x < r && y >= h - r) {
    final dx = r - x;
    final dy = y - (h - 1 - r);
    if (dx * dx + dy * dy > r * r) return false;
  }
  if (x >= w - r && y >= h - r) {
    final dx = x - (w - 1 - r);
    final dy = y - (h - 1 - r);
    if (dx * dx + dy * dy > r * r) return false;
  }
  return true;
}

/// 為指定尺寸產生圖層合成後的圖片。
///
/// 統一的圖片生成邏輯，供 ICO、ICNS 等多格式共用。
img.Image generateImageForSize(
  int width, int height,
  img.Image? fgImage, img.Image? bgImage, {
  bool whiteBase = false,
  double? radius,
  double margin = 0,
}) {
  final img.Image sized;
  if (fgImage != null && bgImage != null) {
    sized = merge(fgImage, bgImage, width, height,
        whiteBase: whiteBase, margin: margin);
  } else if (fgImage != null) {
    if (whiteBase) {
      sized = merge(fgImage, null, width, height,
          whiteBase: true, margin: margin);
    } else {
      sized = scaleProportional(fgImage, width, height, margin: margin);
    }
  } else {
    if (whiteBase) {
      sized = merge(null, bgImage, width, height, whiteBase: true);
    } else {
      sized = stretch(bgImage!, width, height);
    }
  }
  final radiusForSize = calculateRadius(radius, width, height);
  return applyRoundedCorners(sized, radiusForSize);
}
