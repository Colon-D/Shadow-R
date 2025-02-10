shader_type spatial;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 uv_rel_mid = UV - vec2(0.5, 0.5);
	if (sqrt(uv_rel_mid.x * uv_rel_mid.x + uv_rel_mid.y * uv_rel_mid.y) > 0.5) discard;
	if (mod(FRAGCOORD.x + FRAGCOORD.y, 2) == 1.0) discard;
	ALBEDO = vec3(0.0);
}
