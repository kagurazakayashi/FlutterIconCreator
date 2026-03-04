import 'src/cli_args.dart';
import 'src/i18n/locale.dart';
import 'src/i18n/strings.dart';
import 'src/validator.dart';

void run(List<String> arguments) {
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

  print(s.validationPassed);
  print('  ${s.flutterProjectPath}: ${args.flutterProjectPath}');
  print('  ${s.targetPlatforms}: ${args.platforms.join(', ')}');
  if (args.listMode) {
    print('  ${s.listMode}');
  }
  if (args.iconSourcePath != null) {
    print('  ${s.iconSourcePath}: ${args.iconSourcePath}');
  }
  if (args.backgroundSourcePath != null) {
    print('  ${s.backgroundSourcePath}: ${args.backgroundSourcePath}');
  }
}
