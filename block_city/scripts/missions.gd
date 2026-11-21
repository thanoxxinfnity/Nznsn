class_name Missions
extends Node3D
# GTA-style tasks: delivery, demolition (BLAST), taxi, paisa-thaile.

signal reward(amount: int)
signal toast(msg: String)
signal pickup

var world: VoxelWorld
var player: Player
var idx := -1
var kind := ""
var title := ""
var text := ""
var targets: Array = []
var stage := 0
var beam: MeshInstance3D
var bags: Array = []
var bld := {}
var init_count := 1
var pause_t := 1.0
var rng := RandomNumberGenerator.new()
var reward_amt := 0

func _ready() -> void:
    rng.randomize()
    beam = MeshInstance3D.new()
    var cm := CylinderMesh.new()
    cm.top_radius = 0.9
    cm.bottom_radius = 0.9
    cm.height = 60.0
    beam.mesh = cm
    var m := StandardMaterial3D.new()
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.albedo_color = Color(1.0, 0.85, 0.1, 0.35)
    beam.material_override = m
    beam.visible = false
    add_child(beam)

func ppos() -> Vector3:
    return player.in_car.global_position if player.in_car else player.global_position

func pick_road(min_d: float, max_d: float) -> Vector3:
    var p := ppos()
    var best := Vector3.ZERO
    for i in 60:
        var c: Vector3 = world.road_points[rng.randi() % world.road_points.size()]
        var d := Vector2(c.x - p.x, c.z - p.z).length()
        if d >= min_d and d <= max_d:
            return c
        best = c
    return best

func set_beam(p: Vector3, c: Color) -> void:
    beam.visible = true
    beam.position = p + Vector3(0, 28, 0)
    (beam.material_override as StandardMaterial3D).albedo_color = Color(c.r, c.g, c.b, 0.35)

func start_next() -> void:
    idx += 1
    stage = 0
    for b in bags:
        if is_instance_valid(b):
            b.queue_free()
    bags.clear()
    var kinds := ["deliver", "demolish", "taxi", "bags"]
    kind = kinds[idx % 4]
    match kind:
        "deliver":
            title = "MISSION: Package delivery"
            reward_amt = 150
            targets = [pick_road(14.0, 28.0)]
            set_beam(targets[0], Color(1.0, 0.85, 0.1))
        "demolish":
            title = "MISSION: Imarat udao (BLAST)"
            reward_amt = 300
            var cands: Array = []
            for b in world.buildings:
                var c := Vector3(b["x0"] + b["w"] / 2.0, 0, b["z0"] + b["d"] / 2.0)
                if Vector2(c.x - ppos().x, c.z - ppos().z).length() > 14.0 and b["h"] >= 8:
                    cands.append(b)
            if cands.is_empty():
                cands = world.buildings
            bld = cands[rng.randi() % cands.size()]
            init_count = maxi(1, world.count_solid_box(bld["x0"], bld["z0"], bld["w"], bld["d"], bld["y0"], bld["h"]))
            var cp := Vector3(bld["x0"] + bld["w"] / 2.0, bld["y0"] + bld["h"], bld["z0"] + bld["d"] / 2.0)
            targets = [Vector3(cp.x, bld["y0"], cp.z)]
            set_beam(Vector3(cp.x, bld["y0"] + bld["h"] * 0.3, cp.z), Color(1.0, 0.25, 0.1))
        "taxi":
            title = "MISSION: Taxi run"
            reward_amt = 200
            targets = [pick_road(34.0, 70.0)]
            set_beam(targets[0], Color(0.2, 0.7, 1.0))
        "bags":
            title = "MISSION: Paisa-thaile jama karo"
            reward_amt = 250
            targets = []
            for i in 5:
                var p := pick_road(6.0, 60.0) + Vector3(rng.randf_range(-3, 3), 0.55, 0)
                var bag := Node3D.new()
                Blocky.box(bag, Vector3(0.55, 0.55, 0.55), Vector3.ZERO, Color(1.0, 0.8, 0.1))
                Blocky.box(bag, Vector3(0.25, 0.12, 0.25), Vector3(0, 0.34, 0), Color(0.4, 0.3, 0.05))
                bag.position = Vector3(p.x, world.ground_y(int(p.x), int(p.z)) + 0.6, p.z)
                add_child(bag)
                bags.append(bag)
                targets.append(bag.position)
            beam.visible = false
    toast.emit(title)

func _process(delta: float) -> void:
    if world == null or player == null:
        return
    if pause_t > 0.0:
        pause_t -= delta
        if pause_t <= 0.0:
            start_next()
        return
    var p := ppos()
    var done := false
    match kind:
        "deliver":
            var d := Vector2(targets[0].x - p.x, targets[0].z - p.z).length()
            text = ("Package uthao: %d m" if stage == 0 else "Package pahuncha do: %d m") % int(d)
            if d < 3.2:
                if stage == 0:
                    stage = 1
                    targets = [pick_road(40.0, 80.0)]
                    set_beam(targets[0], Color(0.3, 1.0, 0.4))
                    toast.emit("Package mil gaya! Manzil tak jao")
                else:
                    done = true
        "demolish":
            var cnt := world.count_solid_box(bld["x0"], bld["z0"], bld["w"], bld["d"], bld["y0"], bld["h"])
            var prog := clampf(1.0 - float(cnt) / float(init_count), 0.0, 1.0)
            text = "Imarat ko BLAST se udao: %d%% (45%% tak)" % int(prog * 100.0)
            done = prog >= 0.45
        "taxi":
            var d2 := Vector2(targets[0].x - p.x, targets[0].z - p.z).length()
            if player.in_car == null:
                text = "Gaadi mein baitho (CAR button), phir manzil tak chalao"
            else:
                text = "Manzil tak chalao: %d m" % int(d2)
                done = d2 < 4.5
        "bags":
            for b in bags.duplicate():
                if is_instance_valid(b) and Vector2(b.position.x - p.x, b.position.z - p.z).length() < 1.9 and absf(b.position.y - p.y) < 3.5:
                    targets.erase(b.position)
                    bags.erase(b)
                    b.queue_free()
                    toast.emit("+ thaila!")
                    pickup.emit()
            text = "Paisa-thaile baaki: %d / 5" % bags.size()
            done = bags.is_empty()
    if kind == "bags":
        for b in bags:
            if is_instance_valid(b):
                b.rotate_y(delta * 2.0)
    if done:
        reward.emit(reward_amt)
        toast.emit("MISSION PURA!  +$%d" % reward_amt)
        beam.visible = false
        text = ""
        targets = []
        pause_t = 3.0
