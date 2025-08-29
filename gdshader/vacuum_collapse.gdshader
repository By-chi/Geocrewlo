shader_type canvas_item;



uniform float burst_progress : hint_range(0.0, 1.0) = 0.0; // animate 0 → 1

uniform float spread_strength : hint_range(0.0, 2.0) = 1.0; // how far pixels fly out

uniform float distortion_strength : hint_range(0.0, 0.2) = 0.05; // wavy distortion

uniform float fade_start : hint_range(0.0, 1.0) = 0.7; // when to start fading alpha



void fragment() {

    // Center UVs

    vec2 centered_uv = UV - vec2(0.5);



    // Direction from center

    vec2 dir = normalize(centered_uv);



    // Distance from center

    float dist = length(centered_uv);



    // Push pixels outward over time

    vec2 uv_outward = centered_uv + dir * burst_progress * spread_strength;



    // Add distortion for energy-like wobble

    uv_outward += distortion_strength * vec2(

        sin(dist * 20.0 - TIME * 10.0),

        cos(dist * 20.0 - TIME * 8.0)

    ) * burst_progress;



    // Return to standard UV space

    vec2 final_uv = uv_outward + vec2(0.5);



    // Sample texture

    vec4 tex = texture(TEXTURE, final_uv);



    // Fade out towards the end

    float alpha_factor = 1.0 - smoothstep(fade_start, 1.0, burst_progress);

    tex.a *= alpha_factor;

    COLOR = tex;

}