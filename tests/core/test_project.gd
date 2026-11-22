extends TestCase
## The project itself: the main scene loads and runs.


func test_main_scene_loads() -> void:
	var path: String = ProjectSettings.get_setting("application/run/main_scene")
	var scene := load(path) as PackedScene
	assert_true(scene != null, "main scene %s" % path)
	var main := keep(scene.instantiate())
	await get_tree().process_frame
	assert_true(main.is_inside_tree())
