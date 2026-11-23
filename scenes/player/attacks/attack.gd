class_name Attack
extends Node3D
## One automatic attack of the runner, like in survivor games: no button, it
## fires by itself every [member AttackSettings.cooldown] seconds at the
## closest enemies (of every active [EnemySwarm]). Each attack is a script
## that extends this one and fills in [method _fire] (one shot; false if there
## was nothing to shoot at), and if needed [method _update] (every frame) and
## [method _draw] (its shapes). This base keeps the cooldown, finds targets,
## hurts enemies, moves [AttackShot]s and fades short flashes.
## Its node is top level (its children draw in the level's space) and only
## runs while [member active] ([PlayerAttacks] turns one on at a time).

## Height of the runner's chest above its feet: where attacks start from.
const CHEST := 1.1

@export var settings: AttackSettings
## Set by [method setup] ([PlayerAttacks] does it).
var runner: Node3D
var level: EndlessLevel
## Only the active attack runs and draws.
var active := false:
	set(value):
		active = value
		if not active:
			clear()
		if _view != null:
			_view.visible = active
## Shots fired since the game started.
var fired := 0
## Enemies this attack killed.
var kills := 0
## How far the runner moved this frame (shots and flashes that ride along
## with it add this).
var runner_move := Vector3.ZERO

var shots: Array[AttackShot] = []
var _view: AttackView
var _cooldown := 0.0
var _last_runner := Vector3.ZERO
var _has_last_runner := false
# Short-lived shapes: {kind, a, b, size, life, time, grow, follow}.
var _flashes: Array[Dictionary] = []


func _ready() -> void:
	if settings == null:
		settings = default_settings()
	top_level = true
	global_transform = Transform3D.IDENTITY
	_view = AttackView.new(settings.color)
	_view.name = "View"
	_view.visible = active
	add_child(_view)


## The numbers this attack uses when no settings are given (tests use them;
## the .tres in resources/attacks/ start as a copy). Override per attack.
func default_settings() -> AttackSettings:
	return AttackSettings.new()


## Gives the attack its runner and level (the level's origin shifts are
## followed so nothing jumps every 2 km).
func setup(runner_node: Node3D, level_node: EndlessLevel) -> void:
	runner = runner_node
	if level != null and level.origin_shifted.is_connected(_on_origin_shifted):
		level.origin_shifted.disconnect(_on_origin_shifted)
	level = level_node
	if level != null:
		level.origin_shifted.connect(_on_origin_shifted)


## Removes every shot, flash and anything else in flight.
func clear() -> void:
	shots.clear()
	_flashes.clear()
	_has_last_runner = false
	_cooldown = 0.0
	_clear()
	if _view != null:
		_view.begin()
		_view.commit()


func _physics_process(delta: float) -> void:
	if not active or runner == null:
		return
	var pos := runner.global_position
	runner_move = pos - _last_runner if _has_last_runner else Vector3.ZERO
	_last_runner = pos
	_has_last_runner = true
	_cooldown -= delta
	if _cooldown <= 0.0:
		if _fire():
			fired += 1
			_cooldown = settings.cooldown
		else:
			_cooldown = 0.0
	_update(delta)
	_view.begin()
	_draw(_view)
	_draw_flashes(delta)
	_view.commit()


## Fires once. Returns false if there was nothing to shoot at (it tries again
## next frame). Override.
func _fire() -> bool:
	return false


## Called every frame after [method _fire]. Override (call super to move shots).
func _update(delta: float) -> void:
	move_shots(delta)


## Lists this frame's shapes. Override (call super to draw the shots).
func _draw(view: AttackView) -> void:
	for shot in shots:
		view.sphere(shot.position, shot.radius)


## Forget anything of your own in flight. Override.
func _clear() -> void:
	pass


## Move anything of your own that remembers a position by -[param delta]
## (the level's origin shifted). Override.
func _shift(_delta: Vector3) -> void:
	pass


# --- Targets --------------------------------------------------------------

