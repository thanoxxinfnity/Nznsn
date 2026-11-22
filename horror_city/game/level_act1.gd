class_name Level
extends Node3D
# Adhyay 1: Rangeela Toys factory. Yard -> Reception -> Assembly Hall -> (Paint room / Generator room) -> Lift.
signal chapter_end

var player: Player
var gud: Gudiya
var hud: Hud
var zones := {}
var flags := {}
var door_entry: Door
var door_hall: Door
var door_paint: Door
var door_gen: Door
var door_lift: Door
var nav: NavigationRegion3D
var patrol: Array[Vector3] = []
var _lift_inter: Interactable
var _fuse_led: MeshInstance3D
var _gen_snd: AudioStreamPlayer3D
var _rain: GPUParticles3D
var _rain_snd: AudioStreamPlayer
var _moon: DirectionalLight3D
var _thunder_t := 12.0
var _env: Environment
var _ended := false
var zone_nodes := {}      # zone -> Array[Node] (culling)
var _vis_key := ""
const LINKS := [["yard", "reception", "door_entry"], ["reception", "hall", "door_hall"], ["hall", "paint", "door_paint"], ["hall", "gen", "door_gen"], ["hall", "lift", "door_lift"]]

const WM := 0.3

func _zone(nm: String, x0: float, z0: float, x1: float, z1: float, lit: bool) -> void:
	zones[nm] = {"rect": Rect2(x0, z0, x1 - x0, z1 - z0), "lit": lit}

func is_lit(p: Vector3) -> bool:
	for k in zones:
		if zones[k].rect.has_point(Vector2(p.x, p.z)):
			return zones[k].lit
	return false

func zone_of(p: Vector3) -> String:
	for k in zones:
		if zones[k].rect.has_point(Vector2(p.x, p.z)):
			return k
	return ""

func surface_at(p: Vector3) -> String:
	var z := zone_of(p)
	return "metal" if z in ["hall", "gen", "lift"] else "concrete"

func random_point() -> Vector3:
	return patrol[randi() % patrol.size()] if patrol.size() > 0 else Vector3.ZERO

func set_zone_power(nm: String, on: bool) -> void:
	if zones.has(nm):
		zones[nm].lit = on
	for l in get_tree().get_nodes_in_group("lamps"):
		if l.zone == nm:
			l.set_powered(on)

func _frame(pos: Vector3, along_x: bool, w: float, h: float, th: float) -> void:
	var m := Mats.solid(Color(0.08, 0.08, 0.08), 0.6)
	var d := th + 0.06
	if along_x:
		Build.box(self, pos + Vector3(-w / 2.0 - 0.06, h / 2.0, 0), Vector3(0.12, h, d), m, false)
		Build.box(self, pos + Vector3(w / 2.0 + 0.06, h / 2.0, 0), Vector3(0.12, h, d), m, false)
		Build.box(self, pos + Vector3(0, h + 0.06, 0), Vector3(w + 0.24, 0.12, d), m, false)
	else:
		Build.box(self, pos + Vector3(0, h / 2.0, -w / 2.0 - 0.06), Vector3(d, h, 0.12), m, false)
		Build.box(self, pos + Vector3(0, h / 2.0, w / 2.0 + 0.06), Vector3(d, h, 0.12), m, false)
		Build.box(self, pos + Vector3(0, h + 0.06, 0), Vector3(d, 0.12, w + 0.24), m, false)

func _pk(uid: String, file: String, pos: Vector3, rot: float, item: String, label: String, kind := "item", sc := 1.0) -> Pickup:
	if Save.data.get("collected", []).has(uid):
		return null
	var pk := Pickup.make(self, file, pos, rot, item, label, kind, sc)
	pk.picked.connect(func(_p):
		if not Save.data.has("collected"):
			Save.data["collected"] = []
		Save.data["collected"].append(uid))
	return pk

