import Foundation

/// 入力欄・CLI の URL を改行で分ける
enum InstallInput {
    static func split(_ raw: String) -> [String] {
        raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// 分割が壊れたらここが落ちる
    static func selfCheck() {
        precondition(split("") == [])
        precondition(split("  \n  ") == [])
        precondition(split("a") == ["a"])
        precondition(split("a\nb") == ["a", "b"])
        precondition(split("a\r\nb\n\nc \n") == ["a", "b", "c"])
        precondition(split("  https://x\n\n@pkg  ") == ["https://x", "@pkg"])
    }
}
