---
name: flutter-icon-creator
description: Generate platform-specific app icons and launch images for Flutter projects. Use when the user needs to create or update Android/iOS/Web/Windows/macOS/Linux icons from source images. Supports adaptive icons, corner radius, margin, backup/restore, and list scan mode.
license: Mulan PSL v2
compatibility: claude-code, opencode, codex, openclaw, cursor, gemini-cli, copilot
metadata:
  tool: FlutterIconCreator
  runtime: Dart SDK (>=3.0.0)
  repo: https://github.com/kagurazakayashi/FlutterIconCreator
---

## What This Tool Does

Flutter Icon Creator is a Dart CLI tool that automatically generates all required app icons and launch/splash images for every Flutter platform from one or two source images.

## When to Use

Invoke this tool when the user asks to:
- Generate app icons for a Flutter project
- Update application icons across platforms
- Create adaptive Android icons or iOS app icon sets
- Generate favicon or PWA icons for Flutter Web
- Generate Windows ICO or macOS icon sets
- Backup or restore existing icon files
- List all icon files in a Flutter project

## Prerequisites

- Dart SDK >=3.0.0 installed and available in PATH
- Flutter project with standard platform directories present

## How to Invoke

### If not yet installed (first use)

```bash
cd <path-to-FlutterIconCreator-clone>
dart pub get
```

### Run directly with Dart

```bash
cd <path-to-FlutterIconCreator-clone>
dart run bin/flutter_icon_creator.dart <arguments>
```

### When added as git submodule (e.g., at tools/flutter_icon_creator)

```bash
cd <flutter-project-root>/tools/flutter_icon_creator
dart pub get  # only needed once
cd <flutter-project-root>
dart run tools/flutter_icon_creator/bin/flutter_icon_creator.dart <arguments>
```

### When compiled to executable

```bash
flutter_icon_creator <arguments>
```

## Complete Parameter Reference

### Required Parameter

| Flag | Description |
|------|-------------|
| `-f <path>` | Flutter project root directory path |

### Source Image Parameters

| Flag | Description | Note |
|------|-------------|------|
| `-i <path>` | Foreground icon source image (PNG recommended) | Required unless using -l/--backup/--restore |
| `-b <path>` | Background image source image | Optional. Used for Android adaptive background or merged composite |

### Platform Selection

| Flag | Description | Default |
|------|-------------|---------|
| `-p <list>` | Target platforms, comma-separated | `all` |

Valid platform values: `android`, `ios`, `web`, `windows`, `macos`, `linux`, `all`

### Style Customization

| Flag | Description | Default |
|------|-------------|---------|
| `-r <number>` | Corner radius in pixels. For Android adaptive icons, a platform-appropriate value (~22.37% of canvas) is used automatically. iOS icons do not apply corner radius (system handles it). | `0` |
| `-m <value>` | Foreground margin. Supports pixel values like `20` or percentages like `10%`. Applied to the foreground layer within the icon canvas. | `0` |

### Operational Modes

| Flag | Description |
|------|-------------|
| `-l` | List scan mode: outputs JSON with all existing icon file paths, dimensions, sizes, and tags. No icons are generated. |
| `--backup <dir>` | Backup all existing icon files to the specified directory. Preserves platform directory structure. |
| `--restore <dir>` | Restore icon files from a previous backup directory. Overwrites existing files. |

### Localization

| Flag | Description | Default |
|------|-------------|---------|
| `--lang <code>` | Output language for messages | Auto-detected from system locale |

Valid language codes: `zh_CN`, `zh_TW`, `en`, `ja`

## Generated File Locations

### Android

| File Pattern | Locations | Notes |
|-------------|-----------|-------|
| `ic_launcher.png` | `mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/` | Legacy launcher icon, merged foreground+background |
| `ic_launcher_foreground.png` | `mipmap-{density}/` | Adaptive icon foreground (108dp canvas) |
| `ic_launcher_background.png` | `mipmap-{density}/` | Adaptive icon background (108dp canvas) |
| `launch_background.png` | `drawable-{density}/` | Splash/launch screen background |

### iOS

| Location | Count | Notes |
|----------|-------|-------|
| `Assets.xcassets/AppIcon.appiconset/` | 15 sizes (20..1024px) | Opaque white background, no corner radius |
| `Assets.xcassets/LaunchImage.imageset/` | 3 sizes | Launch screen images |

