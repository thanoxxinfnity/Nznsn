extends Node3D
# Block City: sab kuch yahan jodta hai.

const SKY_DAY := Color(0.45, 0.72, 0.96)
const SKY_NIGHT := Color(0.03, 0.05, 0.12)

var world: VoxelWorld
var player: Player
var hud: Hud
var missions: Missions
var cars: Array = []
var npcs: Array = []
var npc_respawn: Array = []
var sun: DirectionalLight3D
var env: Environment
var daytime := 0.28
var money := 0
var built := false
var fails := 0
var _last_idx := -99
var wanted := 0.0
var crime_t := 99.0
var police: Array = []
var police_timer := 0.0
var calm_t := 0.0
var clouds: Array = []
var cloud_mat: StandardMaterial3D
var testing := false
var save_path := "user://blockcity.json"
var save_t := 0.0
var snd := {}
var engine_p: AudioStreamPlayer
var siren_p: AudioStreamPlayer
var hurt_cd := 0.0

func _ready() -> void:
    for a in OS.get_cmdline_user_args():
        if a == "--autotest" or a.begins_with("--shot="):
            testing = true
    _setup_audio()
    _setup_env()
    var layer := CanvasLayer.new()
    add_child(layer)
    hud = Hud.new()
    layer.add_child(hud)
    world = VoxelWorld.new()
    add_child(world)
    await get_tree().process_frame
    hud.load_frac = 0.03
    await get_tree().process_frame
    world.generate(4242)
    world.make_water()
    var total := world.chunk_count()
    var i := 0
    for cz in range(VoxelWorld.D / VoxelWorld.CS):
        for cx in range(VoxelWorld.W / VoxelWorld.CS):
            world.build_chunk(cx, cz)
            i += 1
            hud.load_frac = 0.08 + 0.85 * float(i) / float(total)
            await get_tree().process_frame
    _make_clouds()
    _spawn_entities()
    hud.load_frac = 1.0
    built = true
    for a in OS.get_cmdline_user_args():
        if a == "--autotest":
            _autotest()
        elif a.begins_with("--shot="):
            _shots(a.substr(7))

func _setup_env() -> void:
    env = Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = SKY_DAY
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.85, 0.85, 0.9)
    env.fog_enabled = true
    env.fog_light_color = SKY_DAY
    env.fog_density = 0.006
    var we := WorldEnvironment.new()
    we.environment = env
    add_child(we)
    sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -30, 0)
    add_child(sun)

func _spawn_entities() -> void:
    player = Player.new()
    player.world = world
    player.collision_layer = 2
    player.collision_mask = 1
    add_child(player)
    player.global_position = world.spawn_pos
    player.bomb_thrown.connect(_on_bomb)
    player.died.connect(_on_died)
    var gy := float(VoxelWorld.PLATEAU) + 1.05
    var spots := [
        [Vector3(49.5, gy, 57.0), 0.0, Color(0.85, 0.15, 0.15)],
        [Vector3(49.5, gy, 41.0), 0.0, Color(0.95, 0.8, 0.1)],
        [Vector3(57.0, gy, 49.5), PI / 2.0, Color(0.2, 0.4, 0.9)],
        [Vector3(41.0, gy, 49.5), PI / 2.0, Color(0.2, 0.7, 0.3)],
    ]
    for s in spots:
        var c := Car.new()
        c.collision_layer = 2
        c.collision_mask = 1
        c.setup(s[2], s[0], s[1])
        add_child(c)
        cars.append(c)
    for i in 14:
        _spawn_npc()
    missions = Missions.new()
    missions.world = world
    missions.player = player
    add_child(missions)
    missions.reward.connect(func(n: int) -> void:
        money += n
        _play("coin", 2.0)
        missions.idx += 0
        _save())
    missions.pickup.connect(func() -> void: _play("coin", -2.0))
    player.jumped.connect(func() -> void: _play("jump", -8.0))
    player.got_hurt.connect(func() -> void:
        if hurt_cd <= 0.0:
            _play("hurt", -4.0)
            hurt_cd = 0.4)
    if not testing:
        var d := _read_save()
        if d.has("money"):
            money = int(d["money"])
            missions.idx = int(d.get("idx", 0)) - 1
    missions.toast.connect(func(m: String) -> void: hud.show_toast(m))
    missions.pause_t = 1.5

