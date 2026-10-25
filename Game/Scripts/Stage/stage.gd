class_name Stage
extends Node2D

## One stage: scrolling, spawning from the plan, collisions, bell power-ups, arms/ambulance,
## death and continue, the boss, and stage clear.

enum State {
	PLAYING,
	BOSS,
	DEAD,
	CLEAR,
	GAME_OVER,
}

const W := 480.0
const H := 640.0
const SCROLL_SPEED := 40.0
const CLOUD_SPEED := 62.0
const RESPAWN_DELAY := 1.8
const AMBULANCE_DELAY := 2.5
const AMBULANCE_RETRY := 6.0
const CLEAR_TIME := 5.5
const CONTINUE_TIME := 9.99
const BOMB_BLAST_RADIUS := 24.0
const YELLOW_CHAIN := [500, 1000, 2000, 4000, 6000, 8000, 10000]
const FRUIT_CHAIN := [500, 1000, 2000, 3000, 5000]
const FORMATION_BONUS := 1000

var theme: Dictionary
var rank := 0.0
var scroll := 0.0
var events: Array = []
var next_event := 0
var state := State.PLAYING
var state_time := 0.0
var stage_time := 0.0
var yellow_chain := 0
var fruit_chain := 0
var formations := {}
var next_formation_id := 0
var ambulance_timer := -1.0
var boss: Boss
var banner := ""
var banner_sub := ""
var banner_time := 0.0
var banner_duration := 1.0

var world: Node2D
var ground: Ground
var ground_layer: Node2D
var shadow_layer: ShadowLayer
var cloud_layer: Node2D
var air_layer: Node2D
var bullet_layer: Node2D
var fx: Fx
var wisps: Wisps
var hud: Hud
var player: Player


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = Themes.get_theme(Game.stage_index)
	rank = Game.stage_index * 0.35 + Game.loop * 0.8
	events = StagePlan.build(Game.stage_index, Game.loop)

	world = Node2D.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)

	ground = Ground.new()
	ground.setup(theme, Game.stage_index + Game.loop * 3)
	world.add_child(ground)
	ground_layer = _add_layer()
	shadow_layer = ShadowLayer.new()
	shadow_layer.stage = self
	world.add_child(shadow_layer)
	cloud_layer = _add_layer()
	air_layer = _add_layer()
	bullet_layer = _add_layer()
	fx = Fx.new()
	world.add_child(fx)
	wisps = Wisps.new()
	world.add_child(wisps)

	player = Player.new()
	player.setup(self, Game.carry)
	air_layer.add_child(player)

	hud = Hud.new()
	hud.stage = self
	add_child(hud)

	Game.extended.connect(_on_extended)
	show_banner("STAGE %d" % (Game.stage_index + 1 + Game.loop * Game.STAGE_COUNT), theme["name"], 2.6)
	Audio.play("start")
	Audio.play_music("stage")


func _exit_tree() -> void:
	if Game.extended.is_connected(_on_extended):
		Game.extended.disconnect(_on_extended)


func _add_layer() -> Node2D:
	var layer := Node2D.new()
	world.add_child(layer)
	return layer


func controls_enabled() -> bool:
	return state == State.PLAYING or state == State.BOSS


func show_banner(text: String, sub := "", seconds := 2.0) -> void:
	banner = text
	banner_sub = sub
	banner_time = seconds
	banner_duration = seconds


func _process(_delta: float) -> void:
	if state == State.GAME_OVER:
		return
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = not get_tree().paused
		Audio.play("menu")
	elif get_tree().paused and Input.is_action_just_pressed("quit"):
		Game.end_run()


func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return

	stage_time += delta
	state_time += delta
	banner_time -= delta
	scroll += SCROLL_SPEED * delta
	ground.scroll = scroll

	_run_events()
	_collide()
	_update_ambulance(delta)

	match state:
		State.DEAD:
			if state_time >= RESPAWN_DELAY:
				_respawn_or_game_over()
		State.CLEAR:
			_update_clear()
		State.GAME_OVER:
			_update_game_over()


# --- Spawning -----------------------------------------------------------------

func _run_events() -> void:
	while next_event < events.size() and scroll >= events[next_event]["at"]:
		var event: Dictionary = events[next_event]
		next_event += 1
		# Once the boss arrives only clouds keep coming.
		if state != State.PLAYING and state != State.DEAD and event["type"] != "clouds":
			continue
		_spawn_event(event)


