class_name RunnerModel
extends Node3D
## How the runner looks: the Mannequiny model (GDQuest, CC-BY 4.0) and its
## animations. [Runner] calls [method animate] every physics frame; this only
## shows the state, it never changes movement.

## Ground speed (m/s) at which the run animation plays at its own pace.
@export var run_pace_speed := 7.0
## The run animation never plays slower or faster than this many times its pace.
@export var min_run_scale := 0.6
@export var max_run_scale := 2.5
## Below this ground speed (m/s) the runner stands idle.
@export var idle_below := 0.5
## Cross-fade time between animations (s).
@export var blend_time := 0.15

@onready var _anim: AnimationPlayer = $Mannequiny/AnimationPlayer


func _ready() -> void:
	for looping: String in ["idle", "run"]:
		_anim.get_animation(looping).loop_mode = Animation.LOOP_LINEAR
	_anim.play("idle")


## Picks the animation for this frame: idle, run (faster with [param speed])
## or the jump pose in the air.
func animate(speed: float, on_floor: bool) -> void:
	if not on_floor:
		_play("air_jump")
		_anim.speed_scale = 1.0
	elif speed < idle_below:
		_play("idle")
		_anim.speed_scale = 1.0
	else:
		_play("run")
		_anim.speed_scale = clampf(speed / run_pace_speed, min_run_scale, max_run_scale)


## The animation playing now (for tests).
func current_animation() -> String:
	return _anim.current_animation if _anim.is_playing() else _anim.assigned_animation


func _play(anim_name: String) -> void:
	if _anim.assigned_animation != anim_name:
		_anim.play(anim_name, blend_time)
