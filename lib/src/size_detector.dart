import 'package:path/path.dart' as p;

/// Android density 名稱與對應的像素倍率。
const _densityMap = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

/// Android 各類圖示的基底 dp 尺寸。
const _androidBaseDp = {
  'ic_launcher': 48, // 舊版啟動器圖示
  'ic_launcher_foreground': 108, // 自適應前景
  'ic_launcher_background': 108, // 自適應背景
  'launch_background': 108, // 啟動圖片背景
};

/// 從檔案路徑與平台資訊偵測目標尺寸。
///
/// 回傳 `(width, height)`，若無法判斷則回傳 `null`（此時應讀取原始圖片尺寸）。
({int width, int height})? detectTargetSize(String filePath, String platform) {
  final fileName = p.basename(filePath);
  final parentDir = p.basename(p.dirname(filePath));

  switch (platform) {
    case 'ios':
      return _detectIosSize(fileName);
    case 'android':
      return _detectAndroidSize(fileName, parentDir);
    case 'macos':
      return _detectMacosSize(fileName);
    case 'web':
      return _detectWebSize(fileName);
    case 'windows':
      return _detectWindowsSize(fileName);
    default:
      return null;
  }
}

/// 解析 iOS 檔案名稱中的尺寸資訊。
///
/// 支援格式：
/// - `Icon-20.png` → 20×20
/// - `Icon-20@2x.png` → 40×40
/// - `Icon-29@3x.png` → 87×87
/// - `Icon-83.5@2x.png` → 167×167
/// - `LaunchImage@2x.png` → 取基礎尺寸 375×812 乘以倍率
({int width, int height})? _detectIosSize(String fileName) {
  final baseName = p.basenameWithoutExtension(fileName);

  // 啟動圖片：使用常見 iPhone 邏輯解析度作為基礎
  if (baseName.startsWith('LaunchImage')) {
    const baseW = 375;
    const baseH = 812;
    final scaleMatch = RegExp(r'@(\d+)x$').firstMatch(baseName);
    final scale = scaleMatch != null ? int.parse(scaleMatch.group(1)!) : 1;
    return (width: baseW * scale, height: baseH * scale);
  }

  // App Icon：格式為 Icon-{size} 或 Icon-{size}@{scale}x
  final match = RegExp(r'^Icon-(\d+\.?\d*)(?:@(\d+)x)?$').firstMatch(baseName);
  if (match == null) return null;

  final baseSize = double.parse(match.group(1)!);
  final scale = match.group(2) != null ? int.parse(match.group(2)!) : 1;
  final pixelSize = (baseSize * scale).round();

  return (width: pixelSize, height: pixelSize);
}

/// 解析 Android 檔案名稱與父目錄 density 中的尺寸資訊。
///
/// 根據檔案名稱決定基底 dp 尺寸，再搭配 density 倍率計算像素尺寸。
({int width, int height})? _detectAndroidSize(String fileName, String parentDir) {
  // 從父目錄名稱中擷取 density 代號（使用精確匹配優先，避免 xhdpi 誤匹配 hdpi）
  final densityParts = parentDir.split(RegExp(r'[-_]'));
  String? density;
  for (final d in _densityMap.keys) {
    if (densityParts.contains(d)) {
      density = d;
      break;
    }
  }
  if (density == null) return null;
  final multiplier = _densityMap[density]!;

  // 從檔案名判斷圖示類型，按 key 長度降序比對（避免 ic_launcher 攔截 ic_launcher_foreground）
  int baseDp = 48;
  final baseName = p.basenameWithoutExtension(fileName);
  final sortedKeys = _androidBaseDp.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final key in sortedKeys) {
    if (baseName.startsWith(key)) {
      baseDp = _androidBaseDp[key]!;
      break;
    }
  }

  final pixelSize = (baseDp * multiplier).round();
  return (width: pixelSize, height: pixelSize);
}

/// 解析 macOS 檔案名稱中的尺寸資訊。
///
/// 支援格式：
/// - `icon_16x16.png` → 16×16
/// - `icon_16x16@2x.png` → 32×32
/// - `icon_256x256@2x.png` → 512×512
({int width, int height})? _detectMacosSize(String fileName) {
  final baseName = p.basenameWithoutExtension(fileName);

  // 格式：icon_{w}x{h} 或 icon_{w}x{h}@2x
  final match =
      RegExp(r'^icon_(\d+)x(\d+)(?:@(\d+)x)?$').firstMatch(baseName);
  if (match == null) return null;

  final baseW = int.parse(match.group(1)!);
  final baseH = int.parse(match.group(2)!);
  final scale = match.group(3) != null ? int.parse(match.group(3)!) : 1;

  return (width: baseW * scale, height: baseH * scale);
}

/// 解析 Web 檔案名稱中的尺寸資訊。
///
/// 支援格式：
/// - `Icon-192.png` → 192×192
/// - `Icon-512.png` → 512×512
/// - `favicon.png` → 64×64（預設）
({int width, int height})? _detectWebSize(String fileName) {
  final baseName = p.basenameWithoutExtension(fileName);

  if (baseName == 'favicon') {
    return (width: 64, height: 64);
  }

  final match = RegExp(r'^Icon-(\d+)$').firstMatch(baseName);
  if (match == null) return null;

  final size = int.parse(match.group(1)!);
  return (width: size, height: size);
}

/// 解析 Windows .ico 檔案（回傳 `null`，後續使用檔案自身尺寸）。
({int width, int height})? _detectWindowsSize(String fileName) {
  // .ico 檔案不從檔名解析尺寸，由呼叫方讀取原始圖片尺寸
  return null;
}
