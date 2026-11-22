extends TestCase
## The placeholder runner on the endless level.

const RUNNER := preload("res://scenes/player/runner.tscn")

var level: EndlessLevel
var runner: Runner


func before_each() -> void:
	level = EndlessLevel.new()
	level.settings = TerrainSettings.new()
	runner = RUNNER.instantiate()
	runner.use_player_input = false
	runner.movement = Movement.new()
	level.add_child(runner)
	level.runner = runner
	keep(level)


func _wait(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame


func test_stands_on_the_ground() -> void:
	await _wait(60)
	assert_true(runner.is_on_floor(), "on the floor")
	var ground := level.surface_point(runner.position.x, level.runner_distance())
	assert_near(runner.position.y, ground.y, 0.3, "feet on the ground")


func test_running_forward_goes_far_and_fast() -> void:
	await _wait(20)
	runner.move_input = Vector2(0.0, 1.0)
	await _wait(240)  # 4 s
	assert_true(level.runner_distance() > 50.0, "distance %.1f" % level.runner_distance())
	assert_true(runner.speed > 15.0, "speed %.1f" % runner.speed)


func test_jump_leaves_the_ground() -> void:
	await _wait(30)
	var start_y := runner.position.y
	runner.wants_jump = true
	await _wait(10)
	assert_false(runner.is_on_floor(), "in the air")
	assert_true(runner.position.y > start_y + 0.5, "went up")


func test_fast_fall_lands_sooner() -> void:
	await _wait(30)
	runner.wants_jump = true
	runner.fast_falling = true
	var frames := 0
	await _wait(3)
	while not runner.is_on_floor() and frames < 120:
		await _wait(1)
		frames += 1
	assert_true(frames < 30, "landed after %d frames (a normal jump is about 44)" % frames)
