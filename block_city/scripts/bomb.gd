class_name Bomb
extends Node3D
# Hathgola: faikne par udta hai, kisi dabbe se takrate hi phatta hai.

signal exploded(pos: Vector3)
var vel := Vector3.ZERO
var world: VoxelWorld
var life := 3.5

func _ready() -> void:
    Blocky.box(self, Vector3(0.34, 0.34, 0.34), Vector3.ZERO, Color(0.08, 0.08, 0.1))
    Blocky.box(self, Vector3(0.14, 0.14, 0.14), Vector3(0, 0.24, 0), Color(1.0, 0.25, 0.1))

func _physics_process(delta: float) -> void:
    life -= delta
    vel.y -= 22.0 * delta
    var nxt := global_position + vel * delta
    if world.solid_at(nxt) or life <= 0.0 or nxt.y < 0.5:
        exploded.emit(global_position)
        queue_free()
        return
    global_position = nxt
    rotate_x(delta * 9.0)