func build(p_: Player, g_: Gudiya, h_: Hud) -> void:
	player = p_
	gud = g_
	hud = h_
	var W := Mats.wall()
	var BR := Mats.brick()
	var FL := Mats.floor_()
	var TL := Mats.tile()
	var CE := Mats.ceiling()
	_zone("yard", -9, 2, 9, 18, false)
	_zone("reception", -6, -10, 6, 2, true)
	_zone("hall", -16, -34, 16, -10, false)
	_zone("paint", 16, -32, 30, -14, false)
	_zone("gen", -30, -32, -16, -14, false)
	_zone("lift", -6, -44, 6, -34, false)
	# ---- shell ----
	# yard
	Build.floor_(self, -9.3, 2, 9.3, 18.3, FL)
	Build.wall_z(self, -9.15, 2, 18.15, BR, [], 3.2)
	Build.wall_z(self, 9.15, 2, 18.15, BR, [], 3.2)
	Build.wall_x(self, 18.15, -9.3, -3.0, BR, [], 3.2)
	Build.wall_x(self, 18.15, 3.0, 9.3, BR, [], 3.2)
	Build.prop(self, "HM17_FactoryGate", Vector3(0, 0, 18.15), 0.0, 1.0, true)
	# front wall + reception
	Build.wall_x(self, 2.0, -9.3, 9.3, BR, [{"c": 0.0, "w": 1.5, "h": 2.4}], 4.6)
	Build.floor_(self, -6, -10, 6, 2, TL)
	Build.ceiling(self, -6.15, -10.15, 6.15, 2.15, CE, 3.4)
	Build.wall_z(self, -6.0, -10, 2, W, [], 3.4)
	Build.wall_z(self, 6.0, -10, 2, W, [], 3.4)
	# hall
	Build.floor_(self, -16, -34, 16, -10, FL)
	Build.ceiling(self, -16.15, -34.15, 16.15, -9.85, CE, 5.5)
	Build.wall_x(self, -10.0, -16.15, 16.15, W, [{"c": 0.0, "w": 1.5, "h": 2.4}], 5.5)
	Build.wall_x(self, -34.0, -16.15, 16.15, W, [{"c": 0.0, "w": 1.6, "h": 2.5}], 5.5)
	Build.wall_z(self, -16.0, -34, -10, W, [{"c": -22.0, "w": 1.4, "h": 2.4}], 5.5)
	Build.wall_z(self, 16.0, -34, -10, W, [{"c": -22.0, "w": 1.4, "h": 2.4}], 5.5)
	# paint room
	Build.floor_(self, 16, -32, 30, -14, TL)
	Build.ceiling(self, 15.85, -32.15, 30.15, -13.85, CE, 3.4)
	Build.wall_z(self, 30.0, -32.15, -13.85, W, [], 3.4)
	Build.wall_x(self, -32.0, 15.85, 30.15, W, [], 3.4)
	Build.wall_x(self, -14.0, 15.85, 30.15, W, [], 3.4)
	# generator room
	Build.floor_(self, -30, -32, -16, -14, FL)
	Build.ceiling(self, -30.15, -32.15, -15.85, -13.85, CE, 3.4)
	Build.wall_z(self, -30.0, -32.15, -13.85, W, [], 3.4)
	Build.wall_x(self, -32.0, -30.15, -15.85, W, [], 3.4)
	Build.wall_x(self, -14.0, -30.15, -15.85, W, [], 3.4)
	# lift lobby
	Build.floor_(self, -6, -44, 6, -34, FL)
	Build.ceiling(self, -6.15, -44.15, 6.15, -33.85, CE, 3.4)
	Build.wall_z(self, -6.0, -44.15, -34, W, [], 3.4)
	Build.wall_z(self, 6.0, -44.15, -34, W, [], 3.4)
	Build.wall_x(self, -44.0, -6.15, 6.15, W, [], 3.4)
	# ---- darwaze ----
	_frame(Vector3(0, 0, 2.0), true, 1.5, 2.4, WM)
	_frame(Vector3(0, 0, -10.0), true, 1.5, 2.4, WM)
	_frame(Vector3(0, 0, -34.0), true, 1.6, 2.5, WM)
	_frame(Vector3(-16.0, 0, -22.0), false, 1.4, 2.4, WM)
	_frame(Vector3(16.0, 0, -22.0), false, 1.4, 2.4, WM)
	door_entry = Door.make(self, Vector3(0, 0, 2.0), true, 1.5, 2.4, true)
	door_hall = Door.make(self, Vector3(0, 0, -10.0), true, 1.5, 2.4, true)
	door_hall.locked = true
	door_hall.key_id = "key_hall"
	door_hall.lock_msg = Tr.t("It's locked. The key must be somewhere in reception.")
	door_paint = Door.make(self, Vector3(16.0, 0, -22.0), false, 1.4, 2.4, false)
	door_gen = Door.make(self, Vector3(-16.0, 0, -22.0), false, 1.4, 2.4, false)
	door_lift = Door.make(self, Vector3(0, 0, -34.0), true, 1.6, 2.5, true)
	door_lift.locked = true
	door_lift.lock_msg = Tr.t("No power. Start the generator first.")
	_dress_yard()
	_dress_reception()
	_dress_hall()
	_dress_paint()
	_dress_gen()
	_dress_lift()
	_patrol_points()
	_build_nav()
	_build_env()
	_collect_zone_nodes()
	# shuruaati bijli: sirf reception chalu; baaki bund
	for nm in ["hall", "paint", "gen", "lift"]:
		set_zone_power(nm, false)
	if Save.has():
		_restore()
	else:
		player.global_position = Vector3(0, 0.1, 15.5)
		player.set_view(0.0)
	_place_gudiya()

