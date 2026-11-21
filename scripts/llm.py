#!/usr/bin/env python3
"""Multi-provider router with automatic failover.
Har role ki ek chain hai (config/team_models.json). Pehla provider fail (limit/balance/429/down) -> agla.
Fail hue provider ko kuch der aaraam (cooldown) milta hai. Keys .env se.
  llm.py health [--sim]        # har provider:model ko ek chhoti call se parkho
  llm.py chain <role>          # chain dikhao
  llm.py ask <role> "<prompt>" # seedha pucho (failover ke saath)
  llm.py state                 # kaun cooldown mein hai
"""
import os, sys, json, time, subprocess, urllib.request, urllib.error
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STATE = ROOT / "team" / "memory" / "provider_state.json"

class Fail(Exception):
    def __init__(self, msg, cooldown=120, whole=True):
        super().__init__(msg); self.cooldown = cooldown; self.whole = whole

def env(key):
    if os.environ.get(key):
        return os.environ[key]
    p = ROOT / ".env"
    if p.exists():
        for line in p.read_text().splitlines():
            if line.startswith(key + "="):
                return line.split("=", 1)[1].strip()
    raise Fail(f"{key} .env mein nahi hai", 86400)

def providers(): return json.loads((ROOT / "config/providers.json").read_text())

def load_team():
    d = json.loads((ROOT / "config/team_models.json").read_text())
    chains = d.pop("_chains")
    for k, v in d.items():
        v["chain"] = chains[v["chain"]] if isinstance(v["chain"], str) else v["chain"]
    return d

def _state():
    try: return json.loads(STATE.read_text())
    except (OSError, ValueError): return {}

def _save(s):
    try: STATE.write_text(json.dumps(s, indent=1))
    except OSError: pass

def cooling(prov, model):
    s = _state(); now = time.time()
    for k in (prov, f"{prov}:{model}"):
        if s.get(k, {}).get("until", 0) > now:
            return True
    return False

def set_cooldown(prov, model, f):
    s = _state(); key = prov if f.whole else f"{prov}:{model}"
    s[key] = {"until": time.time() + f.cooldown, "why": str(f)[:120]}
    _save(s)

def _gap(prov):
    gap = providers()[prov].get("min_gap", 0)
    s = _state(); last = s.get("_last", {}).get(prov, 0)
    wait = gap - (time.time() - last)
    if wait > 0:
        time.sleep(wait)
    s = _state(); s.setdefault("_last", {})[prov] = time.time(); _save(s)

def _post(url, headers, body, timeout=180):
    req = urllib.request.Request(url, json.dumps(body).encode(), {"Content-Type": "application/json", "User-Agent": "nznsn-llm-router/1.0", **headers})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        txt = e.read().decode("utf-8", "ignore")[:200].replace("\n", " ")
        c = e.code
        if c in (401,): raise Fail(f"401 key kharab: {txt}", 86400)
        if c in (402, 403): raise Fail(f"{c} balance/limit/permission: {txt}", 6 * 3600)
        if c == 429: raise Fail(f"429 rate/daily limit: {txt}", 600)
        if c in (400, 404, 422): raise Fail(f"{c} model/format: {txt}", 1800, whole=False)
        raise Fail(f"{c} server: {txt}", 120)
    except (urllib.error.URLError, TimeoutError, OSError, ValueError) as e:
        raise Fail(f"net/timeout: {str(e)[:100]}", 120)

def call(prov, model, prompt, conv=None):
    cfg = providers()[prov]; t = cfg["type"]
    if t == "openai":
        d = _post(cfg["base"] + "/chat/completions", {"Authorization": "Bearer " + env(cfg["key_env"])},
                  {"model": model, "messages": [{"role": "user", "content": prompt}], "max_tokens": cfg.get("max_tokens", 3000)})
        txt = ((d.get("choices") or [{}])[0].get("message") or {}).get("content")
    elif t == "gemini":
        d = _post(f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent",
                  {"x-goog-api-key": env(cfg["key_env"])},
                  {"contents": [{"parts": [{"text": prompt}]}], "generationConfig": {"maxOutputTokens": 4096}})
        parts = (((d.get("candidates") or [{}])[0].get("content") or {}).get("parts")) or []
        txt = "".join(p.get("text", "") for p in parts if not p.get("thought"))
    elif t == "codex":
        try:
            p = subprocess.run(["bash", str(ROOT / "scripts/codex_agent.sh"), prompt], capture_output=True, text=True, timeout=300,
                               env={**os.environ, "CODEX_MODEL": model})
        except subprocess.TimeoutExpired:
            raise Fail("codex timeout", 300)
        if p.returncode != 0:
            raise Fail("codex fail: " + (p.stderr or "")[-160:].replace("\n", " "), 600)
        txt = p.stdout
    elif t == "sim":
        sys.path.insert(0, str(ROOT / "scripts")); import studio
        who = conv.replace("nznsn-", "") if conv else None
        ag = studio.load_agents()
        if not who or who not in ag:
            raise Fail("sim: is role ka chat link nahi", 3600)
        try:
            txt = studio.raw_chat(ag[who]["chat_id"], prompt, retries=1, conv=conv)
        except RuntimeError as e:
            raise Fail("sim fail: " + str(e)[:100], 900)
    else:
        raise Fail("unknown provider type " + t, 86400)
    if not (txt or "").strip():
        raise Fail("khali jawab", 300, whole=False)
    return txt.strip()

def chat(role, make_prompt, conv=None, chain=None, verbose=True):
    """make_prompt(provider)->str. Returns (text, 'provider:model')."""
    chain = chain or load_team()[role]["chain"]
    errs = []
    for spec in chain:
        prov, _, model = spec.partition(":")
        if cooling(prov, model):
            errs.append(f"{spec}: cooldown"); continue
        _gap(prov)
        try:
            text = call(prov, model, make_prompt(prov), conv)
            if verbose and errs:
                print(f"[failover: {len(errs)} skip -> {spec}]", file=sys.stderr)
            return text, spec
        except Fail as f:
            set_cooldown(prov, model, f); errs.append(f"{spec}: {f}")
            if verbose: print(f"[{spec} fail: {str(f)[:90]}]", file=sys.stderr)
    raise RuntimeError("sab providers fail:\n  " + "\n  ".join(errs))

def health(with_sim=False):
    team = load_team(); seen = []
    for v in team.values():
        for s in v["chain"]:
            if s not in seen and (with_sim or not s.startswith("sim:")):
                seen.append(s)
    for spec in seen:
        prov, _, model = spec.partition(":"); t0 = time.time()
        try:
            _gap(prov); r = call(prov, model, "Reply with exactly the word: OK")
            print(f"OK    {spec:48} {time.time()-t0:5.1f}s  {r[:30]!r}")
        except Fail as f:
            print(f"FAIL  {spec:48} {str(f)[:110]}")

if __name__ == "__main__":
    a = sys.argv[1:]
    if not a: print(__doc__)
    elif a[0] == "health": health("--sim" in a)
    elif a[0] == "chain": print("\n".join(load_team()[a[1]]["chain"]))
    elif a[0] == "state": print(json.dumps({k: v for k, v in _state().items() if k != "_last"}, indent=1))
    elif a[0] == "ask":
        t, used = chat(a[1], lambda p: a[2]); print(t); print(f"\n[via {used}]", file=sys.stderr)
    else: print(__doc__)
