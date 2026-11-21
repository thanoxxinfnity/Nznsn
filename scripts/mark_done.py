#!/usr/bin/env python3
"""horror_city/assets/props mein jo GLB hain unke ID ko ASSET_LIST.csv mein DONE mark karo, phir list .md dobara banao."""
import csv, re, os, glob, json, subprocess, collections
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent; os.chdir(ROOT)
rows = list(csv.DictReader(open("docs/ASSET_LIST.csv", encoding="utf-8-sig")))
mine = set(json.load(open("docs/claude_gen_list.json"))) if Path("docs/claude_gen_list.json").exists() else set()
have = {}
for f in glob.glob("horror_city/assets/props/*.glb"):
    m = re.match(r"([A-Z]{1,2}\d{2,3})", os.path.basename(f)); have.setdefault(m.group(1), []).append(f)
for r in rows:
    if r["ID"] in have:
        r["Done"] = f"DONE{'-Claude' if r['ID'] in mine else ''} ({len(have[r['ID']])}/{r['Variants']})"
with open("docs/ASSET_LIST.csv", "w", newline="", encoding="utf-8-sig") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
subprocess.run(["python3", "scripts/make_asset_list2.py"], capture_output=True)
tot = collections.Counter(r["Priority"] for r in rows); done = collections.Counter(r["Priority"] for r in rows if r["ID"] in have)
print("FILES", sum(len(v) for v in have.values()), "| IDs", len(have), "|", {p: f"{done[p]}/{tot[p]}" for p in ("P1", "P2", "P3", "P4")})
