# SkillDrop

GitHub の Agent Skill を、ボタンひとつで **Cursor / Claude Code / Codex** に入れるアプリです。

| 版 | 対応 | 状態 |
|----|------|------|
| macOS (`SkillDrop.app`) | Apple Silicon (arm64) | 動作確認済み |
| Windows (`.exe`) | amd64 / arm64 | **ソース同梱・クロスビルド済み（実機未確認）** |

## 使い方（macOS）

1. [Releases](https://github.com/Blackphi6/SkillDrop/releases) から `SkillDrop-macos-arm64.zip` をダウンロード
2. 解凍して `SkillDrop.app` を開く（初回は右クリック → 開く、が必要なことがあります）
3. GitHub URL（または `owner/repo`、`.../SKILL.md` の直リンク）を貼る
4. 入れる先にチェックを入れて **入れる**

本体は `~/.agents/skills` に保存し、選んだエージェントへシンボリックリンクします。

`SKILL.md` への直リンクなら、そのスキルだけ入ります。リポジトリのトップ URL だと、見つかったスキルがまとめて入ります。

## 使い方（Windows・実験的）

1. Releases から `SkillDrop-windows-amd64.zip`（または arm64）をダウンロード
2. 解凍し、`SkillDrop-windows-amd64.exe` を実行（または `SkillDrop.bat`）
3. ブラウザが開き、Mac 版と同じ画面で導入できます
4. **git が PATH に入っている必要があります**（[Git for Windows](https://git-scm.com/download/win)）

Windows ではシンボリックリンクが拒否される環境があるため、失敗時はコピーに切り替えます。

### コマンド（共通）

```bash
# macOS
./SkillDrop.app/Contents/MacOS/SkillDrop --install https://github.com/coji/natural-japanese --agents cursor,claude,codex

# Windows
SkillDrop-windows-amd64.exe --install https://github.com/coji/natural-japanese --agents cursor,claude,codex
```

## 自分でビルド

### macOS

Xcode / Swift 6、Apple Silicon Mac が必要です。

```bash
./build-app.sh
open dist/SkillDrop.app
```

### Windows exe（Mac 上でクロスコンパイル可）

Go 1.22+ が必要です。

```bash
cd windows
./build-windows.sh
# → ../dist/SkillDrop-windows-amd64.exe など
```

## ライセンス

MIT
