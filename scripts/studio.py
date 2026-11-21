#!/usr/bin/env python3
"""AI team manager with memory. Agents = Sim.ai deployed chats (stateless), memory is kept here.

  studio.py list
  studio.py add <name> <chat_id> "<role>" [model]
  studio.py ask <name> "<message>"        # uses memory
  studio.py ask <name> "<message>" --fresh # no memory
  studio.py remember "<fact>"             # shared notes for whole team
  studio.py forget <name>                 # clear one agent's memory
  studio.py memory <name>                 # show what the agent remembers
  studio.py team "<task>"                 # 'lead' agent plans, others execute
  studio.py credits                       # Sim ka asli kharcha ($) API se
  studio.py usage                         # kitni calls/characters kharch hue (local log)
"""
import os, sys, json, re, time, urllib.request, urllib.error
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import llm

ROOT = Path(__file__).resolve().parent.parent
AGENTS = ROOT / "config" / "agents.json"
MEM = ROOT / "team" / "memory"
SHARED = MEM / "shared.md"
MAX_TURNS = 8          # recent turns sent verbatim
SUMMARIZE_AT = 14      # when history exceeds this, compress the older part
MAX_CHARS = 12000      # cap on memory context size

def load_agents():
    return json.loads(AGENTS.read_text())

def save_agents(a):
    AGENTS.write_text(json.dumps(a, ensure_ascii=False, indent=2) + "\n")

def raw_chat(chat_id, text, retries=3, timeout=240, conv=None):
    url = f"https://www.sim.ai/api/chat/{chat_id}"
    last = None
    for i in range(retries + 1):
        try:
            body = {"input": text}
            if conv:
                body["conversationId"] = conv   # Sim Agent Memory chalu ho to server-side yaaddasht isi se judti hai
            req = urllib.request.Request(url, json.dumps(body).encode(),
                                         {"Content-Type": "application/json"})
            out = []
            with urllib.request.urlopen(req, timeout=timeout) as r:
                for line in r:
                    line = line.decode().strip()
                    if not line.startswith("data:"):
                        continue
                    d = line[5:].strip()
                    if d == '"[DONE]"':
                        break
                    try:
                        ev = json.loads(d)
                    except ValueError:
                        continue
                    if isinstance(ev, dict) and "chunk" in ev:
                        out.append(ev["chunk"])
            if out:
                reply = "".join(out)
                _log_usage(chat_id, len(text), len(reply))
                return reply
            last = "empty reply"
        except (OSError, urllib.error.URLError) as e:
            last = e
            if getattr(e, 'code', None) == 429:
                time.sleep(15 * (i + 1)); continue
        time.sleep(2 * (i + 1))
    raise RuntimeError(f"chat {chat_id} failed: {last}")

def sim_credits():
    """Sim account ka asli kharcha (dollar). Key: SIM_API_KEY (.env)."""
    key = os.environ.get("SIM_API_KEY")
    if not key:
        for line in (ROOT / ".env").read_text().splitlines():
            if line.startswith("SIM_API_KEY="):
                key = line.split("=", 1)[1].strip()
    req = urllib.request.Request("https://www.sim.ai/api/users/me/usage-limits", headers={"X-API-Key": key})
    with urllib.request.urlopen(req, timeout=30) as r:
        d = json.load(r)["usage"]
    return d["currentPeriodCost"], d["limit"], d.get("plan")

def _log_usage(chat_id, n_in, n_out):
    try:
        with (MEM / "usage.log").open("a") as f:
            f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} {chat_id} in={n_in} out={n_out}\n")
    except OSError:
        pass

# ---- memory ----
def _hist_path(name): return MEM / f"{name}.json"

def load_mem(name):
    p = _hist_path(name)
    if p.exists():
        return json.loads(p.read_text())
    return {"summary": "", "turns": []}

def save_mem(name, m):
    _hist_path(name).write_text(json.dumps(m, ensure_ascii=False, indent=1))

def build_prompt(name, agent, text, m):
    head = [f"Tum is AI game studio team ke member '{name}' ho. Tumhara kaam: {agent.get('role','')}.",
            "Neeche tumhari yaaddasht (memory) hai. Use dhyan se use karo, phir naye message ka jawab do."]
    if SHARED.exists():
        head.append("## Shared project notes\n" + SHARED.read_text().strip())
    if m["summary"]:
        head.append("## Purani baaton ka saar\n" + m["summary"])
    tail = "## Naya message\n" + text
    turns = [f"[{t['who']}] {t['text'][:1500]}" for t in m["turns"][-MAX_TURNS:]]
    # drop oldest history lines until it fits; header and new message are never cut
    while True:
        mid = ["## Haal ki baat-cheet\n" + "\n".join(turns)] if turns else []
        prompt = "\n\n".join(head + mid + [tail])
        if len(prompt) <= MAX_CHARS or not turns:
            return prompt
        turns.pop(0)

def build_prompt_lean(name, agent, text):
    # Sim-side memory chalu hai: history dobara mat bhejo (credits bachte hain)
    head = f"[Tum '{name}' ho. Kaam: {agent.get('role','')}]"
    notes = SHARED.read_text().strip() if SHARED.exists() else ""
    return f"{head}\n{notes}\n\n{text}" if notes else f"{head}\n\n{text}"

