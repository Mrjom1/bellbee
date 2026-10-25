class_name Art

## Shared drawing helpers. Every sprite in the game is drawn from these shapes at runtime,
## so the art stays sharp at any window size and the project needs no image files.

const SHIP_BLUE := Color(0.33, 0.6, 1.0)
const SHADOW_COLOR := Color(0.04, 0.08, 0.2, 0.26)

# Grayscale lit sphere (tinted by the draw colour), its white specular spot, and a soft glow.
static var sphere: Texture2D
static var spec: Texture2D
static var glow: Texture2D

static var _bell_shape := PackedVector2Array()


static func init() -> void:
	if sphere != null:
		return

	var n := 64
	var sphere_image := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var spec_image := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var glow_image := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var light := Vector3(-0.45, -0.6, 0.66).normalized()
	var bounce := Vector3(0.3, 0.8, 0.2).normalized()
	var half := (light + Vector3(0, 0, 1)).normalized()
	var c := (n - 1) * 0.5

	for y in range(n):
		for x in range(n):
			var dx := (x - c) / c
			var dy := (y - c) / c
			var d := sqrt(dx * dx + dy * dy)
			glow_image.set_pixel(x, y, Color(1, 1, 1, pow(clampf(1.0 - d, 0.0, 1.0), 1.7)))

			var edge := clampf((1.0 - d) * c * 0.9, 0.0, 1.0)
			if edge <= 0.0:
				continue
			var normal := Vector3(dx, dy, sqrt(maxf(0.0, 1.0 - d * d)))
			var shade := 0.5 + 0.5 * clampf(normal.dot(light), 0.0, 1.0)
			# Light bounced up from the ground keeps the shadow side from going flat.
			shade += 0.1 * clampf(normal.dot(bounce), 0.0, 1.0)
			sphere_image.set_pixel(x, y, Color(shade, shade, shade, edge))
			var shine := pow(clampf(normal.dot(half), 0.0, 1.0), 28.0)
			spec_image.set_pixel(x, y, Color(1, 1, 1, shine * edge))

	sphere = ImageTexture.create_from_image(sphere_image)
	spec = ImageTexture.create_from_image(spec_image)
	glow = ImageTexture.create_from_image(glow_image)

	# Right half of a bell, top to lip, in units of its radius; mirrored for the left half.
	var profile := [
		Vector2(0.0, -1.0), Vector2(0.22, -0.97), Vector2(0.42, -0.85), Vector2(0.53, -0.62),
		Vector2(0.58, -0.28), Vector2(0.63, 0.08), Vector2(0.74, 0.38), Vector2(0.93, 0.6),
		Vector2(0.98, 0.73), Vector2(0.82, 0.8), Vector2(0.4, 0.83),
	]
	for p in profile:
		_bell_shape.append(p)
	for i in range(profile.size() - 1, 0, -1):
		_bell_shape.append(Vector2(-profile[i].x, profile[i].y))


## Shaded ball with a specular highlight and a thin dark outline.
static func ball(ci: CanvasItem, p: Vector2, r: float, color: Color, outline := true) -> void:
	var rect := Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0)
	ci.draw_texture_rect(sphere, rect, false, color)
	ci.draw_texture_rect(spec, rect, false, Color(1, 1, 1, 0.9 * color.a))
	if outline and r > 2.5:
		var line := color.darkened(0.55)
		line.a = color.a * 0.7
		ci.draw_arc(p, r - 0.4, 0.0, TAU, maxi(12, int(r * 2.0)), line, 1.1, true)


static func glow_at(ci: CanvasItem, p: Vector2, r: float, color: Color) -> void:
	ci.draw_texture_rect(glow, Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), false, color)


static func soft_shadow(ci: CanvasItem, p: Vector2, r: float, alpha := 1.0) -> void:
	var color := SHADOW_COLOR
	color.a *= alpha
	ci.draw_colored_polygon(ellipse_points(p, r, r * 0.6, 0.0, 20), color)


static func ellipse_points(p: Vector2, rx: float, ry: float, rotation := 0.0, segments := 24) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var a := TAU * i / segments
		points.append(p + Vector2(cos(a) * rx, sin(a) * ry).rotated(rotation))
	return points


static func ellipse(ci: CanvasItem, p: Vector2, rx: float, ry: float, color: Color, rotation := 0.0) -> void:
	ci.draw_colored_polygon(ellipse_points(p, rx, ry, rotation), color)


## Ellipse with a vertical gradient (top colour to bottom colour).
static func ellipse_gradient(ci: CanvasItem, p: Vector2, rx: float, ry: float, top: Color, bottom: Color) -> void:
	var points := ellipse_points(p, rx, ry, 0.0, 28)
	var colors := PackedColorArray()
	for point in points:
		colors.append(top.lerp(bottom, clampf((point.y - p.y) / (ry * 2.0) + 0.5, 0.0, 1.0)))
	ci.draw_polygon(points, colors)


