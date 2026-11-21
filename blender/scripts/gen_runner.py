"""blender -b --python gen_runner.py -- <code.py> <out_dir> <base_name> <n_variants> <tri_budget>
AI ka likha build(variant) chalao -> join -> palette materials -> wear/rust bake (512px) -> GLB per variant. JSON report print."""
import bpy, sys, json, re, random, traceback, os, tempfile
a = sys.argv[sys.argv.index("--") + 1:]
code_path, out_dir, base, n, budget = a[0], a[1], a[2], int(a[3]), int(a[4])
PAL = {"red": (0.55, 0.12, 0.1), "blue": (0.15, 0.25, 0.5), "green": (0.2, 0.38, 0.2), "yellow": (0.75, 0.6, 0.15),
       "white": (0.82, 0.8, 0.75), "black": (0.05, 0.05, 0.05), "grey": (0.4, 0.4, 0.4), "gray": (0.4, 0.4, 0.4),
       "brown": (0.35, 0.22, 0.12), "orange": (0.7, 0.35, 0.1), "pink": (0.75, 0.45, 0.5), "cream": (0.85, 0.78, 0.6),
       "purple": (0.35, 0.2, 0.45), "teal": (0.15, 0.4, 0.4)}
BASE = {"wood": ((0.42, 0.28, 0.16), 0.75, 0.0), "wood_dark": ((0.22, 0.13, 0.07), 0.7, 0.0),
        "metal_rust": ((0.36, 0.18, 0.09), 0.85, 0.5), "metal_steel": ((0.55, 0.56, 0.58), 0.45, 0.9),
        "metal_brass": ((0.7, 0.52, 0.22), 0.4, 0.9), "glass": ((0.75, 0.85, 0.9), 0.05, 0.0),
        "paper": ((0.85, 0.82, 0.72), 0.9, 0.0), "rubber_black": ((0.04, 0.04, 0.04), 0.8, 0.0),
        "ceramic_white": ((0.85, 0.84, 0.8), 0.3, 0.0), "concrete": ((0.5, 0.49, 0.46), 0.95, 0.0),
        "leather": ((0.3, 0.17, 0.1), 0.6, 0.0), "stone": ((0.45, 0.43, 0.4), 0.9, 0.0)}

def params(name):
    k = name.lower().split(".")[0]
    if k in BASE:
        return BASE[k] + (k,)
    m = re.match(r"(metal_painted|plastic|fabric|emissive)_([a-z]+)", k)
    if m:
        c = PAL.get(m.group(2), (0.5, 0.5, 0.5)); t = m.group(1)
        r = {"metal_painted": (0.6, 0.4), "plastic": (0.45, 0.0), "fabric": (0.95, 0.0), "emissive": (0.5, 0.0)}[t]
        return (c, r[0], r[1], t)
    return ((0.5, 0.5, 0.5), 0.7, 0.0, "other")

def tris(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)

def setup_wear(mat, p, img, rng):
    col, rough, metal, kind = p
    nt = mat.node_tree; nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial"); bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    nt.links.new(bsdf.outputs[0], out.inputs[0])
    noise = nt.nodes.new("ShaderNodeTexNoise"); noise.inputs["Scale"].default_value = rng.uniform(4, 9)
    noise.inputs["Detail"].default_value = 6
    ramp = nt.nodes.new("ShaderNodeValToRGB"); ramp.color_ramp.elements[0].position = 0.45; ramp.color_ramp.elements[1].position = 0.75
    mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"
    dirt = (0.3, 0.13, 0.06, 1) if kind.startswith("metal") else (0.18, 0.15, 0.12, 1)
    mix.inputs[6].default_value = (*col, 1); mix.inputs[7].default_value = dirt
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    strength = nt.nodes.new("ShaderNodeMath"); strength.operation = "MULTIPLY"; strength.inputs[1].default_value = rng.uniform(0.35, 0.7)
    nt.links.new(ramp.outputs["Color"], strength.inputs[0]); nt.links.new(strength.outputs[0], mix.inputs["Factor"])
    nt.links.new(mix.outputs[2], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = rough; bsdf.inputs["Metallic"].default_value = metal
    tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = img; nt.nodes.active = tex
    return bsdf

def finish_baked(mat, p, img):
    col, rough, metal, kind = p
    nt = mat.node_tree; nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial"); bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = img
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"]); nt.links.new(bsdf.outputs[0], out.inputs[0])
    bsdf.inputs["Roughness"].default_value = rough; bsdf.inputs["Metallic"].default_value = metal

def special(mat, p):
    col, rough, metal, kind = p
    nt = mat.node_tree; nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial"); bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled"); nt.links.new(bsdf.outputs[0], out.inputs[0])
    bsdf.inputs["Base Color"].default_value = (*col, 1); bsdf.inputs["Roughness"].default_value = rough
    if kind == "glass":
        bsdf.inputs["Alpha"].default_value = 0.3
        for attr, val in (("surface_render_method", "BLENDED"), ("blend_method", "BLEND")):
            try: setattr(mat, attr, val)
            except Exception: pass
    if kind == "emissive":
        bsdf.inputs["Emission Color"].default_value = (*col, 1); bsdf.inputs["Emission Strength"].default_value = 4.0

