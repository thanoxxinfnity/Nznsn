class_name Police
extends Car
# Police gaadi: wanted level hone par player ka peecha karti hai.

signal hit(dmg: float)
var target_pos := Vector3.ZERO
var bar_a: MeshInstance3D
var bar_b: MeshInstance3D
var t := 0.0
var despawn_t := 0.0

func _ready() -> void:
    ai = true
    color = Color(0.92, 0.92, 0.96)
    super._ready()
    bar_a = Blocky.box(body_root, Vector3(0.5, 0.18, 0.4), Vector3(-0.35, 1.52, 0.25), Color(0.1, 0.3, 1.0))
    bar_b = Blocky.box(body_root, Vector3(0.5, 0.18, 0.4), Vector3(0.35, 1.52, 0.25), Color(1.0, 0.1, 0.1))
    Blocky.box(body_root, Vector3(1.82, 0.2, 1.2), Vector3(0, 0.62, 1.0), Color(0.1, 0.1, 0.2))

func _physics_process(delta: float) -> void:
    t += delta
    bar_a.visible = int(t * 6.0) % 2 == 0
    bar_b.visible = not bar_a.visible
    var to := target_pos - global_position
    to.y = 0.0
    var dist := to.length()
    var f := -global_transform.basis.z
    f.y = 0.0
    f = f.normalized()
    if dist > 0.01:
        to = to / dist
    var cross_y := f.z * to.x - f.x * to.z
    var dot := f.x * to.x + f.z * to.z
    ai_steer = -clampf(cross_y * 3.0, -1.0, 1.0)
    if dot < 0.0:
        ai_steer = -1.0 if cross_y >= 0.0 else 1.0
    ai_thr = 1.0 if dist > 7.0 else 0.35
    if dist < 3.8:
        hit.emit(16.0 * delta)
    super._physics_process(delta)
