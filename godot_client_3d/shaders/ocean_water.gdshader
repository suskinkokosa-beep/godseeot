shader_type canvas_item;

// Isleborn Online - Ocean Water Shader
// Создаёт эффект океанской воды с волнами, отражениями и прозрачностью

uniform float time_scale : hint_range(0.0, 2.0) = 0.5;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wave_height : hint_range(0.0, 0.5) = 0.1;
uniform vec4 shallow_color : source_color = vec4(0.2, 0.6, 0.9, 0.8);
uniform vec4 deep_color : source_color = vec4(0.05, 0.2, 0.4, 0.9);
uniform float foam_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float transparency : hint_range(0.0, 1.0) = 0.7;

varying vec2 world_position;

vec2 hash(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec2 p) {
	const float K1 = 0.366025404;
	const float K2 = 0.211324865;
	vec2 i = floor(p + (p.x + p.y) * K1);
	vec2 a = p - i + (i.x + i.y) * K2;
	vec2 o = (a.x > a.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec2 b = a - o + K2;
	vec2 c = a - 1.0 + 2.0 * K2;
	vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
	vec3 n = h * h * h * h * vec3(dot(a, hash(i + 0.0)), dot(b, hash(i + o)), dot(c, hash(i + 1.0)));
	return dot(n, vec3(70.0));
}

float waves(vec2 p) {
	float wave = 0.0;
	float freq = 1.0;
	float amp = 0.5;
	
	for (int i = 0; i < 4; i++) {
		wave += amp * noise(p * freq);
		freq *= 2.0;
		amp *= 0.5;
	}
	
	return wave;
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 uv = UV;
	float time = TIME * time_scale;
	
	// Создаём волны
	vec2 wave_uv = world_position * 0.1 + vec2(time * wave_speed * 0.1, 0.0);
	float wave = waves(wave_uv);
	
	// Высота волны для смещения
	float height = wave * wave_height;
	
	// Создаём пену на гребнях волн
	float foam = smoothstep(0.4, 0.6, wave);
	foam *= foam_intensity;
	
	// Градиент от мелководья к глубине (основан на Y координате)
	float depth_factor = smoothstep(0.3, 1.0, uv.y);
	vec4 water_color = mix(shallow_color, deep_color, depth_factor);
	
	// Добавляем оттенок волн
	water_color.rgb += vec3(0.1, 0.15, 0.2) * wave * 0.3;
	
	// Добавляем пену
	water_color.rgb += vec3(1.0) * foam;
	
	// Прозрачность
	water_color.a *= transparency;
	
	COLOR = water_color;
}

