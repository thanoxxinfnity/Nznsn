class_name Hud
extends Control
# Mobile touch HUD: left joystick, right buttons, camera drag, radar, mission text.

var hp := 100.0
var money := 0
var title := ""
var text := ""
var toast := ""
var toast_t := 0.0
var radar: Array = []
var in_car := false
var stars := 0
var load_frac := 0.0
var help_t := 14.0
var joy_id := -1
var joy_vec := Vector2.ZERO
var look_id := -1
var btn_ids := {}
var prev_keys := {}
var font: Font

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    font = ThemeDB.fallback_font

func vp() -> Vector2:
    return get_viewport_rect().size

func joy_center() -> Vector2:
    return Vector2(200, vp().y - 170)

const JOY_R := 120.0

func buttons() -> Dictionary:
    var v := vp()
    return {
        "JUMP": [Vector2(v.x - 130, v.y - 130), 74.0],
        "BLAST": [Vector2(v.x - 300, v.y - 95), 66.0],
        "CAR": [Vector2(v.x - 105, v.y - 300), 58.0],
    }

func show_toast(t: String) -> void:
    toast = t
    toast_t = 3.0

func _input(e: InputEvent) -> void:
    if load_frac < 1.0:
        return
    if e is InputEventScreenTouch:
        var ev := e as InputEventScreenTouch
        if ev.pressed:
            var hit := ""
            for k in buttons():
                var b: Array = buttons()[k]
                if ev.position.distance_to(b[0]) <= float(b[1]) + 14.0:
                    hit = k
            if hit != "":
                btn_ids[ev.index] = hit
                match hit:
                    "JUMP": Ctl.jump = true
                    "BLAST": Ctl.bomb = true
                    "CAR": Ctl.act = true
            elif ev.position.x < vp().x * 0.45 and joy_id == -1:
                joy_id = ev.index
                _joy(ev.position)
            elif look_id == -1:
                look_id = ev.index
        else:
            if ev.index == joy_id:
                joy_id = -1
                joy_vec = Vector2.ZERO
            if ev.index == look_id:
                look_id = -1
            btn_ids.erase(ev.index)
    elif e is InputEventScreenDrag:
        var dv := e as InputEventScreenDrag
        if dv.index == joy_id:
            _joy(dv.position)
        elif dv.index == look_id:
            Ctl.look += dv.relative

func _joy(p: Vector2) -> void:
    var v := (p - joy_center()) / JOY_R
    joy_vec = v.limit_length(1.0)

func _key(k: Key) -> bool:
    return Input.is_physical_key_pressed(k)

func _edge(k: Key) -> bool:
    var now := _key(k)
    var was: bool = prev_keys.get(k, false)
    prev_keys[k] = now
    return now and not was

func _process(delta: float) -> void:
    var kv := Vector2(float(_key(KEY_D) or _key(KEY_RIGHT)) - float(_key(KEY_A) or _key(KEY_LEFT)),
        float(_key(KEY_S) or _key(KEY_DOWN)) - float(_key(KEY_W) or _key(KEY_UP)))
    if not Ctl.auto:
        Ctl.move = joy_vec if joy_id != -1 else kv.limit_length(1.0)
    if _edge(KEY_SPACE): Ctl.jump = true
    if _edge(KEY_B) or _edge(KEY_F): Ctl.bomb = true
    if _edge(KEY_E): Ctl.act = true
    toast_t = maxf(0.0, toast_t - delta)
    help_t = maxf(0.0, help_t - delta)
    queue_redraw()

func _star(c: Vector2, r: float, filled: bool) -> void:
    var pts := PackedVector2Array()
    for i in 10:
        var a := -PI / 2.0 + i * PI / 5.0
        var rr := r if i % 2 == 0 else r * 0.45
        pts.append(c + Vector2(cos(a), sin(a)) * rr)
    draw_colored_polygon(pts, Color(1.0, 0.85, 0.1) if filled else Color(1, 1, 1, 0.18))

