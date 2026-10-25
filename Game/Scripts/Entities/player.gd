class_name Player
extends Node2D

## The player's ship. Shoots up at flyers, lobs bombs at ground targets, and carries bell power-ups.
## Losing an arm disables bombs; losing both also drops the twin shot. A hit with no arms left is fatal.

const BASE_SPEED := 150.0
const SPEED_STEP := 30.0
const MAX_SPEED_LEVEL := 5
const SHOT_INTERVAL := 0.085
const BOMB_INTERVAL := 0.3
const BOMB_RANGE := 120.0
const HIT_RADIUS := 6.0
const BODY_RADIUS := 10.0
const PICKUP_RADIUS := 20.0
const MAX_OPTIONS := 2
const OPTION_SPACING := 12
const BARRIER_HITS := 8
const RESPAWN_INVULNERABLE := 2.5

var stage: Stage
var radius := 16.0
var shadow_height := 1.0
var speed_level := 0
var twin := false
var options := 0
var barrier := 0
var arm_left := true
var arm_right := true
var alive := true
var invulnerable := 0.0
var entering := 0.0
var shot_timer := 0.0
var bomb_timer := 0.0
var shot_count := 0
var trail: Array[Vector2] = []
var t := 0.0
var tilt := 0.0


func setup(p_stage: Stage, power: Dictionary) -> void:
	stage = p_stage
	speed_level = power.get("speed", 0)
	twin = power.get("twin", false)
	options = power.get("options", 0)
	position = Vector2(Stage.W * 0.5, Stage.H - 70.0)
	add_to_group("flyers")


func power() -> Dictionary:
	return {"speed": speed_level, "twin": twin, "options": options}


func reset_power() -> void:
	speed_level = 0
	twin = false
	options = 0
	barrier = 0
	arm_left = true
	arm_right = true


func can_bomb() -> bool:
	return arm_left and arm_right


func has_twin() -> bool:
	return twin and (arm_left or arm_right)


func _physics_process(delta: float) -> void:
	t += delta
	invulnerable = maxf(0.0, invulnerable - delta)
	shot_timer -= delta
	bomb_timer -= delta
	entering -= delta
	if not alive:
		return
	# Flying in after a respawn, or flying off after stage clear: the stage moves the ship.
	if entering > 0.0 or stage.state == Stage.State.CLEAR:
		queue_redraw()
		return

	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed := BASE_SPEED + SPEED_STEP * speed_level
	position += dir * speed * delta
	position = position.clamp(Vector2(22, 30), Vector2(Stage.W - 22, Stage.H - 28))
	tilt = move_toward(tilt, dir.x, delta * 6.0)
	_record_trail()

	if stage.controls_enabled():
		if Input.is_action_pressed("shoot") and shot_timer <= 0.0:
			_fire()
		if Input.is_action_pressed("bomb") and bomb_timer <= 0.0 and can_bomb():
			bomb_timer = BOMB_INTERVAL
			stage.spawn_bomb(position + Vector2(0, -8), position + Vector2(0, -BOMB_RANGE))

	queue_redraw()


func _record_trail() -> void:
	if trail.is_empty() or trail[0].distance_squared_to(position) > 1.0:
		trail.push_front(position)
		if trail.size() > OPTION_SPACING * MAX_OPTIONS + 2:
			trail.pop_back()


func option_position(i: int) -> Vector2:
	if trail.is_empty():
		return position
	return trail[mini((i + 1) * OPTION_SPACING, trail.size() - 1)]


func _fire() -> void:
	shot_timer = SHOT_INTERVAL
	var origins: Array[Vector2] = [position]
	for i in range(options):
		origins.append(option_position(i))
	for origin in origins:
		if has_twin():
			stage.spawn_shot(origin + Vector2(-7, -14))
			stage.spawn_shot(origin + Vector2(7, -14))
		else:
			stage.spawn_shot(origin + Vector2(0, -17))
	shot_count += 1
	if shot_count % 2 == 0:
		Audio.play("shot", -6.0)


func respawn() -> void:
	reset_power()
	alive = true
	visible = true
	trail.clear()
	position = Vector2(Stage.W * 0.5, Stage.H + 30.0)
	invulnerable = RESPAWN_INVULNERABLE
	entering = 0.6
	var tween := create_tween()
	tween.tween_property(self, "position:y", Stage.H - 80.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func draw_shadow(ci: CanvasItem, offset: Vector2) -> void:
	if not alive:
		return
	Art.soft_shadow(ci, position + offset, 15.0)
	for i in range(options):
		Art.soft_shadow(ci, option_position(i) + offset, 12.0, 0.5)


func _draw() -> void:
	if not alive:
		return
	# Blink while invulnerable.
	if invulnerable > 0.0 and int(t * 18.0) % 2 == 0:
		return

	for i in range(options - 1, -1, -1):
		var p := to_local(option_position(i))
		Art.ship(self, p, 0.82, t + i, true, true, 0.0, 0.42, Color(0.45, 0.95, 0.55))

	Art.ship(self, Vector2(0, sin(t * 4.0) * 1.5), 1.0, t, arm_left, arm_right, tilt)

	if barrier > 0:
		var strength := float(barrier) / BARRIER_HITS
		draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 40, Color(1.0, 0.45, 0.55, 0.35 + 0.25 * strength), 2.0, true)
		for i in range(6):
			var a := TAU * i / 6.0 + t * 3.0
			var p := Vector2.from_angle(a) * 27.0
			Art.glow_at(self, p, 9.0, Color(1.0, 0.35, 0.45, 0.6))
			draw_circle(p, 2.6, Color(1.0, 0.85, 0.88), true, -1.0, true)
