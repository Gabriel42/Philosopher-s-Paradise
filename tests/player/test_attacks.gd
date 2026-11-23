extends TestCase
## Runner attacks: enemy health and kills, each of the 10 attacks killing
## enemies placed in front of a still runner, aiming at the closest, not firing
## with nobody in reach, flyers being hit, and the mouse-wheel swap.
## Enemies stand still (their swarm doesn't step on its own); attacks run on
## real physics frames with their default numbers.

var level: EndlessLevel
var swarm: EnemySwarm
var runner: Node3D


func before_each() -> void:
	level = EndlessLevel.new()
	level.settings = TerrainSettings.new()
	keep(level)
	level.set_physics_process(false)
	runner = Node3D.new()
	level.add_child(runner)
	runner.global_position = level.surface_point(0.0, 0.0)


## A swarm of [param count] standing enemies (all far ahead until placed).
func _swarm(count: int, flying := false) -> EnemySwarm:
	var s := EnemySwarm.new()
	s.settings = EnemySettings.new()
	s.settings.count = count
	s.settings.flying = flying
	level.add_child(s)
	s.set_physics_process(false)
	s.step(0.0, runner.global_position, Vector3.ZERO)  # fills the pool
	return s


## Puts enemy [param i] of [param s] on the ground [param x] m to the side and
## [param distance] m ahead of the runner.
func _place(s: EnemySwarm, i: int, x: float, distance: float) -> void:
	s.positions[i] = level.surface_point(x, distance)
	s.step(0.0, runner.global_position, Vector3.ZERO)  # refreshes the drawing


func _attack(script: GDScript) -> Attack:
	var attack: Attack = script.new()
	level.add_child(attack)
	attack.setup(runner, level)
	attack.active = true
	return attack


func _frames(count: int) -> void:
	for k in count:
		await get_tree().physics_frame


# --- Enemy health ---------------------------------------------------------

func test_damage_kills_at_zero_health_and_sends_the_enemy_ahead() -> void:
	swarm = _swarm(1)
	_place(swarm, 0, 0.0, 5.0)
	var killed := []
	swarm.enemy_killed.connect(func(total: int) -> void: killed.append(total))
	var generation := swarm.generations[0]
	assert_false(swarm.damage(0, 2.0))
	assert_near(swarm.health[0], 1.0)
	assert_true(swarm.damage(0, 1.0))
	assert_eq(swarm.kills, 1)
	assert_eq(killed, [1])
	assert_eq(swarm.generations[0], generation + 1)
	assert_near(swarm.health[0], swarm.settings.health)
	assert_true(swarm.positions[0].z < runner.global_position.z - 40.0, "sent ahead")


func test_distance_to_measures_from_the_capsule_surface() -> void:
	swarm = _swarm(1)
	_place(swarm, 0, 0.0, 5.0)
	var c := swarm.center(0)
	assert_near(swarm.distance_to(0, c + Vector3(1.3, 0.0, 0.0)), 1.0)
	assert_near(swarm.distance_to(0, c + Vector3(0.0, 1.5, 0.0)), 1.0)
	assert_true(swarm.distance_to(0, c) < 0.0, "inside")


func test_a_target_is_no_longer_alive_once_its_enemy_died() -> void:
	swarm = _swarm(1)
	_place(swarm, 0, 0.0, 5.0)
	var target := AttackTarget.new(swarm, 0)
	assert_true(target.alive())
	swarm.damage(0, 100.0)
	assert_false(target.alive())


# --- Each attack ----------------------------------------------------------

## Places one enemy, runs [param script] for [param seconds] and checks it died.
func _kills_one(script: GDScript, x: float, distance: float, seconds := 2.0) -> Attack:
	swarm = _swarm(1)
	_place(swarm, 0, x, distance)
	var attack := _attack(script)
	await _frames(roundi(seconds * 60.0))
	assert_eq(swarm.kills, 1, "%s kills" % attack.settings.display_name)
	assert_eq(attack.kills, 1)
	return attack


func test_spark_bolt() -> void:
	await _kills_one(SparkBolt, 3.0, 15.0)


