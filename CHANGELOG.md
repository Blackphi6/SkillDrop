# Changelog

## v1.1.1 — 2026-09-04

- macOS zip から AppleDouble (`._*`) を除去
- ad-hoc 署名を付与
- `Install.command` を同梱（隔離属性を外して /Applications へ入れて起動）
- 「壊れているため開けません」対策

## v1.1.0 — 2026-09-04

- Windows 版を追加（amd64 / arm64 の `.exe`、ブラウザ GUI）
- **実機 Windows での動作は未確認**（Mac 上でクロスビルド＋ロジックのスモークのみ）
- `windows/` に Go 実装を追加

## v1.0.1 — 2026-09-04

- 初回公開（Apple Silicon / arm64）
- Cursor / Claude Code / Codex への Agent Skill 一括導入
- `SKILL.md` 直リンクでの単一スキル絞り込み
- アプリアイコン同梱
