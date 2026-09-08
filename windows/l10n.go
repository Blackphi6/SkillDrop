package main

import (
	"fmt"
	"os"
	"strings"
)

type appLang string

const (
	langJA appLang = "ja"
	langEN appLang = "en"
	langZH appLang = "zh-Hans"
)

func detectLang(explicit string) appLang {
	if explicit != "" {
		return normalizeLang(explicit)
	}
	for _, key := range []string{"LANG", "LC_ALL", "LC_MESSAGES"} {
		if v := os.Getenv(key); v != "" {
			return normalizeLang(v)
		}
	}
	return langEN
}

func normalizeLang(raw string) appLang {
	lower := strings.ToLower(strings.ReplaceAll(raw, "_", "-"))
	if strings.HasPrefix(lower, "ja") {
		return langJA
	}
	if strings.HasPrefix(lower, "zh") {
		return langZH
	}
	if strings.HasPrefix(lower, "en") {
		return langEN
	}
	return langEN
}

var i18nTable = map[appLang]map[string]string{
	langJA: {
		"err_bad_url":    "GitHub の URL（または owner/repo）が読めませんでした",
		"err_git":        "リポジトリの取得に失敗しました: %v",
		"err_no_skill":   "SKILL.md が見つかりませんでした",
		"err_copy":       "コピー失敗: %w",
		"log_target":     "対象: %s/%s",
		"log_path":       "パス指定: %s",
		"log_clone":      "clone: %s",
		"log_filtered":   "絞り込み後: %s",
		"log_found":      "見つかったスキル: %s",
		"log_update":     "更新: %s",
		"log_new":        "新規: %s",
		"log_link":       "リンク: %s → %s",
		"log_done":       "完了: %d 件",
		"log_item":       "--- %d / %d ---\n%s",
		"log_batch_done": "まとめ: 入った %d 件 / 失敗 %d 件",
		"gui_hint":       "ブラウザが開きます。閉じるにはこのウィンドウで Ctrl+C。",
		"gui_url":        "SkillDrop GUI: %s",
	},
	langEN: {
		"err_bad_url":    "Could not parse the GitHub URL (or owner/repo)",
		"err_git":        "Failed to fetch the repository: %v",
		"err_no_skill":   "SKILL.md was not found",
		"err_copy":       "Copy failed: %w",
		"log_target":     "Target: %s/%s",
		"log_path":       "Path filter: %s",
		"log_clone":      "clone: %s",
		"log_filtered":   "Filtered: %s",
		"log_found":      "Found skills: %s",
		"log_update":     "Updated: %s",
		"log_new":        "New: %s",
		"log_link":       "Link: %s → %s",
		"log_done":       "Done: %d skill(s)",
		"log_item":       "--- %d / %d ---\n%s",
		"log_batch_done": "Summary: %d installed / %d failed",
		"gui_hint":       "Opening the browser. Press Ctrl+C in this window to quit.",
		"gui_url":        "SkillDrop GUI: %s",
	},
	langZH: {
		"err_bad_url":    "无法解析 GitHub URL（或 owner/repo）",
		"err_git":        "获取仓库失败：%v",
		"err_no_skill":   "未找到 SKILL.md",
		"err_copy":       "复制失败：%w",
		"log_target":     "目标：%s/%s",
		"log_path":       "路径筛选：%s",
		"log_clone":      "clone: %s",
		"log_filtered":   "筛选后：%s",
		"log_found":      "找到的技能：%s",
		"log_update":     "更新：%s",
		"log_new":        "新建：%s",
		"log_link":       "链接：%s → %s",
		"log_done":       "完成：%d 个",
		"log_item":       "--- %d / %d ---\n%s",
		"log_batch_done": "汇总：成功 %d 个 / 失败 %d 个",
		"gui_hint":       "正在打开浏览器。在此窗口按 Ctrl+C 退出。",
		"gui_url":        "SkillDrop GUI: %s",
	},
}

func tr(lang appLang, key string) string {
	if m, ok := i18nTable[lang]; ok {
		if v, ok := m[key]; ok {
			return v
		}
	}
	return i18nTable[langEN][key]
}

func trf(lang appLang, key string, args ...any) string {
	return fmt.Sprintf(tr(lang, key), args...)
}
