class_name Title
extends Node2D

## Title screen over a slowly scrolling meadow: logo, bobbing ship, floating bells, controls.

const LOGO := "BELL BEE"
const LOGO_COLORS := [
	Color(1.0, 0.82, 0.2), Color(0.35, 0.65, 1.0), Color(1.0, 0.45, 0.55), Color(0.4, 0.88, 0.45),
	Color(1.0, 1.0, 1.0), Color(1.0, 0.82, 0.2), Color(0.35, 0.65, 1.0), Color(1.0, 0.45, 0.55),
]
const CONTROLS := [
	["MOVE", "ARROWS / WASD"],
	["SHOOT", "Z / J"],
	["BOMB", "X / K"],
	["PAUSE", "ESC / P"],
]

var ground: Ground
var wisps: Wisps
var scroll := 0.0
var t := 0.0
var starting := false
var overlay: Node2D


func _ready() -> void:
	ground = Ground.new()
	ground.setup(Themes.get_theme(0), 99)
	add_child(ground)
	wisps = Wisps.new()
	wisps.density = 0.7
	add_child(wisps)
	# The UI draws on its own node above the wisps.
	overlay = Node2D.new()
	add_child(overlay)
	overlay.draw.connect(_draw_overlay.bind(overlay))
	Audio.play_music("title")


func _process(delta: float) -> void:
	t += delta
	scroll += 22.0 * delta
	ground.scroll = scroll
	overlay.queue_redraw()


# Input events rather than polling, so a key tapped and released within one frame still counts.
func _unhandled_input(event: InputEvent) -> void:
	if starting:
		return
	if event.is_action_pressed("start") or event.is_action_pressed("shoot"):
		starting = true
		Audio.stop_music()
		Audio.play("start")
		get_tree().create_timer(0.6).timeout.connect(Game.start_new_game)
	elif event.is_action_pressed("pause") and not OS.has_feature("web"):
		get_tree().quit()


func _draw_overlay(ci: Node2D) -> void:
	var w := Stage.W
	var ink := Color(0.12, 0.1, 0.3)

	# Soft sky wash behind the logo.
	Art.glow_at(ci, Vector2(w * 0.5, 150), 300.0, Color(1, 1, 1, 0.55))

	# Bells drifting around the logo.
	for i in range(5):
		var a := t * 0.6 + i * TAU / 5.0
		var p := Vector2(w * 0.5 + cos(a) * 185.0, 150.0 + sin(a * 1.3) * 60.0)
		Art.bell(ci, p, 13.0, Bell.COLORS[i], sin(t * 4.0 + i) * 0.3)

	# Logo: each letter bobs on its own beat.
	var font := Game.font_bold
	var size := 64
	var x := w * 0.5 - font.get_string_size(LOGO, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	for i in range(LOGO.length()):
		var ch := LOGO[i]
		var bob := sin(t * 3.0 + i * 0.6) * 6.0
		var pos := Vector2(x, 170.0 + bob)
		ci.draw_string_outline(font, pos + Vector2(3, 5), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 12, Color(0, 0, 0.1, 0.3))
		ci.draw_string_outline(font, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 12, ink)
		ci.draw_string(font, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, LOGO_COLORS[i])
		x += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

	_text(ci, "A BELL-SHOOTING SKY ADVENTURE", Vector2(0, 205), 14, Color(1, 1, 1), w)

	# Ship.
	var ship_pos := Vector2(w * 0.5, 330.0 + sin(t * 2.0) * 8.0)
	Art.soft_shadow(ci, ship_pos + Vector2(26, 44), 30.0)
	Art.ship(ci, ship_pos, 2.0, t, true, true, sin(t * 1.3) * 0.4)

	if starting or int(t * 2.0) % 2 == 0:
		_text(ci, "PRESS START", Vector2(0, 440), 24, Color(1.0, 0.95, 0.5), w)

	for i in range(CONTROLS.size()):
		var y := 490.0 + i * 22.0
		_text(ci, CONTROLS[i][0], Vector2(w * 0.5 - 150, y), 14, Color(0.7, 0.9, 1.0), 120, HORIZONTAL_ALIGNMENT_RIGHT)
		_text(ci, CONTROLS[i][1], Vector2(w * 0.5 - 18, y), 14, Color(1, 1, 1), 200, HORIZONTAL_ALIGNMENT_LEFT)

	_text(ci, "HI-SCORE  %07d" % Game.high_score, Vector2(0, 608), 16, Color(1.0, 0.75, 0.8), w)


func _text(ci: Node2D, s: String, pos: Vector2, size: int, color: Color, width: float,
		align := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	ci.draw_string_outline(Game.font_bold, pos, s, align, width, size, 5, Color(0.12, 0.1, 0.3))
	ci.draw_string(Game.font_bold, pos, s, align, width, size, color)
