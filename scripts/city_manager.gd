class_name CityManager
extends Node3D

## Manajer simulasi kota, input tool, utilitas, ekonomi bulanan, dan HUD

signal city_updated(city_data: CityData)
signal show_toast(message: String)
signal open_pak_slamet_modal()
signal open_citizen_modal(citizen_info: Dictionary, complaint_info: Dictionary)
signal open_townhall_modal()
signal open_region_buy_modal(region: Vector2i, price: int)
signal open_building_info_modal(tile_pos: Vector2i, tile_info: Dictionary)
signal move_mode_changed(active: bool)
signal map_tapped()
signal time_weather_updated(month: int, year: int, jam: float, cuaca: String)
signal open_farm_info_modal(tile_pos: Vector2i, tile_info: Dictionary)
signal open_incident_modal()

enum ToolMode {
	NONE,
	ROAD,
	ZONE_R,
	ZONE_C,
	ZONE_I,
	POWER_PLANT,
	WATER_TOWER,
	POWER_CABLE,
	WATER_PIPE,
	SCHOOL,
	CLINIC,
	HOSPITAL,
	POLICE,
	MILITARY,
	MAYOR_OFFICE,
	FIRE_STATION,
	ZONE_MILITARY,
	TRAIN_STATION,
	RAIL,
	STOP_ANGKOT,
	STOP_BUS,
	BUSWAY_LANE,
	STOP_BUSWAY,
	WIDEN_ROAD,
	FLYOVER,
	RUNWAY,
	AIRPORT_TERMINAL,
	PARK,
	FARM,
	BULLDOZER
}

var current_tool: ToolMode = ToolMode.ROAD
var city_data: CityData
var tile_visuals: Dictionary = {} # Vector2i -> Node3D
var forest_trees: Dictionary = {} # "x,y" -> Node3D (khusus peta Hutan, bisa ditebang Bulldozer)
var landscape_root: Node3D = null
var regions_root: Node3D = null
var underground_view_enabled: bool = false
var underground_root: Node3D = null
var _police_bonus_active: bool = false
var _military_bonus_active: bool = false
var preview_rotation: int = 0
var moving_from_pos: Vector2i = Vector2i(-1, -1)
var preview_ghost: Node3D = null
var weather_helper: WeatherCycleHelper = null
var night_lights_root: Node3D = null
var wet_road_root: Node3D = null
var event_props_root: Node3D = null
var _weather_hud_accum: float = 0.0
var ambient_helper: AmbientLifeHelper = null
var emergency_manager: EmergencyUnitManager = null
var _wave_strip: Node3D = null
var _river_flow: Node3D = null
var _traffic_timer: float = 0.0
var _traffic_is_green: bool = true
var _last_drag_tile: Vector2i = Vector2i(-999, -999)

@onready var tiles_root: Node3D = $TilesRoot
@onready var car_controller: CarController = $CarController
@onready var pak_slamet_manager: PakSlametManager = $PakSlametManager
@onready var citizen_manager: CitizenManager = $CitizenManager
@export var camera_controller: CameraController

# Siklus bulan permainan: 1 bulan = 60 detik di kecepatan 1x
var month_timer: float = 0.0
const MONTH_DURATION: float = 60.0

func _ready() -> void:
	city_data = CityData.new()
	var loaded_from_save := false
	var carried_from_s1 := false
	if SaveManager.load_on_start:
		loaded_from_save = SaveManager.load_season2(city_data)
		SaveManager.load_on_start = false
	elif SaveManager.s2_carryover_from_s1:
		SaveManager.s2_carryover_from_s1 = false
		var carry: Dictionary = SaveManager.get_s1_carryover_data()
		city_data.mayor_name = carry["mayor_name"]
		city_data.mayor_age = carry["mayor_age"]
		city_data.popularity = carry["popularity"]
		city_data.integrity = carry["integrity"]
		city_data.money = carry["starting_money"]
		city_data.map_landscape = SaveManager.selected_landscape
		carried_from_s1 = true
	else:
		city_data.map_landscape = SaveManager.selected_landscape

	if car_controller:
		car_controller.setup(city_data)

	if pak_slamet_manager:
		pak_slamet_manager.setup(city_data, car_controller, self)
		pak_slamet_manager.pak_slamet_event.connect(func(_type: String, msg: String):
			AudioManager.play_sfx(self, "complaint")
			show_toast.emit(msg)
			city_updated.emit(city_data)
		)
		pak_slamet_manager.open_pak_slamet_dialog.connect(func():
			open_pak_slamet_modal.emit()
		)
		if loaded_from_save:
			pak_slamet_manager.restore_from_save()

	if citizen_manager:
		citizen_manager.setup(city_data)
		citizen_manager.citizen_selected.connect(func(c_info: Dictionary, comp_info: Dictionary):
			open_citizen_modal.emit(c_info, comp_info)
		)
		if loaded_from_save:
			citizen_manager.restore_from_save()

	if camera_controller:
		camera_controller.tile_clicked.connect(_on_tile_clicked)
		camera_controller.tile_long_pressed.connect(_on_tile_long_pressed)
		camera_controller.tile_dragged.connect(_on_tile_dragged)

	_ensure_townhall_exists()
	city_data.ensure_citizen_wishes()
	city_data.update_utilities()
	_police_bonus_active = city_data.has_working_public(CityData.TileType.POLICE)
	_military_bonus_active = city_data.has_working_public(CityData.TileType.MILITARY)
	city_data.happiness = city_data.calculate_happiness()
	city_data.city_level = CityData.get_city_tier(city_data.population)

	_build_landscape_visuals()
	_build_locked_regions_visuals()
	_refresh_all_visuals()
	_setup_weather_cycle()
	_rebuild_event_visuals()
	ambient_helper = AmbientLifeHelper.new()
	add_child(ambient_helper)
	ambient_helper.setup(city_data.map_landscape == "pantai", _wave_strip, _river_flow)
	emergency_manager = EmergencyUnitManager.new()
	emergency_manager.name = "EmergencyUnitManager"
	add_child(emergency_manager)
	emergency_manager.setup(city_data)
	emergency_manager.unit_arrived.connect(_on_emergency_unit_arrived)
	city_updated.emit(city_data)
	if loaded_from_save:
		show_toast.emit("Kota berhasil dimuat dari save!")
	elif carried_from_s1:
		SaveManager.save_season2(city_data)
		show_toast.emit("Selamat datang Walikota %s! Modal awal kotamu: Rp %s" % [city_data.mayor_name, _format_number(city_data.money)])

func _process(delta: float) -> void:
	if emergency_manager:
		emergency_manager.speed_multiplier = city_data.game_speed
	if city_data.game_speed > 0.0:
		month_timer += delta * city_data.game_speed
		if month_timer >= MONTH_DURATION:
			month_timer = 0.0
			_advance_month()
	if weather_helper:
		var cam_pos := camera_controller.position if camera_controller else Vector3(16.0, 0.0, 16.0)
		weather_helper.tick(delta, city_data.game_speed, cam_pos)
		city_data.waktu_jam = weather_helper.waktu_jam
		city_data.cuaca_saat_ini = weather_helper.cuaca_saat_ini
		_weather_hud_accum += delta
		if _weather_hud_accum >= 0.5:
			_weather_hud_accum = 0.0
			time_weather_updated.emit(city_data.month, city_data.year, city_data.waktu_jam, city_data.cuaca_saat_ini)
	if ambient_helper and city_data.game_speed > 0.0:
		ambient_helper.tick(delta, forest_trees, tile_visuals)
	_traffic_timer += delta * maxf(1.0, city_data.game_speed)
	if _traffic_timer >= 4.0:
		_traffic_timer = 0.0
		_traffic_is_green = not _traffic_is_green
		if car_controller:
			car_controller.traffic_red_light = not _traffic_is_green
		_update_traffic_lamp_colors()
	_update_preview_ghost_position()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			rotate_preview()
		elif event.keycode == KEY_ESCAPE:
			if moving_from_pos != Vector2i(-1, -1):
				cancel_move_building()

func set_tool(tool_mode: ToolMode) -> void:
	current_tool = tool_mode
	_rebuild_preview_ghost()
	_refresh_underground_visuals()

func rotate_preview() -> void:
	preview_rotation = (preview_rotation + 90) % 360
	if preview_ghost and is_instance_valid(preview_ghost):
		preview_ghost.rotation_degrees.y = float(preview_rotation)
	AudioManager.play_sfx(self, "click")

func rotate_building_at(pos: Vector2i) -> void:
	if not city_data or not city_data.is_valid_tile(pos.x, pos.y):
		return
	var tile: Dictionary = city_data.get_tile(pos.x, pos.y)
	if tile.get("type", CityData.TileType.EMPTY) == CityData.TileType.EMPTY:
		return
	var new_rot: int = (int(tile.get("rotation", 0)) + 90) % 360
	tile["rotation"] = new_rot
	_update_tile_visual(pos.x, pos.y)
	AudioManager.play_sfx(self, "click")

static func is_movable_building(tile: Dictionary) -> bool:
	var tp: int = tile.get("type", CityData.TileType.EMPTY)
	var lv: int = tile.get("level", 0)
	if tp in [
		CityData.TileType.EMPTY, CityData.TileType.ROAD, CityData.TileType.RAIL,
		CityData.TileType.BUSWAY_LANE, CityData.TileType.FLYOVER, CityData.TileType.RUNWAY,
		CityData.TileType.FARM
	]:
		return false
	if tp in [CityData.TileType.ZONE_R, CityData.TileType.ZONE_C, CityData.TileType.ZONE_I, CityData.TileType.ZONE_MILITARY]:
		return lv > 0
	return true

static func is_rotatable_tile(tile: Dictionary) -> bool:
	var tp: int = tile.get("type", CityData.TileType.EMPTY)
	if tp in [CityData.TileType.EMPTY, CityData.TileType.ROAD, CityData.TileType.FARM]:
		return false
	return true

func start_move_building(pos: Vector2i) -> void:
	var tile: Dictionary = city_data.get_tile(pos.x, pos.y)
	if not is_movable_building(tile):
		return
	moving_from_pos = pos
	_rebuild_preview_ghost()
	move_mode_changed.emit(true)
	show_toast.emit("Klik tile kosong tujuan untuk memindahkan bangunan (Esc = Batal)")

func cancel_move_building() -> void:
	if moving_from_pos == Vector2i(-1, -1):
		return
	moving_from_pos = Vector2i(-1, -1)
	_rebuild_preview_ghost()
	move_mode_changed.emit(false)

func _is_rotatable_tool(mode: ToolMode) -> bool:
	return mode in [
		ToolMode.POWER_PLANT, ToolMode.WATER_TOWER, ToolMode.PARK,
		ToolMode.SCHOOL, ToolMode.CLINIC, ToolMode.HOSPITAL, ToolMode.POLICE,
		ToolMode.MILITARY, ToolMode.MAYOR_OFFICE, ToolMode.FIRE_STATION,
		ToolMode.TRAIN_STATION, ToolMode.STOP_ANGKOT, ToolMode.STOP_BUS,
		ToolMode.STOP_BUSWAY, ToolMode.AIRPORT_TERMINAL
	]

func _rebuild_preview_ghost() -> void:
	if preview_ghost and is_instance_valid(preview_ghost):
		preview_ghost.queue_free()
		preview_ghost = null
	if not city_data:
		return
	if moving_from_pos != Vector2i(-1, -1):
		var t: Dictionary = city_data.get_tile(moving_from_pos.x, moving_from_pos.y)
		preview_ghost = BuildingBuilder.create_tile_node(t.get("type", CityData.TileType.EMPTY), t.get("level", 0), t.get("zone", 0), true)
		preview_ghost.rotation_degrees.y = float(t.get("rotation", 0))
	elif _is_rotatable_tool(current_tool):
		var tp := _tool_to_tile_type(current_tool)
		preview_ghost = BuildingBuilder.create_tile_node(tp, 1 if current_tool == ToolMode.FARM else 0, 0, true)
		preview_ghost.rotation_degrees.y = float(preview_rotation)
	if preview_ghost:
		preview_ghost.scale = Vector3(1.02, 1.02, 1.02)
		preview_ghost.visible = false
		add_child(preview_ghost)

func _tool_to_tile_type(mode: ToolMode) -> CityData.TileType:
	match mode:
		ToolMode.POWER_PLANT: return CityData.TileType.POWER_PLANT
		ToolMode.WATER_TOWER: return CityData.TileType.WATER_TOWER
		ToolMode.PARK: return CityData.TileType.PARK
		ToolMode.FARM: return CityData.TileType.FARM
		ToolMode.SCHOOL: return CityData.TileType.SCHOOL
		ToolMode.CLINIC: return CityData.TileType.CLINIC
		ToolMode.HOSPITAL: return CityData.TileType.HOSPITAL
		ToolMode.POLICE: return CityData.TileType.POLICE
		ToolMode.MILITARY: return CityData.TileType.MILITARY
		ToolMode.MAYOR_OFFICE: return CityData.TileType.MAYOR_OFFICE
		ToolMode.FIRE_STATION: return CityData.TileType.FIRE_STATION
		ToolMode.TRAIN_STATION: return CityData.TileType.TRAIN_STATION
		ToolMode.STOP_ANGKOT: return CityData.TileType.STOP_ANGKOT
		ToolMode.STOP_BUS: return CityData.TileType.STOP_BUS
		ToolMode.STOP_BUSWAY: return CityData.TileType.STOP_BUSWAY
		ToolMode.AIRPORT_TERMINAL: return CityData.TileType.AIRPORT_TERMINAL
	return CityData.TileType.EMPTY

func _update_preview_ghost_position() -> void:
	if not preview_ghost or not is_instance_valid(preview_ghost) or not camera_controller or not camera_controller.camera:
		return
	var cam: Camera3D = camera_controller.camera
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := cam.project_ray_origin(mouse_pos)
	var ray_dir := cam.project_ray_normal(mouse_pos)
	if abs(ray_dir.y) < 0.0001:
		preview_ghost.visible = false
		return
	var t: float = -ray_origin.y / ray_dir.y
	if t <= 0.0:
		preview_ghost.visible = false
		return
	var hit_pos := ray_origin + ray_dir * t
	var tc := CityData.world_pos_to_tile(hit_pos)
	if not city_data.is_valid_tile(tc.x, tc.y):
		preview_ghost.visible = false
		return
	preview_ghost.visible = true
	preview_ghost.position = CityData.tile_to_world_pos(tc.x, tc.y) + Vector3(0.0, 0.08, 0.0)

