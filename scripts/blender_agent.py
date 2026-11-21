#!/usr/bin/env python3
"""AI Blender operator: agent writes bpy code, we run it in headless Blender, feed errors back, repeat.
  blender_agent.py "<name>" "<description>" [max_tries]
Outputs: assets/models_3d/<name>.glb/.blend/.png and blender/generated/<name>.py"""
import sys, re, json, subprocess
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import studio

ROOT = studio.ROOT
RULES = """Blender 5.3 ke liye ek Python (bpy) script likho. Niyam:
- Scene khaali hai. Sirf bpy aur math use karo; koi bahari file/internet nahi. Export/render mat likho (hum karte hain).
- Primitives (bpy.ops.mesh.primitive_*_add) aur transforms se banao; ek object ko achhe naam do.
- Har part par Principled BSDF material lagao (rang zaroor, use_nodes=True).
- Size meters mein, realistic. Model ka neeche ka hissa z=0 par ho, x/y mein centered.
- Camera/light mat daalo. Poora script ek hi ```python code block mein do, aur kuch nahi."""

ANIM_RULES = """
ANIMATION bhi banao (is script mein hi):
- scene.render.fps=24, frame_start=1, frame_end=48. Ek hi action ban-na chahiye, naam 'open' ya jo kaam ho.
- Hilne wale hisson ko ek EMPTY (hinge/pivot) ke neeche parent karo, aur EMPTY ko rotate/move karke obj.keyframe_insert(data_path=..., frame=...) se kam se kam 2 alag frames par keyframe do.
- Pivot sahi jagah rakho (jaise dhakkan ka hinge peeche ke kinare par), warna animation galat ghoomega.
- Interpolation smooth rakho (BEZIER)."""

def extract(t):
    m = re.search(r"```(?:python)?\n(.*?)```", t, re.S)
    return (m.group(1) if m else t).strip() + "\n"

def run_blender(script, outdir, name):
    p = subprocess.run(["blender", "-b", "--python", str(ROOT / "blender/scripts/run_model.py"),
                        "--", str(script), str(outdir), name], capture_output=True, text=True, timeout=600)
    m = re.findall(r"REPORT:(\{.*\})", p.stdout)
    if m:
        return json.loads(m[-1])
    return {"ok": False, "error": "Blender crash:\n" + (p.stdout + p.stderr)[-1200:]}

def main(name, desc, tries=4, anim=False, base=None):
    out = ROOT / "assets/models_3d"; gen = ROOT / "blender/generated"
    out.mkdir(parents=True, exist_ok=True); gen.mkdir(parents=True, exist_ok=True)
    script = gen / f"{name}.py"
    import os; os.environ["ANIM"] = "1" if anim else "0"
    msg = f"{RULES}{ANIM_RULES if anim else ''}\n\nBanana hai: {desc}"
    if base:
        msg += "\n\nYe pehle se bana hua script hai, ise base banao aur badlo (poora naya script do):\n```python\n" + Path(base).read_text() + "\n```"
    for i in range(1, tries + 1):
        print(f"[try {i}/{tries}] agent se script maang raha hoon...", flush=True)
        script.write_text(extract(studio.ask("blender_tech", msg)))
        rep = run_blender(script, out, name)
        if rep.get("ok"):
            print(json.dumps(rep, ensure_ascii=False, indent=1)); print("DONE:", out / f"{name}.glb"); return 0
        print("  fail:", rep.get("error", "?").splitlines()[-1][:200], flush=True)
        msg = (f"Tumhara script chalane par ye problem aayi:\n{rep.get('error','')}\n\n"
               f"Jo report mili: {json.dumps({k:v for k,v in rep.items() if k!='error'})}\n"
               "Isko theek karke POORA naya script ek ```python block mein do.")
    print("FAILED after", tries, "tries"); return 1

if __name__ == "__main__":
    a = sys.argv[1:]
    anim = "--anim" in a
    base = a[a.index("--base") + 1] if "--base" in a else None
    pos = [x for i, x in enumerate(a) if not x.startswith("--") and not (i and a[i-1] == "--base")]
    sys.exit(main(pos[0], pos[1], int(pos[2]) if len(pos) > 2 else 4, anim, base))
