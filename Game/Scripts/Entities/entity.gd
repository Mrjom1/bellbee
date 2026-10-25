class_name Entity
extends Node2D

## Base for everything that flies, scrolls or can be shot. Stage does the collision checks with plain radii.

var stage: Stage
var radius := 10.0
var hp := 1
var points := 0
var dead := false
var t := 0.0
var flash := 0.0
## False lets player shots pass through (an empty cloud, a boss that is still arriving).
var solid := true
## 0 = on the ground (no shadow), 1 = normal flying height; larger floats higher.
var shadow_height := 1.0


func _physics_process(delta: float) -> void:
	t += delta
	if flash > 0.0:
		flash -= delta
	modulate = Color(1.9, 1.9, 1.9) if flash > 0.0 else Color.WHITE
	tick(delta)
	if is_offscreen():
		left_screen()
		queue_free()
	queue_redraw()


func tick(_delta: float) -> void:
	pass


func is_offscreen() -> bool:
	return position.y > Stage.H + 90.0 or position.y < -240.0 \
		or position.x < -150.0 or position.x > Stage.W + 150.0


func left_screen() -> void:
	pass


func on_shot(_shot: Node2D) -> void:
	damage(1)


func damage(amount: int) -> void:
	if dead:
		return
	hp -= amount
	flash = 0.06
	if hp <= 0:
		dead = true
		die()
		queue_free()
	else:
		Audio.play("hit")


func die() -> void:
	pass


func draw_shadow(ci: CanvasItem, offset: Vector2) -> void:
	Art.soft_shadow(ci, position + offset * shadow_height, radius * 1.05)


func player_position() -> Vector2:
	if stage != null and stage.player != null:
		return stage.player.position
	return Vector2(Stage.W * 0.5, Stage.H)
