import 'dart:convert';
import 'dart:io' show File, stdout;

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'cli_args.dart';
import 'i18n/strings.dart';
import 'scanner.dart';

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
  stdout.writeln(encoder.convert(result));
}

/// 掃描單一平台並回傳 JSON 相容的資料結構。
Map<String, dynamic> _scanPlatformToJson(
    String projectPath, String platform, AppStrings s) {
  final scanned = scanPlatform(projectPath, platform, s);

  return {
    'icons': _filesToJson(scanned.icons, projectPath, platform),
    'splash': _filesToJson(scanned.splash, projectPath, platform),
  };
}

/// 將掃描到的檔案清單轉換為 JSON 陣列。
List<Map<String, dynamic>> _filesToJson(
    List<ScannedFile> files, String projectPath, String platform) {
  final basePath = p.join(projectPath, platform);
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
({int? width, int? height}) _getImageDimensions(File file) {
  try {
    final bytes = file.readAsBytesSync();
    final image = img.decodeImage(bytes);
    if (image != null) {
      return (width: image.width, height: image.height);
    }
    final ext = p.extension(file.path).toLowerCase();
    if (ext == '.ico') {
      final ico = img.decodeIco(bytes);
      if (ico != null) {
        return (width: ico.width, height: ico.height);
      }
    }
  } catch (_) {}
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
