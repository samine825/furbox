shader_type canvas_item;
render_mode blend_mix;

uniform vec2 camera_position;
uniform vec2 viewport_size;
uniform vec2 camera_zoom;
uniform float chunk_size;

uniform vec2 loaded_chunks[1024];
uniform int num_loaded : hint_range(0, 1014);

// === ПАРАМЕТРЫ ГРАДИЕНТА, ШУМОВ И ПИКСЕЛЬ-АРТ ===
uniform float fog_fade_width : hint_range(0.0, 1000.0) = 80.0;

uniform sampler2D noise1 : filter_nearest, repeat_enable;
uniform sampler2D noise2 : filter_nearest, repeat_enable;

uniform float noise_scale1 = 0.002;
uniform float noise_scale2 = 0.0035;
uniform vec2 noise_speed1 = vec2(0.005, 0.01);
uniform vec2 noise_speed2 = vec2(-0.008, 0.015);

uniform vec4 fog_low : source_color = vec4(0.12, 0.15, 0.20, 0.75);
uniform vec4 fog_high : source_color = vec4(0.20, 0.23, 0.30, 0.95);

uniform float posterization_levels : hint_range(4.0, 32.0) = 8.0;

void fragment() {
    vec2 world_pos = camera_position + (UV - 0.5) * (viewport_size / camera_zoom);
    
    // Текущий чанк
    ivec2 chunk_pos = ivec2(floor(world_pos / chunk_size));
    
    // === Проверка загруженности чанков ===
    bool is_loaded = false;
    
    bool left_loaded   = false;
    bool right_loaded  = false;
    bool bottom_loaded = false;
    bool top_loaded    = false;
    
    bool bl_loaded = false; // bottom-left
    bool br_loaded = false; // bottom-right
    bool tl_loaded = false; // top-left
    bool tr_loaded = false; // top-right
    
    ivec2 left_n   = chunk_pos + ivec2(-1, 0);
    ivec2 right_n  = chunk_pos + ivec2( 1, 0);
    ivec2 bottom_n = chunk_pos + ivec2( 0,-1);
    ivec2 top_n    = chunk_pos + ivec2( 0, 1);
    
    ivec2 bl_n = chunk_pos + ivec2(-1,-1);
    ivec2 br_n = chunk_pos + ivec2( 1,-1);
    ivec2 tl_n = chunk_pos + ivec2(-1, 1);
    ivec2 tr_n = chunk_pos + ivec2( 1, 1);
    
    for (int i = 0; i < num_loaded; i++) {
        ivec2 c = ivec2(loaded_chunks[i]);
        
        if (c == chunk_pos)     is_loaded = true;
        
        if (c == left_n)        left_loaded   = true;
        if (c == right_n)       right_loaded  = true;
        if (c == bottom_n)      bottom_loaded = true;
        if (c == top_n)         top_loaded    = true;
        
        if (c == bl_n)          bl_loaded = true;
        if (c == br_n)          br_loaded = true;
        if (c == tl_n)          tl_loaded = true;
        if (c == tr_n)          tr_loaded = true;
    }
    
    // === Расчёт расстояния до ближайшей внешней границы (сторона или угол) ===
    float inward_dist = 1e10;
    
    if (is_loaded) {
        vec2 chunk_min = vec2(chunk_pos) * chunk_size;
        vec2 chunk_max = chunk_min + vec2(chunk_size);
        
        float d_left   = world_pos.x - chunk_min.x;
        float d_right  = chunk_max.x - world_pos.x;
        float d_bottom = world_pos.y - chunk_min.y;
        float d_top    = chunk_max.y - world_pos.y;
        
        // Расстояние до открытых сторон
        if (!left_loaded)   inward_dist = min(inward_dist, d_left);
        if (!right_loaded)  inward_dist = min(inward_dist, d_right);
        if (!bottom_loaded) inward_dist = min(inward_dist, d_bottom);
        if (!top_loaded)    inward_dist = min(inward_dist, d_top);
        
        // Расстояние до открытых углов (диагоналей)
        if (!bl_loaded) inward_dist = min(inward_dist, length(world_pos - chunk_min));
        if (!br_loaded) inward_dist = min(inward_dist, length(world_pos - vec2(chunk_max.x, chunk_min.y)));
        if (!tl_loaded) inward_dist = min(inward_dist, length(world_pos - vec2(chunk_min.x, chunk_max.y)));
        if (!tr_loaded) inward_dist = min(inward_dist, length(world_pos - chunk_max));
    }
    
    // === Вычисление интенсивности тумана ===
    float fog_intensity;
    if (!is_loaded) {
        fog_intensity = 1.0;                    // полностью вне зоны
    } else {
        fog_intensity = 1.0 - smoothstep(0.0, fog_fade_width, inward_dist);
    }
    
    // === Два движущихся шума ===
    vec2 noise_uv1 = world_pos * noise_scale1 * 0.01 + TIME * noise_speed1;
    vec2 noise_uv2 = world_pos * noise_scale2 * 0.01 + TIME * noise_speed2;
    
    float n1 = texture(noise1, noise_uv1).r;
    float n2 = texture(noise2, noise_uv2).r;
    
    float noise_factor = clamp((n1 + n2) * 0.5, 0.0, 1.0);
    vec4 fog_color_varied = mix(fog_low, fog_high, noise_factor);
    
    COLOR = mix(vec4(0.0), fog_color_varied, fog_intensity);
    
    // === Постеризация (пиксель-арт стиль) ===
    float levels = posterization_levels;
    COLOR.rgb = floor(COLOR.rgb * levels) / levels;
}