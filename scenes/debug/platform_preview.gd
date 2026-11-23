extends Node3D
## Temporary preview: builds every platform in resources/platforms/, takes
## one numbered screenshot of each (3/4 view, above a strip of main ground,
## a runner-sized capsule at its start for scale) and one overview of all,
## saved to docs/previews/platforms/, then quits. Needs a window (not headless).

const FOLDER := "res://resources/platforms/"
const OUT := "res://docs/previews/platforms/"
## Space between two platforms in the overview.
const SPACING := 64.0
const PER_ROW := 10
const ROW_SPACING := 300.0
const GROUND_GRADE := 0.12

var _shapes: Array[PlatformShape] = []
var _platforms: Array[Node3D] = []
var _grounds: Array[Node3D] = []
var _camera: Camera3D
var _caption: Label


func _ready() -> void:
	_make_world()
	for file in DirAccess.get_files_at(FOLDER):
		if file.ends_with(".tres"):
			_shapes.append(load(FOLDER + file) as PlatformShape)
	for i in _shapes.size():
		_build_one(i)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _shoot_all()
	get_tree().quit()


func _build_one(i: int) -> void:
	var shape := _shapes[i]
	var builder := PlatformBuilder.new(shape)
	var platform := builder.build()
	platform.position = _slot(i)
	add_child(platform)
	_platforms.append(platform)

	var tag := Label3D.new()
	tag.text = "%d" % (i + 1)
	tag.font_size = 160
	tag.pixel_size = 0.08
	tag.outline_size = 40
	tag.modulate = Color(1.0, 0.95, 0.3)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.position = Vector3(0.0, 14.0, 6.0)
	platform.add_child(tag)

	var runner := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	runner.mesh = capsule
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(0.9, 0.2, 0.15)
	runner.material_override = red
	runner.position = Vector3(builder.center_x(2.0), builder.top_y(0.0, 2.0, shape.width * 0.5) + 0.9, -2.0)
	platform.add_child(runner)

	# A strip of main ground (12 % downhill) below, for height and slope.
	var ground := MeshInstance3D.new()
	var box := BoxMesh.new()
	var ground_length := shape.length + 80.0
	box.size = Vector3(50.0, 2.0, ground_length)
	ground.mesh = box
	var green := StandardMaterial3D.new()
	green.albedo_color = Color(0.3, 0.42, 0.3)
	ground.material_override = green
	var slope := atan(GROUND_GRADE)
	var middle := -(ground_length / 2.0 - 40.0)
	ground.position = Vector3(0.0, -shape.float_height - 1.0 + GROUND_GRADE * middle, middle)
	ground.rotation.x = -slope
	platform.add_child(ground)
	_grounds.append(ground)


func _slot(i: int) -> Vector3:
	return Vector3((i % PER_ROW - (PER_ROW - 1) / 2.0) * SPACING, 0.0, -(i / PER_ROW) * ROW_SPACING)


func _shoot_all() -> void:
	for i in _platforms.size():
		for j in _platforms.size():
			_platforms[j].visible = j == i
		var shape := _shapes[i]
		var builder := PlatformBuilder.new(shape)
		var mid := shape.length * 0.5
		var target := _platforms[i].position + Vector3(builder.center_x(mid), builder.top_y(0.0, mid, shape.width * 0.5) - shape.float_height * 0.45, -mid)
		var reach := shape.length
		_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		_camera.fov = 60.0
		_camera.position = target + Vector3(reach * 0.5 + 24.0, reach * 0.24 + 14.0, reach * 0.45 + 22.0)
		_camera.look_at(target)
		_caption.text = "#%d  %s   (%d m long, %d m wide)" % [i + 1, shape.label, shape.length, shape.width]
		await _save("platform_%02d.png" % (i + 1))

	# Overview: all of them, from above, no ground strips.
	for j in _platforms.size():
		_platforms[j].visible = true
		_grounds[j].visible = false
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 500.0
	_camera.far = 3000.0
	var center := Vector3(0.0, 0.0, -ROW_SPACING * 0.5 - 60.0)
	_camera.position = center + Vector3(0.0, 700.0, 500.0)
	_camera.look_at(center)
	_caption.text = "All 20 platforms (they run north, away from the camera)"
	await _save("overview.png")


func _save(file: String) -> void:
	for f in 4:
		await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT + file))
	print("saved ", file)


func _make_world() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.ground_bottom_color = Color(0.36, 0.52, 0.74)
	sky_material.ground_horizon_color = Color(0.66, 0.74, 0.84)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.transform = Transform3D(Basis(Vector3(0.866025, 0, -0.5), Vector3(-0.25, 0.866025, -0.433013), Vector3(0.433013, 0.5, 0.75)), Vector3(0, 50, 0))
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 400.0
	add_child(sun)

	_camera = Camera3D.new()
	_camera.far = 2000.0
	add_child(_camera)
	_camera.make_current()

	var layer := CanvasLayer.new()
	add_child(layer)
	_caption = Label.new()
	_caption.position = Vector2(24, 16)
	_caption.add_theme_font_size_override("font_size", 40)
	_caption.add_theme_color_override("font_color", Color(1.0, 0.95, 0.3))
	_caption.add_theme_color_override("font_outline_color", Color.BLACK)
	_caption.add_theme_constant_override("outline_size", 12)
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_caption)