func _collect_zone_nodes() -> void:
	for c in get_children():
		var cls := c.get_class()
		if c is Lamp or c is Pickup or c is HideSpot or (cls == "Node3D"):
			var z := zone_of((c as Node3D).global_position)
			if z != "":
				if not zone_nodes.has(z):
					zone_nodes[z] = []
				zone_nodes[z].append(c)

func _update_visibility(force := false) -> void:
	var cur := zone_of(player.global_position)
	var vis := {}
	if cur != "":
		vis[cur] = true
	var doors := {"door_entry": door_entry, "door_hall": door_hall, "door_paint": door_paint, "door_gen": door_gen, "door_lift": door_lift}
	for l in LINKS:
		var d: Door = doors[l[2]]
		var open := d.is_open or d.pivot.rotation.y != 0.0
		if open or force:
			if vis.has(l[0]):
				vis[l[1]] = true
			if vis.has(l[1]):
				vis[l[0]] = true
	var key := ",".join(vis.keys())
	if key == _vis_key and not force:
		return
	_vis_key = key
	for z in zone_nodes:
		var on: bool = vis.has(z) or cur == ""
		for n in zone_nodes[z]:
			if is_instance_valid(n) and n.visible != on:
				n.visible = on
	_moon.shadow_enabled = (cur == "yard")

func _patrol_points() -> void:
	for v in [Vector3(-10, 0, -16), Vector3(10, 0, -16), Vector3(-10, 0, -28), Vector3(10, 0, -28), Vector3(0, 0, -22), Vector3(0, 0, -14), Vector3(0, 0, -30), Vector3(-24, 0, -22), Vector3(24, 0, -22)]:
		patrol.append(v)

func _place_gudiya() -> void:
	gud.player = player
	gud.level = self
	if flags.get("hall_entered", false):
		gud.teleport(Vector3(6, 0, -31))
		gud.activate()
	else:
		gud.teleport(Vector3(4.5, 0, -31.0))
		gud.rotation.y = 0.0

func _restore() -> void:
	var d: Dictionary = Save.data
	player.global_position = d.pos
	player.set_view(d.yaw)
	player.items = d.items.duplicate()
	player.battery = d.battery
	flags = d.flags.duplicate()
	if flags.get("entered", false):
		door_entry.is_open = false
		door_entry.locked = true
		door_entry.lock_msg = Tr.t("The door is stuck — there's no going back.")
	if player.has_item("key_hall"):
		door_hall.locked = false
	if flags.get("power", false):
		_power_on(true)
	hud.objective(d.objective)

