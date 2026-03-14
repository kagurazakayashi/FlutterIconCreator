import 'package:path/path.dart' as p;

/// 圖片圖層類型：決定輸出檔案應包含哪種圖層。
enum ImageLayer {
  /// 僅前景（保持比例縮放）。
  foreground,

  /// 僅背景（拉伸填滿）。
  background,

  /// 合併前景與背景（背景拉伸 + 前景居中保持比例）。
  merged,
}

/// 單一輸出檔案的規格。
class IconOutput {
  /// 相對於 Flutter 專案根目錄的輸出路徑。
  final String relativePath;

  /// 目標寬度（像素）。
  final int width;

  /// 目標高度（像素）。
  final int height;

  /// 此輸出應包含的圖層類型。
  final ImageLayer layer;

  /// 是否為啟動圖片（啟動畫面不套用圓角）。
  final bool isSplash;

  const IconOutput({
    required this.relativePath,
    required this.width,
    required this.height,
    required this.layer,
    this.isSplash = false,
  });
}

/// 各平台的輸出規格集合。
class PlatformSpec {
  final String name;

  /// 該平台的所有圖示輸出（不含 ICO 合併格式）。
  final List<IconOutput> iconOutputs;

  /// 該平台的所有啟動圖片輸出。
  final List<IconOutput> splashOutputs;

  /// ICO 多尺寸輸出：將多個尺寸合併為一個 .ico 檔案。
  ///
  /// Map key 為 ICO 輸出檔案路徑，value 為多個尺寸規格清單。
  final Map<String, List<IconOutput>> icoOutputs;

  /// ICNS 多尺寸輸出：將多個尺寸合併為一個 .icns 檔案。
  ///
  /// Map key 為 ICNS 輸出檔案路徑，value 為多個尺寸規格清單。
  final Map<String, List<IconOutput>> icnsOutputs;

  /// 是否需要不透明底色（如 iOS App Icon 不允許透明區域）。
  final bool requiresOpaqueIcons;

  const PlatformSpec({
    required this.name,
    this.iconOutputs = const [],
    this.splashOutputs = const [],
    this.icoOutputs = const {},
    this.icnsOutputs = const {},
    this.requiresOpaqueIcons = false,
  });
}

// ──────────────────────────────────────────────────────────────
// Android 密度規格
// ──────────────────────────────────────────────────────────────

/// Android density 名稱與對應的 dp 倍數。
const _androidDensities = <({String name, double factor})>[
  (name: 'mdpi', factor: 1.0),
  (name: 'hdpi', factor: 1.5),
  (name: 'xhdpi', factor: 2.0),
  (name: 'xxhdpi', factor: 3.0),
  (name: 'xxxhdpi', factor: 4.0),
];

/// 舊版啟動器圖示基底尺寸（dp）。
const _legacyIconBase = 48;

/// 自適應圖示基底尺寸（dp）。
const _adaptiveIconBase = 108;

/// 計算 Android density 像素尺寸。
int _dp(num baseValue, double factor) => (baseValue * factor).round();

// ──────────────────────────────────────────────────────────────
// Android 平台規格
// ──────────────────────────────────────────────────────────────

PlatformSpec _buildAndroidSpec() {
  final iconOutputs = <IconOutput>[];
  final splashOutputs = <IconOutput>[];

  for (final d in _androidDensities) {
    final densityDir = 'mipmap-${d.name}';
    final drawableDir = 'drawable-${d.name}';
    final androidBase = p.join(
      'android', 'app', 'src', 'main', 'res',
    );

    // 舊版啟動器圖示（合併圖層）
    iconOutputs.add(IconOutput(
      relativePath: p.join(androidBase, densityDir, 'ic_launcher.png'),
      width: _dp(_legacyIconBase, d.factor),
      height: _dp(_legacyIconBase, d.factor),
      layer: ImageLayer.merged,
    ));

    // 自適應圖示前景（僅前景，保持比例）
    iconOutputs.add(IconOutput(
      relativePath: p.join(androidBase, densityDir, 'ic_launcher_foreground.png'),
      width: _dp(_adaptiveIconBase, d.factor),
      height: _dp(_adaptiveIconBase, d.factor),
      layer: ImageLayer.foreground,
    ));

    // 自適應圖示背景（僅背景，拉伸）
    iconOutputs.add(IconOutput(
      relativePath: p.join(androidBase, densityDir, 'ic_launcher_background.png'),
      width: _dp(_adaptiveIconBase, d.factor),
      height: _dp(_adaptiveIconBase, d.factor),
      layer: ImageLayer.background,
    ));

    // 啟動圖片背景（合併圖層）
    splashOutputs.add(IconOutput(
      relativePath: p.join(androidBase, drawableDir, 'launch_background.png'),
      width: _dp(_adaptiveIconBase, d.factor),
      height: _dp(_adaptiveIconBase, d.factor),
      layer: ImageLayer.merged,
      isSplash: true,
    ));
  }

  return PlatformSpec(
    name: 'android',
    iconOutputs: iconOutputs,
    splashOutputs: splashOutputs,
  );
}

