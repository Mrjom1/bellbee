class_name AirEnemy
extends Entity

## Flying enemies. Each kind has its own movement, firing habit and look.

enum Kind {
	PUFF,     # fluffball drifting down in a wave
	SWOOP,    # saucer flying in formation along a curve
	SPINNER,  # pinwheel that stops, fires, and leaves
	KETTLE,   # heavy teapot that sways and fires spreads; drops a bell
}

var kind := Kind.PUFF
var vel := Vector2.ZERO
var base_x := 0.0
var phase := 0.0
var side := 1.0
var formation := -1
var fire_timer := 0.0
var shots_left := 0
var hover_y := 0.0
var hover_time := 0.0
var state := 0


func setup(p_stage: Stage, p_kind: Kind, pos: Vector2, params := {}) -> void:
	stage = p_stage
	kind = p_kind
	position = pos
	base_x = pos.x
	phase = randf() * TAU
	formation = params.get("formation", -1)
	var rank := stage.rank
	add_to_group("air_enemies")

	match kind:
		Kind.PUFF:
			hp = 1
			radius = 12.0
			points = 100
			vel = Vector2(0, 100.0 + rank * 15.0)
			fire_timer = randf_range(0.6, 2.2)
			shots_left = 1 if randf() < 0.3 + rank * 0.2 else 0
		Kind.SWOOP:
			hp = 1
			radius = 11.0
			points = 150
			side = params.get("side", 1.0)
			vel = Vector2(side * 185.0, 72.0)
			fire_timer = randf_range(0.6, 1.2)
			shots_left = 1 if randf() < 0.4 + rank * 0.2 else 0
		Kind.SPINNER:
			hp = 3
			radius = 14.0
			points = 300
			vel = Vector2(0, 130.0)
			hover_y = params.get("hover", 140.0)
			fire_timer = 0.5
			shots_left = 2 + int(rank)
		Kind.KETTLE:
			hp = 12 + int(rank * 4.0)
			radius = 21.0
			points = 1000
			vel = Vector2(0, 55.0)
			hover_y = params.get("hover", 130.0)
			fire_timer = 1.2
			shots_left = 4 + int(rank)
			shadow_height = 1.3


func tick(delta: float) -> void:
	fire_timer -= delta
	match kind:
		Kind.PUFF:
			position.y += vel.y * delta
			position.x = base_x + sin(t * 2.6 + phase) * 34.0
			if fire_timer <= 0.0 and shots_left > 0:
				_fire_aimed(1, 0.0)
		Kind.SWOOP:
			# Bank through ~110 degrees after entering, then fly out straight.
			if t > 0.45 and t < 1.25:
				vel = vel.rotated(side * 2.4 * delta)
			position += vel * delta
			if fire_timer <= 0.0 and shots_left > 0:
				_fire_aimed(1, 0.0)
		Kind.SPINNER:
			_tick_spinner(delta)
		Kind.KETTLE:
			_tick_kettle(delta)


func _tick_spinner(delta: float) -> void:
	match state:
		0:
			position.y += vel.y * delta
			vel.y = maxf(30.0, vel.y - 60.0 * delta)
			if position.y >= hover_y:
				state = 1
		1:
			hover_time += delta
			position.y = hover_y + sin(hover_time * 3.0) * 4.0
			if fire_timer <= 0.0 and shots_left > 0:
				_fire_aimed(3 if stage.rank >= 1.0 else 1, 0.22)
				fire_timer = 0.8
			if hover_time > 2.4 or shots_left <= 0 and hover_time > 1.2:
				state = 2
				vel = Vector2(0, 40.0)
		2:
			vel.y += 260.0 * delta
			position.y += vel.y * delta


func _tick_kettle(delta: float) -> void:
	match state:
		0:
			position.y = move_toward(position.y, hover_y, vel.y * delta)
			if is_equal_approx(position.y, hover_y):
				state = 1
		1:
			hover_time += delta
			position.x = base_x + sin(hover_time * 0.9) * 60.0
			if fire_timer <= 0.0 and shots_left > 0:
				_fire_aimed(3, 0.28)
				fire_timer = 1.4
			if hover_time > 7.0:
				state = 2
		2:
			position.y += 70.0 * delta


func _fire_aimed(count: int, spread: float) -> void:
	shots_left -= 1
	fire_timer = 1.5
	if position.y < 10.0 or position.y > Stage.H * 0.7:
		return
	stage.fire_spread(position, count, spread)


func die() -> void:
	stage.air_enemy_killed(self)
	if kind == Kind.KETTLE:
		stage.spawn_bell(position)