func set_underground_view(enabled: bool) -> void:
	underground_view_enabled = enabled
	_refresh_underground_visuals()

func set_game_speed(speed: float) -> void:
	city_data.game_speed = speed
	city_updated.emit(city_data)

func set_tax_rate(rate: float) -> void:
	city_data.tax_rate = clampf(rate, 0.05, 0.13)
	city_data.happiness = city_data.calculate_happiness()
	city_updated.emit(city_data)

func _ensure_townhall_exists() -> void:
	# Tempatkan gedung Balai Kota di area tengah kota (tile 7, 7) jika belum ada
	var th_pos := Vector2i(7, 7)
	if city_data.get_tile(th_pos.x, th_pos.y).get("type", CityData.TileType.EMPTY) == CityData.TileType.EMPTY:
		city_data.set_tile(th_pos.x, th_pos.y, CityData.TileType.TOWNHALL, 0)

func _on_tile_long_pressed(screen_pos: Vector2) -> void:
	if not camera_controller or not camera_controller.camera:
		return
	var cam: Camera3D = camera_controller.camera
	var ray_origin := cam.project_ray_origin(screen_pos)
	var ray_dir := cam.project_ray_normal(screen_pos)
	if abs(ray_dir.y) < 0.0001:
		return
	var t: float = -ray_origin.y / ray_dir.y
	if t <= 0.0:
		return
	var hit_pos := ray_origin + ray_dir * t
	var tile_coords := CityData.world_pos_to_tile(hit_pos)
	if not city_data.is_valid_tile(tile_coords.x, tile_coords.y):
		return

	var info: Dictionary = city_data.get_tile(tile_coords.x, tile_coords.y)
	var tp: int = info.get("type", CityData.TileType.EMPTY)
	var lv: int = info.get("level", 0)
	var zn: int = info.get("zone", CityData.BuildingZone.RESIDENTIAL)
	var util_str: String = "Listrik & Air: ✓" if info.get("has_utility", true) else "Listrik/Air: ✗ Kurang!"

	var msg := ""
	match tp:
		CityData.TileType.EMPTY:
			msg = "Tanah Kosong (%d, %d)" % [tile_coords.x, tile_coords.y]
		CityData.TileType.ROAD:
			msg = "Jalan Aspal"
		CityData.TileType.ZONE_R:
			msg = "Rumah Lv %d | %s" % [lv, util_str] if lv > 0 else "Zona Perumahan (Kosong)"
		CityData.TileType.ZONE_C:
			msg = "Toko/Kantor Lv %d | %s" % [lv, util_str] if lv > 0 else "Zona Komersial (Kosong)"
		CityData.TileType.ZONE_I:
			msg = "Pabrik Lv %d | %s" % [lv, util_str] if lv > 0 else "Zona Industri (Kosong)"
		CityData.TileType.BUILDING:
			var label_z := "Rumah" if zn == CityData.BuildingZone.RESIDENTIAL else ("Toko" if zn == CityData.BuildingZone.COMMERCIAL else "Pabrik")
			msg = "%s Lv %d | %s" % [label_z, lv, util_str]
		CityData.TileType.POWER_PLANT:
			msg = "Pembangkit Listrik | Supply: 100"
		CityData.TileType.WATER_TOWER:
			msg = "Menara Air | Supply: 100"
		CityData.TileType.PARK:
			msg = "Taman Kota (+Kebahagiaan sekitar)"
		CityData.TileType.FARM:
			var stage_txt := "Siap Panen!" if lv >= 3 else ("Tumbuh" if lv == 2 else "Benih")
			msg = "Farm Gandum | Tahap %d/3 (%s)" % [lv, stage_txt]
		CityData.TileType.OFFICIAL_PARKING:
			msg = "Parkir Resmi (+Rp 5.000/bln)"
		CityData.TileType.TOWNHALL:
			msg = "Balai Kota KotaBareng"

	if not msg.is_empty():
		AudioManager.play_sfx(self, "click")
		show_toast.emit(msg)

func _on_tile_clicked(screen_pos: Vector2) -> void:
	map_tapped.emit()
	if not camera_controller or not camera_controller.camera:
		return

	var cam: Camera3D = camera_controller.camera
	var ray_origin := cam.project_ray_origin(screen_pos)
	var ray_dir := cam.project_ray_normal(screen_pos)

	if abs(ray_dir.y) < 0.0001:
		return

	var t: float = -ray_origin.y / ray_dir.y
	if t <= 0.0:
		return

	var hit_pos := ray_origin + ray_dir * t
	var tile_coords := CityData.world_pos_to_tile(hit_pos)
	var reg := CityData.get_region_for_tile(tile_coords.x, tile_coords.y)

	# 0. Jika sedang mode PINDAH BANGUNAN
	if moving_from_pos != Vector2i(-1, -1):
		if tile_coords == moving_from_pos:
			cancel_move_building()
			return
		if not city_data.is_region_unlocked(reg) or not city_data.is_valid_tile(tile_coords.x, tile_coords.y):
			AudioManager.play_sfx(self, "error")
			show_toast.emit("Tidak bisa dipindah ke sini")
			return
		var src_tile: Dictionary = city_data.get_tile(moving_from_pos.x, moving_from_pos.y)
		var src_type: int = src_tile.get("type", CityData.TileType.EMPTY)
		var dst_tile: Dictionary = city_data.get_tile(tile_coords.x, tile_coords.y)
		if dst_tile.get("type", CityData.TileType.EMPTY) != CityData.TileType.EMPTY or not city_data.is_tile_buildable(tile_coords.x, tile_coords.y, src_type == CityData.TileType.PARK):
			AudioManager.play_sfx(self, "error")
			show_toast.emit("Tidak bisa dipindah ke sini")
			return
		city_data.set_tile(tile_coords.x, tile_coords.y, src_type, src_tile.get("level", 0), src_tile.get("zone", 0), src_tile.get("rotation", 0))
		city_data.set_tile(moving_from_pos.x, moving_from_pos.y, CityData.TileType.EMPTY, 0, 0, 0)
		if not city_data.active_fire.is_empty() and city_data.active_fire.get("pos", Vector2i(-1, -1)) == moving_from_pos:
			city_data.active_fire["pos"] = tile_coords
		city_data.update_utilities()
		_sync_security_bonuses()
		city_data.happiness = city_data.calculate_happiness()
		_refresh_all_visuals()
		cancel_move_building()
		AudioManager.play_sfx(self, "build")
		show_toast.emit("Bangunan berhasil dipindah!")
		city_updated.emit(city_data)
		return

	if not city_data.is_region_unlocked(reg):
		if current_tool != ToolMode.NONE:
			AudioManager.play_sfx(self, "error")
			show_toast.emit("Buka wilayah ini dulu (klik lahan terkunci)")
		elif city_data.is_region_allowed_by_landscape(reg):
			if city_data.unlocked_regions.size() >= 9:
				AudioManager.play_sfx(self, "error")
				show_toast.emit("Wilayah maksimal tercapai")
			elif city_data.is_region_adjacent(reg):
				AudioManager.play_sfx(self, "click")
				open_region_buy_modal.emit(reg, city_data.get_next_region_price())
			else:
				AudioManager.play_sfx(self, "error")
				show_toast.emit("Buka wilayah ini dulu (klik lahan terkunci)")
		else:
			AudioManager.play_sfx(self, "error")
			show_toast.emit("Buka wilayah ini dulu (klik lahan terkunci)")
		return

	if not city_data.is_valid_tile(tile_coords.x, tile_coords.y):
		return

	# 1. Cek apakah klik mengenai warga pejalan kaki (buka profil warga)
	if citizen_manager and citizen_manager.check_click_hit(hit_pos):
		return

	# 2. Cek apakah klik mengenai Pak Slamet / lokasi parkir liar aktif
	var ps_status: Dictionary = city_data.pak_slamet_status
	if ps_status.get("state") == "active":
		var ps_tile: Vector2i = ps_status.get("active_tile", Vector2i(-1, -1))
		if tile_coords == ps_tile or tile_coords.distance_to(ps_tile) <= 1:
			open_pak_slamet_modal.emit()
			return

	# 3. Cek apakah klik mengenai gedung Balai Kota / Kantor Walikota
	var clicked_type: int = city_data.get_tile(tile_coords.x, tile_coords.y).get("type", CityData.TileType.EMPTY)
	if clicked_type == CityData.TileType.TOWNHALL or (clicked_type == CityData.TileType.MAYOR_OFFICE and current_tool != ToolMode.BULLDOZER):
		open_townhall_modal.emit()
		return

	# 4. Cek apakah klik mengenai insiden aktif atau bangunan rusak akibat kebakaran
	if current_tool != ToolMode.BULLDOZER and not city_data.insiden_aktif.is_empty():
		var inc_pos: Vector2i = city_data.insiden_aktif.get("pos", Vector2i(-1, -1))
		var inc_extra: Vector2i = city_data.insiden_aktif.get("extra_pos", Vector2i(-1, -1))
		if tile_coords == inc_pos or (inc_extra != Vector2i(-1, -1) and tile_coords == inc_extra):
			open_incident_modal.emit()
			return
	if current_tool != ToolMode.BULLDOZER and not city_data.active_fire.is_empty():
		if city_data.active_fire.get("pos", Vector2i(-1, -1)) == tile_coords:
			var f_state: String = str(city_data.active_fire.get("state", ""))
			if f_state in ["damaged_light", "damaged_heavy"]:
				_repair_fire_damage()
				return
			elif f_state == "burning":
				open_incident_modal.emit()
				return

	# 5. Klik lahan Farm (panen langsung jika Siap Panen, atau buka Panel Info Lahan jika belum siap)
	var clicked_tile: Dictionary = city_data.get_tile(tile_coords.x, tile_coords.y)
	if int(clicked_tile.get("type", CityData.TileType.EMPTY)) == CityData.TileType.FARM:
		if current_tool == ToolMode.BULLDOZER:
			_apply_tool(tile_coords.x, tile_coords.y)
			return
		if current_tool == ToolMode.NONE or int(clicked_tile.get("level", 0)) >= 3:
			if int(clicked_tile.get("level", 0)) >= 3:
				harvest_farm_at(tile_coords.x, tile_coords.y)
			else:
				open_farm_info_modal.emit(tile_coords, clicked_tile)
			return
		return

	# 6. Klik bangunan yang sudah ada -> buka info bangunan (Putar / Pindah)
	if is_rotatable_tile(clicked_tile) and current_tool not in [ToolMode.BULLDOZER, ToolMode.POWER_CABLE, ToolMode.WATER_PIPE, ToolMode.WIDEN_ROAD, ToolMode.FLYOVER]:
		open_building_info_modal.emit(tile_coords, clicked_tile)
		return

	if current_tool == ToolMode.NONE:
		return

	_apply_tool(tile_coords.x, tile_coords.y)

