import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'cli_args.dart';
import 'i18n/strings.dart';

/// 掃描到的檔案及其分類標籤（前景/背景/無）。
typedef ScannedFile = ({
  File file,
  String? tag,
});

/// 列表掃描模式：掃描並列出所選平台的所有圖示與啟動圖片檔案。
///
/// [args] 為已解析的命令列參數，包含 Flutter 專案路徑、目標平台等。
/// 輸出格式為 JSON。
void runListMode(CliArgs args) {
  final s = AppStrings(args.locale);
  final projectPath = args.flutterProjectPath;
  final result = <String, Map<String, dynamic>>{};

  // 逐一掃描每個目標平台
  for (final platform in args.platforms) {
    result[platform] = _scanPlatformToJson(projectPath, platform, s);
  }

  // 輸出格式化 JSON
  const encoder = JsonEncoder.withIndent('  ');
  print(encoder.convert(result));
}

/// 掃描單一平台並回傳 JSON 相容的資料結構。
Map<String, dynamic> _scanPlatformToJson(
    String projectPath, String platform, AppStrings s) {
  final basePath = p.join(projectPath, platform);
  final dir = Directory(basePath);
  if (!dir.existsSync()) {
    return {'icons': <Map<String, dynamic>>[], 'splash': <Map<String, dynamic>>[]};
  }

  final iconFiles = <ScannedFile>[];
  final splashFiles = <ScannedFile>[];

  // 根據平台類型呼叫對應的掃描函式
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

  return {
    'icons': _filesToJson(iconFiles, basePath),
    'splash': _filesToJson(splashFiles, basePath),
  };
}

/// 將掃描到的檔案清單轉換為 JSON 陣列。
List<Map<String, dynamic>> _filesToJson(
    List<ScannedFile> files, String basePath) {
  return files.map((sf) {
    final map = _fileToJson(sf.file, basePath);
    if (sf.tag != null) {
      map['tag'] = sf.tag;
    }
    return map;
  }).toList();
}

/// 將單一檔案轉換為 JSON 物件。
Map<String, dynamic> _fileToJson(File file, String basePath) {
  final stat = file.statSync();
  final dims = _getImageDimensions(file);
  final d = stat.modified;
  return {
    'path': p.relative(file.path, from: basePath),
    if (dims.width != null && dims.height != null)
      'size': '${dims.width}x${dims.height}',
    'fileSize': _formatSize(stat.size),
    'modified':
        '${d.year}-${_pad(d.month)}-${_pad(d.day)} ${_pad(d.hour)}:${_pad(d.minute)}',
  };
}

/// 解析圖片的實際尺寸（像素）。
///
/// 回傳 `(width, height)`，若無法解析則回傳 `(null, null)`。
({int? width, int? height}) _getImageDimensions(File file) {
  try {
    final bytes = file.readAsBytesSync();
    final image = img.decodeImage(bytes);
    if (image != null) {
      return (width: image.width, height: image.height);
    }

    // decodeImage 可能無法處理某些格式（如 ICO 的 decodeImage）
    // 嘗試使用 decodeIco 處理 Windows 圖示檔案
    final ext = p.extension(file.path).toLowerCase();
    if (ext == '.ico') {
      final ico = img.decodeIco(bytes);
      if (ico != null) {
        return (width: ico.width, height: ico.height);
      }
    }
  } catch (_) {
    // 非圖片檔案或無法解析
  }
  return (width: null, height: null);
}

/// 將檔案大小轉換為人類可讀格式（B / KB / MB）。
String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// 數字補零（個位數前補 0）。
String _pad(int n) => n.toString().padLeft(2, '0');

