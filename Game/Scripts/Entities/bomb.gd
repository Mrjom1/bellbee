class_name Bomb
extends Node2D

## Bomb lobbed ahead of the ship; it lands on the ground spot under the crosshair, which keeps scrolling.

const FLIGHT_TIME := 0.5
const ARC_HEIGHT := 18.0

var stage: Stage
var start := Vector2.ZERO
var target := Vector2.ZERO
var t := 0.0


func _physics_process(delta: float) -> void:
	t += delta
	target.y += Stage.SCROLL_SPEED * delta
	var k := minf(t / FLIGHT_TIME, 1.0)
	position = start.lerp(target, k) + Vector2(0, -sin(k * PI) * ARC_HEIGHT)
	scale = Vector2.ONE * lerpf(1.0, 0.55, k)
	rotation += delta * 9.0
	if k >= 1.0:
		stage.bomb_landed(target)
		queue_free()
	queue_redraw()


func _draw() -> void:
	Art.ball(self, Vector2.ZERO, 6.0, Color(0.32, 0.3, 0.45))
	draw_line(Vector2(0, -6), Vector2(2, -9), Color(0.6, 0.5, 0.3), 1.5, true)
	var spark := 4.0 + 1.5 * sin(t * 50.0)
	Art.glow_at(self, Vector2(2, -9), spark * 1.6, Color(1.0, 0.6, 0.2, 0.9))
	Art.star(self, Vector2(2, -9), spark, Color(1.0, 0.95, 0.6), t * 20.0)
