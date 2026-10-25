class_name Themes

## Per-stage look: ground palette, water layout, tree colours, and sky haze.

enum WaterMode {
	RIVER,
	COAST,
}

const LIST := [
	{
		"name": "MEADOW",
		"mode": WaterMode.RIVER,
		"fields": [Color(0.55, 0.8, 0.38), Color(0.68, 0.86, 0.42), Color(0.88, 0.84, 0.46), Color(0.46, 0.72, 0.36)],
		"hedge": Color(0.3, 0.52, 0.27),
		"water_deep": Color(0.18, 0.44, 0.84),
		"water_shallow": Color(0.42, 0.78, 0.96),
		"sand": Color(0.94, 0.87, 0.63),
		"trees": [Color(0.24, 0.56, 0.26), Color(0.33, 0.66, 0.3), Color(0.2, 0.48, 0.3)],
		"roofs": [Color(0.9, 0.35, 0.32), Color(0.35, 0.5, 0.85), Color(0.95, 0.6, 0.25)],
		"haze": Color(0.85, 0.93, 1.0),
	},
	{
		"name": "COAST",
		"mode": WaterMode.COAST,
		"fields": [Color(0.5, 0.82, 0.48), Color(0.62, 0.88, 0.5), Color(0.82, 0.9, 0.55), Color(0.42, 0.74, 0.44)],
		"hedge": Color(0.26, 0.55, 0.36),
		"water_deep": Color(0.08, 0.4, 0.74),
		"water_shallow": Color(0.3, 0.84, 0.86),
		"sand": Color(0.99, 0.91, 0.66),
		"trees": [Color(0.18, 0.6, 0.38), Color(0.3, 0.72, 0.4), Color(0.15, 0.5, 0.36)],
		"roofs": [Color(0.98, 0.5, 0.45), Color(0.98, 0.85, 0.4), Color(0.4, 0.75, 0.9)],
		"haze": Color(0.8, 0.95, 1.0),
	},
	{
		"name": "AUTUMN",
		"mode": WaterMode.RIVER,
		"fields": [Color(0.93, 0.74, 0.42), Color(0.86, 0.58, 0.32), Color(0.96, 0.86, 0.56), Color(0.79, 0.64, 0.36)],
		"hedge": Color(0.56, 0.36, 0.2),
		"water_deep": Color(0.24, 0.38, 0.74),
		"water_shallow": Color(0.46, 0.66, 0.92),
		"sand": Color(0.96, 0.88, 0.7),
		"trees": [Color(0.9, 0.4, 0.2), Color(0.95, 0.65, 0.2), Color(0.75, 0.25, 0.22), Color(0.5, 0.6, 0.25)],
		"roofs": [Color(0.55, 0.32, 0.6), Color(0.3, 0.45, 0.7), Color(0.85, 0.3, 0.3)],
		"haze": Color(1.0, 0.9, 0.85),
	},
]


static func get_theme(index: int) -> Dictionary:
	return LIST[index % LIST.size()]


## Distance in px from (x, world_y) to the nearest water; negative means in the water.
## Mirrors land_dist() in ground.gdshader, without the shader's edge noise.
static func land_distance(mode: int, x: float, wy: float) -> float:
	if mode == WaterMode.RIVER:
		return absf(x - river_x(wy)) - river_width(wy)
	var left := 150.0 + 55.0 * sin(wy * 0.0023) + 25.0 * sin(wy * 0.0071 + 2.0)
	var right := 330.0 + 55.0 * sin(wy * 0.0021 + 1.7) + 25.0 * sin(wy * 0.0067)
	return -minf(x - left, right - x)


static func river_x(wy: float) -> float:
	return 240.0 + 120.0 * sin(wy * 0.0019) + 45.0 * sin(wy * 0.0053 + 1.3)


static func river_width(wy: float) -> float:
	return 34.0 + 10.0 * sin(wy * 0.004 + 0.7)
