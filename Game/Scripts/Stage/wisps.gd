class_name Wisps
extends Node2D

## Thin, fast high-altitude clouds drawn over everything for depth. Purely decorative.

const SPEED := 150.0

var items: Array = []
var spawn_timer := 0.0
var density := 1.0


func _ready() -> void:
	for i in range(2):
		_spawn(randf_range(0.0, Stage.H))


func _process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = randf_range(4.0, 9.0) / density
		_spawn(-120.0)
	for w in items:
		w["p"] += Vector2(0, SPEED * w["speed"] * delta)
	items = items.filter(func(w): return w["p"].y < Stage.H + 160.0)
	queue_redraw()


func _spawn(y: float) -> void:
	var puffs: Array = []
	var width := randf_range(80.0, 160.0)
	for i in range(7):
		puffs.append({"o": Vector2(randf_range(-width, width), randf_range(-25.0, 25.0)), "r": randf_range(30.0, 55.0)})
	items.append({"p": Vector2(randf_range(-40.0, Stage.W + 40.0), y), "puffs": puffs, "speed": randf_range(0.9, 1.3)})


func _draw() -> void:
	for w in items:
		for puff in w["puffs"]:
			Art.glow_at(self, w["p"] + puff["o"], puff["r"] * 1.6, Color(1, 1, 1, 0.32))