func _apply_tool(x: int, y: int) -> void:
	var cur := city_data.get_tile(x, y)
	var cur_type: int = cur.get("type", CityData.TileType.EMPTY)
	var cur_level: int = cur.get("level", 0)

	# 1. Panen gandum jika lahan Siap Panen (level 3) dan tool BUKAN bulldozer
	if cur_type == CityData.TileType.FARM and cur_level >= 3 and current_tool != ToolMode.BULLDOZER:
		_harvest_farm(x, y)
		return

	if current_tool == ToolMode.BULLDOZER:
		var f_key: String = "%d,%d" % [x, y]
		if forest_trees.has(f_key):
			var tnode: Node3D = forest_trees[f_key]
			if is_instance_valid(tnode):
				tnode.queue_free()
			forest_trees.erase(f_key)
			AudioManager.play_sfx(self, "bulldoze")
			show_toast.emit("Pohon ditebang!")
			return
		if cur_type != CityData.TileType.EMPTY:
			var level: int = cur.get("level", 0)
			if level > 0 and cur_type != CityData.TileType.FARM:
				var zone: int = cur.get("zone", CityData.BuildingZone.RESIDENTIAL)
				if zone == CityData.BuildingZone.RESIDENTIAL:
					city_data.population = maxi(0, city_data.population - (level * 10))

			if cur_type == CityData.TileType.ROAD:
				var pos := Vector2i(x, y)
				city_data.power_cables.erase(pos)
				city_data.water_pipes.erase(pos)
				city_data.wide_roads.erase(pos)
			elif cur_type == CityData.TileType.FLYOVER:
				city_data.flyovers.erase(Vector2i(x, y))

			if not city_data.active_fire.is_empty() and city_data.active_fire.get("pos", Vector2i(-1, -1)) == Vector2i(x, y):
				city_data.active_fire.clear()

			city_data.set_tile(x, y, CityData.TileType.EMPTY, 0)
			if cur_type in [CityData.TileType.ROAD, CityData.TileType.FLYOVER, CityData.TileType.STOP_ANGKOT, CityData.TileType.STOP_BUS]:
				_recompute_road_and_neighbors(x, y)
			city_data.update_utilities()
			_sync_security_bonuses()
			city_data.happiness = city_data.calculate_happiness()
			_refresh_all_visuals()
			_update_demand()
			_check_city_tier()
			AudioManager.play_sfx(self, "bulldoze")
			city_updated.emit(city_data)
		elif city_data.power_cables.has(Vector2i(x, y)) or city_data.water_pipes.has(Vector2i(x, y)):
			var pos := Vector2i(x, y)
			city_data.power_cables.erase(pos)
			city_data.water_pipes.erase(pos)
			city_data.update_utilities()
			city_data.happiness = city_data.calculate_happiness()
			_refresh_all_visuals()
			AudioManager.play_sfx(self, "bulldoze")
			show_toast.emit("Kabel/pipa bawah tanah dibongkar!")
			city_updated.emit(city_data)
		return

	# Cek apakah tile dapat dibangun di peta ini (laut/bukit/sungai/pasir)
	var allow_water_or_park: bool = (current_tool == ToolMode.PARK or current_tool == ToolMode.POWER_CABLE or current_tool == ToolMode.WATER_PIPE)
	if not city_data.is_tile_buildable(x, y, allow_water_or_park):
		AudioManager.play_sfx(self, "error")
		show_toast.emit("Area ini tidak bisa dibangun!")
		return

	if current_tool == ToolMode.POWER_CABLE:
		var pos := Vector2i(x, y)
		if city_data.power_cables.has(pos):
			return
		if city_data.money < CityData.COST_POWER_CABLE:
			AudioManager.play_sfx(self, "error")
			show_toast.emit("Uang tidak cukup! (Kurang Rp %s)" % _format_number(CityData.COST_POWER_CABLE - city_data.money))
			return
		city_data.money -= CityData.COST_POWER_CABLE
		city_data.power_cables[pos] = true
		city_data.update_utilities()
		_refresh_all_visuals()
		AudioManager.play_sfx(self, "build")
		city_updated.emit(city_data)
		return

	if current_tool == ToolMode.WIDEN_ROAD:
		var pos := Vector2i(x, y)
		if cur_type != CityData.TileType.ROAD:
			show_toast.emit("Klik jalan yang sudah ada untuk dilebarkan!")
			return
		if city_data.wide_roads.has(pos):
			show_toast.emit("Jalan ini sudah 2 lajur!")
			return
		if not city_data.has_adjacent_type(x, y, CityData.TileType.EMPTY):
			AudioManager.play_sfx(self, "error")
			show_toast.emit("Butuh 1 tile tanah kosong di sisi jalan!")
			return
		if city_data.money < CityData.COST_WIDEN_ROAD:
			AudioManager.play_sfx(self, "error")
			show_toast.emit("Uang tidak cukup!")
			return
		city_data.money -= CityData.COST_WIDEN_ROAD
		city_data.wide_roads[pos] = true
		_update_tile_visual(x, y)
		AudioManager.play_sfx(self, "build")
		show_toast.emit("Jalan dilebarkan menjadi 2 lajur!")
		city_updated.emit(city_data)
		return

	if current_tool == ToolMode.WATER_PIPE:
		var pos := Vector2i(x, y)
		if city_data.water_pipes.has(pos):
			return
		if city_data.money < CityData.COST_WATER_PIPE:
			AudioManager.play_sfx(self, "error")
			show_toast.emit("Uang tidak cukup! (Kurang Rp %s)" % _format_number(CityData.COST_WATER_PIPE - city_data.money))
			return
		city_data.money -= CityData.COST_WATER_PIPE
		city_data.water_pipes[pos] = true
		city_data.update_utilities()
		_refresh_all_visuals()
		AudioManager.play_sfx(self, "build")
		city_updated.emit(city_data)
		return

	# Syarat Lahan Farm: harus bersebelahan dengan Jalan
	if current_tool == ToolMode.FARM:
		if not city_data.has_adjacent_road(x, y):
			AudioManager.play_sfx(self, "error")
			show_toast.emit("Lahan farm harus bersebelahan dengan Jalan!")
			return

	var cost: int = 0
	var target_type: CityData.TileType = CityData.TileType.EMPTY
	var target_zone: CityData.BuildingZone = CityData.BuildingZone.RESIDENTIAL
	var target_level: int = 0

	match current_tool:
		ToolMode.ROAD:
			cost = CityData.COST_ROAD
			target_type = CityData.TileType.ROAD
		ToolMode.ZONE_R:
			cost = CityData.COST_ZONE_R
			target_type = CityData.TileType.ZONE_R
			target_zone = CityData.BuildingZone.RESIDENTIAL
		ToolMode.ZONE_C:
			cost = CityData.COST_ZONE_C
			target_type = CityData.TileType.ZONE_C
			target_zone = CityData.BuildingZone.COMMERCIAL
		ToolMode.ZONE_I:
			cost = CityData.COST_ZONE_I
			target_type = CityData.TileType.ZONE_I
			target_zone = CityData.BuildingZone.INDUSTRIAL
		ToolMode.POWER_PLANT:
			cost = CityData.COST_POWER_PLANT
			target_type = CityData.TileType.POWER_PLANT
		ToolMode.WATER_TOWER:
			cost = CityData.COST_WATER_TOWER
			target_type = CityData.TileType.WATER_TOWER
		ToolMode.SCHOOL:
			cost = CityData.COST_SCHOOL
			target_type = CityData.TileType.SCHOOL
		ToolMode.CLINIC:
			cost = CityData.COST_CLINIC
			target_type = CityData.TileType.CLINIC
		ToolMode.HOSPITAL:
			cost = CityData.COST_HOSPITAL
			target_type = CityData.TileType.HOSPITAL
		ToolMode.POLICE:
			cost = CityData.COST_POLICE
			target_type = CityData.TileType.POLICE
		ToolMode.MILITARY:
			cost = CityData.COST_MILITARY
			target_type = CityData.TileType.MILITARY
		ToolMode.MAYOR_OFFICE:
			cost = CityData.COST_MAYOR_OFFICE
			target_type = CityData.TileType.MAYOR_OFFICE
		ToolMode.FIRE_STATION:
			cost = CityData.COST_FIRE_STATION
			target_type = CityData.TileType.FIRE_STATION
		ToolMode.ZONE_MILITARY:
			cost = CityData.COST_ZONE_MILITARY
			target_type = CityData.TileType.ZONE_MILITARY
		ToolMode.TRAIN_STATION:
			cost = CityData.COST_TRAIN_STATION
			target_type = CityData.TileType.TRAIN_STATION
		ToolMode.RAIL:
			cost = CityData.COST_RAIL
			target_type = CityData.TileType.RAIL
			if not city_data.has_adjacent_type(x, y, CityData.TileType.TRAIN_STATION) and not city_data.has_adjacent_type(x, y, CityData.TileType.RAIL):
				AudioManager.play_sfx(self, "error")
				show_toast.emit("Rel harus tersambung ke Stasiun Kereta!")
				return
		ToolMode.STOP_ANGKOT:
			cost = CityData.COST_STOP_ANGKOT
			target_type = CityData.TileType.STOP_ANGKOT
		ToolMode.STOP_BUS:
			cost = CityData.COST_STOP_BUS
			target_type = CityData.TileType.STOP_BUS
		ToolMode.BUSWAY_LANE:
			cost = CityData.COST_BUSWAY_LANE
			target_type = CityData.TileType.BUSWAY_LANE
		ToolMode.STOP_BUSWAY:
			cost = CityData.COST_STOP_BUSWAY
			target_type = CityData.TileType.STOP_BUSWAY
		ToolMode.FLYOVER:
			cost = CityData.COST_FLYOVER
			target_type = CityData.TileType.FLYOVER
			if city_data.flyovers.size() >= 3:
				AudioManager.play_sfx(self, "error")
				show_toast.emit("Maksimal 3 Flyover di kota!")
				return
			if cur_type != CityData.TileType.ROAD or (not city_data.has_adjacent_road(x, y) and not city_data.has_adjacent_type(x, y, CityData.TileType.FLYOVER)):
				AudioManager.play_sfx(self, "error")
				show_toast.emit("Flyover dibangun di atas jalan yang tersambung jalan lain!")
				return
		ToolMode.RUNWAY:
			cost = CityData.COST_RUNWAY
			target_type = CityData.TileType.RUNWAY
		ToolMode.AIRPORT_TERMINAL:
			cost = CityData.COST_AIRPORT_TERMINAL
			target_type = CityData.TileType.AIRPORT_TERMINAL
			if not city_data.has_adjacent_type(x, y, CityData.TileType.RUNWAY) or not city_data.has_adjacent_road(x, y):
				AudioManager.play_sfx(self, "error")
				show_toast.emit("Terminal harus bersebelahan dengan Landasan & Jalan!")
				return
		ToolMode.PARK:
			cost = CityData.COST_PARK
			target_type = CityData.TileType.PARK
		ToolMode.FARM:
			cost = CityData.COST_FARM
			target_type = CityData.TileType.FARM
			target_level = 1 # Mulai dari tahap 1: Benih

	if (target_type in CityData.PUBLIC_BUILDING_TYPES) or (target_type in [CityData.TileType.ZONE_MILITARY, CityData.TileType.TRAIN_STATION, CityData.TileType.STOP_ANGKOT, CityData.TileType.STOP_BUS, CityData.TileType.BUSWAY_LANE, CityData.TileType.STOP_BUSWAY, CityData.TileType.FLYOVER, CityData.TileType.AIRPORT_TERMINAL]):
		var unlock_info: Dictionary = city_data.is_public_building_unlocked(target_type)
		if not unlock_info.get("unlocked", false):
			AudioManager.play_sfx(self, "error")
			show_toast.emit(str(unlock_info.get("reason", "Belum terbuka!")))
			return

	if cur_type == target_type and cur.get("level", 0) == target_level:
		return

	if city_data.money < cost:
		AudioManager.play_sfx(self, "error")
		show_toast.emit("Uang tidak cukup! (Kurang Rp %s)" % _format_number(cost - city_data.money))
		return

	city_data.money -= cost
	var f_key2: String = "%d,%d" % [x, y]
	if forest_trees.has(f_key2):
		var tnode2: Node3D = forest_trees[f_key2]
		if is_instance_valid(tnode2):
			tnode2.queue_free()
		forest_trees.erase(f_key2)
	city_data.set_tile(x, y, target_type, target_level, target_zone, preview_rotation)
	if target_type in [CityData.TileType.ROAD, CityData.TileType.STOP_ANGKOT, CityData.TileType.STOP_BUS]:
		var pos := Vector2i(x, y)
		city_data.power_cables[pos] = true
		city_data.water_pipes[pos] = true
	elif target_type == CityData.TileType.FLYOVER:
		city_data.flyovers[Vector2i(x, y)] = true
		city_data.power_cables[Vector2i(x, y)] = true
		city_data.water_pipes[Vector2i(x, y)] = true
	elif target_type == CityData.TileType.POWER_PLANT:
		city_data.power_cables[Vector2i(x, y)] = true
	elif target_type == CityData.TileType.WATER_TOWER:
		city_data.water_pipes[Vector2i(x, y)] = true
	if target_type in [CityData.TileType.ROAD, CityData.TileType.FLYOVER, CityData.TileType.STOP_ANGKOT, CityData.TileType.STOP_BUS]:
		_recompute_road_and_neighbors(x, y)
	city_data.update_utilities()
	_sync_security_bonuses()
	city_data.happiness = city_data.calculate_happiness()
	if target_type in [CityData.TileType.ROAD, CityData.TileType.FLYOVER, CityData.TileType.STOP_ANGKOT, CityData.TileType.STOP_BUS, CityData.TileType.POWER_PLANT, CityData.TileType.WATER_TOWER] or (target_type in CityData.PUBLIC_BUILDING_TYPES):
		_refresh_all_visuals()
	else:
		_update_tile_visual(x, y)
	_update_demand()
	AudioManager.play_sfx(self, "build")
	city_updated.emit(city_data)

func _harvest_farm(x: int, y: int) -> void:
	harvest_farm_at(x, y)

func harvest_farm_at(x: int, y: int) -> bool:
	if not city_data or not city_data.is_valid_tile(x, y):
		return false
	var t: Dictionary = city_data.get_tile(x, y)
	if int(t.get("type", CityData.TileType.EMPTY)) != CityData.TileType.FARM:
		return false
	if int(t.get("level", 0)) < 3:
		return false

	# Kunci tahap lebih dulu untuk mencegah panen ganda pada double-tap
	city_data.set_tile(x, y, CityData.TileType.FARM, 1)
	city_data.wheat_inventory += CityData.WHEAT_PER_HARVEST
	city_data.wheat_harvest_count += 1
	_update_tile_visual(x, y)

	var popup: Label3D = BuildingBuilder.create_harvest_popup(CityData.WHEAT_PER_HARVEST)
	popup.position = CityData.tile_to_world_pos(x, y)
	add_child(popup)
	var tween: Tween = create_tween()
	tween.tween_property(popup, "position:y", popup.position.y + 1.2, 1.2)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 1.2)
	tween.tween_callback(popup.queue_free)

	AudioManager.play_sfx(self, "harvest")
	show_toast.emit("+%d Gandum masuk gudang!" % CityData.WHEAT_PER_HARVEST)
	city_updated.emit(city_data)
	return true

func bulldoze_farm_at(x: int, y: int) -> void:
	if not city_data or not city_data.is_valid_tile(x, y):
		return
	var t: Dictionary = city_data.get_tile(x, y)
	if int(t.get("type", CityData.TileType.EMPTY)) != CityData.TileType.FARM:
		return
	city_data.set_tile(x, y, CityData.TileType.EMPTY, 0)
	city_data.update_utilities()
	city_data.happiness = city_data.calculate_happiness()
	_update_tile_visual(x, y)
	_update_demand()
	AudioManager.play_sfx(self, "bulldoze")
	show_toast.emit("Lahan farm dihapus!")
	city_updated.emit(city_data)

func sell_all_wheat() -> void:
	if city_data.wheat_inventory <= 0:
		AudioManager.play_sfx(self, "error")
		show_toast.emit("Gudang kosong! Belum ada gandum untuk dijual.")
		return

	var count := city_data.wheat_inventory
	var earnings := count * city_data.wheat_price
	city_data.money += earnings
	city_data.wheat_inventory = 0

	AudioManager.play_sfx(self, "sell")
	show_toast.emit("Terjual %d Gandum = Rp %s" % [count, _format_number(earnings)])
	city_updated.emit(city_data)

