class_name Hud
extends CanvasLayer
# Touch HUD: bayein joystick, daayein buttons (USE, TORCH, RUN, CROUCH), dekhne ke liye swipe, darr ka overlay, dairy, maut/jeet screen.
signal retry_pressed
signal continue_pressed
signal pause_pressed

var player: Player
var font: Font
var root: Control
var touch: Control        # draw + input
var fear_rect: ColorRect
var fear_mat: ShaderMaterial
var fade_rect: ColorRect
var prompt_lbl: Label
var toast_lbl: Label
var sub_lbl: Label
var obj_lbl: Label
var items_lbl: Label
var note_panel: PanelContainer
var note_title: Label
var note_body: Label
var death_box: Control
var end_box: Control
var end_title: Label
var end_body: Label
var load_box: Control
var load_lbl: Label

var joy_id := -1
var joy_start := Vector2.ZERO
var joy_vec := Vector2.ZERO
var look_id := -1
var look_last := Vector2.ZERO
var btn_ids := {}
var crouch_on := false
var _toast_t := 0.0
var _sub_t := 0.0
var _flash := 0.0
var _hide := 0.0
var _hide_target := 0.0
var _t := 0.0
var note_open := false

func _ready() -> void:
	layer = 10
	font = load("res://assets/fonts/FreeSans.ttf")
	var th := Theme.new()
	th.default_font = font
	th.default_font_size = 26
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = th
	add_child(root)
	# darr overlay
	fear_rect = ColorRect.new()
	fear_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fear_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fear_mat = ShaderMaterial.new()
	fear_mat.shader = load("res://game/fear.gdshader")
	fear_rect.material = fear_mat
	root.add_child(fear_rect)
	# touch layer
	touch = Control.new()
	touch.set_anchors_preset(Control.PRESET_FULL_RECT)
	touch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch.draw.connect(_draw_touch)
	root.add_child(touch)
	prompt_lbl = _label(30, Color(1, 1, 0.9))
	_place(prompt_lbl, 0.5, 1.0, -300, -230, 300, -185)
	prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_lbl = _label(28, Color(1, 0.95, 0.7))
	_place(toast_lbl, 0.5, 0.0, -400, 70, 400, 112)
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl = _label(28, Color(0.95, 0.92, 0.85))
	_place(sub_lbl, 0.5, 1.0, -460, -170, 460, -90)
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	obj_lbl = _label(24, Color(0.85, 0.85, 0.7))
	obj_lbl.position = Vector2(24, 18)
	obj_lbl.size = Vector2(640, 60)
	obj_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	items_lbl = _label(22, Color(0.8, 0.8, 0.8))
	items_lbl.position = Vector2(24, 86)
	items_lbl.size = Vector2(500, 120)
	# diary
	note_panel = PanelContainer.new()
	note_panel.visible = false
	_place(note_panel, 0.5, 0.5, -380, -230, 380, 230)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.93, 0.87, 0.72, 0.96)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 22
	sb.content_margin_bottom = 22
	note_panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	note_panel.add_child(vb)
	note_title = Label.new()
	note_title.add_theme_color_override("font_color", Color(0.25, 0.1, 0.05))
	note_title.add_theme_font_size_override("font_size", 30)
	vb.add_child(note_title)
	note_body = Label.new()
	note_body.add_theme_color_override("font_color", Color(0.15, 0.1, 0.08))
	note_body.add_theme_font_size_override("font_size", 24)
	note_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_body.custom_minimum_size = Vector2(700, 280)
	vb.add_child(note_body)
	var cb := Button.new()
	cb.text = "ठीक है"
	cb.pressed.connect(close_note)
	vb.add_child(cb)
	root.add_child(note_panel)
	# fade
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade_rect)
	# maut
	death_box = Control.new()
	death_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_box.visible = false
	var dr := ColorRect.new()
	dr.color = Color(0.03, 0, 0, 0.88)
	dr.set_anchors_preset(Control.PRESET_FULL_RECT)
	death_box.add_child(dr)
	var dl := Label.new()
	dl.text = "तुम पकड़ी गईं…"
	dl.add_theme_font_size_override("font_size", 56)
	dl.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))
	_place(dl, 0.5, 0.5, -300, -120, 300, -40)
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_box.add_child(dl)
	var rb := Button.new()
	rb.text = "फिर से कोशिश करो"
	_place(rb, 0.5, 0.5, -150, 0, 150, 70)
	rb.add_theme_font_size_override("font_size", 28)
	rb.pressed.connect(func(): retry_pressed.emit())
	death_box.add_child(rb)
	root.add_child(death_box)
	# end card
	end_box = Control.new()
	end_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_box.visible = false
	var er := ColorRect.new()
	er.color = Color(0, 0, 0, 0.94)
	er.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_box.add_child(er)
	end_title = Label.new()
	end_title.add_theme_font_size_override("font_size", 50)
	end_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	_place(end_title, 0.5, 0.0, -450, 120, 450, 200)
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_box.add_child(end_title)
	end_body = Label.new()
	end_body.add_theme_font_size_override("font_size", 28)
	end_body.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_place(end_body, 0.5, 0.0, -420, 230, 420, 530)
	end_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_box.add_child(end_body)
	var eb := Button.new()
	eb.text = "आगे"
	_place(eb, 0.5, 1.0, -120, -140, 120, -76)
	eb.add_theme_font_size_override("font_size", 28)
	eb.pressed.connect(func(): continue_pressed.emit())
	end_box.add_child(eb)
	root.add_child(end_box)
	# loading
	load_box = Control.new()
	load_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	var lr := ColorRect.new()
	lr.color = Color.BLACK
	lr.set_anchors_preset(Control.PRESET_FULL_RECT)
	load_box.add_child(lr)
	load_lbl = Label.new()
	load_lbl.text = "खिलौना नगर…"
	load_lbl.add_theme_font_size_override("font_size", 40)
	_place(load_lbl, 0.5, 0.5, -300, -30, 300, 30)
	load_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	load_box.add_child(load_lbl)
	root.add_child(load_box)

