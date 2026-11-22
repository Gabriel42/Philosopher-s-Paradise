class_name Runner
extends CharacterBody3D
## The runner (placeholder movement). Runs where the camera looks, gains
## speed going downhill and loses it uphill, jumps, fast-falls. Landing keeps
## the part of the speed that goes along the ground, so landing on a downhill
## slope keeps your speed and landing flat loses some.
## Every number is in [member movement].
## The mouse turns the camera (click to capture it, Esc to free it).

@export var movement: Movement
## Off in tests: then [member move_input], [member wants_jump] and
## [member fast_falling] are set by the test instead of read from the keys.
@export var use_player_input := true

## x = right, y = forward, each -1..1.
var move_input := Vector2.ZERO
var wants_jump := false
var fast_falling := false
## Speed along the ground (m/s).
var speed := 0.0
## Horizontal direction of motion.
var heading := Vector3.FORWARD

var _yaw := 0.0
var _pitch := -0.25
var _was_on_floor := false

@onready var _pivot: Node3D = $CameraPivot
@onready var _arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var _camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var _model: Node3D = $Model
@onready var _speed_label: Label = $Hud/Speed


func _ready() -> void:
	if movement == null:
		movement = Movement.new()
	floor_snap_length = movement.floor_snap
	floor_max_angle = deg_to_rad(movement.max_floor_angle)
	_arm.add_excluded_object(get_rid())
	if use_player_input and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if not use_player_input:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		_yaw -= motion.relative.x * movement.mouse_sensitivity
		_pitch = clampf(_pitch - motion.relative.y * movement.mouse_sensitivity, -1.3, 0.6)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if use_player_input:
		move_input = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
		wants_jump = Input.is_action_just_pressed("jump")
		fast_falling = Input.is_action_pressed("fast_fall")
	_pivot.rotation = Vector3(_pitch, _yaw, 0.0)

	var forward := -_pivot.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := Vector3(-forward.z, 0.0, forward.x)
	var wish := right * move_input.x + forward * move_input.y

	if is_on_floor():
		_move_on_ground(delta, wish)
	else:
		_move_in_air(delta, wish)
	wants_jump = false
	move_and_slide()
	if is_on_wall():
		# Hitting a rock or a pillar costs the speed it stopped.
		var real := get_real_velocity()
		speed = minf(speed, Vector3(real.x, 0.0, real.z).length())
	if is_on_floor() and not _was_on_floor:
		_land()
	_was_on_floor = is_on_floor()
	_update_visuals()


## Puts the runner at [param spot] after falling off (keeps some speed).
func respawn(spot: Vector3) -> void:
	global_position = spot
	speed *= movement.respawn_keep
	heading = Vector3.FORWARD
	velocity = heading * speed
	_was_on_floor = false


func _move_on_ground(delta: float, wish: Vector3) -> void:
	var m := movement
	var fast := clampf(speed / m.max_speed, 0.0, 1.0)
	if wish.length() > 0.1:
		var wish_dir := wish.normalized()
		var turn := lerpf(m.turn_rate_slow, m.turn_rate_fast, fast) * delta
		var angle := heading.signed_angle_to(wish_dir, Vector3.UP)
		heading = heading.rotated(Vector3.UP, clampf(angle, -turn, turn)).normalized()
		var push := heading.dot(wish_dir)
		if push > 0.0 and speed < m.run_speed:
			speed = minf(speed + m.run_accel * push * delta, m.run_speed)
		elif push < -0.3:
			speed -= m.brake * delta
	else:
		speed = move_toward(speed, 0.0, m.friction * delta)

	var n := get_floor_normal()
	var along := (heading - n * heading.dot(n)).normalized()
	# Going down, gravity along the slope speeds you up; going up, it slows you.
	speed += Vector3.DOWN.dot(along) * m.gravity * m.slope_factor * delta
	speed -= m.drag * speed * speed * delta
	speed = clampf(speed, 0.0, m.max_speed)
	velocity = along * speed
	if wants_jump:
		velocity += Vector3.UP * m.jump_velocity


func _move_in_air(delta: float, wish: Vector3) -> void:
	var m := movement
	velocity.y -= (m.fast_fall_gravity if fast_falling else m.gravity) * delta
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	var flat_speed := flat.length()
	if flat_speed > 0.1:
		heading = flat / flat_speed
	if wish.length() > 0.1:
		var wish_dir := wish.normalized()
		var angle := heading.signed_angle_to(wish_dir, Vector3.UP)
		var turn := m.air_turn_rate * delta
		heading = heading.rotated(Vector3.UP, clampf(angle, -turn, turn)).normalized()
		if flat_speed < m.run_speed:
			flat_speed = minf(flat_speed + m.air_accel * delta, m.run_speed)
	flat_speed -= m.drag * flat_speed * flat_speed * delta
	velocity.x = heading.x * flat_speed
	velocity.z = heading.z * flat_speed


## Keeps the part of the velocity that goes along the ground.
func _land() -> void:
	var n := get_floor_normal()
	var along := velocity - n * velocity.dot(n)
	speed = minf(along.length() * movement.landing_keep, movement.max_speed)
	var flat := Vector3(along.x, 0.0, along.z)
	if flat.length() > 0.1:
		heading = flat.normalized()


func _update_visuals() -> void:
	_model.rotation.y = atan2(-heading.x, -heading.z)
	var now := velocity.length()
	var fast := clampf(now / movement.max_speed, 0.0, 1.0)
	_arm.spring_length = lerpf(movement.camera_distance, movement.camera_distance_fast, fast)
	_camera.fov = lerpf(movement.fov, movement.fov_fast, fast)
	_speed_label.text = "%d m/s   %d km/h" % [roundi(now), roundi(now * 3.6)]
