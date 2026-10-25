class_name Shot
extends Node2D

## Player shot: flies straight up.

const SPEED := 560.0

var radius := 5.0
var dead := false


func _ready() -> void:
	add_to_group("shots")


func _physics_process(delta: float) -> void:
	position.y -= SPEED * delta
	if position.y < -20.0:
		queue_free()


func _draw() -> void:
	Art.glow_at(self, Vector2(0, -1), 11.0, Color(1.0, 0.85, 0.35, 0.55))
	draw_line(Vector2(0, -7), Vector2(0, 6), Color(1.0, 0.95, 0.6), 5.0, true)
	draw_line(Vector2(0, -6), Vector2(0, 4), Color(1, 1, 1), 2.2, true)
