shader_type spatial;
render_mode cull_disabled;

// The viewport texture gets plugged into here
uniform sampler2D ticket_texture : source_color;

uniform float curvature : hint_range(-2.0, 2.0) = 0.5;
uniform float curl_direction : hint_range(0.0, 1.0) = 0.0;

void vertex() {
    float dist = mix(VERTEX.x, VERTEX.z, curl_direction);
    VERTEX.y += pow(abs(dist), 2.0) * curvature * sign(dist);
}

void fragment() {
    // Read the pixel color from our SubViewport text layout using UV coordinates
    vec4 tex_color = texture(ticket_texture, UV);
    
    // Apply the texture color directly to the paper mesh
    ALBEDO = tex_color.rgb;
    ROUGHNESS = 0.8;
}