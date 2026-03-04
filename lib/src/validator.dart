import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'cli_args.dart';
import 'i18n/strings.dart';

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}

ValidationResult validate(CliArgs args) {
  final errors = <String>[];
  final warnings = <String>[];
  final s = AppStrings(args.locale);

  final flutterProjectDir = Directory(args.flutterProjectPath);
  if (!flutterProjectDir.existsSync()) {
    errors.add(s.flutterProjectNotFound.replaceAll('{path}', args.flutterProjectPath));
    return ValidationResult(isValid: false, errors: errors, warnings: warnings);
  }

  final pubspecFile = File(p.join(args.flutterProjectPath, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    errors.add(s.pubspecNotFound.replaceAll('{path}', args.flutterProjectPath));
    return ValidationResult(isValid: false, errors: errors, warnings: warnings);
  }

  try {
    final pubspecContent = pubspecFile.readAsStringSync();
    final yaml = loadYaml(pubspecContent);

    bool isFlutterProject = false;

    if (yaml is YamlMap) {
      final dependencies = yaml['dependencies'];
      if (dependencies is YamlMap && dependencies.containsKey('flutter')) {
        isFlutterProject = true;
      }

      final devDependencies = yaml['dev_dependencies'];
      if (devDependencies is YamlMap && devDependencies.containsKey('flutter')) {
        isFlutterProject = true;
      }
    }

    if (!isFlutterProject) {
      errors.add(s.notFlutterProject);
    }
  } catch (e) {
    errors.add(s.parsePubspecError(e));
  }

  if (args.platforms.isEmpty) {
    errors.add(s.noPlatforms);
  } else {
    for (final platform in args.platforms) {
      if (!validPlatforms.contains(platform)) {
        errors.add(s.invalidPlatform(platform, validPlatforms.join(', ')));
      }
    }
  }

  if (args.iconSourcePath != null) {
    final iconFile = File(args.iconSourcePath!);
    if (!iconFile.existsSync()) {
      errors.add(s.iconFileNotFound(args.iconSourcePath!));
    }
  }

  if (args.backgroundSourcePath != null) {
    final bgFile = File(args.backgroundSourcePath!);
    if (!bgFile.existsSync()) {
      errors.add(s.backgroundFileNotFound(args.backgroundSourcePath!));
    }
  }

  if (!args.listMode && args.iconSourcePath == null && args.backgroundSourcePath == null) {
    warnings.add(s.noSourceImages);
  }

  return ValidationResult(
    isValid: errors.isEmpty,
    errors: errors,
    warnings: warnings,
  );
}
