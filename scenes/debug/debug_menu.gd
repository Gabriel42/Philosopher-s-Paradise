class_name DebugMenu
extends CanvasLayer
## Debug panel, shown and hidden with F3 (action "toggle_debug"): for each
## enemy type, how many are out and how many times the runner touched one,
## then the frame rate.

## Every enemy type to show (one [EnemySwarm] per type).
@export var swarms: Array[EnemySwarm] = []

@onready var _panel: Control = $Panel
@onready var _label: Label = $Panel/Label


func _ready() -> void:
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		_panel.visible = not _panel.visible


func _process(_delta: float) -> void:
	if _panel.visible:
		_label.text = panel_text()


## What the panel shows: one line per enemy type, then the FPS.
func panel_text() -> String:
	var lines: PackedStringArray = []
	for swarm in swarms:
		if swarm == null:
			continue
		var kind := swarm.settings.display_name if swarm.settings != null else "-"
		lines.append("%s: %d out, %d touches" % [kind, swarm.positions.size(), swarm.touches])
	lines.append("FPS: %d" % roundi(Engine.get_frames_per_second()))
	return "\n".join(lines)
