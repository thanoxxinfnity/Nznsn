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
"""
import sys, json, re, time, urllib.request, urllib.error
from pathlib import Path

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

def raw_chat(chat_id, text, retries=3, timeout=240):
    url = f"https://www.sim.ai/api/chat/{chat_id}"
    last = None
    for i in range(retries + 1):
        try:
            req = urllib.request.Request(url, json.dumps({"input": text}).encode(),
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
                return "".join(out)
            last = "empty reply"
        except (OSError, urllib.error.URLError) as e:
            last = e
            if getattr(e, 'code', None) == 429:
                time.sleep(15 * (i + 1)); continue
        time.sleep(2 * (i + 1))
    raise RuntimeError(f"chat {chat_id} failed: {last}")

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

def compress(name, agent, m):
    old = m["turns"][:-MAX_TURNS]
    if not old:
        return
    blob = "\n".join(f"[{t['who']}] {t['text']}" for t in old)
    q = ("Neeche purani baat-cheet aur purana saar hai. Inko milakar 10 lines se kam ka saar likho: "
         "faisle, file names, kaam jo ho gaye, aur jo baaki hai. Sirf saar do.\n\n"
         f"Purana saar: {m['summary']}\n\nBaat-cheet:\n{blob}")[:MAX_CHARS]
    m["summary"] = raw_chat(agent["chat_id"], q).strip()
    m["turns"] = m["turns"][-MAX_TURNS:]

def ask(name, text, fresh=False):
    agents = load_agents()
    if name not in agents:
        raise SystemExit(f"agent '{name}' nahi mila. Available: {', '.join(agents)}")
    agent = agents[name]
    m = {"summary": "", "turns": []} if fresh else load_mem(name)
    reply = raw_chat(agent["chat_id"], build_prompt(name, agent, text, m))
    if not fresh:
        m["turns"] += [{"who": "user", "text": text}, {"who": name, "text": reply}]
        if len(m["turns"]) > SUMMARIZE_AT:
            try: compress(name, agent, m)
            except RuntimeError: pass
        save_mem(name, m)
    return reply

def team(task):
    agents = load_agents()
    if "lead" not in agents:
        raise SystemExit("'lead' agent chahiye. Pehle: studio.py add lead <chat_id> \"role\"")
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
        for k, v in load_agents().items():
            print(f"{k:12} {v.get('model','?'):12} {v['chat_id']:12} {v['role']}")
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
    elif cmd == "team":
        plan, res = team(a[1])
        for ag, t, r in res: print(f"\n=== {ag} ===\nTask: {t}\n{r}")
    else:
        print(__doc__)

if __name__ == "__main__":
    main(sys.argv[1:])
