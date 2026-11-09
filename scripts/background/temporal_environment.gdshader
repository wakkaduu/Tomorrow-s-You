shader_type canvas_item;

// Uniforms supplied by TemporalBackground
uniform vec4 bg_dark : source_color = vec4(0.043, 0.063, 0.125, 1.0);
uniform vec4 bg_mid : source_color = vec4(0.078, 0.110, 0.180, 1.0);
uniform vec4 primary_glow : source_color = vec4(0.329, 0.902, 0.918, 1.0);
uniform vec4 secondary_glow : source_color = vec4(0.655, 0.545, 0.980, 1.0);

uniform vec2 glow_center = vec2(0.5, 0.38);
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float beam_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.55;
uniform float pulse : hint_range(0.5, 1.5) = 1.0;
uniform float fog_density : hint_range(0.0, 0.5) = 0.10;
uniform float time_offset = 0.0;

// High quality pseudo-random dither to prevent 8-bit mobile banding
float pseudo_dither(vec2 coord) {
	return fract(sin(dot(coord, vec2(12.9898, 78.233))) * 43758.5453) * 0.015 - 0.0075;
}

void fragment() {
	vec2 uv = UV;
	
	// 1. Base vertical environment gradient
	float vert = smoothstep(0.0, 1.0, uv.y);
	vec4 base_color = mix(bg_mid, bg_dark, vert);
	
	// 2. Radial atmospheric glow around temporal core
	vec2 diff = uv - glow_center;
	// Aspect correction (portrait orientation 9:16 ~ 0.5625)
	diff.y *= 1.4;
	float dist = length(diff);
	
	float radial_glow = clamp(1.0 - smoothstep(0.0, 0.65, dist), 0.0, 1.0);
	float core_glow = clamp(1.0 - smoothstep(0.0, 0.22, dist), 0.0, 1.0);
	
	vec4 glow_col = mix(primary_glow, secondary_glow, smoothstep(0.1, 0.5, dist));
	vec4 ambient = glow_col * (radial_glow * 0.35 + core_glow * 0.65) * glow_intensity * pulse;
	
	// 3. Volumetric downward atmospheric light rays / beams
	float angle = atan(diff.y, diff.x);
	float beam = sin(angle * 6.0 + sin(time_offset * 0.15) * 0.5) * 0.5 + 0.5;
	beam *= sin(angle * 14.0 - time_offset * 0.1) * 0.5 + 0.5;
	float beam_falloff = clamp(1.0 - smoothstep(0.1, 0.75, dist), 0.0, 1.0);
	// Concentrate beams towards the bottom
	float beam_mask = smoothstep(-0.2, 0.8, diff.y);
	vec4 beam_col = primary_glow * beam * beam_falloff * beam_mask * beam_intensity;
	
	// 4. Subtle atmospheric fog drift
	float fog = sin(uv.y * 8.0 + uv.x * 3.0 + time_offset * 0.2) * 0.5 + 0.5;
	fog *= sin(uv.y * 14.0 - uv.x * 5.0 - time_offset * 0.12) * 0.5 + 0.5;
	vec4 fog_col = mix(primary_glow, secondary_glow, 0.5) * fog * fog_density * (1.0 - dist * 0.8);
	
	// Composite lighting layers
	vec4 final_color = base_color + ambient + beam_col + fog_col;
	
	// 5. Restrained peripheral vignette
	vec2 vig_uv = abs(uv - 0.5) * 2.0;
	float vig = smoothstep(0.35, 1.25, length(vig_uv)) * vignette_strength;
	final_color = mix(final_color, bg_dark * 0.4, clamp(vig, 0.0, 0.95));
	
	// 6. Anti-banding dither
	final_color.rgb += pseudo_dither(FRAGCOORD.xy);
	
	COLOR = vec4(final_color.rgb, 1.0);
}

