// Shader for a volumetric, correctly-oriented cloud bed with no seams.
shader_type canvas_item;

// ## Cloud Shape & Density
uniform float cloud_scale : hint_range(0.5, 10.0) = 3.5;
uniform float cloud_coverage : hint_range(0.1, 1.0) = 0.55;
uniform float cloud_softness : hint_range(0.01, 0.5) = 0.15;
uniform int octaves : hint_range(1, 10) = 7;
uniform float persistence : hint_range(0.1, 1.0) = 0.5;
uniform float lacunarity : hint_range(1.0, 4.0) = 2.0;

// ## Color & Lighting
uniform vec4 sky_color : source_color = vec4(0.4, 0.6, 0.85, 1.0);
uniform vec4 cloud_base_color : source_color = vec4(0.8, 0.8, 0.85, 1.0);
uniform vec4 cloud_highlight_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float lighting_contrast : hint_range(0.0, 1.0) = 0.2;

// ## Animation & Perspective
uniform float speed : hint_range(0.0, 5.0) = 1.0;
uniform float perspective : hint_range(0.1, 10.0) = 4.0;
uniform float horizon_line : hint_range(0.0, 1.0) = 0.4;


// -- 3D PERLIN NOISE FUNCTIONS (Higher Quality) --
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 mod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 permute(vec4 x) { return mod289(((x*34.0)+1.0)*x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float perlin_noise(vec3 v) {
    const vec2 C = vec2(1.0/6.0, 1.0/3.0);
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
    vec3 i = floor(v + dot(v, C.yyy));
    vec3 x0 = v - i + dot(i, C.xxx);
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);
    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy;
    vec3 x3 = x0 - D.yyy;
    i = mod289(i);
    vec4 p = permute(permute(permute(
                i.z + vec4(0.0, i1.z, i2.z, 1.0))
            + i.y + vec4(0.0, i1.y, i2.y, 1.0))
            + i.x + vec4(0.0, i1.x, i2.x, 1.0));
    float n_ = 0.142857142857;
    vec3 ns = n_ * D.wyz - D.xzx;
    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_);
    vec4 x = x_ * ns.x + ns.yyyy;
    vec4 y = y_ * ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);
    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);
    vec4 s0 = floor(b0)*2.0 + 1.0;
    vec4 s1 = floor(b1)*2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));
    vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww;
    vec3 p0 = vec3(a0.xy,h.x);
    vec3 p1 = vec3(a0.zw,h.y);
    vec3 p2 = vec3(a1.xy,h.z);
    vec3 p3 = vec3(a1.zw,h.w);
    vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
    p0 *= norm.x; p1 *= norm.y; p2 *= norm.z; p3 *= norm.w;
    vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m*m, vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
}

float fbm(vec3 st) {
    float v = 0.0;
    float a = 0.5;
    vec3 shift = vec3(100.0);
    for (int i = 0; i < octaves; i++) {
        v += a * perlin_noise(st);
        st = st * lacunarity + shift;
        a *= persistence;
    }
    return v;
}
// -- END NOISE FUNCTIONS --

void fragment() {
    vec4 final_color;
    if (UV.y < horizon_line) {
        final_color = sky_color;
    } else {
        float p = (UV.y - horizon_line) / (1.0 - horizon_line);
        p = max(p, 0.001); // **FIX #2**: Prevents division by zero
        float distance = perspective / p;

        // **FIX #1**: Corrected world position calculation
        vec3 world_pos;
        world_pos.z = distance + TIME * speed;
        world_pos.x = (UV.x - 0.5) * perspective * 2.0;
        world_pos.y = 0.0;

        float cloud_height = fbm(world_pos * cloud_scale);
        float cloud_alpha = smoothstep(cloud_coverage - cloud_softness, cloud_coverage + cloud_softness, cloud_height);

        vec3 sun_direction = normalize(vec3(0.5, 0.8, -0.2));
        float height_towards_sun = fbm((world_pos - sun_direction * 0.1) * cloud_scale);

        float light_value = smoothstep(lighting_contrast, 1.0, cloud_height - height_towards_sun);
        vec4 lit_cloud_color = mix(cloud_base_color, cloud_highlight_color, light_value);

        float fog_factor = smoothstep(0.0, 0.5, p);
        cloud_alpha *= fog_factor;

        final_color = mix(sky_color, lit_cloud_color, cloud_alpha);
    }

    COLOR = final_color;
}