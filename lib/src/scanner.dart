import 'dart:io';

import 'package:path/path.dart' as p;

import 'i18n/strings.dart';

/// 掃描到的檔案及其分類標籤（前景/背景/無）。
typedef ScannedFile = ({
  File file,
  String? tag,
});

/// 圖片檔案副檔名白名單。
const imageExtensions = {
  '.png',
  '.jpg',
  '.jpeg',
  '.webp',
  '.ico',
  '.icns',
  '.bmp',
  '.gif',
};

/// 判斷檔案是否為圖片檔案（根據副檔名）。
bool isImageFile(String filePath) {
  final ext = p.extension(filePath).toLowerCase();
  return imageExtensions.contains(ext);
}

/// 根據檔案名稱偵測前景／背景標籤。
///
/// 回傳對應的 i18n 字串，若無法判斷則回傳 `null`。
String? detectTag(String fileName, AppStrings s) {
  final lower = fileName.toLowerCase();
  if (lower.contains('foreground') || lower.contains('_fore')) {
    return s.listModeForeground;
  }
  if (lower.contains('background') || lower.contains('_back')) {
    return s.listModeBackground;
  }
  return null;
}

/// 輔助函式：建立 ScannedFile 並附加標籤。
ScannedFile toScannedFile(File file, AppStrings s) {
  return (file: file, tag: detectTag(p.basename(file.path), s));
}

/// 掃描指定平台的圖示與啟動圖片檔案。
///
/// 回傳 `(icons, splash)` 兩個清單。
({List<ScannedFile> icons, List<ScannedFile> splash}) scanPlatform(
    String projectPath, String platform, AppStrings s) {
  final basePath = p.join(projectPath, platform);
  final dir = Directory(basePath);
  final iconFiles = <ScannedFile>[];
  final splashFiles = <ScannedFile>[];

  if (!dir.existsSync()) {
    return (icons: iconFiles, splash: splashFiles);
  }

  switch (platform) {
    case 'android':
      _scanAndroid(basePath, iconFiles, splashFiles, s);
      break;
    case 'ios':
      _scanIos(basePath, iconFiles, splashFiles, s);
      break;
    case 'web':
      _scanWeb(basePath, iconFiles, splashFiles, s);
      break;
    case 'windows':
      _scanWindows(basePath, iconFiles, splashFiles, s);
      break;
    case 'macos':
      _scanMacos(basePath, iconFiles, splashFiles, s);
      break;
    case 'linux':
      _scanLinux(basePath, iconFiles, splashFiles, s);
      break;
  }

  return (icons: iconFiles, splash: splashFiles);
}

/// 掃描 Android 平台的圖示與啟動圖片。
void _scanAndroid(String basePath, List<ScannedFile> iconFiles,
    List<ScannedFile> splashFiles, AppStrings s) {
  final resPath = p.join(basePath, 'app', 'src', 'main', 'res');
  final resDir = Directory(resPath);
  if (!resDir.existsSync()) return;

  final mipmapPattern = RegExp(r'^mipmap');
  for (final entity in resDir.listSync()) {
    if (entity is! Directory) continue;
    final dirName = p.basename(entity.path);
    if (!mipmapPattern.hasMatch(dirName)) continue;

    for (final file in entity.listSync()) {
      if (file is File) {
        final fileName = p.basename(file.path);
        if (fileName.startsWith('ic_launcher') && isImageFile(fileName)) {
          iconFiles.add(toScannedFile(file.absolute, s));
        }
      }
    }
  }

  final drawablePattern = RegExp(r'^drawable');
  for (final entity in resDir.listSync()) {
    if (entity is! Directory) continue;
    final dirName = p.basename(entity.path);
    if (!drawablePattern.hasMatch(dirName)) continue;

    for (final file in entity.listSync()) {
      if (file is File) {
        final fileName = p.basename(file.path);
        if (fileName.startsWith('launch_background') && isImageFile(fileName)) {
          splashFiles.add(toScannedFile(file.absolute, s));
        }
      }
    }
  }
}

