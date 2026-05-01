import 'src/backup_restore.dart';
import 'src/cli_args.dart';
import 'src/i18n/locale.dart';
import 'src/i18n/strings.dart';
import 'src/icon_generator.dart';
import 'src/list_mode.dart';
import 'src/validator.dart';

Future<void> run(List<String> arguments) async {
  final AppStrings s;
  final CliArgs args;

  try {
    args = parseArgs(arguments);
    s = AppStrings(args.locale);
  } on FormatException catch (e) {
    final fallback = AppStrings(SupportedLocale.en);
    print('${fallback.errorPrefix}: ${e.message}');
    print('');
    print(buildArgParser(detectSystemLocale()).usage);
    return;
  }

  final result = validate(args);

  if (result.warnings.isNotEmpty) {
    for (final w in result.warnings) {
      print('${s.warningPrefix}: $w');
    }
  }

  if (!result.isValid) {
    print('${s.validationFailed}:');
    for (final e in result.errors) {
      print('  ${s.errorPrefix}: $e');
    }
    return;
  }

  // 備份模式：備份所有圖示與啟動圖片
  if (args.backupPath != null) {
    runBackup(args);
    return;
  }

  // 還原模式：從備份目錄還原檔案
  if (args.restorePath != null) {
    runRestore(args);
    return;
  }

  // 列表掃描模式：列出所有圖示與啟動圖片後即結束，不進行轉換
  if (args.listMode) {
    runListMode(args);
    return;
  }

  // 圖示生成模式：為各平台產生圖示與啟動圖片
  await runGenerate(args, s);
}