func checkpoint(obj: String) -> void:
	Save.data = {"pos": player.global_position, "yaw": player.yaw, "items": player.items.duplicate(), "battery": player.battery,
		"flags": flags.duplicate(), "objective": obj, "collected": Save.data.get("collected", [])}
	Save.write()
	hud.toast(Tr.t("✓ Checkpoint saved"), 1.5)

# ---------------------------------------------------------------- dressing
func _P(file: String, x: float, z: float, rot := 0.0, y := 0.0, sc := 1.0, collide := true) -> Node3D:
	return Build.prop(self, file, Vector3(x, y, z), rot, sc, collide)

func _dress_yard() -> void:
	_P("V03_toy_delivery_truck", -5.2, 8.5, 90)
	_P("F09_rusty_oil_barrel", 6.8, 4.2)
	_P("F09_rusty_oil_barrel", 7.6, 5.0)
	_P("F09_rusty_oil_barrel", 7.1, 5.8)
	_P("ST07_TrashCans", 7.5, 13.5, 180)
	_P("F08_wooden_pallet", 6.5, 9.5)
	_P("F07_cardboard_box_stack_v2", 6.5, 9.5, 20, 0.145)
	_P("W27_WoodenCrateStack", -7.6, 3.6, 10)
	_P("BR14_fallen_signboard_v1", 3.0, 7.0, 35)
	_P("D06_trash_bag_pile_v1", -7.8, 14.0, 70)
	_P("R05_street_lamp", -6.2, 12.0, 90)
	_P("R05_street_lamp", 6.2, 6.0, -90)
	_P("F34_toy_factory_sign", 0, 2.6, 2.3, 0, 1.0, false)
	Build.lamp(self, Vector3(-5.2, 4.7, 12.0), Color(0.75, 0.85, 1.0), 2.0, 13.0, 0.35, "", false)
	Build.lamp(self, Vector3(5.2, 4.7, 6.0), Color(0.75, 0.85, 1.0), 1.6, 12.0, 0.15, "", false)

func _dress_reception() -> void:
	_P("H07_reception_desk", 0, -6.2, 0)
	_P("F17_office_swivel_chair", 0.8, -7.3, 205)
	_P("F16_filing_cabinet", 3.6, -9.65, 0)
	_P("F16_filing_cabinet", 4.2, -9.65, 0)
	_P("HE06_waiting_room_bench", -4.6, -1.8, 90)
	_P("HE06_waiting_room_bench", 4.6, -3.2, -90)
	_P("F36_wall_clock", -5.85, -5.0, 90, 2.3, 1.0, false)
	_P("F37_warning_poster_v1", 5.88, -6.0, -90, 1.4, 1.0, false)
	_P("D02_overturned_chair_v1", -3.2, -7.6, 40)
	_P("D09_open_books_on_floor_v1", -2.2, -3.2, 10)
	_P("D06_trash_bag_pile_v2", -5.0, -8.8, 30)
	_P("F21_desk_lamp", -1.0, -6.2, 15, 1.1, 1.0, false)
	_pk("key", "G03_key_v1_brass", Vector3(3.9, 1.3, -9.65), 20, "key_hall", Tr.t("Reception key"), "item", 2.5)
	var d1 := _pk("d1", "G05_diary", Vector3(0.9, 1.12, -6.15), 10, "diary1", Tr.t("Diary"), "note", 1.0)
	if d1:
		d1.note_title = Story.d1_t()
		d1.note_text = Story.d1()
	var b1 := _pk("bat1", "G02_battery_d_cell", Vector3(-4.8, 0.02, -8.6), 0, "", Tr.t("BATTERY"), "battery", 2.0)
	if b1:
		b1.amount = 45.0
	Build.tube(self, Vector3(0, 3.3, -2.0), Color(0.82, 1.0, 0.9), 1.5, 9.0, 0.7, "reception", true)
	Build.tube(self, Vector3(0, 3.3, -7.0), Color(0.82, 1.0, 0.9), 1.3, 9.0, 0.35, "reception", true)

