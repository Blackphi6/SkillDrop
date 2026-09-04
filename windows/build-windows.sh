#!/usr/bin/env bash
# Windows 向け exe をクロスコンパイルする（この Mac 上で生成）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
mkdir -p ../dist

echo "build amd64..."
GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-s -w" -o ../dist/SkillDrop-windows-amd64.exe .

echo "build arm64..."
GOOS=windows GOARCH=arm64 CGO_ENABLED=0 go build -ldflags="-s -w" -o ../dist/SkillDrop-windows-arm64.exe .

# 起動用バッチ（ダブルクリック向け）
cat > ../dist/SkillDrop-windows.bat <<'BAT'
@echo off
cd /d "%~dp0"
if exist "%~dp0SkillDrop-windows-amd64.exe" (
  start "" "%~dp0SkillDrop-windows-amd64.exe"
  exit /b 0
)
if exist "%~dp0SkillDrop-windows-arm64.exe" (
  start "" "%~dp0SkillDrop-windows-arm64.exe"
  exit /b 0
)
echo SkillDrop exe が見つかりません
pause
BAT

ls -lh ../dist/SkillDrop-windows-*.exe ../dist/SkillDrop-windows.bat
file ../dist/SkillDrop-windows-amd64.exe ../dist/SkillDrop-windows-arm64.exe
echo "done"
