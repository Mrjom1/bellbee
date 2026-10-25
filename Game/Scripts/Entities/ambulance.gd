class_name Ambulance
extends Entity

## Flying ambulance that brings lost arms back. It rises from the bottom; touch it to get repaired.

const RISE_SPEED := 75.0

var base_x := 0.0


func setup(p_stage: Stage, x: float) -> void:
	stage = p_stage
	base_x = clampf(x, 70.0, Stage.W - 70.0)
	position = Vector2(base_x, Stage.H + 30.0)
	radius = 18.0
	add_to_group("ambulances")


func tick(delta: float) -> void:
	position.y -= RISE_SPEED * delta
	position.x = base_x + sin(t * 1.7) * 50.0


func _draw() -> void:
	# Rotors.
	for side in [-1.0, 1.0]:
		var hub := Vector2(side * 19.0, -2.0)
		Art.ellipse(self, hub, 9.0, 2.0, Color(0.8, 0.85, 0.9, 0.7), t * 25.0 * side)
		Art.ellipse(self, hub, 9.0, 2.0, Color(0.8, 0.85, 0.9, 0.7), t * 25.0 * side + PI * 0.5)
		draw_line(Vector2(side * 12.0, -2.0), hub, Color(0.6, 0.6, 0.7), 2.0, true)

	var body := PackedVector2Array([Vector2(-12, -14), Vector2(12, -14), Vector2(14, -10), Vector2(14, 13),
		Vector2(11, 16), Vector2(-11, 16), Vector2(-14, 13), Vector2(-14, -10)])
	draw_polygon(body, PackedColorArray([Color(1, 1, 1), Color(0.92, 0.93, 0.97), Color(0.85, 0.87, 0.93),
		Color(0.8, 0.82, 0.9), Color(0.8, 0.82, 0.9), Color(0.85, 0.87, 0.93), Color(0.92, 0.93, 0.97), Color(1, 1, 1)]))
	var closed := body.duplicate()
	closed.append(body[0])
	draw_polyline(closed, Color(0.45, 0.48, 0.6), 1.2, true)

	# Windshield, stripe and red cross.
	draw_rect(Rect2(-10, -12, 20, 5), Color(0.55, 0.85, 1.0))
	draw_rect(Rect2(-14, 10, 28, 3), Color(0.95, 0.25, 0.3))
	draw_rect(Rect2(-2.5, -4, 5, 12), Color(0.95, 0.2, 0.28))
	draw_rect(Rect2(-6, -0.5, 12, 5), Color(0.95, 0.2, 0.28))

	# Siren alternating red and blue.
	var red_on := int(t * 6.0) % 2 == 0
	var siren := Color(1.0, 0.2, 0.25) if red_on else Color(0.25, 0.5, 1.0)
	Art.glow_at(self, Vector2(0, -16), 18.0, Color(siren.r, siren.g, siren.b, 0.6))
	Art.ball(self, Vector2(0, -16), 3.5, siren)
