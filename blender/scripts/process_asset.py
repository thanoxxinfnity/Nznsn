"""blender -b --python process_asset.py -- in.glb out.glb target_size_m max_tris preview.png
Jodta hai (join), sahi size par laata hai (sabse bada side = target), dhuri zameen ke beech mein, decimate, export, preview."""
import bpy, sys, json, math
from mathutils import Vector, Matrix
a = sys.argv[sys.argv.index("--") + 1:]
src, dst, size, budget, prev = a[0], a[1], float(a[2]), int(a[3]), a[4]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
if not meshes:
    print("ASSET " + json.dumps({"error": "no mesh"})); sys.exit(0)
tris0 = sum(len(p.vertices) - 2 for o in meshes for p in o.data.polygons)
for o in meshes:                      # parent transform bake
    me = o.data; me.transform(o.matrix_world); o.parent = None; o.matrix_world = Matrix.Identity(4)
for o in list(bpy.context.scene.objects):
    if o.type != "MESH": bpy.data.objects.remove(o, do_unlink=True)
bpy.ops.object.select_all(action="DESELECT")
for o in meshes: o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1: bpy.ops.object.join()
ob = bpy.context.view_layer.objects.active
def bbox(o):
    vs = [v.co for v in o.data.vertices]      # seedha vertices se (bound_box purana reh jaata hai)
    mn = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
    mx = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
    return mn, mx
mn, mx = bbox(ob); d0 = mx - mn
f = size / max(d0)
ob.data.transform(Matrix.Scale(f, 4))
mn, mx = bbox(ob)
ob.data.transform(Matrix.Translation(Vector((-(mn.x + mx.x) / 2, -(mn.y + mx.y) / 2, -mn.z))))
ob.location = (0, 0, 0)
tris1 = sum(len(p.vertices) - 2 for p in ob.data.polygons)
if tris1 > budget:
    m = ob.modifiers.new("dec", "DECIMATE"); m.ratio = max(0.02, budget / tris1)
    bpy.ops.object.modifier_apply(modifier="dec")
tris2 = sum(len(p.vertices) - 2 for p in ob.data.polygons)
mn, mx = bbox(ob); d1 = mx - mn
imgs = [(i.name, i.size[0], i.size[1]) for i in bpy.data.images if i.size[0] > 4]
rep = {"origin_ok": abs((mn.x + mx.x) / 2) < 0.01 and abs((mn.y + mx.y) / 2) < 0.01 and abs(mn.z) < 0.01, "size_ok": abs(max(d1) - size) < 0.02 * size + 0.005, "tris_before": tris0, "tris_after": tris2, "dims_before": [round(x, 2) for x in d0], "dims_after": [round(x, 2) for x in d1],
       "materials": len(ob.data.materials), "textures": len(imgs), "tex_max": max([max(w, h) for _, w, h in imgs], default=0),
       "has_uv": len(ob.data.uv_layers) > 0}
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB")
sc = bpy.context.scene; ctr = (mn + mx) / 2; sz = max(d1)
bpy.ops.object.light_add(type="SUN", location=(sz, -sz, sz * 2)); bpy.context.object.data.energy = 3
bpy.ops.object.light_add(type="AREA", location=(-sz, -sz, sz)); bpy.context.object.data.energy = 250 * sz
t = bpy.data.objects.new("t", None); sc.collection.objects.link(t); t.location = ctr
cam = bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam)
cam.location = ctr + Vector((sz * 1.5, -sz * 1.9, sz * 0.9))
k = cam.constraints.new("TRACK_TO"); k.target = t; k.track_axis = "TRACK_NEGATIVE_Z"; k.up_axis = "UP_Y"; sc.camera = cam
w = bpy.data.worlds.new("w"); w.use_nodes = True; w.node_tree.nodes["Background"].inputs[0].default_value = (0.3, 0.32, 0.36, 1); sc.world = w
sc.render.engine = "CYCLES"; sc.cycles.samples = 14; sc.cycles.device = "CPU"
sc.render.resolution_x = 360; sc.render.resolution_y = 360; sc.render.filepath = prev
bpy.ops.render.render(write_still=True)
print("ASSET " + json.dumps(rep))