func test_arc_chain_jumps_from_enemy_to_enemy() -> void:
	swarm = _swarm(3)
	_place(swarm, 0, 0.0, 10.0)
	_place(swarm, 1, 4.0, 16.0)
	_place(swarm, 2, 8.0, 22.0)
	var attack := _attack(ArcChain)
	await _frames(2)
	assert_eq(attack.fired, 1)
	assert_eq(swarm.kills, 3, "one arc killed all three")


func test_orbit_stones() -> void:
	await _kills_one(OrbitStones, 3.0, 0.0, 1.5)


func test_pulse() -> void:
	var attack := await _kills_one(Pulse, 0.0, 5.0, 0.2)
	assert_eq(attack.fired, 1)


func test_lance_goes_through_every_enemy_in_line() -> void:
	swarm = _swarm(3)
	_place(swarm, 0, 0.0, 8.0)
	_place(swarm, 1, 0.0, 16.0)
	_place(swarm, 2, 0.0, 24.0)
	var attack := _attack(Lance)
	await _frames(2)
	assert_eq(attack.fired, 1)
	assert_eq(swarm.kills, 3)


func test_seekers() -> void:
	await _kills_one(Seekers, -4.0, 15.0, 3.0)


func test_starfall_lands_after_its_fall_time() -> void:
	swarm = _swarm(1)
	_place(swarm, 0, 2.0, 12.0)
	var attack := _attack(Starfall)
	await _frames(30)  # 0.5 s: still falling
	assert_eq(swarm.kills, 0)
	await _frames(30)
	assert_eq(swarm.kills, 1)
	assert_eq(attack.kills, 1)


func test_glaive_comes_back() -> void:
	var attack := await _kills_one(Glaive, 0.0, 10.0, 0.6) as Glaive
	await _frames(60)
	assert_true(attack.discs.is_empty(), "back in the hand")


func test_shard_fan() -> void:
	await _kills_one(ShardFan, 0.0, 10.0)


func test_vortex_pulls_and_hurts_over_time() -> void:
	swarm = _swarm(2)
	_place(swarm, 0, 0.0, 15.0)
	_place(swarm, 1, 4.0, 15.0)
	var attack := _attack(Vortex)
	await _frames(15)
	var gap := absf(swarm.positions[1].x - swarm.positions[0].x)
	assert_true(gap < 3.0, "pulled together (gap %.2f)" % gap)
	assert_eq(swarm.kills, 0, "not dead in 0.25 s")
	await _frames(60)
	assert_eq(swarm.kills, 2)
	assert_eq(attack.kills, 2)


# --- Aiming ---------------------------------------------------------------

func test_aims_at_the_closest_enemy() -> void:
	swarm = _swarm(2)
	_place(swarm, 0, 0.0, 25.0)
	_place(swarm, 1, 5.0, 10.0)
	var attack := _attack(Lance)
	await _frames(2)
	assert_eq(swarm.kills, 1)
	assert_true(swarm.positions[1].z < runner.global_position.z - 40.0, "the close one died")
	assert_near(swarm.positions[0], level.surface_point(0.0, 25.0), 0.01)
	assert_eq(attack.fired, 1)


func test_ignores_enemies_already_passed() -> void:
	swarm = _swarm(2)
	_place(swarm, 0, 0.0, -6.0)  # 6 m behind, the closest
	_place(swarm, 1, 0.0, 15.0)
	var behind := swarm.positions[0]
	var attack := _attack(Lance)
	await _frames(2)
	assert_eq(attack.fired, 1)
	assert_eq(swarm.kills, 1)
	assert_near(swarm.positions[0], behind, 0.01, "the one behind is left alone")


func test_does_not_fire_with_nobody_in_reach() -> void:
	swarm = _swarm(1)
	_place(swarm, 0, 0.0, 80.0)
	for script: GDScript in [SparkBolt, ArcChain, Pulse, Lance, Seekers, Starfall,
			Glaive, ShardFan, Vortex]:
		var attack := _attack(script)
		await _frames(3)
		assert_eq(attack.fired, 0, attack.settings.display_name)
		attack.active = false


