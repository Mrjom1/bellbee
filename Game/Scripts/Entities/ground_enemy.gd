class_name GroundEnemy
extends Entity

## Targets on the ground. Only bombs can hit them; they scroll with the land.

enum Kind {
	TURRET,  # dome gun that tracks the ship
	TANK,    # small tank rolling sideways
	HUT,     # farm hut; drops fruit when bombed
}

const TANK_SPEED := 28.0

var kind := Kind.TURRET
var aim := PI * 0.5
var dir := 1.0
var fire_timer := 0.0


func setup(p_stage: Stage, p_kind: Kind, pos: Vector2) -> void:
	stage = p_stage
	kind = p_kind
	position = pos
	shadow_height = 0.0
	add_to_group("ground_enemies")
	fire_timer = randf_range(1.0, 2.6)
	dir = -1.0 if randf() < 0.5 else 1.0

	match kind:
		Kind.TURRET:
			radius = 13.0
			points = 300
		Kind.TANK:
			radius = 13.0
			points = 400
		Kind.HUT:
			radius = 15.0
			points = 200


func tick(delta: float) -> void:
	position.y += Stage.SCROLL_SPEED * delta
	if kind == Kind.HUT:
		return

	aim = lerp_angle(aim, (player_position() - position).angle(), delta * 3.0)
	if kind == Kind.TANK:
		var next_x := position.x + dir * TANK_SPEED * delta
		if next_x < 20.0 or next_x > Stage.W - 20.0 or not stage.ground.is_land(next_x + dir * 10.0, position.y, 6.0):
			dir = -dir
		else:
			position.x = next_x

	fire_timer -= delta
	if fire_timer <= 0.0:
		fire_timer = randf_range(2.0, 3.2) / (1.0 + stage.rank * 0.35)
		if position.y > 20.0 and position.y < Stage.H * 0.62:
			stage.fire_spread(position, 1, 0.0)


func die() -> void:
	stage.ground_enemy_killed(self)


func _draw() -> void:
	match kind:
		Kind.TURRET:
			_draw_turret()
		Kind.TANK:
			_draw_tank()
		Kind.HUT:
			_draw_hut()


func _draw_turret() -> void:
	Art.ellipse(self, Vector2(4, 5), 15.0, 12.0, Color(0.05, 0.1, 0.05, 0.3))
	Art.ball(self, Vector2.ZERO, 13.0, Color(0.6, 0.62, 0.68))
	draw_circle(Vector2.ZERO, 9.5, Color(0.36, 0.38, 0.46), true, -1.0, true)
	var muzzle := Vector2.from_angle(aim) * 15.0
	draw_line(Vector2.ZERO, muzzle, Color(0.25, 0.25, 0.32), 5.0, true)
	draw_circle(muzzle, 2.8, Color(0.2, 0.2, 0.26), true, -1.0, true)
	Art.ball(self, Vector2.ZERO, 6.5, Color(0.95, 0.45, 0.4))


func _draw_tank() -> void:
	Art.ellipse(self, Vector2(4, 6), 17.0, 11.0, Color(0.05, 0.1, 0.05, 0.3))
	var tread := Color(0.3, 0.28, 0.3)
	draw_rect(Rect2(-15, -12, 30, 6), tread)
	draw_rect(Rect2(-15, 6, 30, 6), tread)
	for i in range(6):
		var x := -13.0 + fmod(i * 5.0 + t * dir * 30.0, 30.0)
		if x > -14.0 and x < 14.0:
			draw_line(Vector2(x, -12), Vector2(x, -6), tread.lightened(0.25), 1.0)
			draw_line(Vector2(x, 6), Vector2(x, 12), tread.lightened(0.25), 1.0)
	var hull := Color(0.45, 0.62, 0.38)
	draw_rect(Rect2(-13, -8, 26, 16), hull.darkened(0.2))
	draw_rect(Rect2(-12, -8, 24, 9), hull)
	var muzzle := Vector2.from_angle(aim) * 16.0
	draw_line(Vector2.ZERO, muzzle, Color(0.25, 0.3, 0.22), 4.0, true)
	Art.ball(self, Vector2.ZERO, 7.0, hull.lightened(0.15))


func _draw_hut() -> void:
	Art.ellipse(self, Vector2(5, 6), 18.0, 14.0, Color(0.05, 0.1, 0.05, 0.3))
	var roof := Color(0.95, 0.75, 0.3)
	# Round thatched hut with a door-side window and a red flag so it reads as a target.
	Art.ball(self, Vector2.ZERO, 14.0, roof)
	for i in range(8):
		var a := TAU * i / 8.0
		draw_line(Vector2.ZERO, Vector2.from_angle(a) * 13.0, roof.darkened(0.25), 1.0, true)
	Art.ball(self, Vector2.ZERO, 4.0, roof.darkened(0.3))
	draw_line(Vector2(0, 0), Vector2(0, -16), Color(0.4, 0.3, 0.2), 1.5, true)
	var wave := sin(t * 6.0) * 2.0
	draw_colored_polygon(PackedVector2Array([Vector2(0, -16), Vector2(9, -14 + wave), Vector2(0, -11)]),
		Color(1.0, 0.3, 0.35))
