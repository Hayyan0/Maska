shader_type canvas_item;

uniform vec4 wave_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float speed : hint_range(1.0, 20.0) = 10.0;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;

void fragment() {
    vec2 uv = UV;
    
    // Distance from bottom (ground is uv.y = 1.0)
    float ground_dist = 1.0 - uv.y;
    
    // Create multiple sharp spikes across X
    // We use absolute sine for sharp peaks at the bottom
    float spike_freq = 12.0;
    float spikes = abs(sin(uv.x * spike_freq + TIME * speed * 0.2)) * 0.5;
    spikes += abs(sin(uv.x * spike_freq * 2.1 + TIME * speed * 0.5)) * 0.25;
    
    // Overall envelope: Taller in the middle of our Rect
    float envelope = smoothstep(0.0, 0.4, uv.x) * smoothstep(1.0, 0.6, uv.x);
    float final_height = spikes * envelope;
    
    // Threshold for the "energy"
    // Higher up (higher ground_dist), it needs more 'spike' value to be visible
    float mask = smoothstep(final_height, final_height - 0.1, ground_dist);
    
    // Add horizontal jitter to make it look energetic
    float jitter = sin(TIME * 50.0 + uv.y * 10.0) * 0.01;
    float jitter_mask = smoothstep(final_height + jitter, final_height + jitter - 0.05, ground_dist);
    
    // Combine for a sharp, flickering look
    float alpha = jitter_mask * intensity;
    
    // Base color is white
    vec4 color = wave_color;
    
    // Add a bit of "core" brightness at the very bottom
    float core = smoothstep(0.15, 0.0, ground_dist) * envelope;
    color.rgb += core * 0.5;
    
    COLOR = vec4(color.rgb, alpha * color.a);
}
