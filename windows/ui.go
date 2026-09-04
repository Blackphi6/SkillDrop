package main

const indexHTML = `<!DOCTYPE html>
<html lang="ja">
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
</style>
</head>
<body>
<main>
  <h1>SkillDrop</h1>
  <p class="sub">GitHub のスキル URL を入れて、Cursor / Claude Code / Codex にまとめて入れます。<br/>（Windows 版・動作は環境によって未確認のことがあります）</p>
  <label for="url">GitHub URL・owner/repo・SKILL.md のリンク</label>
  <input id="url" type="text" placeholder="https://github.com/owner/repo/.../SKILL.md" value=""/>
  <div class="agents">
    <label><input type="checkbox" value="cursor" checked/> Cursor</label>
    <label><input type="checkbox" value="claude" checked/> Claude Code</label>
    <label><input type="checkbox" value="codex" checked/> Codex</label>
  </div>
  <button id="go" type="button">入れる</button>
  <div id="status" class="status"></div>
  <p class="note">本体は %USERPROFILE%\.agents\skills に保存します。git が PATH に入っている必要があります。</p>
  <pre id="log">ログがここに出ます。</pre>
</main>
<script>
const btn = document.getElementById('go');
const logEl = document.getElementById('log');
const statusEl = document.getElementById('status');
btn.onclick = async () => {
  const url = document.getElementById('url').value.trim();
  const agents = [...document.querySelectorAll('.agents input:checked')].map(x => x.value);
  if (!url || agents.length === 0) return;
  btn.disabled = true;
  statusEl.className = 'status';
  statusEl.textContent = '入れています…';
  logEl.textContent = '';
  try {
    const res = await fetch('/api/install', {
      method: 'POST',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify({url, agents})
    });
    const data = await res.json();
    logEl.textContent = data.log || data.error || '';
    if (data.ok) {
      statusEl.className = 'status ok';
      statusEl.textContent = '完了: ' + (data.skillNames||[]).join(', ');
      logEl.textContent += '\n\n新しいチャットを開くとスキルが使えます。';
    } else {
      statusEl.className = 'status err';
      statusEl.textContent = data.error || '失敗しました';
    }
  } catch (e) {
    statusEl.className = 'status err';
    statusEl.textContent = String(e);
  } finally {
    btn.disabled = false;
  }
};
</script>
</body>
</html>
`
