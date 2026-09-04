import Foundation

enum SkillInstallError: LocalizedError {
    case badURL
    case gitFailed(String)
    case noSkillFound
    case copyFailed(String)

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "GitHub の URL（または owner/repo）が読めませんでした"
        case .gitFailed(let msg):
            return "リポジトリの取得に失敗しました: \(msg)"
        case .noSkillFound:
            return "SKILL.md が見つかりませんでした"
        case .copyFailed(let msg):
            return "コピーに失敗しました: \(msg)"
        }
    }
}

struct InstallResult: Sendable {
    let skillNames: [String]
    let log: String
}

/// GitHub のスキルを ~/.agents に置き、選んだエージェントへリンクする
struct SkillInstaller: Sendable {
    func install(input: String, targets: [AgentTarget], onLog: (String) -> Void = { _ in }) throws -> InstallResult {
        var lines: [String] = []
        func log(_ s: String) {
            let shown = Self.tildefy(s)
            lines.append(shown)
            onLog(shown)
        }

        let repo = try Self.parseRepo(input)
        log("対象: \(repo.owner)/\(repo.name)")
        if let filter = repo.pathFilter, !filter.isEmpty {
            log("パス指定: \(filter)")
        }

        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("SkillDrop-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let cloneURL = "https://github.com/\(repo.owner)/\(repo.name).git"
        log("clone: \(cloneURL)")
        let cloneOut = try Self.run("/usr/bin/git", ["clone", "--depth", "1", cloneURL, tempRoot.path])
        if !cloneOut.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            log(cloneOut.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        try? FileManager.default.removeItem(at: tempRoot.appendingPathComponent(".git"))

        var skillDirs = try Self.findSkillDirectories(in: tempRoot, fallbackName: repo.name)
        if let filter = repo.pathFilter, !filter.isEmpty {
            skillDirs = Self.filterSkills(skillDirs, pathFilter: filter)
            log("絞り込み後: \(skillDirs.map(\.name).joined(separator: ", "))")
        } else {
            log("見つかったスキル: \(skillDirs.map(\.name).joined(separator: ", "))")
        }
        guard !skillDirs.isEmpty else { throw SkillInstallError.noSkillFound }

        let fm = FileManager.default
        let canonical = AgentTarget.agentsCanonical
        try fm.createDirectory(at: canonical.skillsDir, withIntermediateDirectories: true)

        var installed: [String] = []
        for skill in skillDirs {
            let name = skill.name
            let src = skill.directory
            let dest = canonical.skillsDir.appendingPathComponent(name)
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
                log("更新: \(dest.path)")
            } else {
                log("新規: \(dest.path)")
            }
            do {
                try fm.copyItem(at: src, to: dest)
            } catch {
                throw SkillInstallError.copyFailed(error.localizedDescription)
            }
            installed.append(name)

            for target in targets {
                try fm.createDirectory(at: target.skillsDir, withIntermediateDirectories: true)
                let link = target.skillsDir.appendingPathComponent(name)
                if fm.fileExists(atPath: link.path) {
                    try? fm.removeItem(at: link)
                }
                try fm.createSymbolicLink(at: link, withDestinationURL: dest)
                log("リンク: \(target.displayName) → \(link.path)")
            }
        }

        log("完了: \(installed.count) 件")
        return InstallResult(skillNames: installed, log: lines.joined(separator: "\n"))
    }

    // MARK: - helpers

    /// ログ用にホームディレクトリを ~ に置き換える
    private static func tildefy(_ s: String) -> String {
        let home = NSHomeDirectory()
        guard !home.isEmpty else { return s }
        if s == home { return "~" }
        if s.hasPrefix(home + "/") {
            return "~" + String(s.dropFirst(home.count))
        }
        return s.replacingOccurrences(of: home + "/", with: "~/")
    }

    private struct Repo {
        let owner: String
        let name: String
        /// blob/tree URL のリポジトリ内パス（SKILL.md やスキルディレクトリ）
        let pathFilter: String?
    }

    private struct FoundSkill {
        let name: String
        let directory: URL
        let relativePath: String
    }

    private static func parseRepo(_ raw: String) throws -> Repo {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SkillInstallError.badURL }

        if let url = URL(string: trimmed), let host = url.host, host.contains("github.com") {
            var parts = url.path.split(separator: "/").map(String.init)
            guard parts.count >= 2 else { throw SkillInstallError.badURL }
            let owner = parts[0]
            let name = parts[1].replacingOccurrences(of: ".git", with: "")
            parts.removeFirst(2)

            // /blob|/tree|/raw/<ref>/... を剥がす
            if parts.count >= 2, ["blob", "tree", "raw"].contains(parts[0]) {
                parts.removeFirst(2)
            }

            let pathFilter: String?
            if parts.isEmpty {
                pathFilter = nil
            } else if parts.last == "SKILL.md" {
                pathFilter = parts.dropLast().joined(separator: "/")
            } else {
                pathFilter = parts.joined(separator: "/")
            }
            return Repo(owner: owner, name: name, pathFilter: pathFilter)
        }

        let parts = trimmed.split(separator: "/").map(String.init)
        guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else {
            throw SkillInstallError.badURL
        }
        let name = parts[1].replacingOccurrences(of: ".git", with: "")
        return Repo(owner: parts[0], name: name, pathFilter: nil)
    }

