class_name Ground
extends Node2D

## Scrolling ground: the shader paints fields and water, this node draws trees, houses and bomb scorches on top.

const SHADER := preload("res://Shaders/ground.gdshader")
const CHUNK := 320.0
const SCORCH_LIFE := 8.0

var theme: Dictionary
var scroll := 0.0
var seed_base := 0
var rect: ColorRect
var chunks := {}
var scorches: Array = []


func setup(p_theme: Dictionary, p_seed: int) -> void:
	theme = p_theme
	seed_base = p_seed


func _ready() -> void:
	rect = ColorRect.new()
	rect.size = Vector2(Stage.W, Stage.H)
	rect.show_behind_parent = true
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = SHADER
	var fields: Array = theme["fields"]
	material.set_shader_parameter("screen_size", Vector2(Stage.W, Stage.H))
	material.set_shader_parameter("mode", theme["mode"])
	material.set_shader_parameter("field_a", fields[0])
	material.set_shader_parameter("field_b", fields[1])
	material.set_shader_parameter("field_c", fields[2])
	material.set_shader_parameter("field_d", fields[3])
	for key in ["hedge", "water_deep", "water_shallow", "sand", "haze"]:
		material.set_shader_parameter(key, theme[key])
	rect.material = material
	add_child(rect)


func _process(delta: float) -> void:
	(rect.material as ShaderMaterial).set_shader_parameter("scroll", scroll)
	for scorch in scorches:
		scorch["age"] += delta
	scorches = scorches.filter(func(s): return s["age"] < SCORCH_LIFE)
	queue_redraw()


func world_y(screen_y: float) -> float:
	return scroll + Stage.H - screen_y


func screen_y(wy: float) -> float:
	return Stage.H - (wy - scroll)


func land_distance(x: float, sy: float) -> float:
	return Themes.land_distance(theme["mode"], x, world_y(sy))


func is_land(x: float, sy: float, margin := 18.0) -> bool:
	return land_distance(x, sy) > margin


## Finds a land x near `x` on screen row `sy`, or returns NAN if the row is all water.
func find_land_x(x: float, sy: float, margin := 22.0) -> float:
	for offset in [0.0, 40.0, -40.0, 80.0, -80.0, 130.0, -130.0, 190.0, -190.0]:
		var candidate := clampf(x + offset, 30.0, Stage.W - 30.0)
		if is_land(candidate, sy, margin):
			return candidate
	return NAN


func add_scorch(p: Vector2) -> void:
	scorches.append({"x": p.x, "wy": world_y(p.y), "age": 0.0, "angle": randf() * TAU})


func _draw() -> void:
	for scorch in scorches:
		var p := Vector2(scorch["x"], screen_y(scorch["wy"]))
		var fade: float = 1.0 - scorch["age"] / SCORCH_LIFE
		Art.ellipse(self, p, 16.0, 11.0, Color(0.22, 0.15, 0.1, 0.42 * fade), scorch["angle"])
		Art.ellipse(self, p, 9.0, 6.0, Color(0.12, 0.08, 0.06, 0.4 * fade), scorch["angle"])

	var first := int(floor((scroll - 60.0) / CHUNK))
	var last := int(floor((scroll + Stage.H + 60.0) / CHUNK))
	# Far chunks first so nearer decorations overlap them.
	for k in range(last, first - 1, -1):
		for decor in _chunk(k):
			var p := Vector2(decor["x"], screen_y(decor["wy"]))
			if p.y < -40.0 or p.y > Stage.H + 40.0:
				continue
			if decor["kind"] == "tree":
				_draw_tree(p, decor["r"], decor["color"])
			else:
				_draw_house(p, decor["r"], decor["color"], decor["angle"])

	for k in chunks.keys():
		if k < first - 2:
			chunks.erase(k)


