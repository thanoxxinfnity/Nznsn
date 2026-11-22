extends Node3D
# Khilauna Nagar — Adhyay 1. Args: --shot=<dir> (screenshots), --autotest (headless jaanch).
var player: Player
var gud: Gudiya
var hud: Hud
var level: Level
var shot_dir := ""
var autotest := false
var results: Array = []

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot_dir = a.substr(7)
		elif a == "--autotest":
			autotest = true
			Ctl.auto = true
	hud = Hud.new()
	add_child(hud)
	await get_tree().process_frame
	await get_tree().process_frame
	if autotest and OS.get_cmdline_user_args().has("--fresh"):
		Save.clear()
	player = Player.new()
	add_child(player)
	player.hud = hud
	hud.player = player
	gud = Gudiya.new()
	add_child(gud)
	level = Level.new()
	add_child(level)
	player.level = level
	level.build(player, gud, hud)
	_hands()
	player.died.connect(_on_died)
	hud.retry_pressed.connect(func():
		get_tree().reload_current_scene())
	hud.continue_pressed.connect(func():
		get_tree().quit())
	level.chapter_end.connect(func(): print("CHAPTER_END"))
	hud.loaded()
	if not Save.has():
		hud.objective(Story.OBJ_ENTER)
		hud.subtitle(Story.START_SUB, 5.0)
		if not autotest and shot_dir == "":
			get_tree().create_timer(2.5).timeout.connect(func(): hud.show_note(Story.LETTER_T, Story.LETTER))
	if not DisplayServer.is_touchscreen_available() and not autotest and shot_dir == "" and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if shot_dir != "":
		_shots()
	elif autotest:
		_autotest()

func _hands() -> void:
	var path := "res://assets/characters/M04_FPArmsFlashlight.glb"
	if not ResourceLoader.exists(path):
		return
	var m := (load(path) as PackedScene).instantiate() as Node3D
	m.position = Vector3(0.22, -0.36, -0.55)
	m.rotation_degrees = Vector3(-68, 0, 0)
	m.scale = Vector3.ONE * 0.62
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--hand="):
			var v := a.substr(7).split(",")
			m.position = Vector3(float(v[0]), float(v[1]), float(v[2]))
			m.rotation_degrees = Vector3(float(v[3]), float(v[4]), float(v[5]))
			m.scale = Vector3.ONE * float(v[6])
	player.hands.add_child(m)
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).layers = 2
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _on_died(cause: String) -> void:
	await get_tree().create_timer(2.0).timeout
	hud.show_death()

# --------------------------------------------------------------- screenshots
func _snap(nm: String) -> void:
	for i in 6:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(shot_dir)
	img.save_png("%s/%s.png" % [shot_dir, nm])
	print("SHOT ", nm)

func _view(pos: Vector3, yaw_deg: float, pitch_deg := 0.0) -> void:
	player.global_position = pos
	player.set_view(deg_to_rad(yaw_deg), deg_to_rad(pitch_deg))

func _shots() -> void:
	hud.note_panel.visible = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--torch="):
			player.torch.shadow_enabled = false
			player.set_meta("torch_e", float(a.substr(8)))
	if OS.get_cmdline_user_args().has("--bright"):
		level._env.ambient_light_energy = 2.5
		level._env.fog_enabled = false
	for k in 8:
		await get_tree().process_frame
	_view(Vector3(0, 0.1, 15.0), 0)
	await _snap("01_yard_start")
	if OS.get_cmdline_user_args().has("--handonly"):
		get_tree().quit()
		return
	_view(Vector3(0, 0.1, 6.0), 0)
	await _snap("02_yard_door")
	_view(Vector3(0, 0.1, 0.5), 0)
	await _snap("03_reception_in")
	_view(Vector3(0, 0.1, -3.5), 0, -10)
	await _snap("04_reception_desk")
	_view(Vector3(0, 0.1, -9.0), 180)
	await _snap("05_reception_back")
	level.door_hall.locked = false
	level.door_hall.open_away_from(Vector3(0, 0, -8))
	await get_tree().create_timer(1.2).timeout
	_view(Vector3(0, 0.1, -11.5), 0)
	await _snap("06_hall_entry")
	_view(Vector3(0, 0.1, -16.0), 0)
	await _snap("07_hall_mid")
	print("TORCH ", player.torch.visible, " ", player.torch.global_position, " ", player.torch.light_energy, " range ", player.torch.spot_range, " fwd ", -player.torch.global_basis.z, " on ", player.torch_on, " bat ", player.battery)
	_view(Vector3(2.0, 0.1, -24.0), -10)
	await _snap("08_hall_gudiya")
	_view(Vector3(8.0, 0.1, -18.0), 90)
	await _snap("09_hall_east")
	level.door_paint.open_away_from(Vector3(14, 0, -22))
	await get_tree().create_timer(1.2).timeout
	_view(Vector3(18.0, 0.1, -22.0), 270)
	await _snap("10_paint_room")
	_view(Vector3(20.0, 0.1, -22.0), 0)
	await _snap("11_paint_back")
	level.door_gen.open_away_from(Vector3(-14, 0, -22))
	await get_tree().create_timer(1.2).timeout
	_view(Vector3(-18.0, 0.1, -22.0), 90)
	await _snap("12_gen_room")
	level.door_lift.locked = false
	level.door_lift.open_away_from(Vector3(0, 0, -32))
	await get_tree().create_timer(1.2).timeout
	_view(Vector3(0, 0.1, -36.0), 0)
	await _snap("13_lift")
	get_tree().quit()

# --------------------------------------------------------------- autotest
func _check(name_: String, ok: bool, extra := "") -> void:
	results.append(ok)
	print(("PASS " if ok else "FAIL ") + name_ + " " + extra)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func _autotest() -> void:
	await _frames(10)
	_check("nav polygons", level.nav_polys() > 100, str(level.nav_polys()))
	get_tree().quit()
