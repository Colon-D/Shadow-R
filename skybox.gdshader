shader_type sky;

uniform sampler2D source_panorama : filter_nearest, source_color;
global uniform bool in_editor;

void sky() {
	vec2 uv = SKY_COORDS;
	float mult = 1.0;
	if (SKY_COORDS.y > 0.5 && !in_editor) {
		float dist = (uv.y - 0.5) * 2.0;
		uv.y = 0.5 - uv.y * 2.0;
		// I have no clue what this does. I just kept adding random sines and
		// shit until I got something resembling whatever is going on ingame.
		float idk = cos(TIME * 3.14 + 1.0 / (dist + 0.02)) * 0.2 * dist;
		// change color a bit
		mult += 0.5 + idk * 10.0;
		uv.y += idk;
		uv.y = clamp(uv.y, -1.0, 0.0); // oops I didn't know I was negative
		uv.x += 0.001 * sin(TIME * 8.0 + uv.y * 100.0);
	}
	COLOR = texture(source_panorama, uv).rgb * vec3(mult);
	COLOR = clamp(COLOR, vec3(0.0), vec3(1.0));
	//COLOR = vec3(uv.y);
}