func _dress_hall() -> void:
	for z in [-14.2, -17.2, -26.0, -29.0, -32.0]:
		_P("F01_conveyor_belt_straight", -8.0, z, 90)
		_P("F01_conveyor_belt_straight", 8.0, z, 90)
	_P("HM02_injection_molding_machine", -11.5, -33.2, 0)
	_P("HM06_packaging_machine", 11.5, -33.2, 0)
	_P("F42_stuffing_machine", -14.9, -26.0, 90)
	_P("F42_stuffing_machine", 14.9, -26.0, -90)
	_P("F06_metal_shelving_boxes", 15.6, -13.5, -90)
	_P("F06_metal_shelving_boxes", 15.6, -17.5, -90)
	_P("F07_cardboard_box_stack_v1", 4.0, -13.0, 15)
	_P("F07_cardboard_box_stack_v3", -3.5, -12.6, 70)
	_P("F08_wooden_pallet", -2.5, -15.5, 0)
	_P("F08_wooden_pallet", 3.0, -27.0, 30)
	_P("F09_rusty_oil_barrel", -4.2, -24.5)
	_P("F09_rusty_oil_barrel", -4.9, -25.1)
	_P("F33_toy_parts_bin", 2.3, -19.0, 40, 0.0)
	_P("HM13_OverheadPipeRack", 0, -31.0, 0)
	_P("F37_warning_poster_v2", 0.0, -33.8, 0, 1.6, 1.0, false)
	for d in [[-8.0, -14.2, 90], [8.0, -17.2, -90], [-8.0, -29.0, 90], [8.0, -32.0, 180], [-8.0, -26.0, 60]]:
		_P("T02_porcelain_doll_sitting_v%d" % (1 + randi() % 3), d[0], d[1], d[2], 0.9, 1.0, false)
	var hs := HideSpot.make(self, "B04_wooden_wardrobe_v1", Vector3(-15.3, 0, -13.0), 90, Vector3(1.1, 2.0, 1.02))
	hs.add_to_group("hide_spots")
	var d2 := _pk("d2", "G05_diary", Vector3(-2.5, 0.16, -15.5), 70, "diary2", Tr.t("Diary"), "note", 1.0)
	if d2:
		d2.note_title = Story.d2_t()
		d2.note_text = Story.d2()
	Build.lamp(self, Vector3(-10, 4.9, -15), Color(1.0, 0.12, 0.06), 1.1, 11.0, 0.35, "hall_em", true)
	Build.lamp(self, Vector3(10, 4.9, -15), Color(1.0, 0.12, 0.06), 1.1, 11.0, 0.35, "hall_em", true)
	Build.lamp(self, Vector3(-10, 4.9, -28), Color(1.0, 0.12, 0.06), 1.1, 11.0, 0.35, "hall_em", true)
	Build.lamp(self, Vector3(10, 4.9, -28), Color(1.0, 0.12, 0.06), 1.1, 11.0, 0.35, "hall_em", true)
	Build.lamp(self, Vector3(0, 4.9, -22), Color(1.0, 0.12, 0.06), 0.9, 10.0, 0.5, "hall_em", true)
	for pos in [Vector3(-6, 5.1, -18), Vector3(6, 5.1, -18), Vector3(-6, 5.1, -27), Vector3(6, 5.1, -27)]:
		Build.tube(self, pos, Color(0.9, 0.95, 1.0), 2.4, 15.0, 0.0, "hall", true)

