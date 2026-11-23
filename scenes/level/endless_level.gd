class_name EndlessLevel
extends Node3D
## The endless level: keeps a few [TerrainChunk]s around the runner, building
## them ahead and freeing them behind, so the ground never ends.
## Far from (0, 0, 0) 3D numbers lose precision, so every
## [member TerrainSettings.origin_shift_distance] the whole world (chunks and
## runner) shifts back to the centre; [member origin] remembers by how much.
## Falling off the ground respawns the runner ahead.

## Sent after the world shifted back by [param delta] (follow cameras, effects).
signal origin_shifted(delta: Vector3)
## Sent when the runner fell and was put back on the ground.
signal runner_respawned

@export var settings: TerrainSettings
## The node that moves forward (a [Runner]; any Node3D works).
@export var runner: Node3D

var terrain: TerrainHeight
## Real world position of this node's (0, 0, 0): add it to a position in the
## level to get its real coordinates.
var origin := Vector3.ZERO
## Chunk index -> chunk.
var chunks: Dictionary[int, TerrainChunk] = {}
## Where the floating platforms go.
var platform_layout: PlatformLayout
## Chunk index -> the platform after its ramp (null when it has none). A
## platform stays until the runner is past its end, even when its chunk is gone.
var platforms: Dictionary[int, Node3D] = {}


func _ready() -> void:
	if settings == null:
		settings = TerrainSettings.new()
	terrain = TerrainHeight.new(settings)
	platform_layout = PlatformLayout.new(terrain)
	if runner != null:
		runner.global_position = surface_point(0.0, 5.0) + Vector3.UP * 1.0
		update_chunks()


func _physics_process(_delta: float) -> void:
	if runner == null:
		return
	update_chunks()
	check_fall()
	check_origin_shift()


## How far forward the runner is, in real metres from the start.
func runner_distance() -> float:
	return -(runner.global_position.z + origin.z)


## The ground's point (in the level's space) at [param x] and [param distance] forward.
func surface_point(x: float, distance: float) -> Vector3:
	return Vector3(x, terrain.height_at(x, -distance), -distance) - origin


## Builds the missing chunks around the runner and frees the far ones.
func update_chunks() -> void:
	var current := floori(runner_distance() / settings.chunk_length)
	var first := current - settings.chunks_behind
	var last := current + settings.chunks_ahead
	for index: int in chunks.keys():
		if index < first or index > last:
			chunks[index].queue_free()
			chunks.erase(index)
	for index in range(first, last + 1):
		if not chunks.has(index):
			var chunk := TerrainChunk.new()
			chunk.build(index, terrain, origin, platform_layout)
			add_child(chunk)
			chunks[index] = chunk
	update_platforms(first, last)


## Builds the platforms of the chunks [param first]..[param last] and frees
## those the runner is past.
func update_platforms(first: int, last: int) -> void:
	var distance := runner_distance()
	for index: int in platforms.keys():
		var p := platform_layout.platform_of(index)
		var passed: bool = index < first and (p.is_empty() or p.end < distance - settings.chunk_length)
		if index > last or passed:
			if platforms[index] != null:
				platforms[index].queue_free()
			platforms.erase(index)
	for index in range(first, last + 1):
		if platforms.has(index):
			continue
		var p := platform_layout.platform_of(index)
		if p.is_empty():
			platforms[index] = null
			continue
		var builder: PlatformBuilder = p.builder
		var node := builder.build()
		node.name = "Platform%d" % index
		node.position = Vector3(p.x, p.top, -p.start) - origin
		add_child(node)
		platforms[index] = node


## Puts the runner back on the ground ahead if it fell too far below it.
func check_fall() -> void:
	var p := runner.global_position
	var ground := terrain.height_at(p.x + origin.x, p.z + origin.z) - origin.y
	if p.y > ground - settings.fall_depth:
		return
	var spot := surface_point(0.0, runner_distance() + 20.0) + Vector3.UP * 2.0
	if runner.has_method("respawn"):
		runner.respawn(spot)
	else:
		runner.global_position = spot
	runner_respawned.emit()


## Shifts the world back to the centre when the runner is far from it.
func check_origin_shift() -> void:
	var p := runner.global_position
	if absf(p.z) < settings.origin_shift_distance and absf(p.y) < settings.origin_shift_distance:
		return
	var delta := Vector3(0.0, p.y, p.z)
	origin += delta
	for chunk: TerrainChunk in chunks.values():
		chunk.position -= delta
	for platform: Node3D in platforms.values():
		if platform != null:
			platform.position -= delta
	runner.global_position -= delta
	origin_shifted.emit(delta)
