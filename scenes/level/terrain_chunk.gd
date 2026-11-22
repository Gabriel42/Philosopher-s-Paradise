class_name TerrainChunk
extends Node3D
## One chunk of the endless ground: its mesh, its collision and its obstacles.
## Built by [EndlessLevel]; chunk [member index] covers the distances
## index * chunk_length .. (index + 1) * chunk_length.

## Which chunk this is (0 = the start).
var index := 0
## Vertices along X and along the chunk (grid size + 1).
var columns := 0
var rows := 0
var mesh_instance: MeshInstance3D

static var _ground_material: StandardMaterial3D
static var _obstacle_material: StandardMaterial3D


## Builds the chunk [param chunk_index] from [param terrain], placed for the
## world [param origin] (see [member EndlessLevel.origin]).
func build(chunk_index: int, terrain: TerrainHeight, origin: Vector3) -> void:
	index = chunk_index
	name = "Chunk%d" % index
	var s := terrain.settings
	position = Vector3(0.0, 0.0, -index * s.chunk_length) - origin
	_make_materials(s)
	var faces := _build_ground(terrain)
	var body := StaticBody3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	_build_obstacles(terrain)


## Position (in the level's space) of the ground grid's vertex [param ix], [param iz].
func grid_vertex(ix: int, iz: int) -> Vector3:
	var arrays := mesh_instance.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	return position + vertices[iz * columns + ix]


## Builds the ground mesh (top grid + the hanging sides) and returns its
## triangles for the collision.
func _build_ground(terrain: TerrainHeight) -> PackedVector3Array:
	var s := terrain.settings
	var cell := s.cell_size
	var nx := roundi(s.width / cell)
	var nz := roundi(s.chunk_length / cell)
	columns = nx + 1
	rows = nz + 1
	var start_distance := index * s.chunk_length
	# Heights with one extra cell all around, for normals that match the
	# neighbour chunks exactly.
	var stride := nx + 3
	var heights := PackedFloat32Array()
	heights.resize(stride * (nz + 3))
	for iz in range(-1, nz + 2):
		for ix in range(-1, nx + 2):
			var x := -s.width / 2.0 + ix * cell
			var z := -(start_distance + iz * cell)
			heights[(iz + 1) * stride + ix + 1] = terrain.height_at(x, z)

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for iz in range(0, nz + 1):
		for ix in range(0, nx + 1):
			var h := heights[(iz + 1) * stride + ix + 1]
			var dh_dx := (heights[(iz + 1) * stride + ix + 2] - heights[(iz + 1) * stride + ix]) / (2.0 * cell)
			# z goes down as iz goes up.
			var dh_dz := (heights[(iz + 2) * stride + ix + 1] - heights[iz * stride + ix + 1]) / (-2.0 * cell)
			var normal := Vector3(-dh_dx, 1.0, -dh_dz).normalized()
			vertices.append(Vector3(-s.width / 2.0 + ix * cell, h, -iz * cell))
			normals.append(normal)
			colors.append(s.grass_color.lerp(s.steep_color, clampf((1.0 - normal.y) * 4.0, 0.0, 1.0)))
	for iz in nz:
		for ix in nx:
			var a := iz * columns + ix
			var b := a + 1
			var c := a + columns
			var d := c + 1
			indices.append_array([a, c, b, b, c, d])

	# The sides hang down like a floating island.
	for side: int in [0, nx]:
		var outward := Vector3(-1.0 if side == 0 else 1.0, 0.0, 0.0)
		var first := vertices.size()
		for iz in range(0, nz + 1):
			var top := vertices[iz * columns + side]
			vertices.append(top)
			vertices.append(top + Vector3.DOWN * s.skirt_depth)
			normals.append(outward)
			normals.append(outward)
			colors.append(s.rock_color)
			colors.append(s.rock_color.darkened(0.4))
		for iz in nz:
			var a := first + iz * 2
			indices.append_array([a, a + 1, a + 2, a + 2, a + 1, a + 3])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _ground_material)
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Ground"
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

	var faces := PackedVector3Array()
	faces.resize(indices.size())
	for i in indices.size():
		faces[i] = vertices[indices[i]]
	return faces


## Scatters rocks and pillars (never on a ramp or at the very start).
func _build_obstacles(terrain: TerrainHeight) -> void:
	var s := terrain.settings
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([s.terrain_seed, index, "obstacles"])
	for i in s.obstacles_per_chunk:
		var x := rng.randf_range(-s.width * 0.42, s.width * 0.42)
		var along := rng.randf_range(0.0, s.chunk_length)
		var is_pillar := rng.randf() < 0.5
		var size := Vector3(rng.randf_range(2.0, 5.0), rng.randf_range(2.0, 4.0), rng.randf_range(2.0, 5.0))
		var radius := rng.randf_range(0.8, 1.6)
		var tall := rng.randf_range(6.0, 16.0)
		var turn := rng.randf_range(0.0, TAU)
		var distance := index * s.chunk_length + along
		if distance < s.start_smooth_distance or terrain.is_on_ramp(distance):
			continue
		var ground := terrain.height_at(x, -distance)
		var body := StaticBody3D.new()
		var mesh_node := MeshInstance3D.new()
		var collision := CollisionShape3D.new()
		if is_pillar:
			var mesh := CylinderMesh.new()
			mesh.top_radius = radius
			mesh.bottom_radius = radius
			mesh.height = tall
			mesh_node.mesh = mesh
			var shape := CylinderShape3D.new()
			shape.radius = radius
			shape.height = tall
			collision.shape = shape
			body.position = Vector3(x, ground + tall / 2.0 - 1.0, -along)
		else:
			var mesh := BoxMesh.new()
			mesh.size = size
			mesh_node.mesh = mesh
			var shape := BoxShape3D.new()
			shape.size = size
			collision.shape = shape
			body.position = Vector3(x, ground + size.y / 2.0 - 0.8, -along)
			body.rotation = Vector3(0.0, turn, 0.0)
		mesh_node.material_override = _obstacle_material
		body.add_child(mesh_node)
		body.add_child(collision)
		add_child(body)


static func _make_materials(s: TerrainSettings) -> void:
	if _ground_material == null:
		_ground_material = StandardMaterial3D.new()
		_ground_material.vertex_color_use_as_albedo = true
		_ground_material.vertex_color_is_srgb = true
		_ground_material.roughness = 1.0
		_ground_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if _obstacle_material == null:
		_obstacle_material = StandardMaterial3D.new()
		_obstacle_material.albedo_color = s.obstacle_color
		_obstacle_material.roughness = 0.9
