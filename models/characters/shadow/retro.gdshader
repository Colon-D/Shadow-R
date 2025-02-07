shader_type spatial;
render_mode skip_vertex_transform, cull_disabled;

uniform sampler2D albedo_texture : source_color, filter_nearest;

void vertex() {
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX = round(VERTEX * 128.0) / 128.0;
}

void fragment() {
	vec4 color = texture(albedo_texture, UV);
	ALBEDO = color.rgb;
	if (color.a < 0.5) discard;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
