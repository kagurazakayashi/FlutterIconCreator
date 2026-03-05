import 'locale.dart';

class AppStrings {
  final SupportedLocale locale;

  AppStrings(this.locale);

  factory AppStrings.fromCode(String code) {
    return AppStrings(localeFromString(code));
  }

  String get flutterProjectNotFound => _get(_flutterProjectNotFound);
  String get pubspecNotFound => _get(_pubspecNotFound);
  String get notFlutterProject => _get(_notFlutterProject);
  String get noPlatforms => _get(_noPlatforms);
  String get noSourceImages => _get(_noSourceImages);
  String get warningPrefix => _get(_warningPrefix);
  String get validationFailed => _get(_validationFailed);
  String get errorPrefix => _get(_errorPrefix);
  String get validationPassed => _get(_validationPassed);
  String get targetPlatforms => _get(_targetPlatforms);
  String get listMode => _get(_listMode);
  String get iconSourcePath => _get(_iconSourcePath);
  String get backgroundSourcePath => _get(_backgroundSourcePath);
  String get flutterProjectPath => _get(_flutterProjectPath);
  String get listModeHeader => _get(_listModeHeader);
  String get listModeIconFiles => _get(_listModeIconFiles);
  String get listModeSplashFiles => _get(_listModeSplashFiles);
  String get listModeNoFilesFound => _get(_listModeNoFilesFound);
  String get listModeForeground => _get(_listModeForeground);
  String get listModeBackground => _get(_listModeBackground);

  String parsePubspecError(Object error) =>
      _get(_parsePubspecError).replaceAll('{error}', error.toString());

  String invalidPlatform(String platform, String validList) => _get(_invalidPlatform)
      .replaceAll('{platform}', platform)
      .replaceAll('{platforms}', validList);

  String iconFileNotFound(String path) =>
      _get(_iconFileNotFound).replaceAll('{path}', path);

  String backgroundFileNotFound(String path) =>
      _get(_backgroundFileNotFound).replaceAll('{path}', path);

  String _get(Map<SupportedLocale, String> map) {
    return map[locale] ?? map[SupportedLocale.en]!;
  }
}

const _flutterProjectNotFound = {
  SupportedLocale.zhCN: 'Flutter 项目路径不存在: {path}',
  SupportedLocale.zhTW: 'Flutter 專案路徑不存在: {path}',
  SupportedLocale.en: 'Flutter project path not found: {path}',
  SupportedLocale.ja: 'Flutter プロジェクトパスが見つかりません: {path}',
};

const _pubspecNotFound = {
  SupportedLocale.zhCN: '未找到 pubspec.yaml，该路径可能不是 Flutter 项目: {path}',
  SupportedLocale.zhTW: '找不到 pubspec.yaml，該路徑可能不是 Flutter 專案: {path}',
  SupportedLocale.en: 'pubspec.yaml not found, the path may not be a Flutter project: {path}',
  SupportedLocale.ja: 'pubspec.yaml が見つかりません。このパスは Flutter プロジェクトではない可能性があります: {path}',
};

const _notFlutterProject = {
  SupportedLocale.zhCN: 'pubspec.yaml 中未找到 Flutter 依赖，该路径可能不是 Flutter 项目',
  SupportedLocale.zhTW: 'pubspec.yaml 中找不到 Flutter 依賴，該路徑可能不是 Flutter 專案',
  SupportedLocale.en: 'Flutter dependency not found in pubspec.yaml, the path may not be a Flutter project',
  SupportedLocale.ja: 'pubspec.yaml に Flutter 依存関係が見つかりません。このパスは Flutter プロジェクトではない可能性があります',
};

const _parsePubspecError = {
  SupportedLocale.zhCN: '无法解析 pubspec.yaml: {error}',
  SupportedLocale.zhTW: '無法解析 pubspec.yaml: {error}',
  SupportedLocale.en: 'Failed to parse pubspec.yaml: {error}',
  SupportedLocale.ja: 'pubspec.yaml を解析できません: {error}',
};

const _noPlatforms = {
  SupportedLocale.zhCN: '未指定任何平台',
  SupportedLocale.zhTW: '未指定任何平台',
  SupportedLocale.en: 'No platforms specified',
  SupportedLocale.ja: 'プラットフォームが指定されていません',
};

const _invalidPlatform = {
  SupportedLocale.zhCN: '不支持的平台: {platform}，有效值为: {platforms}',
  SupportedLocale.zhTW: '不支援的平台: {platform}，有效值為: {platforms}',
  SupportedLocale.en: 'Unsupported platform: {platform}, valid values: {platforms}',
  SupportedLocale.ja: 'サポートされていないプラットフォーム: {platform}、有効な値: {platforms}',
};

