extends SceneTree
# Sab game/*.gd load karke parse errors dikhao. Naye class_name ke baad pehle: godot --headless --path horror_city --import
func _init():
	var bad := 0
	var d := DirAccess.open("res://game")
	for f in d.get_files():
		if f.ends_with(".gd"):
			var s = load("res://game/" + f)
			if s == null or not (s as GDScript).can_instantiate():
				print("LINT FAIL ", f)
				bad += 1
	print("LINT done bad=", bad)
	quit()
