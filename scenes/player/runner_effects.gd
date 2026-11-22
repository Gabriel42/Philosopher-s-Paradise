class_name RunnerEffects
extends Node3D
## Effects of the runner (presentation only): listens to the parent
## [Runner]'s signals.
## Landing: dust thrown out at the feet (left in the world) and a ring that
## widens around the runner, both growing with the impact; a squash of the
## body; a camera shake on hard landings. Ring colour: bright when the landing
## kept the speed, orange after a fast fall, dust colour otherwise.
## Fast fall: the body stretches and glows, speed lines rush past.
## Placeholder shapes; every number is an @export.

@export var model: Node3D
@export var camera: Camera3D

@export_group("Landing")
## Impacts below this (m/s) show nothing (small hops over bumps).
@export var min_impact := 4.0
## Impact (m/s) that gives the biggest effects.
@export var big_impact := 40.0
## A landing keeping at least this part of the speed counts as good.
@export var good_kept := 0.95
@export var dust_color := Color(0.92, 0.88, 0.8, 0.8)
@export var good_color := Color(0.45, 0.95, 1.0, 0.9)
@export var slam_color := Color(1.0, 0.6, 0.2, 0.9)
@export var ring_size := 4.0
@export var ring_time := 0.35
## How far the body squashes on the biggest landing (0..1).
@export var squash := 0.4
@export var squash_time := 0.25
## Camera shake (metres) on the biggest landing.
@export var shake := 0.35
@export var shake_time := 0.3

@export_group("Fast fall")
## How far the body stretches while fast falling (0..1).
@export var stretch := 0.3
@export var line_color := Color(1.0, 1.0, 1.0, 0.4)
@export var glow_color := Color(1.0, 0.55, 0.15, 0.45)

var _squash := 0.0
var _stretch := 0.0
var _stretch_target := 0.0
var _shake := 0.0
var _fast_fall_landing := false
var _lines: CPUParticles3D
var _glow: StandardMaterial3D
## One-off effects left in the world (freed on an origin shift).
var _spawned: Array[Node3D] = []


func _ready() -> void:
	var runner := get_parent() as Runner
	runner.landed.connect(_on_landed)
	runner.fast_fall_changed.connect(_on_fast_fall_changed)
	var level := runner.get_parent() as EndlessLevel
	if level:
		level.origin_shifted.connect(_on_origin_shifted)
	_lines = _make_speed_lines()
	add_child(_lines)
	_glow = _material(false)
	_glow.albedo_color = Color(glow_color, 0.0)
	if model:
		for child in model.find_children("*", "MeshInstance3D", true, false):
			(child as MeshInstance3D).material_overlay = _glow


## The world moved back: effects left at the old place would jump, so drop them.
func _on_origin_shifted(_delta: Vector3) -> void:
	for node in _spawned:
		if is_instance_valid(node):
			node.queue_free()
	_spawned.clear()
	if _lines.emitting:
		_lines.restart()


func _process(delta: float) -> void:
	_squash = move_toward(_squash, 0.0, delta / squash_time)
	_stretch = move_toward(_stretch, _stretch_target, delta * 8.0)
	_glow.albedo_color.a = glow_color.a * _stretch
	if model:
		var s := ease(_squash, 0.5) * squash
		var t := _stretch * stretch
		model.scale = Vector3(1.0 + s * 0.8 - t * 0.4, 1.0 - s + t, 1.0 + s * 0.8 - t * 0.4)
	if camera:
		_shake = move_toward(_shake, 0.0, delta / shake_time)
		var amount := _shake * _shake * shake
		camera.h_offset = randf_range(-amount, amount)
		camera.v_offset = randf_range(-amount, amount)


func _on_fast_fall_changed(on: bool) -> void:
	_stretch_target = 1.0 if on else 0.0
	_lines.emitting = on
	if on:
		_fast_fall_landing = true


func _on_landed(impact: float, kept: float) -> void:
	var slam := _fast_fall_landing
	_fast_fall_landing = false
	if impact < min_impact:
		return
	var power := clampf((impact - min_impact) / (big_impact - min_impact), 0.0, 1.0)
	_squash = maxf(_squash, 0.3 + 0.7 * power)
	_shake = maxf(_shake, power)
	_burst(power, slam)
	var color := dust_color
	if kept >= good_kept:
		color = good_color
	elif slam:
		color = slam_color
	_ring(power, color, slam)


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


## A flat ring at the feet that widens and fades (follows the runner, so it
## stays in view at any speed).
func _ring(power: float, color: Color, slam: bool) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	torus.rings = 32
	torus.ring_segments = 6
	ring.mesh = torus
	var mat := _material(false)
	mat.albedo_color = color
	ring.material_override = mat
	ring.position = Vector3.UP * 0.1
	ring.scale = Vector3(1.0, 0.15, 1.0)
	add_child(ring)
	var size := ring_size * lerpf(0.5, 1.0, power) * (1.6 if slam else 1.0)
	var tween := ring.create_tween().set_parallel()
	tween.tween_property(ring, "scale", Vector3(size, 0.15, size), ring_time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, ring_time)
	tween.chain().tween_callback(ring.queue_free)


## Thin vertical streaks around the runner; left still in the world, so they
## rush up and back past it as it falls.
func _make_speed_lines() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.amount = 40
	p.lifetime = 0.3
	var box := BoxMesh.new()
	box.size = Vector3(0.025, 1.4, 0.025)
	box.material = _material()
	p.mesh = box
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = 2.5
	p.emission_ring_inner_radius = 1.2
	p.emission_ring_height = 3.0
	p.position = Vector3.UP * 0.5
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.0
	p.color_ramp = _fade(line_color, true)
	return p


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


## Unshaded see-through material; [param vertex_colors] for particles
## (their colour comes from the colour ramp).
func _material(vertex_colors := true) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = vertex_colors
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
