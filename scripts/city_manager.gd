class_name CityManager
extends Node3D

## Manajer simulasi kota, input tool, pertumbuhan otomatis, dan integrasi UI

signal city_updated(city_data: CityData)
signal show_toast(message: String)

enum ToolMode {
	ROAD,
	ZONE_R,
	ZONE_C,
	ZONE_I,
	POWER_PLANT,
	WATER_TOWER,
	BULLDOZER
}

var current_tool: ToolMode = ToolMode.ROAD
var city_data: CityData
var tile_visuals: Dictionary = {} # Vector2i -> Node3D

@onready var tiles_root: Node3D = $TilesRoot
@onready var car_controller: CarController = $CarController
@export var camera_controller: CameraController

# Siklus bulan permainan (1 bulan = 10 detik di Langkah 2)
var month_timer: float = 0.0
const MONTH_DURATION: float = 10.0

func _ready() -> void:
	city_data = CityData.new()

	if car_controller:
		car_controller.setup(city_data)

	if camera_controller:
		camera_controller.tile_clicked.connect(_on_tile_clicked)

	_refresh_all_visuals()
	city_updated.emit(city_data)

func _process(delta: float) -> void:
	month_timer += delta
	if month_timer >= MONTH_DURATION:
		month_timer = 0.0
		_advance_month()

func set_tool(tool_mode: ToolMode) -> void:
	current_tool = tool_mode

func _on_tile_clicked(screen_pos: Vector2) -> void:
	if not camera_controller or not camera_controller.camera:
		return

	var cam: Camera3D = camera_controller.camera
	var ray_origin := cam.project_ray_origin(screen_pos)
	var ray_dir := cam.project_ray_normal(screen_pos)

	# Raycast ke bidang tanah Y = 0
	if abs(ray_dir.y) < 0.0001:
		return

	var t: float = -ray_origin.y / ray_dir.y
	if t <= 0.0:
		return

	var hit_pos := ray_origin + ray_dir * t
	var tile_coords := CityData.world_pos_to_tile(hit_pos)

	if not city_data.is_valid_tile(tile_coords.x, tile_coords.y):
		return

	_apply_tool(tile_coords.x, tile_coords.y)

func _apply_tool(x: int, y: int) -> void:
	var cur := city_data.get_tile(x, y)
	var cur_type: int = cur.get("type", CityData.TileType.EMPTY)

	if current_tool == ToolMode.BULLDOZER:
		if cur_type != CityData.TileType.EMPTY:
			# Kurangi populasi jika bangunan dihapus
			var level: int = cur.get("level", 0)
			if level > 0:
				var zone: int = cur.get("zone", CityData.BuildingZone.RESIDENTIAL)
				if zone == CityData.BuildingZone.RESIDENTIAL:
					city_data.population = maxi(0, city_data.population - (level * 10))

			city_data.set_tile(x, y, CityData.TileType.EMPTY, 0)
			_update_tile_visual(x, y)
			_update_demand()
			city_updated.emit(city_data)
		return

	# Biaya dan target tipe
	var cost: int = 0
	var target_type: CityData.TileType = CityData.TileType.EMPTY
	var target_zone: CityData.BuildingZone = CityData.BuildingZone.RESIDENTIAL

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

	# Jika tile sudah sama, jangan kenakan biaya lagi
	if cur_type == target_type and cur.get("level", 0) == 0:
		return

	# Cek ketersediaan uang
	if city_data.money < cost:
		show_toast.emit("Uang tidak cukup! (Kurang Rp %s)" % _format_number(cost - city_data.money))
		return

	# Potong uang dan pasang tile
	city_data.money -= cost
	city_data.set_tile(x, y, target_type, 0, target_zone)
	_update_tile_visual(x, y)
	_update_demand()
	city_updated.emit(city_data)

## Simulasi pergantian bulan & pertumbuhan otomatis
func _advance_month() -> void:
	city_data.month += 1
	if city_data.month > 12:
		city_data.month = 1
		city_data.year += 1

	# Cek apakah populasi bertumbuh dibanding bulan lalu
	if city_data.population > city_data.prev_population:
		city_data.consecutive_growth_months += 1
	else:
		city_data.consecutive_growth_months = 0
	city_data.prev_population = city_data.population

	var utilities_ready := city_data.has_utilities()

	# 1. Pertumbuhan bangunan baru (maksimal 4 bangunan per bulan)
	var candidates: Array = []
	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			var tile: Dictionary = city_data.get_tile(x, y)
			var type: int = tile.get("type", CityData.TileType.EMPTY)
			var level: int = tile.get("level", 0)

			# Hanya tumbuh di zona kosong level 0
			var is_zone: bool = (type == CityData.TileType.ZONE_R or type == CityData.TileType.ZONE_C or type == CityData.TileType.ZONE_I)
			if is_zone and level == 0:
				# Syarat: Bersebelahan jalan & listrik/air cukup
				if city_data.has_adjacent_road(x, y) and utilities_ready:
					var zone_type: int = tile.get("zone", CityData.BuildingZone.RESIDENTIAL)
					# Syarat demand
					var has_demand := false
					if zone_type == CityData.BuildingZone.RESIDENTIAL and city_data.demand_r > 15.0:
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
		_update_tile_visual(pos.x, pos.y)

		# Tambah populasi
		if zone == CityData.BuildingZone.RESIDENTIAL:
			city_data.population += 10
		elif zone == CityData.BuildingZone.COMMERCIAL:
			city_data.population += 4
		elif zone == CityData.BuildingZone.INDUSTRIAL:
			city_data.population += 6

	# 2. Peningkatan level bangunan (Lv 1 -> 2, Lv 2 -> 3 jika populasi naik 2 bulan berturut-turut)
	if city_data.consecutive_growth_months >= 2:
		var upgrade_candidates: Array = []
		for y in range(CityData.GRID_SIZE):
			for x in range(CityData.GRID_SIZE):
				var tile: Dictionary = city_data.get_tile(x, y)
				var level: int = tile.get("level", 0)
				if level in [1, 2] and utilities_ready:
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
			_update_tile_visual(pos.x, pos.y)

			if zone == CityData.BuildingZone.RESIDENTIAL:
				city_data.population += 15

	_update_demand()
	city_updated.emit(city_data)

## Rumus Demand RCI sederhana dan realistis
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
			# Kurang pekerjaan: demand I dan C meningkat, demand R melandai
			city_data.demand_i = clampf(50.0 + (residents - jobs) * 8.0, 15.0, 95.0)
			city_data.demand_c = clampf(35.0 + (residents - jobs) * 6.0, 15.0, 95.0)
			city_data.demand_r = clampf(65.0 - (residents - jobs) * 3.0, 20.0, 90.0)
		else:
			# Pekerjaan berlimpah: butuh lebih banyak warga (demand R melonjak)
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

	var node := BuildingBuilder.create_tile_node(type, level, zone)
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
