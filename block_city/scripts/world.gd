class_name VoxelWorld
extends Node3D
# Dabbe (voxel) ki duniya: terrain + shehar + ped. Chunks mein mesh banta hai. Dhamake se dabbe udte hain.

const W := 96
const D := 96
const H := 40
const CS := 16
const SEA := 7
const PLATEAU := 10
const CENTER := Vector2(48, 48)

const AIR := 0
const GRASS := 1
const DIRT := 2
const STONE := 3
const SAND := 4
const WOOD := 5
const LEAVES := 6
const ROAD := 7
const WALL := 8
const GLASS := 9
const ROOF := 10
const WALK := 11
const WALL2 := 12
const WALL3 := 13
const BEDROCK := 14

var COLORS: Array[Color] = [
    Color(0, 0, 0), Color(0.36, 0.66, 0.25), Color(0.47, 0.33, 0.2), Color(0.5, 0.5, 0.52),
    Color(0.86, 0.8, 0.55), Color(0.4, 0.27, 0.14), Color(0.2, 0.5, 0.2), Color(0.2, 0.2, 0.22),
    Color(0.75, 0.38, 0.3), Color(0.62, 0.85, 0.95), Color(0.3, 0.3, 0.36), Color(0.72, 0.72, 0.7),
    Color(0.86, 0.78, 0.55), Color(0.55, 0.62, 0.78), Color(0.12, 0.12, 0.14)]

var vox := PackedByteArray()
var top := PackedInt32Array()
var chunk_mesh := {}
var chunk_body := {}
var mat: StandardMaterial3D
var water: MeshInstance3D
var buildings: Array = []
var road_points: Array = []
var spawn_pos := Vector3(49.5, 12, 49.5)

func _ready() -> void:
    mat = StandardMaterial3D.new()
    mat.vertex_color_use_as_albedo = true
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.cull_mode = BaseMaterial3D.CULL_BACK

func idx(x: int, y: int, z: int) -> int:
    return x + z * W + y * W * D

func get_b(x: int, y: int, z: int) -> int:
    if x < 0 or x >= W or z < 0 or z >= D or y >= H:
        return AIR
    if y < 0:
        return STONE
    return vox[idx(x, y, z)]

func set_b(x: int, y: int, z: int, b: int) -> void:
    if x < 0 or x >= W or z < 0 or z >= D or y < 0 or y >= H:
        return
    vox[idx(x, y, z)] = b
    if b != AIR and y > top[x + z * W]:
        top[x + z * W] = y

func solid_at(p: Vector3) -> bool:
    var b := get_b(int(floor(p.x)), int(floor(p.y)), int(floor(p.z)))
    return b != AIR

func ground_y(x: int, z: int) -> int:
    for y in range(H - 1, -1, -1):
        var b := get_b(x, y, z)
        if b != AIR and b != LEAVES:
            return y + 1
    return 1

# ---------------- generation ----------------
func generate(seed_: int) -> void:
    vox.resize(W * D * H)
    vox.fill(0)
    top.resize(W * D)
    top.fill(0)
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_
    var n := FastNoiseLite.new()
    n.seed = seed_
    n.frequency = 0.022
    n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    var n2 := FastNoiseLite.new()
    n2.seed = seed_ + 7
    n2.frequency = 0.09
    var heights := PackedInt32Array()
    heights.resize(W * D)
    for z in D:
        for x in W:
            var dist := Vector2(x, z).distance_to(CENTER)
            var h := 10.0 + n.get_noise_2d(x, z) * 8.0 + n2.get_noise_2d(x, z) * 1.6
            var t := clampf((44.0 - dist) / 8.0, 0.0, 1.0)
            h = lerpf(h, float(PLATEAU) + 0.5, t)
            var edge := float(mini(mini(x, W - 1 - x), mini(z, D - 1 - z)))
            if edge < 10.0:
                h = lerpf(3.0, h, edge / 10.0)
            var hi := clampi(int(h), 2, H - 28)
            heights[x + z * W] = hi
            for y in range(hi + 1):
                var b := STONE if y < hi - 3 else DIRT
                if y == hi:
                    b = SAND if hi <= SEA + 1 else GRASS
                elif hi <= SEA + 1 and y >= hi - 3:
                    b = SAND
                if y == 0:
                    b = BEDROCK
                set_b(x, y, z, b)
    _make_city(rng, heights)
    _make_trees(rng, heights)

