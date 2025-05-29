shader_type canvas_item;

uniform vec4 background_color : source_color = vec4(1.0);
uniform vec4 dot_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float spacing = 32.0;
uniform float dot_radius = 1.5;

void fragment() {
    vec2 uv = FRAGCOORD.xy;

    vec2 grid = mod(uv, spacing);
    float dist = length(grid - spacing / 2.0);
    float dot = smoothstep(dot_radius, dot_radius - 0.5, dist);

    COLOR = mix(background_color, dot_color, dot);
}