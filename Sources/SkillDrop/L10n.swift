import Foundation

/// システム言語に合わせて UI / ログ文言を切り替える（ja / en / zh-Hans）
enum AppLanguage: String, CaseIterable {
    case ja
    case en
    case zhHans = "zh-Hans"

    static var current: AppLanguage {
        for id in Locale.preferredLanguages {
            let lower = id.lowercased()
            if lower.hasPrefix("ja") { return .ja }
            if lower.hasPrefix("zh") { return .zhHans }
            if lower.hasPrefix("en") { return .en }
        }
        if let code = Locale.current.language.languageCode?.identifier {
            if code == "ja" { return .ja }
            if code == "zh" { return .zhHans }
            if code == "en" { return .en }
        }
        return .en
    }
}

enum L10n {
    private static var lang: AppLanguage { .current }

    static func t(_ key: String) -> String {
        table[lang]?[key] ?? table[.en]?[key] ?? key
    }

    static func tf(_ key: String, _ args: CVarArg...) -> String {
        String(format: t(key), arguments: args)
    }

    private static let table: [AppLanguage: [String: String]] = [
        .ja: [
            "subtitle": "URL を入れて、ボタンひとつでエージェントにスキルを入れます。",
            "url_label": "GitHub URL・owner/repo・SKILL.md のリンクでもOK",
            "url_placeholder": "https://github.com/owner/repo/.../SKILL.md",
            "targets_label": "入れる先",
            "targets_note": "本体は常に ~/.agents/skills に保存し、選んだ先へリンクします。",
            "install": "入れる",
            "installing": "入れています…",
            "installed_skills": "入ったスキル: %@",
            "log_label": "ログ",
            "log_hint": "GitHub のスキル URL を入れて「入れる」を押してください。\nCursor / Claude Code / Codex にまとめて入ります。",
            "log_ready": "新しいチャットを開くとスキルが使えます。",
            "error_prefix": "エラー: %@",
            "agents_canonical": "共通本体 (~/.agents)",
            "err_bad_url": "GitHub の URL（または owner/repo）が読めませんでした",
            "err_git": "リポジトリの取得に失敗しました: %@",
            "err_no_skill": "SKILL.md が見つかりませんでした",
            "err_copy": "コピーに失敗しました: %@",
            "log_target": "対象: %@/%@",
            "log_path": "パス指定: %@",
            "log_clone": "clone: %@",
            "log_filtered": "絞り込み後: %@",
            "log_found": "見つかったスキル: %@",
            "log_update": "更新: %@",
            "log_new": "新規: %@",
            "log_link": "リンク: %@ → %@",
            "log_done": "完了: %d 件",
        ],
        .en: [
            "subtitle": "Paste a URL and install Agent Skills into your tools in one click.",
            "url_label": "GitHub URL, owner/repo, or a SKILL.md link",
            "url_placeholder": "https://github.com/owner/repo/.../SKILL.md",
            "targets_label": "Install to",
            "targets_note": "The skill is always saved under ~/.agents/skills, then linked to the targets you select.",
            "install": "Install",
            "installing": "Installing…",
            "installed_skills": "Installed: %@",
            "log_label": "Log",
            "log_hint": "Paste a GitHub skill URL and press Install.\nIt will be added to Cursor / Claude Code / Codex.",
            "log_ready": "Open a new chat to start using the skill.",
            "error_prefix": "Error: %@",
            "agents_canonical": "Shared store (~/.agents)",
            "err_bad_url": "Could not parse the GitHub URL (or owner/repo)",
            "err_git": "Failed to fetch the repository: %@",
            "err_no_skill": "SKILL.md was not found",
            "err_copy": "Copy failed: %@",
            "log_target": "Target: %@/%@",
            "log_path": "Path filter: %@",
            "log_clone": "clone: %@",
            "log_filtered": "Filtered: %@",
            "log_found": "Found skills: %@",
            "log_update": "Updated: %@",
            "log_new": "New: %@",
            "log_link": "Link: %@ → %@",
            "log_done": "Done: %d skill(s)",
        ],
        .zhHans: [
            "subtitle": "粘贴 URL，一键把 Agent Skill 安装到各工具。",
            "url_label": "可用 GitHub URL、owner/repo，或 SKILL.md 链接",
            "url_placeholder": "https://github.com/owner/repo/.../SKILL.md",
            "targets_label": "安装到",
            "targets_note": "技能始终保存在 ~/.agents/skills，再链接到你勾选的目标。",
            "install": "安装",
            "installing": "正在安装…",
            "installed_skills": "已安装：%@",
            "log_label": "日志",
            "log_hint": "粘贴 GitHub 技能 URL，然后点击「安装」。\n将安装到 Cursor / Claude Code / Codex。",
            "log_ready": "打开新的对话即可使用该技能。",
            "error_prefix": "错误：%@",
            "agents_canonical": "公共目录 (~/.agents)",
            "err_bad_url": "无法解析 GitHub URL（或 owner/repo）",
            "err_git": "获取仓库失败：%@",
            "err_no_skill": "未找到 SKILL.md",
            "err_copy": "复制失败：%@",
            "log_target": "目标：%@/%@",
            "log_path": "路径筛选：%@",
            "log_clone": "clone: %@",
            "log_filtered": "筛选后：%@",
            "log_found": "找到的技能：%@",
            "log_update": "更新：%@",
            "log_new": "新建：%@",
            "log_link": "链接：%@ → %@",
            "log_done": "完成：%d 个",
        ],
    ]
}