func _make_city(rng: RandomNumberGenerator, heights: PackedInt32Array) -> void:
    var gy := PLATEAU
    for z in D:
        for x in W:
            var dist := Vector2(x, z).distance_to(CENTER)
            if dist > 34.0:
                continue
            var lx := ((x - 6) % 14 + 14) % 14
            var lz := ((z - 6) % 14 + 14) % 14
            if heights[x + z * W] != gy:
                continue
            if lx < 3 or lz < 3:
                set_b(x, gy, z, ROAD)
                if (lx == 1 and lz >= 3 and z % 4 < 2) or (lz == 1 and lx >= 3 and x % 4 < 2):
                    set_b(x, gy, z, WALK)  # sadak ke beech ki lakeer
                if lx == 1 and lz == 1:
                    road_points.append(Vector3(x + 0.5, gy + 1.0, z + 0.5))
                elif (lx == 1 and lz >= 3 and z % 6 == 0) or (lz == 1 and lx >= 3 and x % 6 == 0):
                    road_points.append(Vector3(x + 0.5, gy + 1.0, z + 0.5))
            elif lx == 3 or lx == 13 or lz == 3 or lz == 13:
                set_b(x, gy, z, WALK)
    # imaarat
    var wall_types := [WALL, WALL2, WALL3]
    for lot_z in range(6, D - 14, 14):
        for lot_x in range(6, W - 14, 14):
            var cx := lot_x + 3 + 4.5
            var cz := lot_z + 3 + 4.5
            if Vector2(cx, cz).distance_to(CENTER) > 30.0:
                continue
            if rng.randf() < 0.2:
                continue
            var w := rng.randi_range(5, 9)
            var d := rng.randi_range(5, 9)
            var x0 := lot_x + 4 + rng.randi_range(0, 9 - w)
            var z0 := lot_z + 4 + rng.randi_range(0, 9 - d)
            var hgt := rng.randi_range(5, 22)
            var wt: int = wall_types[rng.randi() % 3]
            var y0 := gy + 1
            for yy in range(y0, y0 + hgt + 1):
                for zz in range(z0, z0 + d):
                    for xx in range(x0, x0 + w):
                        var perim := xx == x0 or xx == x0 + w - 1 or zz == z0 or zz == z0 + d - 1
                        if yy == y0 + hgt:
                            set_b(xx, yy, zz, ROOF)
                        elif perim:
                            var b := wt
                            if yy % 3 == 2 and (xx + zz) % 2 == 0 and yy > y0:
                                b = GLASS
                            set_b(xx, yy, zz, b)
                        elif yy == y0:
                            set_b(xx, gy, zz, WALK)
            # darwaza (dakshin taraf)
            var dx := x0 + w / 2
            set_b(dx, y0, z0 + d - 1, AIR)
            set_b(dx, y0 + 1, z0 + d - 1, AIR)
            buildings.append({"x0": x0, "z0": z0, "w": w, "d": d, "y0": y0, "h": hgt})
    spawn_pos = Vector3(49.5, gy + 2.0, 49.5)

func _make_trees(rng: RandomNumberGenerator, heights: PackedInt32Array) -> void:
    for z in range(3, D - 3):
        for x in range(3, W - 3):
            var dist := Vector2(x, z).distance_to(CENTER)
            var hi := heights[x + z * W]
            if dist < 40.0 or hi <= SEA + 2 or get_b(x, hi, z) != GRASS:
                continue
            if rng.randf() > 0.022:
                continue
            var th := rng.randi_range(4, 5)
            for y in range(1, th + 1):
                set_b(x, hi + y, z, WOOD)
            for dy in range(th - 1, th + 3):
                var r := 2 if dy < th + 1 else 1
                for dz in range(-r, r + 1):
                    for dx in range(-r, r + 1):
                        if absi(dx) == r and absi(dz) == r and r == 2 and rng.randf() < 0.5:
                            continue
                        if get_b(x + dx, hi + dy, z + dz) == AIR:
                            set_b(x + dx, hi + dy, z + dz, LEAVES)

# ---------------- meshing ----------------
func build_all() -> void:
    for cz in D / CS:
        for cx in W / CS:
            build_chunk(cx, cz)

func chunk_count() -> int:
    return (W / CS) * (D / CS)

const FACES := [
    # normal, shade, corners (CCW bahar se dekhne par)
    [Vector3(0, 1, 0), 1.0, [Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 0), Vector3(0, 1, 0)]],
    [Vector3(0, -1, 0), 0.5, [Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1)]],
    [Vector3(1, 0, 0), 0.8, [Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(1, 0, 1)]],
    [Vector3(-1, 0, 0), 0.68, [Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(0, 1, 0), Vector3(0, 0, 0)]],
    [Vector3(0, 0, 1), 0.88, [Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1), Vector3(0, 0, 1)]],
    [Vector3(0, 0, -1), 0.74, [Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 0, 0)]],
]

