#!/usr/bin/env python3
"""Image -> 3D model (GLB) router with failover, then Blender optimize for phone.
  model3d.py gen <name> <image.png> [--faces 20000] [--only hunyuan|trellis2]
Output: assets/models_3d/<name>.glb + <name>_preview.png
Providers (chain): hunyuan (HF Space tencent/Hunyuan3D-2.1, textured), trellis2 (HF Space microsoft/TRELLIS.2)
Keys: HF_TOKEN in .env. (Tripo/Meshy/Rodin jodne ke liye provider function add karo.)"""
import os, sys, time, shutil, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def env(k):
    if os.environ.get(k):
        return os.environ[k]
    for line in (ROOT / ".env").read_text().splitlines():
        if line.startswith(k + "="):
            return line.split("=", 1)[1].strip()
    raise RuntimeError(f"{k} .env mein nahi")

def _p(r):
    return r if isinstance(r, str) else r.get("value", r.get("path"))

def hunyuan(img):
    from gradio_client import Client, handle_file
    c = Client("tencent/Hunyuan3D-2.1", token=env("HF_TOKEN"), verbose=False)
    r = c.predict(image=handle_file(img), mv_image_front=None, mv_image_back=None, mv_image_left=None, mv_image_right=None,
                  steps=20, guidance_scale=5.0, seed=1234, octree_resolution=192, check_box_rembg=True, num_chunks=8000,
                  randomize_seed=False, api_name="/generation_all")
    return _p(r[1])      # textured_mesh.glb

def trellis2(img):
    from gradio_client import Client, handle_file
    c = Client("microsoft/TRELLIS.2", token=env("HF_TOKEN"), verbose=False)
    c.predict(api_name="/start_session")
    pre = c.predict(input=handle_file(img), api_name="/preprocess_image")
    c.predict(image=handle_file(_p(pre)), seed=0, resolution="1024", ss_guidance_strength=7.5, ss_guidance_rescale=0.7,
              ss_sampling_steps=12, ss_rescale_t=5.0, shape_slat_guidance_strength=7.5, shape_slat_guidance_rescale=0.5,
              shape_slat_sampling_steps=12, shape_slat_rescale_t=3.0, tex_slat_guidance_strength=1.0, tex_slat_guidance_rescale=0.0,
              tex_slat_sampling_steps=12, tex_slat_rescale_t=3.0, api_name="/image_to_3d")
    r = c.predict(decimation_target=100000, texture_size=1024, api_name="/extract_glb")
    return _p(r[0])

CHAIN = [("hunyuan", hunyuan), ("trellis2", trellis2)]

def gen(name, img, faces=20000, only=None):
    out = ROOT / "assets" / "models_3d"
    out.mkdir(parents=True, exist_ok=True)
    errs = []
    for pname, fn in CHAIN:
        if only and pname != only:
            continue
        t0 = time.time()
        try:
            print(f"[{pname}] ban raha hai...", flush=True)
            raw = fn(str(img))
            print(f"[{pname}] mila ({time.time()-t0:.0f}s): {raw}", flush=True)
            dst = out / f"{name}.glb"
            prev = out / f"{name}_preview.png"
            p = subprocess.run(["blender", "-b", "--python", str(ROOT / "blender/scripts/optimize_glb.py"), "--",
                                raw, str(dst), str(faces), str(prev)], capture_output=True, text=True, timeout=600)
            line = [l for l in p.stdout.splitlines() if l.startswith("OPT")]
            print(line[0] if line else "blender: " + p.stdout[-300:])
            return dst
        except Exception as e:
            errs.append(f"{pname}: {type(e).__name__} {str(e)[:140]}")
            print(f"[{pname}] fail: {errs[-1]}", file=sys.stderr, flush=True)
    raise SystemExit("sab providers fail:\n  " + "\n  ".join(errs))

if __name__ == "__main__":
    a = sys.argv[1:]
    if len(a) < 3 or a[0] != "gen":
        print(__doc__); sys.exit(1)
    faces = int(a[a.index("--faces") + 1]) if "--faces" in a else 20000
    only = a[a.index("--only") + 1] if "--only" in a else None
    print("DONE:", gen(a[1], a[2], faces, only))