### Web

| File | Size |
|------|------|
| `web/favicon.png` | 64×64 |
| `web/icons/Icon-192.png` | 192×192 (PWA) |
| `web/icons/Icon-512.png` | 512×512 (PWA) |
| `web/icons/Icon-maskable-192.png` | 192×192 maskable |
| `web/icons/Icon-maskable-512.png` | 512×512 maskable |

### Windows

| File | Contents |
|------|----------|
| `windows/runner/resources/app_icon.ico` | Multi-size ICO (16, 24, 32, 48, 64, 128, 256) |

### macOS

| Location | Count |
|----------|-------|
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/` | 10 sizes (16..1024px, includes @2x variants) |

### Linux

| Location | Size |
|----------|------|
| `linux/snap/gui/icon.png` | 256×256 |
| `linux/flatpak/icon.png` | 256×256 |

## Common Usage Patterns

### Generate all-platform icons from foreground only

```bash
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -i icon.png
```

### Generate with foreground + background (best for Android adaptive icons)

```bash
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -i icon_fg.png -b icon_bg.png
```

### Target specific platforms only

```bash
dart run bin/flutter_icon_creator.dart -f . -i icon.png -p android,ios,web
```

### Apply rounded corners with margin

```bash
dart run bin/flutter_icon_creator.dart -f . -i icon.png -r 12 -m 5%
```

### List all existing icons (for inspection)

```bash
dart run bin/flutter_icon_creator.dart -f . -l
```

### Backup before regenerating

```bash
dart run bin/flutter_icon_creator.dart -f . --backup icons_backup/
```

### Restore from backup

```bash
dart run bin/flutter_icon_creator.dart -f . --restore icons_backup/
```

### Set output language

```bash
dart run bin/flutter_icon_creator.dart -f . -i icon.png --lang ja
```

## Image Format Support

The tool uses the Dart `image` package and supports input formats: PNG, JPEG, WebP, BMP, GIF. PNG is recommended for source images to preserve transparency.

## Key Behaviors to Know

1. **iOS opaque background**: iOS icons always get an opaque white background applied (Apple HIG requirement). No corner radius is applied since iOS handles masking.

2. **Android adaptive canvas**: Foreground and background layers for Android adaptive icons are generated on a 108dp × 108dp canvas. The automatic corner radius for foreground is approximately 22.37% of the icon size, matching Material Design guidelines.

3. **ICO generation**: Windows uses a single `.ico` file containing 7 embedded sizes (16–256px). The tool generates all sizes and packs them automatically.

4. **File scanning**: The `-l` list mode scans for existing files to determine what sizes are already present. During generation, the tool also scans to avoid redundant work when a file already exists at the correct size.

5. **Validation**: The tool validates that the given path is a Flutter project (checks for `pubspec.yaml` with Flutter dependency). Warnings are shown if no source image is provided in generate mode.

## Keeping Your Repository Lean

This tool generates 50+ icon files across all platforms. To avoid bloating the repository, only commit the source images (1-2 files) and let the tool regenerate platform icons on demand.

Add these lines to the Flutter project's `.gitignore` to exclude generated icons:

```gitignore
### Icon Images ###
# Ignore generated icon/launcher image files within platform directories
android/**/*[Ii]con*.png
android/**/ic_launcher*.png
android/**/launch_background.png
ios/**/*[Ii]con*.png
ios/**/LaunchImage*.png
macos/**/*[Ii]con*.png
macos/**/*[Ii]con*.icns
web/**/*[Ii]con*.png
windows/**/*[Ii]con*.png
windows/**/*[Ii]con*.ico
ico/backup
### End of Icon Images ###
```

If the user's `.gitignore` already exists, insert this block before other platform-specific rules. If no `.gitignore` exists, create one with this content.

## Troubleshooting

| Problem | Likely Cause | Solution |
|---------|-------------|----------|
| "pubspec.yaml not found" | Not a Flutter project directory | Verify `-f` points to a directory with `pubspec.yaml` |
| "Not a Flutter project" | `pubspec.yaml` missing Flutter dependency | Verify the project depends on `flutter` in pubspec.yaml |
| Source image decode failure | Unsupported or corrupted image | Ensure source is valid PNG/JPEG/WebP |
| Permission errors on write | No write access to project directory | Check file permissions |