## Simulasi pergantian bulan: ekonomi, pajak, upkeep, dan pertumbuhan
func _advance_month() -> void:
	city_data.month += 1
	if city_data.month > 12:
		city_data.month = 1
		city_data.year += 1

	# 1. Kumpulkan Pajak (Penduduk + Komersial + Industri)
	var tax_multiplier: float = city_data.tax_rate / 0.08 # skala normal pada 8%
	var resident_tax: int = int(float(city_data.population) * 120.0 * tax_multiplier)

	var c_count := 0
	var i_count := 0
	var plant_count := 0
	var tower_count := 0
	var park_count := 0

	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			var tile: Dictionary = city_data.get_tile(x, y)
			var type: int = tile.get("type", CityData.TileType.EMPTY)
			var level: int = tile.get("level", 0)
			if level > 0:
				var z: int = tile.get("zone", CityData.BuildingZone.RESIDENTIAL)
				if z == CityData.BuildingZone.COMMERCIAL:
					c_count += level
				elif z == CityData.BuildingZone.INDUSTRIAL:
					i_count += level
			elif type == CityData.TileType.POWER_PLANT:
				plant_count += 1
			elif type == CityData.TileType.WATER_TOWER:
				tower_count += 1
			elif type == CityData.TileType.PARK:
				park_count += 1

	var commercial_tax: int = int(float(c_count) * 2500.0 * tax_multiplier)
	var industrial_tax: int = int(float(i_count) * 3500.0 * tax_multiplier)
	var total_tax: int = resident_tax + commercial_tax + industrial_tax

	# 2. Bayar Upkeep (Pembangkit, Menara Air, Taman)
	var upkeep_total: int = (plant_count * CityData.UPKEEP_POWER_PLANT) + \
		(tower_count * CityData.UPKEEP_WATER_TOWER) + \
		(park_count * CityData.UPKEEP_PARK)

	var net_cashflow: int = total_tax - upkeep_total
	city_data.money += net_cashflow

	# Update utilitas dan kebahagiaan
	city_data.update_utilities()
	city_data.happiness = city_data.calculate_happiness()

	# Cek pertumbuhan populasi 2 bulan berturut-turut
	if city_data.population > city_data.prev_population:
		city_data.consecutive_growth_months += 1
	else:
		city_data.consecutive_growth_months = 0
	city_data.prev_population = city_data.population

	# 3. Pertumbuhan bangunan baru (maksimal 4 bangunan per bulan)
	# HANYA tumbuh jika supply listrik & air mencukupi dan kebahagiaan tidak hancur
	var candidates: Array[Vector2i] = []
	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			var tile: Dictionary = city_data.get_tile(x, y)
			var type: int = tile.get("type", CityData.TileType.EMPTY)
			var level: int = tile.get("level", 0)

			var is_zone: bool = (type == CityData.TileType.ZONE_R or type == CityData.TileType.ZONE_C or type == CityData.TileType.ZONE_I)
			if is_zone and level == 0 and city_data.has_adjacent_road(x, y):
				var zone_type: int = tile.get("zone", CityData.BuildingZone.RESIDENTIAL)
				# Cek supply listrik dan air untuk bangunan baru ini
				if city_data.can_supply_new_building(zone_type):
					var has_demand := false
					if zone_type == CityData.BuildingZone.RESIDENTIAL and city_data.demand_r > 15.0 and city_data.happiness >= 40.0:
						has_demand = true
					elif zone_type == CityData.BuildingZone.COMMERCIAL and city_data.demand_c > 15.0:
						has_demand = true
					elif zone_type == CityData.BuildingZone.INDUSTRIAL and city_data.demand_i > 15.0:
						has_demand = true

					if has_demand:
						candidates.append(Vector2i(x, y))

	candidates.shuffle()
	var grow_count := mini(4, candidates.size())
	for i in range(grow_count):
		var pos: Vector2i = candidates[i]
		var tile: Dictionary = city_data.get_tile(pos.x, pos.y)
		var zone: int = tile.get("zone", CityData.BuildingZone.RESIDENTIAL)
		var type: int = tile.get("type", CityData.TileType.EMPTY)

		city_data.set_tile(pos.x, pos.y, type, 1, zone)
		if zone == CityData.BuildingZone.RESIDENTIAL:
			city_data.population += 10
		elif zone == CityData.BuildingZone.COMMERCIAL:
			city_data.population += 4
		elif zone == CityData.BuildingZone.INDUSTRIAL:
			city_data.population += 6

	# 3b. Pertumbuhan Zona Militer (tidak menambah populasi)
	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			var mt: Dictionary = city_data.get_tile(x, y)
			if mt.get("type", CityData.TileType.EMPTY) == CityData.TileType.ZONE_MILITARY and mt.get("level", 0) == 0 and city_data.has_adjacent_road(x, y):
				city_data.set_tile(x, y, CityData.TileType.ZONE_MILITARY, randi_range(1, 3), CityData.BuildingZone.RESIDENTIAL)
				break

	# 4. Naik level bangunan (Lv 1 -> 2, Lv 2 -> 3)
	if city_data.consecutive_growth_months >= 2 and city_data.happiness >= 60.0:
		var upgrade_candidates: Array[Vector2i] = []
		for y in range(CityData.GRID_SIZE):
			for x in range(CityData.GRID_SIZE):
				var tile: Dictionary = city_data.get_tile(x, y)
				var level: int = tile.get("level", 0)
				if level in [1, 2] and tile.get("has_utility", false):
					upgrade_candidates.append(Vector2i(x, y))

		upgrade_candidates.shuffle()
		var upgrade_count := mini(2, upgrade_candidates.size())
		for i in range(upgrade_count):
			var pos: Vector2i = upgrade_candidates[i]
			var tile: Dictionary = city_data.get_tile(pos.x, pos.y)
			var cur_level: int = tile.get("level", 0)
			var zone: int = tile.get("zone", CityData.BuildingZone.RESIDENTIAL)
			var type: int = tile.get("type", CityData.TileType.EMPTY)

			city_data.set_tile(pos.x, pos.y, type, cur_level + 1, zone)
			if zone == CityData.BuildingZone.RESIDENTIAL:
				city_data.population += 15

	# 5. Pertumbuhan gandum di lahan farm (3 tahap: Benih -> Tumbuh -> Siap Panen)
	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			var tile: Dictionary = city_data.get_tile(x, y)
			if tile.get("type", CityData.TileType.EMPTY) == CityData.TileType.FARM:
				var stage: int = tile.get("level", 1)
				if stage < 3:
					city_data.set_tile(x, y, CityData.TileType.FARM, stage + 1)

	# Ubah harga pasar gandum tiap bulan (Rp 800 - Rp 1.500)
	city_data.wheat_price = randi_range(800, 1500)

	# 6. Simulasi Siklus Pak Slamet & Pengaduan Warga (Langkah 5)
	if pak_slamet_manager:
		pak_slamet_manager.on_month_passed()

	# Cek pengaduan yang terabaikan sampai akhir bulan (penurunan Popularitas -5)
	var has_mayor_office := city_data.has_working_public(CityData.TileType.MAYOR_OFFICE)
	for complaint in city_data.active_complaints:
		if complaint.get("status") == "active":
			var w_m: int = int(complaint.get("wait_months", 0)) + 1
			complaint["wait_months"] = w_m
			var threshold: int = 2 if has_mayor_office else 1
			if w_m >= threshold:
				complaint["status"] = "late"
				city_data.popularity = clampf(city_data.popularity - 5.0, 0.0, 100.0)
				if complaint.get("type", "") in [ComplaintsData.COMPLAINT_INSECURE, ComplaintsData.COMPLAINT_TRAFFIC]:
					city_data.security = clampf(city_data.security - 5.0, 0.0, 100.0)
		elif complaint.get("status") == "late":
			city_data.popularity = clampf(city_data.popularity - 5.0, 0.0, 100.0)
			if complaint.get("type", "") in [ComplaintsData.COMPLAINT_INSECURE, ComplaintsData.COMPLAINT_TRAFFIC]:
				city_data.security = clampf(city_data.security - 5.0, 0.0, 100.0)

	# 7. Efek Bulanan Gedung Layanan Publik & Event Kebakaran
	_apply_public_buildings_monthly()
	_process_fire_event_monthly()
	_process_incidents_monthly()
	_process_city_events_monthly()
	_process_citizen_wishes_monthly()

	if citizen_manager:
		var prev_comp_count: int = city_data.active_complaints.size()
		citizen_manager.update_citizen_complaints()
		if city_data.active_complaints.size() > prev_comp_count:
			AudioManager.play_sfx(self, "complaint")

	# Update ulang utilitas dan tampilan visual semua tile (supaya ikon peringatan muncul/hilang tepat)
	city_data.update_utilities()
	_sync_security_bonuses()
	city_data.happiness = city_data.calculate_happiness()
	city_data.record_monthly_stats()
	_update_demand()
	_check_city_tier()
	_refresh_all_visuals()
	SaveManager.save_season2(city_data) # Autosave tiap bulan game
	city_updated.emit(city_data)

func _check_city_tier() -> void:
	var new_tier := CityData.get_city_tier(city_data.population)
	if new_tier != city_data.city_level:
		city_data.city_level = new_tier
		AudioManager.play_sfx(self, "level_up")
		if _unlock_free_adjacent_region():
			show_toast.emit("Selamat! Kota naik level — wilayah baru terbuka!")
		else:
			show_toast.emit("Naik level: %s!" % new_tier)

func _unlock_free_adjacent_region() -> bool:
	if city_data.unlocked_regions.size() >= 9:
		return false
	for ry in range(-1, 2):
		for rx in range(-1, 2):
			var r := Vector2i(rx, ry)
			if city_data.is_region_adjacent(r):
				city_data.unlocked_regions.append(r)
				_build_locked_regions_visuals()
				return true
	return false

func buy_region(r: Vector2i) -> bool:
	if city_data.unlocked_regions.size() >= 9:
		AudioManager.play_sfx(self, "error")
		show_toast.emit("Wilayah maksimal tercapai")
		return false
	if not city_data.is_region_adjacent(r):
		return false
	var price: int = city_data.get_next_region_price()
	if city_data.money < price:
		AudioManager.play_sfx(self, "error")
		show_toast.emit("Uang kota tidak cukup")
		return false

	city_data.money -= price
	city_data.regions_bought += 1
	city_data.unlocked_regions.append(r)
	_build_locked_regions_visuals()
	AudioManager.play_sfx(self, "build")
	show_toast.emit("Wilayah baru terbuka!")
	SaveManager.save_season2(city_data)
	city_updated.emit(city_data)
	return true

func _update_demand() -> void:
	var r_count := 0
	var c_count := 0
	var i_count := 0

	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			var tile: Dictionary = city_data.get_tile(x, y)
			var level: int = tile.get("level", 0)
			if level > 0:
				var zone: int = tile.get("zone", CityData.BuildingZone.RESIDENTIAL)
				if zone == CityData.BuildingZone.RESIDENTIAL:
					r_count += level
				elif zone == CityData.BuildingZone.COMMERCIAL:
					c_count += level
				elif zone == CityData.BuildingZone.INDUSTRIAL:
					i_count += level

	if r_count == 0:
		city_data.demand_r = 85.0
		city_data.demand_c = 25.0
		city_data.demand_i = 45.0
	else:
		var jobs := float(c_count) * 1.0 + float(i_count) * 1.5
		var residents := float(r_count) * 1.2

		if jobs < residents:
			city_data.demand_i = clampf(50.0 + (residents - jobs) * 8.0, 15.0, 95.0)
			city_data.demand_c = clampf(35.0 + (residents - jobs) * 6.0, 15.0, 95.0)
			city_data.demand_r = clampf(65.0 - (residents - jobs) * 3.0, 20.0, 90.0)
		else:
			city_data.demand_r = clampf(55.0 + (jobs - residents) * 10.0, 20.0, 100.0)
			city_data.demand_i = clampf(city_data.demand_i - 5.0, 15.0, 90.0)
			city_data.demand_c = clampf(city_data.demand_c - 5.0, 15.0, 90.0)

func _update_tile_visual(x: int, y: int) -> void:
	var key := Vector2i(x, y)
	if tile_visuals.has(key):
		var old_node: Node3D = tile_visuals[key]
		tiles_root.remove_child(old_node)
		old_node.queue_free()
		tile_visuals.erase(key)

	var tile_info := city_data.get_tile(x, y)
	var type: int = tile_info.get("type", CityData.TileType.EMPTY)
	if type == CityData.TileType.EMPTY:
		return

	var level: int = tile_info.get("level", 0)
	var zone: int = tile_info.get("zone", CityData.BuildingZone.RESIDENTIAL)
	var has_util: bool = tile_info.get("has_utility", true)

	var variant: int = absi(x * 7 + y * 13) % 3
	var rshape: String = str(tile_info.get("road_shape", "lurus"))
	var node: Node3D = null
	if type == CityData.TileType.ROAD:
		node = BuildingBuilder.create_road_node(rshape, city_data.wide_roads.has(key), _traffic_is_green)
	elif type == CityData.TileType.FLYOVER:
		node = Node3D.new()
		node.add_child(BuildingBuilder.create_road_node(rshape, city_data.wide_roads.has(key), _traffic_is_green))
		node.add_child(BuildingBuilder.create_flyover_node(rshape))
	else:
		node = BuildingBuilder.create_tile_node(type, level, zone, has_util, variant)
	if not city_data.active_fire.is_empty():
		var af_pos: Vector2i = city_data.active_fire.get("pos", Vector2i(-1, -1))
		var af_extra: Vector2i = city_data.active_fire.get("extra_pos", Vector2i(-1, -1))
		if af_pos == key or (af_extra != Vector2i(-1, -1) and af_extra == key):
			var f_state: String = str(city_data.active_fire.get("state", ""))
			if f_state == "burning":
				node.add_child(BuildingBuilder.create_fire_effect_node())
			elif f_state == "damaged_light":
				node.add_child(BuildingBuilder.create_damaged_badge_node(false))
			elif f_state == "damaged_heavy":
				node.add_child(BuildingBuilder.create_damaged_badge_node(true))
	if not city_data.insiden_aktif.is_empty():
		var inc_pos: Vector2i = city_data.insiden_aktif.get("pos", Vector2i(-1, -1))
		var inc_type: String = str(city_data.insiden_aktif.get("type", ""))
		if inc_pos == key:
			if inc_type == "kemalingan":
				node.add_child(_create_incident_marker_node("Ada maling semalam!", Color(0.95, 0.72, 0.20)))
			elif inc_type == "kerusuhan":
				node.add_child(_create_incident_marker_node("Kami marah!", Color(0.96, 0.32, 0.26)))
	node.position = CityData.tile_to_world_pos(x, y)
	node.rotation_degrees.y = float(tile_info.get("rotation", 0))
	tiles_root.add_child(node)
	tile_visuals[key] = node

func _refresh_all_visuals() -> void:
	for child in tiles_root.get_children():
		tiles_root.remove_child(child)
		child.queue_free()
	tile_visuals.clear()

	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			_recompute_road_shape_at(x, y)
			_update_tile_visual(x, y)
	for k in city_data.extra_tiles.keys():
		_recompute_road_shape_at(k.x, k.y)
		_update_tile_visual(k.x, k.y)
	_refresh_underground_visuals()
	if emergency_manager:
		emergency_manager.sync_units()

