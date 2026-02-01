shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float vignette_intensity = 0.4;
uniform float vignette_opacity = 0.5;
uniform float grain_amount = 0.02;
uniform float chromatic_aberration = 0.0015;
uniform float brightness = 1.0;
uniform float saturation = 1.0;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // Chromatic Aberration
    vec4 col;
    col.r = texture(screen_texture, uv + vec2(chromatic_aberration, 0.0)).r;
    col.g = texture(screen_texture, uv).g;
    col.b = texture(screen_texture, uv - vec2(chromatic_aberration, 0.0)).b;
    col.a = 1.0;
    
    // Brightness
    col.rgb *= brightness;
    
    // Saturation
    float grey = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    col.rgb = mix(vec3(grey), col.rgb, saturation);
    
    // Vignette
    float d = distance(uv, vec2(0.5));
    float vignette = 1.0 - smoothstep(0.5, 0.5 + vignette_intensity, d);
    col.rgb = mix(col.rgb, col.rgb * vignette, vignette_opacity);
    
    // Film Grain
    float noise = (random(uv + TIME * 0.01) - 0.5) * grain_amount;
    col.rgb += noise;
    
    COLOR = col;
}
