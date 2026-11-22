extends TestCase
## Landing on flat and 20° sloped floors: how much speed is kept, the signals
## and the effects.

const RUNNER := preload("res://scenes/player/runner.tscn")

var world: Node3D
var runner: Runner
var landings: Array[Vector3] = []  # (impact, kept, speed right after)
var fast_fall_events: Array[bool] = []


func before_each() -> void:
	world = Node3D.new()
	keep(world)
	landings.clear()
	fast_fall_events.clear()


## A floor through the origin tilted by [param degrees] around X (negative:
## going down towards -Z), and the runner just above it moving with [param v].
func _drop(degrees: float, v: Vector3, fast_fall := false, m: Movement = null, height := 0.4) -> void:
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	shape.position = Vector3.DOWN * 0.5
	floor_body.add_child(shape)
	floor_body.rotation.x = deg_to_rad(degrees)
	world.add_child(floor_body)
	runner = RUNNER.instantiate()
	runner.use_player_input = false
	runner.movement = m if m else Movement.new()
	world.add_child(runner)
	runner.position = Vector3.UP * height
	runner.velocity = v
	runner.heading = Vector3(v.x, 0.0, v.z).normalized()
	runner.fast_falling = fast_fall
	runner.landed.connect(func(impact: float, kept: float) -> void:
		landings.append(Vector3(impact, kept, runner.speed)))
	runner.fast_fall_changed.connect(func(on: bool) -> void: fast_fall_events.append(on))
	for i in 10:
		await get_tree().physics_frame


func test_flat_landing_turns_some_fall_into_speed() -> void:
	await _drop(0.0, Vector3(0.0, -20.0, -20.0))
	assert_eq(landings.size(), 1, "one landing")
	assert_between(landings[0].z, 24.0, 27.0, "20 + 20 × 0.5 × 0.5 ≈ 25")


func test_downhill_landing_gains_speed() -> void:
	await _drop(-20.0, Vector3(0.0, -20.0, -20.0))
	assert_eq(landings.size(), 1, "one landing")
	assert_between(landings[0].z, 29.0, 34.0, "≈ 31.6 m/s")
	assert_true(landings[0].y > 1.0, "kept more than the total before (%.2f)" % landings[0].y)


func test_uphill_landing_keeps_the_minimum() -> void:
	await _drop(-20.0, Vector3(0.0, -20.0, 20.0))
	assert_near(landings[0].z, 15.0, 1.0, "75% of 20 m/s")


func test_no_convert_is_the_old_landing() -> void:
	var m := Movement.new()
	m.landing_convert = 0.0
	m.landing_min_keep = 0.0
	await _drop(0.0, Vector3(0.0, -20.0, -20.0), false, m)
	assert_between(landings[0].z, 19.0, 20.5, "keeps only the 20 m/s along the ground")


func test_fast_fall_signal_on_then_off_at_landing() -> void:
	await _drop(0.0, Vector3(0.0, -5.0, -10.0), true)
	assert_eq(fast_fall_events, [true, false] as Array[bool], "on in the air, off on the ground")


func test_hard_landing_leaves_effects() -> void:
	await _drop(0.0, Vector3(0.0, -30.0, -10.0), true)
	assert_eq(world.get_child_count(), 3, "floor, runner, dust left in the world")
	assert_eq(runner.get_node("Effects").get_child_count(), 2, "speed lines + ring")


func test_small_hop_leaves_no_effects() -> void:
	await _drop(0.0, Vector3(0.0, -1.0, -10.0), false, null, 0.02)
	assert_eq(world.get_child_count(), 2, "only floor and runner")
	assert_eq(runner.get_node("Effects").get_child_count(), 1, "speed lines only")