func _sync_security_bonuses() -> void:
	if not city_data:
		return
	var has_police := city_data.has_working_public(CityData.TileType.POLICE)
	if has_police and not _police_bonus_active:
		city_data.security = clampf(city_data.security + 10.0, 0.0, 100.0)
		_police_bonus_active = true
	elif not has_police and _police_bonus_active:
		city_data.security = clampf(city_data.security - 10.0, 0.0, 100.0)
		_police_bonus_active = false

	var has_mil := city_data.has_working_public(CityData.TileType.MILITARY)
	if has_mil and not _military_bonus_active:
		city_data.security = clampf(city_data.security + 15.0, 0.0, 100.0)
		_military_bonus_active = true
	elif not has_mil and _military_bonus_active:
		city_data.security = clampf(city_data.security - 15.0, 0.0, 100.0)
		_military_bonus_active = false

func _apply_public_buildings_monthly() -> void:
	if city_data.has_working_public(CityData.TileType.SCHOOL):
		city_data.popularity = clampf(city_data.popularity + 2.0, 0.0, 100.0)
	if city_data.has_working_public(CityData.TileType.CLINIC):
		city_data.health = clampf(city_data.health + 3.0, 0.0, 100.0)
	if city_data.has_working_public(CityData.TileType.HOSPITAL):
		city_data.health = clampf(city_data.health + 8.0, 0.0, 100.0)
		city_data.popularity = clampf(city_data.popularity + 5.0, 0.0, 100.0)
	if city_data.has_working_public(CityData.TileType.MILITARY):
		city_data.popularity = clampf(city_data.popularity + 3.0, 0.0, 100.0)
	if city_data.has_working_public(CityData.TileType.MAYOR_OFFICE):
		city_data.popularity = clampf(city_data.popularity + 5.0, 0.0, 100.0)
	if not city_data.get_working_public_positions(CityData.TileType.ZONE_MILITARY).is_empty():
		city_data.popularity = clampf(city_data.popularity + 1.0, 0.0, 100.0)
	if city_data.has_working_airport():
		city_data.money += 50000
		city_data.popularity = clampf(city_data.popularity + 5.0, 0.0, 100.0)
	for comp in city_data.active_complaints:
		if comp.get("type", "") == ComplaintsData.COMPLAINT_PUNGLI and int(comp.get("wait_months", 0)) >= 3 and not comp.get("pungli_warned", false):
			comp["pungli_warned"] = true
			city_data.popularity = clampf(city_data.popularity - 10.0, 0.0, 100.0)
			show_toast.emit("Ada laporan pungli yang tidak ditangani — Popularitas -10")

func _process_fire_event_monthly() -> void:
	city_data.fire_cooldown_months = maxi(0, city_data.fire_cooldown_months - 1)

	if not city_data.active_fire.is_empty():
		var f_state: String = str(city_data.active_fire.get("state", ""))
		if f_state == "burning":
			var inc_active: bool = (str(city_data.insiden_aktif.get("type", "")) == "kebakaran")
			var damkar_sent: bool = bool(city_data.insiden_aktif.get("unit_dispatched", false)) if inc_active else false
			var elapsed: int = int(city_data.active_fire.get("elapsed", 0)) + 1
			city_data.active_fire["elapsed"] = elapsed

			# Korban luka sembuh sendiri 2 bulan jika tidak ada RS/Puskesmas
			if inc_active and bool(city_data.insiden_aktif.get("injured", false)) and not bool(city_data.insiden_aktif.get("ambulans_sent", false)):
				var inj_m: int = int(city_data.insiden_aktif.get("injured_months", 0)) + 1
				city_data.insiden_aktif["injured_months"] = inj_m
				if inj_m >= 2:
					city_data.insiden_aktif["injured"] = false
					city_data.happiness = clampf(city_data.happiness - 2.0, 0.0, 100.0)
					show_toast.emit("Warga luka akibat kebakaran sembuh sendiri (Kebahagiaan -2).")

			# Menyebar ke 1 bangunan tetangga jika tidak ditangani dalam 1 bulan
			if not damkar_sent and elapsed >= 1 and city_data.active_fire.get("extra_pos", Vector2i(-1, -1)) == Vector2i(-1, -1):
				var fpos: Vector2i = city_data.active_fire.get("pos", Vector2i(-1, -1))
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var np: Vector2i = fpos + d
					if city_data.is_valid_tile(np.x, np.y):
						var nt: Dictionary = city_data.get_tile(np.x, np.y)
						var ntp: int = int(nt.get("type", CityData.TileType.EMPTY))
						if int(nt.get("level", 0)) > 0 and ntp in [CityData.TileType.ZONE_R, CityData.TileType.ZONE_C, CityData.TileType.ZONE_I, CityData.TileType.BUILDING]:
							city_data.active_fire["extra_pos"] = np
							if inc_active:
								city_data.insiden_aktif["extra_pos"] = np
							show_toast.emit("Api menyebar ke bangunan di (%d, %d)!" % [np.x, np.y])
							_refresh_all_visuals()
							break

			var left: int = int(city_data.active_fire.get("months_left", 1)) - 1
			city_data.active_fire["months_left"] = left
			if left <= 0:
				if damkar_sent:
					city_data.active_fire["state"] = "damaged_light"
					show_toast.emit("Kebakaran padam! Bangunan rusak ringan (klik untuk perbaiki Rp 10.000).")
				else:
					city_data.active_fire["state"] = "damaged_heavy"
					show_toast.emit("Kebakaran padam! Bangunan rusak berat (klik untuk perbaiki Rp 25.000 / Bulldoze).")
				if str(city_data.insiden_aktif.get("type", "")) == "kebakaran":
					city_data.insiden_aktif.clear()
				if emergency_manager:
					emergency_manager.recall_units_for_resolved_incident()
				for i in range(city_data.active_complaints.size() - 1, -1, -1):
					if city_data.active_complaints[i].get("type", "") == ComplaintsData.COMPLAINT_FIRE:
						city_data.active_complaints.remove_at(i)
				if citizen_manager:
					citizen_manager.resolve_complaint(ComplaintsData.COMPLAINT_FIRE)
		return

	if city_data.fire_cooldown_months > 0 or city_data.population < 100 or not city_data.insiden_aktif.is_empty():
		return

	if randf() >= 0.12:
		return

	var targets: Array[Vector2i] = []
	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			var t: Dictionary = city_data.get_tile(x, y)
			var tp: int = t.get("type", CityData.TileType.EMPTY)
			if t.get("level", 0) > 0 and tp in [CityData.TileType.ZONE_R, CityData.TileType.ZONE_C, CityData.TileType.ZONE_I, CityData.TileType.BUILDING]:
				targets.append(Vector2i(x, y))
	if targets.is_empty():
		return

	var fire_pos: Vector2i = targets[randi() % targets.size()]
	var has_injured: bool = (randf() < 0.20)
	var amb_sent: bool = false
	city_data.active_fire = {
		"pos": fire_pos,
		"extra_pos": Vector2i(-1, -1),
		"state": "burning",
		"months_left": 3,
		"elapsed": 0,
		"had_damkar": false
	}
	city_data.insiden_aktif = {
		"type": "kebakaran",
		"title": "Kebakaran",
		"pos": fire_pos,
		"extra_pos": Vector2i(-1, -1),
		"status": "Menunggu Damkar",
		"unit_dispatched": false,
		"tni_dispatched": false,
		"injured": has_injured,
		"injured_months": 0,
		"ambulans_sent": false,
		"months_left": 3
	}
	if has_injured and emergency_manager and emergency_manager.has_unit_kind("ambulans"):
		var res: Dictionary = emergency_manager.dispatch_unit("ambulans", fire_pos)
		if bool(res.get("ok", false)):
			amb_sent = true
			city_data.insiden_aktif["ambulans_sent"] = true
	city_data.fire_cooldown_months = 12
	if citizen_manager:
		citizen_manager.trigger_fire_complaint("Blok (%d, %d)" % [fire_pos.x, fire_pos.y])
	AudioManager.play_sfx(self, "complaint")
	if has_injured:
		show_toast.emit("KEBAKARAN di (%d, %d)! %s" % [fire_pos.x, fire_pos.y, "Ambulans berangkat mengevakuasi korban luka!" if amb_sent else "1 warga luka ringan."])
	else:
		show_toast.emit("KEBAKARAN! Bangunan di (%d, %d) terbakar!" % [fire_pos.x, fire_pos.y])

func _repair_fire_damage() -> void:
	if city_data.active_fire.is_empty():
		return
	var f_state: String = str(city_data.active_fire.get("state", ""))
	var cost: int = 10000 if f_state == "damaged_light" else 25000
	if city_data.money < cost:
		AudioManager.play_sfx(self, "error")
		show_toast.emit("Uang tidak cukup untuk perbaikan! (Butuh Rp %s)" % _format_number(cost))
		return
	city_data.money -= cost
	city_data.active_fire.clear()
	_refresh_all_visuals()
	AudioManager.play_sfx(self, "build")
	show_toast.emit("Bangunan selesai diperbaiki! (-Rp %s)" % _format_number(cost))
	city_updated.emit(city_data)

func _create_incident_marker_node(bubble_text: String, col: Color) -> Node3D:
	var root := Node3D.new()
	var icon := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.42, 0.42, 0.42)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.9
	icon.mesh = box
	icon.material_override = mat
	icon.position = Vector3(0.0, 2.2, 0.0)
	root.add_child(icon)
	var lbl := Label3D.new()
	lbl.text = bubble_text
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 22
	lbl.outline_size = 4
	lbl.modulate = Color(1.0, 0.96, 0.78)
	lbl.position = Vector3(0.0, 2.85, 0.0)
	root.add_child(lbl)
	return root

func _process_incidents_monthly() -> void:
	city_data.theft_cooldown_months = maxi(0, city_data.theft_cooldown_months - 1)
	city_data.riot_cooldown_months = maxi(0, city_data.riot_cooldown_months - 1)

	# Bonus patroli polisi: +2 Keamanan/bulan jika ada minimal 1 mobil patroli aktif
	if emergency_manager and emergency_manager.has_patrol_active():
		city_data.security = clampf(city_data.security + 2.0, 0.0, 100.0)

	# Proses insiden aktif (kemalingan, kerusuhan, demo)
	if not city_data.insiden_aktif.is_empty():
		var inc_type: String = str(city_data.insiden_aktif.get("type", ""))
		if inc_type == "kebakaran":
			return
		var dispatched: bool = bool(city_data.insiden_aktif.get("unit_dispatched", false))
		var elapsed: int = int(city_data.insiden_aktif.get("months_elapsed", 0)) + 1
		city_data.insiden_aktif["months_elapsed"] = elapsed

		if inc_type == "kemalingan":
			if dispatched:
				var left: int = int(city_data.insiden_aktif.get("months_left", 1)) - 1
				city_data.insiden_aktif["months_left"] = left
				if left <= 0:
					if randf() < 0.70:
						city_data.money += 20000
						city_data.security = clampf(city_data.security + 3.0, 0.0, 100.0)
						city_data.popularity = clampf(city_data.popularity + 2.0, 0.0, 100.0)
						show_toast.emit("Pencuri tertangkap! Barang kembali (+Rp 20.000, Keamanan +3).")
					else:
						city_data.money = maxi(0, city_data.money - 20000)
						city_data.security = clampf(city_data.security - 2.0, 0.0, 100.0)
						show_toast.emit("Pencuri kabur (-Rp 20.000, Keamanan -2).")
					_clear_active_incident()
			elif elapsed >= 1:
				city_data.money = maxi(0, city_data.money - 20000)
				city_data.security = clampf(city_data.security - 5.0, 0.0, 100.0)
				city_data.happiness = clampf(city_data.happiness - 3.0, 0.0, 100.0)
				show_toast.emit("Kemalingan tidak tertangani (-Rp 20.000, Keamanan -5, Kebahagiaan -3).")
				_clear_active_incident()
		elif inc_type == "kerusuhan":
			var left_r: int = int(city_data.insiden_aktif.get("months_left", 2)) - 1
			city_data.insiden_aktif["months_left"] = left_r
			if dispatched and left_r <= 0:
				var rpos: Vector2i = city_data.insiden_aktif.get("pos", Vector2i(-1, -1))
				city_data.active_fire = {"pos": rpos, "extra_pos": Vector2i(-1, -1), "state": "damaged_light", "months_left": 0, "elapsed": 0, "had_damkar": true}
				city_data.security = clampf(city_data.security + 5.0, 0.0, 100.0)
				city_data.popularity = clampf(city_data.popularity - 3.0, 0.0, 100.0)
				show_toast.emit("Kerusuhan berhasil ditenangkan! Bangunan rusak ringan (Perbaiki Rp 10.000).")
				_clear_active_incident()
			elif not dispatched and elapsed >= 2:
				var rpos2: Vector2i = city_data.insiden_aktif.get("pos", Vector2i(-1, -1))
				city_data.active_fire = {"pos": rpos2, "extra_pos": Vector2i(-1, -1), "state": "damaged_heavy", "months_left": 0, "elapsed": 0, "had_damkar": false}
				city_data.security = clampf(city_data.security - 10.0, 0.0, 100.0)
				city_data.popularity = clampf(city_data.popularity - 10.0, 0.0, 100.0)
				city_data.happiness = clampf(city_data.happiness - 5.0, 0.0, 100.0)
				show_toast.emit("Kerusuhan merusak bangunan! (Rusak berat, Keamanan -10, Popularitas -10).")
				_clear_active_incident()
		elif inc_type == "demo":
			if dispatched:
				var left_d: int = int(city_data.insiden_aktif.get("months_left", 1)) - 1
				city_data.insiden_aktif["months_left"] = left_d
				if left_d <= 0:
					city_data.popularity = clampf(city_data.popularity + 2.0, 0.0, 100.0)
					city_data.event_aktif.clear()
					_rebuild_event_visuals()
					show_toast.emit("Polisi menenangkan massa demo! (Popularitas +2).")
					_clear_active_incident()
			elif elapsed > 2:
				# Demo dibiarkan > 2 bulan sebelum polisi dikirim -> berubah jadi Kerusuhan!
				city_data.event_aktif.clear()
				_rebuild_event_visuals()
				_spawn_incident("kerusuhan", city_data.insiden_aktif.get("pos", Vector2i(7, 7)))
				show_toast.emit("Demo memanas menjadi KERUSUHAN! Segera kirim Polisi / Bantuan TNI!")
		return

	if city_data.population < 40:
		return

	# Peluang Kerusuhan (paling jarang, maks 1x per 12 bulan, hanya jika Keamanan < 30 atau Kebahagiaan < 40)
	if city_data.riot_cooldown_months <= 0 and (city_data.security < 30.0 or city_data.happiness < 40.0):
		if randf() < 0.08:
			var r_target: Vector2i = _pick_random_rc_building()
			if r_target != Vector2i(-1, -1):
				city_data.riot_cooldown_months = 12
				_spawn_incident("kerusuhan", r_target)
				return

	# Peluang Kemalingan (maks 1x per 6 bulan)
	if city_data.theft_cooldown_months <= 0:
		var theft_chance: float = 0.08
		if city_data.security < 40.0:
			theft_chance = 0.16
		elif emergency_manager and emergency_manager.has_patrol_active():
			theft_chance = 0.04
		if randf() < theft_chance:
			var t_target: Vector2i = _pick_random_rc_building()
			if t_target != Vector2i(-1, -1):
				city_data.theft_cooldown_months = 6
				_spawn_incident("kemalingan", t_target)

