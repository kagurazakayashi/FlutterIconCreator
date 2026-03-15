# Flutter Icon Creator

[English](README.md) | [简体中文](README.zh-Hans.md) | [繁體中文](README.zh-Hant.md) | **日本語**

Flutter プロジェクト向けに、各プラットフォームのアプリアイコンとスプラッシュ画像を自動生成するコマンドラインツールです。

**Android**、**iOS**、**Web**、**Windows**、**macOS**、**Linux** の 6 つのプラットフォームに対応し、前景アイコンと背景画像を 1 枚ずつ用意するだけで、全プラットフォームのあらゆるサイズのアイコンを一括生成します。

## 機能

- **マルチプラットフォーム対応** — Android、iOS、Web、Windows、macOS、Linux
- **アダプティブアイコン** — Android 向けアダプティブアイコンの前景・背景レイヤーを自動生成
- **角丸とマージン** — 角丸半径と前景マージンをカスタマイズ可能
- **ICO 生成** — Windows 向けのマルチサイズ ICO ファイルを自動生成
- **スプラッシュ画像** — 各プラットフォームの起動画像も同時生成
- **並列処理** — 全 CPU コアを利用したマルチスレッドアイコン生成
- **一覧表示モード** — 既存アイコンファイルのサイズ・寸法などの詳細を JSON 形式で出力
- **バックアップと復元** — 既存アイコンファイルの完全バックアップと復元
- **多言語対応** — 简体中文、繁體中文、English、日本語

## リポジトリサイズの削減

本ツールは全プラットフォームで **50 以上のアイコンファイル** を生成しますが、これらの生成ファイルを Git にコミットする必要はありません。**1-2 枚のソース画像**（前景/背景）だけをコミットし、必要に応じてアイコンを再生成してください。

生成されたアイコンがコミットされないよう、Flutter プロジェクトの `.gitignore` に以下を追加してください：

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

これにより、リポジトリは軽量に保たれます——ソース画像とツールのみが追跡され、プラットフォーム固有のアイコンファイルはオンデマンドで再生成されます。

## システム要件

