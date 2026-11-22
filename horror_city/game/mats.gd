class_name Mats
extends RefCounted
# Materials code se: world-space triplanar, noise + pattern + bump (normal map). Kisi UV ki zaroorat nahi.
static var _c := {}
const SZ := 192

static func _make(key: String, c1: Color, c2: Color, style: int, scale_: float, rough := 0.92, grime := 0.5, bump := 3.0, seed_ := 1, metal := 0.0) -> StandardMaterial3D:
	if _c.has(key):
		return _c[key]
	var n := FastNoiseLite.new()
	n.seed = seed_
	n.frequency = 0.022
	n.fractal_octaves = 4
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	var g := FastNoiseLite.new()
	g.seed = seed_ + 50
	g.frequency = 0.006
	g.fractal_octaves = 3
	var a := Image.create(SZ, SZ, false, Image.FORMAT_RGB8)
	var h := Image.create(SZ, SZ, false, Image.FORMAT_L8)
	for y in SZ:
		for x in SZ:
			var v := n.get_noise_2d(x, y) * 0.5 + 0.5
			var gr := g.get_noise_2d(x, y) * 0.5 + 0.5
			var col := c1.lerp(c2, v)
			var hh := v * 0.6
			match style:
				1:  # brick
					var row := y / 24
					var off := 24 if row % 2 == 1 else 0
					var bx := (x + off) % 48
					if y % 24 < 3 or bx < 3:
						col = Color(0.16, 0.15, 0.14).lerp(c1, v * 0.3)
						hh = 0.0
					else:
						var bv := fmod(float(row * 7 + ((x + off) / 48) * 13), 5.0) / 5.0
						col = col.darkened(bv * 0.25)
						hh = 0.5 + v * 0.4
				2:  # tiles
					if x % 48 < 2 or y % 48 < 2:
						col = col.darkened(0.45)
						hh = 0.0
					else:
						hh = 0.5 + v * 0.3
				3:  # planks
					if x % 32 < 2:
						col = col.darkened(0.5)
						hh = 0.0
					else:
						var pv := fmod(float((x / 32) * 17), 4.0) / 4.0
						col = col.darkened(pv * 0.3)
						hh = 0.5 + v * 0.3
				4:  # metal sheet scratches
					var sc := absf(sin((x * 0.5 + y * 2.3) * 0.9)) * n.get_noise_2d(y * 3, x * 0.3)
					col = col.lerp(c2, clampf(sc, 0.0, 0.5))
					hh = 0.5 + v * 0.1
			col = col.darkened(grime * (1.0 - gr) * 0.85)
			a.set_pixel(x, y, col)
			h.set_pixel(x, y, Color(hh, hh, hh))
	a.generate_mipmaps()
	h.bump_map_to_normal_map(bump)
	h.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(a)
	m.normal_enabled = true
	m.normal_texture = ImageTexture.create_from_image(h)
	m.roughness = rough
	m.metallic = metal
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * scale_
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_c[key] = m
	return m

static func wall() -> StandardMaterial3D:
	return _make("wall", Color(0.30, 0.29, 0.26), Color(0.46, 0.44, 0.40), 0, 0.4, 0.95, 0.7, 2.5, 3)

static func brick() -> StandardMaterial3D:
	return _make("brick", Color(0.38, 0.17, 0.12), Color(0.55, 0.28, 0.2), 1, 0.45, 0.9, 0.6, 3.0, 5)

static func floor_() -> StandardMaterial3D:
	return _make("floor", Color(0.16, 0.16, 0.15), Color(0.28, 0.27, 0.25), 2, 0.5, 0.85, 0.7, 2.0, 7)

static func tile() -> StandardMaterial3D:
	return _make("tile", Color(0.5, 0.52, 0.5), Color(0.7, 0.72, 0.68), 2, 0.5, 0.55, 0.8, 1.5, 9)

static func wood() -> StandardMaterial3D:
	return _make("wood", Color(0.22, 0.12, 0.07), Color(0.4, 0.24, 0.13), 3, 0.5, 0.8, 0.5, 2.0, 11)

static func ceiling() -> StandardMaterial3D:
	return _make("ceiling", Color(0.12, 0.12, 0.12), Color(0.2, 0.2, 0.19), 0, 0.3, 1.0, 0.8, 1.0, 13)

static func metal() -> StandardMaterial3D:
	return _make("metal", Color(0.26, 0.25, 0.24), Color(0.4, 0.22, 0.12), 4, 0.5, 0.55, 0.6, 1.0, 15, 0.55)

static func door_metal() -> StandardMaterial3D:
	return _make("door_metal", Color(0.22, 0.26, 0.25), Color(0.35, 0.3, 0.22), 4, 0.8, 0.5, 0.7, 1.0, 17, 0.6)

static func door_wood() -> StandardMaterial3D:
	return _make("door_wood", Color(0.28, 0.16, 0.09), Color(0.45, 0.28, 0.15), 3, 1.0, 0.8, 0.5, 2.0, 19)

static func solid(c: Color, rough := 0.8, emit := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m
