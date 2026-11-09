// v1.42 (P7): Wasser mit Flussrichtung, Tiefenwirkung (4 Blautoene) und
// pulsierendem Schaum an Uferkante und Steinen. Die Masken-Textur liefert zwei
// Kanaele: R = Uferkante/Schaum (0..1), G = Tiefe (0 = Ufer, 1 = Flussmitte).
shader_type canvas_item;
render_mode blend_mix;

uniform vec2 tiles = vec2(20.0, 80.0);
uniform float speed = 0.30;
// P7.1: Flussachse in UV-Richtung - die Stroemung laeuft sichtbar entlang
uniform vec2 flow_dir = vec2(0.0, 1.0);
uniform vec4 tone0 : source_color = vec4(0.36, 0.68, 0.86, 1.0);
uniform vec4 tone1 : source_color = vec4(0.24, 0.56, 0.78, 1.0);
uniform vec4 tone2 : source_color = vec4(0.14, 0.42, 0.66, 1.0);
uniform vec4 tone3 : source_color = vec4(0.06, 0.27, 0.48, 1.0);
uniform vec4 foam : source_color = vec4(0.86, 0.95, 1.0, 1.0);

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	if (src.a < 0.03) {
		COLOR = vec4(0.0);
	} else {
		float depth = clamp(src.g, 0.0, 1.0);
		vec2 uvw = UV * tiles;
		vec2 fd = normalize(flow_dir);
		// Stroemung entlang der Flussachse, quer dazu nur Wellen
		float along = dot(uvw, fd);
		float across = dot(uvw, vec2(-fd.y, fd.x));
		float flow = along * 1.1 - TIME * speed * 6.0;
		float streak = sin(flow * 1.7 + sin(across * 0.7) * 1.3);
		float ripple = sin(flow * 3.6 + sin(across * 1.6 + TIME * 0.6) * 1.1);
		float m = 0.5 + 0.22 * streak + 0.13 * ripple;
		// P7.2: vier Blautoene nach Tiefe
		vec3 col = mix(tone0.rgb, tone1.rgb, clamp(depth * 3.0, 0.0, 1.0));
		col = mix(col, tone2.rgb, clamp((depth - 0.35) * 3.0, 0.0, 1.0));
		col = mix(col, tone3.rgb, clamp((depth - 0.70) * 3.5, 0.0, 1.0));
		col *= (0.92 + 0.16 * m);
		// Stromschnellen an Engstellen (flaches Wasser): helle Streifen
		float narrow = 1.0 - smoothstep(0.0, 0.32, depth);
		col = mix(col, foam.rgb, narrow * 0.22 * (0.5 + 0.5 * sin(flow * 4.0)));
		// P7.3: Schaum nur an der Uferkante, pulsierend
		float pulse = 0.55 + 0.45 * sin(TIME * 3.2 + along * 0.8);
		col = mix(col, foam.rgb, clamp(src.r, 0.0, 1.0) * pulse);
		COLOR = vec4(col, src.a);
	}
}
