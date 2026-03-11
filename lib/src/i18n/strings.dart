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
  String get backupRestoreConflict => _get(_backupRestoreConflict);
  String get backupNoFiles => _get(_backupNoFiles);
  String get restoreNoFiles => _get(_restoreNoFiles);
  String get decodeImageFailedPrefix => _get(_decodeImageFailedPrefix);

  String get layerTypeForeground => _get(_layerTypeForeground);
  String get layerTypeBackground => _get(_layerTypeBackground);
  String get layerTypeMerged => _get(_layerTypeMerged);
  String get layerTypeWhiteBase => _get(_layerTypeWhiteBase);
  String get newFileLabel => _get(_newFileLabel);

  String parsePubspecError(Object error) =>
      _get(_parsePubspecError).replaceAll('{error}', error.toString());

  String invalidPlatform(String platform, String validList) => _get(_invalidPlatform)
      .replaceAll('{platform}', platform)
      .replaceAll('{platforms}', validList);

  String iconFileNotFound(String path) =>
      _get(_iconFileNotFound).replaceAll('{path}', path);

  String backgroundFileNotFound(String path) =>
      _get(_backgroundFileNotFound).replaceAll('{path}', path);

  String backupSingleFile(String platform, int count, String backupDir) =>
      _get(_backupSingleFile)
          .replaceAll('{platform}', platform)
          .replaceAll('{count}', count.toString())
          .replaceAll('{dir}', backupDir);

  String backupMultipleFiles(String platform, int count, String backupDir) =>
      _get(_backupMultipleFiles)
          .replaceAll('{platform}', platform)
          .replaceAll('{count}', count.toString())
          .replaceAll('{dir}', backupDir);

  String backupComplete(int total, String backupDir) =>
      _get(_backupComplete)
          .replaceAll('{total}', total.toString())
          .replaceAll('{dir}', backupDir);

  String restoreSingleFile(String platform, int count) =>
      _get(_restoreSingleFile)
          .replaceAll('{platform}', platform)
          .replaceAll('{count}', count.toString());

  String restoreMultipleFiles(String platform, int count) =>
      _get(_restoreMultipleFiles)
          .replaceAll('{platform}', platform)
          .replaceAll('{count}', count.toString());

  String restoreComplete(int total) =>
      _get(_restoreComplete).replaceAll('{total}', total.toString());

  String restoreDirNotFound(String path) =>
      _get(_restoreDirNotFound).replaceAll('{path}', path);

  String decodeImageFailed(String path) =>
      _get(_decodeImageFailedPrefix).replaceAll('{path}', path);

  String procesandoPlatforma(String platform) =>
      _get(_procesandoPlatforma).replaceAll('{platform}', platform);

  String skippingLayerFg(String path) =>
      _get(_skippingLayerFg).replaceAll('{path}', path);

  String skippingLayerBg(String path) =>
      _get(_skippingLayerBg).replaceAll('{path}', path);

  String generandoIcono(String path, int width, int height) =>
      _get(_generandoIcono)
          .replaceAll('{path}', path)
          .replaceAll('{width}', width.toString())
          .replaceAll('{height}', height.toString());

  String generandoIconoDetalle(String path, int width, int height, String type, String oldSize, String newSize) =>
      _get(_generandoIconoDetalle)
          .replaceAll('{path}', path)
          .replaceAll('{width}', width.toString())
          .replaceAll('{height}', height.toString())
          .replaceAll('{type}', type)
          .replaceAll('{oldSize}', oldSize)
          .replaceAll('{newSize}', newSize);

  String generandoIco(String path) =>
      _get(_generandoIco).replaceAll('{path}', path);

  String generandoIcoDetalle(String path, String type, String oldSize, String newSize) =>
      _get(_generandoIcoDetalle)
          .replaceAll('{path}', path)
          .replaceAll('{type}', type)
          .replaceAll('{oldSize}', oldSize)
          .replaceAll('{newSize}', newSize);

  String generacionCompletada(int count) =>
      _get(_generacionCompletada).replaceAll('{count}', count.toString());

  String writeError(String path, String error) =>
      _get(_writeError)
          .replaceAll('{path}', path)
          .replaceAll('{error}', error);

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

