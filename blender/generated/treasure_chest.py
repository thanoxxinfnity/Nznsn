import bpy
import math

# ------------------------------------------------------------
# Chhota lakdi ka khazane ka sandook (Treasure Chest)
# Units: meters | neeche ka hissa z=0 | x/y mein centered
# Saamne ka hissa (taala) -Y ki taraf hai
# ------------------------------------------------------------

scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0

# ---------- Naap (meters) ----------
W = 0.60          # chaudai (X)
D = 0.38          # gehrai (Y)
H = 0.24          # body ki unchai (Z)
BODY_BOTTOM = 0.006   # body thoda upar, corner guards zameen par tikte hain
LID_RZ = 0.13     # dhakkan ki curve unchai
RIM_H = 0.02      # dhakkan ke rim ki unchai
STRAP_W = 0.05    # sone ki patti ki chaudai
STRAP_T = 0.007   # patti kitni bahar nikli hai
STRAP_X = 0.18    # pattiyon ki X position (+/-)
GUARD = 0.07      # corner guard ka size (X/Y)
GUARD_H = 0.08    # corner guard ki unchai
GUARD_P = 0.008   # corner guard kitna bahar nikla hai


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


# ---------- Root (sab parts iske neeche) ----------
root = bpy.data.objects.new("TreasureChest", None)
root.empty_display_size = 0.2
scene.collection.objects.link(root)


# ---------- Helper functions ----------
def finish(obj, name, mat, apply=True):
    if apply:
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    obj.name = name
    obj.data.name = name + "_Mesh"
    obj.data.materials.append(mat)
    obj.parent = root
    return obj


def smooth(obj, only_quads=False):
    for p in obj.data.polygons:
        if only_quads:
            p.use_smooth = (len(p.vertices) == 4)
        else:
            p.use_smooth = True


def add_box(name, dims, loc, mat):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.active_object
    obj.scale = dims
    return finish(obj, name, mat)


def add_cylinder_x(name, rz, ry, length, loc, mat, verts=32):
    # Cylinder jiska axis X ki taraf hai; rz = Z radius, ry = Y radius
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=verts, radius=1.0, depth=1.0, end_fill_type='NGON',
        location=loc, rotation=(0.0, math.pi / 2.0, 0.0))
    obj = bpy.context.active_object
    obj.scale = (rz, ry, length)
    finish(obj, name, mat)
    smooth(obj, only_quads=True)
    return obj


def add_cylinder_y(name, radius, length, loc, mat, verts=16):
    # Cylinder jiska axis Y ki taraf hai
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=verts, radius=1.0, depth=1.0, end_fill_type='NGON',
        location=loc, rotation=(math.pi / 2.0, 0.0, 0.0))
    obj = bpy.context.active_object
    obj.scale = (radius, radius, length)
    finish(obj, name, mat)
    smooth(obj, only_quads=True)
    return obj


def add_sphere(name, radius, loc, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=12, ring_count=6, radius=radius, location=loc)
    obj = bpy.context.active_object
    finish(obj, name, mat)
    smooth(obj)
    return obj


def add_torus(name, major, minor, loc, rot, mat):
    bpy.ops.mesh.primitive_torus_add(
        align='WORLD', location=loc, rotation=rot,
        major_segments=24, minor_segments=8,
        major_radius=major, minor_radius=minor)
    obj = bpy.context.active_object
    finish(obj, name, mat)
    smooth(obj)
    return obj


# ---------- 1) Lakdi ka body ----------
body_h = H - BODY_BOTTOM
add_box("Chest_Body", (W, D, body_h), (0.0, 0.0, BODY_BOTTOM + body_h / 2.0), MAT_WOOD)

# Takhton (planks) ke beech ki gehri lakeerein
for i, z in enumerate((0.09, 0.165)):
    add_box("Chest_Plank_Seam_%d" % (i + 1), (W + 0.002, D + 0.002, 0.004),
            (0.0, 0.0, z), MAT_WOOD_DARK)

# ---------- 2) Curved dhakkan (band) ----------
add_cylinder_x("Chest_Lid", LID_RZ, D / 2.0, W - 0.002, (0.0, 0.0, H), MAT_WOOD, verts=48)

# Dhakkan ka rim (body aur dhakkan ke jod par)
add_box("Chest_Lid_Rim", (W + 0.006, D + 0.006, RIM_H),
        (0.0, 0.0, H + RIM_H / 2.0), MAT_WOOD_DARK)

