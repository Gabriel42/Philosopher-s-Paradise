class_name PlayerAttacks
extends Node3D
## The runner's attacks (its [Attack] children). For testing them one by one,
## only one is on at a time: the mouse wheel swaps (actions "attack_next" and
## "attack_prev"), and a label at the top left names the current one.
## [member enabled] off (setup screen, [SetupScreen]): no attack runs, no
## label, the wheel does nothing.
## Lives under the [Runner]; its parent's parent is the [EndlessLevel].

## Sent when the current attack changes.
signal attack_changed(index: int, attack: Attack)

## Which attack is on at start.
@export var start_index := 0
## Whether the runner attacks at all.
@export var enabled := true:
	set(value):
		enabled = value
		if is_node_ready():
			select(index)

## Every attack, in swap order (the children, in the scene's order).
var attacks: Array[Attack] = []
## Index of the current attack in [member attacks].
var index := 0

@onready var _label: Label = $Hud/AttackName


func _ready() -> void:
	var runner := get_parent() as Node3D
	var level := runner.get_parent() as EndlessLevel if runner != null else null
	for child in get_children():
		var attack := child as Attack
		if attack != null:
			attacks.append(attack)
			attack.setup(runner, level)
	select(start_index)


func _unhandled_input(event: InputEvent) -> void:
	var runner := get_parent() as Runner
	if not enabled or (runner != null and not runner.use_player_input):
		return
	if event.is_action_pressed("attack_next"):
		next()
	elif event.is_action_pressed("attack_prev"):
		previous()


## Makes attack [param i] (wraps around) the current one: on (if
## [member enabled]) and every other off.
func select(i: int) -> void:
	if attacks.is_empty():
		return
	var changed := posmod(i, attacks.size()) != index or not is_node_ready()
	index = posmod(i, attacks.size())
	for k in attacks.size():
		attacks[k].active = enabled and k == index
	if _label != null:
		_label.visible = enabled
		_label.text = "Attack %d/%d: %s   (mouse wheel to swap)" % [
				index + 1, attacks.size(), current().settings.display_name]
	if changed:
		attack_changed.emit(index, current())


func next() -> void:
	select(index + 1)


func previous() -> void:
	select(index - 1)


## The attack that is on.
func current() -> Attack:
	return attacks[index] if not attacks.is_empty() else null