ns = {"__name__": "gen"}
results = []
try:
    exec(compile(open(code_path).read(), code_path, "exec"), ns)
    build = ns["build"]
except Exception:
    print("GENREPORT " + json.dumps({"error": "CODE ERROR:\n" + traceback.format_exc()[-1500:]})); sys.exit(0)
for v in range(n):
    rep = {"variant": v}
    try:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        random.seed(1000 + v)
        build(v)
        meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
        if not meshes:
            raise RuntimeError("build() ne koi mesh nahi banaya")
        bpy.ops.object.select_all(action="DESELECT")
        for o in meshes:
            o.select_set(True)
            bpy.context.view_layer.objects.active = o
            for m in list(o.modifiers):
                try: bpy.ops.object.modifier_apply(modifier=m.name)
                except Exception: o.modifiers.remove(m)
        for o in bpy.context.scene.objects:
            if o.type != "MESH": o.select_set(False)
        bpy.context.view_layer.objects.active = meshes[0]
        for o in meshes: o.select_set(True)
        if len(meshes) > 1: bpy.ops.object.join()
        ob = bpy.context.view_layer.objects.active
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        t0 = tris(ob); rep["tris_raw"] = t0
        if t0 > budget * 1.3:
            mod = ob.modifiers.new("dec", "DECIMATE"); mod.ratio = max(0.05, budget / t0)
            bpy.ops.object.modifier_apply(modifier="dec")
        rep["tris"] = tris(ob)
        if not ob.data.materials:
            ob.data.materials.append(bpy.data.materials.new("plastic_grey"))
        rng = random.Random(77 + v)
        bake_mats = []
        for mat in ob.data.materials:
            if mat is None: continue
            mat.use_nodes = True
            p = params(mat.name)
            if p[3] in ("glass", "emissive"): special(mat, p)
            else: bake_mats.append((mat, p))
        rep["materials"] = [m.name for m in ob.data.materials if m]
        if bake_mats:
            bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
            bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.02)
            bpy.ops.object.mode_set(mode="OBJECT")
            img = bpy.data.images.new(f"{base}_v{v}_tex", 512, 512)
            for mat, p in bake_mats: setup_wear(mat, p, img, rng)
            sc = bpy.context.scene; sc.render.engine = "CYCLES"; sc.cycles.samples = 1; sc.cycles.device = "CPU"
            bpy.ops.object.bake(type="DIFFUSE", pass_filter={"COLOR"}, margin=4, use_clear=True)
            fp = os.path.join(tempfile.gettempdir(), f"{base}_v{v}_tex.png")
            img.filepath_raw = fp; img.file_format = "PNG"; img.save()
            for mat, p in bake_mats: finish_baked(mat, p, img)
        name = f"{base}_v{v+1}.glb" if n > 1 else f"{base}.glb"
        bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, name), export_format="GLB", export_image_format="JPEG", export_jpeg_quality=85)
        rep["file"] = name; rep["ok"] = True
    except Exception:
        rep["ok"] = False; rep["error"] = traceback.format_exc()[-1500:]
    results.append(rep)
print("GENREPORT " + json.dumps({"variants": results}))
