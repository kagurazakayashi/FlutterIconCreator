import 'dart:io' show Directory, File, stdout, stderr;

import 'package:path/path.dart' as p;

import 'cli_args.dart';
import 'i18n/strings.dart';
import 'scanner.dart';

/// 備份模式：掃描並將所有圖示與啟動圖片檔案複製到備份目錄。
void runBackup(CliArgs args) {
  final s = AppStrings(args.locale);
  final projectPath = args.flutterProjectPath;
  final backupDirPath = args.backupPath!;

  // 建立備份根目錄
  Directory(backupDirPath).createSync(recursive: true);

  var totalFiles = 0;

  for (final platform in args.platforms) {
    final scanned = scanPlatform(projectPath, platform, s);
    final allFiles = [...scanned.icons, ...scanned.splash];
    if (allFiles.isEmpty) continue;

    final platformBackupDir = p.join(backupDirPath, platform);
    Directory(platformBackupDir).createSync(recursive: true);

    final platformBasePath = p.join(projectPath, platform);
    var platformCount = 0;

    for (final sf in allFiles) {
      // 計算檔案相對於平台根目錄的路徑
      final relativePath = p.relative(sf.file.path, from: platformBasePath);
      final targetPath = p.join(platformBackupDir, relativePath);

      // 建立目標目錄（若不存在）
      Directory(p.dirname(targetPath)).createSync(recursive: true);

      // 複製檔案
      sf.file.copySync(targetPath);
      platformCount++;
    }

    totalFiles += platformCount;

    // 根據複製數量顯示不同方式的回報
    if (platformCount == 1) {
      stdout.writeln(s.backupSingleFile(platform, platformCount, backupDirPath));
    } else {
      stdout.writeln(s.backupMultipleFiles(platform, platformCount, backupDirPath));
    }
  }

  stdout.writeln('');
  if (totalFiles == 0) {
    stdout.writeln(s.backupNoFiles);
  } else {
    stdout.writeln(s.backupComplete(totalFiles, backupDirPath));
  }
}

/// 還原模式：從備份目錄將檔案複製回 Flutter 專案。
void runRestore(CliArgs args) {
  final s = AppStrings(args.locale);
  final projectPath = args.flutterProjectPath;
  final restoreDirPath = args.restorePath!;

  final restoreDir = Directory(restoreDirPath);
  if (!restoreDir.existsSync()) {
    stderr.writeln(s.restoreDirNotFound(restoreDirPath));
    return;
  }

  var totalFiles = 0;

  // 遍歷備份目錄下的每個平台子目錄
  for (final entity in restoreDir.listSync()) {
    if (entity is! Directory) continue;
    final platform = p.basename(entity.path);

    // 跳過非平台目錄
    if (!validPlatforms.contains(platform)) continue;

    final platformRestoreDir = entity.path;
    final platformTargetDir = p.join(projectPath, platform);
    var platformCount = 0;

    // 遞迴複製該平台目錄下的所有檔案
    final files = _listAllFiles(Directory(platformRestoreDir));
    for (final file in files) {
      final relativePath = p.relative(file.path, from: platformRestoreDir);
      final targetPath = p.join(platformTargetDir, relativePath);

      // 建立目標目錄
      Directory(p.dirname(targetPath)).createSync(recursive: true);

      // 複製檔案（覆蓋已存在的檔案）
      file.copySync(targetPath);
      platformCount++;
    }

    totalFiles += platformCount;

    if (platformCount == 1) {
      stdout.writeln(s.restoreSingleFile(platform, platformCount));
    } else {
      stdout.writeln(s.restoreMultipleFiles(platform, platformCount));
    }
  }

  stdout.writeln('');
  if (totalFiles == 0) {
    stdout.writeln(s.restoreNoFiles);
  } else {
    stdout.writeln(s.restoreComplete(totalFiles));
  }
}

/// 遞迴列出目錄下所有檔案。
List<File> _listAllFiles(Directory dir) {
  final files = <File>[];
  if (!dir.existsSync()) return files;

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File) {
      files.add(entity.absolute);
    }
  }
  return files;
}
