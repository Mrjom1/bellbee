class_name EnemyBullet
extends Node2D

## Enemy bullet: a glowing pink orb moving in a straight line.

var vel := Vector2.ZERO
var radius := 4.0
var t := 0.0


func _ready() -> void:
	add_to_group("ebullets")


func _physics_process(delta: float) -> void:
	t += delta
	position += vel * delta
	if position.y > Stage.H + 20.0 or position.y < -30.0 or position.x < -20.0 or position.x > Stage.W + 20.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var pulse := 1.0 + 0.15 * sin(t * 25.0)
	Art.glow_at(self, Vector2.ZERO, 12.0 * pulse, Color(1.0, 0.3, 0.55, 0.7))
	draw_circle(Vector2.ZERO, 4.6, Color(1.0, 0.45, 0.65), true, -1.0, true)
	draw_circle(Vector2(-0.6, -0.6), 2.6, Color(1, 1, 1), true, -1.0, true)
