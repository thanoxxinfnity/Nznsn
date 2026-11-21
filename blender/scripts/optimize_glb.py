"""blender -b --python optimize_glb.py -- in.glb out.glb target_faces [preview.png]
AI se bana GLB -> phone ke liye halka (decimate) -> origin zameen par, 2m ke andar scale -> GLB + preview."""
import bpy, sys, math
from mathutils import Vector
a = sys.argv[sys.argv.index("--") + 1:]
src, dst, target = a[0], a[1], int(a[2])
prev = a[3] if len(a) > 3 else None
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
before = sum(len(o.data.polygons) for o in meshes)
for o in meshes:
    n = len(o.data.polygons)
    if n > target:
        m = o.modifiers.new("dec", "DECIMATE")
        m.ratio = max(0.01, target / n)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_apply(modifier="dec")
dg = bpy.context.evaluated_depsgraph_get()
mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
for o in meshes:
    for c in o.bound_box:
        w = o.matrix_world @ Vector(c)
        mn = Vector(map(min, mn, w)); mx = Vector(map(max, mx, w))
dims = mx - mn
print("OPT before=%d after=%d dims=(%.2f,%.2f,%.2f)" % (before, sum(len(o.data.polygons) for o in meshes), dims.x, dims.y, dims.z))
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB")
if prev:
    sc = bpy.context.scene
    ctr = (mn + mx) / 2; size = max(dims)
    bpy.ops.object.light_add(type="SUN", location=(size, -size, size * 2)); bpy.context.object.data.energy = 3
    bpy.ops.object.light_add(type="AREA", location=(-size, -size, size)); bpy.context.object.data.energy = 200 * size
    tgt = bpy.data.objects.new("t", None); sc.collection.objects.link(tgt); tgt.location = ctr
    cam = bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam)
    cam.location = ctr + Vector((size * 1.5, -size * 1.9, size * 0.9))
    k = cam.constraints.new("TRACK_TO"); k.target = tgt; k.track_axis = "TRACK_NEGATIVE_Z"; k.up_axis = "UP_Y"
    sc.camera = cam
    w = bpy.data.worlds.new("w"); w.use_nodes = True; w.node_tree.nodes["Background"].inputs[0].default_value = (0.3, 0.32, 0.36, 1); sc.world = w
    sc.render.engine = "CYCLES"; sc.cycles.samples = 24; sc.cycles.device = "CPU"
    sc.render.resolution_x = 720; sc.render.resolution_y = 720; sc.render.filepath = prev
    bpy.ops.render.render(write_still=True)
