class_name Boss
extends Entity

## End-of-stage boss: a giant flying kettle with propellers. Cycles through four bullet patterns
## and gets faster below half health.

enum Phase {
	ENTER,
	FIGHT,
	DYING,
}

const BASE_HP := 170
const HOME := Vector2(240, 150)
const ATTACK_INTERVAL := 1.5
const DYING_TIME := 2.6

var phase := Phase.ENTER
var max_hp := BASE_HP
var attack_timer := 1.2
var attack_index := 0
var die_timer := 0.0
var boom_timer := 0.0
var body_color := Color(0.98, 0.58, 0.3)


func setup(p_stage: Stage, stage_index: int) -> void:
	stage = p_stage
	radius = 44.0
	points = 20000
	shadow_height = 1.6
	solid = false
	max_hp = int(BASE_HP * (1.0 + stage.rank * 0.35))
	hp = max_hp
	position = Vector2(HOME.x, -120.0)
	body_color = [Color(0.98, 0.58, 0.3), Color(0.4, 0.7, 0.98), Color(0.8, 0.45, 0.85)][stage_index % 3]
	add_to_group("bosses")


func tick(delta: float) -> void:
	match phase:
		Phase.ENTER:
			position.y = move_toward(position.y, HOME.y, 70.0 * delta)
			if is_equal_approx(position.y, HOME.y):
				phase = Phase.FIGHT
				solid = true
				t = 0.0
		Phase.FIGHT:
			position.x = HOME.x + sin(t * 0.7) * 130.0
			position.y = HOME.y + sin(t * 1.3) * 26.0
			var angry := hp < max_hp / 2
			attack_timer -= delta * (1.45 if angry else 1.0)
			if attack_timer <= 0.0:
				_attack()
				attack_timer = ATTACK_INTERVAL
		Phase.DYING:
			die_timer += delta
			boom_timer -= delta
			position.y += 18.0 * delta
			position.x += sin(die_timer * 40.0) * 1.5
			if boom_timer <= 0.0:
				boom_timer = 0.11
				var p := position + Vector2(randf_range(-40, 40), randf_range(-35, 35))
				stage.fx.explosion(p, 0.8)
				Audio.play("explode", -4.0)
			if die_timer >= DYING_TIME:
				dead = true
				stage.boss_defeated(self)
				queue_free()


func is_offscreen() -> bool:
	return false


func damage(amount: int) -> void:
	if phase != Phase.FIGHT:
		return
	hp -= amount
	flash = 0.05
	if hp <= 0:
		phase = Phase.DYING
		solid = false
		stage.clear_enemy_bullets()
		Audio.play("explode_big")


func _attack() -> void:
	var spout := position + Vector2(-50, 4)
	match attack_index % 4:
		0:
			stage.fire_spread(spout, 5, 0.2)
		1:
			stage.fire_ring(position, 14 + int(stage.rank * 4.0), t, 135.0)
		2:
			stage.fire_spread(spout, 3, 0.15)
			stage.spawn_air(AirEnemy.Kind.PUFF, Vector2(position.x - 60.0, position.y + 10.0))
			stage.spawn_air(AirEnemy.Kind.PUFF, Vector2(position.x + 60.0, position.y + 10.0))
		3:
			# Three rings in quick succession, each turned a little: reads as a spiral.
			for i in range(3):
				var timer := get_tree().create_timer(i * 0.18, false)
				timer.timeout.connect(func():
					if phase == Phase.FIGHT:
						stage.fire_ring(position, 9, t + i * 0.25, 150.0))
	attack_index += 1


func _draw() -> void:
	var c := body_color
	var low := hp < max_hp * 0.3

	# Propellers.
	for side in [-1.0, 1.0]:
		var hub := Vector2(side * 50.0, -14.0)
		draw_line(Vector2(side * 36.0, -10.0), hub, c.darkened(0.45), 5.0, true)
		for blade in range(2):
			Art.ellipse(self, hub, 20.0, 4.0, Color(0.85, 0.88, 0.95, 0.55), t * 30.0 * side + blade * PI * 0.5)
		Art.ball(self, hub, 5.0, Color(0.7, 0.72, 0.8))

	# Handle (right) and spout (left).
	draw_arc(Vector2(40, 2), 17.0, -1.4, 1.4, 18, c.darkened(0.4), 7.0, true)
	draw_polygon(PackedVector2Array([Vector2(-32, -6), Vector2(-60, -22), Vector2(-64, -14), Vector2(-34, 16)]),
		PackedColorArray([c.darkened(0.1), c.lightened(0.25), c, c.darkened(0.35)]))
	Art.ellipse(self, Vector2(-62, -18), 5.0, 3.0, c.darkened(0.5), 0.5)

	# Pot body with a brass band.
	Art.ball(self, Vector2.ZERO, radius, c)
	draw_arc(Vector2(0, -2), radius - 3.0, 0.15, PI - 0.15, 32, Color(1.0, 0.86, 0.4), 5.0, true)
	for i in range(7):
		var a := 0.35 + (PI - 0.7) * i / 6.0
		draw_circle(Vector2.from_angle(a) * (radius - 3.0) + Vector2(0, -2), 1.8, Color(1, 0.95, 0.7), true, -1.0, true)

	# Lid and knob.
	Art.ellipse_gradient(self, Vector2(0, -30), 27.0, 10.0, c.lightened(0.35), c.darkened(0.2))
	Art.ball(self, Vector2(0, -39), 7.0, Color(0.98, 0.42, 0.5))

	# Face: eyes track the player; brows tilt in when angry.
	var look := (player_position() - position).normalized() * 3.5
	for side in [-1.0, 1.0]:
		var eye := Vector2(side * 14.0, -6.0)
		Art.ellipse(self, eye, 8.5, 10.5, Color(1, 1, 1))
		draw_circle(eye + look, 5.0, Color(0.15, 0.1, 0.22), true, -1.0, true)
		draw_circle(eye + look + Vector2(-1.5, -2), 1.8, Color(1, 1, 1), true, -1.0, true)
		var brow_tilt := 5.0 if hp < max_hp / 2 else 1.0
		draw_line(eye + Vector2(-side * 10.0, -14.0 - brow_tilt), eye + Vector2(side * 8.0, -13.0 + brow_tilt),
			c.darkened(0.6), 3.0, true)
	draw_arc(Vector2(0, 16), 9.0, PI + 0.4, TAU - 0.4, 12, Color(0.35, 0.12, 0.1), 3.0, true)

	if low:
		for i in range(3):
			var k := fmod(t * 0.8 + i * 0.33, 1.0)
			Art.glow_at(self, Vector2(-20.0 + i * 20.0, -40.0 - k * 40.0), 10.0 + k * 14.0,
				Color(0.3, 0.3, 0.35, 0.5 * (1.0 - k)))
