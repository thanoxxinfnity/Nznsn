class_name Player
extends CharacterBody3D
# Pehle-person khiladi (Neha): chalna/daudna/jhukna, torch (battery), dekho-aur-dabao, chhupna, darr (fear).
signal died(cause: String)
signal item_changed

const WALK := 2.3
const RUN := 4.2
const CROUCH_SPEED := 1.15
const EYE := 1.6
const EYE_CROUCH := 1.05

var hud                   # Hud
var level                 # Level (surface/lit queries)
var cam: Camera3D
var head: Node3D
var torch: SpotLight3D
var hands: Node3D
var yaw := 0.0
var pitch := 0.0
var torch_on := true
var battery := 100.0
var stamina := 1.0
var items := {}
var fear := 0.0
var hidden := false
var frozen := false
var dead := false
var crouching := false
var running := false
var look_target = null    # Node3D: marne ke samay / cutscene mein dekhne ke liye
var inv_mouse := true

var _shape: CollisionShape3D
var _cap: CapsuleShape3D
var _eye := EYE
var _bob := 0.0
var _step := 0.0
var _hide_spot = null
var _hide_prev := Vector3.ZERO
var _foot: AudioStreamPlayer
var _torch_flick := 0.0
var _target = null
var _breath_t := 0.0

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 16
	_cap = CapsuleShape3D.new()
	_cap.radius = 0.32
	_cap.height = 1.7
	_shape = CollisionShape3D.new()
	_shape.shape = _cap
	_shape.position.y = 0.85
	add_child(_shape)
	head = Node3D.new()
	head.position.y = EYE
	add_child(head)
	cam = Camera3D.new()
	cam.fov = 76.0
	cam.near = 0.04
	cam.far = 90.0
	head.add_child(cam)
	torch = SpotLight3D.new()
	torch.spot_range = 22.0
	torch.spot_angle = 34.0
	torch.spot_angle_attenuation = 1.3
	torch.spot_attenuation = 0.9
	torch.light_energy = 9.0
	torch.light_cull_mask = 1
	torch.light_color = Color(1.0, 0.93, 0.78)
	torch.shadow_enabled = true
	torch.top_level = true
	add_child(torch)
	hands = Node3D.new()
	cam.add_child(hands)
	# haath sirf halki fill-light se roshan (torch usse chamka na de)
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.9, 0.85, 0.8)
	fill.light_energy = 0.9
	fill.omni_range = 1.6
	fill.light_cull_mask = 2
	fill.position = Vector3(0.0, 0.1, 0.2)
	cam.add_child(fill)
	# zameen par thodi si aas-paas ki roshni (bilkul andhera na ho)
	var amb := OmniLight3D.new()
	amb.light_color = Color(0.7, 0.75, 1.0)
	amb.light_energy = 0.28
	amb.omni_range = 4.0
	amb.light_cull_mask = 1
	amb.position = Vector3(0.0, 0.2, 0.0)
	cam.add_child(amb)
	_foot = AudioStreamPlayer.new()
	_foot.volume_db = -9.0
	add_child(_foot)

func set_view(y: float, p := 0.0) -> void:
	yaw = y
	pitch = p
	rotation.y = yaw
	head.rotation.x = pitch

func _unhandled_input(e: InputEvent) -> void:
	if dead or frozen and not hidden:
		return
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Ctl.look += (e as InputEventMouseMotion).relative * 0.6

func add_item(id: String, n := 1) -> void:
	items[id] = items.get(id, 0) + n
	item_changed.emit()

func has_item(id: String) -> bool:
	return items.get(id, 0) > 0

func use_item(id: String) -> bool:
	if has_item(id):
		items[id] -= 1
		item_changed.emit()
		return true
	return false

func add_battery(v: float) -> void:
	battery = minf(100.0, battery + v)
	if hud:
		hud.toast("बैटरी मिली: +%d%%" % int(v))

func add_fear(v: float) -> void:
	fear = clampf(fear + v, 0.0, 1.0)

func torch_cone_contains(p: Vector3) -> bool:
	if not torch_on or battery <= 0.0 or not torch.visible:
		return false
	var to := p - torch.global_position
	var d := to.length()
	if d > torch.spot_range or d < 0.01:
		return d < 0.01
	var fwd := -torch.global_basis.z
	return fwd.dot(to / d) > cos(deg_to_rad(torch.spot_angle * 0.85))

