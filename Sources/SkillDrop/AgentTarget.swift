import Foundation

/// 導入先エージェント（ホーム直下の skills ディレクトリ）
struct AgentTarget: Identifiable, Hashable, Sendable {
    let id: String
    let displayNameKey: String
    let skillsDir: URL

    var displayName: String {
        if displayNameKey.hasPrefix("lit:") {
            return String(displayNameKey.dropFirst(4))
        }
        return L10n.t(displayNameKey)
    }

    static let agentsCanonical = AgentTarget(
        id: "agents",
        displayNameKey: "agents_canonical",
        skillsDir: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".agents/skills")
    )

    static let cursor = AgentTarget(
        id: "cursor",
        displayNameKey: "lit:Cursor",
        skillsDir: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".cursor/skills")
    )

    static let claude = AgentTarget(
        id: "claude",
        displayNameKey: "lit:Claude Code",
        skillsDir: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".claude/skills")
    )

    static let codex = AgentTarget(
        id: "codex",
        displayNameKey: "lit:Codex",
        skillsDir: URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".codex/skills")
    )

    /// UI で選べる導入先（本体は常に入れる）
    static let selectable: [AgentTarget] = [.cursor, .claude, .codex]
}
