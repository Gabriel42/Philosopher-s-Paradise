extends TestCase
## The endless ground's height: same seed same ground, no jumps, downhill.


func _terrain(terrain_seed: int) -> TerrainHeight:
	var settings := TerrainSettings.new()
	settings.terrain_seed = terrain_seed
	return TerrainHeight.new(settings)


func test_same_seed_gives_same_heights() -> void:
	var a := _terrain(7)
	var b := _terrain(7)
	for i in 50:
		var x := -40.0 + i * 1.7
		var z := -i * 37.3
		assert_eq(a.height_at(x, z), b.height_at(x, z), "at %s, %s" % [x, z])


func test_other_seed_gives_other_heights() -> void:
	var a := _terrain(7)
	var b := _terrain(8)
	var differences := 0
	for i in 20:
		if not is_equal_approx(a.height_at(0.0, -100.0 - i * 50.0), b.height_at(0.0, -100.0 - i * 50.0)):
			differences += 1
	assert_true(differences > 15, "%d of 20 points differ" % differences)


## No cliffs: between two points 0.5 m apart the ground never rises or falls
## more than 1 m (slope 2), ramps and chunk borders included.
func test_ground_has_no_jumps() -> void:
	var terrain := _terrain(3)
	for x: float in [0.0, 30.0, -38.0]:
		var previous := terrain.height_at(x, 0.0)
		var d := 0.5
		while d < 3000.0:
			var h := terrain.height_at(x, -d)
			if absf(h - previous) > 1.0:
				fail("jump of %.2f m at x %s, distance %s" % [h - previous, x, d])
				return
			previous = h
			d += 0.5


func test_goes_downhill_overall() -> void:
	var terrain := _terrain(3)
	assert_true(terrain.height_at(0.0, -2000.0) < terrain.height_at(0.0, 0.0) - 150.0)


func test_some_chunks_have_ramps() -> void:
	var terrain := _terrain(3)
	var with_ramp := 0
	for i in range(1, 41):
		if not terrain.ramps_of(i).is_empty():
			with_ramp += 1
	assert_between(with_ramp, 10, 38, "chunks with a ramp out of 40")