func _place(c: Control, ax: float, ay: float, l: float, t: float, r: float, b: float) -> void:
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = l
	c.offset_top = t
	c.offset_right = r
	c.offset_bottom = b

func _label(sz: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(l)
	return l

func vp() -> Vector2:
	return root.get_viewport_rect().size

func joy_center() -> Vector2:
	return Vector2(190, vp().y - 170)

func buttons() -> Dictionary:
	var v := vp()
	return {
		"USE": [Vector2(v.x - 150, v.y - 150), 78.0],
		"TORCH": [Vector2(v.x - 330, v.y - 105), 58.0],
		"RUN": [Vector2(v.x - 110, v.y - 330), 56.0],
		"CROUCH": [Vector2(v.x - 290, v.y - 250), 50.0],
		"PAUSE": [Vector2(v.x * 0.5, 44), 30.0],
	}

func _draw_touch() -> void:
	if load_box.visible or end_box.visible or death_box.visible:
		return
	var c := joy_center()
	touch.draw_circle(c, 120.0, Color(1, 1, 1, 0.07))
	touch.draw_arc(c, 120.0, 0, TAU, 48, Color(1, 1, 1, 0.22), 3.0)
	touch.draw_circle(c + joy_vec * 80.0, 46.0, Color(1, 1, 1, 0.2))
	var b := buttons()
	for k in b:
		var pos: Vector2 = b[k][0]
		var r: float = b[k][1]
		var on: bool = btn_ids.values().has(k) or (k == "CROUCH" and crouch_on) or (k == "TORCH" and player and player.torch_on)
		touch.draw_circle(pos, r, Color(1, 1, 1, 0.22 if on else 0.09))
		touch.draw_arc(pos, r, 0, TAU, 40, Color(1, 1, 1, 0.3), 2.5)
		var txt: String = {"USE": "खोलो", "TORCH": "टॉर्च", "RUN": "दौड़ो", "CROUCH": "झुको", "PAUSE": "II"}[k]
		var fs := 26 if k == "USE" else 21
		var sz := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		touch.draw_string(font, pos + Vector2(-sz.x / 2.0, fs * 0.35), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.8))
	# battery + stamina
	if player:
		var x := vp().x - 270.0
		touch.draw_rect(Rect2(x, 28, 220, 14), Color(0, 0, 0, 0.5))
		var bat: float = player.battery / 100.0
		touch.draw_rect(Rect2(x, 28, 220.0 * bat, 14), Color(1.0, 0.85, 0.4) if bat > 0.2 else Color(1, 0.2, 0.1))
		touch.draw_string(font, Vector2(x, 24), "बैटरी", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.7))
		touch.draw_rect(Rect2(x, 62, 220, 8), Color(0, 0, 0, 0.5))
		touch.draw_rect(Rect2(x, 62, 220.0 * player.stamina, 8), Color(0.5, 0.8, 1.0, 0.8))

