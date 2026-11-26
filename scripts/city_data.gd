class_name CityData
extends RefCounted

## Konstanta dan data dasar kota KotaBarengin (Phase 1 - Langkah 3)
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
	BUILDING,
	OFFICIAL_PARKING,
	TOWNHALL,
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
	FLYOVER,
	RUNWAY,
	AIRPORT_TERMINAL
}

enum BuildingZone {
	RESIDENTIAL,
	COMMERCIAL,
	INDUSTRIAL
}

# Biaya pembelian awal (Rp)
const COST_ROAD: int = 5000
const COST_ZONE_R: int = 2000
const COST_ZONE_C: int = 2000
const COST_ZONE_I: int = 2000
const COST_BULLDOZER: int = 0
const COST_POWER_PLANT: int = 50000
const COST_WATER_TOWER: int = 30000
const COST_PARK: int = 10000
const COST_FARM: int = 15000
const COST_POWER_CABLE: int = 1000
const COST_WATER_PIPE: int = 1000

# Gedung Layanan Publik (Rp)
const COST_SCHOOL: int = 75000
const COST_CLINIC: int = 60000
const COST_HOSPITAL: int = 250000
const COST_POLICE: int = 100000
const COST_MILITARY: int = 200000
const COST_MAYOR_OFFICE: int = 150000
const COST_FIRE_STATION: int = 120000
const COST_ZONE_MILITARY: int = 2000
const COST_TRAIN_STATION: int = 150000
const COST_RAIL: int = 3000
const COST_STOP_ANGKOT: int = 10000
const COST_STOP_BUS: int = 15000
const COST_BUS_KOPAJA: int = 80000
const COST_BUSWAY_LANE: int = 8000
const COST_STOP_BUSWAY: int = 25000
const COST_BUSWAY_UNIT: int = 120000
const COST_WIDEN_ROAD: int = 3000
const COST_FLYOVER: int = 20000
const COST_RUNWAY: int = 5000
const COST_AIRPORT_TERMINAL: int = 300000
const COST_AIRPLANE: int = 200000

const PUBLIC_BUILDING_TYPES: Array = [
	TileType.SCHOOL,
	TileType.CLINIC,
	TileType.HOSPITAL,
	TileType.POLICE,
	TileType.MILITARY,
	TileType.MAYOR_OFFICE,
	TileType.FIRE_STATION
]

# Kebijakan Pak Slamet & Parkir (Langkah 5)
const COST_PAK_SLAMET_EXPEL: int = 50000
const COST_OFFICIAL_PARKING_TILE: int = 150000
const REVENUE_OFFICIAL_PARKING_MONTHLY: int = 5000

# Panen & Pertanian (Langkah 4)
const WHEAT_PER_HARVEST: int = 10
var wheat_inventory: int = 0
var wheat_price: int = 1200 # Acak Rp 800 - Rp 1.500 / unit
var wheat_harvest_count: int = 0

# Pelacakan misi yang sudah diklaim (Langkah 6)
var missions_claimed: Dictionary = {}

# Biaya perawatan / upkeep bulanan (Rp/bulan)
const UPKEEP_POWER_PLANT: int = 2000
const UPKEEP_WATER_TOWER: int = 1500
const UPKEEP_PARK: int = 500

# Kapasitas supply per unit
const SUPPLY_POWER_PER_PLANT: int = 100
const SUPPLY_WATER_PER_TOWER: int = 100

# Kebutuhan utilitas per tipe bangunan
const USAGE_R_POWER: int = 1
const USAGE_R_WATER: int = 1
const USAGE_C_POWER: int = 2
const USAGE_C_WATER: int = 2
const USAGE_I_POWER: int = 3
const USAGE_I_WATER: int = 3

# State kota
var mayor_name: String = "Walikota"
var mayor_age: int = 25
var map_landscape: String = "dataran" # "pantai" | "pegunungan" | "sungai" | "dataran" | "hutan"
var unlocked_regions: Array = [Vector2i(0, 0)]
var regions_bought: int = 0
var money: int = 500000
var population: int = 0
var month: int = 1
var year: int = 1

