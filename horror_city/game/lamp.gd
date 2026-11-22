class_name Lamp
extends OmniLight3D
# Jhilmilati/band hone wali batti. zone = power-zone ka naam; Level.set_zone_power() se on/off.
var base_energy := 1.0
var flicker := 0.0       # 0 = steady, 1 = bahut jhilmil
var zone := ""
var bulb: MeshInstance3D
var powered := true
var _t := 0.0
var _off_until := 0.0
var _seed := randf() * 100.0

func _ready() -> void:
	shadow_enabled = false
	add_to_group("lamps")
	_apply(base_energy)

func set_powered(on: bool) -> void:
	powered = on
	_apply(base_energy if on else 0.0)

func blackout(sec: float) -> void:
	_off_until = _t + sec

func _apply(e: float) -> void:
	light_energy = e
	if bulb and bulb.material_override:
		var m := bulb.material_override as StandardMaterial3D
		m.emission_energy_multiplier = 3.0 * (e / maxf(base_energy, 0.001))

func _process(delta: float) -> void:
	_t += delta
	if not powered:
		return
	if _t < _off_until:
		_apply(0.0)
		return
	if flicker <= 0.0:
		_apply(base_energy)
		return
	var n := sin(_t * 17.0 + _seed) * sin(_t * 5.3 + _seed * 2.0) + sin(_t * 41.0 + _seed)
	var cut := 1.55 - flicker * 0.9
	_apply(base_energy * (0.12 if n > cut else 1.0 - 0.15 * flicker * absf(sin(_t * 9.0 + _seed))))
