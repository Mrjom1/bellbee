class_name StagePlan

## Builds the spawn timeline for a stage: a list of {at, type, ...} sorted by scroll distance.
## Seeded per stage and loop, so a stage plays the same way every time.

const LENGTH := 4400.0

# Air wave mix per stage; later stages lean on the tougher kinds.
const AIR_WAVES := [
	["puffs", "swoop", "puffs", "spinners", "swoop", "puffs", "kettle"],
	["swoop", "puffs", "spinners", "swoop", "kettle", "puffs", "spinners"],
	["spinners", "swoop", "kettle", "puffs", "swoop", "spinners", "kettle"],
]
const GROUND_WAVES := ["turrets", "huts", "tanks", "turrets", "huts"]


static func build(stage_index: int, loop: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + stage_index * 77 + loop * 13
	var events: Array = []
	var density := 1.0 + stage_index * 0.12 + loop * 0.25

	# Clouds: the bell supply. Steady through the whole stage, including the boss.
	var d := 40.0
	while d < LENGTH + 2000.0:
		events.append({"at": d, "type": "clouds", "count": rng.randi_range(1, 3)})
		d += rng.randf_range(170.0, 250.0)

	var waves: Array = AIR_WAVES[stage_index % AIR_WAVES.size()]
	d = 160.0
	var i := 0
	while d < LENGTH - 250.0:
		events.append({"at": d, "type": waves[i % waves.size()], "x": rng.randf_range(90.0, Stage.W - 90.0),
			"side": -1.0 if rng.randf() < 0.5 else 1.0})
		d += rng.randf_range(150.0, 220.0) / density
		i += 1

	d = 260.0
	i = 0
	while d < LENGTH - 150.0:
		events.append({"at": d, "type": GROUND_WAVES[(i + stage_index) % GROUND_WAVES.size()],
			"x": rng.randf_range(60.0, Stage.W - 60.0)})
		d += rng.randf_range(130.0, 200.0) / density
		i += 1

	events.append({"at": LENGTH, "type": "boss"})
	events.sort_custom(func(a, b): return a["at"] < b["at"])
	return events
