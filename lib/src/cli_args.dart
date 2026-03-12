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
  /// 圖示圓角半徑（像素），null 表示根據 iOS 圓角比例自動計算。
  final double? radius;
  /// 前景圖邊距值（像素或百分比數值），null 表示使用預設值（10%）。
  final double? marginValue;
  /// 邊距是否為百分比模式。
  final bool marginIsPercent;

  CliArgs({
    required this.flutterProjectPath,
    required this.platforms,
    required this.listMode,
    required this.locale,
    this.iconSourcePath,
    this.backgroundSourcePath,
    this.backupPath,
    this.restorePath,
    this.radius,
    this.marginValue,
    this.marginIsPercent = false,
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

/// 標準化路徑中的分隔符，使輸入相容 \ 和 /，輸出統一使用 [Platform.pathSeparator]。
///
/// 保留 UNC 路徑前綴（例如 \\\\server\\share），
/// 並合併連續重複的分隔符為單一平台分隔符。
String normalizarRuta(String path) {
  // 保留 UNC 路徑前綴
  final isUnc = path.startsWith(r'\\');
  String processed;
  if (isUnc) {
    processed = path.substring(2);
  } else {
    processed = path;
  }

  // 將所有分隔符統一為平台分隔符
  processed = processed
      .replaceAll('/', Platform.pathSeparator)
      .replaceAll('\\', Platform.pathSeparator);

  // 合併連續重複的分隔符
  final doubleSep =
      '${Platform.pathSeparator}${Platform.pathSeparator}';
  while (processed.contains(doubleSep)) {
    processed = processed.replaceAll(doubleSep, Platform.pathSeparator);
  }

  // 還原 UNC 前綴
  if (isUnc) {
    processed = '${Platform.pathSeparator}${Platform.pathSeparator}$processed';
  }

  return processed;
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
    )
    ..addOption(
      'r',
      abbr: 'r',
      help: '图标圆角半径（像素），默认根据 iOS 圆角比例自动计算。仅对 iOS 以外的平台图标生效，启动画面不受影响',
      valueHelp: 'radius',
    )
    ..addOption(
      'm',
      abbr: 'm',
      help: '前景图距边缘的边距，支持像素（如 10）或百分比（如 10%），默认 10%',
      valueHelp: 'margin',
    );
  return parser;
}

CliArgs parseArgs(List<String> arguments) {
  final systemLocale = detectSystemLocale();
  final parser = buildArgParser(systemLocale);
  final results = parser.parse(arguments);

  final flutterPath = normalizarRuta(results['f'] as String);

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
  final iconPathRaw = results['i'] as String?;
  final iconPath = iconPathRaw != null ? normalizarRuta(iconPathRaw) : null;
  final backgroundPathRaw = results['b'] as String?;
  final backgroundPath = backgroundPathRaw != null ? normalizarRuta(backgroundPathRaw) : null;
  final backupPathRaw = results['backup'] as String?;
  final backupPath = backupPathRaw != null ? normalizarRuta(backupPathRaw) : null;
  final restorePathRaw = results['restore'] as String?;
  final restorePath = restorePathRaw != null ? normalizarRuta(restorePathRaw) : null;

  final lang = results['lang'] as String;
  final locale = localeFromString(lang);

  // 解析圓角半徑參數（選用，像素值）
  double? radius;
  final radiusRaw = results['r'] as String?;
  if (radiusRaw != null) {
    final parsed = double.tryParse(radiusRaw);
    if (parsed == null) {
      throw FormatException('圆角半径参数无效，必须为数字: $radiusRaw');
    }
    if (parsed < 0) {
      throw FormatException('圆角半径不能为负数: $radiusRaw');
    }
    radius = parsed;
  }

  // 解析邊距參數（選用，支援像素值如「10」或百分比如「10%」）
  double? marginValue;
  var marginIsPercent = false;
  final marginRaw = results['m'] as String?;
  if (marginRaw != null) {
    final trimmed = marginRaw.trim();
    if (trimmed.endsWith('%')) {
      final numStr = trimmed.substring(0, trimmed.length - 1);
      final parsed = double.tryParse(numStr);
      if (parsed == null) {
        throw FormatException('边距百分比无效: $marginRaw');
      }
      if (parsed < 0 || parsed > 100) {
        throw FormatException('边距百分比须在 0-100 之间: $marginRaw');
      }
      marginValue = parsed;
      marginIsPercent = true;
    } else {
      final parsed = double.tryParse(trimmed);
      if (parsed == null) {
        throw FormatException('边距参数无效，必须为数字或百分比（如 10 或 10%）: $marginRaw');
      }
      if (parsed < 0) {
        throw FormatException('边距不能为负数: $marginRaw');
      }
      marginValue = parsed;
    }
  }

  return CliArgs(
    flutterProjectPath: flutterPath,
    platforms: platforms,
    listMode: listMode,
    locale: locale,
    iconSourcePath: iconPath,
    backgroundSourcePath: backgroundPath,
    backupPath: backupPath,
    restorePath: restorePath,
    radius: radius,
    marginValue: marginValue,
    marginIsPercent: marginIsPercent,
  );
}
