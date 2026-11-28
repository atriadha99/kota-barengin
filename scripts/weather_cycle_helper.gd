class_name WeatherCycleHelper
extends Node3D

## Siklus Siang/Malam & Cuaca prosedural ringan (60 FPS, Compatibility)

signal night_state_changed(is_night: bool)
signal weather_changed(weather: String)

var waktu_jam: float = 12.0 # 0.0 - 24.0
var cuaca_saat_ini: String = "cerah" # "cerah" | "berawan" | "hujan"
var is_night: bool = false

var _world_env: WorldEnvironment = null
var _dir_light: DirectionalLight3D = null
var _sky_mat: ProceduralSkyMaterial = null
var _rain_root: Node3D = null
var _rain_drops: Array[MeshInstance3D] = []
var _day_timer: float = 0.0
var _next_weather_days: float = 2.5

var _cur_sky_top: Color = Color(0.35, 0.65, 0.95)
var _cur_sky_hor: Color = Color(0.75, 0.85, 0.95)
var _cur_light_col: Color = Color(1.0, 0.98, 0.92)
var _cur_light_energy: float = 1.15
var _cur_amb: float = 0.50

func setup(world_env: WorldEnvironment, dir_light: DirectionalLight3D, start_jam: float = 12.0, start_cuaca: String = "cerah") -> void:
	_world_env = world_env
	_dir_light = dir_light
	waktu_jam = fmod(maxf(0.0, start_jam), 24.0)
	cuaca_saat_ini = start_cuaca if start_cuaca in ["cerah", "berawan", "hujan"] else "cerah"
	if _world_env and _world_env.environment:
		var env: Environment = _world_env.environment
		if env.sky:
			_sky_mat = env.sky.sky_material as ProceduralSkyMaterial
		env.fog_enabled = true
		env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
		env.fog_density = 0.0075
		env.fog_sky_affect = 0.35
		env.ambient_light_energy = 0.85
	if _dir_light:
		_dir_light.shadow_enabled = true
		_dir_light.shadow_blur = 2.2
		_dir_light.shadow_bias = 0.03
	_init_rain_pool()
	is_night = (waktu_jam >= 19.0 or waktu_jam < 5.0)
	_apply_lighting(1.0)

func _init_rain_pool() -> void:
	_rain_root = Node3D.new()
	_rain_root.name = "RainPool"
	add_child(_rain_root)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.025, 0.70, 0.025)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.84, 0.98, 0.65)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for _i in range(42):
		var drop := MeshInstance3D.new()
		drop.mesh = mesh
		drop.material_override = mat
		drop.position = Vector3(randf_range(-14.0, 14.0), randf_range(0.5, 11.0), randf_range(-14.0, 14.0))
		_rain_root.add_child(drop)
		_rain_drops.append(drop)
	_rain_root.visible = (cuaca_saat_ini == "hujan")

func tick(delta: float, game_speed: float, cam_center: Vector3 = Vector3(16.0, 0.0, 16.0)) -> void:
	if game_speed > 0.0:
		# 1 bulan = 60 detik di 1x -> 24 jam = 2 detik (1 hari game) atau 12 detik siklus nyaman
		# Gunakan 1 hari penuh = 24 detik di 1x agar transisi pagi-siang-sore-malam terasa halus
		var hours_delta: float = delta * game_speed * 1.0
		waktu_jam = fmod(waktu_jam + hours_delta, 24.0)
		_day_timer += hours_delta / 24.0
		if _day_timer >= _next_weather_days:
			_day_timer = 0.0
			_next_weather_days = randf_range(2.0, 3.0)
			_pick_next_weather()

	var now_night: bool = (waktu_jam >= 19.0 or waktu_jam < 5.0)
	if now_night != is_night:
		is_night = now_night
		night_state_changed.emit(is_night)

	_apply_lighting(clampf(delta * 1.8, 0.02, 1.0))
	_update_rain(delta, game_speed, cam_center)