func _input_vec() -> Vector2:
	var v := Ctl.move
	if not Ctl.auto:
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			v.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			v.y += 1.0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			v.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			v.x += 1.0
	return v.limit_length(1.0)

func _physics_process(delta: float) -> void:
	_update_torch(delta)
	if dead:
		_face_target(delta, 6.0)
		velocity = Vector3.ZERO
		return
	# dekhna
	var lk := Ctl.look
	Ctl.look = Vector2.ZERO
	if not frozen or hidden:
		var sens := 0.0042
		yaw -= lk.x * sens
		pitch = clampf(pitch - lk.y * sens, deg_to_rad(-80), deg_to_rad(80))
	if hidden and _hide_spot:
		var base: float = _hide_spot.face_yaw
		yaw = clampf(yaw, base - deg_to_rad(38), base + deg_to_rad(38))
		pitch = clampf(pitch, deg_to_rad(-22), deg_to_rad(22))
	if look_target:
		_face_target(delta, 4.0)
	rotation.y = yaw
	head.rotation.x = pitch
	if Ctl.take_torch() and not frozen:
		_toggle_torch()
	if hidden:
		velocity = Vector3.ZERO
		_hide_tick()
		return
	if frozen:
		velocity = Vector3.ZERO
		_cam_fx(delta, 0.0)
		return
	# chalna
	var iv := _input_vec()
	if not Ctl.auto:
		Ctl.crouch = Ctl.crouch if not Input.is_key_pressed(KEY_C) else true
	crouching = Ctl.crouch or (not Ctl.auto and Input.is_key_pressed(KEY_C))
	var want_run := (Ctl.run or (not Ctl.auto and Input.is_key_pressed(KEY_SHIFT))) and iv.length() > 0.1 and not crouching and stamina > 0.05
	running = want_run
	var spd := CROUCH_SPEED if crouching else (RUN if running else WALK)
	var dir := (global_basis * Vector3(iv.x, 0, iv.y)).normalized() * iv.length()
	var tv := dir * spd
	velocity.x = lerpf(velocity.x, tv.x, 1.0 - exp(-12.0 * delta))
	velocity.z = lerpf(velocity.z, tv.z, 1.0 - exp(-12.0 * delta))
	velocity.y = (velocity.y - 18.0 * delta) if not is_on_floor() else -0.5
	move_and_slide()
	# stamina
	if running:
		stamina = maxf(0.0, stamina - delta / 6.0)
		add_fear(0.0)
	else:
		stamina = minf(1.0, stamina + delta / (3.5 if iv.length() < 0.1 else 7.0))
	# jhukna
	var tgt_eye := EYE_CROUCH if crouching else EYE
	_eye = lerpf(_eye, tgt_eye, 1.0 - exp(-9.0 * delta))
	_cap.height = lerpf(_cap.height, 1.1 if crouching else 1.7, 1.0 - exp(-9.0 * delta))
	_shape.position.y = _cap.height / 2.0
	var hs := Vector2(velocity.x, velocity.z).length()
	_cam_fx(delta, hs)
	_footsteps(delta, hs)
	_interact_tick()
	fear = maxf(0.0, fear - 0.1 * delta)

func _cam_fx(delta: float, hs: float) -> void:
	_bob += hs * delta * 1.55
	var amp := 0.028 if not running else 0.05
	var by := sin(_bob * 2.0) * amp * clampf(hs / WALK, 0.0, 1.5)
	var bx := cos(_bob) * amp * 0.7 * clampf(hs / WALK, 0.0, 1.5)
	var shake := fear * 0.012
	head.position = Vector3(bx + randf_range(-shake, shake), _eye + by + randf_range(-shake, shake), 0.0)
	cam.rotation.z = lerp_angle(cam.rotation.z, bx * 0.35 + (randf_range(-1, 1) * fear * 0.01), 0.2)
	# haath/torch halka sway
	hands.position = hands.position.lerp(Vector3(bx * 0.6, by * 0.8, 0.0), 1.0 - exp(-10.0 * delta))

func _footsteps(delta: float, hs: float) -> void:
	if hs < 0.4 or not is_on_floor():
		return
	_step += hs * delta
	var stride := 1.5 if not running else 1.25
	if crouching:
		stride = 1.1
	if _step > stride:
		_step = 0.0
		var snd := "footstep"
		if level and level.has_method("surface_at") and level.surface_at(global_position) == "metal":
			snd = "footstep_metal"
		_foot.stream = Sfx.get_sound(snd)
		_foot.pitch_scale = randf_range(0.85, 1.15)
		_foot.volume_db = -14.0 if crouching else (-6.0 if running else -10.0)
		_foot.play()

