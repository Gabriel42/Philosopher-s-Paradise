class_name Glaive
extends Attack
## Glaive: a spinning disc thrown at the closest enemy. It flies through
## everything on its way out (each enemy hit once), turns back once it reached
## its target or went [member AttackSettings.reach] m, and hits again on the
## way back to the runner.
## Uses: damage, cooldown, reach, count (discs), speed, size (disc radius),
## duration (longest flight).

# Each disc: {position, target: AttackTarget, aim: Vector3 (last known
# target point), travelled, back: bool, life, hit: Dictionary, spin}.
var discs: Array[Dictionary] = []


func default_settings() -> AttackSettings:
	var s := AttackSettings.new()
	s.display_name = "Glaive"
	s.damage = 3.0
	s.cooldown = 1.6
	s.reach = 22.0
	s.count = 1
	s.speed = 45.0
	s.size = 0.6
	s.duration = 3.0
	s.color = Color(0.6, 1.0, 0.4)
	return s


func _fire() -> bool:
	var targets := nearest(chest(), settings.count, settings.reach)
	if targets.is_empty():
		return false
	for k in settings.count:
		var target: AttackTarget = targets[k % targets.size()]
		discs.append({position = chest(), target = target, aim = target.center(),
				travelled = 0.0, back = false, life = settings.duration, hit = {},
				spin = 0.0})
	return true


func _update(delta: float) -> void:
	var k := 0
	while k < discs.size():
		var disc := discs[k]
		disc.life -= delta
		disc.spin += delta * 15.0
		var start: Vector3 = disc.position + runner_move  # rides along with the runner
		var pos := start
		var goal: Vector3
		if disc.back:
			goal = chest()
		else:
			var target: AttackTarget = disc.target
			if target.alive():
				disc.aim = target.center()
			goal = disc.aim
		var to_goal := goal - pos
		var step := settings.speed * delta
		if to_goal.length() <= step:
			pos = goal
			if disc.back:
				discs.remove_at(k)
				continue
		else:
			pos += to_goal.normalized() * step
		disc.position = pos
		disc.travelled += step
		# Swept from where it was: it moves further than an enemy is wide.
		hurt_all(enemies_on_segment(start, pos, settings.size), settings.damage, disc.hit)
		if not disc.back and (pos.is_equal_approx(goal) or disc.travelled >= settings.reach):
			disc.back = true
			disc.hit = {}  # may hit the same enemies again on the way back
		if disc.life <= 0.0:
			discs.remove_at(k)
			continue
		k += 1


func _draw(view: AttackView) -> void:
	for disc in discs:
		var pos: Vector3 = disc.position
		view.ring(pos, settings.size)
		view.sphere(pos, settings.size * 0.35)
		var spin: float = disc.spin
		var arm := Vector3(cos(spin), 0.0, sin(spin)) * settings.size
		view.segment(pos - arm, pos + arm, 0.08)


func _clear() -> void:
	discs.clear()


func _shift(delta: Vector3) -> void:
	for disc in discs:
		disc.position -= delta
		disc.aim -= delta
