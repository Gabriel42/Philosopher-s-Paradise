class_name PlatformBuilder
extends RefCounted
## Builds a floating platform (mesh, collision, obstacles) from a
## [PlatformShape]. The platform starts at the node's origin, top at y = 0,
## and runs along -Z. Same shape (and seed) gives the same platform.

## Part of the hull's depth reached at the middle ring (rounds the underside).
const MID_DEPTH := 0.45
## How far in the middle ring sits, as a part of the half width.
const MID_INSET := 0.25

var shape: PlatformShape
var colors_from: TerrainSettings
## Scales how deep the underside hangs (placement lowers it where the
## ground below is close).
var depth_scale := 1.0
## Where the platform ends (placement cuts it short where it would hit the
## ground further on). The kicker, if any, moves to the new end.
var length := 0.0

var _vertices := PackedVector3Array()
var _normals := PackedVector3Array()
var _colors := PackedColorArray()
var _indices := PackedInt32Array()
var _phases := PackedFloat32Array()

static var _material: StandardMaterial3D
static var _obstacle_material: StandardMaterial3D


func _init(platform_shape: PlatformShape, terrain_settings: TerrainSettings = null) -> void:
	shape = platform_shape
	length = shape.length
	colors_from = terrain_settings if terrain_settings != null else TerrainSettings.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([shape.shape_seed, "platform"])
	for i in 8:
		_phases.append(rng.randf_range(0.0, TAU))


## Builds the whole platform as a new node (mesh + collision + obstacles).
func build() -> Node3D:
	var root := Node3D.new()
	root.name = "Platform"
	_vertices.clear()
	_normals.clear()
	_colors.clear()
	_indices.clear()
	for piece: Dictionary in pieces():
		_build_piece(piece)

	_make_materials()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var normals := PackedVector3Array()
	for n in _normals:
		normals.append(n.normalized())
	arrays[Mesh.ARRAY_VERTEX] = _vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = _colors
	arrays[Mesh.ARRAY_INDEX] = _indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _material)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	mesh_instance.mesh = mesh
	root.add_child(mesh_instance)

	var faces := PackedVector3Array()
	faces.resize(_indices.size())
	for i in _indices.size():
		faces[i] = _vertices[_indices[i]]
	var body := StaticBody3D.new()
	body.name = "Body"
	var collision_shape := ConcavePolygonShape3D.new()
	collision_shape.backface_collision = true
	collision_shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.shape = collision_shape
	body.add_child(collision)
	root.add_child(body)
	_build_obstacles(root)
	return root


## Sideways position of the centre line at [param distance].
func center_x(distance: float) -> float:
	var x := shape.drift * distance / maxf(shape.length, 1.0)
	if shape.curve_amount != 0.0:
		x += shape.curve_amount * sin(TAU * distance / maxf(shape.curve_wavelength, 1.0))
	return x


## Half width at [param distance] on one side ([param side] -1 = left, 1 = right).
func half_width(distance: float, side: float) -> float:
	var t := clampf(distance / maxf(shape.length, 1.0), 0.0, 1.0)
	var half := shape.width * 0.5 * lerpf(1.0, shape.end_width_ratio, t)
	if shape.edge_wobble > 0.0:
		var p := 0 if side < 0.0 else 4
		half += shape.edge_wobble * (0.6 * sin(distance / 7.0 + _phases[p]) + 0.4 * sin(distance / 3.1 + _phases[p + 1]))
	return maxf(half, 0.6)


## Height of the top at [param distance], [param across] from -1 (left edge)
## to 1 (right edge), before piece steps and decks.
func top_y(across: float, distance: float, half: float) -> float:
	var y := -shape.grade * distance
	if shape.wave_height != 0.0:
		y += shape.wave_height * sin(TAU * distance / maxf(shape.wave_length, 1.0))
	var tilt := shape.bank_degrees
	if shape.twist_degrees != 0.0:
		tilt += shape.twist_degrees * sin(TAU * distance / maxf(shape.length, 1.0))
	y -= tan(deg_to_rad(tilt)) * across * half
	if shape.trough_depth != 0.0:
		y -= shape.trough_depth * (1.0 - across * across)
	if shape.kicker_height > 0.0:
		var kicker_start := length - shape.kicker_length
		if distance > kicker_start:
			var t := (distance - kicker_start) / maxf(shape.kicker_length, 0.1)
			y += shape.kicker_height * t * t
	return y


## The parts of the platform, each a closed island: Dictionaries with
## from / to (distances), width_scale, lift (height added) and nose (true for
## the very front: a thin wedge, so its hull doesn't cut into the ground).
func pieces() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([shape.shape_seed, "pieces"])
	var count := maxi(shape.pieces, 1)
	var piece_length := (shape.length - (count - 1) * shape.gap_length) / count
	piece_length = maxf(piece_length, shape.cell_size)
	for i in count:
		var start := i * (piece_length + shape.gap_length)
		var lift := 0.0 if i == 0 else rng.randf_range(-1.0, 1.0) * shape.piece_step
		_add_cut(result, {from = start, to = start + piece_length, width_scale = 1.0, lift = lift, nose = i == 0})
	for k in shape.extra_decks:
		var deck := k + 1
		var shrink := 1.0 - 0.2 * deck
		var half := shape.length * 0.25 * shrink
		var middle := shape.length * 0.5
		_add_cut(result, {from = middle - half, to = middle + half, width_scale = 0.7 * shrink, lift = shape.deck_spacing * deck, nose = false})
	return result