// ──────────────────────────────────────────────────────────────
// iOS 平台規格
// ──────────────────────────────────────────────────────────────

PlatformSpec _buildIosSpec() {
  final base = p.join(
    'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset',
  );

  // iOS App Icon 各尺寸（皆為合併圖層）
  final iconOutputs = <IconOutput>[
    const IconOutput(relativePath: 'Icon-20.png', width: 20, height: 20, layer: ImageLayer.merged),
    const IconOutput(relativePath: 'Icon-20@2x.png', width: 40, height: 40, layer: ImageLayer.merged),
    const IconOutput(relativePath: 'Icon-20@3x.png', width: 60, height: 60, layer: ImageLayer.merged),
    const IconOutput(relativePath: 'Icon-29.png', width: 29, height: 29, layer: ImageLayer.merged),
    const IconOutput(relativePath: 'Icon-29@2x.png', width: 58, height: 58, layer: ImageLayer.merged),
    const IconOutput(relativePath: 'Icon-29@3x.png', width: 87, height: 87, layer: ImageLayer.merged),
    const IconOutput(relativePath: 'Icon-40.png', width: 40, height: 40, layer: ImageLayer.merged),
    const IconOutput(relativePath: 'Icon-40@2x.png', width: 80, height: 80, layer: ImageLayer.merged),
    const IconOutput(relativePath: 'Icon-40@3x.png', width: 120, height: 120, layer: ImageLayer.merged),
    const IconOutput(relativePath: 'Icon-60@2x.png', width: 120, height: 120, layer: ImageLayer.merged),
    const IconOutput(relativePath: 'Icon-60@3x.png', width: 180, height: 180, layer: ImageLayer.merged),
    const IconOutput(relativePath: 'Icon-76.png', width: 76, height: 76, layer: ImageLayer.merged),
    const IconOutput(relativePath: 'Icon-76@2x.png', width: 152, height: 152, layer: ImageLayer.merged),
    const IconOutput(relativePath: 'Icon-83.5@2x.png', width: 167, height: 167, layer: ImageLayer.merged),
    const IconOutput(relativePath: 'Icon-1024.png', width: 1024, height: 1024, layer: ImageLayer.merged),
  ];

  // 將相對路徑加上 iOS base 前綴
  final fullIconOutputs = iconOutputs.map((o) => IconOutput(
    relativePath: p.join(base, o.relativePath),
    width: o.width,
    height: o.height,
    layer: o.layer,
  )).toList();

  // iOS 啟動圖片
  final splashBase = p.join(
    'ios', 'Runner', 'Assets.xcassets', 'LaunchImage.imageset',
  );
  final splashOutputs = <IconOutput>[
    IconOutput(relativePath: p.join(splashBase, 'LaunchImage.png'), width: 375, height: 812, layer: ImageLayer.merged, isSplash: true),
    IconOutput(relativePath: p.join(splashBase, 'LaunchImage@2x.png'), width: 750, height: 1624, layer: ImageLayer.merged, isSplash: true),
    IconOutput(relativePath: p.join(splashBase, 'LaunchImage@3x.png'), width: 1125, height: 2436, layer: ImageLayer.merged, isSplash: true),
  ];

  return PlatformSpec(
    name: 'ios',
    iconOutputs: fullIconOutputs,
    splashOutputs: splashOutputs,
    requiresOpaqueIcons: true,
  );
}

// ──────────────────────────────────────────────────────────────
// Web 平台規格
// ──────────────────────────────────────────────────────────────

PlatformSpec _buildWebSpec() {
  final iconOutputs = <IconOutput>[
    IconOutput(relativePath: p.join('web', 'favicon.png'), width: 64, height: 64, layer: ImageLayer.merged),
    IconOutput(relativePath: p.join('web', 'icons', 'Icon-192.png'), width: 192, height: 192, layer: ImageLayer.merged),
    IconOutput(relativePath: p.join('web', 'icons', 'Icon-512.png'), width: 512, height: 512, layer: ImageLayer.merged),
    IconOutput(relativePath: p.join('web', 'icons', 'Icon-maskable-192.png'), width: 192, height: 192, layer: ImageLayer.merged),
    IconOutput(relativePath: p.join('web', 'icons', 'Icon-maskable-512.png'), width: 512, height: 512, layer: ImageLayer.merged),
  ];

  return PlatformSpec(
    name: 'web',
    iconOutputs: iconOutputs,
  );
}

