class_name CityManager
extends Node3D

## Manajer simulasi kota, input tool, utilitas, ekonomi bulanan, dan HUD

signal city_updated(city_data: CityData)
signal show_toast(message: String)
signal open_pak_slamet_modal()
signal open_citizen_modal(citizen_info: Dictionary, complaint_info: Dictionary)
signal open_townhall_modal()
signal open_region_buy_modal(region: Vector2i, price: int)

enum ToolMode {
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

	_ensure_townhall_exists()
	city_data.update_utilities()
	_police_bonus_active = city_data.has_working_public(CityData.TileType.POLICE)
	_military_bonus_active = city_data.has_working_public(CityData.TileType.MILITARY)
	city_data.happiness = city_data.calculate_happiness()
	city_data.city_level = CityData.get_city_tier(city_data.population)

	_build_landscape_visuals()
	_build_locked_regions_visuals()
	_refresh_all_visuals()
	city_updated.emit(city_data)
	if loaded_from_save:
		show_toast.emit("Kota berhasil dimuat dari save!")
	elif carried_from_s1:
		SaveManager.save_season2(city_data)
		show_toast.emit("Selamat datang Walikota %s! Modal awal kotamu: Rp %s" % [city_data.mayor_name, _format_number(city_data.money)])

func _process(delta: float) -> void:
	if city_data.game_speed > 0.0:
		month_timer += delta * city_data.game_speed
		if month_timer >= MONTH_DURATION:
			month_timer = 0.0
			_advance_month()

func set_tool(tool_mode: ToolMode) -> void:
	current_tool = tool_mode
	_refresh_underground_visuals()

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

	if not city_data.is_region_unlocked(reg):
		if city_data.is_region_allowed_by_landscape(reg):
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

	# 4. Cek apakah klik mengenai bangunan rusak akibat kebakaran (untuk diperbaiki)
	if current_tool != ToolMode.BULLDOZER and not city_data.active_fire.is_empty():
		if city_data.active_fire.get("pos", Vector2i(-1, -1)) == tile_coords:
			var f_state: String = str(city_data.active_fire.get("state", ""))
			if f_state in ["damaged_light", "damaged_heavy"]:
				_repair_fire_damage()
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
	city_data.set_tile(x, y, target_type, target_level, target_zone)
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
	city_data.update_utilities()
	_sync_security_bonuses()
	city_data.happiness = city_data.calculate_happiness()
	if target_type in [CityData.TileType.ROAD, CityData.TileType.POWER_PLANT, CityData.TileType.WATER_TOWER] or (target_type in CityData.PUBLIC_BUILDING_TYPES):
		_refresh_all_visuals()
	else:
		_update_tile_visual(x, y)
	_update_demand()
	AudioManager.play_sfx(self, "build")
	city_updated.emit(city_data)

func _harvest_farm(x: int, y: int) -> void:
	city_data.wheat_inventory += CityData.WHEAT_PER_HARVEST
	city_data.wheat_harvest_count += 1
	city_data.set_tile(x, y, CityData.TileType.FARM, 1) # Kembali ke tahap Benih
	_update_tile_visual(x, y)

	# Tampilkan teks melayang "+10 Gandum" di atas lahan
	var popup: Label3D = BuildingBuilder.create_harvest_popup(CityData.WHEAT_PER_HARVEST)
	popup.position = CityData.tile_to_world_pos(x, y)
	add_child(popup)
	var tween := create_tween()
	tween.tween_property(popup, "position:y", popup.position.y + 1.2, 1.2)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 1.2)
	tween.tween_callback(popup.queue_free)

	AudioManager.play_sfx(self, "harvest")
	show_toast.emit("+%d Gandum masuk gudang!" % CityData.WHEAT_PER_HARVEST)
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

	if citizen_manager:
		var prev_comp_count: int = city_data.active_complaints.size()
		citizen_manager.update_citizen_complaints()
		if city_data.active_complaints.size() > prev_comp_count:
			AudioManager.play_sfx(self, "complaint")

	# Update ulang utilitas dan tampilan visual semua tile (supaya ikon peringatan muncul/hilang tepat)
	city_data.update_utilities()
	_sync_security_bonuses()
	city_data.happiness = city_data.calculate_happiness()
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

	var node := BuildingBuilder.create_wide_road_mesh() if (type == CityData.TileType.ROAD and city_data.wide_roads.has(key)) else BuildingBuilder.create_tile_node(type, level, zone, has_util)
	if not city_data.active_fire.is_empty() and city_data.active_fire.get("pos", Vector2i(-1, -1)) == key:
		var f_state: String = str(city_data.active_fire.get("state", ""))
		if f_state == "burning":
			node.add_child(BuildingBuilder.create_fire_effect_node())
		elif f_state == "damaged_light":
			node.add_child(BuildingBuilder.create_damaged_badge_node(false))
		elif f_state == "damaged_heavy":
			node.add_child(BuildingBuilder.create_damaged_badge_node(true))
	node.position = CityData.tile_to_world_pos(x, y)
	tiles_root.add_child(node)
	tile_visuals[key] = node

