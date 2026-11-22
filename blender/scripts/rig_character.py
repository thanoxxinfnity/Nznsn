"""blender -b --python rig_character.py -- <char.glb> <ybot.fbx> <out.glb>
Insaan-jaise mesh ko Mixamo skeleton (65 bones, ungliyon samet) par skin karo. Skeleton library (mixamo_anims.glb) jaisa hi rehta hai,
mesh ko skeleton ke size tak scale karte hain (Godot mein root scale se wapas chhota). Weights: band proxy par auto-weights -> asli mesh par transfer."""
import bpy, sys, json
from mathutils import Vector
src, ybot, out = sys.argv[sys.argv.index("--") + 1:][:3]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
mesh = [o for o in bpy.data.objects if o.type == "MESH"][0]
bpy.ops.import_scene.fbx(filepath=ybot, automatic_bone_orientation=False)
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE"); arm.name = "Armature"
for o in [o for o in bpy.data.objects if o.type == "MESH" and o is not mesh]: bpy.data.objects.remove(o)
bpy.context.view_layer.update()
hb = arm.data.bones
zs = [(arm.matrix_world @ b.head_local).z for b in hb] + [(arm.matrix_world @ b.tail_local).z for b in hb]
sk_h = (max(zs) - min(zs)) * 1.07
pts = [mesh.matrix_world @ v.co for v in mesh.data.vertices]
mn = Vector(min(p[i] for p in pts) for i in range(3)); mx = Vector(max(p[i] for p in pts) for i in range(3))
mh = mx.z - mn.z; f = sk_h / mh
mesh.data.transform(mesh.matrix_world); mesh.matrix_world.identity()
mesh.data.transform(__import__("mathutils").Matrix.Translation(Vector((-(mn.x + mx.x) / 2, -(mn.y + mx.y) / 2, -mn.z))))
mesh.data.transform(__import__("mathutils").Matrix.Diagonal((f, f, f, 1)))
# band proxy
proxy = mesh.copy(); proxy.data = mesh.data.copy(); proxy.name = "proxy"; bpy.context.scene.collection.objects.link(proxy)
bpy.context.view_layer.objects.active = proxy; bpy.ops.object.select_all(action="DESELECT"); proxy.select_set(True)
rm = proxy.modifiers.new("rm", "REMESH"); rm.mode = "VOXEL"; rm.voxel_size = sk_h / 110; rm.use_smooth_shade = True
bpy.ops.object.modifier_apply(modifier="rm")
bpy.ops.object.select_all(action="DESELECT"); proxy.select_set(True); arm.select_set(True); bpy.context.view_layer.objects.active = arm
bpy.ops.object.parent_set(type="ARMATURE_AUTO")
if not any(v.groups for v in proxy.data.vertices):  # bone-heat fail -> envelope (distance based)
    print("FALLBACK envelope")
    proxy.parent = None; proxy.vertex_groups.clear()
    for m in list(proxy.modifiers): proxy.modifiers.remove(m)
    bpy.ops.object.select_all(action="DESELECT"); proxy.select_set(True); arm.select_set(True); bpy.context.view_layer.objects.active = arm
    for b in arm.data.bones: b.envelope_distance = sk_h * 100 * 0.1; b.head_radius = sk_h * 100 * 0.03; b.tail_radius = sk_h * 100 * 0.03
    bpy.ops.object.parent_set(type="ARMATURE_ENVELOPE")
ok = sum(1 for v in proxy.data.vertices if v.groups); pn = len(proxy.data.vertices)
for b in hb:
    if b.name not in mesh.vertex_groups: mesh.vertex_groups.new(name=b.name)
bpy.ops.object.select_all(action="DESELECT"); mesh.select_set(True); bpy.context.view_layer.objects.active = mesh
dt = mesh.modifiers.new("dt", "DATA_TRANSFER"); dt.object = proxy; dt.use_vert_data = True; dt.data_types_verts = {"VGROUP_WEIGHTS"}; dt.vert_mapping = "NEAREST"
bpy.ops.object.modifier_apply(modifier="dt"); bpy.data.objects.remove(proxy)
# jinhe koi weight nahi mila (dur ke hisse): sabse nazdeeki haddi ko do
segs = [(b.name, arm.matrix_world @ b.head_local, arm.matrix_world @ b.tail_local) for b in hb if not b.name.endswith(("End", "_end"))]
def segd(p, a, c):
    ac = c - a; t = max(0.0, min(1.0, (p - a).dot(ac) / max(ac.length_squared, 1e-9))); return (p - (a + ac * t)).length
fixed = 0
for v in mesh.data.vertices:
    if sum(g.weight for g in v.groups) < 1e-4:
        nm = min(segs, key=lambda sg: segd(v.co, sg[1], sg[2]))[0]; mesh.vertex_groups[nm].add([v.index], 1.0, "REPLACE"); fixed += 1
print("NEARESTFIX", fixed)
bpy.ops.object.select_all(action="DESELECT"); mesh.select_set(True); bpy.context.view_layer.objects.active = mesh
bpy.ops.object.vertex_group_limit_total(group_select_mode="ALL", limit=4)
bpy.ops.object.vertex_group_normalize_all(group_select_mode="ALL", lock_active=False)
try:
    bpy.ops.object.vertex_group_smooth(group_select_mode="ALL", factor=0.6, repeat=6, expand=0.0)
    bpy.ops.object.vertex_group_limit_total(group_select_mode="ALL", limit=4)
    bpy.ops.object.vertex_group_normalize_all(group_select_mode="ALL", lock_active=False)
except Exception as e: print("SMOOTHFAIL", e)
mesh.parent = arm; mesh.matrix_parent_inverse = arm.matrix_world.inverted()
am = mesh.modifiers.new("Armature", "ARMATURE"); am.object = arm
w = sum(1 for v in mesh.data.vertices if v.groups)
print("RIG", src.split("/")[-1], "proxy_weighted %d/%d" % (ok, pn), "mesh_weighted %d/%d" % (w, len(mesh.data.vertices)), "scale_back", round(1 / f, 4), "skel_h", round(sk_h, 3))
bpy.ops.object.select_all(action="DESELECT"); mesh.select_set(True); arm.select_set(True); bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True, export_animations=False, export_image_format="JPEG", export_jpeg_quality=85)
json.dump({"scale_back": 1 / f, "mesh_height_m": mh}, open(out + ".json", "w"))
