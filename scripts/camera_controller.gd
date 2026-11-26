class_name CameraController
extends Node3D

## Kontroler Kamera Orbit, Zoom, Pan (Mouse/Keyboard + Sentuh Android)
signal tile_clicked(screen_pos: Vector2)
signal tile_long_pressed(screen_pos: Vector2)
signal tile_dragged(screen_pos: Vector2)

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
var camera_mode: String = "theotown" # "theotown" | "bebas"

var is_orbiting: bool = false
var is_panning: bool = false
var lmb_pressed: bool = false
var lmb_down_pos: Vector2 = Vector2.ZERO

# State sentuh Android (multitouch pinch zoom + 1 jari pan/tap/long-press)
var _all_touches: Dictionary = {} # index -> Vector2 (dipantau di _input agar pinch jalan walau 1 jari tahan tool)
var _map_touches: Dictionary = {} # index -> { "pos": Vector2, "start_pos": Vector2, "moved": bool, "hold_time": float, "long_fired": bool }
var _prev_pinch_dist: float = 0.0
const LONG_PRESS_DURATION: float = 0.55

@onready var camera: Camera3D = $Camera3D

func rotate_yaw(delta_deg: float) -> void:
	if camera_mode == "theotown":
		return
	yaw = fposmod(yaw + delta_deg, 360.0)
	_update_transform()

func set_camera_mode(mode: String, save_pref: bool = true) -> void:
	camera_mode = "bebas" if mode == "bebas" else "theotown"
	if camera_mode == "theotown":
		yaw = 45.0
		pitch = 45.0
	_update_transform()
	if save_pref:
		var s := SaveManager.load_settings()
		s["camera_mode"] = camera_mode
		SaveManager.save_settings(s)

func _ready() -> void:
	var s := SaveManager.load_settings()
	set_camera_mode(str(s.get("camera_mode", "theotown")), false)
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

	# Cek long-press 1 jari di peta
	if _map_touches.size() == 1 and _all_touches.size() <= 1:
		for idx in _map_touches.keys():
			var td: Dictionary = _map_touches[idx]
			if not td["moved"] and not td["long_fired"]:
				td["hold_time"] = float(td["hold_time"]) + delta
				if td["hold_time"] >= LONG_PRESS_DURATION:
					td["long_fired"] = true
					tile_long_pressed.emit(td["pos"])

func _input(event: InputEvent) -> void:
	# Pantau semua sentuhan untuk pinch 2 jari (tetap jalan walau 1 jari menahan tombol tool)
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_all_touches[st.index] = st.position
			if _all_touches.size() == 2:
				var pts: Array = _all_touches.values()
				_prev_pinch_dist = (pts[0] as Vector2).distance_to(pts[1] as Vector2)
		else:
			_all_touches.erase(st.index)
			if _all_touches.size() < 2:
				_prev_pinch_dist = 0.0
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		_all_touches[sd.index] = sd.position
		if _all_touches.size() == 2:
			var pts: Array = _all_touches.values()
			var dist: float = (pts[0] as Vector2).distance_to(pts[1] as Vector2)
			if _prev_pinch_dist > 0.0:
				var diff: float = dist - _prev_pinch_dist
				zoom_distance = clampf(zoom_distance - diff * 0.04, min_zoom, max_zoom)
				_update_transform()
			_prev_pinch_dist = dist

func _unhandled_input(event: InputEvent) -> void:
	# Sentuh pada area peta (bukan UI)
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_map_touches[st.index] = {
				"pos": st.position,
				"start_pos": st.position,
				"moved": false,
				"hold_time": 0.0,
				"long_fired": false
			}
		else:
			if _map_touches.has(st.index):
				var td: Dictionary = _map_touches[st.index]
				if not td["moved"] and not td["long_fired"] and _all_touches.size() <= 1:
					tile_clicked.emit(st.position)
				_map_touches.erase(st.index)
		return

	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _map_touches.has(sd.index) and _all_touches.size() == 1:
			var td: Dictionary = _map_touches[sd.index]
			td["pos"] = sd.position
			if not td["moved"] and sd.position.distance_to(td["start_pos"]) > 10.0:
				td["moved"] = true
			if td["moved"]:
				var forward := -Vector3(sin(deg_to_rad(yaw)), 0.0, cos(deg_to_rad(yaw)))
				var right := Vector3(cos(deg_to_rad(yaw)), 0.0, -sin(deg_to_rad(yaw)))
				var drag_scale := 0.028 * (zoom_distance / 22.0)
				var move := (-right * sd.relative.x + forward * sd.relative.y) * drag_scale
				focus_position += move
				_clamp_focus()
				_update_transform()
		return

	# Kontrol Mouse untuk Laptop (abaikan mouse emulasi dari sentuhan agar tidak dobel)
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.device == InputEvent.DEVICE_ID_EMULATION:
			return
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
		if mm.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if is_orbiting and camera_mode == "bebas":
			yaw -= mm.relative.x * orbit_sensitivity
			yaw = fposmod(yaw, 360.0)
			pitch = clampf(pitch - mm.relative.y * orbit_sensitivity, min_pitch, max_pitch)
			_update_transform()
		elif lmb_pressed:
			if Input.is_key_pressed(KEY_SHIFT):
				is_panning = true
				tile_dragged.emit(mm.position)
				return
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
	focus_position.x = clampf(focus_position.x, -24.0, CityData.MAP_SIZE + 24.0)
	focus_position.z = clampf(focus_position.z, -24.0, CityData.MAP_SIZE + 24.0)
	focus_position.y = 0.0

func _update_transform() -> void:
	var b := Basis.IDENTITY
	b = b.rotated(Vector3.UP, deg_to_rad(yaw))
	b = b.rotated(b.x.normalized(), deg_to_rad(-pitch))
	transform = Transform3D(b, focus_position)
	if camera:
		camera.position = Vector3(0.0, 0.0, zoom_distance)
		camera.rotation = Vector3.ZERO