## The runner's chest (level space).
func chest() -> Vector3:
	return runner.global_position + Vector3(0.0, CHEST, 0.0)


## Every enemy type in the run.
func swarms() -> Array[EnemySwarm]:
	var found: Array[EnemySwarm] = []
	if not is_inside_tree():
		return found
	for node in get_tree().get_nodes_in_group(EnemySwarm.GROUP):
		var swarm := node as EnemySwarm
		if swarm != null and swarm.active and not swarm.positions.is_empty():
			found.append(swarm)
	return found


## Up to [param count] enemies closest to [param from] (closest first), no
## further than [param max_distance], skipping keys in [param skip] and the
## enemies already passed (see [member AttackSettings.ignore_behind]).
func nearest(from: Vector3, count: int, max_distance: float,
		skip := {}) -> Array[AttackTarget]:
	var best: Array[AttackTarget] = []
	var best_dist := PackedFloat32Array()
	var limit := max_distance * max_distance
	var behind := runner.global_position.z + settings.ignore_behind
	for swarm in swarms():
		for i in swarm.positions.size():
			var c := swarm.center(i)
			if c.z > behind:
				continue
			var d := from.distance_squared_to(c)
			if d > limit:
				continue
			if best.size() == count and d >= best_dist[count - 1]:
				continue
			var t := AttackTarget.new(swarm, i)
			if not skip.is_empty() and skip.has(t.key()):
				continue
			var at := best.size()
			while at > 0 and best_dist[at - 1] > d:
				at -= 1
			best.insert(at, t)
			best_dist.insert(at, d)
			if best.size() > count:
				best.resize(count)
				best_dist.resize(count)
	return best


## Every enemy whose body comes within [param radius] of [param center]
## ([param flat]: measured on X/Z only, any height).
func enemies_near(center: Vector3, radius: float, flat := false) -> Array[AttackTarget]:
	var found: Array[AttackTarget] = []
	for swarm in swarms():
		var reach := radius + swarm.settings.radius + swarm.settings.height * 0.5
		for i in swarm.positions.size():
			var c := swarm.center(i)
			if flat:
				var gap := Vector2(c.x - center.x, c.z - center.z).length()
				if gap - swarm.settings.radius <= radius:
					found.append(AttackTarget.new(swarm, i))
			elif c.distance_squared_to(center) <= reach * reach \
					and swarm.distance_to(i, center) <= radius:
				found.append(AttackTarget.new(swarm, i))
	return found


## Every enemy whose body comes within [param width] of the segment from
## [param a] to [param b].
func enemies_on_segment(a: Vector3, b: Vector3, width: float) -> Array[AttackTarget]:
	var found: Array[AttackTarget] = []
	for swarm in swarms():
		for i in swarm.positions.size():
			var c := swarm.center(i)
			var closest := Geometry3D.get_closest_point_to_segment(c, a, b)
			if closest.distance_squared_to(c) > (width + swarm.settings.height) ** 2:
				continue
			if swarm.distance_to(i, closest) <= width:
				found.append(AttackTarget.new(swarm, i))
	return found


# --- Hurting --------------------------------------------------------------

## Hurts [param target] by [param amount]; counts the kill. True if killed.
func hurt(target: AttackTarget, amount: float) -> bool:
	if target.hurt(amount):
		kills += 1
		return true
	return false


## Hurts every enemy in [param targets] once, skipping (and adding to) the
## keys in [param skip]. Returns how many were hit.
func hurt_all(targets: Array[AttackTarget], amount: float, skip: Dictionary = {}) -> int:
	var hits := 0
	for t in targets:
		var key := t.key()
		if skip.has(key):
			continue
		skip[key] = true
		hurt(t, amount)
		hits += 1
	return hits


# --- Shots ----------------------------------------------------------------

## A new shot from [param from] going [param velocity] (relative to the runner).
func add_shot(from: Vector3, velocity: Vector3) -> AttackShot:
	var shot := AttackShot.new()
	shot.position = from
	shot.velocity = velocity
	shot.life = settings.duration
	shot.radius = settings.size
	shot.pierce = settings.pierce
	shot.turn_rate = settings.turn_rate
	shots.append(shot)
	return shot