## Adds [param piece] cut at [member length] (dropped if it starts past it,
## or if what's left is too short).
func _add_cut(result: Array[Dictionary], piece: Dictionary) -> void:
	piece.to = minf(piece.to, length)
	if piece.to - piece.from >= shape.cell_size:
		result.append(piece)


## Points of the underside (edges, middle rings, keel) every [param step]
## metres, in the platform's space: what must stay above the main ground.
func hull_points(step := 4.0) -> PackedVector3Array:
	var points := PackedVector3Array()
	for piece: Dictionary in pieces():
		var from: float = piece.from
		var to: float = piece.to
		var count := maxi(ceili((to - from) / step), 1)
		for r in count + 1:
			points.append_array(_ring(lerpf(from, to, float(r) / count), piece))
	return points


## How deep the hull hangs at [param distance] in [param piece]: deepest in
## the middle, rounded at the ends, a thin wedge at the nose.
func hull_depth(distance: float, piece: Dictionary) -> float:
	var s := maxf(shape.skirt_depth, 1.0)
	var to_end: float = piece.to - distance
	var from_start: float = distance - piece.from
	var factor := 0.35 + 0.65 * clampf(to_end / s, 0.0, 1.0)
	if piece.nose:
		factor = minf(factor, 0.05 + 0.95 * clampf(from_start / (2.0 * s), 0.0, 1.0))
	else:
		factor = minf(factor, 0.35 + 0.65 * clampf(from_start / s, 0.0, 1.0))
	return depth_scale * shape.skirt_depth * factor * (0.85 + 0.15 * sin(distance / 9.0 + _phases[2]))


## The cross-section of [param piece] at [param distance]: left edge, left
## middle ring, keel, right middle ring, right edge.
func _ring(distance: float, piece: Dictionary) -> PackedVector3Array:
	var width_scale: float = piece.width_scale
	var lift: float = piece.lift
	var cx := center_x(distance)
	var left := half_width(distance, -1.0) * width_scale
	var right := half_width(distance, 1.0) * width_scale
	var depth := hull_depth(distance, piece)
	var left_top := Vector3(cx - left, top_y(-1.0, distance, left) + lift, -distance)
	var right_top := Vector3(cx + right, top_y(1.0, distance, right) + lift, -distance)
	var top_center := top_y(0.0, distance, (left + right) * 0.5) + lift
	return PackedVector3Array([
		left_top,
		Vector3(cx - left * (1.0 - MID_INSET), left_top.y - depth * MID_DEPTH, -distance),
		Vector3(cx, top_center - depth, -distance),
		Vector3(cx + right * (1.0 - MID_INSET), right_top.y - depth * MID_DEPTH, -distance),
		right_top,
	])


## One closed island (see [method pieces]).
func _build_piece(piece: Dictionary) -> void:
	var from: float = piece.from
	var to: float = piece.to
	var width_scale: float = piece.width_scale
	var lift: float = piece.lift
	var cell := shape.cell_size
	var rows := maxi(ceili((to - from) / cell), 1) + 1
	var columns := maxi(ceili(shape.width * width_scale / cell), 2) + 1
	var top_first := _vertices.size()
	var edges_left: Array[Vector3] = []
	var edges_right: Array[Vector3] = []
	var mids_left: Array[Vector3] = []
	var mids_right: Array[Vector3] = []
	var keels: Array[Vector3] = []
	for r in rows:
		var d := lerpf(from, to, float(r) / (rows - 1))
		var cx := center_x(d)
		var left := half_width(d, -1.0) * width_scale
		var right := half_width(d, 1.0) * width_scale
		for c in columns:
			var across := lerpf(-1.0, 1.0, float(c) / (columns - 1))
			var half := left if across < 0.0 else right
			_add_vertex(Vector3(cx + across * half, top_y(across, d, half) + lift, -d), Color.WHITE)
		var ring := _ring(d, piece)
		edges_left.append(ring[0])
		mids_left.append(ring[1])
		keels.append(ring[2])
		mids_right.append(ring[3])
		edges_right.append(ring[4])

	for r in rows - 1:
		for c in columns - 1:
			var a := top_first + r * columns + c
			_add_triangle(a, a + columns, a + 1, Vector3.UP)
			_add_triangle(a + 1, a + columns, a + columns + 1, Vector3.UP)

	_build_hull_side(edges_left, mids_left, keels, -1.0)
	_build_hull_side(edges_right, mids_right, keels, 1.0)
	_build_cap(top_first, columns, mids_left[0], keels[0], mids_right[0], Vector3.BACK)
	_build_cap(top_first + (rows - 1) * columns, columns, mids_left[rows - 1], keels[rows - 1], mids_right[rows - 1], Vector3.FORWARD)

	# Colour the top by steepness, now that its normals are known.
	for i in range(top_first, top_first + rows * columns):
		var n := _normals[i].normalized()
		_colors[i] = colors_from.grass_color.lerp(colors_from.steep_color, clampf((1.0 - n.y) * 4.0, 0.0, 1.0))


