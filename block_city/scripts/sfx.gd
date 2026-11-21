class_name Sfx
extends RefCounted
# Awaazein code se banti hain (koi audio file nahi).

const RATE := 22050

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

static func boom() -> AudioStreamWAV:
    var n := int(RATE * 1.0)
    var s := PackedFloat32Array()
    s.resize(n)
    var rng := RandomNumberGenerator.new()
    rng.seed = 7
    var lp := 0.0
    for i in n:
        var t := float(i) / RATE
        lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.16
        s[i] = lp * 2.2 * exp(-t * 4.2) + sin(TAU * 52.0 * t) * 0.9 * exp(-t * 6.0)
    return _wav(s)

static func coin() -> AudioStreamWAV:
    var n := int(RATE * 0.3)
    var s := PackedFloat32Array()
    s.resize(n)
    for i in n:
        var t := float(i) / RATE
        var f := 988.0 if t < 0.1 else 1319.0
        s[i] = sin(TAU * f * t) * 0.45 * exp(-(t if t < 0.1 else t - 0.1) * 9.0)
    return _wav(s)

static func jump() -> AudioStreamWAV:
    var n := int(RATE * 0.14)
    var s := PackedFloat32Array()
    s.resize(n)
    var ph := 0.0
    for i in n:
        var t := float(i) / RATE
        ph += TAU * (280.0 + 900.0 * t) / RATE
        s[i] = sin(ph) * 0.32 * (1.0 - t / 0.14)
    return _wav(s)

static func throw_() -> AudioStreamWAV:
    var n := int(RATE * 0.22)
    var s := PackedFloat32Array()
    s.resize(n)
    var rng := RandomNumberGenerator.new()
    rng.seed = 3
    var lp := 0.0
    for i in n:
        var t := float(i) / RATE
        lp += (rng.randf_range(-1.0, 1.0) - lp) * (0.05 + 0.5 * t)
        s[i] = lp * 1.4 * sin(PI * t / 0.22)
    return _wav(s)

static func hurt() -> AudioStreamWAV:
    var n := int(RATE * 0.18)
    var s := PackedFloat32Array()
    s.resize(n)
    var rng := RandomNumberGenerator.new()
    rng.seed = 11
    for i in n:
        var t := float(i) / RATE
        s[i] = (rng.randf_range(-1.0, 1.0) * 0.5 + sin(TAU * 140.0 * t) * 0.5) * exp(-t * 14.0)
    return _wav(s)

static func engine() -> AudioStreamWAV:
    var n := int(RATE * 0.25)     # 60Hz * 0.25s = 15 poore cycle => seamless loop
    var s := PackedFloat32Array()
    s.resize(n)
    for i in n:
        var t := float(i) / RATE
        var saw := fmod(t * 60.0, 1.0) * 2.0 - 1.0
        s[i] = saw * 0.35 + sin(TAU * 120.0 * t) * 0.2 + sin(TAU * 180.0 * t) * 0.1
    return _wav(s, true)

static func siren() -> AudioStreamWAV:
    var n := RATE      # 1 second, exact loop
    var s := PackedFloat32Array()
    s.resize(n)
    var ph := 0.0
    for i in n:
        var t := float(i) / RATE
        ph += TAU * (780.0 + 220.0 * sin(TAU * t)) / RATE
        s[i] = sin(ph) * 0.3
    # phase ko loop ke liye 2pi ke poore multiple par laao
    return _wav(s, true)
