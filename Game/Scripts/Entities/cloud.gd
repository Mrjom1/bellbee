class_name Cloud
extends Entity

## Fluffy cloud that hides bells. The first hit shakes a bell loose, then every few hits after that.
## Once empty it no longer stops shots.

const HITS_PER_EXTRA_BELL := 4

var bells := 1
var hits := 0
var wobble := 0.0
var puffs: Array = []


func setup(p_stage: Stage, pos: Vector2, p_bells: int, size: float) -> void:
	stage = p_stage
	position = pos
	bells = p_bells
	shadow_height = 2.2
	radius = 26.0 * size
	add_to_group("clouds")

	var count := 5 + int(size * 2.0)
	for i in range(count):
		var k := (i + 0.5) / count - 0.5
		var r := (13.0 + 9.0 * (1.0 - absf(k) * 1.6) + randf_range(-2.0, 3.0)) * size
		puffs.append({"o": Vector2(k * 62.0 * size, randf_range(-5.0, 4.0) * size - (1.0 - absf(k)) * 6.0 * size), "r": r})


func tick(delta: float) -> void:
	position.y += Stage.CLOUD_SPEED * delta
	wobble = move_toward(wobble, 0.0, delta * 3.0)
	solid = bells > 0


func on_shot(_shot: Node2D) -> void:
	hits += 1
	wobble = 1.0
	stage.fx.puff(position + Vector2(randf_range(-18, 18), 12), Color(1, 1, 1, 0.8))
	if bells > 0 and (hits == 1 or hits % HITS_PER_EXTRA_BELL == 0):
		bells -= 1
		stage.spawn_bell(position + Vector2(0, -6))
		Audio.play("cloud")


func draw_shadow(ci: CanvasItem, offset: Vector2) -> void:
	for puff in puffs:
		Art.glow_at(ci, position + puff["o"] + offset * shadow_height, puff["r"] * 1.6, Color(0.05, 0.1, 0.25, 0.22))


func _draw() -> void:
	var s := 1.0 + wobble * 0.05 * sin(t * 32.0)
	var shade := Color(0.72, 0.8, 0.95)
	var body := Color(0.97, 0.98, 1.0)
	for puff in puffs:
		draw_circle(puff["o"] * s + Vector2(2, 6), puff["r"] * s, shade, true, -1.0, true)
	for puff in puffs:
		draw_circle(puff["o"] * s + Vector2(0, -1), puff["r"] * 0.94 * s, body, true, -1.0, true)
	for puff in puffs:
		var r: float = puff["r"]
		draw_circle(puff["o"] * s + Vector2(-r * 0.22, -r * 0.3), r * 0.52 * s, Color(1, 1, 1), true, -1.0, true)
