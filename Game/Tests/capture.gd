extends Node

## Visual check: plays the title and a stage with a scripted pilot, saving screenshots as it goes.
## Run: Godot --path Game res://Tests/capture.tscn -- <output dir> [stage index] [full|quick]

const FULL_SHOTS := [
	["title", 2.5],
	["stage_early", 9.0],
	["stage_mid", 30.0],
	["stage_late", 70.0],
	["boss_enter", 116.0],
	["boss_fight", 126.0],
	["boss_late", 140.0],
]
const QUICK_SHOTS := [
	["stage_early", 12.0],
	["stage_mid", 24.0],
]

var out_dir := "user://captures"
var elapsed := 0.0
var next_shot := 0
var main: Node
var in_stage := false
var shots: Array = FULL_SHOTS
var stage_index := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	if args.size() > 1:
		stage_index = int(args[1])
	if args.size() > 2 and args[2] == "quick":
		shots = QUICK_SHOTS
	DirAccess.make_dir_recursive_absolute(out_dir)
	main = load("res://Scripts/main.gd").new()
	add_child(main)


func _process(delta: float) -> void:
	elapsed += delta
	if not in_stage and elapsed > 3.0:
		in_stage = true
		Game.start_new_game()
		Game.stage_index = stage_index
		main.start_stage()

	if in_stage:
		# Endless stock so the pilot always reaches the boss.
		Game.stock = maxi(Game.stock, 50)
		if elapsed > 3.3:
			_pilot()

	if next_shot < shots.size() and elapsed >= shots[next_shot][1]:
		var image := get_viewport().get_texture().get_image()
		image.save_png(out_dir.path_join("%s.png" % shots[next_shot][0]))
		print("captured ", shots[next_shot][0])
		next_shot += 1
		if next_shot >= shots.size():
			get_tree().quit()


# Weaves side to side while shooting and bombing, so screenshots show the game in motion.
func _pilot() -> void:
	Input.action_press("shoot")
	Input.action_press("bomb")
	var phase := fmod(elapsed, 4.0)
	Input.action_release("move_left")
	Input.action_release("move_right")
	if phase < 1.5:
		Input.action_press("move_left")
	elif phase >= 2.0 and phase < 3.5:
		Input.action_press("move_right")
