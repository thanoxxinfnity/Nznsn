#!/usr/bin/env python3
"""AI se 3D props banao: har asset ke liye AI bpy build(variant) likhta hai -> Blender runner -> GLB (raw).
  gen_assets.py <out_raw_dir> --ids F40,K05,...   ya   --list file.txt (ek ID per line)  [--workers 3]
Log: <out_raw_dir>/gen_log.jsonl ; code: <out_raw_dir>/code/<ID>.py"""
import sys, csv, re, json, subprocess, time, threading
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, str(Path(__file__).resolve().parent))
import llm
ROOT = Path(__file__).resolve().parent.parent
ROWS = {r["ID"]: r for r in csv.DictReader(open(ROOT / "docs/ASSET_LIST.csv", encoding="utf-8-sig"))}
CHAIN = ["codex:gpt-6.1-sol", "nvidia:moonshotai/kimi-k3.1-pro", "gemini:gemini-3.5-flash", "coarena:deepseek-v4-1-flash-1017", "seek:deepseek-v4.1-flash-free"]
LOCK = threading.Lock()

RULES = """Write a Blender 5.3 Python script (bpy + bmesh + math only) that defines exactly:
    def build(variant: int) -> None
It must create ONE game prop in the CURRENT EMPTY scene. Do NOT reset/clear the scene, no file IO, no camera, no lights, no render, no imports except bpy, bmesh, math, random, mathutils.
Prop: {name}
Description: {prompt}
Variants: {n} (variant goes 0..{nm1}; make each visibly different: proportions, details, colors, damage).
Real size: largest dimension about {size} m. Z is up, object stands on z=0, centered on x/y.
Triangle budget: at most {tris} triangles in total. Low-poly but clearly recognizable: correct proportions, silhouette, and small readable details (legs, handles, knobs, panels, screws, edges). Use primitives (cube, cylinder, cone, uv_sphere, torus), bmesh extrude/inset, bevel modifiers. Several separate objects are fine (they are joined later).
Materials: create with bpy.data.materials.new(name) and assign; use ONLY these names (exact): wood, wood_dark, metal_rust, metal_steel, metal_brass, leather, stone, concrete, paper, glass, ceramic_white, rubber_black, metal_painted_<c>, plastic_<c>, fabric_<c>, emissive_<c>   where <c> is one of red, blue, green, yellow, white, black, grey, brown, orange, pink, cream, purple, teal. (Colors/roughness are set automatically later from the name; glass becomes transparent, emissive glows.)
Theme: abandoned 1980s Indian toy-factory town, old, worn, slightly broken where it fits. No text or letters anywhere.
Reply with ONLY one ```python code block."""

def extract(t):
    m = re.search(r"```(?:python)?\n(.*?)```", t, re.S)
    return (m.group(1) if m else t).strip() + "\n"

def slug(s):
    return re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")[:40]

def run_blender(code_file, out_dir, base, n, budget):
    p = subprocess.run(["blender", "-b", "--python", str(ROOT / "blender/scripts/gen_runner.py"), "--", str(code_file), str(out_dir), base, str(n), str(budget)],
                       capture_output=True, text=True, timeout=900)
    m = [l for l in p.stdout.splitlines() if l.startswith("GENREPORT ")]
    return json.loads(m[-1][10:]) if m else {"error": "blender crash: " + (p.stdout + p.stderr)[-800:]}

def make(aid, out_dir, tries=3):
    r = ROWS[aid]; n = int(r["Variants"]); base = f"{aid}_{slug(r['Name'])}"
    code_dir = out_dir / "code"; code_dir.mkdir(parents=True, exist_ok=True)
    msg = RULES.format(name=r["Name"], prompt=r["Prompt"], n=n, nm1=n - 1, size=r["Size_m"], tris=r["Tris_budget"])
    t0 = time.time(); used = "-"; rep = {}
    for i in range(tries):
        try:
            text, used = llm.chat("blender_tech", lambda p: msg, chain=CHAIN, verbose=False)
        except RuntimeError as e:
            rep = {"error": "LLM: " + str(e)[:300]}; break
        cf = code_dir / f"{aid}.py"; cf.write_text(extract(text))
        rep = run_blender(cf, out_dir, base, n, int(r["Tris_budget"]))
        if "error" in rep:
            err = rep["error"]
        else:
            bad = [v for v in rep["variants"] if not v.get("ok")]
            if not bad:
                break
            err = bad[0]["error"]
        msg = (RULES.format(name=r["Name"], prompt=r["Prompt"], n=n, nm1=n - 1, size=r["Size_m"], tris=r["Tris_budget"])
               + f"\n\nYour previous script failed in Blender with:\n{err[-1200:]}\nFix it and return the FULL corrected script.")
    ok = "variants" in rep and all(v.get("ok") for v in rep["variants"])
    line = {"id": aid, "ok": ok, "llm": used, "tries": i + 1, "sec": round(time.time() - t0), "rep": rep}
    with LOCK:
        with open(out_dir / "gen_log.jsonl", "a") as f: f.write(json.dumps(line) + "\n")
    print(("OK  " if ok else "FAIL"), aid, r["Name"][:30], "| via", used, "| tries", i + 1, "| %ds" % line["sec"], flush=True)
    return line

if __name__ == "__main__":
    a = sys.argv[1:]; out = Path(a[0]); out.mkdir(parents=True, exist_ok=True)
    ids = a[a.index("--ids") + 1].split(",") if "--ids" in a else [l.strip() for l in open(a[a.index("--list") + 1]) if l.strip()]
    workers = int(a[a.index("--workers") + 1]) if "--workers" in a else 3
    done = set()
    if (out / "gen_log.jsonl").exists():
        done = {json.loads(l)["id"] for l in open(out / "gen_log.jsonl") if json.loads(l).get("ok")}
    todo = [i for i in ids if i not in done and i in ROWS]
    print("todo", len(todo), "skip(done)", len(done), flush=True)
    with ThreadPoolExecutor(workers) as ex: list(ex.map(lambda x: make(x, out), todo))