func _spawn_npc() -> void:
    var n := Npc.new()
    n.collision_layer = 4
    n.collision_mask = 1
    add_child(n)
    var p: Vector3 = world.road_points[randi() % world.road_points.size()]
    n.global_position = p + Vector3(randf_range(-1.0, 1.0), 0.6, randf_range(-1.0, 1.0))
    npcs.append(n)

func _process(delta: float) -> void:
    if not built:
        return
    daytime = fmod(daytime + delta / 260.0, 1.0)
    var day := clampf(0.5 + 0.6 * sin(daytime * TAU), 0.0, 1.0)
    var b := lerpf(0.34, 1.0, day)
    world.mat.albedo_color = Color(b, b, b * 1.04)
    var wm := world.water.material_override as StandardMaterial3D
    wm.albedo_color = Color(0.2 * b, 0.5 * b, 0.85 * b, 0.72)
    var sky := SKY_NIGHT.lerp(SKY_DAY, day)
    env.background_color = sky
    env.fog_light_color = sky
    env.ambient_light_energy = lerpf(0.35, 1.0, day)
    sun.light_energy = lerpf(0.12, 1.0, day)
    sun.rotation_degrees.x = -25.0 - 50.0 * day
    # gaadi enter/exit
    if Ctl.act:
        Ctl.act = false
        _toggle_car()
    if player.in_car != null:
        player.global_position = player.in_car.global_position
    # respawn
    for c in cars:
        if c.dead_t > 0.0:
            c.dead_t -= delta
            if c.dead_t <= 0.0:
                c.visible = true
                c.position = c.home
                c.spd = 0.0
    for i in range(npc_respawn.size() - 1, -1, -1):
        npc_respawn[i] -= delta
        if npc_respawn[i] <= 0.0:
            npc_respawn.remove_at(i)
            _spawn_npc()
    # wanted + police
    crime_t += delta
    hurt_cd -= delta
    if crime_t > 8.0 and wanted > 0.0:
        wanted = maxf(0.0, wanted - 0.08 * delta)
    var stars := int(ceil(wanted - 0.001))
    police_timer -= delta
    if stars > 0:
        calm_t = 0.0
        if police.size() < stars and police_timer <= 0.0:
            _spawn_police()
            police_timer = 3.5
    else:
        calm_t += delta
        if calm_t > 4.0 and not police.is_empty():
            for pp in police:
                if is_instance_valid(pp):
                    pp.queue_free()
            police.clear()
    var tp := (player.in_car.global_position if player.in_car else player.global_position)
    var nearest := 999.0
    for pp in police:
        if is_instance_valid(pp):
            pp.target_pos = tp
            nearest = minf(nearest, pp.global_position.distance_to(tp))
    if nearest < 60.0 and not siren_p.playing:
        siren_p.play()
    elif nearest >= 60.0 and siren_p.playing:
        siren_p.stop()
    siren_p.volume_db = lerpf(-4.0, -28.0, clampf(nearest / 60.0, 0.0, 1.0))
    if player.in_car != null:
        var cc := player.in_car as Car
        if not engine_p.playing:
            engine_p.play()
        engine_p.pitch_scale = 0.7 + absf(cc.spd) / 17.0 * 1.3
    elif engine_p.playing:
        engine_p.stop()
    for cl in clouds:
        cl.position.x += delta * 1.4
        if cl.position.x > VoxelWorld.W + 30.0:
            cl.position.x = -30.0
    cloud_mat.albedo_color = Color(b, b, b, 0.92)
    save_t += delta
    if save_t > 20.0:
        save_t = 0.0
        _save()
    # HUD
    hud.stars = stars
    hud.hp = player.hp
    hud.money = money
    hud.title = missions.title if missions.pause_t <= 0.0 else ""
    hud.text = missions.text
    hud.in_car = player.in_car != null
    hud.radar = _radar()

func _radar() -> Array:
    var out: Array = []
    var pp := player.global_position
    var cy := cos(player.yaw)
    var sy := sin(player.yaw)
    var items: Array = []
    for t in missions.targets:
        items.append([t, Color(1.0, 0.85, 0.1)])
    for c in cars:
        if c.dead_t <= 0.0 and c != player.in_car:
            items.append([c.global_position, Color(0.4, 0.7, 1.0)])
    for it in items:
        var dx: float = it[0].x - pp.x
        var dz: float = it[0].z - pp.z
        var rx := dx * cy - dz * sy
        var ru := -dx * sy - dz * cy
        out.append([Vector2(rx, -ru) / 45.0, it[1]])
    return out

