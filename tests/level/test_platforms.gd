extends TestCase
## Floating platforms: the builder, where they go after ramps (same seed same
## platforms, reachable from the lip, never in the ground), no rocks under
## them, and the endless level keeping them until the runner is past.


func _shapes() -> Array[PlatformShape]:
	var plain := PlatformShape.new()
	var pipe := PlatformShape.new()
	pipe.width = 16.0
	pipe.trough_depth = 4.0
	var stones := PlatformShape.new()
	stones.length = 100.0
	stones.pieces = 6
	stones.piece_step = 3.0
	var shelf := PlatformShape.new()
	shelf.length = 140.0
	shelf.grade = 0.0
	shelf.extra_decks = 1
	return [plain, pipe, stones, shelf]


func _settings(terrain_seed := 5) -> TerrainSettings:
	var settings := TerrainSettings.new()
	settings.terrain_seed = terrain_seed
	settings.platforms = _shapes()
	return settings


## Chunk index -> platform, for the chunks 1..[param count] that have one.
func _placed(layout: PlatformLayout, count := 80) -> Dictionary:
	var result := {}
	for i in range(1, count + 1):
		var p := layout.platform_of(i)
		if not p.is_empty():
			result[i] = p
	return result


func test_builder_makes_mesh_and_collision() -> void:
	var node: Node3D = keep(PlatformBuilder.new(PlatformShape.new()).build())
	var mesh: MeshInstance3D = node.get_node("Mesh")
	assert_true(mesh.mesh.get_faces().size() > 300, "mesh triangles")
	var body: StaticBody3D = node.get_node("Body")
	var shape := (body.get_child(0) as CollisionShape3D).shape as ConcavePolygonShape3D
	assert_eq(shape.get_faces().size(), mesh.mesh.get_faces().size())
	# The top starts at y 0 and runs along -Z for its length.
	var box := mesh.get_aabb()
	assert_near(box.position.z, -PlatformShape.new().length, 0.01)
	assert_near(box.end.y, 0.0, 0.01)


func test_shallower_and_shorter() -> void:
	var shape := PlatformShape.new()
	shape.pieces = 4
	var builder := PlatformBuilder.new(shape)
	var deep := builder.hull_points()
	builder.depth_scale = 0.5
	var shallow := builder.hull_points()
	var lowest_deep := INF
	var lowest_shallow := INF
	for p in deep:
		lowest_deep = minf(lowest_deep, p.y)
	for p in shallow:
		lowest_shallow = minf(lowest_shallow, p.y)
	assert_true(lowest_shallow > lowest_deep + 2.0, "%s vs %s" % [lowest_shallow, lowest_deep])
	builder.length = shape.length * 0.5
	assert_between(builder.pieces().size(), 2, 3, "pieces left after cutting in half")
	for piece: Dictionary in builder.pieces():
		assert_true(piece.to <= builder.length + 0.001)


func test_same_seed_same_platforms() -> void:
	var a := _placed(PlatformLayout.new(TerrainHeight.new(_settings(5))))
	var b := _placed(PlatformLayout.new(TerrainHeight.new(_settings(5))))
	assert_eq(a.keys(), b.keys())
	for i: int in a:
		assert_eq(a[i].x, b[i].x)
		assert_eq(a[i].top, b[i].top)
		assert_eq(a[i].end, b[i].end)


func test_some_ramps_get_platforms() -> void:
	var terrain := TerrainHeight.new(_settings())
	var placed := _placed(PlatformLayout.new(terrain))
	var ramps := 0
	for i in range(1, 81):
		if not terrain.ramps_of(i).is_empty():
			ramps += 1
	assert_between(placed.size(), 8, ramps, "platforms after %d ramps" % ramps)


func test_none_without_shapes() -> void:
	var settings := TerrainSettings.new()
	assert_true(_placed(PlatformLayout.new(TerrainHeight.new(settings))).is_empty())


## Each platform starts platform_gap past its ramp's lip, the middle of its
## top platform_drop under the lip (so the kicker carries you onto it).
func test_starts_just_past_and_under_the_lip() -> void:
	var settings := _settings()
	var terrain := TerrainHeight.new(settings)
	for p: Dictionary in _placed(PlatformLayout.new(terrain)).values():
		var ramp: Vector2 = terrain.ramps_of(p.index)[0]
		var lip := ramp.x + settings.ramp_length
		assert_near(p.start, lip + settings.platform_gap, 0.001)
		var builder: PlatformBuilder = p.builder
		var front: float = p.top + builder.top_y(0.0, 0.0, p.shape.width * 0.5)
		assert_near(front, terrain.height_at(p.x, -lip) - settings.platform_drop, 0.001)


