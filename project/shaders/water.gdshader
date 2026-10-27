// Runde 23: ruhiges, fliesendes Wasser. Nur dezente Ripples im Blau, KEINE
// weissen Gischt-Baender in der Mitte (die wirkten wie Loecher im Fluss).
// Schaum gibt es ausschliesslich als schmale Kante am Ufer (R-Kanal der Maske).
shader_type canvas_item;
render_mode blend_mix;

uniform vec2 tiles = vec2(20.0, 80.0);
uniform float speed = 0.30;
uniform vec4 deep : source_color = vec4(0.08, 0.29, 0.46, 1.0);
uniform vec4 light : source_color = vec4(0.22, 0.55, 0.78, 1.0);
uniform vec4 foam : source_color = vec4(0.80, 0.92, 0.98, 1.0);

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	if (src.a < 0.03) {
		COLOR = vec4(0.0);
	} else {
		vec2 uvw = UV * tiles;
		// zwei langsame Wellen -> fliesende Bewegung, bleibt im Blaubereich
		float w1 = sin(uvw.y * 2.6 + TIME * 2.0 + sin(uvw.x * 0.8) * 1.4);
		float w2 = sin(uvw.y * 5.1 - TIME * 3.0 + uvw.x * 1.3);
		float m = 0.5 + 0.26 * w1 + 0.18 * w2;
		vec3 col = mix(deep.rgb, light.rgb, clamp(m, 0.0, 1.0));
		// Schaum NUR am Ufer
		col = mix(col, foam.rgb, clamp(src.r, 0.0, 1.0));
		COLOR = vec4(col, src.a);
	}
}
