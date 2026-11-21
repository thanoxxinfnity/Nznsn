import bpy
import math

# ------------------------------------------------------------
# Khazane ka sandook (Treasure Chest) - dhakkan hinge par khulta hai
# Units: meters | neeche ka hissa z=0 | x/y mein centered
# Saamne ka hissa (taala) -Y ki taraf, hinge peeche (+Y) ke kinare par
# Animation: action 'open' -> frame 1 band, frame 24 par 100 deg khula,
#            frame 48 tak khula rahta hai (24 fps)
# ------------------------------------------------------------

scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0

# ---------- Naap (meters) ----------
W = 0.60          # chaudai (X)
D = 0.38          # gehrai (Y)
H = 0.24          # body ki unchai (Z)
BODY_BOTTOM = 0.006   # body thoda upar, corner guards zameen par tikte hain
WALL = 0.02       # body ki deewar ki motai
FLOOR_T = 0.02    # body ke farsh ki motai
LID_RZ = 0.13     # dhakkan ki curve unchai
RIM_H = 0.02      # dhakkan ke rim ki unchai
STRAP_W = 0.05    # sone ki patti ki chaudai
STRAP_T = 0.007   # patti kitni bahar nikli hai
STRAP_X = 0.18    # pattiyon ki X position (+/-)
GUARD = 0.07      # corner guard ka size (X/Y)
GUARD_H = 0.08    # corner guard ki unchai
GUARD_P = 0.008   # corner guard kitna bahar nikla hai
GUARD_T = GUARD_P + 0.006   # guard plate ki motai (thoda deewar ke andar)

# Hinge (pivot) - peeche ke upari kinare par, kabze ke barrel ke axis par
HINGE_X = 0.07            # kabzon ki X position (+/-)
HINGE_Y = D / 2.0 + 0.008
HINGE_Z = H
OPEN_DEG = 100.0          # dhakkan kitna khulega (peeche ki taraf)

# Andar ka khazana
FILL_TOP = 0.15           # sikkon ki satah ki unchai
MOUND_RX, MOUND_RY, MOUND_RZ = 0.24, 0.14, 0.05   # sikkon ka dher


# ---------- Materials ----------
def make_material(name, color, metallic=0.0, roughness=0.5):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = None
    out = None
    for n in nt.nodes:
        if n.type == 'BSDF_PRINCIPLED':
            bsdf = n
        elif n.type == 'OUTPUT_MATERIAL':
            out = n
    if bsdf is None:
        bsdf = nt.nodes.new('ShaderNodeBsdfPrincipled')
        if out is None:
            out = nt.nodes.new('ShaderNodeOutputMaterial')
            out.location = (300, 0)
        nt.links.new(bsdf.outputs['BSDF'], out.inputs['Surface'])
    rgba = (color[0], color[1], color[2], 1.0)
    if 'Base Color' in bsdf.inputs:
        bsdf.inputs['Base Color'].default_value = rgba
    if 'Metallic' in bsdf.inputs:
        bsdf.inputs['Metallic'].default_value = metallic
    if 'Roughness' in bsdf.inputs:
        bsdf.inputs['Roughness'].default_value = roughness
    mat.diffuse_color = rgba
    return mat


MAT_WOOD = make_material("Chest_Wood", (0.36, 0.20, 0.09), 0.0, 0.75)
MAT_WOOD_DARK = make_material("Chest_Wood_Dark", (0.17, 0.09, 0.04), 0.0, 0.85)
MAT_GOLD = make_material("Chest_Gold", (1.00, 0.76, 0.30), 1.0, 0.30)
MAT_IRON = make_material("Chest_Iron", (0.23, 0.23, 0.25), 1.0, 0.45)
MAT_BLACK = make_material("Chest_Keyhole_Black", (0.02, 0.02, 0.02), 0.0, 0.90)
MAT_RUBY = make_material("Chest_Gem_Ruby", (0.70, 0.03, 0.06), 0.0, 0.15)
MAT_EMERALD = make_material("Chest_Gem_Emerald", (0.03, 0.55, 0.20), 0.0, 0.15)


# ---------- Root (sab parts iske neeche) ----------
root = bpy.data.objects.new("TreasureChest", None)
root.empty_display_size = 0.2
scene.collection.objects.link(root)