func _draw() -> void:
	match kind:
		Kind.PUFF:
			_draw_puff()
		Kind.SWOOP:
			_draw_swoop()
		Kind.SPINNER:
			_draw_spinner()
		Kind.KETTLE:
			_draw_kettle()


func _eyes(center: Vector2, gap: float, size: float, angry := false) -> void:
	var look := (player_position() - (position + center)).normalized() * size * 0.35
	for side_x in [-1.0, 1.0]:
		var p := center + Vector2(side_x * gap, 0)
		Art.ellipse(self, p, size * 0.8, size, Color(1, 1, 1))
		draw_circle(p + look, size * 0.5, Color(0.12, 0.1, 0.2), true, -1.0, true)
		draw_circle(p + look + Vector2(-size * 0.2, -size * 0.25), size * 0.18, Color(1, 1, 1), true, -1.0, true)
		if angry:
			draw_line(p + Vector2(-side_x * size * 1.0, -size * 1.5), p + Vector2(side_x * size * 0.9, -size * 0.9),
				Color(0.25, 0.1, 0.1), 2.0, true)


func _draw_puff() -> void:
	var body := Color(1.0, 0.58, 0.72)
	for i in range(12):
		var a := TAU * i / 12.0 + t * 1.5
		draw_circle(Vector2.from_angle(a) * radius * 0.8, radius * 0.38, body.darkened(0.15), true, -1.0, true)
	Art.ball(self, Vector2.ZERO, radius * 0.9, body)
	_eyes(Vector2(0, -1), 4.2, 3.0)
	Art.ellipse(self, Vector2(-7, 4), 2.4, 1.5, Color(1, 0.35, 0.45, 0.6))
	Art.ellipse(self, Vector2(7, 4), 2.4, 1.5, Color(1, 0.35, 0.45, 0.6))


func _draw_swoop() -> void:
	var tilt := clampf(vel.x / 400.0, -0.35, 0.35)
	Art.ellipse_gradient(self, Vector2(0, 2), 14.0, 6.5, Color(0.62, 0.42, 0.9), Color(0.32, 0.18, 0.55))
	Art.ellipse_gradient(self, Vector2(0, 0), 11.5, 4.5, Color(0.85, 0.7, 1.0), Color(0.55, 0.38, 0.85))
	Art.ball(self, Vector2(tilt * 6.0, -3.5), 6.0, Color(0.5, 1.0, 0.85))
	for i in range(5):
		var a := PI * 0.1 + PI * 0.8 * i / 4.0
		var lit := int(t * 8.0 + i) % 2 == 0
		var lamp := Vector2(cos(a) * 12.0, sin(a) * 4.5 + 2.0)
		draw_circle(lamp, 1.6, Color(1, 0.95, 0.5) if lit else Color(1, 0.5, 0.3), true, -1.0, true)


func _draw_spinner() -> void:
	var colors := [Color(1.0, 0.55, 0.2), Color(0.25, 0.8, 0.85)]
	for i in range(4):
		var a := TAU * i / 4.0 + t * 7.0
		var tip := Vector2.from_angle(a) * radius * 1.2
		var side_point := Vector2.from_angle(a + 0.9) * radius * 0.75
		var c: Color = colors[i % 2]
		draw_polygon(PackedVector2Array([Vector2.ZERO, tip, side_point]),
			PackedColorArray([c.lightened(0.4), c, c.darkened(0.3)]))
	Art.ball(self, Vector2.ZERO, 7.5, Color(1.0, 0.88, 0.3))
	_eyes(Vector2(0, -0.5), 2.8, 1.9)


func _draw_kettle() -> void:
	var body := Color(1.0, 0.62, 0.28)
	# Spout and handle behind the pot.
	draw_polygon(PackedVector2Array([Vector2(-14, -2), Vector2(-30, -12), Vector2(-33, -8), Vector2(-16, 8)]),
		PackedColorArray([body.darkened(0.1), body.lightened(0.2), body, body.darkened(0.3)]))
	draw_arc(Vector2(17, 0), 9.0, -1.3, 1.3, 14, body.darkened(0.35), 4.0, true)
	Art.ball(self, Vector2.ZERO, radius, body)
	Art.ellipse_gradient(self, Vector2(0, -13), 13.0, 5.0, body.lightened(0.3), body.darkened(0.2))
	Art.ball(self, Vector2(0, -18), 4.0, Color(0.95, 0.4, 0.45))
	_eyes(Vector2(0, -1), 6.0, 4.0, true)
	draw_arc(Vector2(0, 9), 4.0, 0.3, PI - 0.3, 10, Color(0.3, 0.12, 0.08), 1.8, true)
