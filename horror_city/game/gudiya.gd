class_name Gudiya
extends CharacterBody3D
# Gudiya: jab tum use DEKH rahe ho (roshni mein, saamne) wo jam jaati hai; nazar hatte hi paas aati hai.
# Chhupoge to dhoondhti hai. Lori sirf tab bajti hai jab wo chal rahi ho.
enum S { DORMANT, STALK, SEARCH, KILL }
const MODEL := "res://assets/rigged/M01_Gudiya.glb"

var state := S.DORMANT
var player: Player
var level             # Level
var model: Node3D
var anim: AnimationPlayer
var agent: NavigationAgent3D
var walk_speed := 2.7
var seen := false
var _lull: AudioStreamPlayer3D
var _t := 0.0
var _repath := 0.0
var _cur := ""
var _step_t := 0.0
var _phase := 0
var _wait := 0.0
var _wander := Vector3.ZERO
var _last_known := Vector3.ZERO
var _whisper_t := 5.0
var _stuck_t := 0.0
var _last_pos := Vector3.ZERO

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.2
	cs.shape = cap
	cs.position.y = 0.6
	add_child(cs)
	model = (load(MODEL) as PackedScene).instantiate()
	model.rotation_degrees.y = 180.0   # model ka saamna +Z hai; hamara aage -Z
	add_child(model)
	var aps := model.find_children("*", "AnimationPlayer", true, false)
	if aps.size() > 0:
		anim = aps[0]
		for n in ["ZombieIdle", "ZombieWalk", "ZombieRunning", "BreathingIdle", "ZombieCrawl", "Crawling"]:
			if anim.has_animation(n):
				anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	agent = NavigationAgent3D.new()
	agent.path_desired_distance = 0.5
	agent.target_desired_distance = 0.8
	agent.radius = 0.35
	agent.avoidance_enabled = false
	add_child(agent)
	_lull = Aud.loop3d(self, global_position, "music_box", -4.0, 22.0)
	_lull.position = Vector3(0, 1.0, 0)
	_lull.stream_paused = true
	_play("ZombieIdle", 1.0)
	_last_pos = global_position

func activate() -> void:
	if state == S.DORMANT:
		state = S.STALK

func _play(n: String, spd: float) -> void:
	if anim == null:
		return
	if _cur != n and anim.has_animation(n):
		anim.play(n, 0.25)
		_cur = n
	anim.speed_scale = spd

func _compute_seen() -> bool:
	if player == null or player.hidden or player.dead:
		return false
	var cam: Camera3D = player.cam
	var p := global_position + Vector3(0, 0.6, 0)
	if not cam.is_position_in_frustum(p):
		return false
	var from := cam.global_position
	var d := from.distance_to(p)
	if d > 28.0:
		return false
	var q := PhysicsRayQueryParameters3D.create(from, p, 1 | 16)
	if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():
		return false
	if d < 2.4:
		return true
	if player.torch_cone_contains(p):
		return true
	return level != null and level.is_lit(p)

func _physics_process(delta: float) -> void:
	_t += delta
	if player == null or player.dead or state == S.DORMANT:
		velocity = Vector3.ZERO
		if _lull:
			_lull.stream_paused = true
		return
	var to := player.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	seen = _compute_seen()
	if state == S.KILL:
		velocity = Vector3.ZERO
		return
	if player.hidden and state != S.SEARCH:
		state = S.SEARCH
		_phase = 0
		_wait = 0.0
		_last_known = player.global_position
	if state == S.SEARCH and not player.hidden:
		state = S.STALK
	# dara hua dekhna: jam jaati hai
	if seen and state == S.STALK:
		velocity = Vector3.ZERO
		_play(_cur if _cur != "" else "ZombieIdle", 0.0)
		_lull.stream_paused = true
		player.add_fear(0.35 * delta * clampf(1.0 - dist / 14.0, 0.1, 1.0))
		_face(to, delta, 3.0)
		return
	match state:
		S.STALK:
			_do_stalk(delta, dist, to)
		S.SEARCH:
			_do_search(delta)
	# fear: kitni paas hai
	if state == S.STALK and dist < 14.0:
		player.add_fear(0.22 * delta * clampf(1.0 - dist / 14.0, 0.0, 1.0))
	# phusphusahat
	_whisper_t -= delta
	if _whisper_t <= 0.0 and dist < 20.0:
		_whisper_t = randf_range(6.0, 12.0)
		Aud.play3d(self, global_position + Vector3(0, 1.0, 0), "whisper", -6.0, randf_range(0.9, 1.1), 18.0)

