import Foundation

/// CLI と GUI の入口を分ける（--install 時はウィンドウを出さない）
@main
enum SkillDropMain {
    static func main() {
        let args = CommandLine.arguments
        if args.contains("--self-check") {
            InstallInput.selfCheck()
            print("ok")
            exit(0)
        }
        if let idx = args.firstIndex(of: "--install"), args.indices.contains(idx + 1) {
            runCLIInstall(input: collectInstallInput(from: args, after: idx), args: args)
            return
        }
        SkillDropApp.main()
    }

    /// `--install` のあとに続く URL を集める（改行付き1引数でも、複数引数でも可）
    private static func collectInstallInput(from args: [String], after idx: Int) -> String {
        var parts: [String] = []
        var i = idx + 1
        while i < args.count {
            let a = args[i]
            if a == "--agents" || a == "--lang" {
                i += 2
                continue
            }
            if a.hasPrefix("--") {
                i += 1
                continue
            }
            parts.append(contentsOf: InstallInput.split(a))
            i += 1
        }
        return parts.joined(separator: "\n")
    }

    private static func runCLIInstall(input: String, args: [String]) {
        var agents = AgentTarget.selectable
        if let aidx = args.firstIndex(of: "--agents"), args.indices.contains(aidx + 1) {
            let ids = Set(args[aidx + 1].split(separator: ",").map(String.init))
            agents = AgentTarget.selectable.filter { ids.contains($0.id) }
        }

        do {
            let result = try SkillInstaller().install(input: input, targets: agents) { print($0) }
            print("OK: \(result.skillNames.joined(separator: ", "))")
            if result.failedCount > 0 {
                fputs("ERROR: \(result.failedCount) failed\n", stderr)
                exit(1)
            }
            exit(0)
        } catch {
            fputs("ERROR: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
