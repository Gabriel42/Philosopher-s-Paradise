extends TestCase
## F3 debug panel: one line per enemy type (count and touches), and the main
## scene shows both enemy1 and enemy3.


func test_shows_every_enemy_type() -> void:
	var level := EndlessLevel.new()
	level.settings = TerrainSettings.new()
	keep(level)
	level.set_physics_process(false)
	var types: Array[EnemySwarm] = []
	for kind in ["walker", "flyer"]:
		var swarm := EnemySwarm.new()
		swarm.settings = EnemySettings.new()
		swarm.settings.display_name = kind
		swarm.settings.flying = kind == "flyer"
		swarm.settings.count = 3 if kind == "flyer" else 5
		level.add_child(swarm)
		swarm.set_physics_process(false)
		swarm.step(0.0, level.surface_point(0.0, 0.0), Vector3.ZERO)
		types.append(swarm)
	types[1].touches = 2
	var menu := keep(load("res://scenes/debug/debug_menu.tscn").instantiate()) as DebugMenu
	menu.swarms = types
	var text := menu.panel_text()
	assert_true(text.contains("walker: 5 out, 0 touches"), text)
	assert_true(text.contains("flyer: 3 out, 2 touches"), text)
	assert_true(text.contains("FPS"), text)


func test_main_scene_has_enemy1_and_enemy3() -> void:
	var main := keep(load("res://scenes/main/main.tscn").instantiate())
	await get_tree().process_frame
	var menu := main.get_node("DebugMenu") as DebugMenu
	var names: Array[String] = []
	for swarm in menu.swarms:
		names.append(swarm.settings.display_name)
	assert_eq(names, ["enemy1", "enemy3"] as Array[String])
	var enemy3 := main.get_node("EndlessLevel/Enemy3") as EnemySwarm
	assert_true(enemy3.settings.flying)
	assert_eq(enemy3.settings.count, 20)
	assert_true(enemy3.settings.color.b > 0.8 and enemy3.settings.color.r < 0.3, "blue")