func _toggle_car() -> void:
    if player.in_car != null:
        var c := player.in_car as Car
        c.driver = null
        player.in_car = null
        player.rig.visible = true
        player.collision_layer = 2
        player.collision_mask = 1
        player.global_position = c.global_position + c.global_transform.basis.x * 2.4 + Vector3(0, 0.3, 0)
        player.velocity = Vector3.ZERO
    else:
        var best: Car = null
        var bd := 4.8
        for c in cars:
            var d := player.global_position.distance_to(c.global_position)
            if c.dead_t <= 0.0 and d < bd:
                bd = d
                best = c
        if best != null:
            best.driver = player
            player.in_car = best
            player.rig.visible = false
            player.collision_layer = 0
            player.collision_mask = 0
            hud.show_toast("Gaadi: upar=aage, neeche=peeche, baayein/daayein=mudo")

func _on_bomb(pos: Vector3, vel: Vector3) -> void:
    _play("throw", -4.0)
    var b := Bomb.new()
    b.world = world
    b.vel = vel
    add_child(b)
    b.global_position = pos
    b.exploded.connect(_on_explode)

func _on_explode(pos: Vector3) -> void:
    var r := 4.3
    var removed := world.explode(pos, r)
    _fx_boom(pos, r, removed > 0)
    var d := player.global_position.distance_to(pos)
    player.shake = maxf(player.shake, clampf(1.0 - d / 30.0, 0.0, 1.0))
    if d < r * 1.7 and player.in_car == null:
        player.hurt((1.0 - d / (r * 1.7)) * 55.0)
    for n in npcs.duplicate():
        if is_instance_valid(n) and n.global_position.distance_to(pos) < r * 1.6:
            _kill_npc(n)
    for c in cars:
        if c.dead_t <= 0.0 and c.global_position.distance_to(pos) < r * 1.5:
            _blow_car(c)
    for pc in police.duplicate():
        if is_instance_valid(pc) and pc.global_position.distance_to(pos) < r * 1.5:
            _blow_police(pc)
    _play("boom", lerpf(0.0, -20.0, clampf(d / 40.0, 0.0, 1.0)))
    Input.vibrate_handheld(140)

func _kill_npc(n: Node3D) -> void:
    _fx_boom(n.global_position + Vector3(0, 1, 0), 1.0, false)
    npcs.erase(n)
    n.queue_free()
    npc_respawn.append(10.0)
    add_wanted(0.6)

func _blow_car(c: Car) -> void:
    if c.driver != null:
        _toggle_car()
    _fx_boom(c.global_position + Vector3(0, 1, 0), 2.2, false)
    c.dead_t = 9.0
    add_wanted(1.0)
    c.visible = false
    c.position = c.home + Vector3(0, -120, 0)
    c.velocity = Vector3.ZERO

func _fx_boom(pos: Vector3, r: float, debris: bool) -> void:
    var ball := MeshInstance3D.new()
    var sm := SphereMesh.new()
    sm.radius = 1.0
    sm.height = 2.0
    sm.radial_segments = 12
    sm.rings = 6
    ball.mesh = sm
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.albedo_color = Color(1.0, 0.65, 0.15, 0.9)
    ball.material_override = m
    ball.scale = Vector3.ONE * 0.4
    add_child(ball)
    ball.global_position = pos
    var tw := create_tween()
    tw.set_parallel(true)
    tw.tween_property(ball, "scale", Vector3.ONE * r * 1.15, 0.28)
    tw.tween_property(m, "albedo_color:a", 0.0, 0.4)
    tw.chain().tween_callback(ball.queue_free)
    var light := OmniLight3D.new()
    light.light_color = Color(1.0, 0.7, 0.3)
    light.omni_range = r * 5.0
    light.light_energy = 3.0
    add_child(light)
    light.global_position = pos
    var tl := create_tween()
    tl.tween_property(light, "light_energy", 0.0, 0.4)
    tl.tween_callback(light.queue_free)
    var colors := [Color(0.5, 0.5, 0.52), Color(0.47, 0.33, 0.2), Color(1.0, 0.55, 0.1)] if debris else [Color(1.0, 0.55, 0.1), Color(0.3, 0.3, 0.3)]
    for col in colors:
        var p := CPUParticles3D.new()
        var bm := BoxMesh.new()
        bm.size = Vector3(0.28, 0.28, 0.28)
        var pm := StandardMaterial3D.new()
        pm.albedo_color = col
        pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        bm.material = pm
        p.mesh = bm
        p.amount = 22 if debris else 12
        p.lifetime = 1.3
        p.one_shot = true
        p.explosiveness = 1.0
        p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
        p.emission_sphere_radius = maxf(0.4, r * 0.35)
        p.direction = Vector3(0, 1, 0)
        p.spread = 180.0
        p.initial_velocity_min = 4.0
        p.initial_velocity_max = 5.0 + r * 1.8
        p.gravity = Vector3(0, -18, 0)
        p.scale_amount_min = 0.5
        p.scale_amount_max = 1.5
        add_child(p)
        p.global_position = pos
        p.emitting = true
        get_tree().create_timer(2.0).timeout.connect(p.queue_free)

