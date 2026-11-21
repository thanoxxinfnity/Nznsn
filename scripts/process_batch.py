#!/usr/bin/env python3
"""process_batch.py <in_dir> <out_dir> : har GLB ko ASSET_LIST ke size/tris ke hisaab se theek karo (Blender headless)."""
import sys, csv, json, re, subprocess
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
ROOT = Path(__file__).resolve().parent.parent
rows = {r["ID"]: r for r in csv.DictReader(open(ROOT / "docs/ASSET_LIST.csv", encoding="utf-8-sig"))}
src, dst = Path(sys.argv[1]), Path(sys.argv[2]); dst.mkdir(parents=True, exist_ok=True)
(dst / "previews").mkdir(exist_ok=True)
def work(f):
    m = re.match(r"([A-Z]{1,2}\d{2,3})", f.name)
    r = rows.get(m.group(1)) if m else None
    if not r: return f.name, {"error": "ID list mein nahi"}
    out = dst / f.name; prev = dst / "previews" / (f.stem + ".png")
    p = subprocess.run(["blender", "-b", "--python", str(ROOT / "blender/scripts/process_asset.py"), "--", str(f), str(out),
                        r["Size_m"], r["Tris_budget"], str(prev)], capture_output=True, text=True, timeout=600)
    line = [l for l in p.stdout.splitlines() if l.startswith("ASSET ")]
    rep = json.loads(line[0][6:]) if line else {"error": "blender fail: " + p.stdout[-150:]}
    rep.update(budget=int(r["Tris_budget"]), target=r["Size_m"], name=r["Name"], size_mb=round(out.stat().st_size / 1e6, 2) if out.exists() else 0)
    return f.name, rep
files = sorted(src.glob("*.glb"))
with ThreadPoolExecutor(4) as ex: res = list(ex.map(work, files))
json.dump(dict(res), open(dst / "report.json", "w"), indent=1)
for n, r in res: print(n, json.dumps(r))
