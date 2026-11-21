extends Node3D
# Nznsn - Jungle ke Khazane. Poori duniya code se banti hai (lakdi ka jungle).

const CHEST_COUNT := 5
const WORLD_R := 70.0
const HUT_POS := Vector3(12, 0, -9)

var rng := RandomNumberGenerator.new()
var player: CharacterBody3D
var chests: Array = []
var opened := 0
var won := false
var l_count: Label
var l_hint: Label
var l_msg: Label
var chest_scene: PackedScene

func _ready() -> void:
    rng.seed = 20261121
    chest_scene = load("res://assets/chest.glb")
    _setup_input()
    _build_environment()
    _build_ground()
    var spots := _chest_spots()
    _build_forest(spots)
    _build_hut(HUT_POS)
    _build_player()
    _build_chests(spots)
    _build_hud()
    var args := OS.get_cmdline_user_args()
    for a in args:
        if a == "--autotest":
            _autotest()
        elif a.begins_with("--shot="):
            _shots(a.substr(7))

# ---------- input ----------
func _setup_input() -> void:
    var map := {
        "move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
        "move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
        "interact": [KEY_E], "jump": [KEY_SPACE], "restart": [KEY_R],
    }
    for a in map:
        if not InputMap.has_action(a):
            InputMap.add_action(a)
        for k in map[a]:
            var ev := InputEventKey.new()
            ev.physical_keycode = k
            InputMap.action_add_event(a, ev)

# ---------- helpers ----------
func _mat(c: Color, rough := 0.9) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = rough
    return m

func _box(pos: Vector3, size: Vector3, mat: Material, rot := Vector3.ZERO) -> StaticBody3D:
    var b := StaticBody3D.new()
    b.position = pos
    b.rotation_degrees = rot
    var mi := MeshInstance3D.new()
    var bm := BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    mi.material_override = mat
    b.add_child(mi)
    var cs := CollisionShape3D.new()
    var bs := BoxShape3D.new()
    bs.size = size
    cs.shape = bs
    b.add_child(cs)
    add_child(b)
    return b

# ---------- world ----------
func _build_environment() -> void:
    var env := Environment.new()
    var sky := Sky.new()
    var sm := ProceduralSkyMaterial.new()
    sm.sky_top_color = Color(0.22, 0.4, 0.75)
    sm.sky_horizon_color = Color(0.62, 0.74, 0.82)
    sm.ground_horizon_color = Color(0.55, 0.68, 0.55)
    sky.sky_material = sm
    env.background_mode = Environment.BG_SKY
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = 0.55
    env.fog_enabled = true
    env.fog_light_color = Color(0.55, 0.68, 0.66)
    env.fog_density = 0.01
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    var we := WorldEnvironment.new()
    we.environment = env
    add_child(we)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -35, 0)
    sun.light_energy = 0.8
    sun.shadow_enabled = true
    add_child(sun)

func _build_ground() -> void:
    var g := StaticBody3D.new()
    var mi := MeshInstance3D.new()
    var pm := PlaneMesh.new()
    pm.size = Vector2(400, 400)
    mi.mesh = pm
    mi.material_override = _mat(Color(0.16, 0.33, 0.12))
    g.add_child(mi)
    var cs := CollisionShape3D.new()
    var bs := BoxShape3D.new()
    bs.size = Vector3(400, 2, 400)
    cs.shape = bs
    cs.position.y = -1.0
    g.add_child(cs)
    add_child(g)

func _chest_spots() -> Array:
    var spots := []
    for i in CHEST_COUNT:
        var a := deg_to_rad(i * 72.0 + rng.randf_range(-18.0, 18.0))
        var r := rng.randf_range(18.0, 46.0)
        var p := Vector3(sin(a) * r, 0, cos(a) * r)
        if p.distance_to(HUT_POS) < 10.0:
            p += Vector3(-14, 0, 6)
        spots.append(p)
    return spots

func _build_forest(spots: Array) -> void:
    var bark := _mat(Color(0.36, 0.23, 0.12))
    var leaf := [_mat(Color(0.08, 0.27, 0.11)), _mat(Color(0.12, 0.33, 0.14)), _mat(Color(0.07, 0.22, 0.1))]
    var placed: Array = []
    var tries := 0
    while placed.size() < 110 and tries < 2000:
        tries += 1
        var a := rng.randf() * TAU
        var r := rng.randf_range(7.0, WORLD_R)
        var p := Vector3(sin(a) * r, 0, cos(a) * r)
        if p.distance_to(HUT_POS) < 8.0:
            continue
        var bad := false
        for s in spots:
            if p.distance_to(s) < 4.5:
                bad = true
        for q in placed:
            if p.distance_to(q) < 3.0:
                bad = true
        if bad:
            continue
        placed.append(p)
        _tree(p, bark, leaf[rng.randi() % 3])
    for i in 16:
        var a2 := rng.randf() * TAU
        var r2 := rng.randf_range(6.0, 55.0)
        var p2 := Vector3(sin(a2) * r2, 0, cos(a2) * r2)
        if p2.distance_to(HUT_POS) > 8.0:
            _log(p2, rng.randf() * TAU, bark)

