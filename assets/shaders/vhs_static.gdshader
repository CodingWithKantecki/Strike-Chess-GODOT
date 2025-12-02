shader_type canvas_item;
render_mode blend_add;

// VHS Static Overlay - adds static noise on top of scene
uniform float intensity : hint_range(0.0, 1.0) = 0.12;
uniform float speed : hint_range(0.1, 3.0) = 0.5;
uniform float grain_size : hint_range(1.0, 8.0) = 3.0;
uniform vec2 screen_size = vec2(1445.0, 940.0);

// Hash function for random noise
float hash(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

void fragment() {
    vec2 uv = SCREEN_UV * screen_size;

    // Pixelate for chunky static grain
    vec2 grain_uv = floor(uv / grain_size);

    // Time that updates in discrete steps (like real TV)
    float t = floor(TIME * 10.0 * speed);

    // Generate static noise
    float noise = hash(grain_uv + t);

    // Add horizontal band variation
    float band = hash(vec2(t * 0.1, floor(SCREEN_UV.y * 100.0)));
    noise = mix(noise, band, 0.2);

    // Threshold for hard black/white
    float static_bw = step(0.5, noise);

    // Output - white pixels only, black becomes transparent
    float alpha = static_bw * intensity;
    COLOR = vec4(1.0, 1.0, 1.0, alpha);
}
