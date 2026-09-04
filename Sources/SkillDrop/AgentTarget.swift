import Foundation

/// 導入先エージェント（ホーム直下の skills ディレクトリ）
struct AgentTarget: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let skillsDir: URL

    static let agentsCanonical = AgentTarget(
        id: "agents",
        displayName: "共通本体 (~/.agents)",
        skillsDir: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".agents/skills")
    )

    static let cursor = AgentTarget(
        id: "cursor",
        displayName: "Cursor",
        skillsDir: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".cursor/skills")
    )

    static let claude = AgentTarget(
        id: "claude",
        displayName: "Claude Code",
        skillsDir: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".claude/skills")
    )

    static let codex = AgentTarget(
        id: "codex",
        displayName: "Codex",
        skillsDir: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".codex/skills")
    )

    /// UI で選べる導入先（本体は常に入れる）
    static let selectable: [AgentTarget] = [.cursor, .claude, .codex]
}