func _spawn_event(event: Dictionary) -> void:
	var x: float = event.get("x", W * 0.5)
	var side: float = event.get("side", 1.0)
	match event["type"]:
		"clouds":
			var count: int = event["count"]
			for i in range(count):
				var cx := (i + 0.5) / count * W + randf_range(-40.0, 40.0)
				var bells := 2 if randf() < 0.25 else 1
				_spawn_cloud(Vector2(clampf(cx, 50.0, W - 50.0), -50.0 - randf_range(0.0, 60.0)), bells)
		"puffs":
			for i in range(5):
				_spawn_air_delayed(AirEnemy.Kind.PUFF, Vector2(x, -20.0), i * 0.35)
		"swoop":
			var id := _new_formation(5)
			var start_x := -20.0 if side > 0.0 else W + 20.0
			for i in range(5):
				_spawn_air_delayed(AirEnemy.Kind.SWOOP, Vector2(start_x, 40.0 + randf_range(0, 10)), i * 0.2,
					{"side": side, "formation": id})
		"spinners":
			for i in range(2 + int(rank)):
				var sx := clampf(x + (i - 0.5) * 120.0, 50.0, W - 50.0)
				_spawn_air_delayed(AirEnemy.Kind.SPINNER, Vector2(sx, -24.0), i * 0.4,
					{"hover": randf_range(110.0, 220.0)})
		"kettle":
			spawn_air(AirEnemy.Kind.KETTLE, Vector2(clampf(x, 100.0, W - 100.0), -30.0), {"hover": 120.0})
		"turrets":
			for i in range(2):
				_spawn_ground(GroundEnemy.Kind.TURRET, x + (i - 0.5) * 60.0)
		"tanks":
			for i in range(2):
				_spawn_ground(GroundEnemy.Kind.TANK, x + (i - 0.5) * 50.0, -24.0 - i * 30.0)
		"huts":
			for i in range(randi_range(1, 3)):
				_spawn_ground(GroundEnemy.Kind.HUT, x + randf_range(-50.0, 50.0), -24.0 - i * 36.0)
		"boss":
			_start_boss()


func spawn_air(kind: AirEnemy.Kind, pos: Vector2, params := {}) -> AirEnemy:
	var enemy := AirEnemy.new()
	enemy.setup(self, kind, pos, params)
	enemy.add_to_group("flyers")
	air_layer.add_child(enemy)
	return enemy


func _spawn_air_delayed(kind: AirEnemy.Kind, pos: Vector2, delay: float, params := {}) -> void:
	if delay <= 0.0:
		spawn_air(kind, pos, params)
		return
	get_tree().create_timer(delay, false, true).timeout.connect(func():
		if state == State.PLAYING or state == State.DEAD:
			spawn_air(kind, pos, params))


func _spawn_ground(kind: GroundEnemy.Kind, x: float, y := -24.0) -> void:
	var land_x := ground.find_land_x(x, y)
	if is_nan(land_x):
		return
	var enemy := GroundEnemy.new()
	enemy.setup(self, kind, Vector2(land_x, y))
	ground_layer.add_child(enemy)


func _spawn_cloud(pos: Vector2, bells: int) -> void:
	var cloud := Cloud.new()
	cloud.setup(self, pos, bells, randf_range(0.85, 1.2))
	cloud.add_to_group("flyers")
	cloud_layer.add_child(cloud)


func spawn_bell(pos: Vector2) -> void:
	var bell := Bell.new()
	bell.setup(self, pos)
	bell.add_to_group("flyers")
	air_layer.add_child(bell)


func spawn_shot(pos: Vector2) -> void:
	var shot := Shot.new()
	shot.position = pos
	air_layer.add_child(shot)


func spawn_bomb(from: Vector2, to: Vector2) -> void:
	var bomb := Bomb.new()
	bomb.stage = self
	bomb.start = from
	bomb.target = to
	bomb.position = from
	air_layer.add_child(bomb)
	Audio.play("bomb_drop", -4.0)


func _new_formation(size: int) -> int:
	var id := next_formation_id
	next_formation_id += 1
	formations[id] = size
	return id


# --- Enemy fire ---------------------------------------------------------------

func bullet_speed() -> float:
	return 145.0 * (1.0 + rank * 0.18)


