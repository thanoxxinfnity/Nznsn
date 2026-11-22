"""blender -b --python rig_fit.py -- <char.glb> <ybot.fbx> <landmarks.json> <out.blend>
Mixamo skeleton (YBot) ko mesh ke joints (landmarks, front-view pixels) par fit karo, band proxy se auto-weights, weights asli mesh par transfer.
Output .blend (armature 'Armature' + mesh) -> bake_char_anims.py se clips lagao."""
import bpy, sys, json, math
from mathutils import Vector, Matrix
src, ybot, lmj, out = sys.argv[sys.argv.index("--") + 1:][:4]
cfg = json.load(open(lmj)); P = cfg["pts"]
def pt(p, y=0.0):
    x = (p[0] - cfg["cx"]) / cfg["ppm"]; z = cfg["z0"] + (cfg["cy"] - p[1]) / cfg["ppm"]
    return Vector((x, p[2] if len(p) > 2 else y, z))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
mesh = [o for o in bpy.data.objects if o.type == "MESH"][0]
bpy.ops.import_scene.fbx(filepath=ybot, automatic_bone_orientation=False)
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE"); arm.name = "Armature"
for o in [o for o in bpy.data.objects if o.type == "MESH" and o is not mesh]: bpy.data.objects.remove(o)
arm.animation_data_clear()
bpy.context.view_layer.objects.active = arm; bpy.ops.object.select_all(action="DESELECT"); arm.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)  # meter, Z-up, identity
bpy.ops.object.mode_set(mode="EDIT")
eb = arm.data.edit_bones
for b in eb: b.use_connect = False
old = {b.name: (b.head.copy(), b.tail.copy()) for b in eb}
def new_seg(name):
    n = name.replace("mixamorig:", "")
    g = lambda k: pt(P[k])
    side = "L" if n.startswith("Left") else ("R" if n.startswith("Right") else None)
    s = P[side] if side else None
    S = lambda k: pt(s[k]) if s else None
    m = n.replace("Left", "").replace("Right", "")
    table = {"Hips": (g("hips"), g("spine")), "Spine": (g("spine"), g("spine1")), "Spine1": (g("spine1"), g("spine2")), "Spine2": (g("spine2"), g("neck")),
             "Neck": (g("neck"), g("head")), "Head": (g("head"), g("head_top")), "HeadTop_End": (g("head_top"), g("head_top") + Vector((0, 0, 0.03)))}
    if side:
        fw = Vector((0, -0.03, 0))
        table.update({"Shoulder": (S("clav"), S("shoulder")), "Arm": (S("shoulder"), S("elbow")), "ForeArm": (S("elbow"), S("wrist")), "Hand": (S("wrist"), S("hand_tip")),
                      "UpLeg": (S("hip"), S("knee")), "Leg": (S("knee"), S("ankle")), "Foot": (S("ankle"), S("toebase")), "ToeBase": (S("toebase"), S("toeend")), "Toe_End": (S("toeend"), S("toeend") + fw)})
        return table.get(m)
    return table.get(n)
def sim(oh, ot, nh, nt):
    od = ot - oh; nd = nt - nh
    R = od.rotation_difference(nd).to_matrix().to_4x4()
    sc = (nd.length / od.length) if od.length > 1e-9 else 1.0
    return Matrix.Translation(nh) @ R @ Matrix.Diagonal((sc, sc, sc, 1)) @ Matrix.Translation(-oh)
main = {}
for b in eb:
    seg = new_seg(b.name)
    if seg: main[b.name] = seg
# fingers / foot-leaf: parent ke similarity se
def root_main(b):
    p = b
    while p and p.name not in main: p = p.parent
    return p
xf = {}
for b in eb:
    if b.name in main: xf[b.name] = sim(*old[b.name], *main[b.name])
for b in eb:
    if b.name not in main:
        r = root_main(b)
        xf[b.name] = xf[r.name] if r else Matrix.Identity(4)