func _on_died() -> void:
    if player.in_car != null:
        _toggle_car()
    money = maxi(0, money - 100)
    hud.show_toast("WASTED!  -$100")
    player.hp = 100.0
    player.velocity = Vector3.ZERO
    player.global_position = world.spawn_pos
    wanted = 0.0
    for pp in police:
        if is_instance_valid(pp):
            pp.queue_free()
    police.clear()

func add_wanted(a: float) -> void:
    var before := int(ceil(wanted - 0.001))
    wanted = minf(3.0, wanted + a)
    crime_t = 0.0
    if before == 0 and wanted > 0.0:
        hud.show_toast("WANTED! Police aa rahi hai")

func _spawn_police() -> void:
    var tp := (player.in_car.global_position if player.in_car else player.global_position)
    var best: Vector3 = world.road_points[0]
    for i in 40:
        var c: Vector3 = world.road_points[randi() % world.road_points.size()]
        var dd := Vector2(c.x - tp.x, c.z - tp.z).length()
        if dd > 28.0 and dd < 55.0:
            best = c
            break
    var p := Police.new()
    p.collision_layer = 2
    p.collision_mask = 1
    p.setup(Color.WHITE, best + Vector3(0, 0.1, 0), 0.0)
    add_child(p)
    p.hit.connect(func(dm: float) -> void: player.hurt(dm))
    police.append(p)

func _blow_police(p: Node3D) -> void:
    _fx_boom(p.global_position + Vector3(0, 1, 0), 2.2, false)
    police.erase(p)
    p.queue_free()
    add_wanted(0.5)

func _play(n: String, db := 0.0) -> void:
    var p := AudioStreamPlayer.new()
    p.stream = snd[n]
    p.volume_db = db
    add_child(p)
    p.finished.connect(p.queue_free)
    p.play()

func _setup_audio() -> void:
    snd = {"boom": Sfx.boom(), "coin": Sfx.coin(), "jump": Sfx.jump(), "throw": Sfx.throw_(), "hurt": Sfx.hurt()}
    engine_p = AudioStreamPlayer.new()
    engine_p.stream = Sfx.engine()
    engine_p.volume_db = -12.0
    add_child(engine_p)
    siren_p = AudioStreamPlayer.new()
    siren_p.stream = Sfx.siren()
    add_child(siren_p)

func _make_clouds() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 5
    cloud_mat = StandardMaterial3D.new()
    cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    cloud_mat.albedo_color = Color(1, 1, 1, 0.92)
    for i in 12:
        var c := Node3D.new()
        for j in rng.randi_range(3, 6):
            var mi := MeshInstance3D.new()
            var bm := BoxMesh.new()
            bm.size = Vector3(rng.randf_range(5.0, 9.0), 2.0, rng.randf_range(4.0, 7.0))
            mi.mesh = bm
            mi.material_override = cloud_mat
            mi.position = Vector3(j * 5.0 - 10.0, rng.randf_range(-0.4, 0.4), rng.randf_range(-3.0, 3.0))
            c.add_child(mi)
        c.position = Vector3(rng.randf_range(-30.0, 130.0), rng.randf_range(32.0, 38.0), rng.randf_range(-10.0, 106.0))
        add_child(c)
        clouds.append(c)

func _write_save(m: int, idx: int) -> void:
    var f := FileAccess.open(save_path, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify({"money": m, "idx": idx}))

