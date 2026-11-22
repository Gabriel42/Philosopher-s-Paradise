extends TestCase
## The runner model alone, driven by calling [method RunnerModel.animate]
## once per physics frame like the runner does.

const MODEL := preload("res://scenes/player/runner_model.tscn")

var model: RunnerModel


func before_each() -> void:
	model = MODEL.instantiate()
	keep(model)


func _frames(count: int, speed: float, on_floor: bool, slope := 0.0) -> void:
	for i in count:
		model.animate(speed, on_floor, slope)
		await get_tree().physics_frame


func test_one_frame_hop_keeps_running() -> void:
	await _frames(20, 20.0, true)
	assert_eq(model.current_animation(), "run", "running")
	for hop in 5:
		await _frames(1, 0.0, false)
		assert_eq(model.current_animation(), "run", "still running in hop %d" % hop)
		await _frames(3, 20.0, true)
	assert_eq(model.current_animation(), "run", "never switched")


func test_real_air_time_starts_the_jump() -> void:
	await _frames(20, 20.0, true)
	await _frames(12, 0.0, false)  # 0.2 s
	assert_eq(model.current_animation(), "air_jump", "jumping after the grace time")


func test_stride_quicker_on_a_climb() -> void:
	await _frames(10, 14.0, true, 0.0)
	var flat := model.get_node("Mannequiny/AnimationPlayer").speed_scale as float
	await _frames(10, 14.0, true, 20.0)
	var climb := model.get_node("Mannequiny/AnimationPlayer").speed_scale as float
	assert_near(flat, 2.0, 0.01, "14 / 7 m/s on the flat")
	assert_near(climb, 2.6, 0.01, "30% quicker on a 20° climb")