for b in eb: b.transform(xf[b.name], scale=True, roll=True)
bpy.ops.object.mode_set(mode="OBJECT")
bpy.context.view_layer.update()
# --- skin ---
mesh.data.transform(mesh.matrix_world); mesh.matrix_world.identity()
proxy = mesh.copy(); proxy.data = mesh.data.copy(); proxy.name = "proxy"; bpy.context.scene.collection.objects.link(proxy)
bpy.context.view_layer.objects.active = proxy; bpy.ops.object.select_all(action="DESELECT"); proxy.select_set(True)
H = max(v.co.z for v in mesh.data.vertices) - min(v.co.z for v in mesh.data.vertices)
rm = proxy.modifiers.new("rm", "REMESH"); rm.mode = "VOXEL"; rm.voxel_size = H / 110; rm.use_smooth_shade = True
bpy.ops.object.modifier_apply(modifier="rm")
bpy.ops.object.select_all(action="DESELECT"); proxy.select_set(True); arm.select_set(True); bpy.context.view_layer.objects.active = arm
bpy.ops.object.parent_set(type="ARMATURE_AUTO")
if not any(v.groups for v in proxy.data.vertices):
    print("FALLBACK envelope")
    proxy.parent = None; proxy.vertex_groups.clear()
    for m in list(proxy.modifiers): proxy.modifiers.remove(m)
    bpy.ops.object.select_all(action="DESELECT"); proxy.select_set(True); arm.select_set(True); bpy.context.view_layer.objects.active = arm
    for b in arm.data.bones: b.envelope_distance = H * 0.1; b.head_radius = H * 0.03; b.tail_radius = H * 0.03
    bpy.ops.object.parent_set(type="ARMATURE_ENVELOPE")
pw = sum(1 for v in proxy.data.vertices if v.groups); pn = len(proxy.data.vertices)
for b in arm.data.bones:
    if b.name not in mesh.vertex_groups: mesh.vertex_groups.new(name=b.name)
bpy.ops.object.select_all(action="DESELECT"); mesh.select_set(True); bpy.context.view_layer.objects.active = mesh
dt = mesh.modifiers.new("dt", "DATA_TRANSFER"); dt.object = proxy; dt.use_vert_data = True; dt.data_types_verts = {"VGROUP_WEIGHTS"}; dt.vert_mapping = "NEAREST"
bpy.ops.object.modifier_apply(modifier="dt"); bpy.data.objects.remove(proxy)
segs = [(b.name, b.head_local, b.tail_local) for b in arm.data.bones if not b.name.endswith(("End", "_end"))]
def segd(p, a, c):
    ac = c - a; t = max(0.0, min(1.0, (p - a).dot(ac) / max(ac.length_squared, 1e-9))); return (p - (a + ac * t)).length
fixed = 0
for v in mesh.data.vertices:
    if sum(g.weight for g in v.groups) < 1e-4:
        nm = min(segs, key=lambda sg: segd(v.co, sg[1], sg[2]))[0]; mesh.vertex_groups[nm].add([v.index], 1.0, "REPLACE"); fixed += 1
ah = cfg.get("assign_hand")
if ah:  # jaise cymbals/stick: haath ki haddi se rigid
    hl = mesh.vertex_groups["mixamorig:LeftHand"]; hr = mesh.vertex_groups["mixamorig:RightHand"]; cnt = 0
    for v in mesh.data.vertices:
        if v.co.z > ah["zmin"] and abs(v.co.x) > ah["xmin"]:
            for g in list(v.groups): mesh.vertex_groups[g.group].remove([v.index])
            (hl if v.co.x > 0 else hr).add([v.index], 1.0, "REPLACE"); cnt += 1
    print("ASSIGNHAND", cnt)
bpy.ops.object.vertex_group_limit_total(group_select_mode="ALL", limit=4)
bpy.ops.object.vertex_group_normalize_all(group_select_mode="ALL", lock_active=False)
mesh.parent = arm; mesh.matrix_parent_inverse = arm.matrix_world.inverted()
am = mesh.modifiers.new("Armature", "ARMATURE"); am.object = arm
print("FIT", src.split("/")[-1], "proxy %d/%d" % (pw, pn), "nearestfix", fixed, "bones", len(arm.data.bones))
bpy.ops.wm.save_as_mainfile(filepath=out)
