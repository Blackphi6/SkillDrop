package main

const indexHTML = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>SkillDrop</title>
<style>
  :root { color-scheme: light dark; --bg:#1c1c1e; --fg:#f5f5f7; --muted:#a1a1a6; --accent:#e8a838; --card:#2c2c2e; --ok:#30d158; --err:#ff453a; }
  * { box-sizing: border-box; }
  body { margin:0; font-family: "Segoe UI", system-ui, sans-serif; background: var(--bg); color: var(--fg); }
  main { max-width: 640px; margin: 0 auto; padding: 32px 24px 48px; }
  h1 { font-size: 28px; margin: 0 0 6px; font-weight: 650; }
  .sub { color: var(--muted); font-size: 14px; margin-bottom: 28px; }
  label { display:block; font-size:12px; color: var(--muted); margin-bottom: 8px; }
  input[type=text] { width:100%; padding:12px 14px; border-radius:10px; border:1px solid #3a3a3c; background:#000; color:var(--fg); font-family: ui-monospace, Consolas, monospace; font-size:14px; }
  .agents { display:flex; gap:16px; flex-wrap:wrap; margin: 18px 0 22px; }
  .agents label { display:flex; gap:8px; align-items:center; color:var(--fg); font-size:14px; margin:0; }
  button { background: var(--accent); color:#111; border:0; border-radius:10px; padding:12px 22px; font-size:15px; font-weight:650; cursor:pointer; }
  button:disabled { opacity:.55; cursor:wait; }
  pre { margin-top:20px; background:var(--card); border-radius:12px; padding:14px; min-height:160px; white-space:pre-wrap; word-break:break-word; font-size:12px; line-height:1.5; color:#ddd; }
  .note { font-size:12px; color:var(--muted); margin-top:10px; }
  .status { margin-top:12px; font-size:13px; }
  .status.ok { color: var(--ok); }
  .status.err { color: var(--err); }
  .lang { margin-bottom: 16px; }
  .lang select { background:#000; color:var(--fg); border:1px solid #3a3a3c; border-radius:8px; padding:6px 10px; }
</style>
</head>
<body>
<main>
  <div class="lang">
    <select id="lang">
      <option value="en">English</option>
      <option value="ja">日本語</option>
      <option value="zh-Hans">简体中文</option>
    </select>
  </div>
  <h1>SkillDrop</h1>
  <p class="sub" data-i18n="subtitle"></p>
  <label for="url" data-i18n="url_label"></label>
  <input id="url" type="text" data-i18n-placeholder="url_placeholder" value=""/>
  <div class="agents">
    <label><input type="checkbox" value="cursor" checked/> Cursor</label>
    <label><input type="checkbox" value="claude" checked/> Claude Code</label>
    <label><input type="checkbox" value="codex" checked/> Codex</label>
  </div>
  <button id="go" type="button" data-i18n="install"></button>
  <div id="status" class="status"></div>
  <p class="note" data-i18n="note"></p>
  <pre id="log" data-i18n="log_hint"></pre>
</main>
<script>
const I18N = {
  en: {
    subtitle: "Paste a URL and install Agent Skills into Cursor / Claude Code / Codex.<br/>(Windows build — behavior may vary by environment)",
    url_label: "GitHub URL, owner/repo, or a SKILL.md link",
    url_placeholder: "https://github.com/owner/repo/.../SKILL.md",
    install: "Install",
    installing: "Installing…",
    note: "Saved under %USERPROFILE%\\.agents\\skills. Git must be on PATH.",
    log_hint: "Log output appears here.",
    done: "Done: ",
    failed: "Failed",
    ready: "\n\nOpen a new chat to start using the skill."
  },
  ja: {
    subtitle: "GitHub のスキル URL を入れて、Cursor / Claude Code / Codex にまとめて入れます。<br/>（Windows 版・動作は環境によって未確認のことがあります）",
    url_label: "GitHub URL・owner/repo・SKILL.md のリンク",
    url_placeholder: "https://github.com/owner/repo/.../SKILL.md",
    install: "入れる",
    installing: "入れています…",
    note: "本体は %USERPROFILE%\\.agents\\skills に保存します。git が PATH に入っている必要があります。",
    log_hint: "ログがここに出ます。",
    done: "完了: ",
    failed: "失敗しました",
    ready: "\n\n新しいチャットを開くとスキルが使えます。"
  },
  "zh-Hans": {
    subtitle: "粘贴 GitHub 技能 URL，一键安装到 Cursor / Claude Code / Codex。<br/>（Windows 版，实际效果可能因环境而异）",
    url_label: "可用 GitHub URL、owner/repo，或 SKILL.md 链接",
    url_placeholder: "https://github.com/owner/repo/.../SKILL.md",
    install: "安装",
    installing: "正在安装…",
    note: "保存在 %USERPROFILE%\\.agents\\skills。需要 PATH 中有 git。",
    log_hint: "日志会显示在这里。",
    done: "完成：",
    failed: "失败",
    ready: "\n\n打开新的对话即可使用该技能。"
  }
};

function detectLang() {
  const nav = (navigator.language || "en").toLowerCase();
  if (nav.startsWith("ja")) return "ja";
  if (nav.startsWith("zh")) return "zh-Hans";
  return "en";
}

function applyI18n(lang) {
  const t = I18N[lang] || I18N.en;
  document.documentElement.lang = lang === "zh-Hans" ? "zh-CN" : lang;
  document.querySelectorAll("[data-i18n]").forEach(el => {
    el.innerHTML = t[el.dataset.i18n] || "";
  });
  document.querySelectorAll("[data-i18n-placeholder]").forEach(el => {
    el.placeholder = t[el.dataset.i18nPlaceholder] || "";
  });
  document.getElementById("go").textContent = t.install;
}

const langSel = document.getElementById("lang");
langSel.value = detectLang();
applyI18n(langSel.value);
langSel.onchange = () => applyI18n(langSel.value);

const btn = document.getElementById("go");
const logEl = document.getElementById("log");
const statusEl = document.getElementById("status");
btn.onclick = async () => {
  const t = I18N[langSel.value] || I18N.en;
  const url = document.getElementById("url").value.trim();
  const agents = [...document.querySelectorAll(".agents input:checked")].map(x => x.value);
  if (!url || agents.length === 0) return;
  btn.disabled = true;
  statusEl.className = "status";
  statusEl.textContent = t.installing;
  logEl.textContent = "";
  try {
    const res = await fetch("/api/install", {
      method: "POST",
      headers: {"Content-Type":"application/json"},
      body: JSON.stringify({url, agents, lang: langSel.value})
    });
    const data = await res.json();
    logEl.textContent = data.log || data.error || "";
    if (data.ok) {
      statusEl.className = "status ok";
      statusEl.textContent = t.done + (data.skillNames||[]).join(", ");
      logEl.textContent += t.ready;
    } else {
      statusEl.className = "status err";
      statusEl.textContent = data.error || t.failed;
    }
  } catch (e) {
    statusEl.className = "status err";
    statusEl.textContent = String(e);
  } finally {
    btn.disabled = false;
    btn.textContent = t.install;
  }
};
</script>
</body>
</html>
`
