shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform float sway_strength = 0.1;
uniform float sway_speed = 1.5;
uniform vec3 wind_direction = vec3(1.0, 0.0, 0.0);
uniform float object_height = 1.0;
uniform float variation_scale = 5.0;
uniform sampler2D albedo_texture;

void vertex() {
    // Add variation by using the vertex position (XZ) as offset
    float variation = sin((VERTEX.x + VERTEX.z) * variation_scale);

    // Sway based on time and vertex position
    float sway_amount = sin(TIME * sway_speed + variation) * sway_strength;

    // Scale sway by vertical position to keep base still
    float sway_factor = clamp(VERTEX.y / object_height, 0.0, 1.0);

    VERTEX.xyz += wind_direction * sway_amount * sway_factor;
}

void fragment() {
    vec3 tex_color = texture(albedo_texture, UV).rgb;
	ALBEDO = pow(tex_color, vec3(2.2));
	ROUGHNESS = 0.0;
	RIM = 1.0;
}