func test_hits_flyers() -> void:
	swarm = _swarm(1, true)
	var p := swarm.positions[0]
	p.z = runner.global_position.z - 12.0
	swarm.positions[0] = p
	var attack := _attack(SparkBolt)
	await _frames(90)
	assert_eq(swarm.kills, 1)
	assert_eq(attack.kills, 1)


func test_shots_keep_up_with_a_fast_runner() -> void:
	swarm = _swarm(1)
	_place(swarm, 0, 3.0, 38.0)
	var attack := _attack(SparkBolt)
	var distance := 0.0
	for frame in 40:
		distance += 40.0 / 60.0  # runner at 40 m/s toward the enemy
		runner.global_position = level.surface_point(0.0, distance)
		await get_tree().physics_frame
	assert_eq(swarm.kills, 1)
	assert_eq(attack.kills, 1)


func test_shots_follow_the_origin_shift() -> void:
	swarm = _swarm(1)
	_place(swarm, 0, 0.0, 35.0)
	var attack := _attack(SparkBolt)
	await _frames(2)
	var before := attack.shots[0].position
	var shift := Vector3(0.0, -50.0, -2000.0)
	level.origin_shifted.emit(shift)
	assert_near(attack.shots[0].position, before - shift)


func test_turning_an_attack_off_clears_its_shots() -> void:
	swarm = _swarm(1)
	_place(swarm, 0, 0.0, 35.0)
	var attack := _attack(SparkBolt)
	await _frames(2)
	assert_eq(attack.shots.size(), 1)
	attack.active = false
	assert_true(attack.shots.is_empty())
	await _frames(60)
	assert_eq(swarm.kills, 0)


# --- Swapping -------------------------------------------------------------

func _player_attacks() -> PlayerAttacks:
	var attacks: PlayerAttacks = load("res://scenes/player/attacks/player_attacks.tscn").instantiate()
	runner.add_child(attacks)
	return attacks


func test_ten_attacks_one_on_at_a_time() -> void:
	var attacks := _player_attacks()
	assert_eq(attacks.attacks.size(), 10)
	var names := {}
	for attack in attacks.attacks:
		names[attack.settings.display_name] = true
		assert_eq(attack.runner, runner)
		assert_eq(attack.level, level)
	assert_eq(names.size(), 10, "ten different attacks")
	attacks.select(3)
	for k in 10:
		assert_eq(attacks.attacks[k].active, k == 3)


func test_mouse_wheel_swaps_and_wraps_around() -> void:
	var attacks := _player_attacks()
	var changed := []
	attacks.attack_changed.connect(func(i: int, _a: Attack) -> void: changed.append(i))
	var wheel := InputEventMouseButton.new()
	wheel.pressed = true
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	attacks._unhandled_input(wheel)
	assert_eq(attacks.index, 1)
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	attacks._unhandled_input(wheel)
	attacks._unhandled_input(wheel)
	assert_eq(attacks.index, 9, "wraps to the last")
	assert_eq(changed, [1, 0, 9])
	assert_true(attacks.current().active)
	var label := attacks.get_node("Hud/AttackName") as Label
	assert_true(label.text.contains("10/10"), label.text)
	assert_true(label.text.contains(attacks.current().settings.display_name), label.text)


func test_disabled_runs_no_attack_and_ignores_the_wheel() -> void:
	swarm = _swarm(1)
	_place(swarm, 0, 0.0, 10.0)
	var attacks := _player_attacks()
	attacks.enabled = false
	for attack in attacks.attacks:
		assert_false(attack.active)
	var wheel := InputEventMouseButton.new()
	wheel.pressed = true
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	attacks._unhandled_input(wheel)
	assert_eq(attacks.index, 0, "wheel ignored")
	await _frames(30)
	assert_eq(swarm.kills, 0)
	attacks.enabled = true
	assert_true(attacks.current().active)
	await _frames(60)  # Spark Bolt needs two bolts (2 + 2 damage)
	assert_true(swarm.kills >= 1, "attacks again once enabled")