func _pick_next_weather() -> void:
	var pool := ["cerah", "cerah", "berawan", "hujan"]
	var next_w: String = pool[randi() % pool.size()]
	if next_w != cuaca_saat_ini:
		cuaca_saat_ini = next_w
		weather_changed.emit(cuaca_saat_ini)

func _apply_lighting(t: float) -> void:
	var target_top := Color(0.35, 0.65, 0.95)
	var target_hor := Color(0.75, 0.85, 0.95)
	var target_lcol := Color(1.0, 0.98, 0.92)
	var target_energy := 1.15
	var target_amb := 0.50

	if waktu_jam >= 5.0 and waktu_jam < 9.0: # Pagi
		target_top = Color(0.50, 0.70, 0.92)
		target_hor = Color(0.98, 0.74, 0.52)
		target_lcol = Color(1.0, 0.86, 0.68)
		target_energy = 0.90
		target_amb = 0.46
	elif waktu_jam >= 9.0 and waktu_jam < 16.0: # Siang
		target_top = Color(0.35, 0.65, 0.95)
		target_hor = Color(0.75, 0.85, 0.95)
		target_lcol = Color(1.0, 0.98, 0.92)
		target_energy = 1.15
		target_amb = 0.52
	elif waktu_jam >= 16.0 and waktu_jam < 19.0: # Sore
		target_top = Color(0.42, 0.45, 0.74)
		target_hor = Color(0.98, 0.56, 0.28)
		target_lcol = Color(1.0, 0.66, 0.40)
		target_energy = 0.72
		target_amb = 0.40
	else: # Malam
		target_top = Color(0.05, 0.08, 0.18)
		target_hor = Color(0.10, 0.14, 0.28)
		target_lcol = Color(0.38, 0.48, 0.78)
		target_energy = 0.34
		target_amb = 0.26

	if cuaca_saat_ini == "berawan":
		target_top = target_top.lerp(Color(0.55, 0.60, 0.66), 0.55)
		target_hor = target_hor.lerp(Color(0.68, 0.72, 0.78), 0.55)
		target_energy *= 0.78
	elif cuaca_saat_ini == "hujan":
		target_top = target_top.lerp(Color(0.34, 0.38, 0.44), 0.72)
		target_hor = target_hor.lerp(Color(0.44, 0.48, 0.54), 0.72)
		target_energy *= 0.58

	_cur_sky_top = _cur_sky_top.lerp(target_top, t)
	_cur_sky_hor = _cur_sky_hor.lerp(target_hor, t)
	_cur_light_col = _cur_light_col.lerp(target_lcol, t)
	_cur_light_energy = lerpf(_cur_light_energy, target_energy, t)
	_cur_amb = lerpf(_cur_amb, target_amb, t)

	if _sky_mat:
		_sky_mat.sky_top_color = _cur_sky_top
		_sky_mat.sky_horizon_color = _cur_sky_hor
	if _world_env and _world_env.environment:
		_world_env.environment.ambient_light_sky_contribution = _cur_amb
		_world_env.environment.fog_light_color = _cur_sky_hor
		_world_env.environment.ambient_light_color = _cur_sky_hor.lerp(Color(0.62, 0.66, 0.74), 0.5)
	if _dir_light:
		_dir_light.light_color = _cur_light_col
		_dir_light.light_energy = _cur_light_energy

func _update_rain(delta: float, game_speed: float, cam_center: Vector3) -> void:
	if not _rain_root:
		return
	_rain_root.visible = (cuaca_saat_ini == "hujan")
	if not _rain_root.visible or game_speed <= 0.0:
		return
	_rain_root.position = Vector3(cam_center.x, 0.0, cam_center.z)
	var fall := delta * maxf(1.0, game_speed) * 14.0
	for drop in _rain_drops:
		drop.position.y -= fall
		if drop.position.y < 0.2:
			drop.position.y = randf_range(9.0, 12.0)