func build_chunk(cx: int, cz: int) -> void:
    var verts := PackedVector3Array()
    var cols := PackedColorArray()
    var x0 := cx * CS
    var z0 := cz * CS
    for z in range(z0, z0 + CS):
        for x in range(x0, x0 + CS):
            var tp := top[x + z * W]
            for y in range(0, tp + 1):
                var b := vox[idx(x, y, z)]
                if b == AIR:
                    continue
                var base := COLORS[b]
                var hsh := float((x * 73856093 ^ y * 19349663 ^ z * 83492791) & 255) / 255.0
                var tint := 0.93 + 0.07 * hsh
                for f in FACES:
                    var nrm: Vector3 = f[0]
                    if get_b(x + int(nrm.x), y + int(nrm.y), z + int(nrm.z)) != AIR:
                        continue
                    var c := base * (float(f[1]) * tint)
                    c.a = 1.0
                    var cr: Array = f[2]
                    var p0: Vector3 = Vector3(x, y, z) + cr[0]
                    var p1: Vector3 = Vector3(x, y, z) + cr[1]
                    var p2: Vector3 = Vector3(x, y, z) + cr[2]
                    var p3: Vector3 = Vector3(x, y, z) + cr[3]
                    verts.append_array([p0, p2, p1, p0, p3, p2])
                    cols.append_array([c, c, c, c, c, c])
    var key := Vector2i(cx, cz)
    if chunk_mesh.has(key):
        chunk_mesh[key].queue_free()
        chunk_body[key].queue_free()
        chunk_mesh.erase(key)
        chunk_body.erase(key)
    if verts.is_empty():
        return
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = verts
    arrays[Mesh.ARRAY_COLOR] = cols
    var am := ArrayMesh.new()
    am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    var mi := MeshInstance3D.new()
    mi.mesh = am
    mi.material_override = mat
    add_child(mi)
    var body := StaticBody3D.new()
    var cs := CollisionShape3D.new()
    var shape := ConcavePolygonShape3D.new()
    shape.set_faces(verts)
    cs.shape = shape
    body.add_child(cs)
    add_child(body)
    chunk_mesh[key] = mi
    chunk_body[key] = body

func make_water() -> void:
    water = MeshInstance3D.new()
    var pm := PlaneMesh.new()
    pm.size = Vector2(500, 500)
    water.mesh = pm
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(0.2, 0.5, 0.85, 0.72)
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    water.material_override = m
    water.position = Vector3(W / 2.0, SEA + 0.85, D / 2.0)
    add_child(water)

# ---------------- dhamaka ----------------
func explode(c: Vector3, r: float) -> int:
    var removed := 0
    var dirty := {}
    for y in range(maxi(1, int(floor(c.y - r))), mini(H, int(ceil(c.y + r)) + 1)):
        for z in range(maxi(0, int(floor(c.z - r))), mini(D, int(ceil(c.z + r)) + 1)):
            for x in range(maxi(0, int(floor(c.x - r))), mini(W, int(ceil(c.x + r)) + 1)):
                var b := vox[idx(x, y, z)]
                if b == AIR:
                    continue
                var d := Vector3(x + 0.5, y + 0.5, z + 0.5).distance_to(c)
                var hsh := float((x * 31 + y * 17 + z * 13) % 10) / 10.0
                if d <= r - 0.5 + hsh * 1.0:
                    vox[idx(x, y, z)] = AIR
                    removed += 1
                    dirty[Vector2i(x / CS, z / CS)] = true
                    if x % CS == 0 and x > 0: dirty[Vector2i(x / CS - 1, z / CS)] = true
                    if x % CS == CS - 1 and x < W - 1: dirty[Vector2i(x / CS + 1, z / CS)] = true
                    if z % CS == 0 and z > 0: dirty[Vector2i(x / CS, z / CS - 1)] = true
                    if z % CS == CS - 1 and z < D - 1: dirty[Vector2i(x / CS, z / CS + 1)] = true
    for k in dirty:
        build_chunk(k.x, k.y)
    return removed

func count_solid_box(x0: int, z0: int, w: int, d: int, y0: int, h: int) -> int:
    var n := 0
    for y in range(y0, mini(H, y0 + h + 1)):
        for z in range(z0, z0 + d):
            for x in range(x0, x0 + w):
                if vox[idx(x, y, z)] != AIR:
                    n += 1
    return n