// ──────────────────────────────────────────────────────────────
// Windows 平台規格
// ──────────────────────────────────────────────────────────────

PlatformSpec _buildWindowsSpec() {
  // Windows 使用多尺寸 ICO 檔案，所有標準尺寸合併為單一檔案
  final icoPath = p.join('windows', 'runner', 'resources', 'app_icon.ico');
  const icoSizes = [16, 20, 24, 32, 40, 48, 64, 96, 128, 256];

  final icoOutputs = <String, List<IconOutput>>{
    icoPath: icoSizes.map((size) => IconOutput(
      relativePath: icoPath,
      width: size,
      height: size,
      layer: ImageLayer.merged,
    )).toList(),
  };

  return PlatformSpec(
    name: 'windows',
    icoOutputs: icoOutputs,
  );
}

// ──────────────────────────────────────────────────────────────
// macOS 平台規格
// ──────────────────────────────────────────────────────────────

PlatformSpec _buildMacosSpec() {
  final base = p.join(
    'macos', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset',
  );

  final iconOutputs = <IconOutput>[
    const IconOutput(width: 16, height: 16, layer: ImageLayer.merged, relativePath: 'icon_16x16.png'),
    const IconOutput(width: 32, height: 32, layer: ImageLayer.merged, relativePath: 'icon_16x16@2x.png'),
    const IconOutput(width: 32, height: 32, layer: ImageLayer.merged, relativePath: 'icon_32x32.png'),
    const IconOutput(width: 64, height: 64, layer: ImageLayer.merged, relativePath: 'icon_32x32@2x.png'),
    const IconOutput(width: 128, height: 128, layer: ImageLayer.merged, relativePath: 'icon_128x128.png'),
    const IconOutput(width: 256, height: 256, layer: ImageLayer.merged, relativePath: 'icon_128x128@2x.png'),
    const IconOutput(width: 256, height: 256, layer: ImageLayer.merged, relativePath: 'icon_256x256.png'),
    const IconOutput(width: 512, height: 512, layer: ImageLayer.merged, relativePath: 'icon_256x256@2x.png'),
    const IconOutput(width: 512, height: 512, layer: ImageLayer.merged, relativePath: 'icon_512x512.png'),
    const IconOutput(width: 1024, height: 1024, layer: ImageLayer.merged, relativePath: 'icon_512x512@2x.png'),
  ];

  final fullIconOutputs = iconOutputs.map((o) => IconOutput(
    relativePath: p.join(base, o.relativePath),
    width: o.width,
    height: o.height,
    layer: o.layer,
  )).toList();

  // macOS ICNS 多尺寸圖示，包含所有標準尺寸
  final icnsPath = p.join('macos', 'Runner', 'app_icon.icns');
  const icnsSizes = [16, 32, 64, 128, 256, 512, 1024];
  final icnsOutputs = <String, List<IconOutput>>{
    icnsPath: icnsSizes.map((size) => IconOutput(
      relativePath: icnsPath,
      width: size,
      height: size,
      layer: ImageLayer.merged,
    )).toList(),
  };

  return PlatformSpec(
    name: 'macos',
    iconOutputs: fullIconOutputs,
    icnsOutputs: icnsOutputs,
  );
}

// ──────────────────────────────────────────────────────────────
// Linux 平台規格
// ──────────────────────────────────────────────────────────────

PlatformSpec _buildLinuxSpec() {
  final iconOutputs = <IconOutput>[
    IconOutput(relativePath: p.join('linux', 'snap', 'gui', 'icon.png'), width: 256, height: 256, layer: ImageLayer.merged),
    IconOutput(relativePath: p.join('linux', 'snap', 'gui', 'snap-icon.png'), width: 256, height: 256, layer: ImageLayer.merged),
    IconOutput(relativePath: p.join('linux', 'flatpak', 'icon.png'), width: 256, height: 256, layer: ImageLayer.merged),
  ];

  return PlatformSpec(
    name: 'linux',
    iconOutputs: iconOutputs,
  );
}

// ──────────────────────────────────────────────────────────────
// 平台規格工廠函式
// ──────────────────────────────────────────────────────────────

/// 根據平台名稱取得對應的輸出規格。
///
/// 若平台名稱不支援則回傳 `null`。
PlatformSpec? getPlatformSpec(String platform) {
  switch (platform) {
    case 'android':
      return _buildAndroidSpec();
    case 'ios':
      return _buildIosSpec();
    case 'web':
      return _buildWebSpec();
    case 'windows':
      return _buildWindowsSpec();
    case 'macos':
      return _buildMacosSpec();
    case 'linux':
      return _buildLinuxSpec();
    default:
      return null;
  }
}