func _pick_random_rc_building() -> Vector2i:
	var cands: Array[Vector2i] = []
	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			var t: Dictionary = city_data.get_tile(x, y)
			var tp: int = int(t.get("type", CityData.TileType.EMPTY))
			if int(t.get("level", 0)) > 0 and tp in [CityData.TileType.ZONE_R, CityData.TileType.ZONE_C, CityData.TileType.BUILDING]:
				cands.append(Vector2i(x, y))
	if cands.is_empty():
		return Vector2i(-1, -1)
	return cands[randi() % cands.size()]

func _spawn_incident(inc_type: String, pos: Vector2i) -> void:
	var title_txt: String = "Kemalingan" if inc_type == "kemalingan" else ("Kerusuhan" if inc_type == "kerusuhan" else "Demo Warga")
	var req_unit: String = "polisi"
	city_data.insiden_aktif = {
		"type": inc_type,
		"title": title_txt,
		"pos": pos,
		"extra_pos": Vector2i(-1, -1),
		"status": "Menunggu unit",
		"unit_dispatched": false,
		"tni_dispatched": false,
		"months_elapsed": 0,
		"months_left": 2 if inc_type == "kerusuhan" else 1,
		"req_unit": req_unit
	}
	AudioManager.play_sfx(self, "complaint")
	if citizen_manager:
		var msg_type: String = ComplaintsData.COMPLAINT_EVENT_DEMO if inc_type == "demo" else ComplaintsData.COMPLAINT_INSECURE
		citizen_manager.trigger_custom_complaint(msg_type, "Blok (%d, %d)" % [pos.x, pos.y])
	show_toast.emit("%s terjadi di (%d, %d)! Cek Balai Kota / klik lokasi." % [title_txt, pos.x, pos.y])
	_refresh_all_visuals()

func _clear_active_incident() -> void:
	city_data.insiden_aktif.clear()
	if emergency_manager:
		emergency_manager.recall_units_for_resolved_incident()
	_refresh_all_visuals()
	city_updated.emit(city_data)

func _on_emergency_unit_arrived(kind: String, _target_pos: Vector2i) -> void:
	if city_data.insiden_aktif.is_empty():
		return
	city_data.insiden_aktif["status"] = "Ditangani (%s di lokasi)" % kind.capitalize()
	show_toast.emit("Unit %s tiba di lokasi!" % kind.capitalize())
	city_updated.emit(city_data)

func dispatch_unit_to_incident(kind: String) -> void:
	if city_data.insiden_aktif.is_empty() or not emergency_manager:
		return
	var inc_type: String = str(city_data.insiden_aktif.get("type", ""))
	if inc_type == "kerusuhan" and not bool(city_data.insiden_aktif.get("unit_dispatched", false)):
		if city_data.money < 50000:
			AudioManager.play_sfx(self, "error")
			show_toast.emit("Uang kota tidak cukup")
			return
		city_data.money -= 50000

	var target: Vector2i = city_data.insiden_aktif.get("pos", Vector2i(7, 7))
	var res: Dictionary = emergency_manager.dispatch_unit(kind, target)
	if not bool(res.get("ok", false)):
		if inc_type == "kerusuhan" and not bool(city_data.insiden_aktif.get("unit_dispatched", false)):
			city_data.money += 50000
		AudioManager.play_sfx(self, "error")
		show_toast.emit(str(res.get("reason", "Unit tidak tersedia")))
		return

	if kind == "tni":
		city_data.insiden_aktif["tni_dispatched"] = true
		city_data.insiden_aktif["months_left"] = maxi(1, int(city_data.insiden_aktif.get("months_left", 2)) - 1)
		show_toast.emit("Truk Bantuan TNI berangkat! Kerusuhan reda lebih cepat.")
	else:
		city_data.insiden_aktif["unit_dispatched"] = true
		city_data.insiden_aktif["status"] = "%s berangkat" % kind.capitalize()
		if inc_type == "kebakaran":
			city_data.active_fire["had_damkar"] = true
			city_data.active_fire["months_left"] = 1
		elif inc_type == "demo":
			city_data.insiden_aktif["months_left"] = 1
		show_toast.emit("Unit %s berangkat menuju lokasi!" % kind.capitalize())
	AudioManager.play_sfx(self, "click")
	city_updated.emit(city_data)

func handle_demo_demands() -> void:
	if city_data.money < 30000:
		AudioManager.play_sfx(self, "error")
		show_toast.emit("Uang kota tidak cukup")
		return
	city_data.money -= 30000
	city_data.popularity = clampf(city_data.popularity + 5.0, 0.0, 100.0)
	if str(city_data.event_aktif.get("id", "")) == "demo":
		city_data.event_aktif.clear()
		_rebuild_event_visuals()
	_clear_active_incident()
	AudioManager.play_sfx(self, "build")
	show_toast.emit("Tuntutan warga didengarkan! Demo bubar (Popularitas +5).")

func ignore_active_incident() -> void:
	if city_data.insiden_aktif.is_empty():
		return
	AudioManager.play_sfx(self, "click")
	show_toast.emit("Insiden diabaikan untuk sementara — pantau kondisinya!")
	city_updated.emit(city_data)

func _refresh_underground_visuals() -> void:
	if not underground_root:
		underground_root = Node3D.new()
		underground_root.name = "UndergroundRoot"
		add_child(underground_root)

	for child in underground_root.get_children():
		underground_root.remove_child(child)
		child.queue_free()

	var show_net := underground_view_enabled or current_tool == ToolMode.POWER_CABLE or current_tool == ToolMode.WATER_PIPE
	if not show_net or not city_data:
		return

	var cable_mat := StandardMaterial3D.new()
	cable_mat.albedo_color = Color(1.0, 0.85, 0.15)
	cable_mat.emission_enabled = true
	cable_mat.emission = Color(0.95, 0.78, 0.10)
	cable_mat.emission_energy_multiplier = 0.6

	var pipe_mat := StandardMaterial3D.new()
	pipe_mat.albedo_color = Color(0.20, 0.65, 1.0)
	pipe_mat.emission_enabled = true
	pipe_mat.emission = Color(0.15, 0.55, 0.95)
	pipe_mat.emission_energy_multiplier = 0.6

	var hub_mesh := BoxMesh.new()
	hub_mesh.size = Vector3(0.24, 0.08, 0.24)
	var arm_x_mesh := BoxMesh.new()
	arm_x_mesh.size = Vector3(1.0, 0.06, 0.14)
	var arm_z_mesh := BoxMesh.new()
	arm_z_mesh.size = Vector3(0.14, 0.06, 1.0)

	_draw_network_layer(city_data.power_cables, cable_mat, Vector3(-0.14, 0.14, -0.14), hub_mesh, arm_x_mesh, arm_z_mesh)
	_draw_network_layer(city_data.water_pipes, pipe_mat, Vector3(0.14, 0.12, 0.14), hub_mesh, arm_x_mesh, arm_z_mesh)

func _draw_network_layer(net: Dictionary, mat: StandardMaterial3D, offset: Vector3, hub_mesh: BoxMesh, arm_x_mesh: BoxMesh, arm_z_mesh: BoxMesh) -> void:
	for pos in net.keys():
		var base := CityData.tile_to_world_pos(pos.x, pos.y) + offset
		var hub := MeshInstance3D.new()
		hub.mesh = hub_mesh
		hub.material_override = mat
		hub.position = base
		underground_root.add_child(hub)

		if net.has(pos + Vector2i(1, 0)):
			var arm_x := MeshInstance3D.new()
			arm_x.mesh = arm_x_mesh
			arm_x.material_override = mat
			arm_x.position = base + Vector3(0.5 * CityData.TILE_SIZE, 0.0, 0.0)
			underground_root.add_child(arm_x)
		if net.has(pos + Vector2i(0, 1)):
			var arm_z := MeshInstance3D.new()
			arm_z.mesh = arm_z_mesh
			arm_z.material_override = mat
			arm_z.position = base + Vector3(0.0, 0.0, 0.5 * CityData.TILE_SIZE)
			underground_root.add_child(arm_z)

func _format_number(val: int) -> String:
	var s := str(val)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "." + result
	return result

## Penyelesaian Pengaduan Warga dari Balai Kota
func resolve_complaint(complaint_id: String, option_idx: int) -> void:
	var target_index := -1
	var target_complaint: Dictionary = {}

	for idx in range(city_data.active_complaints.size()):
		var c: Dictionary = city_data.active_complaints[idx]
		if c.get("id") == complaint_id:
			target_complaint = c
			target_index = idx
			break

	if target_complaint.is_empty():
		return

	var c_type: String = target_complaint.get("type", "")
	var solutions: Array = ComplaintsData.COMPLAINT_SOLUTIONS.get(c_type, [])
	if option_idx >= solutions.size():
		return

	var chosen: Dictionary = solutions[option_idx]
	var cost: int = chosen.get("cost", 0)
	var pop_gain: int = chosen.get("pop_gain", 0)

	if city_data.money < cost:
		show_toast.emit("Uang tidak cukup! (Kurang Rp %s)" % _format_number(cost - city_data.money))
		return

	city_data.money -= cost
	city_data.popularity = clampf(city_data.popularity + float(pop_gain), 0.0, 100.0)
	var integ_gain: int = int(chosen.get("integ_gain", 0))
	if integ_gain != 0:
		city_data.integrity = clampf(city_data.integrity + float(integ_gain), 0.0, 100.0)
	city_data.happiness = clampf(city_data.happiness + (2.0 if pop_gain > 0 else -1.0), 0.0, 100.0)

	city_data.active_complaints.remove_at(target_index)
	if citizen_manager:
		citizen_manager.resolve_complaint(c_type)

	if c_type in [ComplaintsData.COMPLAINT_EVENT_BANJIR, ComplaintsData.COMPLAINT_EVENT_DEMO] and pop_gain > 0:
		_archive_active_event()
		_rebuild_event_visuals()

	var label_action: String = "positif (+%d)" % pop_gain if pop_gain >= 0 else "negatif (%d)" % pop_gain
	show_toast.emit("Pengaduan diselesaikan! Dampak Popularitas %s" % label_action)
	city_updated.emit(city_data)

## --- SISTEM MISI (Langkah 6: 6 misi, sekali klaim tiap misi) ---
func get_missions_status() -> Array:
	if not city_data:
		return []

	var house_count := 0
	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			var t: Dictionary = city_data.get_tile(x, y)
			var tp: int = t.get("type", CityData.TileType.EMPTY)
			var lv: int = t.get("level", 0)
			var zn: int = t.get("zone", CityData.BuildingZone.RESIDENTIAL)
			if lv > 0 and (tp == CityData.TileType.ZONE_R or (tp == CityData.TileType.BUILDING and zn == CityData.BuildingZone.RESIDENTIAL)):
				house_count += 1

	var has_power_and_water: bool = (city_data.power_supply >= 100 and city_data.water_supply >= 100)
	var is_kota_kecil: bool = (city_data.population >= 100 or city_data.city_level != "Desa")

	var defs := [
		{ "id": "pop_50", "title": "Capai 50 penduduk", "reward": 50000, "done": city_data.population >= 50 },
		{ "id": "pop_100", "title": "Capai 100 penduduk", "reward": 100000, "done": city_data.population >= 100 },
		{ "id": "houses_10", "title": "Bangun 10 rumah", "reward": 75000, "done": house_count >= 10 },
		{ "id": "util_1", "title": "1 Pembangkit + 1 Menara Air", "reward": 50000, "done": has_power_and_water },
		{ "id": "wheat_1", "title": "Panen gandum pertama", "reward": 25000, "done": city_data.wheat_harvest_count >= 1 },
		{ "id": "tier_kc", "title": "Capai level Kota Kecil", "reward": 150000, "done": is_kota_kecil },
		{ "id": "airport_1", "title": "Bangun Bandara pertama", "reward": 150000, "done": city_data.has_working_airport() }
	]

	var result: Array = []
	for d in defs:
		var mid: String = d["id"]
		result.append({
			"id": mid,
			"title": d["title"],
			"reward": d["reward"],
			"completed": d["done"],
			"claimed": bool(city_data.missions_claimed.get(mid, false))
		})
	return result

func claim_mission(mission_id: String) -> bool:
	if not city_data:
		return false
	if city_data.missions_claimed.get(mission_id, false):
		return false

	for m in get_missions_status():
		if m["id"] == mission_id and m["completed"]:
			var reward: int = m["reward"]
			city_data.missions_claimed[mission_id] = true
			city_data.money += reward
			SaveManager.save_season2(city_data)
			show_toast.emit("Misi selesai! Hadiah +Rp %s" % _format_number(reward))
			city_updated.emit(city_data)
			return true
	return false

func save_game(is_manual: bool = false) -> bool:
	if not city_data:
		return false
	var ok: bool = SaveManager.save_season2(city_data)
	if ok and is_manual:
		show_toast.emit("Permainan berhasil disimpan!")
	return ok

func _setup_weather_cycle() -> void:
	if weather_helper and is_instance_valid(weather_helper):
		return
	weather_helper = WeatherCycleHelper.new()
	weather_helper.name = "WeatherCycleHelper"
	add_child(weather_helper)
	var p: Node = get_parent()
	var w_env := p.get_node_or_null("WorldEnvironment") as WorldEnvironment if p else null
	var d_light := p.get_node_or_null("DirectionalLight3D") as DirectionalLight3D if p else null
	weather_helper.setup(w_env, d_light, city_data.waktu_jam, city_data.cuaca_saat_ini)
	weather_helper.night_state_changed.connect(func(_n: bool): _rebuild_night_lights())
	weather_helper.weather_changed.connect(func(w: String):
		_rebuild_wet_roads()
		if citizen_manager:
			citizen_manager.set_rain_umbrellas(w == "hujan")
	)
	_rebuild_night_lights()
	_rebuild_wet_roads()
	if citizen_manager:
		citizen_manager.set_rain_umbrellas(city_data.cuaca_saat_ini == "hujan")

