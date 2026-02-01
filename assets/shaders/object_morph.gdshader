shader_type canvas_item;

uniform sampler2D tex_cute : filter_nearest;
uniform sampler2D tex_tough : filter_nearest;

// Regular Uniforms (Set via code)
uniform float wipe_progress;
uniform vec2 wipe_center;
uniform float screen_aspect;
uniform bool target_is_tough;

void fragment() {
	vec4 color_cute = texture(tex_cute, UV);
	vec4 color_tough = texture(tex_tough, UV);
	
	vec2 diff = SCREEN_UV - wipe_center;
	diff.x *= screen_aspect;
	float dist = length(diff);
	
	// Radius: 0.0 -> 1.5 (Full Coverage)
	float radius = wipe_progress * 1.5;
	
	// Smooth edge
	float mix_val = smoothstep(radius - 0.05, radius, dist);
	
	vec4 out_color;
	
	if (target_is_tough) {
		out_color = mix(color_tough, color_cute, mix_val);
	} else {
		out_color = mix(color_cute, color_tough, mix_val);
	}
	
	COLOR = out_color;
	
	if (COLOR.a == 0.0) discard;
}
