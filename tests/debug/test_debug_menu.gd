extends TestCase
## The F3 debug panel in the main scene: open at start, shows both enemy
## types and enemy2's shots.


func test_open_at_start_with_both_enemy_types() -> void:
	var main := keep((load("res://scenes/main/main.tscn") as PackedScene).instantiate())
	var menu := main.get_node("DebugMenu") as DebugMenu
	assert_eq(menu.swarms.size(), 2)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true((menu.get_node("Panel") as Control).visible, "panel open at start")
	var text := (menu.get_node("Panel/Label") as Label).text
	assert_true(text.contains("enemy1: 40 out"), text)
	assert_true(text.contains("enemy2: 6 out"), text)
	assert_true(text.contains("Enemy2 shots: 0 fired / 0 hit"), text)


func test_f3_closes_it() -> void:
	var menu := keep((load("res://scenes/debug/debug_menu.tscn") as PackedScene).instantiate()) as DebugMenu
	var press := InputEventAction.new()
	press.action = "toggle_debug"
	press.pressed = true
	menu._unhandled_input(press)
	assert_false((menu.get_node("Panel") as Control).visible)
