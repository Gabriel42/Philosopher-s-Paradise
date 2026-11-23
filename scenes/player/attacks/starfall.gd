class_name Starfall
extends Attack
## Starfall: a ring marks the closest enemy and follows it while a rock falls
## from the sky; [member AttackSettings.duration] s later it lands and blasts
## everything within [member AttackSettings.area].
## Uses: damage, cooldown, reach, area (blast radius), duration (fall time),
## size (rock radius).

## Height the rock falls from (m above its target).
const FALL_HEIGHT := 25.0

# Each falling rock: {target: AttackTarget, point: Vector3, time: float}.
var rocks: Array[Dictionary] = []


func default_settings() -> AttackSettings:
	var s := AttackSettings.new()
	s.display_name = "Starfall"
	s.damage = 5.0
	s.cooldown = 1.3
	s.reach = 40.0
	s.area = 3.5
	s.duration = 0.8
	s.size = 0.8
	s.color = Color(1.0, 0.35, 0.1)
	return s


func _fire() -> bool:
	var targets := nearest(chest(), 1, settings.reach)
	if targets.is_empty():
		return false
	rocks.append({target = targets[0], point = targets[0].center(), time = settings.duration})
	return true


func _update(delta: float) -> void:
	var k := 0
	while k < rocks.size():
		var rock := rocks[k]
		var target: AttackTarget = rock.target
		if target.alive():
			rock.point = target.center()
		rock.time -= delta
		if rock.time > 0.0:
			k += 1
			continue
		var point: Vector3 = rock.point
		hurt_all(enemies_near(point, settings.area), settings.damage)
		flash_ring(point, settings.area, 0.4, true)
		flash_sphere(point, settings.area * 0.7, 0.25)
		rocks.remove_at(k)


func _draw(view: AttackView) -> void:
	for rock in rocks:
		var point: Vector3 = rock.point
		var falling: float = clampf(rock.time / settings.duration, 0.0, 1.0)
		view.ring(point, settings.area, 0.6)
		view.sphere(point + Vector3.UP * FALL_HEIGHT * falling, settings.size)


func _clear() -> void:
	rocks.clear()


func _shift(delta: Vector3) -> void:
	for rock in rocks:
		rock.point -= delta
