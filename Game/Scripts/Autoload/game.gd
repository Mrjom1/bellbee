extends Node

## Run state shared across screens: score, stock, stage, and the power carried between stages.

signal extended

const SAVE_PATH := "user://bellbee.cfg"
const STAGE_COUNT := 3
const STARTING_STOCK := 2
const FIRST_EXTEND := 30000
const EXTEND_EVERY := 80000

var main: Node
var score := 0
var high_score := 0
var stock := STARTING_STOCK
var stage_index := 0
var loop := 0
var next_extend := FIRST_EXTEND
var carry := {}

var font: Font
var font_bold: Font


func _ready() -> void:
	_register_inputs()
	Art.init()
	font = _make_font(600)
	font_bold = _make_font(900)
	load_records()


func start_new_game() -> void:
	score = 0
	stock = STARTING_STOCK
	stage_index = 0
	loop = 0
	next_extend = FIRST_EXTEND
	carry = {}
	main.start_stage()


# Arcade-style continue: the score starts over, the stage does not.
func continue_game() -> void:
	score = 0
	stock = STARTING_STOCK
	next_extend = FIRST_EXTEND


func complete_stage(power: Dictionary) -> void:
	carry = power
	stage_index += 1
	if stage_index >= STAGE_COUNT:
		stage_index = 0
		loop += 1
	main.start_stage()


func end_run() -> void:
	save_records()
	main.show_title()


func add_score(points: int) -> void:
	score += points
	if score > high_score:
		high_score = score
	while score >= next_extend:
		stock += 1
		next_extend += EXTEND_EVERY
		extended.emit()


func load_records() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		high_score = int(config.get_value("records", "high_score", 0))


func save_records() -> void:
	var config := ConfigFile.new()
	config.set_value("records", "high_score", high_score)
	config.save(SAVE_PATH)


func _make_font(weight: int) -> Font:
	# Browsers expose no system fonts; thicken Godot's built-in font so text keeps its weight.
	if OS.has_feature("web"):
		var web_font := FontVariation.new()
		web_font.base_font = ThemeDB.fallback_font
		web_font.variation_embolden = (weight - 400) / 500.0
		return web_font

	var system_font := SystemFont.new()
	system_font.font_names = PackedStringArray(["Arial Rounded MT Bold", "Segoe UI", "Verdana", "Arial"])
	system_font.font_weight = weight
	return system_font


func _register_inputs() -> void:
	_bind("move_left", [KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_bind("move_right", [KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_bind("move_up", [KEY_UP, KEY_W], [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_LEFT_Y, -1.0]])
	_bind("move_down", [KEY_DOWN, KEY_S], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	_bind("shoot", [KEY_Z, KEY_J], [JOY_BUTTON_A], [])
	_bind("bomb", [KEY_X, KEY_K], [JOY_BUTTON_B, JOY_BUTTON_X], [])
	_bind("start", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE], [JOY_BUTTON_START], [])
	_bind("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START], [])
	_bind("quit", [KEY_Q], [JOY_BUTTON_BACK], [])


func _bind(action: String, keys: Array, buttons: Array, axes: Array) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action, 0.35)

	# Bind both the physical key and the key label: some browser and remote-input events carry only one.
	for key in keys:
		var physical_event := InputEventKey.new()
		physical_event.physical_keycode = key
		InputMap.action_add_event(action, physical_event)
		var label_event := InputEventKey.new()
		label_event.keycode = key
		InputMap.action_add_event(action, label_event)

	for button in buttons:
		var button_event := InputEventJoypadButton.new()
		button_event.button_index = button
		InputMap.action_add_event(action, button_event)

	for axis in axes:
		var motion_event := InputEventJoypadMotion.new()
		motion_event.axis = axis[0]
		motion_event.axis_value = axis[1]
		InputMap.action_add_event(action, motion_event)
