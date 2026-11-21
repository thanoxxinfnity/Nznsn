class_name Car
extends CharacterBody3D
# Dabba-gaadi (aage = -Z). Driver andar ho to Ctl.move se chalti hai.

const GRAV := 24.0
var driver: Node3D = null
var spd := 0.0
var home := Vector3.ZERO
var color := Color(0.8, 0.15, 0.15)
var dead_t := 0.0
var body_root: Node3D
var ai := false
var ai_thr := 0.0
var ai_steer := 0.0

func setup(c: Color, pos: Vector3, yaw: float) -> void:
    color = c
    home = pos
    position = pos
    rotation.y = yaw

func _ready() -> void:
    var cs := CollisionShape3D.new()
    var bs := BoxShape3D.new()
    bs.size = Vector3(1.8, 1.1, 3.5)
    cs.shape = bs
    cs.position.y = 0.75
    add_child(cs)
    body_root = Node3D.new()
    add_child(body_root)
    Blocky.box(body_root, Vector3(1.8, 0.65, 3.5), Vector3(0, 0.62, 0), color)
    Blocky.box(body_root, Vector3(1.5, 0.55, 1.7), Vector3(0, 1.17, 0.25), color.lightened(0.15))
    Blocky.box(body_root, Vector3(1.44, 0.42, 0.05), Vector3(0, 1.2, -0.62), Color(0.6, 0.85, 0.95))
    Blocky.box(body_root, Vector3(0.35, 0.2, 0.06), Vector3(-0.6, 0.7, -1.76), Color(1, 0.95, 0.6))
    Blocky.box(body_root, Vector3(0.35, 0.2, 0.06), Vector3(0.6, 0.7, -1.76), Color(1, 0.95, 0.6))
    for wx in [-0.95, 0.95]:
        for wz in [-1.1, 1.1]:
            Blocky.box(body_root, Vector3(0.22, 0.55, 0.55), Vector3(wx, 0.3, wz), Color(0.08, 0.08, 0.08))

func _physics_process(delta: float) -> void:
    if dead_t > 0.0:
        return
    var thr := 0.0
    var steer := 0.0
    if ai:
        thr = ai_thr
        steer = ai_steer
    elif driver != null:
        thr = -Ctl.move.y
        steer = Ctl.move.x
    var target := thr * (17.0 if thr > 0.0 else 6.0)
    spd = move_toward(spd, target, (14.0 if absf(thr) > 0.05 else 9.0) * delta)
    rotation.y -= steer * 1.9 * clampf(spd / 5.0, -1.0, 1.0) * delta
    var f := -global_transform.basis.z
    velocity.x = f.x * spd
    velocity.z = f.z * spd
    if not is_on_floor():
        velocity.y -= GRAV * delta
    else:
        velocity.y = -1.0
    move_and_slide()
    if is_on_floor() and is_on_wall() and absf(spd) > 2.5 and velocity.y <= 0.0:
        velocity.y = 7.2
    position.x = clampf(position.x, 2.0, VoxelWorld.W - 2.0)
    position.z = clampf(position.z, 2.0, VoxelWorld.D - 2.0)
    if position.y < -8.0:
        position = home
        spd = 0.0