func _txt(t: String, pos: Vector2, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
    draw_string(font, pos + Vector2(2, 2), t, align, w, size, Color(0, 0, 0, 0.8))
    draw_string(font, pos, t, align, w, size, col)

func _draw() -> void:
    var v := vp()
    if load_frac < 1.0:
        draw_rect(Rect2(Vector2.ZERO, v), Color(0.05, 0.07, 0.12))
        _txt("BLOCK CITY", Vector2(0, v.y * 0.4), 64, Color(1, 0.85, 0.3), HORIZONTAL_ALIGNMENT_CENTER, v.x)
        _txt("Duniya ban rahi hai... %d%%" % int(load_frac * 100.0), Vector2(0, v.y * 0.4 + 60), 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, v.x)
        draw_rect(Rect2(v.x * 0.3, v.y * 0.4 + 90, v.x * 0.4, 16), Color(1, 1, 1, 0.15))
        draw_rect(Rect2(v.x * 0.3, v.y * 0.4 + 90, v.x * 0.4 * load_frac, 16), Color(1, 0.85, 0.3))
        return
    # joystick
    var jc := joy_center()
    draw_circle(jc, JOY_R, Color(1, 1, 1, 0.10))
    draw_arc(jc, JOY_R, 0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
    draw_circle(jc + joy_vec * JOY_R * 0.8, 52.0, Color(1, 1, 1, 0.32))
    # buttons
    var labels := {"JUMP": "JUMP", "BLAST": "BLAST", "CAR": ("EXIT" if in_car else "CAR")}
    for k in buttons():
        var b: Array = buttons()[k]
        var pressed: bool = k in btn_ids.values()
        var col := Color(1.0, 0.3, 0.15, 0.45) if k == "BLAST" else Color(1, 1, 1, 0.22)
        if pressed:
            col.a += 0.25
        draw_circle(b[0], float(b[1]), col)
        draw_arc(b[0], float(b[1]), 0, TAU, 40, Color(1, 1, 1, 0.5), 3.0)
        _txt(labels[k], b[0] + Vector2(-float(b[1]), 9), 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, float(b[1]) * 2.0)
    # hp + money
    draw_rect(Rect2(24, 20, 264, 26), Color(0, 0, 0, 0.5))
    draw_rect(Rect2(26, 22, 260.0 * hp / 100.0, 22), Color(0.3, 0.85, 0.3).lerp(Color(0.9, 0.2, 0.2), 1.0 - hp / 100.0))
    _txt("HP", Vector2(34, 42), 20, Color.WHITE)
    _txt("$ %d" % money, Vector2(24, 88), 34, Color(0.5, 1.0, 0.5))
    for i in 3:
        _star(Vector2(38 + i * 36, 124), 15.0, i < stars)
    # mission
    if title != "":
        _txt(title, Vector2(0, 40), 26, Color(1, 0.9, 0.3), HORIZONTAL_ALIGNMENT_CENTER, v.x)
        _txt(text, Vector2(0, 74), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, v.x)
    # radar
    var rc := Vector2(v.x - 110, 112)
    draw_circle(rc, 84.0, Color(0, 0, 0, 0.45))
    draw_arc(rc, 84.0, 0, TAU, 40, Color(1, 1, 1, 0.5), 2.0)
    for it in radar:
        var p: Vector2 = it[0]
        if p.length() > 1.0:
            p = p.normalized()
        draw_circle(rc + p * 80.0, 5.0, it[1])
    draw_circle(rc, 5.0, Color.WHITE)
    draw_line(rc, rc + Vector2(0, -14), Color.WHITE, 2.0)
    _txt("FPS %d" % int(Engine.get_frames_per_second()), Vector2(v.x * 0.5 - 40, v.y - 16), 18, Color(1, 1, 1, 0.45))
    # toast
    if toast_t > 0.0:
        var a := clampf(toast_t, 0.0, 1.0)
        _txt(toast, Vector2(0, v.y * 0.3), 38, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, v.x)
    if help_t > 0.0:
        _txt("Baayein: chalo | Daayein drag: dekho | BLAST: bam fenko (dabbe udte hain!) | CAR: gaadi", Vector2(24, v.y - 18), 20, Color(1, 1, 1, clampf(help_t / 3.0, 0.0, 0.9)))
