# Flutter Icon Creator

[English](README.md) | **简体中文** | [繁體中文](README.zh-Hant.md) | [日本語](README.ja.md)

为 Flutter 项目自动生成各平台应用图标和启动图片的命令行工具。

支持 **Android**、**iOS**、**Web**、**Windows**、**macOS**、**Linux** 六大平台，只需提供一张前景图标和一张背景图片，即可一键生成所有平台所需的各种尺寸图标。

## 功能特性

- **多平台覆盖** — 支持 Android、iOS、Web、Windows、macOS、Linux
- **自适应图标** — 自动生成 Android 自适应图标的前景图层与背景图层
- **圆角与边距** — 可自定义圆角半径和前景边距
- **ICO 生成** — 自动生成 Windows 所需的多尺寸 ICO 文件
- **启动图片** — 同时生成各平台启动图片
- **扫描列表** — 列出已有图标文件及其尺寸、大小等详细信息（JSON 格式）
- **备份还原** — 可将现有图标文件整体备份，支持完整还原
- **多语言** — 支持简体中文、繁體中文、English、日本語

## 系统要求

- [Dart SDK](https://dart.dev/get-dart) **3.0.0** 或更高版本

> 注意：本工具是纯 Dart 命令行工具，不依赖 Flutter SDK。

## 部署

### 方式一：直接克隆运行

```bash
git clone git@github.com:kagurazakayashi/FlutterIconCreator.git
cd FlutterIconCreator
dart pub get
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -i icon.png
```

### 方式二：Git 子模块（推荐集成到项目）

将本工具作为 Git 子模块添加到你的 Flutter 项目中：

```bash
# 在 Flutter 项目根目录下执行
git submodule add git@github.com:kagurazakayashi/FlutterIconCreator.git tools/flutter_icon_creator
git submodule update --init --recursive

# 安装依赖
cd tools/flutter_icon_creator
dart pub get
cd ../..
```

使用时，在项目根目录执行：

```bash
dart run tools/flutter_icon_creator/bin/flutter_icon_creator.dart -f . -i assets/icon.png
```

更新子模块版本：

```bash
cd tools/flutter_icon_creator
git pull origin main
cd ../..
```

### 方式三：全局激活

```bash
dart pub global activate --source path <本工具所在目录路径>
```

激活后可直接使用 `flutter_icon_creator` 命令。

### 方式四：编译为可执行文件

参见下方"编译"章节。

## 编译

### 编译为独立可执行文件

```bash
dart pub get
dart compile exe bin/flutter_icon_creator.dart -o flutter_icon_creator
```

编译完成后，将生成的 `flutter_icon_creator.exe`（Windows）或 `flutter_icon_creator`（macOS/Linux）放到任意 `PATH` 目录下即可全局使用。

各平台编译输出示例：

| 平台    | 命令                                                                         | 输出文件                   |
| ------- | ---------------------------------------------------------------------------- | -------------------------- |
| Windows | `dart compile exe bin/flutter_icon_creator.dart -o flutter_icon_creator.exe` | `flutter_icon_creator.exe` |
| macOS   | `dart compile exe bin/flutter_icon_creator.dart -o flutter_icon_creator`     | `flutter_icon_creator`     |
| Linux   | `dart compile exe bin/flutter_icon_creator.dart -o flutter_icon_creator`     | `flutter_icon_creator`     |

## 使用方法

### 基本用法

```bash
# 生成所有平台图标（仅前景）
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -i path/to/icon.png

# 使用前景 + 背景图层
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -i icon_fg.png -b icon_bg.png

# 仅生成 Android 和 iOS 图标
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -i icon.png -p android,ios

# 扫描并列出项目中已有的图标文件
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -l

# 备份现有图标
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project --backup backup/

# 从备份还原图标
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project --restore backup/
```

### 参数说明

| 短参数 | 长参数      | 说明                                                | 默认值   | 必填 |
| ------ | ----------- | --------------------------------------------------- | -------- | ---- |
| `-f`   | —           | Flutter 项目根目录路径                              | —        | 是   |
| `-p`   | —           | 目标平台，逗号分隔                                  | `all`    | 否   |
| `-i`   | —           | 前景图标源图片路径                                  | —        | 否\* |
| `-b`   | —           | 背景图片源图片路径                                  | —        | 否   |
| `-r`   | —           | 图标圆角半径（像素）                                | `0`      | 否   |
| `-m`   | —           | 前景边距。可用像素值（如 `20`）或百分比（如 `10%`） | `0`      | 否   |
| `-l`   | —           | 列表扫描模式（输出 JSON）                           | `false`  | 否   |
| —      | `--backup`  | 备份图标到指定目录                                  | —        | 否   |
| —      | `--restore` | 从备份目录还原图标                                  | —        | 否   |
| —      | `--lang`    | 输出语言                                            | 系统语言 | 否   |

\* 非列表/备份/还原模式下，需至少提供 `-i` 或 `-b` 之一。

### 支持的平台值

| 值        | 对应平台 |
| --------- | -------- |
| `android` | Android  |
| `ios`     | iOS      |
| `web`     | Web      |
| `windows` | Windows  |
| `macos`   | macOS    |
| `linux`   | Linux    |
| `all`     | 以上全部 |

### 支持的语言值

| 值      | 语言         |
| ------- | ------------ |
| `zh_CN` | 简体中文     |
| `zh_TW` | 繁體中文     |
| `en`    | English (US) |
| `ja`    | 日本語       |

### 使用示例

```bash
# 在当前目录的 Flutter 项目生成图标（圆角 8px，边距 5%）
dart run bin/flutter_icon_creator.dart -f . -i assets/app_icon.png -r 8 -m 5%

# 仅生成 Web 图标
dart run bin/flutter_icon_creator.dart -f . -i icon.png -p web

# 指定中文输出
dart run bin/flutter_icon_creator.dart -f . -i icon.png --lang zh_CN

# 编译后使用
flutter_icon_creator -f /path/to/flutter_project -i icon.png -r 12 -m 15%
```

### 各平台生成文件清单

| 平台        | 输出文件                                                                                                                                                                                      |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Android** | `mipmap-{density}/ic_launcher.png`（5种密度）<br>`mipmap-{density}/ic_launcher_foreground.png`<br>`mipmap-{density}/ic_launcher_background.png`<br>`drawable-{density}/launch_background.png` |
| **iOS**     | `Assets.xcassets/AppIcon.appiconset/` 下 15 种尺寸<br>`Assets.xcassets/LaunchImage.imageset/` 下 3 种尺寸                                                                                     |
| **Web**     | `web/favicon.png`<br>`web/icons/Icon-192.png`、`Icon-512.png` 等                                                                                                                              |
| **Windows** | `windows/runner/resources/app_icon.ico`（含 7 种尺寸）                                                                                                                                        |
| **macOS**   | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` 下 10 种尺寸                                                                                                                               |
| **Linux**   | `linux/snap/`、`linux/flatpak/` 下各 256×256                                                                                                                                                  |

### iOS 图标特殊说明

- iOS 图标使用不透明白底（遵循 iOS 规范要求），不会应用圆角（由系统自动处理）。
- Android 自适应图标的前景图层按 108dp × 108dp 画布生成，圆角半径约 22.37% 符合平台规范。

## AI 代理技能

项目根目录下的 `SKILL.md` 可供 AI 编程代理使用。请根据所用工具将其复制到对应的发现路径：

```bash
# Claude Code
cp SKILL.md .claude/skills/flutter-icon-creator/SKILL.md

# OpenCode（亦可从上述任一路径读取）
cp SKILL.md .opencode/skills/flutter-icon-creator/SKILL.md

# Codex CLI / Copilot / Cursor / Gemini CLI
cp SKILL.md .agents/skills/flutter-icon-creator/SKILL.md

# OpenClaw
cp SKILL.md workspace/skills/flutter-icon-creator/SKILL.md
# 或全局安装：
cp SKILL.md ~/.openclaw/skills/flutter-icon-creator/SKILL.md
```

`SKILL.md` 格式是一种开放标准（由 Anthropic 最早发布），在主流 AI 编程工具中具有 99% 以上的一致性，同一份文件可在所有支持的代理中正常运作。

代理发现后将自动获取：工具的用途与调用时机、完整 CLI 参数参考、各平台输出路径以及常见用法模式。

## 许可

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