func _dress_paint() -> void:
	for x in [18.5, 20.5, 22.5]:
		_P("W03_toy_shop_shelf_v1", x, -31.7, 0)
	_P("F05_paint_vat", 28.6, -30.0, 90)
	_P("F05_paint_vat", 28.6, -27.2, 90)
	_P("HM04_paint_booth", 26.5, -17.5, 180)
	_P("F10_workbench_tools", 28.7, -22.5, -90)
	_P("D21_paint_cans_v1", 25.0, -24.0, 20)
	_P("D21_paint_cans_v2", 24.4, -24.6, 60)
	for i in 5:
		_P("T02_porcelain_doll_sitting_v%d" % (1 + i % 3), 22.0 + i * 1.0, -20.0, 90 + (i - 2) * 8.0, 0.0, 1.0, false)
	var h1 := HideSpot.make(self, "B04_wooden_wardrobe_v1", Vector3(16.75, 0, -17.8), 90, Vector3(1.1, 2.0, 1.02))
	var h2 := HideSpot.make(self, "B04_wooden_wardrobe_v1", Vector3(16.75, 0, -28.5), 90, Vector3(1.1, 2.0, 1.02))
	h1.add_to_group("hide_spots")
	h2.add_to_group("hide_spots")
	_pk("fuse", "G04_ceramic_fuse", Vector3(28.4, 1.07, -22.3), 0, "fuse", Tr.t("Ceramic fuse"), "item", 3.0)
	var d3 := _pk("d3", "G05_diary", Vector3(28.4, 1.07, -23.2), 40, "diary3", Tr.t("Diary"), "note", 1.0)
	if d3:
		d3.note_title = Story.d3_t()
		d3.note_text = Story.d3()
	var b2 := _pk("bat2", "G02_battery_d_cell", Vector3(20.0, 0.02, -30.0), 0, "", Tr.t("BATTERY"), "battery", 2.0)
	if b2:
		b2.amount = 45.0
	Build.lamp(self, Vector3(23, 3.0, -23), Color(1.0, 0.7, 0.35), 1.2, 11.0, 0.85, "paint_em", true)
	Build.lamp(self, Vector3(27, 2.8, -28), Color(1.0, 0.65, 0.3), 0.8, 8.0, 0.6, "paint_em", true)

func _dress_gen() -> void:
	_P("F13_diesel_generator", -26.0, -31.35, 0)
	var fb := _P("F12_fuse_box_wall", -29.8, -23.0, 90, 1.3, 1.0, false)
	_P("U17_big_fuse_panel", -29.45, -17.5, 90)
	_P("F10_workbench_tools", -25.5, -15.2, 180)
	_P("F09_rusty_oil_barrel", -17.5, -31.0)
	_P("F09_rusty_oil_barrel", -18.2, -31.4)
	_P("CS18_pipes_stack", -20.0, -30.8, 0)
	_P("Y08_floor_cable_bundles_v1", -23.0, -25.0, 30, 0.0, 1.0, false)
	_P("D26_pipe_pieces_v1", -18.5, -16.5, 20)
	_fuse_led = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.04
	sm.height = 0.08
	_fuse_led.mesh = sm
	_fuse_led.material_override = Mats.solid(Color(1, 0.1, 0.05), 0.4, 3.0)
	_fuse_led.position = Vector3(-29.55, 1.62, -23.0)
	add_child(_fuse_led)
	Interactable.make(self, Vector3(-29.5, 1.5, -23.0), Vector3(0.8, 0.8, 0.8), _fuse_prompt, _fuse_use)
	Build.lamp(self, Vector3(-23, 3.0, -23), Color(1.0, 0.85, 0.6), 1.3, 11.0, 0.6, "gen", true)
	_gen_snd = Aud.loop3d(self, Vector3(-26, 1.0, -31.0), "generator", -50.0, 40.0)
	_gen_snd.stop()

func _dress_lift() -> void:
	_P("F30_freight_elevator_cage", 0.0, -43.05, 0)
	_lift_inter = Interactable.make(self, Vector3(0, 1.25, -42.0), Vector3(1.9, 2.5, 0.5), _lift_prompt, _lift_use)
	Build.tube(self, Vector3(0, 3.3, -39.0), Color(0.9, 1.0, 0.95), 1.6, 10.0, 0.0, "lift", true)
	_P("F09_rusty_oil_barrel", -4.6, -35.2)
	_P("F07_cardboard_box_stack_v2", 4.5, -35.6, 20)