func _rebuild_night_lights() -> void:
	if not night_lights_root:
		night_lights_root = Node3D.new()
		night_lights_root.name = "NightLightsRoot"
		add_child(night_lights_root)
	for child in night_lights_root.get_children():
		night_lights_root.remove_child(child)
		child.queue_free()
	if not weather_helper or not weather_helper.is_night or not city_data:
		return
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(1.0, 0.90, 0.45)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1.0, 0.85, 0.35)
	lamp_mat.emission_energy_multiplier = 1.2
	var lamp_mesh := BoxMesh.new()
	lamp_mesh.size = Vector3(0.18, 0.12, 0.18)
	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			var t: Dictionary = city_data.get_tile(x, y)
			var tp: int = t.get("type", CityData.TileType.EMPTY)
			if tp == CityData.TileType.ROAD and (x + y) % 2 == 0:
				var lm := MeshInstance3D.new()
				lm.mesh = lamp_mesh
				lm.material_override = lamp_mat
				lm.position = CityData.tile_to_world_pos(x, y) + Vector3(0.75, 0.65, 0.75)
				night_lights_root.add_child(lm)
			elif t.get("level", 0) > 0 and ((x * 5 + y * 3) % 2 == 0):
				var wm := MeshInstance3D.new()
				wm.mesh = lamp_mesh
				wm.material_override = lamp_mat
				wm.position = CityData.tile_to_world_pos(x, y) + Vector3(0.0, 0.55, 0.48)
				night_lights_root.add_child(wm)

func _rebuild_wet_roads() -> void:
	if not wet_road_root:
		wet_road_root = Node3D.new()
		wet_road_root.name = "WetRoadRoot"
		add_child(wet_road_root)
	for child in wet_road_root.get_children():
		wet_road_root.remove_child(child)
		child.queue_free()
	if not weather_helper or weather_helper.cuaca_saat_ini != "hujan" or not city_data:
		return
	var wet_mat := StandardMaterial3D.new()
	wet_mat.albedo_color = Color(0.08, 0.10, 0.14, 0.42)
	wet_mat.roughness = 0.15
	wet_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var wet_mesh := BoxMesh.new()
	wet_mesh.size = Vector3(1.98, 0.015, 1.98)
	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			var tp: int = city_data.get_tile(x, y).get("type", CityData.TileType.EMPTY)
			if tp in [CityData.TileType.ROAD, CityData.TileType.STOP_ANGKOT, CityData.TileType.STOP_BUS]:
				var wm := MeshInstance3D.new()
				wm.mesh = wet_mesh
				wm.material_override = wet_mat
				wm.position = CityData.tile_to_world_pos(x, y) + Vector3(0.0, 0.042, 0.0)
				wet_road_root.add_child(wm)

func _archive_active_event() -> void:
	if city_data.event_aktif.is_empty():
		return
	var entry := "%s (Bln %d Th %d)" % [str(city_data.event_aktif.get("title", "Event")), city_data.month, city_data.year]
	city_data.riwayat_event.push_front(entry)
	if city_data.riwayat_event.size() > 10:
		city_data.riwayat_event.resize(10)
	city_data.event_aktif.clear()

func _process_city_events_monthly() -> void:
	city_data.flood_cooldown = maxi(0, city_data.flood_cooldown - 1)
	if not city_data.event_aktif.is_empty():
		var ev_id: String = str(city_data.event_aktif.get("id", ""))
		if ev_id == "kuliner":
			city_data.money += 20000
		elif ev_id == "pasar_malam":
			city_data.popularity = clampf(city_data.popularity + 3.0, 0.0, 100.0)
		elif ev_id == "17an":
			city_data.popularity = clampf(city_data.popularity + 5.0, 0.0, 100.0)
		elif ev_id == "demo":
			city_data.popularity = clampf(city_data.popularity - 3.0, 0.0, 100.0)

		var left: int = int(city_data.event_aktif.get("months_left", 1)) - 1
		city_data.event_aktif["months_left"] = left
		if left <= 0:
			_archive_active_event()
			_rebuild_event_visuals()
		return

	city_data.event_cooldown -= 1
	if city_data.event_cooldown > 0:
		return

	var pool := [
		{"id": "kuliner", "title": "Festival Kuliner", "months": 1},
		{"id": "pasar_malam", "title": "Pasar Malam", "months": 1},
		{"id": "17an", "title": "Perayaan 17-an", "months": 1}
	]
	if city_data.flood_cooldown <= 0 and city_data.population >= 50:
		pool.append({"id": "banjir", "title": "Hujan Deras + Banjir Kecil", "months": 1})
	if city_data.popularity < 30.0:
		pool.append({"id": "demo", "title": "Demo Warga", "months": 2})

	var filtered: Array = []
	for item in pool:
		if item["id"] != city_data.last_event_id:
			filtered.append(item)
	if filtered.is_empty():
		filtered = pool

	var chosen: Dictionary = filtered[randi() % filtered.size()]
	var cid: String = chosen["id"]
	city_data.last_event_id = cid
	city_data.event_cooldown = randi_range(2, 4)
	if cid == "banjir":
		city_data.flood_cooldown = 12
	city_data.event_aktif = {
		"id": cid,
		"title": chosen["title"],
		"months_left": chosen["months"],
		"total_months": chosen["months"]
	}
	_rebuild_event_visuals()
	show_toast.emit("Event: %s dimulai!" % chosen["title"])
	if citizen_manager:
		if cid == "banjir":
			citizen_manager.trigger_custom_complaint(ComplaintsData.COMPLAINT_EVENT_BANJIR, "Jalan Raya")
		elif cid == "demo":
			var th_pos: Vector2i = Vector2i(7, 7)
			var th_list: Array[Vector2i] = city_data.get_public_positions(CityData.TileType.TOWNHALL)
			if not th_list.is_empty():
				th_pos = th_list[0]
			if city_data.insiden_aktif.is_empty():
				_spawn_incident("demo", th_pos)
			citizen_manager.trigger_custom_complaint(ComplaintsData.COMPLAINT_EVENT_DEMO, "Depan Balai Kota")

func _rebuild_event_visuals() -> void:
	if not event_props_root:
		event_props_root = Node3D.new()
		event_props_root.name = "EventPropsRoot"
		add_child(event_props_root)
	for child in event_props_root.get_children():
		event_props_root.remove_child(child)
		child.queue_free()
	if city_data.event_aktif.is_empty():
		return
	var ev_id: String = str(city_data.event_aktif.get("id", ""))
	var center := CityData.tile_to_world_pos(7, 7)
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	var mat := StandardMaterial3D.new()
	if ev_id == "kuliner":
		b.size = Vector3(1.2, 0.65, 1.2)
		mat.albedo_color = Color(0.95, 0.55, 0.20)
		m.position = center + Vector3(2.0, 0.35, 0.0)
	elif ev_id == "pasar_malam":
		b.size = Vector3(1.4, 0.70, 1.4)
		mat.albedo_color = Color(0.85, 0.25, 0.75)
		mat.emission_enabled = true
		mat.emission = Color(0.95, 0.45, 0.85)
		m.position = center + Vector3(-2.0, 0.35, 0.0)
	elif ev_id == "17an":
		b.size = Vector3(0.25, 1.6, 0.25)
		mat.albedo_color = Color(0.92, 0.15, 0.15)
		m.position = center + Vector3(0.0, 0.8, 2.0)
	elif ev_id == "banjir":
		b.size = Vector3(3.8, 0.06, 2.0)
		mat.albedo_color = Color(0.22, 0.48, 0.78, 0.72)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.position = center + Vector3(0.0, 0.05, 2.0)
	else:
		return
	m.mesh = b
	m.material_override = mat
	event_props_root.add_child(m)

func _process_citizen_wishes_monthly() -> void:
	city_data.ensure_citizen_wishes()
	for c in city_data.citizens_data:
		var cid: String = str(c.get("id", ""))
		if cid.is_empty() or not city_data.keinginan_warga.has(cid):
			continue
		var w: Dictionary = city_data.keinginan_warga[cid]
		if bool(w.get("fulfilled", false)):
			w["cooldown"] = int(w.get("cooldown", 0)) + 1
			if int(w["cooldown"]) >= 1:
				city_data.assign_new_wish(cid)
		elif city_data.is_wish_fulfilled(str(w.get("type", ""))):
			w["fulfilled"] = true
			w["cooldown"] = 0
			city_data.happiness = clampf(city_data.happiness + 2.0, 0.0, 100.0)
			city_data.popularity = clampf(city_data.popularity + 1.0, 0.0, 100.0)
			if citizen_manager:
				for walker in citizen_manager.walkers:
					if walker.citizen_data.get("id", "") == cid:
						walker.thank_you_timer = 3.5
						citizen_manager._show_bubble(walker, "%s: Makasih, Pak Wali! Keinginanku terpenuhi!" % str(c.get("name", "Warga")), false)
						break
		else:
			w["months"] = int(w.get("months", 0)) + 1
			if int(w["months"]) >= 3:
				city_data.assign_new_wish(cid)

func buy_kopaja_bus() -> void:
	if city_data.bus_kopaja_count >= 3:
		show_toast.emit("Maksimal 3 Bus Kota (Kopaja)!")
		return
	if city_data.count_public_type(CityData.TileType.STOP_BUS) < 1:
		AudioManager.play_sfx(self, "error")
		show_toast.emit("Bangun minimal 1 Halte Bus dulu!")
		return
	if city_data.money < CityData.COST_BUS_KOPAJA:
		AudioManager.play_sfx(self, "error")
		show_toast.emit("Uang tidak cukup!")
		return
	city_data.money -= CityData.COST_BUS_KOPAJA
	city_data.bus_kopaja_count += 1
	AudioManager.play_sfx(self, "build")
	show_toast.emit("Bus Kota (Kopaja) #%d beroperasi!" % city_data.bus_kopaja_count)
	city_updated.emit(city_data)

func buy_busway_unit() -> void:
	if city_data.busway_count >= 2:
		show_toast.emit("Maksimal 2 Busway!")
		return
	if city_data.count_public_type(CityData.TileType.STOP_BUSWAY) < 1:
		AudioManager.play_sfx(self, "error")
		show_toast.emit("Bangun Halte Busway dulu!")
		return
	if city_data.money < CityData.COST_BUSWAY_UNIT:
		AudioManager.play_sfx(self, "error")
		show_toast.emit("Uang tidak cukup!")
		return
	city_data.money -= CityData.COST_BUSWAY_UNIT
	city_data.busway_count += 1
	AudioManager.play_sfx(self, "build")
	show_toast.emit("Busway #%d beroperasi!" % city_data.busway_count)
	city_updated.emit(city_data)

func buy_airplane() -> void:
	if city_data.airplane_count >= 2:
		show_toast.emit("Maksimal 2 Pesawat!")
		return
	if city_data.count_public_type(CityData.TileType.RUNWAY) < 20 or city_data.count_public_type(CityData.TileType.AIRPORT_TERMINAL) < 1:
		AudioManager.play_sfx(self, "error")
		show_toast.emit("Butuh 20 tile Landasan + Terminal Bandara!")
		return
	if city_data.money < CityData.COST_AIRPLANE:
		AudioManager.play_sfx(self, "error")
		show_toast.emit("Uang tidak cukup!")
		return
	city_data.money -= CityData.COST_AIRPLANE
	city_data.airplane_count += 1
	AudioManager.play_sfx(self, "build")
	show_toast.emit("Pesawat #%d siap lepas landas!" % city_data.airplane_count)
	city_updated.emit(city_data)

