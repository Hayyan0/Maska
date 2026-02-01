shader_type canvas_item;

uniform float reveal : hint_range(0.0, 1.0) = 0.0;
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.35;
uniform vec2 center = vec2(0.5, 0.5);

void fragment() {
    vec2 uv = UV;

    float dist = distance(uv, center);
    float mask = smoothstep(reveal, reveal - 0.25, dist);

    float distortion = distortion_strength * (1.0 - reveal) * mask;
    vec2 dir = normalize(uv - center);
    uv += dir * dist * distortion;

    vec4 col = texture(TEXTURE, uv);
    col.a *= mask;

    COLOR = col;
}
