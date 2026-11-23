class_name CameraController
extends Node3D

## Kontroler Kamera Orbit, Zoom, dan Pan untuk KotaBarengin (Godot 4.7)
signal tile_clicked(screen_pos: Vector2)

@export var min_pitch: float = 30.0
@export var max_pitch: float = 60.0
@export var min_zoom: float = 12.0
@export var max_zoom: float = 30.0
@export var orbit_sensitivity: float = 0.3
@export var zoom_step: float = 1.5
@export var pan_speed: float = 18.0

var yaw: float = 45.0
var pitch: float = 45.0
var zoom_distance: float = 22.0
var focus_position: Vector3 = Vector3(16.0, 0.0, 16.0)

var is_orbiting: bool = false
var is_panning: bool = false
var lmb_pressed: bool = false
var lmb_down_pos: Vector2 = Vector2.ZERO

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	_clamp_focus()
	_update_transform()

func _process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		var forward := -Vector3(sin(deg_to_rad(yaw)), 0.0, cos(deg_to_rad(yaw)))
		var right := Vector3(cos(deg_to_rad(yaw)), 0.0, -sin(deg_to_rad(yaw)))
		var move := (right * input_dir.x + forward * -input_dir.y) * pan_speed * delta
		focus_position += move
		_clamp_focus()
		_update_transform()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			is_orbiting = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				lmb_pressed = true
				lmb_down_pos = mb.position
				is_panning = false
			else:
				# Ketika mouse kiri dilepas:
				# Jika pergeseran kurang dari 5 pixel, itu adalah KLIK (pakai tool)
				if lmb_pressed and not is_panning:
					tile_clicked.emit(mb.position)
				lmb_pressed = false
				is_panning = false
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_distance = clampf(zoom_distance - zoom_step, min_zoom, max_zoom)
			_update_transform()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_distance = clampf(zoom_distance + zoom_step, min_zoom, max_zoom)
			_update_transform()

	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if is_orbiting:
			yaw -= mm.relative.x * orbit_sensitivity
			yaw = fposmod(yaw, 360.0)
			pitch = clampf(pitch - mm.relative.y * orbit_sensitivity, min_pitch, max_pitch)
			_update_transform()
		elif lmb_pressed:
			# Jika digeser lebih dari 5 pixel dari posisi awal tekan, mulai pan kamera
			if not is_panning:
				if mm.position.distance_to(lmb_down_pos) > 5.0:
					is_panning = true
			if is_panning:
				var forward := -Vector3(sin(deg_to_rad(yaw)), 0.0, cos(deg_to_rad(yaw)))
				var right := Vector3(cos(deg_to_rad(yaw)), 0.0, -sin(deg_to_rad(yaw)))
				var drag_scale := 0.025 * (zoom_distance / 22.0)
				var move := (-right * mm.relative.x + forward * mm.relative.y) * drag_scale
				focus_position += move
				_clamp_focus()
				_update_transform()

func _clamp_focus() -> void:
	focus_position.x = clampf(focus_position.x, 0.0, CityData.MAP_SIZE)
	focus_position.z = clampf(focus_position.z, 0.0, CityData.MAP_SIZE)
	focus_position.y = 0.0

func _update_transform() -> void:
	var b := Basis.IDENTITY
	b = b.rotated(Vector3.UP, deg_to_rad(yaw))
	b = b.rotated(b.x.normalized(), deg_to_rad(-pitch))
	transform = Transform3D(b, focus_position)
	if camera:
		camera.position = Vector3(0.0, 0.0, zoom_distance)
		camera.rotation = Vector3.ZERO
