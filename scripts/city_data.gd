class_name CityData
extends RefCounted

## Konstanta dan data dasar kota KotaBarengin (Phase 1)
const GRID_SIZE: int = 16
const TILE_SIZE: float = 2.0
const MAP_SIZE: float = float(GRID_SIZE) * TILE_SIZE # 32.0 meter

enum TileType {
	EMPTY,
	ROAD,
	ZONE_R,
	ZONE_C,
	ZONE_I,
	POWER_PLANT,
	WATER_TOWER,
	PARK,
	FARM,
	BUILDING
}

enum BuildingZone {
	RESIDENTIAL,
	COMMERCIAL,
	INDUSTRIAL
}

# Biaya pembuatan tile (Rp)
const COST_ROAD: int = 5000
const COST_ZONE_R: int = 2000
const COST_ZONE_C: int = 2000
const COST_ZONE_I: int = 2000
const COST_BULLDOZER: int = 0
const COST_POWER_PLANT: int = 50000
const COST_WATER_TOWER: int = 30000

# State kota
var money: int = 150000
var population: int = 0
var month: int = 1
var year: int = 1

# Demand RCI (0.0 - 100.0)
var demand_r: float = 85.0
var demand_c: float = 25.0
var demand_i: float = 45.0

# Pelacakan pertumbuhan populasi 2 bulan berturut-turut untuk upgrade bangunan
var consecutive_growth_months: int = 0
var prev_population: int = 0

# Data grid tile: array 16x16
# Format tiap tile: { "type": TileType, "level": int (0..3), "zone": BuildingZone }
var tiles: Array = []

func _init() -> void:
	reset_grid()

func reset_grid() -> void:
	tiles.clear()
	for y in range(GRID_SIZE):
		var row: Array = []
		for x in range(GRID_SIZE):
			row.append({
				"type": TileType.EMPTY,
				"level": 0,
				"zone": BuildingZone.RESIDENTIAL
			})
		tiles.append(row)

func get_tile(x: int, y: int) -> Dictionary:
	if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
		return {}
	return tiles[y][x]

func set_tile(x: int, y: int, type: TileType, level: int = 0, zone: BuildingZone = BuildingZone.RESIDENTIAL) -> void:
	if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
		return
	tiles[y][x] = {
		"type": type,
		"level": level,
		"zone": zone
	}

static func tile_to_world_pos(x: int, y: int) -> Vector3:
	return Vector3(float(x) * TILE_SIZE + TILE_SIZE * 0.5, 0.0, float(y) * TILE_SIZE + TILE_SIZE * 0.5)

static func world_pos_to_tile(pos: Vector3) -> Vector2i:
	return Vector2i(int(floor(pos.x / TILE_SIZE)), int(floor(pos.z / TILE_SIZE)))

func is_valid_tile(x: int, y: int) -> bool:
	return x >= 0 and x < GRID_SIZE and y >= 0 and y < GRID_SIZE

## Cek apakah tile bersebelahan dengan Jalan (4 arah mata angin)
func has_adjacent_road(x: int, y: int) -> bool:
	var neighbors = [
		Vector2i(x + 1, y),
		Vector2i(x - 1, y),
		Vector2i(x, y + 1),
		Vector2i(x, y - 1)
	]
	for n in neighbors:
		if is_valid_tile(n.x, n.y):
			if get_tile(n.x, n.y).get("type", TileType.EMPTY) == TileType.ROAD:
				return true
	return false

## Hitung utilitas di Langkah 2: cukup jika ada min 1 Pembangkit & 1 Menara Air
func has_utilities() -> bool:
	var has_power: bool = false
	var has_water: bool = false
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var t: int = tiles[y][x].get("type", TileType.EMPTY)
			if t == TileType.POWER_PLANT:
				has_power = true
			elif t == TileType.WATER_TOWER:
				has_water = true
			if has_power and has_water:
				return true
	return false

func count_tile_type(type: TileType) -> int:
	var count: int = 0
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if tiles[y][x].get("type", TileType.EMPTY) == type:
				count += 1
	return count