func _tree(p: Vector3, bark: Material, leaf: Material) -> void:
    var h := rng.randf_range(3.0, 6.0)
    var s := StaticBody3D.new()
    s.position = p
    s.rotation.y = rng.randf() * TAU
    var tm := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 0.22; cm.bottom_radius = 0.42; cm.height = h
    tm.mesh = cm
    tm.material_override = bark
    tm.position.y = h / 2.0
    s.add_child(tm)
    var cs := CollisionShape3D.new()
    var sh := CylinderShape3D.new()
    sh.radius = 0.42; sh.height = h
    cs.shape = sh
    cs.position.y = h / 2.0
    s.add_child(cs)
    var base := h * 0.55
    var scale := rng.randf_range(0.85, 1.3)
    for i in 3:
        var fm := MeshInstance3D.new()
        var cone := CylinderMesh.new()
        cone.top_radius = 0.0
        cone.bottom_radius = (2.3 - i * 0.55) * scale
        cone.height = 2.6 * scale
        fm.mesh = cone
        fm.material_override = leaf
        fm.position.y = base + i * 1.3 * scale + 1.0
        s.add_child(fm)
    var fc := CollisionShape3D.new()
    var fs := CylinderShape3D.new()
    fs.radius = 1.7 * scale
    fs.height = 4.0 * scale
    fc.shape = fs
    fc.position.y = base + 2.2 * scale
    s.add_child(fc)
    add_child(s)

func _log(p: Vector3, yaw: float, bark: Material) -> void:
    var len := rng.randf_range(2.5, 4.5)
    var rad := rng.randf_range(0.3, 0.45)
    var b := StaticBody3D.new()
    b.position = Vector3(p.x, rad, p.z)
    b.basis = Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, PI / 2.0)
    var mi := MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = rad; cm.bottom_radius = rad; cm.height = len
    mi.mesh = cm
    mi.material_override = bark
    b.add_child(mi)
    var cs := CollisionShape3D.new()
    var sh := CylinderShape3D.new()
    sh.radius = rad; sh.height = len
    cs.shape = sh
    b.add_child(cs)
    add_child(b)

func _build_hut(c: Vector3) -> void:
    var wall := _mat(Color(0.5, 0.33, 0.17))
    var floor_m := _mat(Color(0.4, 0.27, 0.14))
    var roof := _mat(Color(0.28, 0.17, 0.09))
    _box(c + Vector3(0, 0.1, 0), Vector3(6, 0.2, 5), floor_m)
    _box(c + Vector3(0, 1.6, -2.35), Vector3(6, 3, 0.3), wall)           # peeche
    _box(c + Vector3(-2.85, 1.6, 0), Vector3(0.3, 3, 5), wall)           # baayein
    _box(c + Vector3(2.85, 1.6, 0), Vector3(0.3, 3, 5), wall)            # daayein
    _box(c + Vector3(-1.95, 1.6, 2.35), Vector3(2.1, 3, 0.3), wall)      # aage (darwaze ke ek taraf)
    _box(c + Vector3(1.95, 1.6, 2.35), Vector3(2.1, 3, 0.3), wall)       # aage (dusri taraf)
    _box(c + Vector3(0, 2.75, 2.35), Vector3(1.8, 0.5, 0.3), wall)       # darwaze ke upar
    _box(c + Vector3(0, 3.55, -1.3), Vector3(6.6, 0.2, 3.3), roof, Vector3(-35, 0, 0))
    _box(c + Vector3(0, 3.55, 1.3), Vector3(6.6, 0.2, 3.3), roof, Vector3(35, 0, 0))
    var lamp := OmniLight3D.new()
    lamp.position = c + Vector3(0, 2.2, 0)
    lamp.light_color = Color(1.0, 0.75, 0.4)
    lamp.omni_range = 7.0
    add_child(lamp)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.set_script(load("res://player.gd"))
    player.position = Vector3(0, 0.5, 5)
    add_child(player)

