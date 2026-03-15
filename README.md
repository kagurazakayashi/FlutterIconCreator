# Flutter Icon Creator

**English** | [简体中文](README.zh-Hans.md) | [繁體中文](README.zh-Hant.md) | [日本語](README.ja.md)

A command-line tool for automatically generating platform-specific app icons and launch images for Flutter projects.

Supports six major platforms — **Android**, **iOS**, **Web**, **Windows**, **macOS**, **Linux** — with a single foreground icon and an optional background image.

## Features

- **Multi-platform coverage** — Android, iOS, Web, Windows, macOS, Linux
- **Adaptive icons** — Auto-generates Android adaptive icon foreground and background layers
- **Corner radius & margin** — Customizable corner radius and foreground margin
- **ICO generation** — Auto-generates multi-size ICO files for Windows
- **Launch images** — Generates platform-specific launch/splash images
- **Parallel processing** — Multi-threaded icon generation using all CPU cores by default
- **List mode** — Outputs existing icon files with size, dimensions, etc. in JSON format
- **Backup & restore** — Backup all existing icons and restore them in full
- **Multi-language** — Supports 简体中文, 繁體中文, English, 日本語

## Reducing Repository Size

This tool generates **50+ icon files** across all platforms — you don't need to commit those generated files to Git. Just commit your **1-2 source images** (foreground/background) and regenerate icons whenever needed.

To prevent generated icons from being committed, add the following lines to your Flutter project's `.gitignore`:

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

This keeps your repository lean — only source images and the tool are tracked, while platform-specific icon files are regenerated on demand.

## Requirements

