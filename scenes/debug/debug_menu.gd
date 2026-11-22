class_name DebugMenu
extends CanvasLayer
## Debug panel, shown and hidden with F3 (action "toggle_debug"): how many
## times the runner touched an enemy, how many enemies are out, frame rate.

@export var swarm: EnemySwarm

var touches := 0

@onready var _panel: Control = $Panel
@onready var _label: Label = $Panel/Label


func _ready() -> void:
	_panel.visible = false
	if swarm != null:
		swarm.runner_touched.connect(_on_runner_touched)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		_panel.visible = not _panel.visible


func _process(_delta: float) -> void:
	if not _panel.visible:
		return
	var enemies := swarm.positions.size() if swarm != null else 0
	_label.text = "Enemy touches: %d\nEnemies: %d\nFPS: %d" % [
			touches, enemies, roundi(Engine.get_frames_per_second())]


func _on_runner_touched(total: int) -> void:
	touches = total
