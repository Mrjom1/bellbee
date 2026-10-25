class_name Item
extends Entity

## Fruit left on the ground by a bombed hut. Fly over it to collect.

enum Kind {
	CHERRY,
	APPLE,
	STRAWBERRY,
	MELON,
}

var kind := Kind.CHERRY


func setup(p_stage: Stage, pos: Vector2) -> void:
	stage = p_stage
	position = pos
	radius = 11.0
	shadow_height = 0.0
	kind = (randi() % Kind.size()) as Kind
	add_to_group("items")


func tick(delta: float) -> void:
	position.y += Stage.SCROLL_SPEED * delta


func _draw() -> void:
	var bob := sin(t * 5.0) * 2.0
	Art.glow_at(self, Vector2(0, bob), 22.0, Color(1.0, 1.0, 0.7, 0.4 + 0.2 * sin(t * 8.0)))
	Art.ellipse(self, Vector2(3, 9), 9.0, 4.0, Color(0, 0, 0, 0.2))
	var p := Vector2(0, bob - 2.0)
	match kind:
		Kind.CHERRY:
			draw_line(p + Vector2(-4, 0), p + Vector2(1, -11), Color(0.35, 0.55, 0.2), 1.5, true)
			draw_line(p + Vector2(5, 1), p + Vector2(1, -11), Color(0.35, 0.55, 0.2), 1.5, true)
			Art.ball(self, p + Vector2(-4, 1), 5.0, Color(0.95, 0.15, 0.25))
			Art.ball(self, p + Vector2(5, 2), 5.0, Color(0.9, 0.12, 0.22))
		Kind.APPLE:
			Art.ball(self, p, 8.0, Color(0.95, 0.25, 0.22))
			draw_line(p + Vector2(0, -7), p + Vector2(1, -11), Color(0.45, 0.3, 0.15), 1.6, true)
			Art.ellipse(self, p + Vector2(4, -10), 3.5, 1.8, Color(0.35, 0.75, 0.3), -0.5)
		Kind.STRAWBERRY:
			var points := PackedVector2Array([p + Vector2(-8, -4), p + Vector2(8, -4), p + Vector2(0, 9)])
			draw_polygon(points, PackedColorArray([Color(1, 0.4, 0.45), Color(0.85, 0.15, 0.25), Color(0.75, 0.1, 0.2)]))
			draw_circle(p + Vector2(0, -3), 8.0, Color(0.95, 0.25, 0.32), true, -1.0, true)
			for seed_pos in [Vector2(-3, -1), Vector2(3, -1), Vector2(0, 3), Vector2(-4, -5), Vector2(4, -5)]:
				draw_circle(p + seed_pos, 0.8, Color(1, 0.95, 0.5))
			Art.star(self, p + Vector2(0, -9), 5.0, Color(0.3, 0.7, 0.3), 0.3)
		Kind.MELON:
			Art.ball(self, p, 8.5, Color(0.55, 0.85, 0.4))
			for i in range(4):
				var x := -6.0 + i * 4.0
				draw_line(p + Vector2(x, -7), p + Vector2(x * 0.8, 7), Color(0.3, 0.55, 0.25), 1.2, true)
