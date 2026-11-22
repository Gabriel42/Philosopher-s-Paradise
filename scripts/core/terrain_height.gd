class_name TerrainHeight
extends RefCounted
## The height of the endless ground at any point, from [TerrainSettings].
## Pure function of the world position (and the seed): chunks built apart
## still join exactly, and the same seed always gives the same level.
##
## Height = steady downhill + big hills + small bumps + ramps.
## Ramps: each chunk may hold one (chosen by its own seeded RNG): a kicker
## that rises, then a downhill landing dipping under the ground, then back.

var settings: TerrainSettings
var _hills := FastNoiseLite.new()
var _bumps := FastNoiseLite.new()
## Chunk index -> its ramps, as Vector2(start distance, height).
var _ramps: Dictionary[int, Array] = {}


func _init(terrain_settings: TerrainSettings) -> void:
	settings = terrain_settings
	if settings.ramp_total_length() > settings.chunk_length:
		push_warning("A ramp is longer than a chunk: ramps may cut off.")
	for noise: FastNoiseLite in [_hills, _bumps]:
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	_hills.seed = settings.terrain_seed
	_hills.frequency = 1.0 / settings.hill_wavelength
	_bumps.seed = settings.terrain_seed + 1
	_bumps.frequency = 1.0 / settings.bump_wavelength


## Ground height at world [param x], [param z] (no origin shift: real coordinates).
func height_at(x: float, z: float) -> float:
	var distance := -z
	var grow := clampf(distance / settings.start_smooth_distance, 0.0, 1.0)
	var h := -settings.downhill_grade * distance
	h += grow * _hills.get_noise_2d(x, z) * settings.hill_height
	h += grow * _bumps.get_noise_2d(x, z) * settings.bump_height
	h += ramp_offset(distance)
	return h


## How much the ramps raise (or lower) the ground at [param distance].
func ramp_offset(distance: float) -> float:
	var index := floori(distance / settings.chunk_length)
	var total := 0.0
	for i in [index - 1, index]:
		for ramp: Vector2 in ramps_of(i):
			total += _ramp_profile(distance - ramp.x, ramp.y)
	return total


## True if [param distance] is on a kicker or its landing (no obstacles there).
func is_on_ramp(distance: float) -> bool:
	var index := floori(distance / settings.chunk_length)
	for i in [index - 1, index]:
		for ramp: Vector2 in ramps_of(i):
			var s := distance - ramp.x
			if s > -8.0 and s < settings.ramp_length + settings.landing_length + 8.0:
				return true
	return false


## The ramps of chunk [param index] (none in the first chunks).
func ramps_of(index: int) -> Array:
	if index < 1:
		return []
	if _ramps.has(index):
		return _ramps[index]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([settings.terrain_seed, index, "ramps"])
	var result: Array = []
	if rng.randf() < settings.ramp_chance:
		var start := index * settings.chunk_length + rng.randf_range(
				0.0, maxf(0.0, settings.chunk_length - settings.ramp_total_length()))
		var height := rng.randf_range(settings.ramp_height_min, settings.ramp_height_max)
		result.append(Vector2(start, height))
	_ramps[index] = result
	return result


## Height added by one ramp of [param height], [param s] metres after its start.
func _ramp_profile(s: float, height: float) -> float:
	var rise := settings.ramp_length
	var land := settings.landing_length
	var back := settings.recovery_length
	if s <= 0.0 or s >= rise + land + back:
		return 0.0
	var depth := height * settings.landing_depth_ratio
	if s < rise:
		var t := s / rise
		return height * t * t
	if s < rise + land:
		return lerpf(height, -depth, smoothstep(0.0, 1.0, (s - rise) / land))
	return -depth * (1.0 - smoothstep(0.0, 1.0, (s - rise - land) / back))
