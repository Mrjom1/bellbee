class_name ShadowLayer
extends Node2D

## Draws every flyer's shadow on the ground, plus the bomb crosshair.
## Sits between the ground targets and the clouds so shadows fall across tanks and huts.

const LIGHT_OFFSET := Vector2(16, 26)

var stage: Stage


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for node in get_tree().get_nodes_in_group("flyers"):
		if node.visible and node.shadow_height > 0.0:
			node.draw_shadow(self, LIGHT_OFFSET)

	var player := stage.player
	if player != null and player.alive and player.can_bomb() and stage.controls_enabled():
		var p := player.position + Vector2(0, -Player.BOMB_RANGE)
		var pulse := 0.5 + 0.5 * sin(player.t * 6.0)
		var color := Color(1.0, 1.0, 1.0, 0.45 + 0.25 * pulse)
		draw_arc(p, 9.0, 0.0, TAU, 24, color, 1.6, true)
		for i in range(4):
			var dir := Vector2.from_angle(i * PI * 0.5 + PI * 0.25)
			draw_line(p + dir * 5.0, p + dir * 12.0, color, 1.6, true)
