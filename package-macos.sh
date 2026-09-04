#!/usr/bin/env bash
# macOS 配布用 zip（._* なし・ad-hoc 署名）。Install.command は同梱しない
# （.command 自体が Gatekeeper に引っかかって手間が増えるため）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

./build-app.sh

STAGE="$ROOT/dist/macos-stage"
ZIP="$ROOT/dist/SkillDrop-macos-arm64.zip"
rm -rf "$STAGE" "$ZIP"
mkdir -p "$STAGE"

ditto --norsrc --noextattr "$ROOT/dist/SkillDrop.app" "$STAGE/SkillDrop.app"
xattr -cr "$STAGE/SkillDrop.app" 2>/dev/null || true
codesign --force --deep --sign - "$STAGE/SkillDrop.app"

cat > "$STAGE/README-open.txt" <<'TXT'
SkillDrop (macOS)

おすすめの入れ方（Gatekeeper の警告を避けやすい）:

  brew tap Blackphi6/skilldrop https://github.com/Blackphi6/SkillDrop
  brew install --cask skilldrop

zip から手動で入れる場合:

  xattr -cr /path/to/SkillDrop.app
  open /path/to/SkillDrop.app

※ Apple の有料デベロッパ登録＋公証がないと、
  ダウンロードした .app をダブルクリックしただけでは警告が出ます。
TXT

(
  cd "$STAGE"
  COPYFILE_DISABLE=1 zip -r -X "$ZIP" SkillDrop.app README-open.txt
)

echo "zip 内容:"
unzip -l "$ZIP"
echo "SHA256: $(shasum -a 256 "$ZIP" | awk '{print $1}')"
echo "できた: $ZIP"
