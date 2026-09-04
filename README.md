# SkillDrop

GitHub の Agent Skill を、ボタンひとつで **Cursor / Claude Code / Codex** に入れるアプリです。

| 版 | 対応 | 状態 |
|----|------|------|
| macOS (`SkillDrop.app`) | Apple Silicon (arm64) | 動作確認済み |
| Windows (`.exe`) | amd64 / arm64 | 実機未確認 |

## いちばん楽な入れ方（macOS）

Apple の**有料**デベロッパ登録がないと、ブラウザから落とした `.app` は必ず Gatekeeper に止められます（無料アカウントでは公証できません）。

だから **Homebrew 経由**がおすすめです（設定画面の「このまま開く」が不要）:

```bash
brew tap Blackphi6/skilldrop https://github.com/Blackphi6/SkillDrop
brew install --cask skilldrop
```

更新:

```bash
brew upgrade --cask skilldrop
```

## zip から入れる場合（非推奨）

[Releases](https://github.com/Blackphi6/SkillDrop/releases) の `SkillDrop-macos-arm64.zip` を解凍したあと:

```bash
xattr -cr ./SkillDrop.app
open ./SkillDrop.app
```

（アプリを直接ダブルクリックすると「壊れている／検証できません」になります）

## 使い方

1. アプリを開く
2. GitHub URL（または `owner/repo`、`.../SKILL.md`）を貼る
3. Cursor / Claude Code / Codex にチェックして **入れる**

本体は `~/.agents/skills` に保存し、選んだエージェントへリンクします。

### コマンド

```bash
# macOS
./SkillDrop.app/Contents/MacOS/SkillDrop --install https://github.com/coji/natural-japanese --agents cursor,claude,codex

# Windows
SkillDrop-windows-amd64.exe --install https://github.com/coji/natural-japanese --agents cursor,claude,codex
```

## Windows（実験的）

1. Releases から `SkillDrop-windows-amd64.zip`（または arm64）をダウンロード
2. `.exe` を実行（**Git for Windows** が PATH にあること）

## 自分でビルド

```bash
# macOS app + zip
./package-macos.sh

# Windows exe（クロスコンパイル）
cd windows && ./build-windows.sh
```

## 公証について

ダブルクリックだけで警告ゼロにするには、Apple Developer Program（有料）の **Developer ID** 証明書と **notarization** が必要です。いまのアカウントは無料の Personal Team のため、公証はできません。有料登録できたら対応できます。

## ライセンス

MIT