func _read_save() -> Dictionary:
    if not FileAccess.file_exists(save_path):
        return {}
    var f := FileAccess.open(save_path, FileAccess.READ)
    if f == null:
        return {}
    var d: Variant = JSON.parse_string(f.get_as_text())
    return d if d is Dictionary else {}

func _save() -> void:
    if not testing and missions != null:
        _write_save(money, missions.idx + (1 if missions.pause_t > 0.0 else 0))

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_GO_BACK_REQUEST:
        _save()

# ---------------- tests ----------------
func _t(name: String, cond: bool, info: String = "") -> void:
    print("TEST ", "PASS " if cond else "FAIL ", name, "  ", info)
    if not cond:
        fails += 1

func _frames(n: int) -> void:
    for i in n:
        await get_tree().physics_frame

func _autotest() -> void:
    Ctl.auto = true
    await _frames(5)
    _t("chunks bane", world.chunk_mesh.size() > 20, str(world.chunk_mesh.size()))
    _t("imaarat bani", world.buildings.size() >= 8, str(world.buildings.size()))
    await _frames(60)
    _t("player zameen par", player.is_on_floor(), "y=%.2f" % player.global_position.y)
    var p0 := player.global_position
    Ctl.move = Vector2(0, -1)
    await _frames(90)
    Ctl.move = Vector2.ZERO
    _t("player chala", p0.distance_to(player.global_position) > 5.0, "%.1f m" % p0.distance_to(player.global_position))
    var b: Dictionary = world.buildings[0]
    var before := world.count_solid_box(b["x0"], b["z0"], b["w"], b["d"], b["y0"], b["h"])
    _on_explode(Vector3(b["x0"] + b["w"] / 2.0, b["y0"] + 3, b["z0"]))
    var after := world.count_solid_box(b["x0"], b["z0"], b["w"], b["d"], b["y0"], b["h"])
    _t("dhamake se dabbe udte hain", after < before, "%d -> %d" % [before, after])
    await _frames(20)
    var car: Car = cars[0]
    player.global_position = car.global_position + Vector3(2.0, 0.3, 0)
    await _frames(5)
    Ctl.act = true
    await _frames(5)
    _t("gaadi mein baitha", player.in_car != null)
    var c0 := car.global_position
    Ctl.move = Vector2(0, -1)
    await _frames(100)
    Ctl.move = Vector2.ZERO
    _t("gaadi chali", c0.distance_to(car.global_position) > 8.0, "%.1f m" % c0.distance_to(car.global_position))
    Ctl.act = true
    await _frames(5)
    _t("gaadi se utra", player.in_car == null)
    var start_idx := missions.idx
    await _frames(20)
    for step in 80:
        if money >= 900:
            break
        if missions.idx != _last_idx:
            print("  mission idx ", missions.idx, " kind ", missions.kind, " money ", money)
            _last_idx = missions.idx
        if missions.pause_t > 0.0 or missions.targets.is_empty():
            missions.pause_t = minf(missions.pause_t, 0.05) if missions.pause_t > 0.0 else 0.0
            await _frames(6)
            continue
        match missions.kind:
            "deliver":
                player.global_position = missions.targets[0] + Vector3(0, 0.5, 0)
            "demolish":
                var bb: Dictionary = missions.bld
                world.explode(Vector3(bb["x0"] + bb["w"] / 2.0, bb["y0"] + 4, bb["z0"] + bb["d"] / 2.0), 7.5)
            "taxi":
                if player.in_car == null:
                    player.global_position = car.global_position + Vector3(2.0, 0.3, 0)
                    await _frames(3)
                    Ctl.act = true
                    await _frames(3)
                if player.in_car != null:
                    car.global_position = missions.targets[0] + Vector3(0, 0.6, 0)
            "bags":
                if not missions.bags.is_empty():
                    if player.in_car != null:
                        player.in_car.global_position = missions.bags[0].position + Vector3(0, 0.6, 0)
                    else:
                        player.global_position = missions.bags[0].position
        await _frames(8)
    _t("4 missions pure hue (deliver+demolish+taxi+bags)", money >= 900, "idx %d -> %d, paisa $%d" % [start_idx, missions.idx, money])
    # --- v0.2 checks
    _t("awaazein bani", Sfx.boom().data.size() > 10000 and Sfx.engine().data.size() > 5000 and Sfx.siren().data.size() > 10000)
    if player.in_car != null:
        _toggle_car()
    player.global_position = world.spawn_pos
    wanted = 0.0
    police_timer = 0.0
    for pp in police:
        if is_instance_valid(pp):
            pp.queue_free()
    police.clear()
    add_wanted(1.0)
    await _frames(20)
    _t("police aayi", police.size() >= 1, str(police.size()))
    var pc: Police = police[0]
    pc.position = Vector3(49.5, VoxelWorld.PLATEAU + 1.2, world.spawn_pos.z + 22.0)
    pc.rotation.y = 0.0
    pc.spd = 0.0
    player.hp = 100.0
    var d0 := pc.global_position.distance_to(player.global_position)
    await _frames(150)
    var d1 := pc.global_position.distance_to(player.global_position)
    _t("police ne peecha kiya", d1 < d0 - 8.0, "%.1f -> %.1f m" % [d0, d1])
    await _frames(60)
    _t("police ne chot maari", player.hp < 100.0, "hp %d" % int(player.hp))
    _on_explode(pc.global_position)
    _t("police udi", not police.has(pc))
    var w1 := wanted
    save_path = "user://test_save.json"
    _write_save(777, 5)
    var sd := _read_save()
    _t("save/load", int(sd.get("money", 0)) == 777 and int(sd.get("idx", 0)) == 5)
    print("AUTOTEST ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
    get_tree().quit(0 if fails == 0 else 1)

func _shot(path: String) -> void:
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(path)
    print("SHOT ", path)

func _shots(dir_s: String) -> void:
    missions.pause_t = 0.2
    await _frames(40)
    player.yaw = 0.5
    await _frames(10)
    await _shot(dir_s + "/s1_spawn.png")
    player.yaw = 3.3
    player.pitch = -0.2
    await _frames(10)
    await _shot(dir_s + "/s2_city.png")
    # sabse paas wali imaarat par saaf nazar se dhamaka
    var sp := world.spawn_pos
    var best: Dictionary = world.buildings[0]
    var bdist := 1e9
    for bb in world.buildings:
        var cc := Vector3(bb["x0"] + bb["w"] / 2.0, 0, bb["z0"] + bb["d"] / 2.0)
        var dd := Vector2(cc.x - sp.x, cc.z - sp.z).length()
        if dd < bdist and bb["h"] >= 9:
            bdist = dd
            best = bb
    var bc := Vector3(best["x0"] + best["w"] / 2.0, best["y0"] + 5, best["z0"] + best["d"] / 2.0)
    var eye := Vector3(sp.x, 12.5, sp.z)
    var dir := (Vector3(bc.x, 12.5, bc.z) - eye).normalized()
    player.global_position = Vector3(sp.x, sp.y, sp.z)
    player.face_dir(dir)
    await _frames(30)
    var hit := eye
    for i in 160:
        hit = eye + dir * (i * 0.25)
        if world.solid_at(hit):
            break
    var hp0 := hit - dir * 0.4 + Vector3(0, 1.5, 0)
    _on_explode(hp0)
    await get_tree().create_timer(0.12).timeout
    await _shot(dir_s + "/s3_boom.png")
    await get_tree().create_timer(0.9).timeout
    _on_explode(hp0 + dir * 4.0 + Vector3(0, 3, 0))
    await get_tree().create_timer(0.5).timeout
    await _shot(dir_s + "/s4_debris.png")
    var car: Car = cars[0]
    player.global_position = car.global_position + Vector3(2.0, 0.3, 0)
    await _frames(5)
    Ctl.act = true
    await _frames(5)
    car.rotation.y = 0.4
    player.yaw = 0.4
    Ctl.move = Vector2(0, -1)
    await _frames(40)
    await _shot(dir_s + "/s5_car.png")
    Ctl.move = Vector2.ZERO
    _toggle_car()
    player.global_position = world.spawn_pos
    player.face_dir(Vector3(0, 0, 1))
    wanted = 0.0
    add_wanted(2.0)
    police_timer = 0.0
    await _frames(15)
    for pp in police:
        pp.position = Vector3(49.5, 11.2, world.spawn_pos.z + 14.0)
        break
    await _frames(25)
    await _shot(dir_s + "/s7_police.png")
    player.pitch = 0.35
    await _frames(5)
    await _shot(dir_s + "/s8_sky.png")
    player.pitch = -0.25
    daytime = 0.78
    await _frames(5)
    await _shot(dir_s + "/s6_night.png")
    get_tree().quit()
