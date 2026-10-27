// soft_look.gdshader — sanftes 2D-Post-Processing (Godot 4, CanvasItem)
//
// Quellen / Vorlage (auf GitHub recherchiert):
//  * godotengine/godot-docs — "Custom post-processing" (Single-Pass-Pattern:
//    CanvasLayer + ColorRect + hint_screen_texture + SCREEN_UV)
//  * godotshaders.com — Rezepte für Vignette / Bloom / Farb-Grading
//    (z.B. "Screen"), sowie PSCactux/godot-effects-lab (hint_screen_texture-Stil)
//
// Wirkung: weiche Kanten (5-Tap-Weichzeichner), dezenter Glow auf hellen
// Flächen, leicht angehobene Schatten, sanfte Sättigung/Wärme und Vignette.
// Bewusst billig gehalten (5 Texture-Taps), damit es auf Android flüssig bleibt.

shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

uniform float softness : hint_range(0.0, 1.0) = 0.45;      // weiche Kanten
uniform float bloom_strength : hint_range(0.0, 1.0) = 0.22; // Glow auf Highlights
uniform float bloom_radius : hint_range(0.0, 4.0) = 2.0;
uniform float lift : hint_range(0.0, 0.2) = 0.030;          // Schatten anheben (soft)
uniform float saturation : hint_range(0.5, 1.6) = 1.07;
uniform float warmth : hint_range(-0.1, 0.1) = 0.020;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.20;

void fragment() {
	// 5-Tap-Weichzeichner (nur auf Grafikstufe HOCH aktiv)
	vec2 px = SCREEN_PIXEL_SIZE * bloom_radius;

	vec3 c = texture(screen_texture, SCREEN_UV).rgb;

	vec3 soft = c * 0.44;
	soft += texture(screen_texture, SCREEN_UV + vec2(px.x, px.y)).rgb * 0.14;
	soft += texture(screen_texture, SCREEN_UV - vec2(px.x, px.y)).rgb * 0.14;
	soft += texture(screen_texture, SCREEN_UV + vec2(px.x, -px.y)).rgb * 0.14;
	soft += texture(screen_texture, SCREEN_UV + vec2(-px.x, px.y)).rgb * 0.14;

	vec3 col = mix(c, soft, softness);

	// Bloom: nur helle Bereiche aufglühen lassen
	vec3 bright = max(soft - vec3(0.58), vec3(0.0));
	col += bright * bloom_strength;

	// Farb-Grading
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, saturation);                 // Sättigung
	col += vec3(warmth, warmth * 0.45, -warmth * 0.55);  // leichte Wärme
	col = clamp(col + lift * (1.0 - l), 0.0, 1.0);       // Schatten anheben

	// Vignette (weich, keine harte Kante)
	float vig = 1.0 - smoothstep(0.42, 1.15, length(SCREEN_UV - vec2(0.5)) * 1.55);
	col *= mix(1.0, vig, vignette_strength);

	COLOR = vec4(col, 1.0);
}
