class_name Ctl
extends RefCounted
# Sab input (touch + keyboard) yahan aata hai; Player yahin se padhta hai.
static var move := Vector2.ZERO   # x=daayein, y=peeche
static var look := Vector2.ZERO   # camera drag (pixel); player padhke zero karta hai
static var run := false
static var crouch := false
static var use_p := false         # ek baar (consume)
static var torch_p := false       # ek baar (consume)
static var auto := false          # test mode: HUD move ko overwrite na kare

static func take_use() -> bool:
	var v := use_p
	use_p = false
	return v

static func take_torch() -> bool:
	var v := torch_p
	torch_p = false
	return v