# Ekonomi & Pajak (Langkah 3)
var tax_rate: float = 0.08 # 8% default (5% - 13%)
var happiness: float = 70.0 # 0 - 100 (mulai 70)
var popularity: float = 70.0 # 0 - 100 (mulai 70, terpisah dari kebahagiaan)
var integrity: float = 80.0 # 0 - 100 (default 80)
var security: float = 50.0 # 0 - 100 (mulai 50)
var health: float = 70.0 # 0 - 100 (mulai 70)
var fire_cooldown_months: int = 0 # Maksimal 1x per 12 bulan game
var active_fire: Dictionary = {} # { "pos": Vector2i, "state": "burning"|"damaged_light"|"damaged_heavy", "months_left": int }
var wide_roads: Dictionary = {} # Vector2i -> true
var flyovers: Dictionary = {} # Vector2i -> true
var bus_kopaja_count: int = 0
var busway_count: int = 0
var airplane_count: int = 0
var waktu_jam: float = 12.0
var cuaca_saat_ini: String = "cerah"
var event_aktif: Dictionary = {}
var event_cooldown: int = 2
var last_event_id: String = ""
var flood_cooldown: int = 0
var riwayat_event: Array = []
var keinginan_warga: Dictionary = {}
var riwayat_statistik: Array = []

const WISH_DEFS: Array = [
	{"type": "taman", "text": "Pengen ada taman di dekat rumah"},
	{"type": "pabrik", "text": "Pengen kerja di pabrik"},
	{"type": "sekolah", "text": "Pengen ada sekolah buat anakku"},
	{"type": "jalan", "text": "Pengen jalan di depan rumah diperbaiki"},
	{"type": "angkutan", "text": "Pengen ada angkutan umum di dekat rumah"},
	{"type": "aman", "text": "Pengen kotaku aman"},
	{"type": "berobat", "text": "Pengen ada tempat berobat di dekat rumah"},
	{"type": "pasar", "text": "Pengen ada pasar di dekat rumah"}
]
var city_level: String = "Desa"
var game_speed: float = 1.0 # 0.0 (Pause), 1.0 (1x), 3.0 (3x)

# Status Pak Slamet (Langkah 5)
# state: "idle" | "active" | "official"
var pak_slamet_status: Dictionary = {
	"state": "idle",
	"active_tile": Vector2i(-1, -1),
	"street_name": "Jl. Merdeka",
	"months_active": 0,
	"months_ignored": 0,
	"cooldown_months": 2, # pertama muncul di Bulan 3 game
	"has_official_parking": false,
	"official_parking_tiles": []
}

# Daftar pengaduan aktif warga
var active_complaints: Array = []

# Data profil warga tetap (Persistent Citizens)
var citizens_data: Array = []

var power_supply: int = 0
var power_used: int = 0
var water_supply: int = 0
var water_used: int = 0

# Demand RCI (0.0 - 100.0)
var demand_r: float = 85.0
var demand_c: float = 25.0
var demand_i: float = 45.0

# Pelacakan pertumbuhan populasi untuk upgrade bangunan & level kota
var consecutive_growth_months: int = 0
var prev_population: int = 0

# Data grid tile 16x16: { "type": TileType, "level": int (0..3), "zone": BuildingZone, "has_utility": bool }
var tiles: Array = []
# Tile di wilayah perluasan (Vector2i(x, y) -> Dictionary)
var extra_tiles: Dictionary = {}
# Jaringan utilitas bawah tanah (Vector2i(x, y) -> bool)
var power_cables: Dictionary = {}
var water_pipes: Dictionary = {}

func _init() -> void:
	reset_grid()
	init_citizens_data()