def compress(name, agent, m):
    old = m["turns"][:-MAX_TURNS]
    if not old:
        return
    blob = "\n".join(f"[{t['who']}] {t['text']}" for t in old)
    q = ("Neeche purani baat-cheet aur purana saar hai. Inko milakar 10 lines se kam ka saar likho: "
         "faisle, file names, kaam jo ho gaye, aur jo baaki hai. Sirf saar do.\n\n"
         f"Purana saar: {m['summary']}\n\nBaat-cheet:\n{blob}")[:MAX_CHARS]
    m["summary"] = llm.chat(name, lambda p: q, chain=llm.load_team()["art_director"]["chain"][:-1])[0].strip()
    m["turns"] = m["turns"][-MAX_TURNS:]

def ask(name, text, fresh=False):
    agents = load_agents() if AGENTS.exists() else {}
    teamcfg = llm.load_team()
    if name not in teamcfg:
        raise SystemExit(f"agent '{name}' nahi mila. Available: {', '.join(teamcfg)}")
    agent = {**agents.get(name, {}), "role": teamcfg[name]["role"]}
    m = {"summary": "", "turns": []} if fresh else load_mem(name)
    empty = {"summary": "", "turns": []}

    def make(provider):
        # Sim ke paas server-side yaaddasht hai: sirf tab lean jab pichla jawab bhi Sim ne diya ho
        if provider == "sim" and not fresh and m.get("last") == "sim" and os.environ.get("NZNSN_LOCAL_MEMORY") != "1":
            return build_prompt_lean(name, agent, text)
        return build_prompt(name, agent, text, empty if fresh else m)

    reply, used = llm.chat(name, make, conv=None if fresh else f"nznsn-{name}")
    print(f"[{name} <- {used}]", file=sys.stderr)
    if not fresh:
        m["turns"] += [{"who": "user", "text": text}, {"who": name, "text": reply}]
        m["last"] = used.split(":")[0]
        m["turns"] = m["turns"][-MAX_TURNS * 2:]
        if len(m["turns"]) > SUMMARIZE_AT:
            try: compress(name, agent, m)
            except RuntimeError: pass
        save_mem(name, m)
    return reply

def team(task):
    agents = llm.load_team()
    others = {k: v["role"] for k, v in agents.items() if k != "lead"}
    plan = ask("lead",
        f"Task: {task}\n\nTeam members: {json.dumps(others, ensure_ascii=False)}\n"
        'Sirf JSON array do: [{"agent":"<name>","task":"<poora, khud-mein-sampoorn kaam>"}]')
    m = re.search(r"\[.*\]", plan, re.S)
    steps = json.loads(m.group(0)) if m else []
    results = []
    for s in steps:
        if s.get("agent") in agents:
            results.append((s["agent"], s["task"], ask(s["agent"], s["task"])))
    return plan, results

def main(a):
    if not a or a[0] in ("-h", "--help"):
        print(__doc__); return
    cmd = a[0]
    if cmd == "list":
        for k, v in llm.load_team().items():
            print(f"{k:18} {v['chain'][0].split(':')[0]:>7} -> ... ({len(v['chain'])} providers)  {v['role'][:60]}")
    elif cmd == "add":
        ag = load_agents()
        ag[a[1]] = {"chat_id": a[2], "role": a[3], "model": a[4] if len(a) > 4 else "Fable 5.2"}
        save_agents(ag); print("added", a[1])
    elif cmd == "ask":
        print(ask(a[1], a[2], fresh="--fresh" in a))
    elif cmd == "remember":
        with SHARED.open("a") as f: f.write(f"- {a[1]}\n")
        print("saved to shared notes")
    elif cmd == "forget":
        p = _hist_path(a[1]); p.unlink(missing_ok=True); print("cleared", a[1])
    elif cmd == "memory":
        m = load_mem(a[1]); print("SUMMARY:", m["summary"] or "-"); print("TURNS:", len(m["turns"]))
    elif cmd == "credits":
        c, l, plan = sim_credits()
        print(f"Sim ({plan}): ${c:.2f} / ${l:.2f} kharch ({c/l*100:.0f}%), bacha ${l-c:.2f}")
        try:
            key = [x.split("=", 1)[1].strip() for x in (ROOT / ".env").read_text().splitlines() if x.startswith("XINGCHI_API_KEY=")][0]
            rq = urllib.request.Request("https://api.xingchiapi.com/v1/usage", headers={"Authorization": f"Bearer {key}"})
            u = json.load(urllib.request.urlopen(rq, timeout=30))
            print(f"xingchi (Codex): balance ${u['balance']:.2f}")
        except Exception as e:
            print("xingchi balance nahi mila:", str(e)[:60])
    elif cmd == "usage":
        f = MEM / "usage.log"
        rows = f.read_text().splitlines() if f.exists() else []
        tot_in = sum(int(r.split("in=")[1].split()[0]) for r in rows); tot_out = sum(int(r.split("out=")[1]) for r in rows)
        print(f"calls={len(rows)} in_chars={tot_in} out_chars={tot_out} (log shuru hone ke baad se)")
    elif cmd == "team":
        plan, res = team(a[1])
        for ag, t, r in res: print(f"\n=== {ag} ===\nTask: {t}\n{r}")
    else:
        print(__doc__)

if __name__ == "__main__":
    main(sys.argv[1:])
