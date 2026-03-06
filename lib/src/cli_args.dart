import 'dart:io';

import 'package:args/args.dart';

import 'i18n/locale.dart';

class CliArgs {
  final String flutterProjectPath;
  final List<String> platforms;
  final bool listMode;
  final String? iconSourcePath;
  final String? backgroundSourcePath;
  final String? backupPath;
  final String? restorePath;
  final SupportedLocale locale;

  CliArgs({
    required this.flutterProjectPath,
    required this.platforms,
    required this.listMode,
    required this.locale,
    this.iconSourcePath,
    this.backgroundSourcePath,
    this.backupPath,
    this.restorePath,
  });
}

const Set<String> validPlatforms = {
  'android',
  'ios',
  'web',
  'windows',
  'macos',
  'linux',
};

SupportedLocale detectSystemLocale() {
  try {
    return localeFromString(Platform.localeName);
  } catch (_) {
    return SupportedLocale.en;
  }
}

ArgParser buildArgParser(SupportedLocale defaultLocale) {
  final parser = ArgParser()
    ..addOption(
      'f',
      abbr: 'f',
      help: 'Flutter 项目根目录路径',
      valueHelp: 'path',
      mandatory: true,
    )
    ..addOption(
      'p',
      abbr: 'p',
      help: '要处理的平台，逗号分隔 (${validPlatforms.join(',')})，默认 all',
      valueHelp: 'platforms',
      defaultsTo: 'all',
    )
    ..addFlag(
      'l',
      abbr: 'l',
      help: '扫描并列出所选平台的所有图标和启动图片文件，不做实际转换',
      negatable: false,
    )
    ..addOption(
      'i',
      abbr: 'i',
      help: '前景图标源图片文件路径',
      valueHelp: 'path',
    )
    ..addOption(
      'b',
      abbr: 'b',
      help: '背景图标源图片文件路径',
      valueHelp: 'path',
    )
    ..addOption(
      'backup',
      help: '备份扫描到的图标文件到指定目录',
      valueHelp: 'path',
    )
    ..addOption(
      'restore',
      help: '从备份目录恢复图标文件到 Flutter 项目中',
      valueHelp: 'path',
    )
    ..addOption(
      'lang',
      help: '输出语言 (zh_CN, zh_TW, en, ja)，默认跟随系统语言',
      valueHelp: 'locale',
      defaultsTo: localeToCode(defaultLocale),
      allowed: ['zh_CN', 'zh_TW', 'en', 'ja'],
    );
  return parser;
}

CliArgs parseArgs(List<String> arguments) {
  final systemLocale = detectSystemLocale();
  final parser = buildArgParser(systemLocale);
  final results = parser.parse(arguments);

  final flutterPath = results['f'] as String;

  final platformsRaw = results['p'] as String;
  List<String> platforms;
  if (platformsRaw == 'all') {
    platforms = validPlatforms.toList();
  } else {
    platforms = platformsRaw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  final listMode = results['l'] as bool;
  final iconPath = results['i'] as String?;
  final backgroundPath = results['b'] as String?;
  final backupPath = results['backup'] as String?;
  final restorePath = results['restore'] as String?;

  final lang = results['lang'] as String;
  final locale = localeFromString(lang);

  return CliArgs(
    flutterProjectPath: flutterPath,
    platforms: platforms,
    listMode: listMode,
    locale: locale,
    iconSourcePath: iconPath,
    backgroundSourcePath: backgroundPath,
    backupPath: backupPath,
    restorePath: restorePath,
  );
}
