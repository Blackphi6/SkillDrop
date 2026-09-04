import Foundation

/// CLI と GUI の入口を分ける（--install 時はウィンドウを出さない）
@main
enum SkillDropMain {
    static func main() {
        let args = CommandLine.arguments
        if let idx = args.firstIndex(of: "--install"), args.indices.contains(idx + 1) {
            runCLIInstall(url: args[idx + 1], args: args)
            return
        }
        SkillDropApp.main()
    }

    private static func runCLIInstall(url: String, args: [String]) {
        var agents = AgentTarget.selectable
        if let aidx = args.firstIndex(of: "--agents"), args.indices.contains(aidx + 1) {
            let ids = Set(args[aidx + 1].split(separator: ",").map(String.init))
            agents = AgentTarget.selectable.filter { ids.contains($0.id) }
        }

        do {
            let result = try SkillInstaller().install(input: url, targets: agents) { print($0) }
            print("OK: \(result.skillNames.joined(separator: ", "))")
            exit(0)
        } catch {
            fputs("ERROR: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
