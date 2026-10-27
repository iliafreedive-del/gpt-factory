shader_type spatial;
render_mode cull_disabled;
uniform vec4 slab_color : source_color = vec4(0.48, 0.49, 0.46, 1.0);
uniform vec2 slab_metres = vec2(6.0, 3.0);
varying vec3 world_position;

float hash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
    vec2 p = world_position.xz;
    vec2 cell = floor(p / slab_metres);
    vec2 local = fract(p / slab_metres);
    float seed = hash21(cell);
    vec2 distance_to_joint = min(local, 1.0 - local) * slab_metres;
    float aa = max(length(fwidth(p)), 0.015);
    float joint = 1.0 - smoothstep(0.025, 0.025 + aa, min(distance_to_joint.x, distance_to_joint.y));
    float coarse = hash21(floor(p * 2.5));
    float grain = hash21(floor(p * 38.0));
    float crack_axis = local.y - (0.2 + seed * 0.5 + 0.025 * sin(local.x * 9.0 + seed * 21.0));
    float crack = (1.0 - smoothstep(0.004, 0.004 + aa / slab_metres.y, abs(crack_axis))) * step(0.94, seed);
    vec3 base = slab_color.rgb * (0.94 + seed * 0.10 + coarse * 0.025 + grain * 0.03);
    float stain = smoothstep(0.65, 0.95, sin(p.x * 0.37) * sin(p.y * 0.55) * 0.5 + 0.5);
    base *= 1.0 - stain * 0.08;
    ALBEDO = mix(base, vec3(0.25, 0.27, 0.25), max(joint * 0.38, crack * 0.40));
    ROUGHNESS = 0.96;
}
