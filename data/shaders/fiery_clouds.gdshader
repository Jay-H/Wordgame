shader_type canvas_item;

// --- Basic Cloud Parameters ---
uniform vec4 fire_color_a : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform vec4 fire_color_b : source_color = vec4(0.8, 0.0, 0.0, 1.0);
uniform vec4 smoke_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform float noise_scale = 3.0;
uniform float octaves = 5.0;
uniform float density : hint_range(0.1, 10.0, 0.1) = 3.0;

// --- Animation & Position Parameters ---
uniform float morphing_speed = 0.2;
uniform float cloud_position : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float cloud_fade_softness : hint_range(0.0, 1.0, 0.01) = 0.4;

// --- NEW Edge Fade Parameter ---
uniform float border_fade_size : hint_range(0.0, 0.5, 0.01) = 0.3;


// 3D simplex noise function (unchanged)
vec4 mod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 permute(vec4 x) { return mod289(((x*34.0)+1.0)*x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float snoise(vec3 v) {
    const vec2 C = vec2(1.0/6.0, 1.0/3.0) ;
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
    vec3 i  = floor(v + dot(v, C.yyy) );
    vec3 x0 = v - i + dot(i, C.xxx) ;
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min( g.xyz, l.zxy );
    vec3 i2 = max( g.xyz, l.zxy );
    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy;
    vec3 x3 = x0 - D.yyy;
    i = mod289(i);
    vec4 p = permute( permute( permute(
                i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
            + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
            + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));
    float n_ = 0.142857142857;
    vec3  ns = n_ * D.wyz - D.xzx;
    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_ );
    vec4 x = x_ *ns.x + ns.yyyy;
    vec4 y = y_ *ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);
    vec4 b0 = vec4( x.xy, y.xy );
    vec4 b1 = vec4( x.zw, y.zw );
    vec4 s0 = floor(b0)*2.0 + 1.0;
    vec4 s1 = floor(b1)*2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));
    vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
    vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;
    vec3 p0 = vec3(a0.xy,h.x);
    vec3 p1 = vec3(a0.zw,h.y);
    vec3 p2 = vec3(a1.xy,h.z);
    vec3 p3 = vec3(a1.zw,h.w);
    vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;
    vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    m = m * m;
    return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1),
                                    dot(p2,x2), dot(p3,x3) ) );
}


void fragment() {
    // Generate base noise pattern
    vec2 base_uv = UV * noise_scale;
    vec3 noise_coord = vec3(base_uv, TIME * morphing_speed);
    float noise = 0.0;
    float amp = 1.0;
    for (float i = 0.0; i < octaves; i++) {
        noise += snoise(noise_coord) * amp;
        noise_coord *= 2.0;
        amp *= 0.5;
    }
    noise = (noise + 1.0) / 2.0;
    float dense_noise = pow(noise, density);

    // --- NEW: Create a mask that fades at the rectangle's border ---
    // Calculate distance from the center (0.5, 0.5) to the edge (0.0 or 1.0)
    vec2 dist_from_center = abs(UV - 0.5);
    // Find the maximum distance (creates a square gradient)
    float max_dist = max(dist_from_center.x, dist_from_center.y);
    // Use smoothstep to create a soft fade-out effect near the edge (max_dist = 0.5)
    float border_mask = 1.0 - smoothstep(0.5 - border_fade_size, 0.5, max_dist);

    // Create the vertical mask to keep clouds at the bottom
    float vertical_top_edge = cloud_position;
    float vertical_bottom_edge = cloud_position + cloud_fade_softness;
    float vertical_mask = smoothstep(vertical_bottom_edge, vertical_top_edge, UV.y);

    // Use the "dense_noise" for coloring
    vec3 fire = mix(fire_color_a.rgb, fire_color_b.rgb, dense_noise);
    vec3 color = mix(smoke_color.rgb, fire, dense_noise);

    COLOR.rgb = color;
    // The final alpha is the dense noise pattern multiplied by both masks
    COLOR.a = dense_noise * vertical_mask * border_mask;
}