# ---------- Dhakkan ka hinge EMPTY (pivot) ----------
# Dhakkan ke saare hisse iske neeche parent honge; yahi rotate hoga.
lid_hinge = bpy.data.objects.new("Chest_Lid_Hinge", None)
lid_hinge.empty_display_type = 'ARROWS'
lid_hinge.empty_display_size = 0.08
lid_hinge.rotation_mode = 'XYZ'
lid_hinge.location = (0.0, HINGE_Y, HINGE_Z)
scene.collection.objects.link(lid_hinge)
lid_hinge.parent = root


# ---------- Helper functions ----------
def finish(obj, name, mat, parent=None, apply=True):
    if apply:
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.name = name
    obj.data.name = name + "_Mesh"
    obj.data.materials.append(mat)
    par = parent if parent is not None else root
    obj.parent = par
    # Parent (root/hinge) abhi bina rotation ke hai, isliye sirf location
    # ghata dene se object apni world jagah par hi rahta hai.
    obj.location = obj.location - par.location
    return obj


def smooth(obj, only_quads=False):
    for p in obj.data.polygons:
        if only_quads:
            p.use_smooth = (len(p.vertices) == 4)
        else:
            p.use_smooth = True


def add_box(name, dims, loc, mat, parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.active_object
    obj.scale = dims
    return finish(obj, name, mat, parent)


def add_cylinder_x(name, rz, ry, length, loc, mat, parent=None, verts=32):
    # Cylinder jiska axis X ki taraf hai; rz = Z radius, ry = Y radius
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=verts, radius=1.0, depth=1.0, end_fill_type='NGON',
        location=loc, rotation=(0.0, math.pi / 2.0, 0.0))
    obj = bpy.context.active_object
    obj.scale = (rz, ry, length)
    finish(obj, name, mat, parent)
    smooth(obj, only_quads=True)
    return obj


def add_half_cylinder_x(name, rz, ry, length, loc, mat, parent=None, verts=48, cut=0.0):
    # Aadha (upar wala) cylinder: neeche ke vertices ko z=cut par chapta kar dete hain,
    # taaki dhakkan khulne par neeche se seedha (flat) dikhe.
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=verts, radius=1.0, depth=1.0, end_fill_type='NGON',
        location=loc, rotation=(0.0, math.pi / 2.0, 0.0))
    obj = bpy.context.active_object
    obj.scale = (rz, ry, length)
    finish(obj, name, mat, parent)
    me = obj.data
    for v in me.vertices:
        if v.co.z < cut:
            v.co.z = cut
    for p in me.polygons:
        zc = sum(me.vertices[i].co.z for i in p.vertices) / len(p.vertices)
        p.use_smooth = (len(p.vertices) == 4 and zc > cut + 1e-5)
    me.update()
    return obj


def add_cylinder_y(name, radius, length, loc, mat, parent=None, verts=16):
    # Cylinder jiska axis Y ki taraf hai
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=verts, radius=1.0, depth=1.0, end_fill_type='NGON',
        location=loc, rotation=(math.pi / 2.0, 0.0, 0.0))
    obj = bpy.context.active_object
    obj.scale = (radius, radius, length)
    finish(obj, name, mat, parent)
    smooth(obj, only_quads=True)
    return obj


def add_sphere(name, radius, loc, mat, parent=None):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=12, ring_count=6, radius=radius, location=loc)
    obj = bpy.context.active_object
    finish(obj, name, mat, parent)
    smooth(obj)
    return obj


def add_torus(name, major, minor, loc, rot, mat, parent=None):
    bpy.ops.mesh.primitive_torus_add(
        align='WORLD', location=loc, rotation=rot,
        major_segments=24, minor_segments=8,
        major_radius=major, minor_radius=minor)
    obj = bpy.context.active_object
    finish(obj, name, mat, parent)
    smooth(obj)
    return obj


def add_coin(name, loc, rot, mat):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=16, radius=0.018, depth=0.004, end_fill_type='NGON',
        location=loc, rotation=rot)
    obj = bpy.context.active_object
    finish(obj, name, mat)
    smooth(obj, only_quads=True)
    return obj


def add_gem(name, radius, loc, mat):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=radius, location=loc)
    obj = bpy.context.active_object
    return finish(obj, name, mat)


def heap_z(x, y):
    # Sikkon ke dher ki satah ki unchai (x, y) par
    k = 1.0 - (x / MOUND_RX) ** 2 - (y / MOUND_RY) ** 2
    if k > 0.0:
        return FILL_TOP + MOUND_RZ * math.sqrt(k)
    return FILL_TOP