# ---------- 3) Sone ki pattiyan (body + dhakkan par) ----------
strap_bottom = 0.003
strap_h = H - strap_bottom
for side, sx in (("L", -1.0), ("R", 1.0)):
    x = sx * STRAP_X
    add_box("Chest_Gold_Strap_Body_" + side,
            (STRAP_W, D + 2.0 * STRAP_T, strap_h),
            (x, 0.0, strap_bottom + strap_h / 2.0), MAT_GOLD)
    add_cylinder_x("Chest_Gold_Strap_Lid_" + side,
                   LID_RZ + STRAP_T, D / 2.0 + STRAP_T, STRAP_W - 0.002,
                   (x, 0.0, H), MAT_GOLD, verts=48)
    # Patti ke rivets (aage aur peeche)
    for fb, sy in (("Front", -1.0), ("Back", 1.0)):
        for j, z in enumerate((0.05, H - 0.04)):
            add_sphere("Chest_Strap_Rivet_%s_%s_%d" % (side, fb, j + 1), 0.006,
                       (x, sy * (D / 2.0 + STRAP_T), z), MAT_GOLD)

# ---------- 4) Chaar kono par dhaatu ke corner guards ----------
for nx, sx in (("L", -1.0), ("R", 1.0)):
    for ny, sy in (("Front", -1.0), ("Back", 1.0)):
        cx = sx * (W / 2.0 + GUARD_P - GUARD / 2.0)
        cy = sy * (D / 2.0 + GUARD_P - GUARD / 2.0)
        tag = "%s_%s" % (ny, nx)
        add_box("Chest_CornerGuard_" + tag, (GUARD, GUARD, GUARD_H),
                (cx, cy, GUARD_H / 2.0), MAT_IRON)
        # Har guard par 2 sone ke rivets
        add_sphere("Chest_CornerRivet_%s_SideX" % tag, 0.006,
                   (sx * (W / 2.0 + GUARD_P), cy, 0.05), MAT_GOLD)
        add_sphere("Chest_CornerRivet_%s_SideY" % tag, 0.006,
                   (cx, sy * (D / 2.0 + GUARD_P), 0.05), MAT_GOLD)

# ---------- 5) Kunda (hasp) aur taala - saamne (-Y) ----------
hasp_h = 0.08
hasp_t = 0.012
hasp_y = -(D / 2.0 + 0.005)
hasp_front_y = hasp_y - hasp_t / 2.0
add_box("Chest_Lock_Hasp", (0.055, hasp_t, hasp_h),
        (0.0, hasp_y, H + RIM_H - hasp_h / 2.0), MAT_GOLD)

lock_w, lock_d, lock_h = 0.05, 0.02, 0.042
lock_top = H - 0.052
lock_cz = lock_top - lock_h / 2.0
lock_y = hasp_front_y - lock_d / 2.0 + 0.001
add_box("Chest_Padlock_Body", (lock_w, lock_d, lock_h), (0.0, lock_y, lock_cz), MAT_GOLD)

# Taale ka kada (shackle)
add_torus("Chest_Padlock_Shackle", 0.014, 0.0035,
          (0.0, lock_y, lock_top), (math.pi / 2.0, 0.0, 0.0), MAT_IRON)

# Kunda jisme se shackle guzarta hai
add_box("Chest_Lock_Staple", (0.008, 0.016, 0.006),
        (0.0, hasp_front_y - 0.007, lock_top + 0.005), MAT_GOLD)

# Chaabi ka chhed
lock_front_y = lock_y - lock_d / 2.0
add_cylinder_y("Chest_Padlock_Keyhole", 0.004, 0.003,
               (0.0, lock_front_y, lock_cz + 0.004), MAT_BLACK)
add_box("Chest_Padlock_KeySlot", (0.003, 0.003, 0.012),
        (0.0, lock_front_y, lock_cz - 0.004), MAT_BLACK)

# ---------- 6) Side ke kunde (uthane ke ring handles) ----------
handle_z = 0.15
for side, sx in (("L", -1.0), ("R", 1.0)):
    add_box("Chest_Handle_Mount_" + side, (0.012, 0.05, 0.018),
            (sx * (W / 2.0 + 0.004), 0.0, handle_z), MAT_GOLD)
    add_torus("Chest_Handle_Ring_" + side, 0.028, 0.0045,
              (sx * (W / 2.0 + 0.012), 0.0, handle_z - 0.024),
              (0.0, math.pi / 2.0, 0.0), MAT_GOLD)

# ---------- 7) Peeche ke kabze (hinges) ----------
for side, sx in (("L", -1.0), ("R", 1.0)):
    add_cylinder_x("Chest_Hinge_" + side, 0.007, 0.007, 0.05,
                   (sx * 0.07, D / 2.0 + 0.008, H), MAT_GOLD, verts=16)

# ---------- Safai: selection hatao, root ko active rakho ----------
for o in scene.objects:
    o.select_set(False)
root.select_set(True)
bpy.context.view_layer.objects.active = root