func _toggle_torch() -> void:
	if battery <= 0.0:
		return
	torch_on = not torch_on
	Aud.play2d(self, "click", -6.0)

func _update_torch(delta: float) -> void:
	# torch camera ke peeche halka lag ke saath
	var gb := cam.global_basis
	torch.global_position = cam.global_position + gb * Vector3(0.12, -0.12, -0.2)
	torch.global_basis = torch.global_basis.slerp(gb, 1.0 - exp(-14.0 * delta)) if torch.global_basis.is_finite() else gb
	if torch_on and battery > 0.0 and not dead:
		battery = maxf(0.0, battery - 0.3 * delta)
		if battery <= 0.0:
			torch_on = false
			if hud:
				hud.toast("टॉर्च की बैटरी ख़त्म!")
	torch.visible = torch_on and battery > 0.0
	var e := 9.0
	if battery < 15.0 and torch_on:
		_torch_flick += delta
		e *= 0.35 + 0.65 * (1.0 if sin(_torch_flick * 37.0) * sin(_torch_flick * 11.0) > -0.2 else 0.0)
	torch.light_energy = e if not has_meta("torch_e") else float(get_meta("torch_e"))

func _interact_tick() -> void:
	var from := cam.global_position
	var fwd := -cam.global_basis.z
	var space := get_world_3d().direct_space_state
	var qw := PhysicsRayQueryParameters3D.create(from, from + fwd * 2.5, 1 | 16)
	var hw := space.intersect_ray(qw)
	var dmax := 2.5 if hw.is_empty() else from.distance_to(hw.position)
	var qi := PhysicsRayQueryParameters3D.create(from, from + fwd * 2.5, 8)
	var hi := space.intersect_ray(qi)
	_target = null
	if not hi.is_empty() and from.distance_to(hi.position) <= dmax + 0.1:
		_target = hi.collider
	var pr := ""
	if _target and _target.has_method("get_prompt"):
		pr = _target.get_prompt(self)
	if hud:
		hud.set_prompt(pr)
	if Ctl.take_use() or (not Ctl.auto and Input.is_action_just_pressed("ui_accept")):
		if _target and pr != "":
			_target.interact(self)

func hide_in(spot) -> void:
	_hide_spot = spot
	_hide_prev = global_position
	hidden = true
	frozen = true
	global_position = spot.global_position + Vector3(0, 0.05, 0)
	yaw = spot.face_yaw
	pitch = 0.0
	velocity = Vector3.ZERO
	_shape.disabled = true
	if hud:
		hud.set_hidden(true)
	Aud.play2d(self, "door_creak", -10.0, 1.3)

func leave_hide() -> void:
	if not hidden:
		return
	hidden = false
	frozen = false
	_shape.disabled = false
	global_position = _hide_prev
	if hud:
		hud.set_hidden(false)
	_hide_spot = null
	Aud.play2d(self, "door_creak", -10.0, 1.1)

func _hide_tick() -> void:
	if hud:
		hud.set_prompt("बाहर निकलो")
	if Ctl.take_use():
		leave_hide()

func _face_target(delta: float, rate: float) -> void:
	if look_target == null:
		return
	var to: Vector3 = look_target.global_position + Vector3(0, 0.9, 0) - cam.global_position
	var ty := atan2(-to.x, -to.z)
	var tp := atan2(to.y, Vector2(to.x, to.z).length())
	yaw = lerp_angle(yaw, ty, 1.0 - exp(-rate * delta))
	pitch = lerpf(pitch, clampf(tp, -1.2, 1.2), 1.0 - exp(-rate * delta))
	rotation.y = yaw
	head.rotation.x = pitch

func kill(by: Node3D, cause := "gudiya") -> void:
	if dead:
		return
	dead = true
	frozen = true
	look_target = by
	hidden = false
	_shape.disabled = true
	Aud.play2d(self, "scream", -2.0)
	Aud.play2d(self, "stinger", 0.0)
	if hud:
		hud.set_hidden(false)
		hud.set_prompt("")
	died.emit(cause)

func get_look_dir() -> Vector3:
	return -cam.global_basis.z

func revive() -> void:
	dead = false
	frozen = false
	hidden = false
	look_target = null
	_shape.disabled = false
	fear = 0.0
