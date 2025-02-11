shader_type spatial;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
		MODEL_MATRIX[3]);
}

void fragment() {
	ALBEDO = vec3(1.0);
	float dist = 2.0 * abs(0.5 - UV.x) / UV.y;
	ALPHA = 1.0 - dist;
	ALPHA *= 0.33 + sin(NODE_POSITION_WORLD.x * 4.0 + NODE_POSITION_WORLD.y + TIME / 2.0) / 3.0;
}
