#!/usr/bin/env bash
# Apple Silicon (arm64) 向けに SkillDrop.app を作る
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

ARCH="$(uname -m)"
if [[ "$ARCH" != "arm64" ]]; then
  echo "このビルドは Apple Silicon (arm64) 専用です（今: $ARCH）" >&2
  exit 1
fi

if [[ ! -f "$ROOT/Resources/AppIcon.icns" ]]; then
  echo "Resources/AppIcon.icns がありません" >&2
  exit 1
fi

swift build -c release --arch arm64
BIN="$(swift build -c release --arch arm64 --show-bin-path)/SkillDrop"

APP_DIR="$ROOT/dist/SkillDrop.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>SkillDrop</string>
  <key>CFBundleDisplayName</key>
  <string>SkillDrop</string>
  <key>CFBundleIdentifier</key>
  <string>local.skilldrop.app</string>
  <key>CFBundleVersion</key>
  <string>7</string>
  <key>CFBundleShortVersionString</key>
  <string>1.2.3</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleExecutable</key>
  <string>SkillDrop</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIconName</key>
  <string>AppIcon</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <false/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

cp "$BIN" "$APP_DIR/Contents/MacOS/SkillDrop"
chmod +x "$APP_DIR/Contents/MacOS/SkillDrop"
cp "$ROOT/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

# Gatekeeper 対策: 拡張属性を落として ad-hoc 署名
xattr -cr "$APP_DIR" 2>/dev/null || true
codesign --force --deep --sign - "$APP_DIR"
codesign --verify --verbose=2 "$APP_DIR" 2>&1 || true

lipo -info "$APP_DIR/Contents/MacOS/SkillDrop" || true
file "$APP_DIR/Contents/MacOS/SkillDrop"

echo "できたアプリ: $APP_DIR"
echo "起動: open \"$APP_DIR\""