func _hit_button(pos: Vector2) -> String:
	var b := buttons()
	for k in b:
		if pos.distance_to(b[k][0]) <= float(b[k][1]) + 14.0:
			return k
	return ""

func _input(e: InputEvent) -> void:
	if load_box.visible or end_box.visible or death_box.visible:
		return
	if note_open:
		if e is InputEventKey and (e as InputEventKey).pressed:
			close_note()
		return
	if e is InputEventScreenTouch:
		var ev := e as InputEventScreenTouch
		if ev.pressed:
			var hit := _hit_button(ev.position)
			if hit != "":
				btn_ids[ev.index] = hit
				match hit:
					"PAUSE": pause_pressed.emit()
					"USE": Ctl.use_p = true
					"TORCH": Ctl.torch_p = true
					"RUN": Ctl.run = true
					"CROUCH":
						crouch_on = not crouch_on
						Ctl.crouch = crouch_on
			elif ev.position.x < vp().x * 0.45 and joy_id == -1:
				joy_id = ev.index
				joy_start = joy_center()
				_joy(ev.position)
			elif look_id == -1:
				look_id = ev.index
				look_last = ev.position
		else:
			if ev.index == joy_id:
				joy_id = -1
				joy_vec = Vector2.ZERO
				if not Ctl.auto:
					Ctl.move = Vector2.ZERO
			elif ev.index == look_id:
				look_id = -1
			if btn_ids.has(ev.index):
				if btn_ids[ev.index] == "RUN":
					Ctl.run = false
				btn_ids.erase(ev.index)
	elif e is InputEventScreenDrag:
		var ed := e as InputEventScreenDrag
		if ed.index == joy_id:
			_joy(ed.position)
		elif ed.index == look_id:
			Ctl.look += ed.relative
	elif e is InputEventKey and (e as InputEventKey).pressed and not (e as InputEventKey).echo:
		match (e as InputEventKey).keycode:
			KEY_E, KEY_ENTER: Ctl.use_p = true
			KEY_F: Ctl.torch_p = true

func _joy(pos: Vector2) -> void:
	var d := (pos - joy_start) / 110.0
	joy_vec = d.limit_length(1.0)
	if not Ctl.auto:
		Ctl.move = joy_vec
		if joy_vec.length() < 0.12:
			Ctl.move = Vector2.ZERO

func toast(t: String, secs := 3.0) -> void:
	toast_lbl.text = t
	_toast_t = secs

func subtitle(t: String, secs := 4.0) -> void:
	sub_lbl.text = t
	_sub_t = secs

func objective(t: String) -> void:
	obj_lbl.text = "▸ " + t

func set_prompt(t: String) -> void:
	prompt_lbl.text = t

func set_hidden(b: bool) -> void:
	_hide_target = 1.0 if b else 0.0

func flash(v := 1.0) -> void:
	_flash = v

func show_note(title: String, text: String) -> void:
	note_title.text = title
	note_body.text = text
	note_panel.visible = true
	note_open = true
	if player:
		player.frozen = true

func close_note() -> void:
	note_panel.visible = false
	note_open = false
	if player and not player.hidden and not player.dead:
		player.frozen = false

func show_death() -> void:
	death_box.visible = true
	if player:
		player.frozen = true

func show_end(title: String, body: String) -> void:
	end_title.text = title
	end_body.text = body
	end_box.visible = true

func fade_to(a: float, secs: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", a, secs)

func loaded() -> void:
	load_box.visible = false

func _process(delta: float) -> void:
	_t += delta
	_hide = lerpf(_hide, _hide_target, 1.0 - exp(-8.0 * delta))
	_flash = maxf(0.0, _flash - delta * 2.5)
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t <= 0.0:
			toast_lbl.text = ""
	if _sub_t > 0.0:
		_sub_t -= delta
		if _sub_t <= 0.0:
			sub_lbl.text = ""
	var f := 0.0
	if player:
		f = player.fear
		if player.battery < 20.0:
			f = maxf(f, 0.15)
		var parts := []
		for k in player.items:
			if player.items[k] > 0:
				parts.append(Story.item_name(k))
		items_lbl.text = ("सामान: " + ", ".join(parts)) if parts.size() > 0 else ""
	fear_mat.set_shader_parameter("fear", f)
	fear_mat.set_shader_parameter("hide_amt", _hide)
	fear_mat.set_shader_parameter("flash", _flash)
	fear_mat.set_shader_parameter("t", _t)
	touch.queue_redraw()