## Bangun visual landscape peta (Pantai, Pegunungan, Sungai, Dataran Hijau, Hutan) — shared mesh/material
func _build_landscape_visuals() -> void:
	if landscape_root and is_instance_valid(landscape_root):
		landscape_root.queue_free()
	forest_trees.clear()

	landscape_root = Node3D.new()
	landscape_root.name = "LandscapeRoot"
	add_child(landscape_root)

	var l_type: String = city_data.map_landscape

	# Alas rumput dasar 3x3 wilayah (96x96m) agar wilayah terkunci tetap punya warna tanah di bawah kabut
	var outer_ground := MeshInstance3D.new()
	var og_box := BoxMesh.new()
	og_box.size = Vector3(96.0, 0.04, 96.0)
	var og_mat := StandardMaterial3D.new()
	og_mat.albedo_color = Color(0.28, 0.54, 0.25)
	og_mat.roughness = 0.95
	outer_ground.mesh = og_box
	outer_ground.material_override = og_mat
	outer_ground.position = Vector3(16.0, -0.025, 16.0)
	landscape_root.add_child(outer_ground)

	if l_type == "dataran":
		return

	var tile_box := BoxMesh.new()
	tile_box.size = Vector3(2.0, 0.04, 2.0)

	if l_type == "pantai":
		var deep_mat := StandardMaterial3D.new()
		deep_mat.albedo_color = Color(0.08, 0.34, 0.76)
		deep_mat.roughness = 0.30
		var sea_mat := StandardMaterial3D.new()
		sea_mat.albedo_color = Color(0.24, 0.68, 0.94)
		sea_mat.roughness = 0.25
		var sand_mat := StandardMaterial3D.new()
		sand_mat.albedo_color = Color(0.92, 0.84, 0.56)
		sand_mat.roughness = 0.9

		# Gradasi laut dalam (z=0..2) dan dangkal (z=2..4)
		var deep_sea := MeshInstance3D.new()
		var ds_box := BoxMesh.new()
		ds_box.size = Vector3(96.0, 0.05, 2.2)
		deep_sea.mesh = ds_box
		deep_sea.material_override = deep_mat
		deep_sea.position = Vector3(16.0, 0.018, 1.0)
		landscape_root.add_child(deep_sea)

		var sea := MeshInstance3D.new()
		var sea_box := BoxMesh.new()
		sea_box.size = Vector3(96.0, 0.05, 2.0)
		sea.mesh = sea_box
		sea.material_override = sea_mat
		sea.position = Vector3(16.0, 0.02, 3.0)
		landscape_root.add_child(sea)

		# Ombak putih tipis di tepi pantai
		var wave := MeshInstance3D.new()
		var w_box := BoxMesh.new()
		w_box.size = Vector3(96.0, 0.055, 0.35)
		var w_mat := StandardMaterial3D.new()
		w_mat.albedo_color = Color(0.95, 0.98, 1.0, 0.82)
		w_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wave.mesh = w_box
		wave.material_override = w_mat
		wave.position = Vector3(16.0, 0.025, 3.95)
		landscape_root.add_child(wave)
		_wave_strip = wave

		# Pantai pasir (y=2..3, membentang 96m kiri-kanan)
		var sand := MeshInstance3D.new()
		var sand_box := BoxMesh.new()
		sand_box.size = Vector3(96.0, 0.04, 4.0)
		sand.mesh = sand_box
		sand.material_override = sand_mat
		sand.position = Vector3(16.0, 0.018, 6.0)
		landscape_root.add_child(sand)

		# Pohon kelapa di tepi pantai
		for px in [1, 4, 8, 11, 14]:
			var palm := S1VisualBuilder.create_tree(0)
			palm.position = CityData.tile_to_world_pos(px, 3) + Vector3(0.4, 0.0, 0.5)
			landscape_root.add_child(palm)

	elif l_type == "pegunungan":
		var dark_grass := StandardMaterial3D.new()
		dark_grass.albedo_color = Color(0.22, 0.46, 0.22)
		var hill_mat := StandardMaterial3D.new()
		hill_mat.albedo_color = Color(0.46, 0.40, 0.34)
		var snow_mat := StandardMaterial3D.new()
		snow_mat.albedo_color = Color(0.75, 0.77, 0.80)
		var hill_mesh := PrismMesh.new()
		hill_mesh.size = Vector3(2.4, 2.6, 2.4)

		var ground_tint := MeshInstance3D.new()
		var gt_box := BoxMesh.new()
		gt_box.size = Vector3(32.0, 0.02, 8.0)
		ground_tint.mesh = gt_box
		ground_tint.material_override = dark_grass
		ground_tint.position = Vector3(16.0, 0.01, 4.0)
		landscape_root.add_child(ground_tint)

		var foot_dirt := MeshInstance3D.new()
		var fd_box := BoxMesh.new()
		fd_box.size = Vector3(32.0, 0.024, 2.2)
		var fd_mat := StandardMaterial3D.new()
		fd_mat.albedo_color = Color(0.45, 0.36, 0.26)
		foot_dirt.mesh = fd_box
		foot_dirt.material_override = fd_mat
		foot_dirt.position = Vector3(16.0, 0.014, 4.2)
		landscape_root.add_child(foot_dirt)

		for y in range(3):
			for x in range(CityData.GRID_SIZE):
				if y <= 1 or (y == 2 and (x < 4 or x > 11)):
					var m := MeshInstance3D.new()
					m.mesh = hill_mesh
					m.material_override = snow_mat if (y == 0 and x % 3 == 0) else hill_mat
					m.position = CityData.tile_to_world_pos(x, y) + Vector3(0.0, 1.25, 0.0)
					m.scale = Vector3(1.0, 1.3 if y == 0 else 0.85, 1.0)
					landscape_root.add_child(m)
		for px in [1, 3, 5, 7, 9, 11, 13, 15]:
			var pine := S1VisualBuilder.create_tree(0)
			pine.position = CityData.tile_to_world_pos(px, 3) + Vector3(-0.3, 0.0, -0.4)
			landscape_root.add_child(pine)

	elif l_type == "sungai":
		var river_mat := StandardMaterial3D.new()
		river_mat.albedo_color = Color(0.16, 0.52, 0.88)
		river_mat.roughness = 0.3
		var bank_mat := StandardMaterial3D.new()
		bank_mat.albedo_color = Color(0.56, 0.44, 0.30)
		var bridge_mat := StandardMaterial3D.new()
		bridge_mat.albedo_color = Color(0.58, 0.40, 0.22)

		# Sungai membelah peta di x=7..8
		var river := MeshInstance3D.new()
		var r_box := BoxMesh.new()
		r_box.size = Vector3(4.0, 0.04, 32.0)
		river.mesh = r_box
		river.material_override = river_mat
		river.position = Vector3(16.0, 0.02, 16.0)
		landscape_root.add_child(river)

		# Garis arus sungai mengalir pelan
		_river_flow = Node3D.new()
		var flow_box := BoxMesh.new()
		flow_box.size = Vector3(0.22, 0.048, 1.3)
		var flow_mat := StandardMaterial3D.new()
		flow_mat.albedo_color = Color(0.55, 0.82, 0.98, 0.65)
		flow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		for fz in [2.0, 8.0, 14.0, 20.0, 26.0]:
			var fl := MeshInstance3D.new()
			fl.mesh = flow_box
			fl.material_override = flow_mat
			fl.position = Vector3(16.0, 0.026, fz)
			_river_flow.add_child(fl)
		landscape_root.add_child(_river_flow)

		# Tepi sungai coklat lembut (x=6 dan x=9)
		for bx in [13.0, 19.0]:
			var bank := MeshInstance3D.new()
			var b_box := BoxMesh.new()
			b_box.size = Vector3(2.0, 0.02, 32.0)
			bank.mesh = b_box
			bank.material_override = bank_mat
			bank.position = Vector3(bx, 0.01, 16.0)
			landscape_root.add_child(bank)

		# 2 jembatan visual di y=5 dan y=10
		for by in [5, 10]:
			var br := MeshInstance3D.new()
			var br_box := BoxMesh.new()
			br_box.size = Vector3(4.2, 0.10, 1.9)
			br.mesh = br_box
			br.material_override = bridge_mat
			br.position = Vector3(16.0, 0.06, float(by) * 2.0 + 1.0)
			landscape_root.add_child(br)

	elif l_type == "hutan":
		var f_mat := StandardMaterial3D.new()
		f_mat.albedo_color = Color(0.20, 0.45, 0.20)
		var f_ground := MeshInstance3D.new()
		var fg_box := BoxMesh.new()
		fg_box.size = Vector3(32.0, 0.02, 32.0)
		f_ground.mesh = fg_box
		f_ground.material_override = f_mat
		f_ground.position = Vector3(16.0, 0.01, 16.0)
		landscape_root.add_child(f_ground)

		# Sebar pohon di tepi & tersebar (~42 pohon, bisa ditebang pakai Bulldozer)
		for y in range(CityData.GRID_SIZE):
			for x in range(CityData.GRID_SIZE):
				if city_data.get_tile(x, y).get("type", CityData.TileType.EMPTY) != CityData.TileType.EMPTY:
					continue
				var is_edge: bool = (x == 0 or y == 0 or x == CityData.GRID_SIZE - 1 or y == CityData.GRID_SIZE - 1)
				if (is_edge and (x + y) % 2 == 0) or ((x * 7 + y * 13) % 11 == 0):
					var tree := S1VisualBuilder.create_tree(x + y)
					tree.position = CityData.tile_to_world_pos(x, y)
					landscape_root.add_child(tree)
					forest_trees["%d,%d" % [x, y]] = tree

## Tampilkan lahan terkunci di sekeliling wilayah awal (8 arah, gembok geometris + harga)
func _build_locked_regions_visuals() -> void:
	if regions_root and is_instance_valid(regions_root):
		regions_root.queue_free()
	regions_root = Node3D.new()
	regions_root.name = "RegionsRoot"
	add_child(regions_root)

	var fog_adj_mat := StandardMaterial3D.new()
	fog_adj_mat.albedo_color = Color(0.14, 0.18, 0.20, 0.45)
	fog_adj_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var fog_far_mat := StandardMaterial3D.new()
	fog_far_mat.albedo_color = Color(0.08, 0.10, 0.12, 0.62)
	fog_far_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var lock_gold := StandardMaterial3D.new()
	lock_gold.albedo_color = Color(0.95, 0.78, 0.22)
	var lock_grey := StandardMaterial3D.new()
	lock_grey.albedo_color = Color(0.50, 0.52, 0.56)

	var region_plane := BoxMesh.new()
	region_plane.size = Vector3(31.8, 0.04, 31.8)
	var lock_body := BoxMesh.new()
	lock_body.size = Vector3(1.6, 1.4, 0.8)
	var lock_shackle := BoxMesh.new()
	lock_shackle.size = Vector3(1.1, 0.9, 0.4)

	var max_reached: bool = (city_data.unlocked_regions.size() >= 9)
	var next_price: int = city_data.get_next_region_price()

	for ry in range(-1, 2):
		for rx in range(-1, 2):
			var r := Vector2i(rx, ry)
			if city_data.is_region_unlocked(r) or not city_data.is_region_allowed_by_landscape(r):
				continue

			var adj: bool = city_data.is_region_adjacent(r)
			var center := Vector3(float(rx) * 32.0 + 16.0, 0.0, float(ry) * 32.0 + 16.0)

			var fog := MeshInstance3D.new()
			fog.mesh = region_plane
			fog.material_override = fog_adj_mat if adj else fog_far_mat
			fog.position = center + Vector3(0.0, 0.03, 0.0)
			regions_root.add_child(fog)

			# Ikon gembok geometris
			var body := MeshInstance3D.new()
			body.mesh = lock_body
			body.material_override = lock_gold if (adj and not max_reached) else lock_grey
			body.position = center + Vector3(0.0, 0.9, 0.0)
			regions_root.add_child(body)

			var shackle := MeshInstance3D.new()
			shackle.mesh = lock_shackle
			shackle.material_override = lock_grey
			shackle.position = center + Vector3(0.0, 1.9, 0.0)
			regions_root.add_child(shackle)

			if adj:
				var lbl := Label3D.new()
				lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				lbl.font_size = 36
				lbl.outline_size = 5
				lbl.outline_modulate = Color(0.05, 0.05, 0.08)
				if max_reached:
					lbl.text = "Wilayah maksimal tercapai"
					lbl.modulate = Color(0.85, 0.55, 0.55)
				else:
					lbl.text = "Rp %s" % _format_number(next_price)
					lbl.modulate = Color(1.0, 0.88, 0.30)
				lbl.position = center + Vector3(0.0, 3.0, 0.0)
				regions_root.add_child(lbl)

func _count_adjacent_roads(x: int, y: int) -> int:
	var c := 0
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var tp: int = city_data.get_tile(x + d.x, y + d.y).get("type", CityData.TileType.EMPTY)
		if tp in [CityData.TileType.ROAD, CityData.TileType.STOP_ANGKOT, CityData.TileType.STOP_BUS]:
			c += 1
	return c

func _update_traffic_lamp_colors() -> void:
	var col := Color(0.20, 0.92, 0.30) if _traffic_is_green else Color(0.95, 0.22, 0.20)
	for k in tile_visuals.keys():
		var nd: Node3D = tile_visuals[k]
		if nd and is_instance_valid(nd):
			var lamp := nd.find_child("TrafficLamp", true, false) as MeshInstance3D
			if lamp and lamp.material_override is StandardMaterial3D:
				var sm := lamp.material_override as StandardMaterial3D
				sm.albedo_color = col
				sm.emission = col

func _on_tile_dragged(screen_pos: Vector2) -> void:
	if not (current_tool in [ToolMode.ROAD, ToolMode.FLYOVER, ToolMode.BUSWAY_LANE, ToolMode.RAIL, ToolMode.POWER_CABLE, ToolMode.WATER_PIPE, ToolMode.RUNWAY, ToolMode.WIDEN_ROAD]):
		return
	if not camera_controller or not camera_controller.camera:
		return
	var cam: Camera3D = camera_controller.camera
	var ray_origin := cam.project_ray_origin(screen_pos)
	var ray_dir := cam.project_ray_normal(screen_pos)
	if abs(ray_dir.y) < 0.0001:
		return
	var t: float = -ray_origin.y / ray_dir.y
	if t <= 0.0:
		return
	var tc := CityData.world_pos_to_tile(ray_origin + ray_dir * t)
	if tc == _last_drag_tile:
		return
	_last_drag_tile = tc
	if city_data.is_valid_tile(tc.x, tc.y):
		_apply_tool(tc.x, tc.y)

func _is_road_like(x: int, y: int) -> bool:
	if not city_data.is_valid_tile(x, y):
		return false
	var tp: int = city_data.get_tile(x, y).get("type", CityData.TileType.EMPTY)
	return tp in [CityData.TileType.ROAD, CityData.TileType.STOP_ANGKOT, CityData.TileType.STOP_BUS, CityData.TileType.FLYOVER]

func _recompute_road_and_neighbors(x: int, y: int) -> void:
	_recompute_road_shape_at(x, y)
	for d: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		var nx: int = x + d.x
		var ny: int = y + d.y
		if city_data.is_valid_tile(nx, ny):
			_recompute_road_shape_at(nx, ny)
			_update_tile_visual(nx, ny)

func _recompute_road_shape_at(x: int, y: int) -> void:
	if not city_data.is_valid_tile(x, y):
		return
	var tile: Dictionary = city_data.get_tile(x, y)
	var tp: int = int(tile.get("type", CityData.TileType.EMPTY))
	if not (tp in [CityData.TileType.ROAD, CityData.TileType.FLYOVER]):
		return
	var n: bool = _is_road_like(x, y - 1)
	var e: bool = _is_road_like(x + 1, y)
	var s: bool = _is_road_like(x, y + 1)
	var w: bool = _is_road_like(x - 1, y)
	var cnt: int = int(n) + int(e) + int(s) + int(w)
	var shape: String = "lurus"
	var rot: int = 0
	if cnt == 4:
		shape = "perempatan"
		rot = 0
	elif cnt == 3:
		shape = "t_junction"
		if not w:
			rot = 0
		elif not n:
			rot = 270
		elif not e:
			rot = 180
		else:
			rot = 90
	elif cnt == 2:
		if n and s:
			shape = "lurus"
			rot = 0
		elif e and w:
			shape = "lurus"
			rot = 90
		elif n and e:
			shape = "tikungan"
			rot = 0
		elif e and s:
			shape = "tikungan"
			rot = 270
		elif s and w:
			shape = "tikungan"
			rot = 180
		else:
			shape = "tikungan"
			rot = 90
	elif cnt == 1:
		shape = "lurus"
		rot = 90 if (e or w) else 0
	tile["road_shape"] = shape
	tile["rotation"] = rot
