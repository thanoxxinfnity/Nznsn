class_name Player
extends CharacterBody3D
# Veer: dabba-insaan. Camera third-person. Touch/keyboard Ctl se.

signal bomb_thrown(pos: Vector3, vel: Vector3)
signal died
signal jumped
signal got_hurt

const GRAV := 24.0
var world: VoxelWorld
var rig: Node3D
var parts: Dictionary
var yaw := 0.0
var pitch := -0.32
var hp := 100.0
var since_hurt := 99.0
var bomb_cd := 0.0
var walk_t := 0.0
var in_car: Node3D = null
var shake := 0.0
var cam_pivot: Node3D
var arm: SpringArm3D
var cam: Camera3D

func _ready() -> void:
    var cs := CollisionShape3D.new()
    var cap := CapsuleShape3D.new()
    cap.radius = 0.34
    cap.height = 1.76
    cs.shape = cap
    cs.position.y = 0.88
    add_child(cs)
    floor_snap_length = 0.35
    rig = Node3D.new()
    rig.rotation.y = PI
    add_child(rig)
    parts = Blocky.human(rig, Color(0.93, 0.5, 0.15), Color(0.2, 0.3, 0.7), Color(0.9, 0.7, 0.52), Color(0.25, 0.15, 0.08))
    cam_pivot = Node3D.new()
    cam_pivot.top_level = true
    add_child(cam_pivot)
    arm = SpringArm3D.new()
    arm.spring_length = 6.5
    arm.margin = 0.25
    arm.add_excluded_object(get_rid())
    cam_pivot.add_child(arm)
    cam = Camera3D.new()
    cam.fov = 72
    cam.far = 220
    cam.current = true
    arm.add_child(cam)

func hurt(a: float) -> void:
    hp -= a
    since_hurt = 0.0
    got_hurt.emit()
    if hp <= 0.0:
        hp = 0.0
        died.emit()

func face_dir(d: Vector3) -> void:
    yaw = atan2(-d.x, -d.z)
    pitch = -0.2

func fwd_dir() -> Vector3:
    return Vector3(-sin(yaw), 0, -cos(yaw))

func _physics_process(delta: float) -> void:
    bomb_cd -= delta
    since_hurt += delta
    if hp > 0.0 and since_hurt > 5.0:
        hp = minf(100.0, hp + 6.0 * delta)
    # camera ghumao
    yaw -= Ctl.look.x * 0.0045
    pitch = clampf(pitch - Ctl.look.y * 0.0045, -1.25, 0.45)
    Ctl.look = Vector2.ZERO
    if Ctl.bomb:
        Ctl.bomb = false
        if bomb_cd <= 0.0:
            bomb_cd = 0.55
            var o := (in_car.global_position if in_car else global_position) + Vector3(0, 1.5, 0)
            var v := fwd_dir() * 17.0 + Vector3(0, 6.5 + pitch * -6.0, 0)
            bomb_thrown.emit(o, v)
    if in_car != null:
        return
    var mv: Vector2 = Ctl.move
    var dir := Vector3.ZERO
    var sp := 0.0
    if mv.length() > 0.12:
        dir = (Basis(Vector3.UP, yaw) * Vector3(mv.x, 0, mv.y)).normalized()
        sp = 7.2 if mv.length() > 0.86 else 4.4 * mv.length() / 0.86
    velocity.x = dir.x * sp
    velocity.z = dir.z * sp
    if not is_on_floor():
        velocity.y -= GRAV * delta
    else:
        velocity.y = -1.0
        if Ctl.jump:
            velocity.y = 8.6
            jumped.emit()
    Ctl.jump = false
    move_and_slide()
    if is_on_floor() and is_on_wall() and sp > 0.5 and velocity.y <= 0.0:
        velocity.y = 7.6   # 1 dabba chadhne ke liye auto-hop
    if dir != Vector3.ZERO:
        rig.rotation.y = lerp_angle(rig.rotation.y, atan2(dir.x, dir.z), minf(1.0, 14.0 * delta))
    walk_t += delta * sp * 1.7
    Blocky.animate(parts, sp, walk_t)
    position.x = clampf(position.x, 1.5, VoxelWorld.W - 1.5)
    position.z = clampf(position.z, 1.5, VoxelWorld.D - 1.5)
    if position.y < -8.0:
        hurt(999.0)

func _process(delta: float) -> void:
    var follow: Vector3 = (in_car.global_position if in_car else global_position) + Vector3(0, 1.6, 0)
    arm.spring_length = lerpf(arm.spring_length, 9.5 if in_car else 6.5, minf(1.0, 4.0 * delta))
    cam_pivot.global_position = follow
    cam_pivot.rotation = Vector3(pitch, yaw, 0)
    shake = maxf(0.0, shake - 2.2 * delta)
    cam.h_offset = randf_range(-1.0, 1.0) * shake * 0.5
    cam.v_offset = randf_range(-1.0, 1.0) * shake * 0.5
