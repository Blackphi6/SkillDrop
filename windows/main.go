package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

type agentTarget struct {
	ID          string `json:"id"`
	DisplayName string `json:"displayName"`
	SkillsDir   string `json:"-"`
}

func homeDir() string {
	h, err := os.UserHomeDir()
	if err != nil {
		return ""
	}
	return h
}

func selectableAgents() []agentTarget {
	h := homeDir()
	return []agentTarget{
		{ID: "cursor", DisplayName: "Cursor", SkillsDir: filepath.Join(h, ".cursor", "skills")},
		{ID: "claude", DisplayName: "Claude Code", SkillsDir: filepath.Join(h, ".claude", "skills")},
		{ID: "codex", DisplayName: "Codex", SkillsDir: filepath.Join(h, ".codex", "skills")},
	}
}

func agentsCanonical() agentTarget {
	return agentTarget{
		ID:          "agents",
		DisplayName: "共通本体",
		SkillsDir:   filepath.Join(homeDir(), ".agents", "skills"),
	}
}

type repoRef struct {
	Owner      string
	Name       string
	PathFilter string
}

type foundSkill struct {
	Name         string
	Directory    string
	RelativePath string
}

type installResult struct {
	SkillNames []string `json:"skillNames"`
	Log        string   `json:"log"`
}

func parseRepo(raw string) (repoRef, error) {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return repoRef{}, errors.New("bad_url")
	}

	if strings.Contains(trimmed, "github.com") {
		u := trimmed
		u = strings.TrimPrefix(u, "https://")
		u = strings.TrimPrefix(u, "http://")
		u = strings.TrimPrefix(u, "www.")
		parts := strings.Split(strings.Trim(u, "/"), "/")
		if len(parts) < 3 || parts[0] != "github.com" {
			return repoRef{}, errors.New("bad_url")
		}
		owner := parts[1]
		name := strings.TrimSuffix(parts[2], ".git")
		rest := parts[3:]
		if len(rest) >= 2 && (rest[0] == "blob" || rest[0] == "tree" || rest[0] == "raw") {
			rest = rest[2:]
		}
		filter := ""
		if len(rest) > 0 {
			if rest[len(rest)-1] == "SKILL.md" {
				rest = rest[:len(rest)-1]
			}
			filter = strings.Join(rest, "/")
		}
		return repoRef{Owner: owner, Name: name, PathFilter: filter}, nil
	}

	parts := strings.Split(trimmed, "/")
	if len(parts) != 2 || parts[0] == "" || parts[1] == "" {
		return repoRef{}, errors.New("bad_url")
	}
	return repoRef{Owner: parts[0], Name: strings.TrimSuffix(parts[1], ".git")}, nil
}

func runGit(args ...string) (string, error) {
	cmd := exec.Command("git", args...)
	out, err := cmd.CombinedOutput()
	s := string(out)
	if err != nil {
		return s, fmt.Errorf("%v\n%s", err, s)
	}
	return s, nil
}

func relativePath(path, root string) string {
	rel, err := filepath.Rel(root, path)
	if err != nil {
		return filepath.Base(path)
	}
	if rel == "." {
		return ""
	}
	return filepath.ToSlash(rel)
}

func findSkillDirectories(root, fallbackName string) ([]foundSkill, error) {
	var found []foundSkill
	skillsRoot := filepath.Join(root, "skills")
	if st, err := os.Stat(skillsRoot); err == nil && st.IsDir() {
		entries, err := os.ReadDir(skillsRoot)
		if err == nil {
			for _, e := range entries {
				if !e.IsDir() {
					continue
				}
				dir := filepath.Join(skillsRoot, e.Name())
				if _, err := os.Stat(filepath.Join(dir, "SKILL.md")); err == nil {
					found = append(found, foundSkill{
						Name:         e.Name(),
						Directory:    dir,
						RelativePath: relativePath(dir, root),
					})
				}
			}
		}
	}

	if _, err := os.Stat(filepath.Join(root, "SKILL.md")); err == nil && len(found) == 0 {
		found = append(found, foundSkill{Name: fallbackName, Directory: root, RelativePath: ""})
	}

	_ = filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil
		}
		if d.IsDir() {
			base := d.Name()
			if base == ".git" || base == "node_modules" {
				return filepath.SkipDir
			}
			return nil
		}
		if d.Name() != "SKILL.md" {
			return nil
		}
		dir := filepath.Dir(path)
		name := filepath.Base(dir)
		if filepath.Clean(dir) == filepath.Clean(root) {
			name = fallbackName
		}
		found = append(found, foundSkill{
			Name:         name,
			Directory:    dir,
			RelativePath: relativePath(dir, root),
		})
		return nil
	})

	seen := map[string]bool{}
	var uniq []foundSkill
	for _, s := range found {
		if seen[s.Name] {
			continue
		}
		seen[s.Name] = true
		uniq = append(uniq, s)
	}
	return uniq, nil
}

