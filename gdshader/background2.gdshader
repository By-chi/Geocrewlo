shader_type canvas_item;

uniform float separation: hint_range(0.0, 0.2) = 0.05;
uniform float radius: hint_range(0.0, 0.1) = 0.001;
uniform float min_thick: hint_range(0.0, 1.0) = 0.2;
uniform float speed: hint_range(0.0, 0.1) = 0.04;
uniform bool tilt_45 = true;
uniform float direction: hint_range(-180.0, 180.0) = -45.0;
uniform sampler2D noise_texture: repeat_enable;
uniform vec4 color1: source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform vec4 color2: source_color = vec4(0.0, 0.8, 0.4, 1.0);

float get_line(vec2 uv, vec2 point1, vec2 point2, vec2 dir) {
	// get the distance of the uv from our line
	float line_dist = length(cross(vec3(point2 - point1, 0.0), vec3(point1 - uv, 0.0))) / length(point2 - point1);
	// Calculate the position along the line
	float t = dot(uv - point1, point2 - point1) / dot(point2 - point1, point2 - point1);
	// sample the noise midpoint at the midpoint of the line
	vec2 midpoint = (point1 + point2) / 2.0;
	float sample = smoothstep(0.0, 1.0, texture(noise_texture, 
		midpoint + -dir * speed * TIME
		).r);
	// calculate our thickness range
	float range = (sample - 0.5) * 2.0 + 0.5;
	float min_thickness = radius * min_thick * (range);
	float max_thickness = radius * 0.95;
	// use a gaussian function for the curve of the connecting line
	float line_thickness = mix(max_thickness, min_thickness, exp(-pow((t - 0.5) * 4.0, 2.0)));
	// is our pixel within the line?
	float line = mix(0.0, 1.0, step(line_dist, line_thickness * 0.8));
	// cut off the line after a certain point if the line would be thin enough
	line = mix(0.0, line, step(0.2, sample));
	return line;
}

void fragment() {
	// set up the direction
	float direction_radians = radians(direction);
	vec2 dir = vec2(sin(direction_radians), cos(direction_radians));
	// preserve ratio
	float ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	vec2 uv = vec2(SCREEN_UV.x, SCREEN_UV.y * ratio)
		+ dir * speed * TIME;
	// rotate by 45 if checked
	float angle = PI / 4.0 * float(tilt_45);
	uv = vec2(cos(angle) * uv.x - sin(angle) * uv.y, sin(angle) * uv.x + cos(angle) * uv.y);
	// get our circle points
	vec2 point1 = vec2(floor(uv.x / separation), round(uv.y / separation)) * separation;
	vec2 point2 = vec2(point1.x + separation, point1.y);
	vec2 cpoint1 = vec2(round(uv.x / separation), floor(uv.y / separation)) * separation;
	vec2 cpoint2 = vec2(cpoint1.x, cpoint1.y + separation);
	// this is going to draw two half circles
	float circle1 = mix(0.0, 1.0, step(distance(uv, point1), radius));
	float circle2 = mix(0.0, 1.0, step(distance(uv, point2), radius));
	// horizontal line connection and vertical line
	float line1 = get_line(uv, point1, point2, dir);
	float line4 = get_line(uv, cpoint1, cpoint2, dir);
	// merge all of our pixel values
	// if our uv is one of these lines or circles, then it's 1.0
	float lines = max(line1, line4);
	float circles = max(circle1, circle2);
	// make our pixel white where ever there are lines or circle pixels
	float shape = max(circles, lines);
	// we replace black with color2 and white with color1
	vec4 color = mix(color2, color1, shape);
	COLOR = color;
}