const _backupRestoreConflict = {
  SupportedLocale.zhCN: '--backup 与 --restore 不能同时使用',
  SupportedLocale.zhTW: '--backup 與 --restore 不能同時使用',
  SupportedLocale.en: '--backup and --restore cannot be used together',
  SupportedLocale.ja: '--backup と --restore は同時に使用できません',
};

const _restoreDirNotFound = {
  SupportedLocale.zhCN: '备份目录不存在: {path}',
  SupportedLocale.zhTW: '備份目錄不存在: {path}',
  SupportedLocale.en: 'Backup directory not found: {path}',
  SupportedLocale.ja: 'バックアップディレクトリが見つかりません: {path}',
};

const _backupSingleFile = {
  SupportedLocale.zhCN: '{platform}：已备份 {count} 个文件至 {dir}',
  SupportedLocale.zhTW: '{platform}：已備份 {count} 個檔案至 {dir}',
  SupportedLocale.en: '{platform}: {count} file backed up to {dir}',
  SupportedLocale.ja: '{platform}：{count} ファイルを {dir} にバックアップしました',
};

const _backupMultipleFiles = {
  SupportedLocale.zhCN: '{platform}：已备份 {count} 个文件至 {dir}',
  SupportedLocale.zhTW: '{platform}：已備份 {count} 個檔案至 {dir}',
  SupportedLocale.en: '{platform}: {count} files backed up to {dir}',
  SupportedLocale.ja: '{platform}：{count} ファイルを {dir} にバックアップしました',
};

const _backupComplete = {
  SupportedLocale.zhCN: '备份完成，共 {total} 个文件已保存至 {dir}',
  SupportedLocale.zhTW: '備份完成，共 {total} 個檔案已儲存至 {dir}',
  SupportedLocale.en: 'Backup complete, {total} file(s) saved to {dir}',
  SupportedLocale.ja: 'バックアップ完了、{total} ファイルを {dir} に保存しました',
};

const _backupNoFiles = {
  SupportedLocale.zhCN: '未找到任何图标或启动图片文件，未执行备份',
  SupportedLocale.zhTW: '未找到任何圖示或啟動圖片檔案，未執行備份',
  SupportedLocale.en: 'No icon or splash files found, no backup performed',
  SupportedLocale.ja: 'アイコンまたはスプラッシュファイルが見つかりません。バックアップは実行されませんでした',
};

const _restoreSingleFile = {
  SupportedLocale.zhCN: '{platform}：已还原 {count} 个文件',
  SupportedLocale.zhTW: '{platform}：已還原 {count} 個檔案',
  SupportedLocale.en: '{platform}: {count} file restored',
  SupportedLocale.ja: '{platform}：{count} ファイルを復元しました',
};

const _restoreMultipleFiles = {
  SupportedLocale.zhCN: '{platform}：已还原 {count} 个文件',
  SupportedLocale.zhTW: '{platform}：已還原 {count} 個檔案',
  SupportedLocale.en: '{platform}: {count} files restored',
  SupportedLocale.ja: '{platform}：{count} ファイルを復元しました',
};

const _restoreComplete = {
  SupportedLocale.zhCN: '还原完成，共 {total} 个文件已还原',
  SupportedLocale.zhTW: '還原完成，共 {total} 個檔案已還原',
  SupportedLocale.en: 'Restore complete, {total} file(s) restored',
  SupportedLocale.ja: '復元完了、{total} ファイルを復元しました',
};

const _restoreNoFiles = {
  SupportedLocale.zhCN: '备份目录中未找到任何平台文件，未执行还原',
  SupportedLocale.zhTW: '備份目錄中未找到任何平台檔案，未執行還原',
  SupportedLocale.en: 'No platform files found in backup directory, no restore performed',
  SupportedLocale.ja: 'バックアップディレクトリにプラットフォームファイルが見つかりません。復元は実行されませんでした',
};

const _decodeImageFailedPrefix = {
  SupportedLocale.zhCN: '无法解码图片文件: {path}',
  SupportedLocale.zhTW: '無法解碼圖片檔案: {path}',
  SupportedLocale.en: 'Failed to decode image file: {path}',
  SupportedLocale.ja: '画像ファイルをデコードできません: {path}',
};

const _procesandoPlatforma = {
  SupportedLocale.zhCN: '正在处理 {platform} 平台...',
  SupportedLocale.zhTW: '正在處理 {platform} 平台...',
  SupportedLocale.en: 'Processing {platform} platform...',
  SupportedLocale.ja: '{platform} プラットフォームを処理中...',
};

