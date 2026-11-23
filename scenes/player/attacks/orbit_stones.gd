class_name OrbitStones
extends Attack
## Orbit Stones: stones circle the runner at chest height and hit whatever
## runs into them; a stone waits [member AttackSettings.cooldown] s before it
## hits the same enemy again. Always out: it doesn't aim, the enemies come.
## Uses: damage, cooldown (per enemy), count (stones), speed (turns per
## second), area (orbit radius), size (stone radius).

## Angle of the first stone (radians).
var angle := 0.0
# Key of an enemy -> seconds before the stones may hit it again.
var _wait := {}


func default_settings() -> AttackSettings:
	var s := AttackSettings.new()
	s.display_name = "Orbit Stones"
	s.damage = 3.0
	s.cooldown = 0.5
	s.count = 4
	s.speed = 1.0
	s.area = 3.0
	s.size = 0.45
	s.color = Color(0.8, 0.7, 0.55)
	return s


## Where stone [param k] is now.
func stone_position(k: int) -> Vector3:
	var a := angle + TAU * k / settings.count
	return chest() + Vector3(cos(a), 0.0, sin(a)) * settings.area


func _update(delta: float) -> void:
	angle = fmod(angle + TAU * settings.speed * delta, TAU)
	for key in _wait.keys():
		_wait[key] -= delta
		if _wait[key] <= 0.0:
			_wait.erase(key)
	for k in settings.count:
		for t in enemies_near(stone_position(k), settings.size):
			var key := t.key()
			if _wait.has(key):
				continue
			_wait[key] = settings.cooldown
			hurt(t, settings.damage)
			flash_sphere(stone_position(k), settings.size * 1.2, 0.12, true)


func _draw(view: AttackView) -> void:
	for k in settings.count:
		view.sphere(stone_position(k), settings.size)


func _clear() -> void:
	_wait.clear()
