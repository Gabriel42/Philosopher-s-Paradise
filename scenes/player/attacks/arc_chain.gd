class_name ArcChain
extends Attack
## Arc Chain: an instant lightning hit on the closest enemy that jumps on to
## the enemy closest to it, and so on ([member AttackSettings.count] enemies,
## each jump at most [member AttackSettings.area] long).
## Uses: damage, cooldown, reach, count, area (jump length), size (arc width).


func default_settings() -> AttackSettings:
	var s := AttackSettings.new()
	s.display_name = "Arc Chain"
	s.damage = 3.0
	s.cooldown = 1.0
	s.reach = 30.0
	s.count = 5
	s.area = 10.0
	s.size = 0.08
	s.color = Color(0.55, 0.85, 1.0)
	return s


func _fire() -> bool:
	var from := chest()
	var targets := nearest(from, 1, settings.reach)
	if targets.is_empty():
		return false
	var hit := {}
	var target: AttackTarget = targets[0]
	for jump in settings.count:
		var to := target.center()
		flash_segment(from, to, settings.size, 0.2)
		flash_sphere(to, 0.4, 0.2)
		hit[target.key()] = true
		hurt(target, settings.damage)
		from = to
		var next := nearest(from, 1, settings.area, hit)
		if next.is_empty():
			break
		target = next[0]
	return true
