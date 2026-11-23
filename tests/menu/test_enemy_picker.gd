extends TestCase
## Start screen that picks which enemy types are in the run: lists them,
## turns them on/off, pauses until Start, remembers the choice.

const SAVE := "user://test_enemy_picker.cfg"

var level: EndlessLevel
var enemy1: EnemySwarm
var enemy2: EnemyFlankers


func before_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	level = EndlessLevel.new()
	level.settings = TerrainSettings.new()
	enemy1 = EnemySwarm.new()
	enemy1.settings = EnemySettings.new()
	level.add_child(enemy1)
	enemy2 = EnemyFlankers.new()
	enemy2.settings = FlankerSettings.new()
	level.add_child(enemy2)
	keep(level)
	level.set_physics_process(false)
	enemy1.set_physics_process(false)
	enemy2.set_physics_process(false)


func after_each() -> void:
	get_tree().paused = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _picker(show := false) -> EnemyPicker:
	var picker := (load("res://scenes/menu/enemy_picker.tscn") as PackedScene).instantiate() as EnemyPicker
	picker.level = level
	picker.save_path = SAVE
	picker.show_at_start = show
	picker.skip_when_headless = false
	keep(picker)
	return picker


func _fill() -> void:
	var pos := level.surface_point(0.0, 0.0)
	enemy1.step(1.0 / 60.0, pos, Vector3.ZERO)
	enemy2.step(1.0 / 60.0, pos, Vector3.ZERO)


func test_lists_every_enemy_type_ticked() -> void:
	var picker := _picker()
	assert_eq(picker.boxes.size(), 2)
	assert_eq(picker.boxes[0].text, "enemy1")
	assert_eq(picker.boxes[1].text, "enemy2")
	assert_true(picker.boxes[0].button_pressed and picker.boxes[1].button_pressed)


func test_unticking_turns_a_type_off() -> void:
	var picker := _picker()
	_fill()
	picker.boxes[0].button_pressed = false
	assert_false(enemy1.active)
	assert_eq(enemy1.positions.size(), 0)
	assert_true(enemy2.active)
	assert_eq(enemy2.positions.size(), 6)
	picker.boxes[0].button_pressed = true
	assert_true(enemy1.active)


func test_open_pauses_until_start() -> void:
	var picker := _picker(true)
	assert_true(picker.is_open())
	assert_true(get_tree().paused)
	var started: Array[bool] = []
	picker.started.connect(func() -> void: started.append(true))
	picker.start()
	assert_false(picker.is_open())
	assert_false(get_tree().paused)
	assert_eq(started.size(), 1)


func test_enter_starts() -> void:
	var picker := _picker(true)
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.pressed = true
	picker._input(enter)
	assert_false(picker.is_open())
	assert_false(get_tree().paused)


func test_remembers_the_choice() -> void:
	var picker := _picker(true)
	picker.boxes[1].button_pressed = false
	picker.start()
	picker.queue_free()
	enemy2.active = true  # a fresh game: every type starts on
	var again := _picker(true)
	assert_true(again.boxes[0].button_pressed)
	assert_false(again.boxes[1].button_pressed, "enemy2 still unticked")
	assert_false(enemy2.active)


func test_main_scene_lists_every_type_and_does_not_pause_headless() -> void:
	var main := keep((load("res://scenes/main/main.tscn") as PackedScene).instantiate())
	var picker := main.get_node("EnemyPicker") as EnemyPicker
	var names: Array[String] = []
	for box in picker.boxes:
		names.append(box.text)
	assert_eq(names, ["enemy1", "enemy2", "enemy3"] as Array[String])
	assert_false(picker.is_open(), "skipped in headless runs")
	assert_false(get_tree().paused)


func test_a_flying_type_can_be_turned_off() -> void:
	var flyers := EnemySwarm.new()
	flyers.settings = EnemySettings.new()
	flyers.settings.display_name = "flyers"
	flyers.settings.flying = true
	flyers.settings.count = 5
	level.add_child(flyers)
	flyers.set_physics_process(false)
	var picker := _picker()
	flyers.step(1.0 / 60.0, level.surface_point(0.0, 0.0), Vector3.ZERO)
	assert_eq(flyers.positions.size(), 5)
	picker.boxes[2].button_pressed = false
	assert_eq(flyers.positions.size(), 0)
	flyers.step(1.0 / 60.0, level.surface_point(0.0, 0.0), Vector3.ZERO)
	assert_eq(flyers.positions.size(), 0, "stays empty while off")
