shader_type canvas_item;

uniform vec2 hole_center = vec2(0.5, 0.5);
uniform float hole_radius = 0.0;
uniform float aspect = 1.777;

// Aesthetics
// Replaced single color with Gradient Texture for background
uniform sampler2D border_gradient : source_color; 
uniform vec4 icon_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Color of the stars

uniform float border_width = 0.1; // Total width
uniform float white_edge_thickness = 0.01; // Thickness of white lines

// Pattern
uniform sampler2D pattern_texture : filter_linear_mipmap, repeat_enable;
uniform float pattern_scale = 10.0; // Grid size
uniform float pattern_speed = 0.5;
uniform float pattern_rotation = 0.0; // Degrees

vec2 rotate(vec2 uv, float deg) {
	float rad = radians(deg);
	mat2 m = mat2(vec2(cos(rad), -sin(rad)), vec2(sin(rad), cos(rad)));
	return m * uv;
}

void fragment() {
	vec2 diff = UV - hole_center;
	diff.x *= aspect;
	float dist = length(diff);
	
	// --- Regions ---
	bool is_hole = dist < hole_radius;
	bool is_inner_white = dist >= hole_radius && dist < (hole_radius + white_edge_thickness);
	bool is_pattern_band = dist >= (hole_radius + white_edge_thickness) && dist < (hole_radius + border_width - white_edge_thickness);
	bool is_outer_white = dist >= (hole_radius + border_width - white_edge_thickness) && dist < (hole_radius + border_width);
	
	// --- Pattern Logic ---
	// Tiled UVs with Aspect Correction
	vec2 corrected_uv = UV;
	corrected_uv.x *= aspect; 
	
	// Apply Rotation centered on the hole? Or just screen center?
	// Screen center (0.5*aspect, 0.5) is better for stability.
	vec2 center_for_rot = vec2(0.5 * aspect, 0.5);
	vec2 rotated_uv = rotate(corrected_uv - center_for_rot, pattern_rotation) + center_for_rot;
	
	vec2 grid_uv = rotated_uv * pattern_scale;
	// Scroll diagonally
	grid_uv += vec2(TIME * pattern_speed, -TIME * pattern_speed); 
	
	vec4 pat_color = texture(pattern_texture, grid_uv);
	
	// --- Gradient Logic ---
	// Sample gradient based on UV.x (Linear) or Angle (Sweep)?
	// Let's do simple UV.x for a nice horizontal sweep.
	vec4 bg_color = texture(border_gradient, vec2(UV.x, 0.0));
	
	// --- Composition ---
	vec4 tex_color = texture(TEXTURE, UV);
	vec3 final_rgb = tex_color.rgb;
	float final_alpha = 1.0;
	
	if (is_hole) {
		final_alpha = 0.0; 
	} else if (is_inner_white) {
		final_rgb = vec3(1.0); 
	} else if (is_pattern_band) {
		// Background of band is Gradient
		vec3 bg = bg_color.rgb;
		
		// Icon (Pattern)
		// Mix BG with Icon Color based on pattern alpha
		// We use icon_color.a to control opacity of icon
		
		final_rgb = mix(bg, icon_color.rgb, pat_color.a * icon_color.a); 
		
	} else if (is_outer_white) {
		final_rgb = vec3(1.0); 
	} else {
		final_rgb = tex_color.rgb;
	}
	
	COLOR = vec4(final_rgb, final_alpha);
}
