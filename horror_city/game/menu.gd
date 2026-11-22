class_name Menu
extends Control
# Title menu, pause menu, settings. Hud ke upar chalta hai; pause mein process_mode ALWAYS.
signal start_new
signal start_continue
signal resumed
signal to_title
signal quit_game

var font: Font
var title_box: Control
var pause_box: Control
var settings_box: Control
var cont_btn: Button
var _from_pause := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fit()
	get_viewport().size_changed.connect(_fit)
	font = load("res://assets/fonts/FreeSans.ttf")
	var th := Theme.new()
	th.default_font = font
	th.default_font_size = 30
	theme = th
	title_box = _make_title()
	pause_box = _make_pause()
	settings_box = _make_settings()
	add_child(title_box)
	add_child(pause_box)
	add_child(settings_box)
	title_box.visible = false
	pause_box.visible = false
	settings_box.visible = false

func _fit() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size

func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(380, 74)
	b.add_theme_font_size_override("font_size", 32)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.05, 0.05, 0.85)
	sb.border_color = Color(0.6, 0.15, 0.1)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	b.add_theme_stylebox_override("normal", sb)
	var sh := sb.duplicate() as StyleBoxFlat
	sh.bg_color = Color(0.3, 0.08, 0.06, 0.95)
	b.add_theme_stylebox_override("hover", sh)
	b.add_theme_stylebox_override("pressed", sh)
	b.pressed.connect(cb)
	return b

func _full_bg(c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = c
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	return r

func _center_box() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.anchor_left = 0.5
	v.anchor_right = 0.5
	v.anchor_top = 0.5
	v.anchor_bottom = 0.5
	v.offset_left = -220
	v.offset_right = 220
	v.offset_top = -190
	v.offset_bottom = 230
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.add_theme_constant_override("separation", 16)
	return v

func _make_title() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(_full_bg(Color(0.02, 0.0, 0.0, 1.0)))
	var t := Label.new()
	t.text = "खिलौना नगर"
	t.add_theme_font_size_override("font_size", 92)
	t.add_theme_color_override("font_color", Color(0.85, 0.12, 0.08))
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	t.add_theme_constant_override("shadow_offset_x", 4)
	t.add_theme_constant_override("shadow_offset_y", 4)
	t.anchor_left = 0.5
	t.anchor_right = 0.5
	t.offset_left = -500
	t.offset_right = 500
	t.offset_top = 40
	t.offset_bottom = 170
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(t)
	var sub := Label.new()
	sub.text = "अध्याय 1 — रंगीला टॉयज़"
	sub.add_theme_font_size_override("font_size", 28)
	sub.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	sub.anchor_left = 0.5
	sub.anchor_right = 0.5
	sub.offset_left = -400
	sub.offset_right = 400
	sub.offset_top = 165
	sub.offset_bottom = 210
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(sub)
	var v := _center_box()
	v.offset_top = -90
	v.offset_bottom = 300
	cont_btn = _btn("जारी रखो", func(): start_continue.emit())
	v.add_child(cont_btn)
	v.add_child(_btn("नया खेल", func(): start_new.emit()))
	v.add_child(_btn("सेटिंग्स", func(): _open_settings(false)))
	v.add_child(_btn("बाहर", func(): quit_game.emit()))
	c.add_child(v)
	return c

func _make_pause() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(_full_bg(Color(0, 0, 0, 0.72)))
	var l := Label.new()
	l.text = "रुका हुआ"
	l.add_theme_font_size_override("font_size", 56)
	l.anchor_left = 0.5
	l.anchor_right = 0.5
	l.offset_left = -300
	l.offset_right = 300
	l.offset_top = 60
	l.offset_bottom = 150
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(l)
	var v := _center_box()
	v.offset_top = -120
	v.offset_bottom = 260
	v.add_child(_btn("खेल जारी रखो", func(): hide_pause(); resumed.emit()))
	v.add_child(_btn("सेटिंग्स", func(): _open_settings(true)))
	v.add_child(_btn("मुख्य मेनू", func(): to_title.emit()))
	c.add_child(v)
	return c

func _make_settings() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(_full_bg(Color(0.02, 0.0, 0.0, 0.96)))
	var l := Label.new()
	l.text = "सेटिंग्स"
	l.add_theme_font_size_override("font_size", 52)
	l.anchor_left = 0.5
	l.anchor_right = 0.5
	l.offset_left = -300
	l.offset_right = 300
	l.offset_top = 40
	l.offset_bottom = 120
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(l)
	var v := VBoxContainer.new()
	v.anchor_left = 0.5
	v.anchor_right = 0.5
	v.anchor_top = 0.0
	v.offset_left = -330
	v.offset_right = 330
	v.offset_top = 140
	v.offset_bottom = 560
	v.add_theme_constant_override("separation", 14)
	v.add_child(_row("देखने की संवेदनशीलता", 0.4, 2.2, Settings.sens, func(x): Settings.sens = x))
	v.add_child(_row("आवाज़", 0.0, 1.0, Settings.volume, func(x): Settings.volume = x; AudioServer.set_bus_volume_db(0, linear_to_db(maxf(x, 0.0001)))))
	var ql := Label.new()
	ql.text = "ग्राफ़िक्स क्वालिटी"
	v.add_child(ql)
	var ob := OptionButton.new()
	ob.add_item("कम (तेज़ फ़ोन)", 0)
	ob.add_item("मध्यम", 1)
	ob.add_item("ऊँची", 2)
	ob.select(Settings.quality)
	ob.custom_minimum_size = Vector2(0, 64)
	ob.item_selected.connect(func(i): Settings.quality = i)
	v.add_child(ob)
	v.add_child(_btn("वापस", func(): _close_settings()))
	c.add_child(v)
	return c

func _row(text: String, mn: float, mx: float, val: float, cb: Callable) -> Control:
	var v := VBoxContainer.new()
	var l := Label.new()
	l.text = text
	v.add_child(l)
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = 0.05
	s.value = val
	s.custom_minimum_size = Vector2(0, 40)
	s.value_changed.connect(cb)
	v.add_child(s)
	return v

func show_title(has_save: bool) -> void:
	title_box.visible = true
	pause_box.visible = false
	settings_box.visible = false
	cont_btn.visible = has_save

func hide_title() -> void:
	title_box.visible = false

func show_pause() -> void:
	pause_box.visible = true
	get_tree().paused = true

func hide_pause() -> void:
	pause_box.visible = false
	get_tree().paused = false

func _open_settings(from_pause: bool) -> void:
	_from_pause = from_pause
	settings_box.visible = true

func _close_settings() -> void:
	settings_box.visible = false
	Settings.save_()
	settings_changed.emit()

signal settings_changed