func fire_spread(from: Vector2, count: int, spread: float) -> void:
	if not player.alive:
		return
	var base := (player.position - from).angle()
	for i in range(count):
		var offset := (i - (count - 1) * 0.5) * spread
		_spawn_bullet(from, Vector2.from_angle(base + offset) * bullet_speed())


func fire_ring(from: Vector2, count: int, angle_offset: float, speed: float) -> void:
	for i in range(count):
		_spawn_bullet(from, Vector2.from_angle(angle_offset + TAU * i / count) * speed * (1.0 + rank * 0.1))


func _spawn_bullet(from: Vector2, vel: Vector2) -> void:
	var bullet := EnemyBullet.new()
	bullet.position = from
	bullet.vel = vel
	bullet_layer.add_child(bullet)


func clear_enemy_bullets() -> void:
	for bullet in get_tree().get_nodes_in_group("ebullets"):
		fx.burst(bullet.position, Color(1, 0.6, 0.8), 2, 40.0, 2.0, 0.3)
		bullet.queue_free()


# --- Collisions ---------------------------------------------------------------

func _collide() -> void:
	var targets: Array = []
	targets.append_array(get_tree().get_nodes_in_group("bells"))
	targets.append_array(get_tree().get_nodes_in_group("bosses"))
	targets.append_array(get_tree().get_nodes_in_group("air_enemies"))
	targets.append_array(get_tree().get_nodes_in_group("clouds"))

	for shot in get_tree().get_nodes_in_group("shots"):
		if shot.dead:
			continue
		for target in targets:
			if target.dead or not target.solid:
				continue
			var reach: float = target.radius + shot.radius
			if shot.position.distance_squared_to(target.position) < reach * reach:
				shot.dead = true
				shot.queue_free()
				target.on_shot(shot)
				break

	if not player.alive:
		return

	for bell in get_tree().get_nodes_in_group("bells"):
		if not bell.dead and player.position.distance_to(bell.position) < Player.PICKUP_RADIUS + bell.radius:
			_collect_bell(bell)

	for item in get_tree().get_nodes_in_group("items"):
		if not item.dead and player.position.distance_to(item.position) < Player.PICKUP_RADIUS + item.radius:
			_collect_item(item)

	for ambulance in get_tree().get_nodes_in_group("ambulances"):
		if not ambulance.dead and player.position.distance_to(ambulance.position) < Player.PICKUP_RADIUS + ambulance.radius:
			_board_ambulance(ambulance)

	if player.invulnerable > 0.0 or not controls_enabled():
		return

	for bullet in get_tree().get_nodes_in_group("ebullets"):
		var reach: float = Player.HIT_RADIUS + bullet.radius
		if player.position.distance_squared_to(bullet.position) < reach * reach:
			bullet.queue_free()
			_player_hit()
			return

	for enemy in get_tree().get_nodes_in_group("air_enemies"):
		if enemy.dead:
			continue
		var reach: float = Player.BODY_RADIUS + enemy.radius * 0.8
		if player.position.distance_squared_to(enemy.position) < reach * reach:
			enemy.damage(3)
			_player_hit()
			return

	if boss != null and is_instance_valid(boss) and boss.solid:
		if player.position.distance_to(boss.position) < Player.BODY_RADIUS + boss.radius * 0.85:
			_player_hit()


func bomb_landed(p: Vector2) -> void:
	fx.explosion(p, 0.6)
	Audio.play("bomb_hit", -3.0)
	for enemy in get_tree().get_nodes_in_group("ground_enemies"):
		var reach: float = BOMB_BLAST_RADIUS + enemy.radius
		if not enemy.dead and enemy.position.distance_squared_to(p) < reach * reach:
			enemy.damage(1)
			# Only real hits leave a scorch, so constant bombing does not litter the fields.
			ground.add_scorch(enemy.position)


# --- Scoring ------------------------------------------------------------------

func add_score(points: int, at: Vector2, color := Color(1, 1, 1), show := true) -> void:
	Game.add_score(points)
	if show:
		fx.popup(at, str(points), color)


