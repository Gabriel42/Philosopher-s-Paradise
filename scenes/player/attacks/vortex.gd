class_name Vortex
extends Attack
## Vortex: a well opens on the closest group of enemies (of the few closest,
## the one with the most others around it) and rides along with the runner
## for [member AttackSettings.duration] s, pulling every enemy within
## [member AttackSettings.area] (any height) to its middle and hurting them
## [member AttackSettings.damage] per second.
## Uses: damage (per second), cooldown, reach, area (radius), duration, pull,
## size (core radius).

## Seconds between two damage ticks.
const TICK := 0.25
## How many of the closest enemies are looked at to find the group.
const CANDIDATES := 6

# Each well: {position: Vector3, time: float, tick: float, spin: float}.
var wells: Array[Dictionary] = []


func default_settings() -> AttackSettings:
	var s := AttackSettings.new()
	s.display_name = "Vortex"
	s.damage = 3.0
	s.cooldown = 3.5
	s.reach = 40.0
	s.area = 6.0
	s.duration = 2.5
	s.pull = 5.0
	s.size = 0.6
	s.color = Color(0.6, 0.35, 1.0)
	return s


func _fire() -> bool:
	var candidates := nearest(chest(), CANDIDATES, settings.reach)
	if candidates.is_empty():
		return false
	var best := candidates[0].center()
	var best_count := -1
	for c in candidates:
		var here := c.center()
		var around := 0
		for other in candidates:
			if other.center().distance_to(here) <= settings.area:
				around += 1
		if around > best_count:
			best_count = around
			best = here
	wells.append({position = best, time = settings.duration, tick = 0.0, spin = 0.0})
	return true


func _update(delta: float) -> void:
	var share := 1.0 - exp(-settings.pull * delta)
	var k := 0
	while k < wells.size():
		var well := wells[k]
		well.position += runner_move
		well.time -= delta
		well.spin += delta
		var center: Vector3 = well.position
		var caught := enemies_near(center, settings.area, true)
		for t in caught:
			var gap := center - t.center()
			t.swarm.drag(t.index, Vector3(gap.x, 0.0, gap.z) * share)
		well.tick -= delta
		if well.tick <= 0.0:
			well.tick += TICK
			hurt_all(caught, settings.damage * TICK)
		if well.time <= 0.0:
			wells.remove_at(k)
		else:
			k += 1


func _draw(view: AttackView) -> void:
	for well in wells:
		var center: Vector3 = well.position
		var spin: float = well.spin
		var fade: float = clampf(well.time / 0.3, 0.0, 1.0)
		view.ring(center, settings.area, 0.5 * fade)
		for r in 3:
			# Rings that shrink toward the middle, one after the other.
			var phase := fmod(spin * 1.2 + r / 3.0, 1.0)
			view.ring(center, settings.area * (1.0 - phase), phase * fade)
		view.sphere(center, settings.size, 0.8 * fade)


func _clear() -> void:
	wells.clear()


func _shift(delta: Vector3) -> void:
	for well in wells:
		well.position -= delta