func _refresh_all_visuals() -> void:
	for child in tiles_root.get_children():
		tiles_root.remove_child(child)
		child.queue_free()
	tile_visuals.clear()

	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			_update_tile_visual(x, y)
	for k in city_data.extra_tiles.keys():
		_update_tile_visual(k.x, k.y)
	_refresh_underground_visuals()

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
			var left: int = int(city_data.active_fire.get("months_left", 1)) - 1
			city_data.active_fire["months_left"] = left
			if left <= 0:
				var had_damkar: bool = bool(city_data.active_fire.get("had_damkar", false)) or city_data.has_working_public(CityData.TileType.FIRE_STATION)
				if had_damkar:
					city_data.active_fire["state"] = "damaged_light"
					show_toast.emit("Kebakaran padam! Bangunan rusak ringan (klik untuk perbaiki Rp 10.000).")
				else:
					city_data.active_fire["state"] = "damaged_heavy"
					show_toast.emit("Kebakaran padam! Bangunan rusak berat (klik untuk perbaiki Rp 25.000 / Bulldoze).")
				for i in range(city_data.active_complaints.size() - 1, -1, -1):
					if city_data.active_complaints[i].get("type", "") == ComplaintsData.COMPLAINT_FIRE:
						city_data.active_complaints.remove_at(i)
				if citizen_manager:
					citizen_manager.resolve_complaint(ComplaintsData.COMPLAINT_FIRE)
		return

	if city_data.fire_cooldown_months > 0 or city_data.population < 100:
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
	var has_damkar := city_data.has_working_public(CityData.TileType.FIRE_STATION)
	city_data.active_fire = {
		"pos": fire_pos,
		"state": "burning",
		"months_left": 1 if has_damkar else 3,
		"had_damkar": has_damkar
	}
	city_data.fire_cooldown_months = 12
	if citizen_manager:
		citizen_manager.trigger_fire_complaint("Blok (%d, %d)" % [fire_pos.x, fire_pos.y])
	AudioManager.play_sfx(self, "complaint")
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

## Bangun visual landscape peta (Pantai, Pegunungan, Sungai, Dataran Hijau, Hutan) — shared mesh/material
func _build_landscape_visuals() -> void:
	if landscape_root and is_instance_valid(landscape_root):
		landscape_root.queue_free()
	forest_trees.clear()

	landscape_root = Node3D.new()
	landscape_root.name = "LandscapeRoot"
	add_child(landscape_root)

	var l_type: String = city_data.map_landscape
	if l_type == "dataran":
		return

	var tile_box := BoxMesh.new()
	tile_box.size = Vector3(2.0, 0.04, 2.0)

	if l_type == "pantai":
		var sea_mat := StandardMaterial3D.new()
		sea_mat.albedo_color = Color(0.14, 0.48, 0.85)
		sea_mat.roughness = 0.35
		var sand_mat := StandardMaterial3D.new()
		sand_mat.albedo_color = Color(0.92, 0.84, 0.56)
		sand_mat.roughness = 0.9

		# Laut biru (y=0..1)
		var sea := MeshInstance3D.new()
		var sea_box := BoxMesh.new()
		sea_box.size = Vector3(32.0, 0.05, 4.0)
		sea.mesh = sea_box
		sea.material_override = sea_mat
		sea.position = Vector3(16.0, 0.02, 2.0)
		landscape_root.add_child(sea)

		# Pantai pasir (y=2..3)
		var sand := MeshInstance3D.new()
		var sand_box := BoxMesh.new()
		sand_box.size = Vector3(32.0, 0.04, 4.0)
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

		for y in range(3):
			for x in range(CityData.GRID_SIZE):
				if y <= 1 or (y == 2 and (x < 4 or x > 11)):
					var m := MeshInstance3D.new()
					m.mesh = hill_mesh
					m.material_override = snow_mat if (y == 0 and x % 3 == 0) else hill_mat
					m.position = CityData.tile_to_world_pos(x, y) + Vector3(0.0, 1.25, 0.0)
					m.scale = Vector3(1.0, 1.3 if y == 0 else 0.85, 1.0)
					landscape_root.add_child(m)
		for px in [2, 5, 7, 10, 13]:
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
	fog_adj_mat.albedo_color = Color(0.16, 0.20, 0.22, 0.85)
	fog_adj_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var fog_far_mat := StandardMaterial3D.new()
	fog_far_mat.albedo_color = Color(0.08, 0.10, 0.12, 0.92)
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
