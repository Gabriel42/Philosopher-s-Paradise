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


func _fly(seconds: float, climb: float, side: float, on_floor := false) -> void:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		model.animate(0.0, on_floor)
		model.fly(climb, side)
		await get_tree().physics_frame


func test_flying_body_points_where_it_goes() -> void:
	await _fly(0.4, 0.0, 0.0)
	assert_near(model.tip(), -90.0, 1.0, "level: belly flat, head forward")
	await _fly(0.3, 30.0, 0.0)
	assert_near(model.tip(), -69.0, 1.0, "going up 30°: head up 21°")
	await _fly(0.3, -45.0, 0.0)
	assert_near(model.tip(), -121.5, 1.0, "going down 45°: head down 31.5°")
	await _fly(0.3, -89.0, 0.0)
	assert_near(model.tip(), -140.0, 1.0, "never more than 50° head down")


func test_flying_body_banks_with_the_slide() -> void:
	await _fly(0.5, 0.0, 1.0)
	assert_near(model.bank(), 30.0, 0.5, "right: banked right")
	await _fly(0.6, 0.0, -1.0)
	assert_near(model.bank(), -30.0, 0.5, "left: banked left")
	await _fly(0.1, 0.0, -1.0, true)
	assert_near(model.bank(), 0.0, 0.5, "level again on the ground")
