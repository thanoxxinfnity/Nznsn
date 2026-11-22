shader_type canvas_item;
// Darr ka overlay: kinaron par andhera/laal, dhadkan ke saath saans, grain; almari mein chhupne par patli darar.
uniform float fear : hint_range(0.0, 1.0) = 0.0;
uniform float hide_amt : hint_range(0.0, 1.0) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float t = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV - 0.5;
	float r = length(uv * vec2(1.15, 1.0));
	float vig = smoothstep(0.32, 0.9, r);
	float pulse = 0.5 + 0.5 * sin(t * (4.0 + fear * 6.0));
	float a = vig * (0.38 + 0.5 * fear) + fear * 0.1 * pulse * vig;
	vec3 col = mix(vec3(0.0), vec3(0.22, 0.0, 0.0), fear * vig);
	float n = hash(UV * vec2(1100.0, 620.0) + t * 7.0);
	a += (n - 0.5) * 0.06;
	float slit = step(abs(uv.y + 0.02), 0.03) * step(abs(uv.x), 0.46);
	float hide_a = hide_amt * 0.97 * (1.0 - slit);
	a = max(a, hide_a);
	col = mix(col, vec3(1.0), flash);
	a = max(a, flash);
	COLOR = vec4(col, clamp(a, 0.0, 1.0));
}
