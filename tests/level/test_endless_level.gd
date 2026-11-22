extends TestCase
## The endless level: chunks around the runner, joins, origin shift, falling.

var level: EndlessLevel
var mover: Node3D


func before_each() -> void:
	level = EndlessLevel.new()
	level.settings = TerrainSettings.new()
	mover = Node3D.new()
	level.add_child(mover)
	level.runner = mover
	keep(level)
	level.set_physics_process(false)  # the test moves things itself


func _indices() -> Array[int]:
	var result: Array[int] = level.chunks.keys()
	result.sort()
	return result


func test_starts_with_chunks_around_the_start() -> void:
	assert_eq(_indices(), [-1, 0, 1, 2, 3] as Array[int])
	assert_near(level.runner_distance(), 5.0, 0.01)


func test_builds_ahead_and_frees_behind() -> void:
	mover.position = level.surface_point(0.0, 500.0)  # chunk 4
	level.update_chunks()
	assert_eq(_indices(), [3, 4, 5, 6, 7] as Array[int])


func test_chunks_join_exactly() -> void:
	var first := level.chunks[1]
	var second := level.chunks[2]
	for ix in first.columns:
		assert_near(first.grid_vertex(ix, first.rows - 1), second.grid_vertex(ix, 0), 0.001, "column %d" % ix)


func test_origin_shift_keeps_the_runner_on_the_same_ground() -> void:
	mover.position = level.surface_point(0.0, 2500.0) + Vector3.UP
	level.update_chunks()
	level.check_origin_shift()
	assert_true(mover.position.length() < 1.5, "runner back near the centre: %s" % mover.position)
	assert_near(level.runner_distance(), 2500.0, 0.01)
	assert_near(level.surface_point(0.0, 2500.0) + Vector3.UP, mover.position, 0.01)
	# Chunks built before and after the shift still join.
	level.update_chunks()
	mover.position = level.surface_point(0.0, 2700.0)
	level.update_chunks()
	var index := floori(2600.0 / level.settings.chunk_length)
	var a := level.chunks[index]
	var b := level.chunks[index + 1]
	assert_near(a.grid_vertex(10, a.rows - 1), b.grid_vertex(10, 0), 0.01)


func test_falling_off_respawns_ahead_on_the_ground() -> void:
	mover.position = level.surface_point(30.0, 300.0) + Vector3.DOWN * 200.0
	level.check_fall()
	assert_near(level.runner_distance(), 320.0, 0.01)
	assert_near(mover.position, level.surface_point(0.0, 320.0) + Vector3.UP * 2.0, 0.01)
