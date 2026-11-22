extends Node3D
# Khilauna Nagar — Adhyay 1. Args: --shot=<dir> (screenshots), --autotest (headless jaanch).
var player: Player
var gud: Gudiya
var hud: Hud
var level: Level
var shot_dir := ""
var autotest := false
var results: Array = []

var menu: Menu
var menu_dir := ""
var started := false
var paused := false

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot_dir = a.substr(7)
		elif a.begins_with("--menushot="):
			menu_dir = a.substr(11)
		elif a == "--autotest" or a == "--walktest":
			autotest = true
			Ctl.auto = true
	Settings.load_()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lang="):
			Settings.lang = a.substr(7)
	hud = Hud.new()
	add_child(hud)
	await get_tree().process_frame
	await get_tree().process_frame
	if autotest or shot_dir != "":
		if OS.get_cmdline_user_args().has("--fresh"):
			Save.clear()
		_start_game()
		return
	var cl := CanvasLayer.new()
	cl.layer = 20
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(cl)
	menu = Menu.new()
	cl.add_child(menu)
	menu.start_new.connect(func():
		Save.clear()
		menu.hide_title()
		_start_game())
	menu.start_continue.connect(func():
		menu.hide_title()
		_start_game())
	menu.resumed.connect(func(): _set_paused(false))
	menu.to_title.connect(func():
		get_tree().paused = false
		Save.skip_menu = false
		get_tree().reload_current_scene())
	menu.quit_game.connect(func(): get_tree().quit())
	menu.settings_changed.connect(func(lang_changed: bool):
		if lang_changed:
			get_tree().paused = false
			Save.skip_menu = false
			get_tree().reload_current_scene()
		elif started:
			Settings.apply(get_viewport(), level, player))
	hud.pause_pressed.connect(func(): _set_paused(true))
	if not Save.has():
		Save.read()
	if menu_dir != "":
		shot_dir = menu_dir
		menu.show_title(true)
		await _snap("m1_title")
		print("MENUSZ ", menu.size, " ", menu.title_box.size, " ", menu.get_parent().get_class(), " vp ", get_viewport().get_visible_rect().size)
		menu._open_settings(false)
		await _snap("m2_settings")
		menu._close_settings()
		menu.hide_title()
		_start_game_quiet()
		await get_tree().create_timer(1.0).timeout
		hud.show_note(Story.letter_t(), Story.letter())
		await _snap("m3_letter")
		hud.close_note()
		menu.show_pause()
		await _snap("m4_pause")
		get_tree().quit()
		return
	if Save.skip_menu:
		Save.skip_menu = false
		_start_game()
	else:
		menu.show_title(Save.has())

func _set_paused(on: bool) -> void:
	if not started or hud.death_box.visible or hud.end_box.visible:
		return
	paused = on
	if on:
		menu.show_pause()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		menu.hide_pause()
		if not DisplayServer.is_touchscreen_available() and DisplayServer.get_name() != "headless":
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and (e as InputEventKey).pressed and (e as InputEventKey).keycode == KEY_ESCAPE and menu:
		_set_paused(not paused)

func _start_game_quiet() -> void:
	shot_dir = ""
	_start_game()
	shot_dir = menu_dir