func filterSkills(skills []foundSkill, pathFilter string) []foundSkill {
	filter := strings.Trim(filepath.ToSlash(pathFilter), "/")
	filterName := filepath.Base(filter)
	var out []foundSkill
	for _, s := range skills {
		rel := strings.Trim(s.RelativePath, "/")
		if rel == filter || strings.HasSuffix(rel, "/"+filter) || strings.HasPrefix(rel, filter+"/") || s.Name == filterName {
			out = append(out, s)
		}
	}
	return out
}

func copyDir(src, dst string) error {
	return filepath.WalkDir(src, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(src, path)
		if err != nil {
			return err
		}
		target := filepath.Join(dst, rel)
		if d.IsDir() {
			return os.MkdirAll(target, 0o755)
		}
		in, err := os.Open(path)
		if err != nil {
			return err
		}
		defer in.Close()
		if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
			return err
		}
		out, err := os.OpenFile(target, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o644)
		if err != nil {
			return err
		}
		defer out.Close()
		_, err = io.Copy(out, in)
		return err
	})
}

func linkOrCopy(dest, link string) error {
	_ = os.RemoveAll(link)
	if err := os.Symlink(dest, link); err == nil {
		return nil
	}
	// Windows で symlink が拒否される場合はコピーに落とす
	return copyDir(dest, link)
}

func splitInputs(raw string) []string {
	raw = strings.ReplaceAll(strings.ReplaceAll(raw, "\r\n", "\n"), "\r", "\n")
	var out []string
	for _, line := range strings.Split(raw, "\n") {
		line = strings.TrimSpace(line)
		if line != "" {
			out = append(out, line)
		}
	}
	return out
}

func install(input string, agentIDs []string, lang appLang, logfn func(string)) (installResult, error) {
	items := splitInputs(input)
	if len(items) == 0 {
		return installResult{}, errors.New(tr(lang, "err_bad_url"))
	}
	if len(items) == 1 {
		return installOne(items[0], agentIDs, lang, logfn)
	}

	var names []string
	var lines []string
	failed := 0
	var lastErr error
	emit := func(s string) {
		s = tildefy(s)
		lines = append(lines, s)
		if logfn != nil {
			logfn(s)
		}
	}
	for i, item := range items {
		emit(trf(lang, "log_item", i+1, len(items), item))
		res, err := installOne(item, agentIDs, lang, func(s string) {
			lines = append(lines, s)
			if logfn != nil {
				logfn(s)
			}
		})
		if err != nil {
			lastErr = err
			failed++
			emit("ERROR: " + err.Error())
			continue
		}
		names = append(names, res.SkillNames...)
	}
	emit(trf(lang, "log_batch_done", len(names), failed))
	if len(names) == 0 {
		if lastErr != nil {
			return installResult{Log: strings.Join(lines, "\n")}, lastErr
		}
		return installResult{Log: strings.Join(lines, "\n")}, errors.New(tr(lang, "err_bad_url"))
	}
	return installResult{SkillNames: names, Log: strings.Join(lines, "\n")}, nil
}

func installOne(input string, agentIDs []string, lang appLang, logfn func(string)) (installResult, error) {
	var lines []string
	log := func(s string) {
		shown := tildefy(s)
		lines = append(lines, shown)
		if logfn != nil {
			logfn(shown)
		}
	}

	repo, err := parseRepo(input)
	if err != nil {
		return installResult{}, errors.New(tr(lang, "err_bad_url"))
	}
	log(trf(lang, "log_target", repo.Owner, repo.Name))
	if repo.PathFilter != "" {
		log(trf(lang, "log_path", repo.PathFilter))
	}

	tempRoot, err := os.MkdirTemp("", "SkillDrop-*")
	if err != nil {
		return installResult{}, err
	}
	defer os.RemoveAll(tempRoot)

	cloneURL := fmt.Sprintf("https://github.com/%s/%s.git", repo.Owner, repo.Name)
	log(trf(lang, "log_clone", cloneURL))
	out, err := runGit("clone", "--depth", "1", cloneURL, tempRoot)
	if strings.TrimSpace(out) != "" {
		log(strings.TrimSpace(out))
	}
	if err != nil {
		return installResult{}, fmt.Errorf(tr(lang, "err_git"), err)
	}
	_ = os.RemoveAll(filepath.Join(tempRoot, ".git"))

	skills, err := findSkillDirectories(tempRoot, repo.Name)
	if err != nil {
		return installResult{}, err
	}
	if repo.PathFilter != "" {
		skills = filterSkills(skills, repo.PathFilter)
		log(trf(lang, "log_filtered", joinNames(skills)))
	} else {
		log(trf(lang, "log_found", joinNames(skills)))
	}
	if len(skills) == 0 {
		return installResult{}, errors.New(tr(lang, "err_no_skill"))
	}

	canonical := agentsCanonical()
	if err := os.MkdirAll(canonical.SkillsDir, 0o755); err != nil {
		return installResult{}, err
	}

	want := map[string]bool{}
	for _, id := range agentIDs {
		want[id] = true
	}
	var targets []agentTarget
	for _, a := range selectableAgents() {
		if want[a.ID] {
			targets = append(targets, a)
		}
	}

	var installed []string
	for _, skill := range skills {
		dest := filepath.Join(canonical.SkillsDir, skill.Name)
		if _, err := os.Stat(dest); err == nil {
			_ = os.RemoveAll(dest)
			log(trf(lang, "log_update", dest))
		} else {
			log(trf(lang, "log_new", dest))
		}
		if err := copyDir(skill.Directory, dest); err != nil {
			return installResult{}, fmt.Errorf(tr(lang, "err_copy"), err)
		}
		installed = append(installed, skill.Name)
		for _, t := range targets {
			if err := os.MkdirAll(t.SkillsDir, 0o755); err != nil {
				return installResult{}, err
			}
			link := filepath.Join(t.SkillsDir, skill.Name)
			if err := linkOrCopy(dest, link); err != nil {
				return installResult{}, err
			}
			log(trf(lang, "log_link", t.DisplayName, link))
		}
	}

	log(trf(lang, "log_done", len(installed)))
	return installResult{SkillNames: installed, Log: strings.Join(lines, "\n")}, nil
}

