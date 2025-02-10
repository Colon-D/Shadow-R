shader_type spatial;

// shader that should hopefully billboard with depth closer to camera, to stop
// shield slicing the player in two

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

uniform sampler2D texture_albedo : source_color, filter_nearest;

void fragment() {
	vec4 color = texture(texture_albedo, UV);
	ALBEDO = color.rgb;
	if (color.a <= 0.0) discard;
	// shields are translucent :3
	ALPHA = 0.5;

	// stolen from https://docs.godotengine.org/en/latest/tutorials/shaders/advanced_postprocessing.html#depth-texture
	float depth = FRAGCOORD.z;
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	#endif
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	// make shield closer
	linear_depth -= 0.6;
	// janky conversion back to non linear depth
	// I might have made mistakes here, my math isn't great.
	// also cbf with other renderer
	view.z = -linear_depth * view.w;
	vec4 clip_space = PROJECTION_MATRIX * view;
	ndc = clip_space.xyz / clip_space.w;
	DEPTH = ((ndc.z + 1.0) / 2.0);
}
