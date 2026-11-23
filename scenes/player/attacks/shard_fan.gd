class_name ShardFan
extends Attack
## Shard Fan: a fan of shards toward the closest enemy, flying straight; each
## shard goes through [member AttackSettings.pierce] enemies.
## Uses: damage, cooldown, reach, count (shards), spread (fan angle), speed,
## size, duration (flight time), pierce.


func default_settings() -> AttackSettings:
	var s := AttackSettings.new()
	s.display_name = "Shard Fan"
	s.damage = 2.0
	s.cooldown = 0.9
	s.reach = 35.0
	s.count = 5
	s.spread = 40.0
	s.speed = 60.0
	s.size = 0.2
	s.duration = 0.6
	s.pierce = 1
	s.color = Color(0.8, 0.6, 1.0)
	return s


func _fire() -> bool:
	var from := chest()
	var targets := nearest(from, 1, settings.reach)
	if targets.is_empty():
		return false
	var toward := (targets[0].center() - from).normalized()
	var spread := deg_to_rad(settings.spread)
	for k in settings.count:
		var turn := 0.0 if settings.count == 1 \
				else lerpf(-spread * 0.5, spread * 0.5, float(k) / (settings.count - 1))
		add_shot(from, toward.rotated(Vector3.UP, turn) * settings.speed)
	return true
