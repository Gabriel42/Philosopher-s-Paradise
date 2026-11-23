class_name SparkBolt
extends Attack
## Spark Bolt: a fast bolt at the closest enemy, often. It homes in a little,
## so it still lands on an enemy that moves.
## Uses: damage, cooldown, reach, speed, size, duration, turn_rate.


func default_settings() -> AttackSettings:
	var s := AttackSettings.new()
	s.display_name = "Spark Bolt"
	s.damage = 2.0
	s.cooldown = 0.35
	s.reach = 40.0
	s.speed = 70.0
	s.size = 0.25
	s.duration = 1.2
	s.turn_rate = 10.0
	s.color = Color(1.0, 0.9, 0.3)
	return s


func _fire() -> bool:
	var targets := nearest(chest(), 1, settings.reach)
	if targets.is_empty():
		return false
	var from := chest()
	var shot := add_shot(from, (targets[0].center() - from).normalized() * settings.speed)
	shot.target = targets[0]
	return true
