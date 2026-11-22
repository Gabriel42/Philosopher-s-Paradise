class_name RunnerEffects
extends Node3D
## Effects of the runner (presentation only): listens to the parent
## [Runner]'s signals.
## Landing: dust thrown out at the feet (left in the world), growing with the
## impact (more after a fast fall), and a camera shake on hard landings. No
## ring and no squash: the body runs straight on, see [RunnerModel], which
## also shows the fast fall (a flip, then a dive).
## Placeholder shapes; every number is an @export.

@export var camera: Camera3D

@export_group("Landing")
## Impacts below this (m/s) show nothing (small hops over bumps).
@export var min_impact := 4.0
## Impact (m/s) that gives the biggest effects.
@export var big_impact := 40.0
@export var dust_color := Color(0.92, 0.88, 0.8, 0.8)
## Camera shake (metres) on the biggest landing.
@export var shake := 0.35
@export var shake_time := 0.3

var _shake := 0.0
var _fast_fall_landing := false
## One-off effects left in the world (freed on an origin shift).
var _spawned: Array[Node3D] = []


func _ready() -> void:
	var runner := get_parent() as Runner
	runner.landed.connect(_on_landed)
	runner.fast_fall_changed.connect(_on_fast_fall_changed)
	var level := runner.get_parent() as EndlessLevel
	if level:
		level.origin_shifted.connect(_on_origin_shifted)

## The world moved back: effects left at the old place would jump, so drop them.
func _on_origin_shifted(_delta: Vector3) -> void:
	for node in _spawned:
		if is_instance_valid(node):
			node.queue_free()
	_spawned.clear()


func _process(delta: float) -> void:
	if camera:
		_shake = move_toward(_shake, 0.0, delta / shake_time)
		var amount := _shake * _shake * shake
		camera.h_offset = randf_range(-amount, amount)
		camera.v_offset = randf_range(-amount, amount)


func _on_fast_fall_changed(on: bool) -> void:
	if on:
		_fast_fall_landing = true


func _on_landed(impact: float, _kept: float) -> void:
	var slam := _fast_fall_landing
	_fast_fall_landing = false
	if impact < min_impact:
		return
	var power := clampf((impact - min_impact) / (big_impact - min_impact), 0.0, 1.0)
	_shake = maxf(_shake, power)
	_burst(power, slam)


## Dust thrown out flat around the feet, left in the world.
func _burst(power: float, slam: bool) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = int(lerpf(12.0, 40.0, power)) * (2 if slam else 1)
	p.lifetime = 0.6
	p.mesh = _sphere(0.18)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = 0.6
	p.emission_ring_inner_radius = 0.4
	p.emission_ring_height = 0.1
	p.direction = Vector3.RIGHT
	p.spread = 180.0
	p.flatness = 1.0
	p.initial_velocity_min = lerpf(3.0, 8.0, power)
	p.initial_velocity_max = lerpf(5.0, 16.0, power) * (1.5 if slam else 1.0)
	p.damping_min = 8.0
	p.damping_max = 12.0
	p.gravity = Vector3(0.0, 2.0, 0.0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	p.scale_amount_curve = _fade_curve()
	p.color_ramp = _fade(dust_color)
	_leave_in_world(p, p.lifetime + 0.1)
	p.emitting = true


## Adds a one-off effect where the runner is, in the level (so it stays in the
## world when the runner moves on), and frees it after [param life] seconds.
func _leave_in_world(node: Node3D, life: float) -> void:
	var runner := get_parent()
	var where := runner.get_parent() if runner.get_parent() else runner
	where.add_child(node)
	node.global_position = global_position
	_spawned.assign(_spawned.filter(func(n: Variant) -> bool: return is_instance_valid(n)))
	_spawned.append(node)
	get_tree().create_timer(life).timeout.connect(node.queue_free)


## Unshaded see-through material for particles (their colour comes from the
## colour ramp).
func _material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _sphere(radius: float) -> SphereMesh:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	sphere.material = _material()
	return sphere


## [param color] fading out over a particle's life (in and out if [param both]).
func _fade(color: Color, both := false) -> Gradient:
	var g := Gradient.new()
	var clear := Color(color, 0.0)
	g.set_color(0, clear if both else color)
	g.set_color(1, clear)
	if both:
		g.add_point(0.3, color)
	return g


func _fade_curve() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 1.0))
	c.add_point(Vector2(1.0, 0.2))
	return c