func _move_to(target: Vector3, speed: float, delta: float, anim_name: String) -> void:
	_repath -= delta
	if _repath <= 0.0:
		_repath = 0.3
		agent.target_position = target
	var dir := Vector3.ZERO
	var nav_ok := NavigationServer3D.map_get_iteration_id(get_world_3d().navigation_map) > 0 and not agent.is_navigation_finished()
	if nav_ok:
		dir = agent.get_next_path_position() - global_position
	else:
		dir = target - global_position
	dir.y = 0.0
	if dir.length() > 0.05:
		dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity.y = -2.0
	_face(dir, delta, 6.0)
	_play(anim_name, speed / 2.7)
	move_and_slide()
	_open_doors()
	# atak gayi to seedhe dhakka
	_stuck_t += delta
	if _stuck_t > 1.0:
		_stuck_t = 0.0
		if global_position.distance_to(_last_pos) < 0.2 and not seen:
			_repath = 0.0
		_last_pos = global_position
	_step_t -= delta
	if _step_t <= 0.0 and speed > 0.1:
		_step_t = 0.55 / (speed / 2.7)
		Aud.play3d(self, global_position, "footstep", -8.0, randf_range(1.25, 1.5), 16.0)

func _face(dir: Vector3, delta: float, rate: float) -> void:
	if dir.length() < 0.05:
		return
	var ty := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, ty, 1.0 - exp(-rate * delta))

func _open_doors() -> void:
	for d in get_tree().get_nodes_in_group("doors"):
		if not d.is_open and d.global_position.distance_to(global_position) < 1.9:
			d.monster_open(global_position)

func _do_stalk(delta: float, dist: float, to: Vector3) -> void:
	_lull.stream_paused = false
	if dist < 1.15:
		_kill()
		return
	_move_to(player.global_position, walk_speed, delta, "ZombieWalk" if walk_speed < 3.3 else "ZombieRunning")

func _do_search(delta: float) -> void:
	_lull.stream_paused = false
	match _phase:
		0:
			if global_position.distance_to(_last_known) < 1.5:
				_phase = 1
				_wait = randf_range(5.0, 8.0)
				velocity = Vector3.ZERO
				_play("ZombieIdle", 1.0)
			else:
				_move_to(_last_known, walk_speed, delta, "ZombieWalk")
		1:
			velocity = Vector3.ZERO
			_play("ZombieIdle", 1.0)
			_wait -= delta
			if _wait <= 0.0:
				# kabhi kabhi almari kholti hai
				if randf() < 0.3 and player.hidden:
					player.kill(self, "almari")
					state = S.KILL
					_play("ZombieAttack", 1.0)
					return
				_phase = 2
				_wait = 7.0
				_wander = level.random_point() if level and level.has_method("random_point") else global_position + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
		2:
			_wait -= delta
			_move_to(_wander, walk_speed * 0.8, delta, "ZombieWalk")
			if _wait <= 0.0 or global_position.distance_to(_wander) < 1.0:
				_phase = 0
				_last_known = player.global_position if player.hidden else _last_known

func _kill() -> void:
	state = S.KILL
	velocity = Vector3.ZERO
	_lull.stream_paused = true
	_play("ZombieAttack", 1.0)
	player.kill(self, "gudiya")

func teleport(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