func air_enemy_killed(enemy: AirEnemy) -> void:
	fx.explosion(enemy.position, 1.3 if enemy.kind == AirEnemy.Kind.KETTLE else 0.8)
	Audio.play("explode", -2.0)
	add_score(enemy.points, enemy.position, Color(1, 1, 1), enemy.points >= 300)
	if enemy.formation >= 0 and formations.has(enemy.formation):
		formations[enemy.formation] -= 1
		if formations[enemy.formation] <= 0:
			formations.erase(enemy.formation)
			add_score(FORMATION_BONUS, enemy.position + Vector2(0, -16), Color(1, 0.9, 0.4))
			spawn_bell(enemy.position)


func ground_enemy_killed(enemy: GroundEnemy) -> void:
	add_score(enemy.points, enemy.position, Color(1, 1, 1), false)
	for i in range(5):
		fx.chunk(enemy.position, Color(0.55, 0.5, 0.45), randf_range(2.0, 3.5),
			Vector2(randf_range(-80, 80), randf_range(-160, -60)))
	if enemy.kind == GroundEnemy.Kind.HUT:
		var item := Item.new()
		item.setup(self, enemy.position)
		ground_layer.add_child(item)


func yellow_bell_missed() -> void:
	yellow_chain = 0


func _collect_bell(bell: Bell) -> void:
	bell.dead = true
	var p := bell.position
	var color := bell.get_color()
	fx.ring(p, color, 30.0, 0.35)
	fx.burst(p, color, 10, 120.0, 2.5, 0.4)

	match bell.kind:
		Bell.Kind.YELLOW:
			var points: int = YELLOW_CHAIN[mini(yellow_chain, YELLOW_CHAIN.size() - 1)]
			yellow_chain += 1
			add_score(points, p, Color(1.0, 0.9, 0.3))
			Audio.play("bell_get")
		Bell.Kind.BLUE:
			if player.speed_level < Player.MAX_SPEED_LEVEL:
				player.speed_level += 1
				fx.popup(p, "SPEED UP", Color(0.5, 0.75, 1.0))
				Audio.play("powerup")
			else:
				add_score(500, p, Color(0.5, 0.75, 1.0))
				Audio.play("bell_get")
		Bell.Kind.WHITE:
			if not player.twin:
				player.twin = true
				fx.popup(p, "TWIN SHOT", Color(1, 1, 1))
				Audio.play("powerup")
			else:
				add_score(500, p)
				Audio.play("bell_get")
		Bell.Kind.GREEN:
			if player.options < Player.MAX_OPTIONS:
				player.options += 1
				fx.popup(p, "OPTION", Color(0.5, 1.0, 0.55))
				Audio.play("powerup")
			else:
				add_score(500, p, Color(0.5, 1.0, 0.55))
				Audio.play("bell_get")
		Bell.Kind.RED:
			player.barrier = Player.BARRIER_HITS
			fx.popup(p, "BARRIER", Color(1.0, 0.5, 0.55))
			Audio.play("powerup")
	bell.queue_free()


func _collect_item(item: Item) -> void:
	item.dead = true
	var points: int = FRUIT_CHAIN[mini(fruit_chain, FRUIT_CHAIN.size() - 1)]
	fruit_chain += 1
	add_score(points, item.position, Color(1.0, 0.75, 0.85))
	fx.burst(item.position, Color(1.0, 0.85, 0.5), 8, 90.0, 2.5, 0.4)
	Audio.play("fruit")
	item.queue_free()


func _on_extended() -> void:
	fx.popup(player.position + Vector2(0, -30), "1UP!", Color(0.5, 1.0, 0.6))
	Audio.play("extend")


# --- Damage, arms, ambulance --------------------------------------------------

func _player_hit() -> void:
	if player.barrier > 0:
		player.barrier -= 1
		player.invulnerable = 0.4
		fx.ring(player.position, Color(1.0, 0.5, 0.6), 32.0, 0.3)
		Audio.play("barrier_hit")
		return

	if player.arm_left or player.arm_right:
		var lose_left := player.arm_left and (not player.arm_right or randf() < 0.5)
		if lose_left:
			player.arm_left = false
		else:
			player.arm_right = false
		var side := -1.0 if lose_left else 1.0
		fx.chunk(player.position + Vector2(side * 21.0, -3.0), Color(1, 1, 1), 5.0,
			Vector2(side * 90.0, -150.0))
		fx.burst(player.position + Vector2(side * 16.0, 0.0), Color(1.0, 0.8, 0.4), 8, 120.0, 2.5, 0.35)
		player.invulnerable = 1.2
		Audio.play("arm_lost")
		if ambulance_timer < 0.0 and get_tree().get_nodes_in_group("ambulances").is_empty():
			ambulance_timer = AMBULANCE_DELAY
		return

	_kill_player()