func _start_game() -> void:
	player = Player.new()
	add_child(player)
	player.hud = hud
	hud.player = player
	gud = Gudiya.new()
	add_child(gud)
	level = Level.new()
	add_child(level)
	player.level = level
	var t0 := Time.get_ticks_msec()
	level.build(player, gud, hud)
	print("BUILD ms=", Time.get_ticks_msec() - t0)
	_hands()
	player.died.connect(_on_died)
	hud.retry_pressed.connect(func():
		Save.skip_menu = true
		get_tree().reload_current_scene())
	hud.continue_pressed.connect(func():
		get_tree().quit())
	level.chapter_end.connect(func(): print("CHAPTER_END"))
	Settings.apply(get_viewport(), level, player)
	hud.loaded()
	started = true
	if not Save.has():
		hud.objective(Story.obj_enter())
		hud.subtitle(Story.start_sub(), 5.0)
		if not autotest and shot_dir == "":
			get_tree().create_timer(2.5).timeout.connect(func(): hud.show_note(Story.letter_t(), Story.letter()))
	if not DisplayServer.is_touchscreen_available() and not autotest and shot_dir == "" and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if shot_dir != "" and OS.get_cmdline_user_args().has("--shot2"):
		_shots2()
	elif shot_dir != "":
		_shots()
	elif OS.get_cmdline_user_args().has("--walktest"):
		_walktest()
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
	print("PERF %s draws=%d objs=%d prims=%d" % [nm, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
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

func _shots2() -> void:
	hud.note_panel.visible = false
	for k in 8:
		await get_tree().process_frame
	level.door_hall.locked = false
	level.door_hall.open_away_from(Vector3(0, 0, -8))
	gud.teleport(Vector3(1.0, 0, -19.5))
	gud.rotation.y = deg_to_rad(15)
	gud.activate()
	gud.set_physics_process(false)
	_stand(Vector3(0, 0.1, -16.5), Vector3(1.0, 0.9, -19.5))
	await _snap("a_gudiya_near")
	gud.teleport(Vector3(0.4, 0, -17.6))
	_look_at(Vector3(0.4, 1.0, -17.6))
	await _snap("b_gudiya_close")
	_stand(Vector3(3.9, 0.1, -8.4), Vector3(3.9, 1.3, -9.65))
	await _snap("c_key_prompt")
	_stand(Vector3(0.0, 0.1, -4.0), Vector3(0.9, 1.1, -6.15))
	await _snap("d_diary_prompt")
	level.hud.show_note(Story.d2_t(), Story.d2())
	await _snap("e_note")
	level.hud.close_note()
	_stand(Vector3(-13.9, 0.1, -13.0), Vector3(-15.3, 1.0, -13.0))
	await _snap("f_wardrobe_prompt")
	await _use()
	for k in 25:
		await get_tree().process_frame
	await _snap("g_hidden")
	await _use()
	gud.set_physics_process(true)
	gud.global_position = Vector3(0.0, 0, -15.0)
	_stand(Vector3(0, 0.1, -16.0), Vector3(0.0, 1.0, -15.0))
	player.kill(gud)
	await get_tree().create_timer(0.9).timeout
	await _snap("h_death_look")
	hud.show_death()
	await _snap("i_death_screen")
	hud.death_box.visible = false
	player.revive()
	_stand(Vector3(26.9, 0.1, -22.3), Vector3(28.4, 1.07, -22.3))
	level.door_paint.open_away_from(Vector3(14, 0, -22))
	await _snap("j_fuse_bench")
	_stand(Vector3(-27.6, 0.1, -23.0), Vector3(-29.5, 1.5, -23.0))
	await _snap("k_fusebox")
	get_tree().quit()

# --------------------------------------------------------------- autotest
func _check(name_: String, ok: bool, extra := "") -> void:
	results.append(ok)
	print(("PASS " if ok else "FAIL ") + name_ + " " + extra)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func _look_at(target: Vector3) -> void:
	var eye := player.global_position + Vector3(0, 1.6, 0)
	var d := target - eye
	player.set_view(atan2(-d.x, -d.z), atan2(d.y, Vector2(d.x, d.z).length()))

func _stand(pos: Vector3, target: Vector3) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	_look_at(target)

func _use() -> void:
	Ctl.use_p = true
	await _frames(4)
	Ctl.use_p = false

func _walk_to(target: Vector3, label: String, max_frames := 1500) -> bool:
	var map := level.nav.get_navigation_map()
	var path := NavigationServer3D.map_get_path(map, player.global_position, target, true)
	if path.size() < 2:
		_check("walk path " + label, false, "no path")
		return false
	var doors := [level.door_entry, level.door_hall, level.door_paint, level.door_gen, level.door_lift]
	for wp in path:
		var frames := 0
		while Vector2(player.global_position.x - wp.x, player.global_position.z - wp.z).length() > 0.45 and frames < max_frames:
			var d: Vector3 = wp - player.global_position
			player.yaw = atan2(-d.x, -d.z)
			player.pitch = 0.0
			Ctl.move = Vector2(0, -1)
			for dr in doors:
				if not dr.is_open and dr.global_position.distance_to(player.global_position) < 2.4:
					dr.locked = false
					dr.open_away_from(player.global_position)
			await get_tree().physics_frame
			frames += 1
		if frames >= max_frames:
			Ctl.move = Vector2.ZERO
			var cn := []
			for i in player.get_slide_collision_count():
				var col := player.get_slide_collision(i)
				var co = col.get_collider()
				cn.append("%s path=%s layer=%d gpos=%s normal=%s" % [co.get_class(), co.get_path(), co.collision_layer, co.global_position, col.get_normal()])
			var q := PhysicsRayQueryParameters3D.create(player.global_position + Vector3(0, 0.5, 0), player.global_position + Vector3(0, 0.5, 0) + Vector3(sin(0.0) - 1.0 * signf(wp.x - player.global_position.x), 0, 0) * 1.5, 1 | 16)
			var hit := player.get_world_3d().direct_space_state.intersect_ray(q)
			_check("walk " + label, false, "stuck near %s going to %s frozen=%s hidden=%s onfloor=%s vel=%s ray=%s" % [player.global_position, wp, player.frozen, player.hidden, player.is_on_floor(), player.velocity, hit.get("collider").get_path() if not hit.is_empty() else "none"])
			return false
	Ctl.move = Vector2.ZERO
	var dist := Vector2(player.global_position.x - target.x, player.global_position.z - target.z).length()
	_check("walk " + label, dist < 1.0, "end=%s" % player.global_position)
	return dist < 1.0

func _walktest() -> void:
	await _frames(10)
	player.torch_on = true
	gud.set_physics_process(false)
	for leg in [[Vector3(0, 0.1, -5.0), "yard -> reception"], [Vector3(0, 0.1, -13.0), "reception -> hall"], [Vector3(22, 0.1, -22.0), "hall -> paint room"], [Vector3(-22, 0.1, -22.0), "paint -> generator room"], [Vector3(0, 0.1, -39.0), "gen -> lift"], [Vector3(26, 0.1, -29.0), "lift -> paint corner"], [Vector3(-26, 0.1, -17.0), "paint -> gen corner"]]:
		if not await _walk_to(leg[0], leg[1]):
			break
	var ok := 0
	for r in results:
		if r:
			ok += 1
	print("WALKTEST %d/%d" % [ok, results.size()])
	get_tree().quit(0 if ok == results.size() else 1)

func _autotest() -> void:
	await _frames(10)
	_check("nav polygons", level.nav_polys() > 100, str(level.nav_polys()))
	# 1) touch HUD
	var t := InputEventScreenTouch.new()
	t.index = 3
	t.pressed = true
	t.position = hud.joy_center()
	hud._input(t)
	var dr := InputEventScreenDrag.new()
	dr.index = 3
	dr.position = hud.joy_center() + Vector2(0, -90)
	hud._input(dr)
	_check("touch joystick", hud.joy_vec.y < -0.5, str(hud.joy_vec))
	t = InputEventScreenTouch.new()
	t.index = 3
	t.pressed = false
	hud._input(t)
	var b: Array = hud.buttons()["USE"]
	t = InputEventScreenTouch.new()
	t.index = 4
	t.pressed = true
	t.position = b[0]
	hud._input(t)
	_check("touch USE button", Ctl.use_p)
	Ctl.use_p = false
	t.pressed = false
	hud._input(t)
	# 2) entry door
	_stand(Vector3(0, 0.1, 4.0), Vector3(0, 1.2, 2.0))
	await _frames(6)
	_check("door prompt", hud.prompt_lbl.text != "", hud.prompt_lbl.text)
	await _use()
	await _frames(70)
	_check("entry door opens", level.door_entry.is_open)
	# 3) andar jaao -> darwaza band
	_stand(Vector3(0, 0.1, 2.8), Vector3(0, 1.4, -6.0))
	Ctl.move = Vector2(0, -1)
	await _frames(150)
	Ctl.move = Vector2.ZERO
	_check("walked into reception", player.global_position.z < 0.5, str(player.global_position))
	await _frames(40)
	_check("entry door slams+locks", level.flags.get("entered", false) and not level.door_entry.is_open and level.door_entry.locked)
	# 4) chaabi
	_stand(Vector3(3.9, 0.1, -8.6), Vector3(3.9, 1.3, -9.65))
	await _frames(6)
	_check("key prompt", hud.prompt_lbl.text.begins_with(Tr.t("Pick up")), hud.prompt_lbl.text)
	await _use()
	await _frames(10)
	_check("key picked", player.has_item("key_hall"))
	await _frames(10)
	_check("key_taken flag + save", level.flags.get("key_taken", false) and Save.has())
	# 5) hall door
	_stand(Vector3(0, 0.1, -8.4), Vector3(0, 1.2, -10.0))
	await _frames(6)
	await _use()
	await _frames(80)
	_check("hall door unlocks+opens", level.door_hall.is_open and not level.door_hall.locked)
	# 6) hall + Gudiya
	_stand(Vector3(0, 0.1, -11.5), Vector3(0, 1.0, -30.0))
	await _frames(20)
	_check("hall entered", level.flags.get("hall_entered", false))
	gud.teleport(Vector3(0, 0, -24.0))
	gud.rotation.y = 0.0
	gud.activate()
	_stand(Vector3(0, 0.1, -16.0), Vector3(0, 0.7, -24.0))
	await _frames(30)
	var p0 := gud.global_position
	await _frames(90)
	_check("gudiya seen", gud.seen, "seen=%s" % gud.seen)
	_check("gudiya frozen while watched", gud.global_position.distance_to(p0) < 0.1, str(gud.global_position.distance_to(p0)))
	player.torch_on = true
	_stand(Vector3(0, 0.1, -16.0), Vector3(0, 1.0, 0.0))
	var d0 := gud.global_position.distance_to(player.global_position)
	await _frames(150)
	var d1 := gud.global_position.distance_to(player.global_position)
	_check("gudiya advances when unseen", d1 < d0 - 1.0, "%.1f -> %.1f" % [d0, d1])
	# 7) maut
	var steps := 0
	while not player.dead and steps < 40:
		await _frames(30)
		steps += 1
	_check("player killed by gudiya", player.dead, "after %d s" % (steps / 2))
	await get_tree().create_timer(2.6).timeout
	_check("death screen shown", hud.death_box.visible)
	hud.death_box.visible = false
	player.revive()
	# 8) chhupna
	gud.teleport(Vector3(0, 0, -26.0))
	gud.state = Gudiya.S.STALK
	_stand(Vector3(-13.9, 0.1, -13.0), Vector3(-15.3, 1.0, -13.0))
	await _frames(6)
	_check("wardrobe prompt", hud.prompt_lbl.text.contains(Tr.t("Hide")), hud.prompt_lbl.text)
	await _use()
	await _frames(10)
	_check("hidden in wardrobe", player.hidden)
	await _frames(60)
	_check("gudiya switches to search", gud.state == Gudiya.S.SEARCH, str(gud.state))
	await _use()
	await _frames(10)
	_check("left wardrobe", not player.hidden)
	gud.state = Gudiya.S.DORMANT
	gud.teleport(Vector3(0, 0, -31))
	# 9) fuse -> power
	var fuse_pos := Vector3(28.4, 1.07, -22.3)
	_stand(Vector3(26.9, 0.1, -22.3), fuse_pos)
	await _frames(6)
	await _use()
	await _frames(10)
	_check("fuse picked", player.has_item("fuse"))
	_stand(Vector3(-27.6, 0.1, -23.0), Vector3(-29.5, 1.5, -23.0))
	await _frames(6)
	_check("fuse box prompt", hud.prompt_lbl.text.contains(Tr.t("fuse")), hud.prompt_lbl.text)
	await _use()
	await _frames(20)
	_check("power on", level.flags.get("power", false) and not level.door_lift.locked and level.is_lit(Vector3(0, 0, -22)))
	# 10) lift
	_stand(Vector3(0, 0.1, -39.5), Vector3(0, 1.25, -42.0))
	await _frames(6)
	_check("lift prompt", hud.prompt_lbl.text.contains(Tr.t("lift")), hud.prompt_lbl.text)
	await _use()
	await get_tree().create_timer(3.0).timeout
	_check("chapter end card", hud.end_box.visible)
	var ok := 0
	for r in results:
		if r:
			ok += 1
	print("AUTOTEST %d/%d" % [ok, results.size()])
	get_tree().quit(0 if ok == results.size() else 1)