func _build_chests(spots: Array) -> void:
    for p in spots:
        var c := Node3D.new()
        c.set_script(load("res://chest.gd"))
        c.position = p
        c.rotation.y = atan2(-p.x, -p.z)
        add_child(c)
        c.setup(chest_scene)
        c.opened_signal.connect(_on_opened)
        chests.append(c)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    l_count = _label(layer, Vector2(24, 18), 30)
    l_hint = _label(layer, Vector2(0, 0), 32)
    l_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    l_hint.position = Vector2(-220, -140)
    l_msg = _label(layer, Vector2(0, 0), 46)
    l_msg.set_anchors_preset(Control.PRESET_CENTER)
    l_msg.position = Vector2(-420, -80)
    var help := _label(layer, Vector2(24, 0), 20)
    help.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    help.position = Vector2(24, -40)
    help.text = "WASD chalo | Shift daudo | Space kudo | Mouse dekho | E sandook kholo | R dobara"
    _update_hud()

func _label(parent: Node, pos: Vector2, size: int) -> Label:
    var l := Label.new()
    l.position = pos
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_outline_color", Color.BLACK)
    l.add_theme_constant_override("outline_size", 8)
    parent.add_child(l)
    return l

# ---------- gameplay ----------
func _nearest_closed() -> Node3D:
    var best: Node3D = null
    var bd := 1e9
    for c in chests:
        if not c.is_open:
            var d := player.global_position.distance_to(c.global_position)
            if d < bd:
                bd = d
                best = c
    return best

func _update_hud() -> void:
    var n := _nearest_closed()
    var txt := "Sandook: %d / %d" % [opened, CHEST_COUNT]
    if n and player:
        txt += "   (sabse paas: %d m)" % int(player.global_position.distance_to(n.global_position))
    l_count.text = txt

func _process(_d: float) -> void:
    if Input.is_action_just_pressed("restart"):
        get_tree().reload_current_scene()
        return
    if player == null:
        return
    var n := _nearest_closed()
    var near: bool = n != null and player.global_position.distance_to(n.global_position) < 3.2
    l_hint.text = "E dabao: sandook kholo" if near and not won else ""
    if near and Input.is_action_just_pressed("interact"):
        n.open()
    if player.global_position.length() > WORLD_R + 12.0:
        player.global_position = Vector3(0, 1, 5)
        player.velocity = Vector3.ZERO
    _update_hud()

func _on_opened() -> void:
    opened += 1
    _update_hud()
    if opened >= CHEST_COUNT and not won:
        won = true
        l_msg.text = "JEET GAYE!\nVeer ne saare khazane dhoondh liye!\n(R dabao: dobara khelo)"

# ---------- tests / screenshots ----------
func _autotest() -> void:
    await get_tree().create_timer(0.5).timeout
    var ok := true
    for c in chests:
        player.global_position = c.global_position + Vector3(0, 0.5, 2.0)
        await get_tree().process_frame
        await get_tree().process_frame
        var n := _nearest_closed()
        if n != c:
            ok = false
            print("AUTOTEST: nearest galat")
        n.open()
        await get_tree().create_timer(0.1).timeout
    await get_tree().create_timer(1.2).timeout
    var anim_moved := 0
    for c in chests:
        if c.anim and c.anim.current_animation == "open":
            anim_moved += 1
    print("AUTOTEST opened=%d/%d won=%s anim_playing_open=%d/%d" % [opened, CHEST_COUNT, won, anim_moved, CHEST_COUNT])
    var pass_ := ok and won and opened == CHEST_COUNT and anim_moved == CHEST_COUNT
    print("AUTOTEST ", "PASS" if pass_ else "FAIL")
    get_tree().quit(0 if pass_ else 1)

func _shot(path: String) -> void:
    await RenderingServer.frame_post_draw
    var img := get_viewport().get_texture().get_image()
    img.save_png(path)
    print("SHOT ", path)

func _shots(dir: String) -> void:
    for i in 12:
        await get_tree().process_frame
    await _shot(dir + "/g1_spawn.png")
    var c: Node3D = chests[0]
    var d := (c.global_position - Vector3(0, c.global_position.y, 0)).normalized()
    var side := d.cross(Vector3.UP).normalized()
    player.global_position = c.global_position - d * 4.0 + side * 2.4 + Vector3(0, 0.5, 0)
    player.face((c.global_position - player.global_position).normalized())
    player.yaw += 0.55
    player._apply_look()
    for i in 10:
        await get_tree().process_frame
    await _shot(dir + "/g2_near_chest.png")
    c.open()
    await get_tree().create_timer(1.6).timeout
    await _shot(dir + "/g3_opened.png")
    var h := (HUT_POS - Vector3(0, 0, 0))
    player.global_position = HUT_POS + Vector3(0, 0.5, 9)
    player.face(Vector3(0, 0, -1))
    for i in 10:
        await get_tree().process_frame
    await _shot(dir + "/g4_hut.png")
    get_tree().quit()
