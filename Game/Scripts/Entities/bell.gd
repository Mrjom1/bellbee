class_name Bell
extends Entity

## Power-up bell. Each shot knocks it upward; every few shots it changes colour.
## Shoot it too much past red and it breaks.

enum Kind {
	YELLOW,
	BLUE,
	WHITE,
	GREEN,
	RED,
}

const COLORS := [
	Color(1.0, 0.82, 0.16),
	Color(0.32, 0.6, 1.0),
	Color(0.94, 0.95, 1.0),
	Color(0.36, 0.86, 0.38),
	Color(1.0, 0.32, 0.36),
]
const HITS_PER_COLOR := 5
# Knock and spawn speeds are scaled with gravity so a hit still lifts the bell ~75 px.
const GRAVITY := 420.0
const MAX_FALL := 210.0
const KNOCK_SPEED := 250.0
const SPAWN_SPEED := 290.0
const HIT_COOLDOWN := 0.06

var kind := Kind.YELLOW
var vel := Vector2.ZERO
var hits := 0
var hit_cooldown := 0.0
var change_glow := 0.0


func setup(p_stage: Stage, pos: Vector2) -> void:
	stage = p_stage
	position = pos
	radius = 13.0
	shadow_height = 1.3
	vel = Vector2(randf_range(-30.0, 30.0), -SPAWN_SPEED)
	add_to_group("bells")


func tick(delta: float) -> void:
	hit_cooldown -= delta
	change_glow = move_toward(change_glow, 0.0, delta * 2.5)
	vel.y = minf(vel.y + GRAVITY * delta, MAX_FALL)
	vel.x = move_toward(vel.x, 0.0, 50.0 * delta)
	position += vel * delta

	if position.x < 16.0 or position.x > Stage.W - 16.0:
		position.x = clampf(position.x, 16.0, Stage.W - 16.0)
		vel.x = -vel.x
	if position.y < 18.0 and vel.y < 0.0:
		position.y = 18.0
		vel.y = 0.0


func on_shot(shot: Node2D) -> void:
	vel.y = -KNOCK_SPEED
	vel.x = clampf((position.x - shot.position.x) * 7.0, -70.0, 70.0)
	if hit_cooldown > 0.0:
		return
	hit_cooldown = HIT_COOLDOWN
	hits += 1

	if hits % HITS_PER_COLOR != 0:
		Audio.play("bell_hit", -3.0)
		return

	if kind == Kind.RED:
		dead = true
		stage.fx.burst(position, COLORS[kind], 16, 170.0, 3.0, 0.5)
		stage.fx.ring(position, Color(1, 0.6, 0.6), 26.0, 0.3)
		Audio.play("bell_break")
		queue_free()
		return

	kind = (kind + 1) as Kind
	change_glow = 1.0
	stage.fx.ring(position, COLORS[kind], 30.0, 0.35)
	Audio.play("bell_change")


func left_screen() -> void:
	if kind == Kind.YELLOW and position.y > Stage.H:
		stage.yellow_bell_missed()


func get_color() -> Color:
	return COLORS[kind]


func draw_shadow(ci: CanvasItem, offset: Vector2) -> void:
	Art.soft_shadow(ci, position + offset * shadow_height, 9.0, 0.8)


func _draw() -> void:
	var sway := sin(t * 5.0) * 0.22 + clampf(vel.x * 0.004, -0.3, 0.3)
	var color: Color = COLORS[kind]
	if change_glow > 0.0:
		Art.glow_at(self, Vector2.ZERO, 34.0, Color(1, 1, 1, change_glow * 0.7))
	Art.bell(self, Vector2.ZERO, radius, color, sway)

	# Little glint that orbits now and then.
	var glint := fmod(t * 0.9, 1.0)
	if glint < 0.25:
		var k := glint / 0.25
		Art.star(self, Vector2(-8, -10).rotated(k * 0.5), 5.0 * sin(k * PI), Color(1, 1, 1, 0.95), k * 2.0)
