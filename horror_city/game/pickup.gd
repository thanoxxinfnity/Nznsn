class_name Pickup
extends Node3D
# Uthane wali cheez: prop model + halki chamak. kind: "item" (inventory), "battery", "note".
var item_id := ""
var label := ""
var kind := "item"
var note_title := ""
var note_text := ""
var amount := 1.0
var _light: OmniLight3D
var _inter: Interactable
signal picked(p)

static func make(parent: Node, file: String, pos: Vector3, rot_deg: float, item_id_: String, label_: String, kind_ := "item", sc := 1.0) -> Pickup:
	var pk := Pickup.new()
	pk.item_id = item_id_
	pk.label = label_
	pk.kind = kind_
	pk.position = pos
	parent.add_child(pk)
	Build.prop(pk, file, Vector3.ZERO, rot_deg, sc, false)
	return pk

func _ready() -> void:
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.85, 0.5)
	_light.light_energy = 0.35
	_light.omni_range = 1.4
	_light.position = Vector3(0, 0.25, 0)
	add_child(_light)
	_inter = Interactable.make(self, Vector3(0, 0.15, 0), Vector3(0.6, 0.4, 0.6), func(_p): return "उठाओ: " + label, _take)

func _process(_d: float) -> void:
	var pl = get_tree().get_first_node_in_group("player")
	if pl and _light:
		_light.visible = global_position.distance_to(pl.global_position) < 9.0

func _take(p) -> void:
	Aud.play2d(p, "pickup", -4.0)
	match kind:
		"battery":
			p.add_battery(amount)
		"note":
			p.add_item(item_id)
			if p.hud:
				p.hud.show_note(note_title, note_text)
		_:
			p.add_item(item_id)
			if p.hud:
				p.hud.toast("मिला: " + label)
	picked.emit(p)
	queue_free()