# ---------- 1) Lakdi ka body (khokhla: 4 deewarein + farsh) ----------
body_h = H - BODY_BOTTOM
body_cz = BODY_BOTTOM + body_h / 2.0
add_box("Chest_Body_Front", (W, WALL, body_h),
        (0.0, -(D / 2.0 - WALL / 2.0), body_cz), MAT_WOOD)
add_box("Chest_Body_Back", (W, WALL, body_h),
        (0.0, (D / 2.0 - WALL / 2.0), body_cz), MAT_WOOD)
for side, sx in (("L", -1.0), ("R", 1.0)):
    add_box("Chest_Body_Side_" + side, (WALL, D - 2.0 * WALL, body_h),
            (sx * (W / 2.0 - WALL / 2.0), 0.0, body_cz), MAT_WOOD)

floor_top = BODY_BOTTOM + FLOOR_T
floor_h = FLOOR_T - 0.001
add_box("Chest_Body_Floor",
        (W - 2.0 * WALL + 0.002, D - 2.0 * WALL + 0.002, floor_h),
        (0.0, 0.0, floor_top - floor_h / 2.0), MAT_WOOD)

# Takhton (planks) ke beech ki gehri lakeerein - sirf bahar ki taraf (andar nahi dikhti)
for i, z in enumerate((0.09, 0.165)):
    n = i + 1
    for fb, sy in (("Front", -1.0), ("Back", 1.0)):
        add_box("Chest_Plank_Seam_%d_%s" % (n, fb), (W + 0.002, 0.006, 0.004),
                (0.0, sy * (D / 2.0 - 0.002), z), MAT_WOOD_DARK)
    for side, sx in (("L", -1.0), ("R", 1.0)):
        add_box("Chest_Plank_Seam_%d_%s" % (n, side), (0.006, D - 0.010, 0.004),
                (sx * (W / 2.0 - 0.002), 0.0, z), MAT_WOOD_DARK)

# ---------- 2) Curved dhakkan (hinge ke neeche parent) ----------
# Lid ka flat neecha rim ke andar chhupa hai (cut=0.002), rim ka neecha hi dhakkan ka andar ka hissa hai
add_half_cylinder_x("Chest_Lid", LID_RZ, D / 2.0, W - 0.002, (0.0, 0.0, H), MAT_WOOD,
                    parent=lid_hinge, verts=48, cut=0.002)

# Dhakkan ka rim (body aur dhakkan ke jod par)
add_box("Chest_Lid_Rim", (W + 0.006, D + 0.006, RIM_H),
        (0.0, 0.0, H + RIM_H / 2.0), MAT_WOOD_DARK, parent=lid_hinge)

# ---------- 3) Sone ki pattiyan (body par aage/peeche + dhakkan par) ----------
strap_bottom = 0.003
strap_h = H - strap_bottom
strap_d = STRAP_T + 0.004
for side, sx in (("L", -1.0), ("R", 1.0)):
    x = sx * STRAP_X
    for fb, sy in (("Front", -1.0), ("Back", 1.0)):
        add_box("Chest_Gold_Strap_Body_%s_%s" % (side, fb),
                (STRAP_W, strap_d, strap_h),
                (x, sy * (D / 2.0 + STRAP_T - strap_d / 2.0), strap_bottom + strap_h / 2.0),
                MAT_GOLD)
        # Patti ke rivets
        for j, z in enumerate((0.05, H - 0.04)):
            add_sphere("Chest_Strap_Rivet_%s_%s_%d" % (side, fb, j + 1), 0.006,
                       (x, sy * (D / 2.0 + STRAP_T), z), MAT_GOLD)
    # Dhakkan ki patti (dhakkan ke saath ghoomti hai)
    add_half_cylinder_x("Chest_Gold_Strap_Lid_" + side,
                        LID_RZ + STRAP_T, D / 2.0 + STRAP_T, STRAP_W - 0.002,
                        (x, 0.0, H), MAT_GOLD, parent=lid_hinge, verts=48, cut=0.001)

