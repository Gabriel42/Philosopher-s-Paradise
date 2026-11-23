extends Node3D
## Entry scene: the endless level with the runner. The setup screen opens
## first; R during a run ([signal SetupScreen.back_requested]) reloads the
## whole scene, so a fresh run starts behind a fresh setup screen.


func _ready() -> void:
	var setup := get_node_or_null("SetupScreen") as SetupScreen
	if setup != null:
		setup.back_requested.connect(_on_back_requested)


## Starts over: reloads this scene (the setup screen opens again with the
## saved choice).
func _on_back_requested() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
