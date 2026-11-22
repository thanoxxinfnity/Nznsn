class_name Sfx
extends RefCounted
# Saari awaazein code se banti hain (koi audio file nahi). Cache hoti hain.
const RATE := 22050
static var _cache := {}

static func _wav(s: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var b := PackedByteArray()
	b.resize(s.size() * 2)
	for i in s.size():
		b.encode_s16(i * 2, int(clampf(s[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = b
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = s.size()
	return w

static func get_sound(name: String) -> AudioStreamWAV:
	if not _cache.has(name):
		var fn := Callable(Sfx, name)
		_cache[name] = fn.call()
	return _cache[name]

static func _buf(sec: float) -> PackedFloat32Array:
	var s := PackedFloat32Array()
	s.resize(int(RATE * sec))
	return s

static func _rng(seed_: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_
	return r

static func hum() -> AudioStreamWAV:  # bijli ka bhaari hum, loop
	var s := _buf(4.0)
	var r := _rng(1)
	var lp := 0.0
	for i in s.size():
		var t := float(i) / RATE
		lp += (r.randf_range(-1, 1) - lp) * 0.02
		s[i] = sin(TAU * 50.0 * t) * 0.16 + sin(TAU * 100.0 * t) * 0.07 + sin(TAU * 150.0 * t) * 0.03 + lp * 0.35
	return _wav(s, true)

static func rain() -> AudioStreamWAV:
	var s := _buf(3.0)
	var r := _rng(2)
	var lp := 0.0
	for i in s.size():
		lp += (r.randf_range(-1, 1) - lp) * 0.45
		s[i] = lp * 0.5
	return _wav(s, true)

static func generator() -> AudioStreamWAV:
	var s := _buf(2.0)
	var r := _rng(3)
	var lp := 0.0
	for i in s.size():
		var t := float(i) / RATE
		lp += (r.randf_range(-1, 1) - lp) * 0.08
		var pulse := pow(maxf(0.0, sin(TAU * 12.0 * t)), 3.0)
		s[i] = (sin(TAU * 38.0 * t) * 0.35 + lp * 0.4) * (0.55 + 0.45 * pulse)
	return _wav(s, true)

static func heartbeat() -> AudioStreamWAV:  # lub-dub, ek baar
	var s := _buf(0.9)
	for i in s.size():
		var t := float(i) / RATE
		var a := sin(TAU * 62.0 * t) * exp(-t * 22.0)
		var t2 := t - 0.22
		var b := sin(TAU * 52.0 * t2) * exp(-t2 * 26.0) * 0.8 if t2 > 0 else 0.0
		s[i] = (a + b) * 0.9
	return _wav(s)

static func footstep() -> AudioStreamWAV:
	var s := _buf(0.18)
	var r := _rng(4)
	var lp := 0.0
	for i in s.size():
		var t := float(i) / RATE
		lp += (r.randf_range(-1, 1) - lp) * 0.25
		s[i] = (lp * 0.8 + sin(TAU * 90.0 * t) * 0.4) * exp(-t * 28.0)
	return _wav(s)

static func footstep_metal() -> AudioStreamWAV:
	var s := _buf(0.3)
	var r := _rng(5)
	for i in s.size():
		var t := float(i) / RATE
		s[i] = (r.randf_range(-1, 1) * 0.3 * exp(-t * 60.0) + sin(TAU * 420.0 * t) * 0.25 * exp(-t * 14.0) + sin(TAU * 910.0 * t) * 0.12 * exp(-t * 18.0))
	return _wav(s)

static func door_creak() -> AudioStreamWAV:
	var s := _buf(1.2)
	var ph := 0.0
	var r := _rng(6)
	for i in s.size():
		var t := float(i) / RATE
		var f := 180.0 + 120.0 * sin(TAU * 1.7 * t) + 220.0 * t
		ph += TAU * f / RATE
		s[i] = (sin(ph) * 0.18 + sin(ph * 2.01) * 0.1 + r.randf_range(-1, 1) * 0.05) * sin(PI * t / 1.2)
	return _wav(s)

static func door_slam() -> AudioStreamWAV:
	var s := _buf(0.9)
	var r := _rng(7)
	var lp := 0.0
	for i in s.size():
		var t := float(i) / RATE
		lp += (r.randf_range(-1, 1) - lp) * 0.2
		s[i] = lp * 1.6 * exp(-t * 9.0) + sin(TAU * 58.0 * t) * 0.9 * exp(-t * 7.0)
	return _wav(s)

static func door_locked() -> AudioStreamWAV:
	var s := _buf(0.25)
	for i in s.size():
		var t := float(i) / RATE
		s[i] = (sin(TAU * 240.0 * t) * 0.25 + sin(TAU * 610.0 * t) * 0.2) * exp(-t * 26.0) * (1.0 if fmod(t, 0.12) < 0.06 else 0.4)
	return _wav(s)

static func pickup() -> AudioStreamWAV:
	var s := _buf(0.35)
	for i in s.size():
		var t := float(i) / RATE
		var f := 660.0 if t < 0.1 else 880.0
		s[i] = sin(TAU * f * t) * 0.3 * exp(-(t if t < 0.1 else t - 0.1) * 9.0)
	return _wav(s)

static func click() -> AudioStreamWAV:
	var s := _buf(0.08)
	var r := _rng(8)
	for i in s.size():
		var t := float(i) / RATE
		s[i] = (r.randf_range(-1, 1) * 0.4 + sin(TAU * 1500.0 * t) * 0.3) * exp(-t * 90.0)
	return _wav(s)

static func thunder() -> AudioStreamWAV:
	var s := _buf(3.2)
	var r := _rng(9)
	var lp := 0.0
	for i in s.size():
		var t := float(i) / RATE
		lp += (r.randf_range(-1, 1) - lp) * 0.04
		var env := (1.0 - exp(-t * 30.0)) * exp(-t * 1.1)
		s[i] = lp * 3.2 * env + sin(TAU * 34.0 * t) * 0.35 * env
	return _wav(s)

static func stinger() -> AudioStreamWAV:  # jump-scare
	var s := _buf(1.2)
	var r := _rng(10)
	for i in s.size():
		var t := float(i) / RATE
		var env := exp(-t * 3.0)
		s[i] = ((sin(TAU * 311.0 * t) + sin(TAU * 329.6 * t) + sin(TAU * 466.0 * t)) * 0.18 + r.randf_range(-1, 1) * 0.4) * env
	return _wav(s)

static func music_box() -> AudioStreamWAV:  # Gudiya ki lori (original dhun)
	var notes := [659.3, 784.0, 987.8, 784.0, 880.0, 740.0, 659.3, 0.0, 587.3, 740.0, 880.0, 740.0, 784.0, 659.3, 587.3, 0.0]
	var nd := 0.42
	var s := _buf(nd * notes.size())
	for k in notes.size():
		var f: float = notes[k]
		if f == 0.0:
			continue
		for i in int(RATE * nd * 1.6):
			var idx := int(k * nd * RATE) + i
			if idx >= s.size():
				break
			var t := float(i) / RATE
			s[idx] += (sin(TAU * f * t) * 0.3 + sin(TAU * f * 2.756 * t) * 0.12 + sin(TAU * f * 5.4 * t) * 0.05) * exp(-t * 4.5)
	return _wav(s, true)

static func whisper() -> AudioStreamWAV:
	var s := _buf(1.6)
	var r := _rng(11)
	var lp := 0.0
	var lp2 := 0.0
	for i in s.size():
		var t := float(i) / RATE
		var w := r.randf_range(-1, 1)
		lp += (w - lp) * 0.5
		lp2 += (lp - lp2) * 0.5
		var env := sin(PI * t / 1.6) * (0.6 + 0.4 * sin(TAU * 5.0 * t))
		s[i] = (lp - lp2) * 2.2 * env
	return _wav(s)

static func fuse_in() -> AudioStreamWAV:
	var s := _buf(0.7)
	var r := _rng(12)
	for i in s.size():
		var t := float(i) / RATE
		var pop := r.randf_range(-1, 1) * 0.5 * exp(-t * 40.0)
		var rise := sin(TAU * (80.0 + 500.0 * t) * t) * 0.3 * clampf((t - 0.15) * 4.0, 0.0, 1.0) * exp(-(t - 0.15) * 3.0) if t > 0.15 else 0.0
		s[i] = pop + rise
	return _wav(s)

static func power_up() -> AudioStreamWAV:
	var s := _buf(2.0)
	var r := _rng(13)
	for i in s.size():
		var t := float(i) / RATE
		var f := 40.0 + 90.0 * (1.0 - exp(-t * 2.0))
		s[i] = (sin(TAU * f * t) * 0.5 + r.randf_range(-1, 1) * 0.1) * (1.0 - exp(-t * 6.0)) * exp(-maxf(0.0, t - 1.2) * 2.5)
	return _wav(s)

static func lift_hum() -> AudioStreamWAV:
	var s := _buf(2.0)
	var r := _rng(14)
	var lp := 0.0
	for i in s.size():
		var t := float(i) / RATE
		lp += (r.randf_range(-1, 1) - lp) * 0.05
		s[i] = sin(TAU * 70.0 * t) * 0.3 + sin(TAU * 140.5 * t) * 0.12 + lp * 0.3
	return _wav(s, true)

static func scream() -> AudioStreamWAV:
	var s := _buf(1.4)
	var r := _rng(15)
	var ph := 0.0
	for i in s.size():
		var t := float(i) / RATE
		var f := 620.0 + 260.0 * sin(TAU * 7.0 * t) + 400.0 * t
		ph += TAU * f / RATE
		s[i] = (sin(ph) * 0.4 + sin(ph * 1.5) * 0.2 + r.randf_range(-1, 1) * 0.3) * (1.0 - exp(-t * 40.0)) * exp(-t * 1.4)
	return _wav(s)