/// 掃描 iOS 平台的圖示與啟動圖片。
void _scanIos(String basePath, List<ScannedFile> iconFiles,
    List<ScannedFile> splashFiles, AppStrings s) {
  final runnerPath = p.join(basePath, 'Runner');

  final appIconPath =
      p.join(runnerPath, 'Assets.xcassets', 'AppIcon.appiconset');
  final appIconDir = Directory(appIconPath);
  if (appIconDir.existsSync()) {
    for (final entity in appIconDir.listSync()) {
      if (entity is File && isImageFile(entity.path)) {
        iconFiles.add(toScannedFile(entity.absolute, s));
      }
    }
  }

  final launchImagePath =
      p.join(runnerPath, 'Assets.xcassets', 'LaunchImage.imageset');
  final launchImageDir = Directory(launchImagePath);
  if (launchImageDir.existsSync()) {
    for (final entity in launchImageDir.listSync()) {
      if (entity is File && isImageFile(entity.path)) {
        splashFiles.add(toScannedFile(entity.absolute, s));
      }
    }
  }
}

/// 掃描 Web 平台的圖示與啟動圖片。
void _scanWeb(String basePath, List<ScannedFile> iconFiles,
    List<ScannedFile> splashFiles, AppStrings s) {
  final faviconFile = File(p.join(basePath, 'favicon.png'));
  if (faviconFile.existsSync()) {
    iconFiles.add(toScannedFile(faviconFile.absolute, s));
  }

  final iconsDir = Directory(p.join(basePath, 'icons'));
  if (iconsDir.existsSync()) {
    for (final entity in iconsDir.listSync()) {
      if (entity is File && isImageFile(entity.path)) {
        final name = p.basename(entity.path);
        if (name.startsWith('Icon-')) {
          iconFiles.add(toScannedFile(entity.absolute, s));
        } else if (name.toLowerCase().contains('splash')) {
          splashFiles.add(toScannedFile(entity.absolute, s));
        }
      }
    }
  }
}

/// 掃描 Windows 平台的圖示。
void _scanWindows(String basePath, List<ScannedFile> iconFiles,
    List<ScannedFile> splashFiles, AppStrings s) {
  final iconPath = p.join(basePath, 'runner', 'resources', 'app_icon.ico');
  final iconFile = File(iconPath);
  if (iconFile.existsSync()) {
    iconFiles.add(toScannedFile(iconFile.absolute, s));
  }
}

/// 掃描 macOS 平台的圖示。
void _scanMacos(String basePath, List<ScannedFile> iconFiles,
    List<ScannedFile> splashFiles, AppStrings s) {
  final appIconPath =
      p.join(basePath, 'Runner', 'Assets.xcassets', 'AppIcon.appiconset');
  final appIconDir = Directory(appIconPath);
  if (appIconDir.existsSync()) {
    for (final entity in appIconDir.listSync()) {
      if (entity is File && isImageFile(entity.path)) {
        iconFiles.add(toScannedFile(entity.absolute, s));
      }
    }
  }

  final icnsPath = p.join(basePath, 'Runner', 'app_icon.icns');
  final icnsFile = File(icnsPath);
  if (icnsFile.existsSync()) {
    iconFiles.add(toScannedFile(icnsFile.absolute, s));
  }
}

/// 掃描 Linux 平台的圖示。
void _scanLinux(String basePath, List<ScannedFile> iconFiles,
    List<ScannedFile> splashFiles, AppStrings s) {
  void checkFile(String relativePath) {
    final file = File(p.join(basePath, relativePath));
    if (file.existsSync()) {
      iconFiles.add(toScannedFile(file.absolute, s));
    }
  }

  checkFile(p.join('snap', 'gui', 'icon.png'));
  checkFile(p.join('snap', 'gui', 'snap-icon.png'));
  checkFile(p.join('flatpak', 'icon.png'));
}
