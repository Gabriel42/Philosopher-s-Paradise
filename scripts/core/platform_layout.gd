class_name PlatformLayout
extends RefCounted
## Where the floating platforms go: at most one per chunk, right after that
## chunk's ramp, so the kicker launches the runner onto it. Its top starts a
## little below the ramp's lip and its whole underside stays above the
## ground. Pure function of the seed (like [TerrainHeight]): chunks built
## apart agree, the same seed gives the same platforms.

var terrain: TerrainHeight
## Chunk index -> its platform (empty Dictionary = none).
var _cache: Dictionary[int, Dictionary] = {}


func _init(terrain_height: TerrainHeight) -> void:
	terrain = terrain_height


## The platform that follows chunk [param index]'s ramp, or an empty
## Dictionary. Keys: shape ([PlatformShape]), builder ([PlatformBuilder]),
## x (centre at its start), start / end (distances), top (real height of
## the top at its start), index.
func platform_of(index: int) -> Dictionary:
	if _cache.has(index):
		return _cache[index]
	var result := _place(index)
	_cache[index] = result
	return result


## True if the point [param x], [param distance] (real coordinates) is
## under or on a platform, with [param margin] metres around it.
func covers(x: float, distance: float, margin := 3.0) -> bool:
	var index := floori(distance / terrain.settings.chunk_length)
	# A platform can reach a few chunks past its ramp's chunk.
	for i in range(index - 3, index + 1):
		var p := platform_of(i)
		if p.is_empty() or distance < p.start - margin or distance > p.end + margin:
			continue
		var builder: PlatformBuilder = p.builder
		var along := clampf(distance - p.start, 0.0, p.builder.length)
		var offset: float = x - p.x - builder.center_x(along)
		var half := builder.half_width(along, signf(offset))
		if absf(offset) < half + margin:
			return true
	return false


func _place(index: int) -> Dictionary:
	var s := terrain.settings
	if s.platforms.is_empty():
		return {}
	var ramps := terrain.ramps_of(index)
	if ramps.is_empty():
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([s.terrain_seed, index, "platform"])
	if rng.randf() >= s.platform_chance:
		return {}
	var ramp: Vector2 = ramps[0]
	var lip := ramp.x + s.ramp_length
	var start := lip + s.platform_gap
	for attempt in s.platform_tries:
		var shape: PlatformShape = s.platforms[rng.randi() % s.platforms.size()]
		if shape == null:
			continue
		var builder := PlatformBuilder.new(shape, s)
		var x := rng.randf_range(_x_min(shape), _x_max(shape))
		# The middle of its front lines up with the lip (a half-pipe's
		# edges stand above it).
		var top := terrain.height_at(x, -lip) - s.platform_drop - builder.top_y(0.0, 0.0, shape.width * 0.5)
		# Cut it short where it would hit the ground, keeping at least half.
		for cut in 3:
			var fit := _fit(builder, x, start, top)
			if fit.fail < 0.0:
				if _overlaps_earlier(builder, x, start, index):
					break
				builder.depth_scale = fit.depth
				return {shape = shape, builder = builder, x = x, start = start,
						end = start + builder.length, top = top, index = index}
			var shorter: float = fit.fail - 6.0
			if shorter < shape.length * 0.5 or shorter < 30.0:
				break
			builder.length = shorter
	return {}


## True if the platform would cross (or come within a few metres of) the
## platform of one of the chunks before [param index].
func _overlaps_earlier(builder: PlatformBuilder, x: float, start: float, index: int) -> bool:
	const MARGIN := 4.0
	for i in range(index - 3, index):
		var other := platform_of(i)
		if other.is_empty() or other.end + MARGIN < start or other.start - MARGIN > start + builder.length:
			continue
		var other_builder: PlatformBuilder = other.builder
		var along := 0.0
		while along <= builder.length:
			var distance := start + along
			var other_along: float = distance - other.start
			if other_along > -MARGIN and other_along < other_builder.length + MARGIN:
				other_along = clampf(other_along, 0.0, other_builder.length)
				var gap: float = absf(x + builder.center_x(along) - other.x - other_builder.center_x(other_along))
				var halves := maxf(builder.half_width(along, -1.0), builder.half_width(along, 1.0))
				halves += maxf(other_builder.half_width(other_along, -1.0), other_builder.half_width(other_along, 1.0))
				if gap < halves + MARGIN:
					return true
			along += 4.0
	return false


## How the platform fits with its top starting at [param top]: depth (the
## deepest underside, as a part of the shape's, at most 1, that stays
## [member TerrainSettings.platform_clearance] above the ground; never less
## than [member TerrainSettings.platform_min_depth]) and fail (the first
## distance along it where even that doesn't fit, -1 if none).
func _fit(builder: PlatformBuilder, x: float, start: float, top: float) -> Dictionary:
	var s := terrain.settings
	builder.depth_scale = 0.0
	var tops := builder.hull_points()
	builder.depth_scale = 1.0
	var bottoms := builder.hull_points()
	var depth := 1.0
	var fail := INF
	for i in tops.size():
		var wx := x + tops[i].x
		if absf(wx) > s.width / 2.0:
			continue  # over the void: nothing to hit
		var ground := terrain.height_at(wx, -start + tops[i].z)
		var room := top + tops[i].y - ground - s.platform_clearance
		var hang := tops[i].y - bottoms[i].y
		if room < hang * s.platform_min_depth:
			fail = minf(fail, -tops[i].z)
		elif hang > 0.01:
			depth = minf(depth, room / hang)
	return {depth = depth, fail = -1.0 if fail == INF else fail}


## The centre's range at the start, so the platform stays over the ground.
func _x_min(shape: PlatformShape) -> float:
	return clampf(-_room(shape) - minf(shape.drift, 0.0), -_room(shape), 0.0)


func _x_max(shape: PlatformShape) -> float:
	return clampf(_room(shape) - maxf(shape.drift, 0.0), 0.0, _room(shape))


func _room(shape: PlatformShape) -> float:
	var widest := shape.width * 0.5 * maxf(1.0, shape.end_width_ratio) + shape.edge_wobble
	return maxf(terrain.settings.width / 2.0 - widest - absf(shape.curve_amount) - 2.0, 0.0)