/// 圖片檔案副檔名白名單。
const _imageExtensions = {
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
bool _isImageFile(String filePath) {
  final ext = p.extension(filePath).toLowerCase();
  return _imageExtensions.contains(ext);
}

/// 根據檔案名稱偵測前景／背景標籤。
///
/// 回傳對應的 i18n 字串，若無法判斷則回傳 `null`。
String? _detectTag(String fileName, AppStrings s) {
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
ScannedFile _toScannedFile(File file, AppStrings s) {
  return (file: file, tag: _detectTag(p.basename(file.path), s));
}

/// 掃描 Android 平台的圖示與啟動圖片。
///
/// Android 圖示位於 res/mipmap-* 目錄，啟動圖片位於 res/drawable* 目錄。
/// Android 自適應圖示可能區分前景（foreground）與背景（background）。
void _scanAndroid(String basePath, List<ScannedFile> iconFiles,
    List<ScannedFile> splashFiles, AppStrings s) {
  final resPath = p.join(basePath, 'app', 'src', 'main', 'res');
  final resDir = Directory(resPath);
  if (!resDir.existsSync()) return;

  // 掃描 mipmap 目錄中的啟動器圖示（ic_launcher 開頭的檔案）
  final mipmapPattern = RegExp(r'^mipmap');
  for (final entity in resDir.listSync()) {
    if (entity is! Directory) continue;
    final dirName = p.basename(entity.path);
    if (!mipmapPattern.hasMatch(dirName)) continue;

    for (final file in entity.listSync()) {
      if (file is File) {
        final fileName = p.basename(file.path);
        if (fileName.startsWith('ic_launcher') && _isImageFile(fileName)) {
          iconFiles.add(_toScannedFile(file.absolute, s));
        }
      }
    }
  }

  // 掃描 drawable 目錄中的啟動背景圖片檔案
  final drawablePattern = RegExp(r'^drawable');
  for (final entity in resDir.listSync()) {
    if (entity is! Directory) continue;
    final dirName = p.basename(entity.path);
    if (!drawablePattern.hasMatch(dirName)) continue;

    for (final file in entity.listSync()) {
      if (file is File) {
        final fileName = p.basename(file.path);
        if (fileName.startsWith('launch_background') && _isImageFile(fileName)) {
          splashFiles.add(_toScannedFile(file.absolute, s));
        }
      }
    }
  }
}

/// 掃描 iOS 平台的圖示與啟動圖片。
///
/// iOS 圖示位於 Assets.xcassets/AppIcon.appiconset，
/// 啟動圖片位於 LaunchImage.imageset。
/// 排除 Contents.json 等非圖片檔案。
void _scanIos(String basePath, List<ScannedFile> iconFiles,
    List<ScannedFile> splashFiles, AppStrings s) {
  final runnerPath = p.join(basePath, 'Runner');

  final appIconPath =
      p.join(runnerPath, 'Assets.xcassets', 'AppIcon.appiconset');
  final appIconDir = Directory(appIconPath);
  if (appIconDir.existsSync()) {
    for (final entity in appIconDir.listSync()) {
      if (entity is File && _isImageFile(entity.path)) {
        iconFiles.add(_toScannedFile(entity.absolute, s));
      }
    }
  }

  final launchImagePath =
      p.join(runnerPath, 'Assets.xcassets', 'LaunchImage.imageset');
  final launchImageDir = Directory(launchImagePath);
  if (launchImageDir.existsSync()) {
    for (final entity in launchImageDir.listSync()) {
      if (entity is File && _isImageFile(entity.path)) {
        splashFiles.add(_toScannedFile(entity.absolute, s));
      }
    }
  }
}

/// 掃描 Web 平台的圖示與啟動圖片。
///
/// Web 圖示包括 favicon.png 與 icons 目錄下的圖片檔案，
/// 排除 manifest.json 等非圖片配置檔案。
void _scanWeb(String basePath, List<ScannedFile> iconFiles,
    List<ScannedFile> splashFiles, AppStrings s) {
  final faviconFile = File(p.join(basePath, 'favicon.png'));
  if (faviconFile.existsSync()) {
    iconFiles.add(_toScannedFile(faviconFile.absolute, s));
  }

  final iconsDir = Directory(p.join(basePath, 'icons'));
  if (iconsDir.existsSync()) {
    for (final entity in iconsDir.listSync()) {
      if (entity is File && _isImageFile(entity.path)) {
        final name = p.basename(entity.path);
        if (name.startsWith('Icon-')) {
          iconFiles.add(_toScannedFile(entity.absolute, s));
        } else if (name.toLowerCase().contains('splash')) {
          splashFiles.add(_toScannedFile(entity.absolute, s));
        }
      }
    }
  }
}

/// 掃描 Windows 平台的圖示。
///
/// Windows 圖示位於 runner/resources/app_icon.ico。
void _scanWindows(String basePath, List<ScannedFile> iconFiles,
    List<ScannedFile> splashFiles, AppStrings s) {
  final iconPath = p.join(basePath, 'runner', 'resources', 'app_icon.ico');
  final iconFile = File(iconPath);
  if (iconFile.existsSync()) {
    iconFiles.add(_toScannedFile(iconFile.absolute, s));
  }
}

/// 掃描 macOS 平台的圖示。
///
/// macOS 圖示位於 Assets.xcassets/AppIcon.appiconset，
/// 以及可能的 .icns 檔案。
void _scanMacos(String basePath, List<ScannedFile> iconFiles,
    List<ScannedFile> splashFiles, AppStrings s) {
  final appIconPath =
      p.join(basePath, 'Runner', 'Assets.xcassets', 'AppIcon.appiconset');
  final appIconDir = Directory(appIconPath);
  if (appIconDir.existsSync()) {
    for (final entity in appIconDir.listSync()) {
      if (entity is File && _isImageFile(entity.path)) {
        iconFiles.add(_toScannedFile(entity.absolute, s));
      }
    }
  }

  final icnsPath = p.join(basePath, 'Runner', 'app_icon.icns');
  final icnsFile = File(icnsPath);
  if (icnsFile.existsSync()) {
    iconFiles.add(_toScannedFile(icnsFile.absolute, s));
  }
}

/// 掃描 Linux 平台的圖示。
///
/// Linux 沒有標準化的圖示位置，檢查常見的 Snap/Flatpak 圖示路徑。
void _scanLinux(String basePath, List<ScannedFile> iconFiles,
    List<ScannedFile> splashFiles, AppStrings s) {
  void checkFile(String relativePath) {
    final file = File(p.join(basePath, relativePath));
    if (file.existsSync()) {
      iconFiles.add(_toScannedFile(file.absolute, s));
    }
  }

  checkFile(p.join('snap', 'gui', 'icon.png'));
  checkFile(p.join('snap', 'gui', 'snap-icon.png'));
  checkFile(p.join('flatpak', 'icon.png'));
}