## Every vertex of every platform (sampled every 2 m, finer than placement's
## 4 m) is above the ground under it.
func test_never_in_the_ground() -> void:
	var settings := _settings()
	var terrain := TerrainHeight.new(settings)
	var checked := 0
	for p: Dictionary in _placed(PlatformLayout.new(terrain)).values():
		var node: Node3D = keep(p.builder.build())
		var mesh: MeshInstance3D = node.get_node("Mesh")
		var lowest_room := INF
		var vertices: PackedVector3Array = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for v in vertices:
			var world: Vector3 = Vector3(p.x, p.top, -p.start) + v
			if absf(world.x) > settings.width / 2.0:
				continue
			lowest_room = minf(lowest_room, world.y - terrain.height_at(world.x, world.z))
			checked += 1
		assert_true(lowest_room > 0.5, "chunk %d: %.2f m above the ground at the lowest" % [p.index, lowest_room])
	assert_true(checked > 1000, "%d vertices checked" % checked)


func test_no_rocks_under_platforms() -> void:
	var settings := _settings()
	settings.obstacles_per_chunk = 40
	var terrain := TerrainHeight.new(settings)
	var layout := PlatformLayout.new(terrain)
	var placed := _placed(layout, 20)
	assert_false(placed.is_empty(), "a platform in the first 20 chunks")
	for i: int in placed:
		for index in [i, i + 1]:
			var chunk: TerrainChunk = keep(TerrainChunk.new())
			chunk.build(index, terrain, Vector3.ZERO, layout)
			for child in chunk.get_children():
				if child is StaticBody3D and child.get_child_count() == 2:  # an obstacle
					var x: float = child.position.x
					var distance: float = index * settings.chunk_length - child.position.z
					assert_false(layout.covers(x, distance, 0.0), "rock at %.1f, %.1f" % [x, distance])


func test_level_keeps_platforms_until_passed() -> void:
	var level := EndlessLevel.new()
	level.settings = _settings()
	var mover := Node3D.new()
	level.add_child(mover)
	level.runner = mover
	keep(level)
	level.set_physics_process(false)
	var layout := level.platform_layout
	var placed := _placed(layout, 40)
	assert_false(placed.is_empty())
	var index: int = placed.keys()[0]
	var p: Dictionary = placed[index]
	# Runner on the platform, past its ramp's chunk and the one after.
	var on := minf(p.end - 5.0, maxf(p.start + 10.0, (index + 2) * level.settings.chunk_length + 5.0))
	mover.position = level.surface_point(0.0, on)
	level.update_chunks()
	assert_true(level.platforms.get(index) != null, "platform %d kept at %.0f m (ends %.0f)" % [index, on, p.end])
	var node: Node3D = level.platforms[index]
	assert_near(node.position, Vector3(p.x, p.top, -p.start), 0.001)
	# Origin shift moves it with the world.
	mover.position = level.surface_point(0.0, p.end + 2100.0)
	level.check_origin_shift()
	assert_near(node.position + level.origin, Vector3(p.x, p.top, -p.start), 0.01)
	level.update_chunks()
	assert_false(level.platforms.has(index), "freed once far behind")


## Two platforms never cross: along each one, every other platform at the
## same distance is clear of it sideways.
func test_platforms_never_overlap() -> void:
	var settings := _settings(9)
	var long_shape := PlatformShape.new()
	long_shape.length = 220.0
	long_shape.grade = 0.0
	long_shape.drift = 25.0
	settings.platforms.append(long_shape)
	var layout := PlatformLayout.new(TerrainHeight.new(settings))
	var placed := _placed(layout, 120).values()
	for a: Dictionary in placed:
		for b: Dictionary in placed:
			if a.index >= b.index:
				continue
			var d: float = b.start
			while d < minf(a.end, b.end):
				var ab: PlatformBuilder = a.builder
				var bb: PlatformBuilder = b.builder
				var gap: float = absf(a.x + ab.center_x(d - a.start) - b.x - bb.center_x(d - b.start))
				var halves := ab.half_width(d - a.start, 1.0) + bb.half_width(d - b.start, 1.0)
				assert_true(gap > halves, "chunks %d and %d cross at %.0f m" % [a.index, b.index, d])
				d += 2.0
