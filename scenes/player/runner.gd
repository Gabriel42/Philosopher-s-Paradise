class_name Runner
extends CharacterBody3D
## The runner (placeholder movement). Runs where the camera looks, gains
## speed going downhill and loses it uphill, jumps, fast-falls. Landing keeps
## the speed along the ground and turns part of the fall into forward speed
## (more on a downhill slope), see [method _land].
## Every number is in [member movement].
## The camera is fixed, looking north down the course (the mouse doesn't turn
## it; it stays captured, click to capture it again). Esc quits the game.
## Effects listen to [signal landed] and [signal fast_fall_changed].

## Sent when touching the ground. [param impact]: speed into the ground (m/s);
## [param kept]: speed after landing / total speed just before (can be > 1).
signal landed(impact: float, kept: float)
## Sent when fast fall starts or stops having an effect (held in the air).
signal fast_fall_changed(on: bool)

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
## Sideways speed in the air (m/s, positive = to the right of [member heading]),
## from left / right, see [member Movement.air_side_speed]. 0 on the ground.
var air_side := 0.0

var _was_on_floor := false
var _fast_fall_on := false

@onready var _pivot: Node3D = $CameraPivot
@onready var _arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var _camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var _model: RunnerModel = $Model
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
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if use_player_input:
		move_input = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
		wants_jump = Input.is_action_just_pressed("jump")
		fast_falling = Input.is_action_pressed("fast_fall")
	_pivot.rotation = Vector3(movement.camera_pitch, 0.0, 0.0)

	var forward := -_pivot.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := Vector3(-forward.z, 0.0, forward.x)
	var wish := right * move_input.x + forward * move_input.y

	if is_on_floor():
		air_side = 0.0
		_move_on_ground(delta, wish)
	else:
		_move_in_air(delta, wish)
	wants_jump = false
	var before := velocity
	move_and_slide()
	if is_on_wall():
		# Hitting a rock or a pillar costs the speed it stopped.
		var real := get_real_velocity()
		speed = minf(speed, Vector3(real.x, 0.0, real.z).length())
	if is_on_floor() and not _was_on_floor:
		_land(before)
	_was_on_floor = is_on_floor()
	var fast_fall_now := fast_falling and not is_on_floor()
	if fast_fall_now != _fast_fall_on:
		_fast_fall_on = fast_fall_now
		fast_fall_changed.emit(fast_fall_now)
	_update_visuals()


## Puts the runner at [param spot] after falling off (keeps some speed).
func respawn(spot: Vector3) -> void:
	global_position = spot
	speed *= movement.respawn_keep
	heading = Vector3.FORWARD
	air_side = 0.0
	velocity = heading * speed
	_was_on_floor = false
	if _fast_fall_on:
		_fast_fall_on = false
		fast_fall_changed.emit(false)


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


## In the air the horizontal velocity is a forward part along [member heading]
## (turned by the input) plus [member air_side], a slide to the side.
func _move_in_air(delta: float, wish: Vector3) -> void:
	var m := movement
	velocity.y -= (m.fast_fall_gravity if fast_falling else m.gravity) * delta
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	# Forward part only: the slide is kept apart in air_side.
	var flat_speed := maxf(flat.dot(heading), 0.0)
	if flat_speed < 0.1 and flat.length() > 0.1:
		heading = flat.normalized()
		flat_speed = flat.length()
	# Straight from the left / right keys (the turn below doesn't weaken it).
	var side_input := clampf(move_input.x, -1.0, 1.0)
	air_side = move_toward(air_side, side_input * m.air_side_speed, m.air_side_accel * delta)
	if wish.length() > 0.1:
		var wish_dir := wish.normalized()
		var angle := heading.signed_angle_to(wish_dir, Vector3.UP)
		var turn := m.air_turn_rate * delta
		heading = heading.rotated(Vector3.UP, clampf(angle, -turn, turn)).normalized()
		if flat_speed < m.run_speed:
			flat_speed = minf(flat_speed + m.air_accel * delta, m.run_speed)
	flat_speed -= m.drag * flat_speed * flat_speed * delta
	var side := Vector3(-heading.z, 0.0, heading.x) * air_side
	velocity.x = heading.x * flat_speed + side.x
	velocity.z = heading.z * flat_speed + side.z


## Landing with [param before] (the velocity just before touching the ground):
## keeps the part along the ground, and turns part of the speed into the ground
## (the impact) into forward speed: all of [member Movement.landing_convert]
## on a downhill slope of [member Movement.landing_full_slope], half on flat
## ground, none on a rising slope as steep. Never keeps less than
## [member Movement.landing_min_keep] of the horizontal speed.
func _land(before: Vector3) -> void:
	var m := movement
	var n := get_floor_normal()
	var impact := maxf(-before.dot(n), 0.0)
	var along := before - n * before.dot(n)
	var flat := Vector3(along.x, 0.0, along.z)
	if flat.length() > 0.1:
		heading = flat.normalized()
	# How much the ground goes down along the heading (sine of the slope).
	var dir := (heading - n * heading.dot(n)).normalized()
	var downhill := Vector3.DOWN.dot(dir)
	var share := clampf(0.5 + 0.5 * downhill / sin(deg_to_rad(m.landing_full_slope)), 0.0, 1.0)
	var new_speed := along.length() * m.landing_keep + impact * m.landing_convert * share
	var before_flat := Vector2(before.x, before.z).length()
	new_speed = maxf(new_speed, before_flat * m.landing_min_keep)
	speed = minf(new_speed, m.max_speed)
	air_side = 0.0
	landed.emit(impact, speed / maxf(before.length(), 0.1))


func _update_visuals() -> void:
	_model.rotation.y = atan2(-heading.x, -heading.z)
	var slope := 0.0
	if is_on_floor():
		var n := get_floor_normal()
		var along := (heading - n * heading.dot(n)).normalized()
		slope = rad_to_deg(asin(clampf(along.y, -1.0, 1.0)))
	_model.animate(speed if is_on_floor() else 0.0, is_on_floor(), slope)
	# Where the runner is going: climb angle and how hard it slides sideways.
	var flat := Vector2(velocity.x, velocity.z).length()
	var climb := rad_to_deg(atan2(velocity.y, maxf(flat, 0.1)))
	_model.fly(climb, air_side / maxf(movement.air_side_speed, 0.1))
	var now := velocity.length()
	var fast := clampf(now / movement.max_speed, 0.0, 1.0)
	_arm.spring_length = lerpf(movement.camera_distance, movement.camera_distance_fast, fast)
	_camera.fov = lerpf(movement.fov, movement.fov_fast, fast)
	_speed_label.text = "%d m/s   %d km/h" % [roundi(now), roundi(now * 3.6)]