func init_citizens_data() -> void:
	citizens_data = [
		{
			"id": "dimas",
			"name": "Mas Dimas",
			"age": 21,
			"occupation": "Mahasiswa",
			"address": "Jl. Merdeka No. 12",
			"traits": "Santai, hobi ngopi",
			"history": ["Kemarin ketabrak becak di Jl. Merdeka, kakinya keseleo, sekarang kuliahnya naik ojek."]
		},
		{
			"id": "sari",
			"name": "Mbak Sari",
			"age": 28,
			"occupation": "Kasir Minimarket",
			"address": "Jl. Sudirman No. 4B",
			"traits": "Ramah tapi gampang gemas",
			"history": ["Baru kredit motor matic bulan lalu, tiap pagi lewat persimpangan macet."]
		},
		{
			"id": "budi",
			"name": "Pak Budi",
			"age": 45,
			"occupation": "Guru SD",
			"address": "Jl. Melati No. 8",
			"traits": "Penyabar dan gemar berkebun",
			"history": ["Suka menyiram tanaman di pekarangan, paling kesal kalau tong sampah depan rumah telat diangkut."]
		},
		{
			"id": "rina",
			"name": "Bu Rina",
			"age": 40,
			"occupation": "Pemilik Warung Nasi",
			"address": "Jl. Merdeka No. 3",
			"traits": "Pekerja keras dan supel",
			"history": ["Warungnya selalu penuh saat jam makan siang karyawan dan sopir."]
		},
		{
			"id": "joko",
			"name": "Kang Joko",
			"age": 35,
			"occupation": "Kurir Paket",
			"address": "Jl. Kartini No. 17",
			"traits": "Cekatan dan hafal jalan tikus",
			"history": ["Sehari keliling antar 80 paket, hafal persimpangan mana yang lampu merahnya lama."]
		},
		{
			"id": "dewi",
			"name": "Teh Dewi",
			"age": 30,
			"occupation": "Bidan Puskesmas",
			"address": "Jl. Melati No. 2",
			"traits": "Penyayang dan tenang",
			"history": ["Sering jalan kaki ke klinik, senang kalau lingkungan sekitarnya teduh dan banyak pohon."]
		},
		{
			"id": "agus",
			"name": "Bang Agus",
			"age": 38,
			"occupation": "Montir Bengkel",
			"address": "Jl. Sudirman No. 19",
			"traits": "Humoris dan to the point",
			"history": ["Sering ngobrol akrab sambil menambal ban motor warga yang bocor."]
		},
		{
			"id": "lestari",
			"name": "Mbak Lestari",
			"age": 26,
			"occupation": "Admin Perkantoran",
			"address": "Jl. Kartini No. 5",
			"traits": "Tertib dan rapi",
			"history": ["Tiap pagi berangkat kerja selalu bawa bekal, sensitif dengan debu dan bau sampah."]
		}
	]

func reset_grid() -> void:
	tiles.clear()
	extra_tiles.clear()
	power_cables.clear()
	water_pipes.clear()
	security = 50.0
	health = 70.0
	fire_cooldown_months = 0
	active_fire.clear()
	wide_roads.clear()
	flyovers.clear()
	bus_kopaja_count = 0
	busway_count = 0
	airplane_count = 0
	riwayat_statistik.clear()
	for y in range(GRID_SIZE):
		var row: Array = []
		for x in range(GRID_SIZE):
			row.append({
				"type": TileType.EMPTY,
				"level": 0,
				"zone": BuildingZone.RESIDENTIAL,
				"has_utility": true,
				"rotation": 0,
				"road_shape": "lurus"
			})
		tiles.append(row)

func get_tile(x: int, y: int) -> Dictionary:
	if x >= 0 and x < GRID_SIZE and y >= 0 and y < GRID_SIZE:
		return tiles[y][x]
	var k := Vector2i(x, y)
	if extra_tiles.has(k):
		return extra_tiles[k]
	return { "type": TileType.EMPTY, "level": 0, "zone": BuildingZone.RESIDENTIAL, "has_utility": true, "rotation": 0, "road_shape": "lurus" }

func set_tile(x: int, y: int, type: TileType, level: int = 0, zone: BuildingZone = BuildingZone.RESIDENTIAL, rotation: int = 0, road_shape: String = "lurus") -> void:
	var d := {
		"type": type,
		"level": level,
		"zone": zone,
		"has_utility": true,
		"rotation": ((rotation % 360) + 360) % 360,
		"road_shape": road_shape
	}
	if x >= 0 and x < GRID_SIZE and y >= 0 and y < GRID_SIZE:
		tiles[y][x] = d
	elif is_valid_tile(x, y):
		extra_tiles[Vector2i(x, y)] = d