# ---------------------------------------------------------------- navmesh / env
func _build_nav() -> void:
	nav = NavigationRegion3D.new()
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nm.geometry_source_group_name = &"navsource"
	nm.agent_radius = 0.5
	nm.agent_height = 1.25
	nm.agent_max_climb = 0.25
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	nav.navigation_mesh = nm
	add_child(nav)
	nav.bake_navigation_mesh(false)

func nav_polys() -> int:
	return nav.navigation_mesh.get_polygon_count()

func _build_env() -> void:
	var we := WorldEnvironment.new()
	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.015, 0.02, 0.035)
	sm.sky_horizon_color = Color(0.06, 0.07, 0.1)
	sm.ground_bottom_color = Color(0.02, 0.02, 0.03)
	sm.ground_horizon_color = Color(0.06, 0.07, 0.1)
	sky.sky_material = sm
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.2, 0.22, 0.28)
	_env.ambient_light_energy = 0.55
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.fog_enabled = true
	_env.fog_light_color = Color(0.035, 0.04, 0.055)
	_env.fog_density = 0.018
	_env.glow_enabled = true
	_env.glow_intensity = 0.7
	_env.glow_bloom = 0.08
	_env.adjustment_enabled = true
	_env.adjustment_contrast = 1.12
	_env.adjustment_saturation = 0.85
	we.environment = _env
	add_child(we)
	_moon = DirectionalLight3D.new()
	_moon.light_color = Color(0.5, 0.6, 0.9)
	_moon.light_energy = 0.28
	_moon.rotation_degrees = Vector3(-52, 25, 0)
	_moon.shadow_enabled = true
	_moon.directional_shadow_max_distance = 24.0
	add_child(_moon)
	# baarish
	_rain = GPUParticles3D.new()
	_rain.amount = 700
	_rain.lifetime = 0.9
	_rain.visibility_aabb = AABB(Vector3(-20, -14, -20), Vector3(40, 28, 40))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(13, 0.1, 13)
	pm.direction = Vector3(0.12, -1, 0)
	pm.spread = 3.0
	pm.initial_velocity_min = 16.0
	pm.initial_velocity_max = 20.0
	pm.gravity = Vector3(0, -6, 0)
	pm.particle_flag_align_y = true
	_rain.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.014, 0.55)
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(0.7, 0.8, 1.0, 0.35)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.material = rm
	_rain.draw_pass_1 = qm
	add_child(_rain)
	_rain_snd = AudioStreamPlayer.new()
	_rain_snd.stream = Sfx.get_sound("rain")
	_rain_snd.volume_db = -60.0
	add_child(_rain_snd)
	_rain_snd.play()
	var hum := AudioStreamPlayer.new()
	hum.stream = Sfx.get_sound("hum")
	hum.volume_db = -24.0
	add_child(hum)
	hum.play()

