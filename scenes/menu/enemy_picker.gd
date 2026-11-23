class_name EnemyPicker
extends CanvasLayer
## Start screen for testing: one checkbox per enemy type (every [EnemySwarm]
## under [member level]), and Start. While it is open the game is paused and
## the mouse is free; ticking or unticking a type turns it on or off at once
## ([member EnemySwarm.active]). The choice is saved (see [constant SAVE_PATH])
## and ticked again next time; a type never seen before starts ticked. When
## the screen doesn't open, every type stays on.
## Below, an "Attacks" checkbox turns the runner's attacks on or off
## ([member PlayerAttacks.enabled]); it is saved too, with the attack last
## used, which the next run starts with.
## Start (button or Enter) closes it and the run begins; Esc quits.

## Sent when the player presses Start.
signal started

## Where the last choice is kept (one bool per enemy type's display name).
const SAVE_PATH := "user://enemy_picker.cfg"

## The level whose enemy types are listed.
@export var level: EndlessLevel
## The runner's attacks (the "Attacks" checkbox). Optional.
@export var attacks: PlayerAttacks
## Whether the screen opens when the game starts.
@export var show_at_start := true
## Don't open in headless runs (tests, --quit-after checks), where nobody can
## press Start.
@export var skip_when_headless := true
## File the choice is saved to (tests use their own).
@export var save_path := SAVE_PATH

## The enemy types listed, in tree order.
var swarms: Array[EnemySwarm] = []
## The checkbox of each type, in the same order.
var boxes: Array[CheckBox] = []
## The "Attacks" checkbox (null without [member attacks]).
var attacks_box: CheckBox

var _backdrop: ColorRect
var _panel: PanelContainer
var _start: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_find_swarms()
	_build()
	if show_at_start and not (skip_when_headless and DisplayServer.get_name() == "headless"):
		_load_choice()
		open()
		if attacks != null:
			attacks.attack_changed.connect(_on_attack_changed)
	else:
		_backdrop.visible = false
		_panel.visible = false  # every type stays on (the saved choice is not used)


## Shows the screen and pauses the game.
func open() -> void:
	_panel.visible = true
	_backdrop.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_start.grab_focus.call_deferred()


## Saves the choice, hides the screen and unpauses the game.
func start() -> void:
	_save_choice()
	_panel.visible = false
	_backdrop.visible = false
	get_tree().paused = false
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	started.emit()


## True while the screen is shown.
func is_open() -> bool:
	return _panel.visible


func _input(event: InputEvent) -> void:
	if not is_open():
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo \
			and (key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER):
		get_viewport().set_input_as_handled()
		start()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		get_tree().quit()


func _find_swarms() -> void:
	swarms.clear()
	if level == null:
		return
	for child in level.get_children():
		if child is EnemySwarm:
			swarms.append(child as EnemySwarm)


func _build() -> void:
	# Dims the frozen world (the camera hasn't pulled back yet at start).
	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.color = Color(0.05, 0.07, 0.1, 0.85)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var title := Label.new()
	title.text = "Enemies in this run"
	title.add_theme_font_size_override("font_size", 28)
	column.add_child(title)
	boxes.clear()
	for swarm in swarms:
		var box := CheckBox.new()
		box.text = _name_of(swarm)
		box.button_pressed = true
		box.add_theme_font_size_override("font_size", 22)
		box.toggled.connect(func(on: bool) -> void: swarm.active = on)
		column.add_child(box)
		boxes.append(box)
	if swarms.is_empty():
		var none := Label.new()
		none.text = "(no enemy types in the level)"
		column.add_child(none)
	attacks_box = null
	if attacks != null:
		var heading := Label.new()
		heading.text = "Runner"
		heading.add_theme_font_size_override("font_size", 28)
		column.add_child(heading)
		attacks_box = CheckBox.new()
		attacks_box.name = "Attacks"
		attacks_box.text = "Attacks  (mouse wheel swaps)"
		attacks_box.button_pressed = attacks.enabled
		attacks_box.add_theme_font_size_override("font_size", 22)
		attacks_box.toggled.connect(func(on: bool) -> void: attacks.enabled = on)
		column.add_child(attacks_box)
	_start = Button.new()
	_start.name = "Start"
	_start.text = "Start  (Enter)"
	_start.add_theme_font_size_override("font_size", 22)
	_start.pressed.connect(start)
	column.add_child(_start)


func _name_of(swarm: EnemySwarm) -> String:
	if swarm.settings != null and swarm.settings.display_name != "":
		return swarm.settings.display_name
	return String(swarm.name)


func _load_choice() -> void:
	var file := ConfigFile.new()
	if file.load(save_path) != OK:
		return
	for i in swarms.size():
		var on: bool = file.get_value("enemies", _name_of(swarms[i]), true)
		boxes[i].button_pressed = on  # sends toggled: sets active
		swarms[i].active = on
	if attacks != null:
		var enabled: bool = file.get_value("attacks", "enabled", true)
		attacks_box.button_pressed = enabled
		attacks.enabled = enabled
		attacks.select(file.get_value("attacks", "index", attacks.index))


func _save_choice() -> void:
	var file := ConfigFile.new()
	file.load(save_path)  # keep types not in this level
	for i in swarms.size():
		file.set_value("enemies", _name_of(swarms[i]), boxes[i].button_pressed)
	if attacks != null:
		file.set_value("attacks", "enabled", attacks_box.button_pressed)
		file.set_value("attacks", "index", attacks.index)
	file.save(save_path)


## Remembers the attack last used (swapped with the wheel during the run).
func _on_attack_changed(index: int, _attack: Attack) -> void:
	var file := ConfigFile.new()
	file.load(save_path)
	file.set_value("attacks", "index", index)
	file.save(save_path)