## Moves every shot (riding along with the runner), steers homing ones and
## hits the first enemy each one touches.
func move_shots(delta: float) -> void:
	var k := 0
	while k < shots.size():
		var shot := shots[k]
		shot.life -= delta
		if shot.target != null and not shot.target.alive():
			shot.target = null
			if shot.retarget:
				var next := nearest(shot.position, 1, settings.reach)
				if not next.is_empty():
					shot.target = next[0]
		if shot.target != null and shot.turn_rate > 0.0:
			var want := shot.target.center() - shot.position
			if want.length_squared() > 0.0001:
				shot.velocity = _turn_toward(shot.velocity, want, shot.turn_rate * delta)
		var from := shot.position
		shot.position += runner_move + shot.velocity * delta
		if shot.life <= 0.0 or _shot_hits(shot, from):
			shots.remove_at(k)
		else:
			k += 1


## Hits what [param shot] touched on its way from [param from] this frame (a
## swept check: fast shots move further than an enemy is wide in one frame).
## True when the shot is used up.
func _shot_hits(shot: AttackShot, from: Vector3) -> bool:
	for t in enemies_on_segment(from, shot.position, shot.radius):
		var key := t.key()
		if shot.hit.has(key):
			continue
		if shot.blast > 0.0:
			var at := t.center()
			hurt_all(enemies_near(at, shot.blast), settings.damage)
			flash_ring(at, shot.blast, 0.3, true)
			flash_sphere(at, shot.blast * 0.6, 0.2)
			return true
		shot.hit[key] = true
		hurt(t, settings.damage)
		shot.pierce -= 1
		if shot.pierce < 0:
			return true
	return false


## [param from] turned toward [param want] by at most [param angle] radians
## (keeps its length).
static func _turn_toward(from: Vector3, want: Vector3, angle: float) -> Vector3:
	var speed := from.length()
	var a := from.normalized()
	var b := want.normalized()
	var between := a.angle_to(b)
	if between <= angle or between < 0.0001:
		return b * speed
	var axis := a.cross(b)
	if axis.length_squared() < 0.000001:
		axis = Vector3.UP if absf(a.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	return a.rotated(axis.normalized(), angle) * speed


# --- Flashes --------------------------------------------------------------

## A ball that fades over [param time] s ([param follow]: rides with the runner).
func flash_sphere(pos: Vector3, radius: float, time: float, follow := false) -> void:
	_flashes.append({kind = 0, a = pos, b = pos, size = radius, life = time,
			time = time, grow = false, follow = follow})


## A bar that fades over [param time] s.
func flash_segment(a: Vector3, b: Vector3, width: float, time: float, follow := false) -> void:
	_flashes.append({kind = 1, a = a, b = b, size = width, life = time,
			time = time, grow = false, follow = follow})


## A flat ring that fades over [param time] s ([param grow]: opens from small).
func flash_ring(center: Vector3, radius: float, time: float, grow := false,
		follow := false) -> void:
	_flashes.append({kind = 2, a = center, b = center, size = radius, life = time,
			time = time, grow = grow, follow = follow})


func _draw_flashes(delta: float) -> void:
	var k := 0
	while k < _flashes.size():
		var f := _flashes[k]
		f.life -= delta
		if f.life <= 0.0:
			_flashes.remove_at(k)
			continue
		if f.follow:
			f.a += runner_move
			f.b += runner_move
		var left: float = f.life / f.time
		var size: float = f.size * (1.0 - left * 0.8 if f.grow else 1.0)
		match f.kind:
			0: _view.sphere(f.a, size, left)
			1: _view.segment(f.a, f.b, size, left)
			2: _view.ring(f.a, size, left)
		k += 1


func _on_origin_shifted(delta: Vector3) -> void:
	_last_runner -= delta
	for shot in shots:
		shot.position -= delta
	for f in _flashes:
		f.a -= delta
		f.b -= delta
	_shift(delta)
