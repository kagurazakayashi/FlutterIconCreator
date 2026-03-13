# Flutter Icon Creator

[English](README.md) | [简体中文](README.zh-Hans.md) | **繁體中文** | [日本語](README.ja.md)

為 Flutter 專案自動產生各平台應用圖示與啟動圖片的命令列工具。

支援 **Android**、**iOS**、**Web**、**Windows**、**macOS**、**Linux** 六大平台，只需提供一張前景圖示與一張背景圖片，即可一鍵產生所有平台所需的各種尺寸圖示。

## 功能特色

- **多平台覆蓋** — 支援 Android、iOS、Web、Windows、macOS、Linux
- **自適應圖示** — 自動產生 Android 自適應圖示的前景圖層與背景圖層
- **圓角與邊距** — 可自訂圓角半徑與前景邊距
- **ICO 產生** — 自動產生 Windows 所需的多尺寸 ICO 檔案
- **啟動圖片** — 同時產生各平台啟動圖片
- **掃描列表** — 列出既有圖示檔案及其尺寸、大小等詳細資訊（JSON 格式）
- **備份還原** — 可將現有圖示檔案整體備份，支援完整還原
- **多語言** — 支援简体中文、繁體中文、English、日本語

## 系統需求

- [Dart SDK](https://dart.dev/get-dart) **3.0.0** 或更高版本

> 注意：本工具是純 Dart 命令列工具，不依賴 Flutter SDK。

## 部署

### 方式一：直接複製執行

```bash
git clone git@github.com:kagurazakayashi/FlutterIconCreator.git
cd FlutterIconCreator
dart pub get
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -i icon.png
```

### 方式二：Git 子模組（推薦整合至專案）

將本工具作為 Git 子模組新增到你的 Flutter 專案中：

```bash
# 在 Flutter 專案根目錄下執行
git submodule add git@github.com:kagurazakayashi/FlutterIconCreator.git tools/flutter_icon_creator
git submodule update --init --recursive

# 安裝依賴
cd tools/flutter_icon_creator
dart pub get
cd ../..
```

使用時，在專案根目錄執行：

```bash
dart run tools/flutter_icon_creator/bin/flutter_icon_creator.dart -f . -i assets/icon.png
```

更新子模組版本：

```bash
cd tools/flutter_icon_creator
git pull origin main
cd ../..
```

### 方式三：全域啟用

```bash
dart pub global activate --source path <本工具所在目錄路徑>
```

啟用後可直接使用 `flutter_icon_creator` 命令。

### 方式四：編譯為可執行檔

參見下方「編譯」章節。

## 編譯

### 編譯為獨立可執行檔

```bash
dart pub get
dart compile exe bin/flutter_icon_creator.dart -o flutter_icon_creator
```

編譯完成後，將產生的 `flutter_icon_creator.exe`（Windows）或 `flutter_icon_creator`（macOS/Linux）放到任意 `PATH` 目錄下即可全域使用。

各平台編譯輸出範例：

| 平台 | 命令 | 輸出檔案 |
|------|------|----------|
| Windows | `dart compile exe bin/flutter_icon_creator.dart -o flutter_icon_creator.exe` | `flutter_icon_creator.exe` |
| macOS | `dart compile exe bin/flutter_icon_creator.dart -o flutter_icon_creator` | `flutter_icon_creator` |
| Linux | `dart compile exe bin/flutter_icon_creator.dart -o flutter_icon_creator` | `flutter_icon_creator` |

## 使用方法

### 基本用法

```bash
# 產生所有平台圖示（僅前景）
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -i path/to/icon.png

# 使用前景 + 背景圖層
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -i icon_fg.png -b icon_bg.png

# 僅產生 Android 和 iOS 圖示
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -i icon.png -p android,ios

# 掃描並列出專案中既有的圖示檔案
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -l

# 備份現有圖示
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project --backup backup/

# 從備份還原圖示
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project --restore backup/
```

### 參數說明

| 短參數 | 長參數 | 說明 | 預設值 | 必填 |
|--------|--------|------|--------|------|
| `-f` | — | Flutter 專案根目錄路徑 | — | 是 |
| `-p` | — | 目標平台，逗號分隔 | `all` | 否 |
| `-i` | — | 前景圖示來源圖片路徑 | — | 否\* |
| `-b` | — | 背景圖片來源圖片路徑 | — | 否 |
| `-r` | — | 圖示圓角半徑（像素） | `0` | 否 |
| `-m` | — | 前景邊距。可用像素值（如 `20`）或百分比（如 `10%`） | `0` | 否 |
| `-l` | — | 列表掃描模式（輸出 JSON） | `false` | 否 |
| — | `--backup` | 備份圖示到指定目錄 | — | 否 |
| — | `--restore` | 從備份目錄還原圖示 | — | 否 |
| — | `--lang` | 輸出語言 | 系統語言 | 否 |

\* 非列表/備份/還原模式下，需至少提供 `-i` 或 `-b` 之一。

### 支援的平台值

| 值 | 對應平台 |
|----|----------|
| `android` | Android |
| `ios` | iOS |
| `web` | Web |
| `windows` | Windows |
| `macos` | macOS |
| `linux` | Linux |
| `all` | 以上全部 |

### 支援的語言值

| 值 | 語言 |
|----|------|
| `zh_CN` | 简体中文 |
| `zh_TW` | 繁體中文 |
| `en` | English (US) |
| `ja` | 日本語 |

### 使用範例

```bash
# 在目前目錄的 Flutter 專案產生圖示（圓角 8px，邊距 5%）
dart run bin/flutter_icon_creator.dart -f . -i assets/app_icon.png -r 8 -m 5%

# 僅產生 Web 圖示
dart run bin/flutter_icon_creator.dart -f . -i icon.png -p web

# 指定中文輸出
dart run bin/flutter_icon_creator.dart -f . -i icon.png --lang zh_TW

# 編譯後使用
flutter_icon_creator -f /path/to/flutter_project -i icon.png -r 12 -m 15%
```

### 各平台產生檔案清單

| 平台 | 輸出檔案 |
|------|----------|
| **Android** | `mipmap-{density}/ic_launcher.png`（5 種密度）<br>`mipmap-{density}/ic_launcher_foreground.png`<br>`mipmap-{density}/ic_launcher_background.png`<br>`drawable-{density}/launch_background.png` |
| **iOS** | `Assets.xcassets/AppIcon.appiconset/` 下 15 種尺寸<br>`Assets.xcassets/LaunchImage.imageset/` 下 3 種尺寸 |
| **Web** | `web/favicon.png`<br>`web/icons/Icon-192.png`、`Icon-512.png` 等 |
| **Windows** | `windows/runner/resources/app_icon.ico`（含 7 種尺寸） |
| **macOS** | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` 下 10 種尺寸 |
| **Linux** | `linux/snap/`、`linux/flatpak/` 下各 256×256 |

### iOS 圖示特殊說明

- iOS 圖示使用不透明白底（遵循 iOS 規範要求），不會套用圓角（由系統自動處理）。
- Android 自適應圖示的前景圖層以 108dp × 108dp 畫布產生，圓角半徑約 22.37% 符合平台規範。

## AI 代理技能

專案根目錄下的 `SKILL.md` 可供 AI 程式設計代理使用。請根據所用工具將其複製到對應的發現路徑：

```bash
# Claude Code
cp SKILL.md .claude/skills/flutter-icon-creator/SKILL.md

# OpenCode（亦可從上述任一路徑讀取）
cp SKILL.md .opencode/skills/flutter-icon-creator/SKILL.md

# Codex CLI / Copilot / Cursor / Gemini CLI
cp SKILL.md .agents/skills/flutter-icon-creator/SKILL.md

# OpenClaw
cp SKILL.md workspace/skills/flutter-icon-creator/SKILL.md
# 或全域安裝：
cp SKILL.md ~/.openclaw/skills/flutter-icon-creator/SKILL.md
```

`SKILL.md` 格式是一種開放標準（由 Anthropic 最早發布），在主流 AI 程式設計工具中具有 99% 以上的一致性，同一份檔案可在所有支援的代理中正常運作。

代理發現後將自動取得：工具的用途與呼叫時機、完整 CLI 參數參考、各平台輸出路徑以及常見用法模式。

## 授權

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
