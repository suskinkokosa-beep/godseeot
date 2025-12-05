shader_type spatial;
render_mode depth_draw_opaque, depth_test_disabled, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Isleborn Online - 3D Ocean Water Shader
// Создаёт эффект океанской воды с волнами и прозрачностью

uniform float time_scale : hint_range(0.0, 2.0) = 0.5;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wave_height : hint_range(0.0, 2.0) = 0.5;
uniform vec4 shallow_color : source_color = vec4(0.2, 0.6, 0.9, 0.8);
uniform vec4 deep_color : source_color = vec4(0.05, 0.2, 0.4, 0.95);
uniform float transparency : hint_range(0.0, 1.0) = 0.7;
uniform float metallic : hint_range(0.0, 1.0) = 0.1;
uniform float roughness : hint_range(0.0, 1.0) = 0.3;

varying vec3 world_position;

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
	float freq = 0.5;
	float amp = 0.5;
	
	for (int i = 0; i < 4; i++) {
		wave += amp * noise(p * freq);
		freq *= 2.0;
		amp *= 0.5;
	}
	
	return wave;
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	float time = TIME * time_scale;
	vec2 wave_uv = world_position.xz * 0.1 + vec2(time * wave_speed * 0.1, 0.0);
	float wave = waves(wave_uv);
	
	// Смещаем вершины по Y для создания волн
	VERTEX.y += wave * wave_height;
	
	// Создаём нормали для освещения
	vec2 offset = vec2(0.1, 0.0);
	float wave_x = waves(wave_uv + offset);
	float wave_z = waves(wave_uv + offset.yx);
	
	vec3 normal = normalize(vec3(
		(wave - wave_x) / offset.x,
		wave_height,
		(wave - wave_z) / offset.x
	));
	
	NORMAL = (MODEL_MATRIX * vec4(normal, 0.0)).xyz;
}

void fragment() {
	float time = TIME * time_scale;
	vec2 wave_uv = world_position.xz * 0.1 + vec2(time * wave_speed * 0.1, 0.0);
	float wave = waves(wave_uv);
	
	// Градиент цвета в зависимости от глубины
	// Используем расстояние от центра или Y координату для глубины
	float depth_factor = smoothstep(0.0, 1.0, wave);
	vec4 water_color = mix(shallow_color, deep_color, depth_factor);
	
	// Добавляем оттенок от волн
	water_color.rgb += vec3(0.1, 0.15, 0.2) * wave * 0.2;
	
	ALBEDO = water_color.rgb;
	ALPHA = water_color.a * transparency;
	METALLIC = metallic;
	ROUGHNESS = roughness;
}