func _kill_player() -> void:
	player.alive = false
	player.visible = false
	fx.explosion(player.position, 1.6)
	for i in range(6):
		fx.chunk(player.position, Art.SHIP_BLUE, randf_range(3.0, 5.0),
			Vector2(randf_range(-140, 140), randf_range(-220, -60)))
	Audio.play("death")
	yellow_chain = 0
	ambulance_timer = -1.0
	_set_state(State.DEAD)


func _respawn_or_game_over() -> void:
	if Game.stock <= 0:
		_set_state(State.GAME_OVER)
		Game.save_records()
		Audio.stop_music()
		Audio.play("game_over")
		return
	Game.stock -= 1
	player.respawn()
	_set_state(State.BOSS if boss != null and is_instance_valid(boss) else State.PLAYING)


func _update_ambulance(delta: float) -> void:
	if ambulance_timer < 0.0:
		return
	ambulance_timer -= delta
	if ambulance_timer > 0.0:
		return
	ambulance_timer = -1.0
	if not player.alive or (player.arm_left and player.arm_right):
		return
	var ambulance := Ambulance.new()
	ambulance.setup(self, player.position.x)
	ambulance.add_to_group("flyers")
	ambulance.tree_exited.connect(_on_ambulance_gone)
	air_layer.add_child(ambulance)
	Audio.play("siren")


func _on_ambulance_gone() -> void:
	# Missed it: send another one a little later.
	if is_inside_tree() and player.alive and not (player.arm_left and player.arm_right):
		ambulance_timer = AMBULANCE_RETRY


func _board_ambulance(ambulance: Ambulance) -> void:
	ambulance.dead = true
	player.arm_left = true
	player.arm_right = true
	fx.ring(player.position, Color(1, 1, 1), 34.0, 0.4)
	fx.popup(player.position + Vector2(0, -28), "ARMS BACK!", Color(1.0, 0.6, 0.65))
	Audio.play("arms_back")
	ambulance.queue_free()


# --- Boss, clear, game over ---------------------------------------------------

func _start_boss() -> void:
	# If the player is mid-respawn, the respawn picks up the BOSS state itself.
	if state != State.DEAD:
		_set_state(State.BOSS)
	show_banner("WARNING", "BIG ONE APPROACHING", 2.4)
	Audio.play("warning")
	Audio.play_music("boss")
	boss = Boss.new()
	boss.setup(self, Game.stage_index)
	boss.add_to_group("flyers")
	air_layer.add_child(boss)


func boss_defeated(defeated: Boss) -> void:
	fx.explosion(defeated.position, 3.0)
	for i in range(14):
		fx.chunk(defeated.position, defeated.body_color, randf_range(4.0, 8.0),
			Vector2(randf_range(-220, 220), randf_range(-300, -80)))
	add_score(defeated.points, defeated.position, Color(1, 0.9, 0.4))
	Audio.play("explode_big")
	boss = null
	_set_state(State.CLEAR)
	clear_enemy_bullets()
	Audio.stop_music()
	get_tree().create_timer(1.2, false).timeout.connect(func():
		Audio.play("stage_clear")
		show_banner("STAGE CLEAR", "", CLEAR_TIME))


func _update_clear() -> void:
	if not player.alive:
		player.respawn()
	if state_time > 2.0 and player.alive:
		player.position.y -= (state_time - 2.0) * 220.0 * get_physics_process_delta_time()
	if state_time >= CLEAR_TIME:
		Game.complete_stage(player.power())


func _update_game_over() -> void:
	if state_time < 1.0:
		return
	if Input.is_action_just_pressed("start"):
		Game.continue_game()
		player.respawn()
		Audio.play("start")
		Audio.play_music("boss" if boss != null and is_instance_valid(boss) else "stage")
		_set_state(State.BOSS if boss != null and is_instance_valid(boss) else State.PLAYING)
		return
	if state_time >= CONTINUE_TIME + 1.0:
		Game.end_run()


func continue_seconds_left() -> int:
	return maxi(0, int(ceil(CONTINUE_TIME + 1.0 - state_time)))


func _set_state(next: State) -> void:
	state = next
	state_time = 0.0