const _iconFileNotFound = {
  SupportedLocale.zhCN: '前景图标文件不存在: {path}',
  SupportedLocale.zhTW: '前景圖示檔案不存在: {path}',
  SupportedLocale.en: 'Icon source file not found: {path}',
  SupportedLocale.ja: '前景アイコンファイルが見つかりません: {path}',
};

const _backgroundFileNotFound = {
  SupportedLocale.zhCN: '背景图片文件不存在: {path}',
  SupportedLocale.zhTW: '背景圖片檔案不存在: {path}',
  SupportedLocale.en: 'Background image file not found: {path}',
  SupportedLocale.ja: '背景画像ファイルが見つかりません: {path}',
};

const _noSourceImages = {
  SupportedLocale.zhCN: '未提供源图片文件（-i 或 -b），不会生成任何图标',
  SupportedLocale.zhTW: '未提供來源圖片檔案（-i 或 -b），不會生成任何圖示',
  SupportedLocale.en: 'No source image provided (-i or -b), no icons will be generated',
  SupportedLocale.ja: 'ソース画像が指定されていません（-i または -b）、アイコンは生成されません',
};

const _warningPrefix = {
  SupportedLocale.zhCN: '警告',
  SupportedLocale.zhTW: '警告',
  SupportedLocale.en: 'Warning',
  SupportedLocale.ja: '警告',
};

const _validationFailed = {
  SupportedLocale.zhCN: '参数验证失败',
  SupportedLocale.zhTW: '參數驗證失敗',
  SupportedLocale.en: 'Validation failed',
  SupportedLocale.ja: '検証に失敗しました',
};

const _errorPrefix = {
  SupportedLocale.zhCN: '错误',
  SupportedLocale.zhTW: '錯誤',
  SupportedLocale.en: 'Error',
  SupportedLocale.ja: 'エラー',
};

const _validationPassed = {
  SupportedLocale.zhCN: '参数验证通过',
  SupportedLocale.zhTW: '參數驗證通過',
  SupportedLocale.en: 'Validation passed',
  SupportedLocale.ja: '検証に合格しました',
};

const _flutterProjectPath = {
  SupportedLocale.zhCN: 'Flutter 项目路径',
  SupportedLocale.zhTW: 'Flutter 專案路徑',
  SupportedLocale.en: 'Flutter project path',
  SupportedLocale.ja: 'Flutter プロジェクトパス',
};

const _targetPlatforms = {
  SupportedLocale.zhCN: '目标平台',
  SupportedLocale.zhTW: '目標平台',
  SupportedLocale.en: 'Target platforms',
  SupportedLocale.ja: '対象プラットフォーム',
};

const _listMode = {
  SupportedLocale.zhCN: '列表扫描',
  SupportedLocale.zhTW: '列表掃描',
  SupportedLocale.en: 'List mode',
  SupportedLocale.ja: 'リストモード',
};

const _iconSourcePath = {
  SupportedLocale.zhCN: '前景图标源文件',
  SupportedLocale.zhTW: '前景圖示來源檔案',
  SupportedLocale.en: 'Icon source file',
  SupportedLocale.ja: '前景アイコンソースファイル',
};

const _backgroundSourcePath = {
  SupportedLocale.zhCN: '背景图标源文件',
  SupportedLocale.zhTW: '背景圖示來源檔案',
  SupportedLocale.en: 'Background source file',
  SupportedLocale.ja: '背景画像ソースファイル',
};

const _listModeHeader = {
  SupportedLocale.zhCN: '列表扫描模式 - 列出所有图标和启动图片文件',
  SupportedLocale.zhTW: '列表掃描模式 - 列出所有圖示和啟動圖片檔案',
  SupportedLocale.en: 'List mode - Listing all icon and splash files',
  SupportedLocale.ja: 'リストモード - 全アイコンとスプラッシュファイルを一覧表示',
};

const _listModeIconFiles = {
  SupportedLocale.zhCN: '图标',
  SupportedLocale.zhTW: '圖示',
  SupportedLocale.en: 'Icon',
  SupportedLocale.ja: 'アイコン',
};

const _listModeSplashFiles = {
  SupportedLocale.zhCN: '启动图片',
  SupportedLocale.zhTW: '啟動圖片',
  SupportedLocale.en: 'Splash',
  SupportedLocale.ja: 'スプラッシュ',
};

const _listModeNoFilesFound = {
  SupportedLocale.zhCN: '(无)',
  SupportedLocale.zhTW: '(無)',
  SupportedLocale.en: '(none)',
  SupportedLocale.ja: '(なし)',
};

const _listModeForeground = {
  SupportedLocale.zhCN: '前景',
  SupportedLocale.zhTW: '前景',
  SupportedLocale.en: 'Foreground',
  SupportedLocale.ja: '前景',
};

const _listModeBackground = {
  SupportedLocale.zhCN: '背景',
  SupportedLocale.zhTW: '背景',
  SupportedLocale.en: 'Background',
  SupportedLocale.ja: '背景',
};