# ---------------------------------------------------------------- events
func _process(delta: float) -> void:
	if player == null or _ended:
		return
	_update_visibility()
	var z := zone_of(player.global_position)
	# baarish sirf yard mein
	var in_yard := z == "yard"
	_rain.global_position = player.global_position + Vector3(0, 11, 0)
	_rain.emitting = in_yard
	_rain_snd.volume_db = lerpf(_rain_snd.volume_db, -12.0 if in_yard else -34.0, 1.0 - exp(-2.0 * delta))
	# bijli
	_thunder_t -= delta
	if _thunder_t <= 0.0:
		_thunder_t = randf_range(14.0, 30.0)
		_lightning()
	# events
	var pp := player.global_position
	if not flags.get("entered", false) and pp.z < 0.4 and pp.x > -1.2 and pp.x < 1.2 and zone_of(pp) == "reception":
		flags["entered"] = true
		door_entry.close(true)
		door_entry.locked = true
		door_entry.lock_msg = Tr.t("The door is stuck — there's no going back.")
		for l in get_tree().get_nodes_in_group("lamps"):
			if l.zone == "reception":
				l.blackout(0.8)
		Aud.play2d(self, "stinger", -8.0)
		hud.subtitle(Tr.t("Neha: The door shut by itself…? I need to find the key."), 4.5)
		hud.objective(Story.obj_key())
		checkpoint(Story.obj_key())
	if flags.get("entered", false) and not flags.get("key_taken", false) and player.has_item("key_hall"):
		flags["key_taken"] = true
		hud.objective(Story.obj_hall())
		hud.subtitle(Tr.t("Neha: This is the key to the hall."), 3.0)
		checkpoint(Story.obj_hall())
	if not flags.get("hall_entered", false) and zone_of(pp) == "hall" and pp.z < -11.0:
		flags["hall_entered"] = true
		for l in get_tree().get_nodes_in_group("lamps"):
			if l.zone == "hall_em":
				l.blackout(0.9)
		Aud.play2d(self, "stinger", -4.0)
		hud.subtitle(Tr.t("Neha: That doll… did it just move? Keep the light on it."), 5.0)
		hud.objective(Story.obj_fuse())
		checkpoint(Story.obj_fuse())
		get_tree().create_timer(6.0).timeout.connect(func(): gud.activate())
	if flags.get("hall_entered", false) and not flags.get("fuse_taken", false) and player.has_item("fuse"):
		flags["fuse_taken"] = true
		hud.objective(Story.obj_gen())
		hud.subtitle(Tr.t("Neha: Got the fuse. The generator room… to the west."), 4.0)
		checkpoint(Story.obj_gen())

func _lightning() -> void:
	var tw := create_tween()
	tw.tween_property(_moon, "light_energy", 2.2, 0.05)
	tw.tween_property(_moon, "light_energy", 0.4, 0.08)
	tw.tween_property(_moon, "light_energy", 1.8, 0.06)
	tw.tween_property(_moon, "light_energy", 0.28, 0.5)
	get_tree().create_timer(randf_range(0.6, 1.8)).timeout.connect(func(): Aud.play2d(self, "thunder", -8.0))

# ---------------------------------------------------------------- fuse / power / lift
func _fuse_prompt(p) -> String:
	if flags.get("power", false):
		return ""
	return Tr.t("Insert fuse") if p.has_item("fuse") else Tr.t("Fuse box — the fuse is missing")

func _fuse_use(p) -> void:
	if flags.get("power", false):
		return
	if not p.has_item("fuse"):
		hud.toast(Tr.t("The fuse is missing. Try the paint room."))
		Aud.play2d(p, "door_locked", -6.0)
		return
	p.use_item("fuse")
	Aud.play2d(p, "fuse_in", -2.0)
	flags["power"] = true
	_power_on(false)

func _power_on(silent: bool) -> void:
	for nm in ["hall", "gen", "lift", "paint"]:
		set_zone_power(nm, true)
	(_fuse_led.material_override as StandardMaterial3D).albedo_color = Color(0.1, 1.0, 0.2)
	(_fuse_led.material_override as StandardMaterial3D).emission = Color(0.1, 1.0, 0.2)
	_gen_snd.volume_db = -4.0
	if not _gen_snd.playing:
		_gen_snd.play()
	door_lift.locked = false
	gud.walk_speed = 3.15
	hud.objective(Story.obj_lift())
	if not silent:
		Aud.play2d(self, "power_up", -4.0)
		hud.flash(0.6)
		hud.subtitle(Tr.t("Neha: Power's back! The lift — hurry! She's faster now!"), 5.0)
		checkpoint(Story.obj_lift())

func _lift_prompt(p) -> String:
	if _ended:
		return ""
	return Tr.t("Enter lift") if flags.get("power", false) else Tr.t("Lift offline — no power")

func _lift_use(p) -> void:
	if not flags.get("power", false):
		hud.toast(Tr.t("The lift has no power."))
		Aud.play2d(p, "door_locked", -6.0)
		return
	_ended = true
	p.frozen = true
	gud.state = Gudiya.S.DORMANT
	Aud.play2d(self, "door_slam", -2.0)
	hud.fade_to(1.0, 2.0)
	await get_tree().create_timer(2.4).timeout
	hud.show_end(Story.end_t(), Story.end_b())
	chapter_end.emit()
