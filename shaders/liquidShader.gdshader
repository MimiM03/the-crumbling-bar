// ANCHOR: all
shader_type spatial;
render_mode cull_disabled,shadows_disabled;

uniform float fill_percent : hint_range(0.0, 1.0) = 0.5;
// ANCHOR: surface_color
uniform vec4 liquid_surface_color: source_color = vec4(0.7, 0.5, 1.0, 1.0);
// END: surface_color
uniform sampler2D liquid_rim_gradient;
uniform float rim_emission_intensity: hint_range(0.0, 2.0) = 0.2;
uniform float rim_exponent: hint_range(1.0, 10.0) = 3.0;
uniform float emission_intensity:hint_range(0.0, 3.0) = 0.1;
// ANCHOR: gradient_size
uniform float liquid_surface_gradient_size: hint_range(0.0, 3.0) = 0.1;
// END: gradient_size
uniform vec2 wobble = vec2(0.0, 0.0); 
uniform float world_bottom_y = 0.0;
uniform float world_vertical_length = 0.55;
// ANCHOR: varying
varying float y_coordinate;
// END: varying
// ANCHOR: rotate
mat4 rotate_x(in float angle) {
	return mat4(
			vec4(1.0,0.0,0.0,0.0),
			vec4(0.0,cos(angle),-sin(angle),0.0),
			vec4(0.0,sin(angle),cos(angle),0.0),
			vec4(0.0,0.0,0.0,1.0));
}

mat4 rotate_z(in float angle) {
	return mat4(
			vec4(cos(angle),-sin(angle), 0.0, 0.0),
			vec4(sin(angle),cos(angle), 0.0, 0.0),
			vec4(0.0,0.0,1.0,0.0),
			vec4(0.0,0.0,0.0,1.0));
}
// END: rotate
void vertex() {
	// ANCHOR: vertex
	vec3 rotated_vert_z = (rotate_z(1.6) * vec4(VERTEX, 1.0)).xyz;
	vec3 rotated_vert_x = (rotate_x(-1.6) * vec4(VERTEX, 1.0)).xyz;
	vec3 vert = (rotated_vert_z * wobble.x + rotated_vert_x * wobble.y) + VERTEX;
	vec3 world_v = (MODEL_MATRIX * vec4(vert, 1.0)).xyz;
	// The script passes the liquid mesh bounds in world space so the fill level stays
	// stable even when imported bottles use different local axes.
	y_coordinate = (world_v.y - world_bottom_y) / max(world_vertical_length, 0.001);
	// END: vertex
}

void fragment() {
	// ANCHOR: fresnel
	float fresnel = dot(normalize(NORMAL), normalize(VERTEX));
	fresnel = abs(fresnel);
	fresnel = 1.0 - fresnel;
	float pow_fresnel = pow(fresnel, rim_exponent);
	// END: fresnel
	// ANCHOR: discard
	if (y_coordinate > fill_percent) {
		discard;
	}
	// END: discard
	if (FRONT_FACING) {
		// ANCHOR: liquid_color
		vec4 liquid_color = texture(liquid_rim_gradient, vec2(pow_fresnel));
		// END: liquid_color
		// ANCHOR: surface_component
		float surface_component = smoothstep(
				fill_percent - liquid_surface_gradient_size,
				fill_percent,
				y_coordinate);
		// END: surface_component
		// ANCHOR: surface_mix
		ALBEDO = mix(liquid_color.rgb, liquid_surface_color.rgb, surface_component);
		// END: surface_mix
	} else {
		// This is an approximation of the normal.
		// the normal of the backface will always point up
		// ANCHOR: inv_camera
		NORMAL = (INV_PROJECTION_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
		// END: inv_camera
		// ANCHOR: albedo_ao
		ALBEDO = liquid_surface_color.rgb;
		// this is needed because we want the backfaces to look solid
		// if we let it be affected by AO, it will reveal the trick
		AO_LIGHT_AFFECT = 0.0;
		// END: albedo_ao
	}
	// Magical liquid!
	EMISSION = ALBEDO * (pow_fresnel * rim_emission_intensity + emission_intensity);
}
// END: all