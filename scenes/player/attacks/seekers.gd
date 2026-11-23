class_name Seekers
extends Attack
## Seekers: a few slower missiles, each after a different close enemy. They
## leave upward and to the sides, curve in, and burst on the first enemy they
## touch (small blast). If their enemy dies first, they pick the closest one.
## Uses: damage, cooldown, reach, count (missiles), speed, turn_rate, duration,
## size, area (blast radius).


func default_settings() -> AttackSettings:
	var s := AttackSettings.new()
	s.display_name = "Seekers"
	s.damage = 3.0
	s.cooldown = 1.4
	s.reach = 40.0
	s.count = 3
	s.speed = 30.0
	s.turn_rate = 6.0
	s.duration = 3.0
	s.size = 0.3
	s.area = 1.5
	s.color = Color(1.0, 0.55, 0.15)
	return s


func _fire() -> bool:
	var from := chest()
	var targets := nearest(from, settings.count, settings.reach)
	if targets.is_empty():
		return false
	for k in settings.count:
		var target: AttackTarget = targets[k % targets.size()]
		var toward := (target.center() - from).normalized()
		var side := toward.cross(Vector3.UP).normalized()
		var spread := 0.0 if settings.count == 1 else lerpf(-1.0, 1.0, float(k) / (settings.count - 1))
		var dir := (toward * 0.4 + Vector3.UP * 0.7 + side * spread * 0.6).normalized()
		var shot := add_shot(from, dir * settings.speed)
		shot.target = target
		shot.retarget = true
		shot.blast = settings.area
	return true
