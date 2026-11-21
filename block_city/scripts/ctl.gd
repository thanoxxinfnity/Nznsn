class_name Ctl
extends RefCounted
# Sab input (touch + keyboard) yahan aata hai; Player/Car yahin se padhte hain.
static var move := Vector2.ZERO    # joystick: x=right, y=down(=peeche)
static var look := Vector2.ZERO    # camera drag (pixels), consumer zero karta hai
static var jump := false
static var bomb := false
static var act := false
static var auto := false    # test mode: HUD Ctl.move ko overwrite na kare