static func tile_to_world_pos(x: int, y: int) -> Vector3:
	return Vector3(float(x) * TILE_SIZE + TILE_SIZE * 0.5, 0.0, float(y) * TILE_SIZE + TILE_SIZE * 0.5)

static func world_pos_to_tile(pos: Vector3) -> Vector2i:
	return Vector2i(int(floor(pos.x / TILE_SIZE)), int(floor(pos.z / TILE_SIZE)))

static func get_region_for_tile(x: int, y: int) -> Vector2i:
	return Vector2i(floori(float(x) / float(GRID_SIZE)), floori(float(y) / float(GRID_SIZE)))

func is_region_unlocked(r: Vector2i) -> bool:
	return r in unlocked_regions

func is_region_allowed_by_landscape(r: Vector2i) -> bool:
	if r.x < -1 or r.x > 1 or r.y < -1 or r.y > 1:
		return false
	if map_landscape in ["pantai", "pegunungan"] and r.y < 0:
		return false
	return true

func is_region_adjacent(r: Vector2i) -> bool:
	if is_region_unlocked(r) or not is_region_allowed_by_landscape(r):
		return false
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if is_region_unlocked(r + dir):
			return true
	return false

func get_next_region_price() -> int:
	match regions_bought:
		0: return 100000
		1: return 250000
		2: return 500000
		3: return 1000000
		_: return 1000000 + 500000 * (regions_bought - 3)

func is_valid_tile(x: int, y: int) -> bool:
	return is_region_unlocked(get_region_for_tile(x, y))

## Cek apakah tile dapat dibangun berdasarkan tipe peta (laut/bukit/sungai/pasir)
func is_tile_buildable(x: int, y: int, allow_park_on_sand: bool = false) -> bool:
	if not is_valid_tile(x, y):
		return false
	match map_landscape:
		"pantai":
			if y <= 1:
				return false # Laut biru
			if y <= 3:
				return allow_park_on_sand # Pantai pasir hanya bisa Taman
		"pegunungan":
			if y <= 1 or (y == 2 and (x < 4 or x > 11)):
				return false # Bukit / gunung low-poly
		"sungai":
			if (x == 7 or x == 8) and y != 5 and y != 10:
				return false # Sungai (kecuali 2 titik jembatan y=5, y=10)
	return true

