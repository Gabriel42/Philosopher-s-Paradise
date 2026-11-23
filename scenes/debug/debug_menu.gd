class_name DebugMenu
extends CanvasLayer
## Debug panel, shown at start (see [member start_visible]) and toggled with
## F3 (action "toggle_debug"): for each enemy type how many are out and how
## many times they touched the runner and how many attacks killed, shots
## fired / hit for types that shoot ([EnemyFlankers]), the runner's current
## attack, and the frame rate.

## Every enemy type to show (one [EnemySwarm] per type).
@export var swarms: Array[EnemySwarm] = []
## The runner's attacks (shows the current one). Optional.
@export var attacks: PlayerAttacks
## Whether the panel is open when the game starts.
@export var start_visible := true

@onready var _panel: Control = $Panel
@onready var _label: Label = $Panel/Label


func _ready() -> void:
	_panel.visible = start_visible
	# Keeps updating while the game is paused (e.g. behind the start screen).
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		_panel.visible = not _panel.visible


func _process(_delta: float) -> void:
	if _panel.visible:
		_label.text = panel_text()


## What the panel shows: one line per enemy type (or "off" if it isn't in
## the run), shots for types that shoot, then the FPS.
func panel_text() -> String:
	var lines: PackedStringArray = []
	for swarm in swarms:
		if swarm == null:
			continue
		var kind := swarm.settings.display_name if swarm.settings != null else "-"
		if not swarm.active:
			lines.append("%s: off" % kind)
			continue
		lines.append("%s: %d out, %d touches, %d kills" % [
				kind, swarm.positions.size(), swarm.touches, swarm.kills])
		if swarm is EnemyFlankers:
			var flankers := swarm as EnemyFlankers
			lines.append("%s shots: %d fired / %d hit" % [
					kind.left(1).to_upper() + kind.substr(1), flankers.shots_fired, flankers.shots_hit])
	if attacks != null and not attacks.enabled:
		lines.append("Attack: off")
	elif attacks != null and attacks.current() != null:
		var attack := attacks.current()
		lines.append("Attack: %s (%d fired, %d kills)" % [
				attack.settings.display_name, attack.fired, attack.kills])
	lines.append("FPS: %d" % roundi(Engine.get_frames_per_second()))
	return "\n".join(lines)
