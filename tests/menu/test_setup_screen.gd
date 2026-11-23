extends TestCase
## Setup screen that picks which enemy types are in the run: lists them,
## turns them on/off, pauses until Start, remembers the choice.

const SAVE := "user://test_setup_screen.cfg"

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


func _setup(show := false) -> SetupScreen:
	var setup := (load("res://scenes/menu/setup_screen.tscn") as PackedScene).instantiate() as SetupScreen
	setup.level = level
	setup.save_path = SAVE
	setup.show_at_start = show
	setup.skip_when_headless = false
	keep(setup)
	return setup


func _fill() -> void:
	var pos := level.surface_point(0.0, 0.0)
	enemy1.step(1.0 / 60.0, pos, Vector3.ZERO)
	enemy2.step(1.0 / 60.0, pos, Vector3.ZERO)


func test_lists_every_enemy_type_ticked() -> void:
	var setup := _setup()
	assert_eq(setup.boxes.size(), 2)
	assert_eq(setup.boxes[0].text, "enemy1")
	assert_eq(setup.boxes[1].text, "enemy2")
	assert_true(setup.boxes[0].button_pressed and setup.boxes[1].button_pressed)


func test_unticking_turns_a_type_off() -> void:
	var setup := _setup()
	_fill()
	setup.boxes[0].button_pressed = false
	assert_false(enemy1.active)
	assert_eq(enemy1.positions.size(), 0)
	assert_true(enemy2.active)
	assert_eq(enemy2.positions.size(), 6)
	setup.boxes[0].button_pressed = true
	assert_true(enemy1.active)


func test_open_pauses_until_start() -> void:
	var setup := _setup(true)
	assert_true(setup.is_open())
	assert_true(get_tree().paused)
	var started: Array[bool] = []
	setup.started.connect(func() -> void: started.append(true))
	setup.start()
	assert_false(setup.is_open())
	assert_false(get_tree().paused)
	assert_eq(started.size(), 1)


func test_enter_starts() -> void:
	var setup := _setup(true)
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.pressed = true
	setup._input(enter)
	assert_false(setup.is_open())
	assert_false(get_tree().paused)


func test_r_asks_to_go_back_only_during_the_run() -> void:
	var setup := _setup(true)
	var asked: Array[bool] = []
	setup.back_requested.connect(func() -> void: asked.append(true))
	var r := InputEventKey.new()
	r.physical_keycode = KEY_R
	r.pressed = true
	setup._input(r)
	assert_eq(asked.size(), 0, "ignored while the setup screen is open")
	setup.start()
	setup._input(r)
	assert_eq(asked.size(), 1, "R during the run")
	r.echo = true
	setup._input(r)
	assert_eq(asked.size(), 1, "holding R doesn't repeat")


func test_main_scene_reloads_on_back() -> void:
	var main := keep((load("res://scenes/main/main.tscn") as PackedScene).instantiate())
	var setup := main.get_node("SetupScreen") as SetupScreen
	assert_eq(setup.back_requested.get_connections().size(), 1)
	assert_eq(setup.back_requested.get_connections()[0].callable.get_object(), main)


func test_remembers_the_choice() -> void:
	var setup := _setup(true)
	setup.boxes[1].button_pressed = false
	setup.start()
	setup.queue_free()
	enemy2.active = true  # a fresh game: every type starts on
	var again := _setup(true)
	assert_true(again.boxes[0].button_pressed)
	assert_false(again.boxes[1].button_pressed, "enemy2 still unticked")
	assert_false(enemy2.active)


func test_main_scene_lists_every_type_and_does_not_pause_headless() -> void:
	var main := keep((load("res://scenes/main/main.tscn") as PackedScene).instantiate())
	var setup := main.get_node("SetupScreen") as SetupScreen
	var names: Array[String] = []
	for box in setup.boxes:
		names.append(box.text)
	assert_eq(names, ["enemy1", "enemy2", "enemy3"] as Array[String])
	assert_false(setup.is_open(), "skipped in headless runs")
	assert_false(get_tree().paused)


func test_a_flying_type_can_be_turned_off() -> void:
	var flyers := EnemySwarm.new()
	flyers.settings = EnemySettings.new()
	flyers.settings.display_name = "flyers"
	flyers.settings.flying = true
	flyers.settings.count = 5
	level.add_child(flyers)
	flyers.set_physics_process(false)
	var setup := _setup()
	flyers.step(1.0 / 60.0, level.surface_point(0.0, 0.0), Vector3.ZERO)
	assert_eq(flyers.positions.size(), 5)
	setup.boxes[2].button_pressed = false
	assert_eq(flyers.positions.size(), 0)
	flyers.step(1.0 / 60.0, level.surface_point(0.0, 0.0), Vector3.ZERO)
	assert_eq(flyers.positions.size(), 0, "stays empty while off")


# --- Attacks checkbox -----------------------------------------------------

## The runner's attacks, under a pretend runner in the level.
func _attacks() -> PlayerAttacks:
	var runner := Node3D.new()
	level.add_child(runner)
	var attacks := (load("res://scenes/player/attacks/player_attacks.tscn") as PackedScene).instantiate() as PlayerAttacks
	runner.add_child(attacks)
	return attacks


func _setup_with(attacks: PlayerAttacks, show := false) -> SetupScreen:
	var setup := (load("res://scenes/menu/setup_screen.tscn") as PackedScene).instantiate() as SetupScreen
	setup.level = level
	setup.attacks = attacks
	setup.save_path = SAVE
	setup.show_at_start = show
	setup.skip_when_headless = false
	keep(setup)
	return setup


func test_no_attacks_checkbox_without_attacks() -> void:
	var setup := _setup()
	assert_eq(setup.attacks_box, null)


func test_attacks_checkbox_turns_attacks_on_and_off() -> void:
	var attacks := _attacks()
	var setup := _setup_with(attacks)
	assert_true(setup.attacks_box.button_pressed, "ticked by default")
	assert_true(attacks.current().active)
	setup.attacks_box.button_pressed = false
	assert_false(attacks.enabled)
	for attack in attacks.attacks:
		assert_false(attack.active)
	assert_false((attacks.get_node("Hud/AttackName") as Label).visible, "label hidden")
	setup.attacks_box.button_pressed = true
	assert_true(attacks.enabled)
	assert_true(attacks.current().active)


func test_remembers_attacks_off() -> void:
	var attacks := _attacks()
	var setup := _setup_with(attacks, true)
	setup.attacks_box.button_pressed = false
	setup.start()
	setup.queue_free()
	attacks.enabled = true  # a fresh game
	var again := _setup_with(attacks, true)
	assert_false(again.attacks_box.button_pressed, "still unticked")
	assert_false(attacks.enabled)


func test_starts_with_the_attack_last_used() -> void:
	var attacks := _attacks()
	var setup := _setup_with(attacks, true)
	setup.start()
	attacks.select(4)  # swapped with the wheel during the run
	setup.free()
	attacks.select(0)  # a fresh game
	_setup_with(attacks, true)
	assert_eq(attacks.index, 4)


func test_main_scene_has_the_attacks_checkbox() -> void:
	var main := keep((load("res://scenes/main/main.tscn") as PackedScene).instantiate())
	var setup := main.get_node("SetupScreen") as SetupScreen
	assert_ne(setup.attacks_box, null)
	assert_eq(setup.attacks, main.get_node("EndlessLevel/Runner/Attacks"))
