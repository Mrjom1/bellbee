class_name Fx
extends Node2D

## Lightweight effects: glowing sparks and rings (additive), smoke puffs and falling debris (normal),
## and floating score text.

var sparks: Array = []
var smokes: Array = []
var debris: Array = []
var rings: Array = []
var popups: Array = []
var glow_layer: Node2D


func _ready() -> void:
	glow_layer = Node2D.new()
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow_layer.material = material
	add_child(glow_layer)
	glow_layer.draw.connect(_draw_glow)


func burst(p: Vector2, color: Color, count := 14, speed := 160.0, size := 3.0, life := 0.5) -> void:
	for i in range(count):
		var v := Vector2.from_angle(randf() * TAU) * speed * randf_range(0.3, 1.0)
		sparks.append({"p": p, "v": v, "life": life * randf_range(0.6, 1.0), "max": life,
			"size": size * randf_range(0.6, 1.3), "color": color})


func puff(p: Vector2, color := Color(1, 1, 1, 0.8), count := 3) -> void:
	for i in range(count):
		smokes.append({"p": p + Vector2(randf_range(-6, 6), randf_range(-4, 4)),
			"v": Vector2(randf_range(-20, 20), randf_range(-30, 5)), "life": 0.5, "max": 0.5,
			"size": randf_range(5.0, 9.0), "grow": 14.0, "color": color})


func ring(p: Vector2, color: Color, radius: float, life := 0.35, width := 3.0) -> void:
	rings.append({"p": p, "r": radius, "life": life, "max": life, "color": color, "width": width})


func popup(p: Vector2, text: String, color := Color(1, 1, 1)) -> void:
	popups.append({"p": p, "text": text, "life": 1.0, "max": 1.0, "color": color})


func chunk(p: Vector2, color: Color, size: float, v: Vector2) -> void:
	debris.append({"p": p, "v": v, "life": 1.4, "max": 1.4, "size": size, "color": color,
		"spin": randf_range(-8, 8), "a": 0.0})


func explosion(p: Vector2, size := 1.0) -> void:
	sparks.append({"p": p, "v": Vector2.ZERO, "life": 0.18, "max": 0.18, "size": 34.0 * size,
		"color": Color(1.0, 0.95, 0.75), "flash": true})
	ring(p, Color(1.0, 0.75, 0.35), 34.0 * size, 0.32, 4.0 * size)
	burst(p, Color(1.0, 0.72, 0.25), int(14 * size), 190.0 * size, 3.2, 0.55)
	burst(p, Color(1.0, 0.95, 0.6), int(6 * size), 120.0 * size, 2.0, 0.4)
	for i in range(int(5 * size)):
		smokes.append({"p": p + Vector2(randf_range(-8, 8), randf_range(-8, 8)) * size,
			"v": Vector2(randf_range(-40, 40), randf_range(-50, 10)) * size, "life": 0.7, "max": 0.7,
			"size": randf_range(6.0, 11.0) * size, "grow": 22.0 * size, "color": Color(0.95, 0.92, 0.9, 0.75)})


func _process(delta: float) -> void:
	for s in sparks:
		s["life"] -= delta
		s["p"] += s["v"] * delta
		s["v"] *= 1.0 - minf(1.0, 3.0 * delta)
	for s in smokes:
		s["life"] -= delta
		s["p"] += s["v"] * delta
		s["size"] += s["grow"] * delta
	for d in debris:
		d["life"] -= delta
		d["v"] += Vector2(0, 300.0 * delta)
		d["p"] += d["v"] * delta
		d["a"] += d["spin"] * delta
	for r in rings:
		r["life"] -= delta
	for p in popups:
		p["life"] -= delta
		p["p"] += Vector2(0, -32.0 * delta)

	var alive := func(e): return e["life"] > 0.0
	sparks = sparks.filter(alive)
	smokes = smokes.filter(alive)
	debris = debris.filter(alive)
	rings = rings.filter(alive)
	popups = popups.filter(alive)
	queue_redraw()
	glow_layer.queue_redraw()


func clear() -> void:
	sparks.clear()
	smokes.clear()
	debris.clear()
	rings.clear()


func _draw() -> void:
	for s in smokes:
		var k: float = s["life"] / s["max"]
		var c: Color = s["color"]
		draw_circle(s["p"], s["size"], Color(c.r, c.g, c.b, c.a * k), true, -1.0, true)
	for d in debris:
		var k: float = minf(1.0, d["life"] / 0.4)
		var c: Color = d["color"]
		Art.ball(self, d["p"], d["size"], Color(c.r, c.g, c.b, k))
	for p in popups:
		var k: float = p["life"] / p["max"]
		var c: Color = p["color"]
		var pos: Vector2 = p["p"] + Vector2(-60, 0)
		var size := 15
		draw_string_outline(Game.font_bold, pos, p["text"], HORIZONTAL_ALIGNMENT_CENTER, 120, size, 4,
			Color(0.15, 0.1, 0.3, k))
		draw_string(Game.font_bold, pos, p["text"], HORIZONTAL_ALIGNMENT_CENTER, 120, size, Color(c.r, c.g, c.b, k))


func _draw_glow() -> void:
	for s in sparks:
		var k: float = s["life"] / s["max"]
		var c: Color = s["color"]
		if s.get("flash", false):
			Art.glow_at(glow_layer, s["p"], s["size"] * (1.5 - k * 0.5), Color(c.r, c.g, c.b, k))
		else:
			Art.glow_at(glow_layer, s["p"], s["size"] * 3.0, Color(c.r, c.g, c.b, 0.7 * k))
	for r in rings:
		var k: float = r["life"] / r["max"]
		var c: Color = r["color"]
		var radius: float = r["r"] * (1.2 - k * 0.9)
		glow_layer.draw_arc(r["p"], radius, 0.0, TAU, 40, Color(c.r, c.g, c.b, k), r["width"] * (0.5 + k), true)
