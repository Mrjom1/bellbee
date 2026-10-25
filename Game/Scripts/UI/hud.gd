class_name Hud
extends CanvasLayer

## Score bar, stock and power readout, boss gauge, banners, pause and continue screens.

const INK := Color(0.12, 0.1, 0.3)

var stage: Stage
var canvas: Node2D
var t := 0.0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas = Node2D.new()
	add_child(canvas)
	canvas.draw.connect(_draw_hud)


func _process(delta: float) -> void:
	t += delta
	canvas.queue_redraw()


func text(s: String, pos: Vector2, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, outline := 5) -> void:
	var font := Game.font_bold
	canvas.draw_string_outline(font, pos, s, align, width, size, outline, INK)
	canvas.draw_string(font, pos, s, align, width, size, color)


func _draw_hud() -> void:
	var w := Stage.W
	var h := Stage.H

	# Score bar.
	canvas.draw_rect(Rect2(0, 0, w, 30), Color(0.1, 0.12, 0.3, 0.35))
	text("1P", Vector2(12, 21), 13, Color(0.55, 0.85, 1.0))
	text("%07d" % Game.score, Vector2(34, 22), 17, Color(1, 1, 1))
	text("HI", Vector2(w * 0.5 - 52, 21), 13, Color(1.0, 0.6, 0.65))
	text("%07d" % Game.high_score, Vector2(w * 0.5 - 30, 22), 17, Color(1.0, 0.95, 0.75))
	text("STAGE %d" % (Game.stage_index + 1 + Game.loop * Game.STAGE_COUNT), Vector2(0, 21), 13,
		Color(0.8, 1.0, 0.8), HORIZONTAL_ALIGNMENT_RIGHT, w - 12)

	# Stock.
	for i in range(mini(Game.stock, 6)):
		Art.ship(canvas, Vector2(18 + i * 22, h - 18), 0.48, t, true, true, 0.0)

	_draw_power(Vector2(w - 12, h - 14))

	if stage.boss != null and is_instance_valid(stage.boss) and stage.boss.phase != Boss.Phase.DYING:
		var k := float(maxi(stage.boss.hp, 0)) / stage.boss.max_hp
		var bar := Rect2(60, 38, w - 120, 9)
		canvas.draw_rect(bar.grow(2), Color(0.1, 0.08, 0.25, 0.6))
		canvas.draw_rect(Rect2(bar.position, Vector2(bar.size.x * k, bar.size.y)), Color(1.0, 0.4, 0.45).lerp(Color(1, 0.85, 0.3), k))
		text("BOSS", Vector2(12, 47), 12, Color(1, 0.7, 0.7))

	if stage.banner_time > 0.0:
		_draw_banner()

	if stage.state == Stage.State.GAME_OVER:
		_draw_game_over()
	elif stage.get_tree().paused:
		canvas.draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.05, 0.15, 0.55))
		text("PAUSE", Vector2(0, h * 0.45), 44, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER, w, 8)
		text("ESC / P  resume      Q  quit to title", Vector2(0, h * 0.45 + 40), 14, Color(0.85, 0.9, 1.0),
			HORIZONTAL_ALIGNMENT_CENTER, w)


func _draw_power(anchor: Vector2) -> void:
	var player := stage.player
	var x := anchor.x

	if player.barrier > 0:
		Art.glow_at(canvas, Vector2(x - 6, anchor.y - 4), 10.0, Color(1.0, 0.4, 0.5, 0.7))
		text("x%d" % player.barrier, Vector2(x - 18, anchor.y + 2), 11, Color(1.0, 0.7, 0.75))
		x -= 40.0

	for i in range(player.options):
		Art.ball(canvas, Vector2(x - 6, anchor.y - 4), 5.0, Color(0.45, 0.95, 0.55))
		x -= 14.0

	if player.twin:
		var on := player.has_twin()
		text("TWIN", Vector2(x - 36, anchor.y + 1), 11, Color(1, 1, 1) if on else Color(0.6, 0.6, 0.7))
		x -= 44.0

	for i in range(Player.MAX_SPEED_LEVEL):
		var filled := i < player.speed_level
		var p := Vector2(x - 6 - (Player.MAX_SPEED_LEVEL - 1 - i) * 8, anchor.y - 4)
		canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -5), p + Vector2(4, 3), p + Vector2(-4, 3)]),
			Color(0.45, 0.75, 1.0) if filled else Color(0.3, 0.35, 0.5, 0.6))

	if not player.can_bomb() and player.alive:
		var blink := int(t * 3.0) % 2 == 0
		if blink:
			text("NO BOMB", Vector2(0, Stage.H - 36), 12, Color(1.0, 0.6, 0.6), HORIZONTAL_ALIGNMENT_CENTER, Stage.W)


func _draw_banner() -> void:
	var shown_for := stage.banner_duration - stage.banner_time
	var fade := clampf(stage.banner_time * 2.0, 0.0, 1.0) * clampf(shown_for * 6.0, 0.0, 1.0)
	var y := Stage.H * 0.38
	# Pops in slightly oversized, then settles.
	var scale := 1.0 + 0.35 * maxf(0.0, 1.0 - shown_for * 4.0)
	var color := Color(1, 1, 1, fade)
	if stage.banner == "WARNING":
		color = Color(1.0, 0.35, 0.4, fade * (0.6 + 0.4 * sin(t * 12.0)))
	canvas.draw_set_transform(Vector2(Stage.W * 0.5, y), 0.0, Vector2(scale, scale))
	var font := Game.font_bold
	canvas.draw_string_outline(font, Vector2(-Stage.W * 0.5, 0), stage.banner, HORIZONTAL_ALIGNMENT_CENTER, Stage.W, 40, 9,
		Color(INK.r, INK.g, INK.b, fade))
	canvas.draw_string(font, Vector2(-Stage.W * 0.5, 0), stage.banner, HORIZONTAL_ALIGNMENT_CENTER, Stage.W, 40, color)
	canvas.draw_set_transform(Vector2.ZERO)
	if stage.banner_sub != "":
		text(stage.banner_sub, Vector2(0, y + 30), 16, Color(1.0, 0.95, 0.7, fade), HORIZONTAL_ALIGNMENT_CENTER, Stage.W)


func _draw_game_over() -> void:
	var w := Stage.W
	var h := Stage.H
	canvas.draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.05, 0.15, 0.45))
	text("GAME OVER", Vector2(0, h * 0.4), 42, Color(1.0, 0.55, 0.6), HORIZONTAL_ALIGNMENT_CENTER, w, 8)
	if stage.state_time > 1.0:
		text("CONTINUE?", Vector2(0, h * 0.5), 22, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER, w)
		text(str(stage.continue_seconds_left()), Vector2(0, h * 0.5 + 56), 48, Color(1.0, 0.9, 0.4), HORIZONTAL_ALIGNMENT_CENTER, w, 8)
		if int(t * 2.5) % 2 == 0:
			text("PRESS START", Vector2(0, h * 0.5 + 92), 16, Color(0.8, 0.9, 1.0), HORIZONTAL_ALIGNMENT_CENTER, w)
