class_name AttackTarget
extends RefCounted
## One enemy an attack is aiming at: its swarm, its slot in the pool and the
## slot's generation, so [method alive] turns false once that enemy is killed
## (or sent ahead) and the slot holds another one.

var swarm: EnemySwarm
var index := 0
var generation := 0


func _init(from: EnemySwarm, i: int) -> void:
	swarm = from
	index = i
	generation = from.generations[i]


## True while the enemy is still the one aimed at.
func alive() -> bool:
	return is_instance_valid(swarm) and swarm.active \
			and index < swarm.generations.size() \
			and swarm.generations[index] == generation


## Middle of the enemy (level space).
func center() -> Vector3:
	return swarm.center(index)


## Takes [param amount] health from it. Returns true if it was killed.
func hurt(amount: float) -> bool:
	if not alive():
		return false
	return swarm.damage(index, amount)


## Key that tells this enemy apart from every other (for "already hit" sets).
func key() -> String:
	return "%d:%d:%d" % [swarm.get_instance_id(), index, generation]
