class_name Pulse
extends Attack
## Pulse: a wave around the runner that hits every enemy within
## [member AttackSettings.area] at once. Fires only when an enemy is that
## close.
## Uses: damage, cooldown, area (radius).


func default_settings() -> AttackSettings:
	var s := AttackSettings.new()
	s.display_name = "Pulse"
	s.damage = 3.0
	s.cooldown = 1.5
	s.area = 7.0
	s.color = Color(1.0, 0.45, 0.85)
	return s


func _fire() -> bool:
	var targets := enemies_near(chest(), settings.area)
	if targets.is_empty():
		return false
	hurt_all(targets, settings.damage)
	flash_ring(runner.global_position + Vector3(0.0, 0.3, 0.0), settings.area, 0.35, true, true)
	flash_ring(chest(), settings.area * 0.9, 0.25, true, true)
	return true
