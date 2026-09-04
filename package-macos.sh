#!/usr/bin/env bash
# macOS 配布用 zip（._* なし・隔離解除用 Install.command 同梱）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

./build-app.sh

STAGE="$ROOT/dist/macos-stage"
ZIP="$ROOT/dist/SkillDrop-macos-arm64.zip"
rm -rf "$STAGE" "$ZIP"
mkdir -p "$STAGE"

# リソースフォークを付けずにコピー
ditto --norsrc --noextattr "$ROOT/dist/SkillDrop.app" "$STAGE/SkillDrop.app"
xattr -cr "$STAGE/SkillDrop.app" 2>/dev/null || true
codesign --force --deep --sign - "$STAGE/SkillDrop.app"

# ダブルクリックで Applications へ入れて開く
cat > "$STAGE/Install.command" <<'CMD'
#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
APP="SkillDrop.app"
if [[ ! -d "$APP" ]]; then
  echo "SkillDrop.app が見つかりません" >&2
  read -r -p "Enter で閉じる… "
  exit 1
fi
echo "隔離フラグを外しています…"
xattr -cr "$APP" 2>/dev/null || true
echo "アプリケーションフォルダへコピーしています…"
rm -rf "/Applications/SkillDrop.app"
ditto --norsrc --noextattr "$APP" "/Applications/SkillDrop.app"
xattr -cr "/Applications/SkillDrop.app" 2>/dev/null || true
codesign --force --deep --sign - "/Applications/SkillDrop.app" 2>/dev/null || true
echo "起動します…"
open "/Applications/SkillDrop.app"
echo "完了。この窓は閉じて大丈夫です。"
sleep 2
CMD
chmod +x "$STAGE/Install.command"

cat > "$STAGE/README-open.txt" <<'TXT'
SkillDrop (macOS) — how to open
===============================

This build is not Apple-notarized yet, so a browser download may show
"SkillDrop.app is damaged and can't be opened".

Easiest fix:
  1. Double-click Install.command in this folder
  2. Approve Terminal / Open on first run
  3. It copies to /Applications and launches

Manual fix:
  xattr -cr /Applications/SkillDrop.app
  open /Applications/SkillDrop.app
TXT

# ._ ファイルを出さない zip
(
  cd "$STAGE"
  COPYFILE_DISABLE=1 zip -r -X "$ZIP" SkillDrop.app Install.command README-open.txt
)

echo "zip 内容:"
unzip -l "$ZIP"
echo "できた: $ZIP"
