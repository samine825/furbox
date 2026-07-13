shader_type canvas_item;

uniform float pixel_size = 8.0; // теперь реально 8 пикселей

uniform sampler2D noise_texture1 : repeat_enable;
uniform sampler2D noise_texture2 : repeat_enable;

uniform float speed1 = 0.5;
uniform float speed2 = 0.8;

uniform float scale1 = 2.0;
uniform float scale2 = 3.0;

uniform vec2 direction1 = vec2(1.0, 0.3);
uniform vec2 direction2 = vec2(-0.5, 0.7);

uniform float amplitude = 1.0;
uniform float posterize_levels = 4.0;

uniform vec4 color1 : source_color;
uniform vec4 color2 : source_color;

void fragment() {

	vec2 uv_block = floor(UV / pixel_size) * pixel_size + pixel_size * 0.5;

	vec2 uv1 = uv_block * scale1 + direction1 * TIME * speed1;
	vec2 uv2 = uv_block * scale2 + direction2 * TIME * speed2;

	float noise1 = texture(noise_texture1, uv1).r;
	float noise2 = texture(noise_texture2, uv2).r;

	float combined = (noise1 + noise2) * 0.5;
	float value = clamp(combined * amplitude, 0.0, 1.0);

	vec3 water = mix(color1.rgb, color2.rgb, value);

	float levels = posterize_levels;
	water = floor(water * levels) / levels;

	COLOR = vec4(water, 1.0);
}