    private static func filterSkills(_ skills: [FoundSkill], pathFilter: String) -> [FoundSkill] {
        let filter = pathFilter.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let filterName = URL(fileURLWithPath: filter).lastPathComponent
        return skills.filter { skill in
            if skill.relativePath == filter { return true }
            if skill.relativePath.hasSuffix("/" + filter) { return true }
            if skill.relativePath.hasPrefix(filter + "/") { return true }
            if skill.name == filterName { return true }
            return false
        }
    }

    private static func findSkillDirectories(in root: URL, fallbackName: String) throws -> [FoundSkill] {
        let fm = FileManager.default
        var found: [FoundSkill] = []

        let skillsRoot = root.appendingPathComponent("skills")
        if fm.fileExists(atPath: skillsRoot.path) {
            let kids = try fm.contentsOfDirectory(
                at: skillsRoot,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            for kid in kids {
                let skillMD = kid.appendingPathComponent("SKILL.md")
                if fm.fileExists(atPath: skillMD.path) {
                    found.append(
                        FoundSkill(
                            name: kid.lastPathComponent,
                            directory: kid,
                            relativePath: relativePath(of: kid, to: root)
                        )
                    )
                }
            }
        }

        if found.isEmpty {
            let rootSkill = root.appendingPathComponent("SKILL.md")
            if fm.fileExists(atPath: rootSkill.path) {
                found.append(FoundSkill(name: fallbackName, directory: root, relativePath: ""))
            }
        }

        // モノレポ（plugins/*/skills/*/SKILL.md など）も拾う
        let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        var deep: [FoundSkill] = []
        while let item = enumerator?.nextObject() as? URL {
            if item.lastPathComponent == "SKILL.md" {
                let dir = item.deletingLastPathComponent()
                let rel = relativePath(of: dir, to: root)
                let name = dir.path == root.path ? fallbackName : dir.lastPathComponent
                deep.append(FoundSkill(name: name, directory: dir, relativePath: rel))
            }
        }
        var seen = Set(found.map(\.name))
        for s in deep where seen.insert(s.name).inserted {
            found.append(s)
        }

        seen = []
        return found.filter { seen.insert($0.name).inserted }
    }

    private static func relativePath(of url: URL, to root: URL) -> String {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        if path == rootPath { return "" }
        if path.hasPrefix(rootPath + "/") {
            return String(path.dropFirst(rootPath.count + 1))
        }
        return url.lastPathComponent
    }

    @discardableResult
    private static func run(_ launchPath: String, _ args: [String]) throws -> String {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: launchPath)
        proc.arguments = args
        let out = Pipe()
        let err = Pipe()
        proc.standardOutput = out
        proc.standardError = err
        try proc.run()
        proc.waitUntilExit()
        let o = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let e = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        if proc.terminationStatus != 0 {
            throw SkillInstallError.gitFailed(e.isEmpty ? o : e)
        }
        return o + e
    }
}
