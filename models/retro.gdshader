shader_type spatial;
render_mode skip_vertex_transform, cull_disabled, depth_prepass_alpha;

uniform sampler2D texture_albedo : source_color, filter_nearest;

void vertex() {
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX = round(VERTEX * 128.0) / 128.0;
}

void fragment() {
	vec4 color = texture(texture_albedo, UV);
	ALBEDO = color.rgb;

	vec4 world_vertex = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	if (world_vertex.y < -0.01) discard;

	if (color.a <= 0.0) discard;
	ALPHA = color.a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
