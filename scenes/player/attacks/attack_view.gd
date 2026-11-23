class_name AttackView
extends Node3D
## Draws an attack cheaply: every frame the attack lists spheres, segments
## (stretched boxes: beams, chains) and flat rings between [method begin] and
## [method commit], and three MultiMeshes draw them all (one colour, each
## shape with its own transparency). Placeholder look, glowing and unshaded.

## Floats per instance: a 3×4 transform, then the colour.
const _STRIDE := 16

var color := Color.WHITE

var _spheres: MultiMesh
var _segments: MultiMesh
var _rings: MultiMesh
var _sphere_data := PackedFloat32Array()
var _segment_data := PackedFloat32Array()
var _ring_data := PackedFloat32Array()


func _init(tint: Color) -> void:
	color = tint
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 12
	sphere.rings = 6
	_spheres = _add_multimesh("Spheres", sphere)
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	_segments = _add_multimesh("Segments", box)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.88
	torus.outer_radius = 1.0
	torus.rings = 48
	torus.ring_segments = 6
	_rings = _add_multimesh("Rings", torus)


func _add_multimesh(node_name: String, mesh: Mesh) -> MultiMesh:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color.WHITE
	mesh.surface_set_material(0, material)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	var view := MultiMeshInstance3D.new()
	view.name = node_name
	view.multimesh = multimesh
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Instances can be anywhere in the level: never cull the whole set.
	view.custom_aabb = AABB(Vector3.ONE * -100000.0, Vector3.ONE * 200000.0)
	add_child(view)
	return multimesh


## Starts a new frame: forgets what was drawn.
func begin() -> void:
	_sphere_data.clear()
	_segment_data.clear()
	_ring_data.clear()


## A ball of [param radius] at [param pos].
func sphere(pos: Vector3, radius: float, alpha := 1.0) -> void:
	_put(_sphere_data, Basis.from_scale(Vector3.ONE * radius), pos, alpha)


## A bar [param width] thick from [param a] to [param b].
func segment(a: Vector3, b: Vector3, width: float, alpha := 1.0) -> void:
	var along := b - a
	var length := along.length()
	if length < 0.001:
		return
	var y := along / length
	var side := Vector3.UP if absf(y.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var x := y.cross(side).normalized()
	var z := x.cross(y)
	_put(_segment_data, Basis(x * width, y * length, z * width), (a + b) * 0.5, alpha)


## A flat ring of [param radius] around [param center] (lying on X/Z).
func ring(center: Vector3, radius: float, alpha := 1.0) -> void:
	_put(_ring_data, Basis.from_scale(Vector3(radius, 2.0, radius)), center, alpha)


## Sends this frame's shapes to the MultiMeshes.
func commit() -> void:
	_send(_spheres, _sphere_data)
	_send(_segments, _segment_data)
	_send(_rings, _ring_data)


func _put(data: PackedFloat32Array, basis: Basis, origin: Vector3, alpha: float) -> void:
	data.append_array(PackedFloat32Array([
		basis.x.x, basis.y.x, basis.z.x, origin.x,
		basis.x.y, basis.y.y, basis.z.y, origin.y,
		basis.x.z, basis.y.z, basis.z.z, origin.z,
		color.r, color.g, color.b, color.a * clampf(alpha, 0.0, 1.0)]))


func _send(multimesh: MultiMesh, data: PackedFloat32Array) -> void:
	var count := data.size() / _STRIDE
	if count > multimesh.instance_count:
		multimesh.instance_count = count
	var full := data.duplicate()
	full.resize(multimesh.instance_count * _STRIDE)  # unused ones: all zero, invisible
	if full.size() > 0:
		multimesh.buffer = full
	multimesh.visible_instance_count = count


## How many of each shape this frame (spheres, segments, rings): for tests.
func counts() -> Vector3i:
	return Vector3i(_sphere_data.size() / _STRIDE, _segment_data.size() / _STRIDE,
			_ring_data.size() / _STRIDE)
