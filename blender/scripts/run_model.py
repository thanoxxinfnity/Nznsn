"""Run inside Blender: blender -b --python run_model.py -- <script.py> <outdir> <name>
Runs an agent-written bpy script in an empty scene, validates, exports .glb/.blend, renders preview."""
import bpy, sys, json, math, os, traceback
from mathutils import Vector

script, outdir, name = sys.argv[sys.argv.index("--") + 1:][:3]
report = {"ok": False, "name": name}

def finish(code=0):
    print("REPORT:" + json.dumps(report))
    sys.stdout.flush()
    sys.exit(code)

bpy.ops.wm.read_factory_settings(use_empty=True)
try:
    src = open(script).read()
    exec(compile(src, script, "exec"), {"bpy": bpy, "__name__": "__main__"})
except Exception:
    report["error"] = "SCRIPT ERROR:\n" + traceback.format_exc()[-1800:]
    finish(1)

meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
if not meshes:
    report["error"] = "Script ne koi MESH object nahi banaya."
    finish(1)

dg = bpy.context.evaluated_depsgraph_get()
mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3); verts = 0; faces = 0
for o in meshes:
    ev = o.evaluated_get(dg).to_mesh()
    verts += len(ev.vertices); faces += len(ev.polygons)
    for c in o.bound_box:
        w = o.matrix_world @ Vector(c)
        mn = Vector(map(min, mn, w)); mx = Vector(map(max, mx, w))
dims = mx - mn
report.update(meshes=len(meshes), verts=verts, faces=faces,
              dims=[round(d, 3) for d in dims],
              z_min=round(mn.z, 3),
              materials=sum(1 for o in meshes if o.data.materials))
problems = []
if verts < 8: problems.append("bahut kam vertices")
if max(dims) > 100 or max(dims) < 0.02: problems.append(f"size ajeeb hai {report['dims']} (meters mein 0.05-50 hona chahiye)")
if not report["materials"]: problems.append("kisi mesh par material nahi hai (rang do)")
if abs(mn.z) > 0.05 * max(dims) + 0.01: problems.append(f"neeche ka hissa z=0 par nahi hai (z_min={report['z_min']})")
# animation info
acts = []
for a in bpy.data.actions:
    n = 0; fr = []
    try:
        for fc in a.fcurves:
            n += len(fc.keyframe_points); fr += [k.co.x for k in fc.keyframe_points]
    except Exception:
        for lay in getattr(a, "layers", []):
            for st in lay.strips:
                for cb in getattr(st, "channelbags", []):
                    for fc in cb.fcurves:
                        n += len(fc.keyframe_points); fr += [k.co.x for k in fc.keyframe_points]
    acts.append({"name": a.name, "keyframes": n, "frames": [min(fr), max(fr)] if fr else None})
report["animations"] = acts
report["fps"] = bpy.context.scene.render.fps
if os.environ.get("ANIM") == "1":
    good = [a for a in acts if a["keyframes"] >= 2 and a["frames"] and a["frames"][1] > a["frames"][0]]
    if not good: problems.append("animation nahi bana: keyframe_insert se kam se kam 2 keyframes, alag frames par chahiye")
report["problems"] = problems

# export
try:
    bpy.ops.wm.save_as_mainfile(filepath=f"{outdir}/{name}.blend")
    bpy.ops.export_scene.gltf(filepath=f"{outdir}/{name}.glb", export_format="GLB")
except Exception:
    report["error"] = "EXPORT ERROR:\n" + traceback.format_exc()[-1000:]
    finish(1)

# preview render (non-fatal)
try:
    sc = bpy.context.scene
    ctr = (mn + mx) / 2
    size = max(dims)
    bpy.ops.object.light_add(type="SUN", location=(size, -size, size * 2))
    bpy.context.object.data.energy = 4
    bpy.ops.object.light_add(type="AREA", location=(-size, -size, size))
    bpy.context.object.data.energy = 300 * size
    tgt = bpy.data.objects.new("tgt", None); sc.collection.objects.link(tgt); tgt.location = ctr
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam)
    cam.location = ctr + Vector((size * 1.6, -size * 1.9, size * 1.1))
    con = cam.constraints.new("TRACK_TO"); con.target = tgt
    con.track_axis = "TRACK_NEGATIVE_Z"; con.up_axis = "UP_Y"
    sc.camera = cam
    w = bpy.data.worlds.new("w"); w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.35, 0.37, 0.42, 1)
    sc.world = w
    sc.render.engine = "CYCLES"; sc.cycles.samples = 24; sc.cycles.device = "CPU"
    sc.render.resolution_x = 768; sc.render.resolution_y = 768
    sc.render.filepath = f"{outdir}/{name}.png"
    frames = []
    if os.environ.get("ANIM") == "1" and acts and acts[0]["frames"]:
        f0, f1 = int(acts[0]["frames"][0]), int(acts[0]["frames"][1])
        for tag, f in (("f0", f0), ("f1", (f0 + f1) // 2), ("f2", f1)):
            sc.frame_set(f); sc.render.filepath = f"{outdir}/{name}_{tag}.png"
            bpy.ops.render.render(write_still=True); frames.append(sc.render.filepath)
        report["frames"] = frames
    sc.frame_set(sc.frame_start); sc.render.filepath = f"{outdir}/{name}.png"
    bpy.ops.render.render(write_still=True)
    report["preview"] = f"{outdir}/{name}.png"
except Exception:
    report["preview_error"] = traceback.format_exc()[-400:]

report["ok"] = not problems
if problems:
    report["error"] = "VALIDATION: " + "; ".join(problems)
finish(0 if report["ok"] else 1)