# ---------- 4) Chaar kono par dhaatu ke corner guards (L-shape plates) ----------
for nx, sx in (("L", -1.0), ("R", 1.0)):
    for ny, sy in (("Front", -1.0), ("Back", 1.0)):
        cx = sx * (W / 2.0 + GUARD_P - GUARD / 2.0)
        cy = sy * (D / 2.0 + GUARD_P - GUARD / 2.0)
        tag = "%s_%s" % (ny, nx)
        # Aage/peeche wali plate
        add_box("Chest_CornerGuard_%s_PlateY" % tag, (GUARD, GUARD_T, GUARD_H),
                (cx, sy * (D / 2.0 + GUARD_P - GUARD_T / 2.0), GUARD_H / 2.0), MAT_IRON)
        # Side wali plate
        side_len = GUARD - GUARD_T
        add_box("Chest_CornerGuard_%s_PlateX" % tag, (GUARD_T, side_len, GUARD_H),
                (sx * (W / 2.0 + GUARD_P - GUARD_T / 2.0),
                 sy * (D / 2.0 + GUARD_P - GUARD_T - side_len / 2.0),
                 GUARD_H / 2.0), MAT_IRON)
        # Har guard par 2 sone ke rivets
        add_sphere("Chest_CornerRivet_%s_SideX" % tag, 0.006,
                   (sx * (W / 2.0 + GUARD_P), cy, 0.05), MAT_GOLD)
        add_sphere("Chest_CornerRivet_%s_SideY" % tag, 0.006,
                   (cx, sy * (D / 2.0 + GUARD_P), 0.05), MAT_GOLD)

# ---------- 5) Kunda (hasp) aur taala - saamne (-Y), dhakkan ke saath uthta hai ----------
hasp_h = 0.08
hasp_t = 0.012
hasp_y = -(D / 2.0 + 0.005)
hasp_front_y = hasp_y - hasp_t / 2.0
add_box("Chest_Lock_Hasp", (0.055, hasp_t, hasp_h),
        (0.0, hasp_y, H + RIM_H - hasp_h / 2.0), MAT_GOLD, parent=lid_hinge)

lock_w, lock_d, lock_h = 0.05, 0.02, 0.042
lock_top = H - 0.052
lock_cz = lock_top - lock_h / 2.0
lock_y = hasp_front_y - lock_d / 2.0 + 0.001
add_box("Chest_Padlock_Body", (lock_w, lock_d, lock_h), (0.0, lock_y, lock_cz),
        MAT_GOLD, parent=lid_hinge)

# Taale ka kada (shackle)
add_torus("Chest_Padlock_Shackle", 0.014, 0.0035,
          (0.0, lock_y, lock_top), (math.pi / 2.0, 0.0, 0.0), MAT_IRON, parent=lid_hinge)

# Kunda jisme se shackle guzarta hai
add_box("Chest_Lock_Staple", (0.008, 0.016, 0.006),
        (0.0, hasp_front_y - 0.007, lock_top + 0.005), MAT_GOLD, parent=lid_hinge)

# Chaabi ka chhed
lock_front_y = lock_y - lock_d / 2.0
add_cylinder_y("Chest_Padlock_Keyhole", 0.004, 0.003,
               (0.0, lock_front_y, lock_cz + 0.004), MAT_BLACK, parent=lid_hinge)
add_box("Chest_Padlock_KeySlot", (0.003, 0.003, 0.012),
        (0.0, lock_front_y, lock_cz - 0.004), MAT_BLACK, parent=lid_hinge)

# ---------- 6) Side ke kunde (uthane ke ring handles) ----------
handle_z = 0.15
for side, sx in (("L", -1.0), ("R", 1.0)):
    add_box("Chest_Handle_Mount_" + side, (0.012, 0.05, 0.018),
            (sx * (W / 2.0 + 0.004), 0.0, handle_z), MAT_GOLD)
    add_torus("Chest_Handle_Ring_" + side, 0.028, 0.0045,
              (sx * (W / 2.0 + 0.012), 0.0, handle_z - 0.024),
              (0.0, math.pi / 2.0, 0.0), MAT_GOLD)