func _chunk(k: int) -> Array:
	if chunks.has(k):
		return chunks[k]

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(seed_base * 7919 + 13, k))
	var list: Array = []
	var trees: Array = theme["trees"]
	var roofs: Array = theme["roofs"]

	for cluster in range(rng.randi_range(3, 5)):
		var cx := rng.randf_range(10.0, Stage.W - 10.0)
		var cwy := k * CHUNK + rng.randf_range(0.0, CHUNK)
		for i in range(rng.randi_range(3, 8)):
			var x := cx + rng.randf_range(-34.0, 34.0)
			var wy := cwy + rng.randf_range(-26.0, 26.0)
			if Themes.land_distance(theme["mode"], x, wy) < 16.0:
				continue
			list.append({"kind": "tree", "x": x, "wy": wy, "r": rng.randf_range(7.0, 12.0),
				"color": trees[rng.randi() % trees.size()], "angle": 0.0})

	for i in range(rng.randi_range(0, 3)):
		var x := rng.randf_range(20.0, Stage.W - 20.0)
		var wy := k * CHUNK + rng.randf_range(0.0, CHUNK)
		if Themes.land_distance(theme["mode"], x, wy) < 24.0:
			continue
		list.append({"kind": "house", "x": x, "wy": wy, "r": rng.randf_range(8.0, 11.0),
			"color": roofs[rng.randi() % roofs.size()], "angle": rng.randf_range(-0.3, 0.3)})

	# Higher world y is further up the screen, so draw those first.
	list.sort_custom(func(a, b): return a["wy"] > b["wy"])
	chunks[k] = list
	return list


func _draw_tree(p: Vector2, r: float, color: Color) -> void:
	Art.ellipse(self, p + Vector2(r * 0.5, r * 0.65), r * 1.05, r * 0.7, Color(0.05, 0.12, 0.05, 0.28))
	draw_circle(p, r, color.darkened(0.3), true, -1.0, true)
	draw_circle(p + Vector2(-r * 0.15, -r * 0.18), r * 0.8, color, true, -1.0, true)
	draw_circle(p + Vector2(-r * 0.32, -r * 0.36), r * 0.45, color.lightened(0.2), true, -1.0, true)
	draw_circle(p + Vector2(-r * 0.42, -r * 0.46), r * 0.18, color.lightened(0.45), true, -1.0, true)


func _draw_house(p: Vector2, r: float, roof: Color, angle: float) -> void:
	var w := r * 1.4
	var h := r
	var corners := [Vector2(-w, -h), Vector2(w, -h), Vector2(w, h), Vector2(-w, h)]
	var shadow := PackedVector2Array()
	for c in corners:
		shadow.append(p + (c + Vector2(4, 5)).rotated(angle))
	draw_colored_polygon(shadow, Color(0.05, 0.08, 0.05, 0.3))

	# Two roof slopes meeting at the ridge: lit side and shade side.
	var ridge_a := p + Vector2(-w, 0).rotated(angle)
	var ridge_b := p + Vector2(w, 0).rotated(angle)
	var lit := PackedVector2Array([p + corners[0].rotated(angle), p + corners[1].rotated(angle), ridge_b, ridge_a])
	var shade := PackedVector2Array([ridge_a, ridge_b, p + corners[2].rotated(angle), p + corners[3].rotated(angle)])
	draw_colored_polygon(lit, roof.lightened(0.15))
	draw_colored_polygon(shade, roof.darkened(0.2))
	draw_line(ridge_a, ridge_b, roof.darkened(0.45), 1.5, true)
	var outline := PackedVector2Array()
	for c in corners + [corners[0]]:
		outline.append(p + c.rotated(angle))
	draw_polyline(outline, roof.darkened(0.5), 1.0, true)
	# Chimney.
	var chimney := p + Vector2(w * 0.45, -h * 0.5).rotated(angle)
	draw_rect(Rect2(chimney - Vector2(2, 2), Vector2(4, 4)), Color(0.55, 0.45, 0.4))