## Cek apakah tile bersebelahan dengan Jalan (4 arah mata angin)
func has_adjacent_road(x: int, y: int) -> bool:
	var neighbors: Array[Vector2i] = [
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

## Hitung total utilitas berdasarkan konektivitas jaringan kabel listrik & pipa air bawah tanah
func update_utilities() -> void:
	var plant_positions: Array[Vector2i] = []
	var tower_positions: Array[Vector2i] = []
	var building_positions: Array[Vector2i] = []

	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var pos := Vector2i(x, y)
			var tile: Dictionary = tiles[y][x]
			var t: int = tile.get("type", TileType.EMPTY)
			if t == TileType.POWER_PLANT:
				plant_positions.append(pos)
				tile["has_utility"] = true
			elif t == TileType.WATER_TOWER:
				tower_positions.append(pos)
				tile["has_utility"] = true
			elif (tile.get("level", 0) > 0 and t in [TileType.ZONE_R, TileType.ZONE_C, TileType.ZONE_I, TileType.BUILDING, TileType.ZONE_MILITARY]) or (t in PUBLIC_BUILDING_TYPES) or (t in [TileType.TRAIN_STATION, TileType.STOP_BUSWAY, TileType.AIRPORT_TERMINAL]):
				building_positions.append(pos)
			else:
				tile["has_utility"] = true

	for pos in extra_tiles.keys():
		var tile: Dictionary = extra_tiles[pos]
		var t: int = tile.get("type", TileType.EMPTY)
		if t == TileType.POWER_PLANT:
			plant_positions.append(pos)
			tile["has_utility"] = true
		elif t == TileType.WATER_TOWER:
			tower_positions.append(pos)
			tile["has_utility"] = true
		elif (tile.get("level", 0) > 0 and t in [TileType.ZONE_R, TileType.ZONE_C, TileType.ZONE_I, TileType.BUILDING, TileType.ZONE_MILITARY]) or (t in PUBLIC_BUILDING_TYPES) or (t in [TileType.TRAIN_STATION, TileType.STOP_BUSWAY, TileType.AIRPORT_TERMINAL]):
			building_positions.append(pos)
		else:
			tile["has_utility"] = true

	power_supply = plant_positions.size() * SUPPLY_POWER_PER_PLANT
	water_supply = tower_positions.size() * SUPPLY_WATER_PER_TOWER

	var powered_tiles: Dictionary = _bfs_network(plant_positions, power_cables)
	var watered_tiles: Dictionary = _bfs_network(tower_positions, water_pipes)

	var current_power_used := 0
	var current_water_used := 0

	for pos in building_positions:
		var tile: Dictionary = get_tile(pos.x, pos.y)
		var t: int = tile.get("type", TileType.EMPTY)
		var req_p := USAGE_R_POWER
		var req_w := USAGE_R_WATER
		var need_water := true
		if t == TileType.HOSPITAL:
			req_p = 20
			req_w = 20
		elif t == TileType.AIRPORT_TERMINAL:
			req_p = 10
			req_w = 10
		elif t in [TileType.TRAIN_STATION, TileType.STOP_BUSWAY]:
			req_p = 3
			req_w = 0
			need_water = false
		elif (t in PUBLIC_BUILDING_TYPES) or t == TileType.ZONE_MILITARY:
			req_p = 2
			req_w = 2
		else:
			var zone: int = tile.get("zone", BuildingZone.RESIDENTIAL)
			if zone == BuildingZone.COMMERCIAL:
				req_p = USAGE_C_POWER
				req_w = USAGE_C_WATER
			elif zone == BuildingZone.INDUSTRIAL:
				req_p = USAGE_I_POWER
				req_w = USAGE_I_WATER

		current_power_used += req_p
		current_water_used += req_w

		var has_p := _is_connected_to_net(pos, powered_tiles) and (current_power_used <= power_supply)
		var has_w := true if not need_water else (_is_connected_to_net(pos, watered_tiles) and (current_water_used <= water_supply))
		tile["has_utility"] = has_p and has_w

	power_used = current_power_used
	water_used = current_water_used

func _bfs_network(starts: Array[Vector2i], grid_net: Dictionary) -> Dictionary:
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = []
	for s in starts:
		visited[s] = true
		queue.append(s)
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while queue.size() > 0:
		var curr: Vector2i = queue.pop_front()
		for dir in dirs:
			var nxt: Vector2i = curr + dir
			if not visited.has(nxt) and grid_net.has(nxt):
				visited[nxt] = true
				queue.append(nxt)
	return visited

func _is_connected_to_net(pos: Vector2i, net: Dictionary) -> bool:
	if net.has(pos):
		return true
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if net.has(pos + dir):
			return true
	return false

## Cek apakah supply listrik dan air masih mencukupi untuk pertambahan
func can_supply_new_building(zone_type: int) -> bool:
	var req_p := USAGE_R_POWER
	var req_w := USAGE_R_WATER
	if zone_type == BuildingZone.COMMERCIAL:
		req_p = USAGE_C_POWER
		req_w = USAGE_C_WATER
	elif zone_type == BuildingZone.INDUSTRIAL:
		req_p = USAGE_I_POWER
		req_w = USAGE_I_WATER

	return (power_used + req_p <= power_supply) and (water_used + req_w <= water_supply)

## Cek apakah ada taman di dekat koordinat (jarak <= 3 tile)
func has_nearby_park(cx: int, cy: int, max_dist: int = 3) -> bool:
	for dy in range(-max_dist, max_dist + 1):
		for dx in range(-max_dist, max_dist + 1):
			var nx: int = cx + dx
			var ny: int = cy + dy
			if is_valid_tile(nx, ny) and get_tile(nx, ny).get("type", TileType.EMPTY) == TileType.PARK:
				return true
	return false

## Hitung tingkat kebahagiaan kota (0 - 100)
func calculate_happiness() -> float:
	var base: float = 70.0

	# 1. Pengaruh Pajak: Default 8% netral. Tiap 1% di atas 8% mengurangi 3 kebahagiaan.
	var tax_diff := (tax_rate - 0.08) * 100.0
	base -= tax_diff * 3.5

	# 2. Pengaruh Utilitas: Jika ada defisit listrik atau air, kurangi drastis
	if power_used > power_supply:
		var deficit_ratio := float(power_used - power_supply) / float(maxi(1, power_used))
		base -= deficit_ratio * 30.0
	if water_used > water_supply:
		var deficit_ratio := float(water_used - water_supply) / float(maxi(1, water_used))
		base -= deficit_ratio * 30.0

	# 3. Pengaruh Taman di dekat perumahan (+ bonus kebahagiaan)
	var house_count := 0
	var happy_house_count := 0
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile: Dictionary = tiles[y][x]
			if tile.get("level", 0) > 0 and tile.get("zone", BuildingZone.RESIDENTIAL) == BuildingZone.RESIDENTIAL:
				house_count += 1
				if has_nearby_park(x, y, 3):
					happy_house_count += 1

	if house_count > 0:
		var park_ratio := float(happy_house_count) / float(house_count)
		base += park_ratio * 18.0

	# 4. Pengaruh Pengangguran
	# Pekerjaan dari Komersial (8/toko) + Industri (12/pabrik)
	var c_count := 0
	var i_count := 0
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile: Dictionary = tiles[y][x]
			if tile.get("level", 0) > 0:
				var z: int = tile.get("zone", BuildingZone.RESIDENTIAL)
				if z == BuildingZone.COMMERCIAL:
					c_count += tile.get("level", 1)
				elif z == BuildingZone.INDUSTRIAL:
					i_count += tile.get("level", 1)

	var total_jobs := c_count * 8 + i_count * 12
	if population > 0 and population > total_jobs:
		var unemployed := population - total_jobs
		var unemp_ratio := float(unemployed) / float(population)
		if unemp_ratio > 0.2:
			base -= (unemp_ratio - 0.2) * 35.0

	# 5. Pengaruh Keamanan & Gedung Layanan Publik
	if security < 30.0:
		base -= 5.0
	elif security >= 70.0:
		base += 3.0

	var schools := get_working_public_positions(TileType.SCHOOL)
	var clinics := get_working_public_positions(TileType.CLINIC)
	var hospitals := get_working_public_positions(TileType.HOSPITAL)
	var polices := get_working_public_positions(TileType.POLICE)
	var fires := get_working_public_positions(TileType.FIRE_STATION)

	if _any_house_in_radius(schools, 10):
		base += 5.0
	if _any_house_in_radius(clinics, 10):
		base += 3.0
	if _any_house_in_radius(hospitals, 15):
		base += 5.0
	if _any_house_in_radius(polices, 12):
		base += 3.0
	if _any_house_in_radius(fires, 12):
		base += 3.0

	# 6. Pengaruh Transportasi, Flyover & Bandara
	if _any_house_in_radius(get_working_public_positions(TileType.TRAIN_STATION), 15):
		base += 3.0
	if _any_house_in_radius(get_public_positions(TileType.STOP_ANGKOT), 8):
		base += 2.0
	if bus_kopaja_count > 0 and _any_house_in_radius(get_public_positions(TileType.STOP_BUS), 10):
		base += 3.0
	if busway_count > 0 and _any_house_in_radius(get_working_public_positions(TileType.STOP_BUSWAY), 15):
		base += 5.0
	if not flyovers.is_empty():
		var fly_arr: Array[Vector2i] = []
		for fk in flyovers.keys():
			fly_arr.append(fk)
		if _any_house_in_radius(fly_arr, 10):
			base += 3.0
	if has_working_airport():
		if _any_house_in_radius(get_working_public_positions(TileType.AIRPORT_TERMINAL), 15):
			base += 5.0
	var runways := get_public_positions(TileType.RUNWAY)
	if not runways.is_empty() and _any_house_in_radius(runways, 5):
		base -= 3.0

	# 7. Pengaruh Event Aktif
	var ev_id: String = str(event_aktif.get("id", ""))
	if ev_id in ["kuliner", "pasar_malam"]:
		base += 5.0
	elif ev_id == "17an":
		base += 3.0
	elif ev_id == "banjir":
		base -= 3.0

	return clampf(base, 0.0, 100.0)

func get_public_positions(target_type: int) -> Array[Vector2i]:
	var res: Array[Vector2i] = []
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if tiles[y][x].get("type", TileType.EMPTY) == target_type:
				res.append(Vector2i(x, y))
	for p in extra_tiles.keys():
		if extra_tiles[p].get("type", TileType.EMPTY) == target_type:
			res.append(p)
	return res

func has_working_airport() -> bool:
	return count_public_type(TileType.RUNWAY) >= 20 and has_working_public(TileType.AIRPORT_TERMINAL) and airplane_count >= 1

func has_adjacent_type(cx: int, cy: int, target_type: int) -> bool:
	for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx: int = cx + dir.x
		var ny: int = cy + dir.y
		if is_valid_tile(nx, ny) and get_tile(nx, ny).get("type", TileType.EMPTY) == target_type:
			return true
	return false

func get_military_zones_list() -> Array:
	var res: Array = []
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var t: Dictionary = tiles[y][x]
			if t.get("type", TileType.EMPTY) == TileType.ZONE_MILITARY:
				res.append([x, y, t.get("level", 0)])
	for p in extra_tiles.keys():
		var t: Dictionary = extra_tiles[p]
		if t.get("type", TileType.EMPTY) == TileType.ZONE_MILITARY:
			res.append([p.x, p.y, t.get("level", 0)])
	return res

func _any_house_in_radius(centers: Array[Vector2i], radius: int) -> bool:
	if centers.is_empty():
		return false
	var has_any_house := false
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile: Dictionary = tiles[y][x]
			if tile.get("level", 0) > 0 and tile.get("zone", BuildingZone.RESIDENTIAL) == BuildingZone.RESIDENTIAL:
				has_any_house = true
				var p := Vector2i(x, y)
				for c in centers:
					if p.distance_to(c) <= float(radius):
						return true
	for p in extra_tiles.keys():
		var tile: Dictionary = extra_tiles[p]
		if tile.get("level", 0) > 0 and tile.get("zone", BuildingZone.RESIDENTIAL) == BuildingZone.RESIDENTIAL:
			has_any_house = true
			for c in centers:
				if p.distance_to(c) <= float(radius):
					return true
	return not has_any_house

func get_working_public_positions(target_type: int) -> Array[Vector2i]:
	var res: Array[Vector2i] = []
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var t: Dictionary = tiles[y][x]
			if t.get("type", TileType.EMPTY) == target_type and t.get("has_utility", true):
				res.append(Vector2i(x, y))
	for p in extra_tiles.keys():
		var t: Dictionary = extra_tiles[p]
		if t.get("type", TileType.EMPTY) == target_type and t.get("has_utility", true):
			res.append(p)
	return res

func ensure_citizen_wishes() -> void:
	for c in citizens_data:
		var cid: String = str(c.get("id", ""))
		if not cid.is_empty() and not keinginan_warga.has(cid):
			assign_new_wish(cid)

func assign_new_wish(cid: String) -> void:
	var w: Dictionary = WISH_DEFS[randi() % WISH_DEFS.size()]
	keinginan_warga[cid] = {
		"type": w["type"],
		"text": w["text"],
		"fulfilled": false,
		"months": 0,
		"cooldown": 0
	}

func is_wish_fulfilled(w_type: String) -> bool:
	match w_type:
		"taman":
			return count_public_type(TileType.PARK) >= 1
		"pabrik":
			return count_public_type(TileType.ZONE_I) >= 1
		"sekolah":
			return has_working_public(TileType.SCHOOL)
		"jalan":
			return not wide_roads.is_empty() or not flyovers.is_empty()
		"angkutan":
			return count_public_type(TileType.STOP_ANGKOT) >= 1 or count_public_type(TileType.STOP_BUS) >= 1 or has_working_public(TileType.TRAIN_STATION)
		"aman":
			return security >= 70.0
		"berobat":
			return has_working_public(TileType.CLINIC) or has_working_public(TileType.HOSPITAL)
		"pasar":
			return count_public_type(TileType.ZONE_C) >= 1
	return false

func record_monthly_stats() -> void:
	riwayat_statistik.append({
		"month": month,
		"year": year,
		"pop": population,
		"money": money,
		"happy": int(round(happiness)),
		"popu": int(round(popularity)),
		"sec": int(round(security))
	})
	if riwayat_statistik.size() > 12:
		riwayat_statistik.remove_at(0)

func has_working_public(target_type: int) -> bool:
	return not get_working_public_positions(target_type).is_empty()

func count_public_type(target_type: int) -> int:
	var count := 0
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if tiles[y][x].get("type", TileType.EMPTY) == target_type:
				count += 1
	for p in extra_tiles.keys():
		if extra_tiles[p].get("type", TileType.EMPTY) == target_type:
			count += 1
	return count

func is_public_building_unlocked(target_type: int) -> Dictionary:
	match target_type:
		TileType.SCHOOL:
			return {"unlocked": population >= 100, "reason": "Butuh Pop 100"}
		TileType.CLINIC:
			return {"unlocked": population >= 50, "reason": "Butuh Pop 50"}
		TileType.HOSPITAL:
			return {"unlocked": population >= 500 and count_public_type(TileType.CLINIC) >= 1, "reason": "Butuh Pop 500 + Puskesmas"}
		TileType.POLICE:
			return {"unlocked": population >= 100, "reason": "Butuh Pop 100"}
		TileType.MILITARY:
			return {"unlocked": population >= 500 and count_public_type(TileType.POLICE) >= 1, "reason": "Butuh Pop 500 + Polisi"}
		TileType.MAYOR_OFFICE:
			return {"unlocked": population >= 100, "reason": "Butuh Pop 100"}
		TileType.FIRE_STATION:
			return {"unlocked": population >= 100, "reason": "Butuh Pop 100"}
		TileType.ZONE_MILITARY:
			return {"unlocked": count_public_type(TileType.MILITARY) >= 1, "reason": "Butuh Markas TNI"}
		TileType.TRAIN_STATION:
			return {"unlocked": population >= 500, "reason": "Butuh Pop 500"}
		TileType.STOP_ANGKOT:
			return {"unlocked": population >= 100, "reason": "Butuh Pop 100"}
		TileType.STOP_BUS:
			return {"unlocked": population >= 100, "reason": "Butuh Pop 100"}
		TileType.BUSWAY_LANE:
			return {"unlocked": population >= 500, "reason": "Butuh Pop 500"}
		TileType.STOP_BUSWAY:
			return {"unlocked": population >= 500, "reason": "Butuh Pop 500"}
		TileType.FLYOVER:
			return {"unlocked": population >= 500, "reason": "Butuh Pop 500"}
		TileType.AIRPORT_TERMINAL:
			return {"unlocked": population >= 1500 and count_public_type(TileType.RUNWAY) >= 20, "reason": "Pop 1500+20 Landasan"}
	return {"unlocked": true, "reason": ""}

func get_public_buildings_list() -> Array:
	var list: Array = []
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tp: int = tiles[y][x].get("type", TileType.EMPTY)
			if tp in PUBLIC_BUILDING_TYPES:
				list.append([x, y, tp])
	for p in extra_tiles.keys():
		var tp: int = extra_tiles[p].get("type", TileType.EMPTY)
		if tp in PUBLIC_BUILDING_TYPES:
			list.append([p.x, p.y, tp])
	return list

## Nama level kota berdasarkan populasi
static func get_city_tier(pop: int) -> String:
	if pop >= 5000:
		return "Metropolis"
	elif pop >= 1500:
		return "Kota Besar"
	elif pop >= 500:
		return "Kota"
	elif pop >= 100:
		return "Kota Kecil"
	else:
		return "Desa"
