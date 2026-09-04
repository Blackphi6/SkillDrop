# SkillDrop

GitHub の Agent Skill を、ボタンひとつで **Cursor / Claude Code / Codex** に入れる macOS アプリです（Apple Silicon / arm64 専用）。

## 使い方

1. [Releases](https://github.com/Blackphi6/SkillDrop/releases) から `SkillDrop-macos-arm64.zip` をダウンロード
2. 解凍して `SkillDrop.app` を開く（初回は右クリック → 開く、が必要なことがあります）
3. GitHub URL（または `owner/repo`、`.../SKILL.md` の直リンク）を貼る
4. 入れる先にチェックを入れて **入れる**

本体は `~/.agents/skills` に保存し、選んだエージェントへシンボリックリンクします。

`SKILL.md` への直リンクなら、そのスキルだけ入ります。リポジトリのトップ URL だと、見つかったスキルがまとめて入ります。

## コマンドでも入れる

```bash
./SkillDrop.app/Contents/MacOS/SkillDrop \
  --install https://github.com/coji/natural-japanese \
  --agents cursor,claude,codex
```

## 自分でビルド

Xcode / Swift 6、Apple Silicon Mac が必要です。

```bash
./build-app.sh
open dist/SkillDrop.app
```

## ライセンス

MIT