## The side of the hull: top edge, middle ring, keel.
func _build_hull_side(edges: Array[Vector3], mids: Array[Vector3], keels: Array[Vector3], side: float) -> void:
	var rock := colors_from.rock_color
	var first := _vertices.size()
	for r in edges.size():
		_add_vertex(edges[r], rock)
		_add_vertex(mids[r], rock.darkened(0.25))
		_add_vertex(keels[r], rock.darkened(0.5))
	var hint := Vector3(side, -0.3, 0.0)
	for r in edges.size() - 1:
		var a := first + r * 3
		var b := a + 3
		_add_triangle(a, b, a + 1, hint)
		_add_triangle(a + 1, b, b + 1, hint)
		_add_triangle(a + 1, b + 1, a + 2, hint)
		_add_triangle(a + 2, b + 1, b + 2, hint)


## Closes one end of a piece: a fan from its top edge row down to the hull.
func _build_cap(row_first: int, columns: int, mid_left: Vector3, keel: Vector3, mid_right: Vector3, outward: Vector3) -> void:
	var rock := colors_from.rock_color
	var first := _vertices.size()
	for c in columns:
		_add_vertex(_vertices[row_first + c], rock)
	var ml := _add_vertex(mid_left, rock.darkened(0.25))
	var k := _add_vertex(keel, rock.darkened(0.5))
	var mr := _add_vertex(mid_right, rock.darkened(0.25))
	var middle := columns / 2
	for c in columns - 1:
		var bottom := ml if c < middle else mr
		_add_triangle(first + c, first + c + 1, bottom, outward)
	_add_triangle(first + middle, ml, k, outward)
	_add_triangle(first + middle, k, mr, outward)


func _add_vertex(position: Vector3, color: Color) -> int:
	_vertices.append(position)
	_normals.append(Vector3.ZERO)
	_colors.append(color)
	return _vertices.size() - 1


## Adds a triangle facing [param hint] (Godot's front faces wind clockwise)
## and adds its normal to its three vertices.
func _add_triangle(a: int, b: int, c: int, hint: Vector3) -> void:
	var va := _vertices[a]
	var normal := (_vertices[c] - va).cross(_vertices[b] - va)
	if normal.length_squared() < 0.000001:
		return
	if normal.dot(hint) < 0.0:
		var swap := b
		b = c
		c = swap
		normal = -normal
	_indices.append_array([a, b, c])
	for i: int in [a, b, c]:
		_normals[i] += normal


## Rocks and pillars on top (never on the kicker).
func _build_obstacles(root: Node3D) -> void:
	if shape.obstacles <= 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([shape.shape_seed, "obstacles"])
	for i in shape.obstacles:
		var d := rng.randf_range(length * 0.1, length - maxf(shape.kicker_length, 6.0))
		var across := rng.randf_range(-0.7, 0.7)
		var is_pillar := rng.randf() < 0.5
		var half := half_width(d, signf(across))
		var x := center_x(d) + across * half
		var ground := top_y(across, d, half)
		var body := StaticBody3D.new()
		var mesh_node := MeshInstance3D.new()
		var collision := CollisionShape3D.new()
		if is_pillar:
			var radius := rng.randf_range(0.6, 1.2)
			var tall := rng.randf_range(4.0, 10.0)
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = radius
			cylinder.bottom_radius = radius
			cylinder.height = tall
			mesh_node.mesh = cylinder
			var cylinder_shape := CylinderShape3D.new()
			cylinder_shape.radius = radius
			cylinder_shape.height = tall
			collision.shape = cylinder_shape
			body.position = Vector3(x, ground + tall / 2.0 - 0.8, -d)
		else:
			var size := Vector3(rng.randf_range(1.5, 3.5), rng.randf_range(1.5, 3.0), rng.randf_range(1.5, 3.5))
			var box := BoxMesh.new()
			box.size = size
			mesh_node.mesh = box
			var box_shape := BoxShape3D.new()
			box_shape.size = size
			collision.shape = box_shape
			body.position = Vector3(x, ground + size.y / 2.0 - 0.6, -d)
			body.rotation.y = rng.randf_range(0.0, TAU)
		mesh_node.material_override = _obstacle_material
		body.add_child(mesh_node)
		body.add_child(collision)
		root.add_child(body)


func _make_materials() -> void:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
		_material.roughness = 1.0
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if _obstacle_material == null:
		_obstacle_material = StandardMaterial3D.new()
		_obstacle_material.albedo_color = colors_from.obstacle_color
		_obstacle_material.roughness = 0.9