static func star(ci: CanvasItem, p: Vector2, r: float, color: Color, rotation := 0.0) -> void:
	var points := PackedVector2Array()
	for i in range(8):
		var radius := r if i % 2 == 0 else r * 0.28
		points.append(p + Vector2.from_angle(rotation + TAU * i / 8.0) * radius)
	ci.draw_colored_polygon(points, color)


## The player's ship: a round blue flyer with a glass dome, two arms with white gloves, and booster pods.
static func ship(
	ci: CanvasItem,
	p: Vector2,
	s: float,
	t: float,
	arm_left: bool,
	arm_right: bool,
	tilt: float,
	alpha := 1.0,
	body := SHIP_BLUE
) -> void:
	var flicker := 0.8 + 0.2 * sin(t * 47.0)
	var a := alpha

	# Booster flames.
	for side in [-1.0, 1.0]:
		var nozzle := p + Vector2(side * 8.0 - tilt * 2.0, 17.0) * s
		glow_at(ci, nozzle + Vector2(0, 5) * s, 11.0 * s * flicker, Color(1.0, 0.55, 0.15, 0.85 * a))
		glow_at(ci, nozzle + Vector2(0, 2) * s, 6.0 * s * flicker, Color(1.0, 0.95, 0.7, a))

	# Booster pods.
	for side in [-1.0, 1.0]:
		ball(ci, p + Vector2(side * 8.5 - tilt * 1.5, 11.0) * s, 6.5 * s, _alpha(body.darkened(0.28), a))

	# Arms with gloves; they swing with the bank.
	var bob := sin(t * 6.0) * 1.2
	for side in [-1.0, 1.0]:
		var has_arm := arm_left if side < 0.0 else arm_right
		if not has_arm:
			# A small capped stump where the arm was.
			ball(ci, p + Vector2(side * 14.0, 1.0) * s, 3.0 * s, _alpha(body.darkened(0.4), a))
			continue
		var shoulder := p + Vector2(side * 12.0, 1.0) * s
		var hand := p + Vector2(side * 21.0, -3.0 + bob + side * tilt * 3.0) * s
		ci.draw_line(shoulder, hand, _alpha(body.darkened(0.35), a), 3.6 * s, true)
		ball(ci, hand, 5.0 * s, _alpha(Color(1.0, 1.0, 1.0), a))

	# Body, belly band, nose, and dome.
	ball(ci, p, 15.0 * s, _alpha(body, a))
	ci.draw_arc(p + Vector2(0, 1.5) * s, 13.3 * s, 0.25, PI - 0.25, 18, Color(1, 1, 1, 0.85 * a), 2.6 * s, true)
	ball(ci, p + Vector2(0, -13.5) * s, 3.4 * s, _alpha(Color(1.0, 0.45, 0.55), a))
	ball(ci, p + Vector2(-tilt * 1.5, -4.0) * s, 7.6 * s, _alpha(Color(0.72, 0.93, 1.0), a))


## A bell, swaying on its loop. `rotation` is the sway angle.
static func bell(ci: CanvasItem, p: Vector2, r: float, color: Color, rotation: float, alpha := 1.0) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var light := color.lightened(0.5)
	var dark := color.darkened(0.35)
	for unit in _bell_shape:
		points.append(p + (unit * r).rotated(rotation))
		var tone := light.lerp(color, clampf(unit.x * 1.6 + 1.0, 0.0, 1.0))
		if unit.x > 0.0:
			tone = color.lerp(dark, clampf(unit.x * 1.2, 0.0, 1.0))
		tone = tone.darkened(clampf(unit.y, 0.0, 1.0) * 0.12)
		tone.a = alpha
		colors.append(tone)

	glow_at(ci, p, r * 2.2, Color(color.r, color.g, color.b, 0.32 * alpha))
	ball(ci, p + Vector2(0, r * 0.9).rotated(rotation), r * 0.2, _alpha(color.darkened(0.3), alpha))
	ci.draw_polygon(points, colors)

	var outline := points.duplicate()
	outline.append(points[0])
	ci.draw_polyline(outline, _alpha(color.darkened(0.6), alpha * 0.85), 1.3, true)

	# Lip band and the hanging loop.
	var lip_left := p + (Vector2(-0.88, 0.67) * r).rotated(rotation)
	var lip_right := p + (Vector2(0.88, 0.67) * r).rotated(rotation)
	ci.draw_line(lip_left, lip_right, _alpha(color.darkened(0.25), alpha), r * 0.16, true)
	ci.draw_arc(p + (Vector2(0, -1.12) * r).rotated(rotation), r * 0.17, 0.0, TAU, 12,
		_alpha(color.darkened(0.45), alpha), 1.6, true)

	# Highlight streak.
	ellipse(ci, p + (Vector2(-0.24, -0.4) * r).rotated(rotation), r * 0.1, r * 0.3,
		Color(1, 1, 1, 0.8 * alpha), rotation + 0.18)


static func _alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, color.a * alpha)
