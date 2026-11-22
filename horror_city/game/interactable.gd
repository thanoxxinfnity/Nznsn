class_name Interactable
extends StaticBody3D
# Player ki "dekho aur dabao" cheezein: prompt_fn(player)->String ('' = chhupa), handler(player).
var prompt_fn := Callable()
var handler := Callable()
var enabled := true

static func make(parent: Node, pos: Vector3, size: Vector3, prompt_fn_: Callable, handler_: Callable) -> Interactable:
	var it := Interactable.new()
	it.collision_layer = 8
	it.collision_mask = 0
	it.position = pos
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	it.add_child(cs)
	it.prompt_fn = prompt_fn_
	it.handler = handler_
	parent.add_child(it)
	return it

func get_prompt(p) -> String:
	if enabled and prompt_fn.is_valid():
		return prompt_fn.call(p)
	return ""

func interact(p) -> void:
	if enabled and handler.is_valid():
		handler.call(p)