const _skippingLayerFg = {
  SupportedLocale.zhCN: '跳过（无前景源图片）: {path}',
  SupportedLocale.zhTW: '跳過（無前景來源圖片）: {path}',
  SupportedLocale.en: 'Skipping (no foreground source): {path}',
  SupportedLocale.ja: 'スキップ（前景ソースなし）: {path}',
};

const _skippingLayerBg = {
  SupportedLocale.zhCN: '跳过（无背景源图片）: {path}',
  SupportedLocale.zhTW: '跳過（無背景來源圖片）: {path}',
  SupportedLocale.en: 'Skipping (no background source): {path}',
  SupportedLocale.ja: 'スキップ（背景ソースなし）: {path}',
};

const _generandoIcono = {
  SupportedLocale.zhCN: '  生成: {path} ({width}x{height})',
  SupportedLocale.zhTW: '  生成: {path} ({width}x{height})',
  SupportedLocale.en: '  Generated: {path} ({width}x{height})',
  SupportedLocale.ja: '  生成: {path} ({width}x{height})',
};

const _generandoIco = {
  SupportedLocale.zhCN: '  生成 ICO: {path}',
  SupportedLocale.zhTW: '  生成 ICO: {path}',
  SupportedLocale.en: '  Generated ICO: {path}',
  SupportedLocale.ja: '  ICO を生成: {path}',
};

const _generacionCompletada = {
  SupportedLocale.zhCN: '生成完成，共 {count} 个文件',
  SupportedLocale.zhTW: '生成完成，共 {count} 個檔案',
  SupportedLocale.en: 'Generation complete, {count} file(s) generated',
  SupportedLocale.ja: '生成完了、{count} ファイルを生成しました',
};

const _writeError = {
  SupportedLocale.zhCN: '写入文件失败: {path}: {error}',
  SupportedLocale.zhTW: '寫入檔案失敗: {path}: {error}',
  SupportedLocale.en: 'Failed to write file: {path}: {error}',
  SupportedLocale.ja: 'ファイル書き込み失敗: {path}: {error}',
};

const _layerTypeForeground = {
  SupportedLocale.zhCN: '前景',
  SupportedLocale.zhTW: '前景',
  SupportedLocale.en: 'Foreground',
  SupportedLocale.ja: '前景',
};

const _layerTypeBackground = {
  SupportedLocale.zhCN: '背景',
  SupportedLocale.zhTW: '背景',
  SupportedLocale.en: 'Background',
  SupportedLocale.ja: '背景',
};

const _layerTypeMerged = {
  SupportedLocale.zhCN: '合并',
  SupportedLocale.zhTW: '合併',
  SupportedLocale.en: 'Merged',
  SupportedLocale.ja: '統合',
};

const _layerTypeWhiteBase = {
  SupportedLocale.zhCN: '不透明白底',
  SupportedLocale.zhTW: '不透明白底',
  SupportedLocale.en: 'Opaque white',
  SupportedLocale.ja: '不透明白背景',
};

const _newFileLabel = {
  SupportedLocale.zhCN: '新文件',
  SupportedLocale.zhTW: '新檔案',
  SupportedLocale.en: 'New',
  SupportedLocale.ja: '新規',
};

const _generandoIconoDetalle = {
  SupportedLocale.zhCN: '  生成: {path} ({width}x{height}) [{type}] {oldSize} → {newSize}',
  SupportedLocale.zhTW: '  生成: {path} ({width}x{height}) [{type}] {oldSize} → {newSize}',
  SupportedLocale.en: '  Generated: {path} ({width}x{height}) [{type}] {oldSize} → {newSize}',
  SupportedLocale.ja: '  生成: {path} ({width}x{height}) [{type}] {oldSize} → {newSize}',
};

const _generandoIcoDetalle = {
  SupportedLocale.zhCN: '  生成 ICO: {path} [{type}] {oldSize} → {newSize}',
  SupportedLocale.zhTW: '  生成 ICO: {path} [{type}] {oldSize} → {newSize}',
  SupportedLocale.en: '  Generated ICO: {path} [{type}] {oldSize} → {newSize}',
  SupportedLocale.ja: '  ICO を生成: {path} [{type}] {oldSize} → {newSize}',
};