func joinNames(skills []foundSkill) string {
	names := make([]string, 0, len(skills))
	for _, s := range skills {
		names = append(names, s.Name)
	}
	return strings.Join(names, ", ")
}

// ログ用にホームディレクトリを ~ に置き換える
func tildefy(s string) string {
	home := homeDir()
	if home == "" {
		return s
	}
	home = filepath.Clean(home)
	if s == home {
		return "~"
	}
	prefix := home + string(filepath.Separator)
	if strings.HasPrefix(s, prefix) {
		return "~/" + filepath.ToSlash(strings.TrimPrefix(s, prefix))
	}
	// git のメッセージなどに絶対パスが混ざる場合
	return strings.ReplaceAll(s, prefix, "~/")
}

func openBrowser(url string) {
	var cmd *exec.Cmd
	switch runtime.GOOS {
	case "windows":
		cmd = exec.Command("rundll32", "url.dll,FileProtocolHandler", url)
	case "darwin":
		cmd = exec.Command("open", url)
	default:
		cmd = exec.Command("xdg-open", url)
	}
	_ = cmd.Start()
}

func runGUI() error {
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		_, _ = w.Write([]byte(indexHTML))
	})
	mux.HandleFunc("/api/install", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "POST only", http.StatusMethodNotAllowed)
			return
		}
		var req struct {
			URL    string   `json:"url"`
			Agents []string `json:"agents"`
			Lang   string   `json:"lang"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		lang := detectLang(req.Lang)
		res, err := install(req.URL, req.Agents, lang, nil)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		if err != nil {
			_ = json.NewEncoder(w).Encode(map[string]any{
				"ok":    false,
				"error": err.Error(),
				"log":   res.Log,
			})
			return
		}
		_ = json.NewEncoder(w).Encode(map[string]any{
			"ok":         true,
			"skillNames": res.SkillNames,
			"log":        res.Log,
		})
	})

	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return err
	}
	lang := detectLang("")
	url := fmt.Sprintf("http://%s", ln.Addr().String())
	fmt.Println(trf(lang, "gui_url", url))
	fmt.Println(tr(lang, "gui_hint"))
	go func() {
		time.Sleep(300 * time.Millisecond)
		openBrowser(url)
	}()
	return http.Serve(ln, mux)
}

func main() {
	args := os.Args[1:]
	if len(args) >= 1 && args[0] == "--self-check" {
		got := strings.Join(splitInputs("a\r\nb\n\nc "), ",")
		if got != "a,b,c" {
			fmt.Fprintln(os.Stderr, "self-check failed:", got)
			os.Exit(1)
		}
		fmt.Println("ok")
		return
	}
	if len(args) >= 2 && args[0] == "--install" {
		var urls []string
		agents := []string{"cursor", "claude", "codex"}
		lang := detectLang("")
		for i := 1; i < len(args); i++ {
			a := args[i]
			if a == "--agents" || a == "--lang" {
				if i+1 < len(args) {
					if a == "--agents" {
						agents = strings.Split(args[i+1], ",")
					} else {
						lang = detectLang(args[i+1])
					}
					i++
				}
				continue
			}
			if strings.HasPrefix(a, "--") {
				continue
			}
			urls = append(urls, splitInputs(a)...)
		}
		res, err := install(strings.Join(urls, "\n"), agents, lang, func(s string) { fmt.Println(s) })
		if err != nil {
			fmt.Fprintln(os.Stderr, "ERROR:", err)
			os.Exit(1)
		}
		fmt.Println("OK:", strings.Join(res.SkillNames, ", "))
		return
	}

	if err := runGUI(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
