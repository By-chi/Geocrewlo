/*
Shader from Godot Shaders - 平衡噪点版本
保留自然细腻的噪点效果，去除干扰性的条状噪声
*/

shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// 覆盖层设置
uniform bool overlay = false;

// 扫描线参数
uniform float scanlines_opacity : hint_range(0.0, 1.0) = 0.4;
uniform float scanlines_width : hint_range(0.0, 0.5) = 0.25;

// 格栅参数
uniform float grille_opacity : hint_range(0.0, 1.0) = 0.3;
uniform vec2 resolution = vec2(640.0, 480.0);

// 像素化开关
uniform bool pixelate = true;

// 适度噪点参数（降低强度避免干扰）
uniform float noise_opacity : hint_range(0.0, 0.3) = 0.1;  // 低强度
uniform float noise_speed : hint_range(0.1, 3.0) = 0.8;    // 慢速移动

// 静态噪点参数
uniform float static_noise_intensity : hint_range(0.0, 0.1) = 0.02;  // 微弱强度

// 色差参数
uniform float aberration : hint_range(-0.5, 0.5) = 0.02;
uniform float brightness = 1.2;

// 褪色效果
uniform bool discolor = true;

// 扭曲参数
uniform float warp_amount : hint_range(0.0, 2.0) = 0.5;
uniform bool clip_warp = false;

// 暗角参数
uniform float vignette_intensity = 0.3;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.4;

// 随机数生成（用于自然噪点）
vec2 random(vec2 uv){
    uv = vec2( dot(uv, vec2(127.1,311.7) ),
               dot(uv, vec2(269.5,183.3) ) );
    return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

// 柏林噪声（用于柔和噪点）
float noise(vec2 uv) {
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);

    vec2 blur = smoothstep(0.0, 1.0, uv_fract);

    return mix( mix( dot( random(uv_index + vec2(0.0,0.0) ), uv_fract - vec2(0.0,0.0) ),
                     dot( random(uv_index + vec2(1.0,0.0) ), uv_fract - vec2(1.0,0.0) ), blur.x),
                mix( dot( random(uv_index + vec2(0.0,1.0) ), uv_fract - vec2(0.0,1.0) ),
                     dot( random(uv_index + vec2(1.0,1.0) ), uv_fract - vec2(1.0,1.0) ), blur.x), blur.y) * 0.5 + 0.5;
}

// 扭曲函数
vec2 warp(vec2 uv){
    vec2 delta = uv - 0.5;
    float dist = length(delta);
    float distortion = dist * dist * warp_amount * 0.1;
    return uv + delta * distortion;
}

// 边框函数
float border (vec2 uv){
    vec2 clamped = clamp(uv, 0.05, 0.95);
    float edge_factor = smoothstep(0.0, 0.05, distance(uv, clamped));
    return 1.0 - edge_factor;
}

// 暗角函数
float vignette(vec2 uv){
    uv *= 1.0 - uv.xy;
    float vignette = uv.x * uv.y * 15.0;
    return pow(vignette, vignette_intensity * vignette_opacity);
}

void fragment()
{
    // 应用UV扭曲
    vec2 uv = overlay ? warp(SCREEN_UV) : warp(UV);
    vec2 text_uv = uv;
    
    // 像素化处理
    if (pixelate)
    {
        text_uv = ceil(uv * resolution) / resolution;
    }
    
    // 基础颜色采样
    vec4 text;
    text.r = texture(SCREEN_TEXTURE, text_uv + vec2(aberration, 0.0) * 0.05).r;
    text.g = texture(SCREEN_TEXTURE, text_uv - vec2(aberration, 0.0) * 0.05).g;
    text.b = texture(SCREEN_TEXTURE, text_uv).b;
    text.a = 1.0;
    
    float r = text.r;
    float g = text.g;
    float b = text.b;
    
    // 应用RGB格栅效果
    if (grille_opacity > 0.0){
        float g_r = smoothstep(0.85, 0.95, abs(sin(uv.x * (resolution.x * 3.14159265))));
        r = mix(r, r * g_r, grille_opacity);
        
        float g_g = smoothstep(0.85, 0.95, abs(sin(1.05 + uv.x * (resolution.x * 3.14159265))));
        g = mix(g, g * g_g, grille_opacity);
        
        float b_b = smoothstep(0.85, 0.95, abs(sin(2.1 + uv.x * (resolution.x * 3.14159265))));
        b = mix(b, b * b_b, grille_opacity);
    }
    
    // 亮度调整
    text.r = clamp(r * brightness, 0.0, 1.0);
    text.g = clamp(g * brightness, 0.0, 1.0);
    text.b = clamp(b * brightness, 0.0, 1.0);
    
    // 扫描线效果
    if (scanlines_opacity > 0.0)
    {
        float scanlines = smoothstep(scanlines_width, scanlines_width + 0.5, abs(sin(uv.y * (resolution.y * 3.14159265))));
        text.rgb = mix(text.rgb, text.rgb * vec3(scanlines), scanlines_opacity);
    }
    
    // 自然噪点（低强度，无条状干扰）
    if (noise_opacity > 0.0)
    {
        // 均匀分布的噪点，无方向性
        float noise_val = noise(uv * vec2(10.0, 10.0) + TIME * noise_speed);
        noise_val = (noise_val - 0.5) * 2.0; // 范围调整到-1.0到1.0
        text.rgb += noise_val * noise_opacity * 0.1;
        text.rgb = clamp(text.rgb, vec3(0.0), vec3(1.0));
    }
    
    // 静态噪点（微弱强度）
    if (static_noise_intensity > 0.0)
    {
        float static_val = random(uv * 100.0 + fract(TIME * 0.2)).x;
        static_val = (static_val + 1.0) * 0.5; // 范围调整到0.0到1.0
        text.rgb += static_val * static_noise_intensity;
        text.rgb = clamp(text.rgb, vec3(0.0), vec3(1.0));
    }
    
    // 应用边框和暗角
    text.rgb *= border(uv);
    text.rgb *= vignette(uv);
    
    // 裁剪扭曲区域
    if (clip_warp)
    {
        text.a = border(uv);
    }
    
    // 褪色效果
    if (discolor)
    {
        vec3 greyscale = vec3(text.r + text.g + text.b) / 3.0;
        text.rgb = mix(text.rgb, greyscale, 0.4);
        
        float midpoint = pow(0.5, 2.2);
        text.rgb = (text.rgb - vec3(midpoint)) * 1.1 + vec3(midpoint);
    }
    
    COLOR = text;
}
