extends CharacterBody3D
# Veer: third-person player. WASD chalo, Shift daudo, Space kudo, mouse se camera.

const SPEED := 6.0
const RUN := 10.0
const JUMP := 6.5

var yaw := 0.0
var pitch := -0.2
var model: Node3D
var pivot: Node3D
var cam: Camera3D
var t := 0.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _mat(c: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = 0.85
    return m

func _part(parent: Node3D, mesh: Mesh, pos: Vector3, c: Color) -> void:
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = _mat(c)
    mi.position = pos
    parent.add_child(mi)

func _ready() -> void:
    var cs := CollisionShape3D.new()
    var cap := CapsuleShape3D.new()
    cap.radius = 0.4
    cap.height = 1.8
    cs.shape = cap
    cs.position.y = 0.9
    add_child(cs)

    model = Node3D.new()
    add_child(model)
    var body := CapsuleMesh.new(); body.radius = 0.34; body.height = 1.2
    _part(model, body, Vector3(0, 0.75, 0), Color(0.75, 0.25, 0.15))          # kurta
    var head := SphereMesh.new(); head.radius = 0.24; head.height = 0.48
    _part(model, head, Vector3(0, 1.6, 0), Color(0.85, 0.62, 0.45))           # sar
    var hat := CylinderMesh.new(); hat.top_radius = 0.0; hat.bottom_radius = 0.34; hat.height = 0.3
    _part(model, hat, Vector3(0, 1.9, 0), Color(0.45, 0.3, 0.15))             # topi
    var pack := BoxMesh.new(); pack.size = Vector3(0.4, 0.5, 0.2)
    _part(model, pack, Vector3(0, 0.95, -0.34), Color(0.35, 0.25, 0.12))      # peeth ka jhola
    var nose := BoxMesh.new(); nose.size = Vector3(0.1, 0.1, 0.16)
    _part(model, nose, Vector3(0, 1.58, 0.26), Color(0.85, 0.62, 0.45))       # aage ki disha

    pivot = Node3D.new()
    pivot.position.y = 1.6
    add_child(pivot)
    var arm := SpringArm3D.new()
    arm.spring_length = 5.0
    arm.shape = SphereShape3D.new()
    (arm.shape as SphereShape3D).radius = 0.3
    arm.add_excluded_object(get_rid())
    pivot.add_child(arm)
    cam = Camera3D.new()
    cam.current = true
    cam.fov = 70
    arm.add_child(cam)
    _apply_look()
    if DisplayServer.get_name() != "headless":
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _apply_look() -> void:
    pivot.rotation = Vector3(pitch, yaw, 0)

func face(dir: Vector3) -> void:
    yaw = atan2(-dir.x, -dir.z)
    pitch = -0.25
    _apply_look()

func _unhandled_input(e: InputEvent) -> void:
    if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        yaw -= e.relative.x * 0.0025
        pitch = clamp(pitch - e.relative.y * 0.0025, -1.2, 0.6)
        _apply_look()
    elif e is InputEventMouseButton and e.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    elif e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    elif Input.is_action_just_pressed("jump"):
        velocity.y = JUMP
    var iv := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var dir := Vector3.ZERO
    if iv != Vector2.ZERO:
        dir = (Basis(Vector3.UP, yaw) * Vector3(iv.x, 0, iv.y)).normalized()
    var sp := RUN if Input.is_key_pressed(KEY_SHIFT) else SPEED
    velocity.x = dir.x * sp
    velocity.z = dir.z * sp
    if dir != Vector3.ZERO:
        model.rotation.y = lerp_angle(model.rotation.y, atan2(dir.x, dir.z), 12.0 * delta)
        t += delta * sp
        model.position.y = abs(sin(t * 1.4)) * 0.08
    else:
        model.position.y = lerpf(model.position.y, 0.0, 10.0 * delta)
    move_and_slide()