- [Dart SDK](https://dart.dev/get-dart) **3.0.0** 以上

> 注意：本ツールは純粋な Dart CLI ツールであり、Flutter SDK は不要です。

## インストール

### 方法 1: クローンして実行

```bash
git clone git@github.com:kagurazakayashi/FlutterIconCreator.git
cd FlutterIconCreator
dart pub get
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -i icon.png
```

### 方法 2: Git サブモジュール（プロジェクト統合におすすめ）

本ツールを Git サブモジュールとして Flutter プロジェクトに追加します：

```bash
# Flutter プロジェクトのルートディレクトリで実行
git submodule add git@github.com:kagurazakayashi/FlutterIconCreator.git tools/flutter_icon_creator
git submodule update --init --recursive

# 依存関係のインストール
cd tools/flutter_icon_creator
dart pub get
cd ../..
```

使用時はプロジェクトのルートディレクトリから実行します：

```bash
dart run tools/flutter_icon_creator/bin/flutter_icon_creator.dart -f . -i assets/icon.png
```

サブモジュールの更新：

```bash
cd tools/flutter_icon_creator
git pull origin main
cd ../..
```

### 方法 3: グローバル有効化

```bash
dart pub global activate --source path <本ツールのディレクトリパス>
```

有効化後、`flutter_icon_creator` コマンドを直接使用できます。

### 方法 4: 実行ファイルにコンパイル

下記の「コンパイル」セクションを参照してください。

## コンパイル

### スタンドアロン実行ファイルへのコンパイル

```bash
dart pub get
dart compile exe bin/flutter_icon_creator.dart -o flutter_icon_creator
```

コンパイル後、生成された `flutter_icon_creator.exe`（Windows）または `flutter_icon_creator`（macOS/Linux）を任意の `PATH` ディレクトリに配置すれば、グローバルに使用できます。

プラットフォーム別のコンパイルコマンド：

| プラットフォーム | コマンド | 出力ファイル |
|-----------------|----------|-------------|
| Windows | `dart compile exe bin/flutter_icon_creator.dart -o flutter_icon_creator.exe` | `flutter_icon_creator.exe` |
| macOS | `dart compile exe bin/flutter_icon_creator.dart -o flutter_icon_creator` | `flutter_icon_creator` |
| Linux | `dart compile exe bin/flutter_icon_creator.dart -o flutter_icon_creator` | `flutter_icon_creator` |

## 使用方法

### 基本的な使い方

```bash
# 全プラットフォームのアイコンを生成（前景のみ）
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -i path/to/icon.png

# 前景 + 背景レイヤーを使用
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -i icon_fg.png -b icon_bg.png

# Android と iOS のみ生成
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -i icon.png -p android,ios

# プロジェクト内の既存アイコンファイルを一覧表示
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project -l

# 既存アイコンをバックアップ
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project --backup backup/

# バックアップからアイコンを復元
dart run bin/flutter_icon_creator.dart -f /path/to/flutter_project --restore backup/
```

### パラメータ

| 短縮 | 長形式 | 説明 | デフォルト値 | 必須 |
|------|--------|------|-------------|------|
| `-f` | `--project` | Flutter プロジェクトのルートディレクトリパス | — | はい |
| `-p` | `--platforms` | 対象プラットフォーム（カンマ区切り） | `all` | いいえ |
| `-i` | `--icon` | 前景アイコンのソース画像パス | — | いいえ\* |
| `-b` | `--background` | 背景画像のソース画像パス | — | いいえ |
| `-r` | `--radius` | アイコン角丸半径（ピクセル） | 自動 (0) | いいえ |
| `-m` | `--margin` | 前景マージン。ピクセル値（例: `20`）またはパーセント（例: `10%`） | `10%` | いいえ |
| `-l` | `--list` | 一覧表示モード（JSON 出力） | `false` | いいえ |
| `-B` | `--backup` | 指定ディレクトリにアイコンをバックアップ | — | いいえ |
| `-R` | `--restore` | バックアップディレクトリからアイコンを復元 | — | いいえ |
| `-L` | `--locale` | 出力言語 | システム言語 | いいえ |
| `-j` | `--jobs` | 並列ワーカー数（1 に設定すると並列処理を無効化） | CPU コア数 | いいえ |

\* 一覧表示/バックアップ/復元モード以外では、`-i` または `-b` の少なくとも 1 つが必要です。

### 対応プラットフォーム値

| 値 | プラットフォーム |
|----|-----------------|
| `android` | Android |
| `ios` | iOS |
| `web` | Web |
| `windows` | Windows |
| `macos` | macOS |
| `linux` | Linux |
| `all` | 上記すべて |

### 対応言語値

| 値 | 言語 |
|----|------|
| `zh_CN` | 简体中文 |
| `zh_TW` | 繁體中文 |
| `en` | English (US) |
| `ja` | 日本語 |

### 使用例

```bash
# カレントディレクトリの Flutter プロジェクトにアイコンを生成（角丸 8px、マージン 5%）
dart run bin/flutter_icon_creator.dart -f . -i assets/app_icon.png -r 8 -m 5%

# Web アイコンのみ生成
dart run bin/flutter_icon_creator.dart -f . -i icon.png -p web

# 日本語出力を指定
dart run bin/flutter_icon_creator.dart -f . -i icon.png --locale ja

# コンパイル後
flutter_icon_creator -f /path/to/flutter_project -i icon.png -r 12 -m 15%

# 並列ワーカーで高速生成
dart run bin/flutter_icon_creator.dart -f . -i icon.png -j 4

# シングルスレッドモード
dart run bin/flutter_icon_creator.dart -f . -i icon.png -j 1
```

### プラットフォーム別生成ファイル一覧

| プラットフォーム | 出力ファイル |
|-----------------|-------------|
| **Android** | `mipmap-{density}/ic_launcher.png`（5 密度）<br>`mipmap-{density}/ic_launcher_foreground.png`<br>`mipmap-{density}/ic_launcher_background.png`<br>`drawable-{density}/launch_background.png` |
| **iOS** | `Assets.xcassets/AppIcon.appiconset/` 以下 15 サイズ<br>`Assets.xcassets/LaunchImage.imageset/` 以下 3 サイズ |
| **Web** | `web/favicon.png`<br>`web/icons/Icon-192.png`、`Icon-512.png` など |
| **Windows** | `windows/runner/resources/app_icon.ico`（7 サイズ） |
| **macOS** | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` 以下 10 サイズ |
| **Linux** | `linux/snap/`、`linux/flatpak/` 以下各 256×256 |

### iOS アイコンに関する注意

- iOS アイコンは不透明な白背景（Apple HIG 準拠）を使用し、角丸は適用されません（システムが自動処理）。
- Android アダプティブアイコンの前景レイヤーは 108dp × 108dp キャンバスに生成され、角丸半径はプラットフォーム仕様に合わせて約 22.37% になります。

## AI エージェントスキル

リポジトリルートの `SKILL.md` は AI コーディングエージェントで使用できます。使用するツールに応じて、適切な発見パスにコピーしてください：

```bash
# Claude Code
cp SKILL.md .claude/skills/flutter-icon-creator/SKILL.md

# OpenCode（上記のいずれかのパスからも読み取り可能）
cp SKILL.md .opencode/skills/flutter-icon-creator/SKILL.md

# Codex CLI / Copilot / Cursor / Gemini CLI
cp SKILL.md .agents/skills/flutter-icon-creator/SKILL.md

# OpenClaw
cp SKILL.md workspace/skills/flutter-icon-creator/SKILL.md
# またはグローバル：
cp SKILL.md ~/.openclaw/skills/flutter-icon-creator/SKILL.md
```

`SKILL.md` 形式はオープンスタンダード（Anthropic が最初に公開）であり、主要な AI コーディングツール間で 99% 以上の一貫性を持ちます。同じファイルがすべてのサポートされているエージェントで同一に動作します。

エージェントが発見すると、ツールの目的、CLI パラメータ、プラットフォーム別出力パス、一般的な使用パターンを自動的に取得します。

## ライセンス

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
