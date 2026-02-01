shader_type canvas_item;

uniform vec2 hole_center = vec2(0.5, 0.5);
uniform float hole_radius = 0.0;
uniform float aspect = 1.777;

void fragment() {
	vec2 diff = UV - hole_center;
	diff.x *= aspect;
	float dist = length(diff);
	
	// If inside hole, Alpha = 0 (Transparent -> Show Live Game)
	// If outside hole, Alpha = 1 (Opaque -> Show Snapshot)
	
	// Smoothstep for softer edge
	float alpha = smoothstep(hole_radius, hole_radius + 0.05, dist);
	
	COLOR.a = alpha;
}
