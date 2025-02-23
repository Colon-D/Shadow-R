shader_type spatial;
render_mode skip_vertex_transform, cull_disabled, depth_prepass_alpha;

uniform sampler2D texture_albedo : source_color, filter_nearest;
uniform sampler2D fake_metal : source_color, filter_nearest;

void vertex() {
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX = round(VERTEX * 128.0) / 128.0;

	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 front = CAMERA_DIRECTION_WORLD;
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), front));
	vec3 up = normalize(cross(right, front));
	vec2 fm_uv = vec2(0.5) + vec2(dot(NORMAL, right), dot(NORMAL, up)) / 4.0;

	vec4 color = texture(texture_albedo, UV);
	if (color.rgba == vec4(0.0, 1.0, 0.0, 1.0)) {
		//color.rgb = vec3(dot(NORMAL, right));
		//color.rgb = vec3(NORMAL);
		//color.rgb = vec3(right);
		color.rgb = texture(fake_metal, fm_uv).rgb;
	}
	ALBEDO = color.rgb;

	vec4 world_vertex = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	if (world_vertex.y < -0.01) discard;

	if (color.a <= 0.0) discard;
	ALPHA = color.a;
}
