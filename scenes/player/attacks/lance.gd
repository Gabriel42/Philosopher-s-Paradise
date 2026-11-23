class_name Lance
extends Attack
## Lance: an instant beam toward the closest enemy, [member AttackSettings.reach]
## long, that hits every enemy along it.
## Uses: damage, cooldown, reach (target distance and beam length), size
## (half the beam's width).


func default_settings() -> AttackSettings:
	var s := AttackSettings.new()
	s.display_name = "Lance"
	s.damage = 4.0
	s.cooldown = 1.2
	s.reach = 35.0
	s.size = 0.5
	s.color = Color(0.75, 1.0, 1.0)
	return s


func _fire() -> bool:
	var from := chest()
	var targets := nearest(from, 1, settings.reach)
	if targets.is_empty():
		return false
	var to := from + (targets[0].center() - from).normalized() * settings.reach
	hurt_all(enemies_on_segment(from, to, settings.size), settings.damage)
	flash_segment(from, to, settings.size, 0.25, true)
	return true
