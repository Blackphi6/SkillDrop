@echo off
REM ダブルクリックで GUI を開く（同じフォルダの exe を使う）
cd /d "%~dp0"
if /I "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
  if exist "SkillDrop-windows-arm64.exe" (
    start "" "SkillDrop-windows-arm64.exe"
    exit /b 0
  )
)
if exist "SkillDrop-windows-amd64.exe" (
  start "" "SkillDrop-windows-amd64.exe"
  exit /b 0
)
if exist "SkillDrop-windows-arm64.exe" (
  start "" "SkillDrop-windows-arm64.exe"
  exit /b 0
)
echo SkillDrop の exe が見つかりません。
pause