# ---------- 7) Peeche ke kabze (hinges) - barrel pivot ke axis par ----------
for side, sx in (("L", -1.0), ("R", 1.0)):
    hx = sx * HINGE_X
    # Barrel (body par sthir, isi ke axis par dhakkan ghoomta hai)
    add_cylinder_x("Chest_Hinge_Barrel_" + side, 0.007, 0.007, 0.05,
                   (hx, HINGE_Y, HINGE_Z), MAT_GOLD, verts=16)
    # Body wali patti
    add_box("Chest_Hinge_Leaf_Body_" + side, (0.05, 0.005, 0.032),
            (hx, D / 2.0 + 0.0015, H - 0.019), MAT_GOLD)
    # Dhakkan wali patti (dhakkan ke saath ghoomti hai)
    add_box("Chest_Hinge_Leaf_Lid_" + side, (0.05, 0.004, 0.016),
            (hx, D / 2.0 + 0.004, H + 0.010), MAT_GOLD, parent=lid_hinge)

# ---------- 8) Andar ka khazana (dhakkan khulne par dikhta hai) ----------
add_box("Chest_Treasure_Bed",
        (W - 2.0 * WALL + 0.002, D - 2.0 * WALL + 0.002, FILL_TOP - floor_top),
        (0.0, 0.0, (floor_top + FILL_TOP) / 2.0), MAT_GOLD)

bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=1.0,
                                     location=(0.0, 0.0, FILL_TOP))
mound = bpy.context.active_object
mound.scale = (MOUND_RX, MOUND_RY, MOUND_RZ)
finish(mound, "Chest_Treasure_Mound", MAT_GOLD)
smooth(mound)

coins = (
    (-0.15, -0.05, 12.0, -18.0),
    (-0.06, 0.06, -15.0, 8.0),
    (0.02, -0.07, 20.0, 5.0),
    (0.10, 0.04, -8.0, -14.0),
    (0.17, -0.03, 10.0, 22.0),
    (-0.21, 0.10, 0.0, 0.0),
    (0.22, 0.11, 0.0, 0.0),
    (0.20, -0.12, 0.0, 0.0),
)
for i, (cxp, cyp, tx, ty) in enumerate(coins):
    add_coin("Chest_Treasure_Coin_%d" % (i + 1),
             (cxp, cyp, heap_z(cxp, cyp) + 0.002),
             (math.radians(tx), math.radians(ty), 0.0), MAT_GOLD)

gems = (
    ("Ruby_1", 0.0, 0.0, 0.014, MAT_RUBY),
    ("Emerald_1", -0.11, 0.01, 0.012, MAT_EMERALD),
    ("Ruby_2", 0.13, -0.06, 0.011, MAT_RUBY),
)
for gname, gx, gy, gr, gmat in gems:
    add_gem("Chest_Treasure_Gem_" + gname, gr, (gx, gy, heap_z(gx, gy) + gr * 0.5), gmat)

# ---------- 9) ANIMATION: action 'open' ----------
scene.render.fps = 24
scene.render.fps_base = 1.0
scene.frame_start = 1
scene.frame_end = 48

try:
    bpy.context.preferences.edit.keyframe_new_interpolation_type = 'BEZIER'
except Exception:
    pass

# Saamne ka kinara -Y par hai aur hinge +Y par, isliye X axis par NEGATIVE rotation
# dhakkan ko upar aur peeche ki taraf kholta hai.
open_angle = -math.radians(OPEN_DEG)
for frame, ang in ((1, 0.0), (24, open_angle), (48, open_angle)):
    lid_hinge.rotation_euler = (ang, 0.0, 0.0)
    lid_hinge.keyframe_insert(data_path="rotation_euler", index=0, frame=frame)

action = lid_hinge.animation_data.action
action.name = "open"


def action_fcurves(act):
    # Naye (layered/slotted) aur purane dono action API ke liye
    fcs = []
    try:
        for layer in act.layers:
            for strip in layer.strips:
                for bag in strip.channelbags:
                    fcs.extend(bag.fcurves)
    except AttributeError:
        pass
    if not fcs:
        legacy = getattr(act, "fcurves", None)
        if legacy is not None:
            fcs.extend(legacy)
    return fcs


for fc in action_fcurves(action):
    for kp in fc.keyframe_points:
        kp.interpolation = 'BEZIER'
        kp.handle_left_type = 'AUTO_CLAMPED'
        kp.handle_right_type = 'AUTO_CLAMPED'
    fc.update()

# Sirf ek hi action rahe
for a in list(bpy.data.actions):
    if a != action:
        bpy.data.actions.remove(a)

scene.frame_set(1)

# ---------- Safai: selection hatao, root ko active rakho ----------
for o in scene.objects:
    o.select_set(False)
root.select_set(True)
bpy.context.view_layer.objects.active = root