- [Dart SDK](https://dart.dev/get-dart) **3.0.0** or higher

> Note: This is a pure Dart CLI tool. Flutter SDK is not required.

## Installation

### Method 1: Clone and Run

```bash
git clone git@github.com:kagurazakayashi/FlutterIconCreator.git
cd FlutterIconCreator
dart pub get
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -i icon.png
```

### Method 2: Git Submodule (recommended for project integration)

Add this tool as a Git submodule inside your Flutter project:

```bash
# Run from your Flutter project root
git submodule add git@github.com:kagurazakayashi/FlutterIconCreator.git tools/flutter_icon_creator
git submodule update --init --recursive

# Install dependencies
cd tools/flutter_icon_creator
dart pub get
cd ../..
```

Then run from the project root:

```bash
dart run tools/flutter_icon_creator/bin/flutter_icon_creator.dart -f . -i assets/icon.png
```

Updating the submodule to the latest version:

```bash
cd tools/flutter_icon_creator
git pull origin main
cd ../..
```

### Method 3: Global Activation

```bash
dart pub global activate --source path <path_to_this_tool>
```

After activation, use the `flutter_icon_creator` command directly.

### Method 4: Compile to Executable

See the "Compilation" section below.

## Compilation

### Compile to Standalone Executable

```bash
dart pub get
dart compile exe bin/flutter_icon_creator.dart -o flutter_icon_creator
```

After compilation, place the output binary — `flutter_icon_creator.exe` (Windows) or `flutter_icon_creator` (macOS/Linux) — in any directory on your `PATH` for global access.

Platform-specific compile commands:

| Platform | Command | Output File |
|----------|---------|-------------|
| Windows | `dart compile exe bin/flutter_icon_creator.dart -o flutter_icon_creator.exe` | `flutter_icon_creator.exe` |
| macOS | `dart compile exe bin/flutter_icon_creator.dart -o flutter_icon_creator` | `flutter_icon_creator` |
| Linux | `dart compile exe bin/flutter_icon_creator.dart -o flutter_icon_creator` | `flutter_icon_creator` |

## Usage

### Basic Usage

```bash
# Generate icons for all platforms (foreground only)
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -i path/to/icon.png

# Use foreground + background layers
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -i icon_fg.png -b icon_bg.png

# Generate only for Android and iOS
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -i icon.png -p android,ios

# List existing icon files in the project
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -l

# Backup existing icons
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project --backup backup/

# Restore icons from backup
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project --restore backup/
```

### Parameters

| Short | Long | Description | Default | Required |
|-------|------|-------------|---------|----------|
| `-f` | `--project` | Flutter project root directory path | — | Yes |
| `-p` | `--platforms` | Target platforms, comma-separated | `all` | No |
| `-i` | `--icon` | Foreground icon source image path | — | No\* |
| `-b` | `--background` | Background image source path | — | No |
| `-r` | `--radius` | Icon corner radius in pixels | auto (0) | No |
| `-m` | `--margin` | Foreground margin: pixel (e.g. `20`) or percentage (e.g. `10%`) | `10%` | No |
| `-l` | `--list` | List scan mode (outputs JSON) | `false` | No |
| `-B` | `--backup` | Backup icons to specified directory | — | No |
| `-R` | `--restore` | Restore icons from backup directory | — | No |
| `-L` | `--locale` | Output language | System locale | No |
| `-j` | `--jobs` | Number of parallel workers (set to 1 to disable parallelism) | CPU cores | No |

\* In non-list/backup/restore mode, at least one of `-i` or `-b` is required.

### Supported Platform Values

| Value | Platform |
|-------|----------|
| `android` | Android |
| `ios` | iOS |
| `web` | Web |
| `windows` | Windows |
| `macos` | macOS |
| `linux` | Linux |
| `all` | All of the above |

### Supported Language Values

| Value | Language |
|-------|----------|
| `zh_CN` | 简体中文 |
| `zh_TW` | 繁體中文 |
| `en` | English (US) |
| `ja` | 日本語 |

### Examples

```bash
# Generate icons for a Flutter project in the current directory (8px radius, 5% margin)
dart run bin/flutter_icon_creator.dart -f . -i assets/app_icon.png -r 8 -m 5%

# Generate only Web icons
dart run bin/flutter_icon_creator.dart -f . -i icon.png -p web

# Use Chinese output
dart run bin/flutter_icon_creator.dart -f . -i icon.png --locale zh_CN

# After compilation
flutter_icon_creator -f /path/to/flutter_project -i icon.png -r 12 -m 15%

# Use parallel workers for faster generation
dart run bin/flutter_icon_creator.dart -f . -i icon.png -j 4

# Single-threaded mode
dart run bin/flutter_icon_creator.dart -f . -i icon.png -j 1
```

### Generated Files per Platform

| Platform | Output Files |
|----------|-------------|
| **Android** | `mipmap-{density}/ic_launcher.png` (5 densities)<br>`mipmap-{density}/ic_launcher_foreground.png`<br>`mipmap-{density}/ic_launcher_background.png`<br>`drawable-{density}/launch_background.png` |
| **iOS** | 15 sizes under `Assets.xcassets/AppIcon.appiconset/`<br>3 sizes under `Assets.xcassets/LaunchImage.imageset/` |
| **Web** | `web/favicon.png`<br>`web/icons/Icon-192.png`, `Icon-512.png`, etc. |
| **Windows** | `windows/runner/resources/app_icon.ico` (7 sizes) |
| **macOS** | 10 sizes under `macos/Runner/Assets.xcassets/AppIcon.appiconset/` |
| **Linux** | 256×256 under `linux/snap/` and `linux/flatpak/` |

### iOS Icon Notes

- iOS icons use an opaque white background (per Apple HIG) and do not apply corner radius (system handles it).
- Android adaptive icon foreground layers are generated on a 108dp × 108dp canvas with a corner radius of approximately 22.37% following platform guidelines.

## AI Agent Skills

This project includes a `SKILL.md` at the repository root for use with AI coding agents. Copy it to the appropriate discovery path for your tool:

```bash
# Claude Code
cp SKILL.md .claude/skills/flutter-icon-creator/SKILL.md

# OpenCode (read from any of the above paths)
cp SKILL.md .opencode/skills/flutter-icon-creator/SKILL.md

# Codex CLI / Copilot / Cursor / Gemini CLI
cp SKILL.md .agents/skills/flutter-icon-creator/SKILL.md

# OpenClaw
cp SKILL.md workspace/skills/flutter-icon-creator/SKILL.md
# or globally:
cp SKILL.md ~/.openclaw/skills/flutter-icon-creator/SKILL.md
```

The `SKILL.md` format is an open standard (originally published by Anthropic) with 99%+ consistency across major AI coding tools. The same file works identically for all supported agents.

When discovered, the agent learns the tool's purpose, CLI parameters, platform-specific output paths, and common usage patterns.

## License

```LICENSE
Copyright (c) 2026 KagurazakaYashi(KagurazakaMiyabi)
Flutter Icon Creator is licensed under Mulan PSL v2.
You can use this software according to the terms and conditions of the Mulan PSL v2.
You may obtain a copy of Mulan PSL v2 at:
    http://license.coscl.org.cn/MulanPSL2
THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
See the Mulan PSL v2 for more details.
```
