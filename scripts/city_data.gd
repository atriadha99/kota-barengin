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
	TOWNHALL
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

# Kebijakan Pak Slamet & Parkir (Langkah 5)
const COST_PAK_SLAMET_EXPEL: int = 50000
const COST_OFFICIAL_PARKING_TILE: int = 150000
const REVENUE_OFFICIAL_PARKING_MONTHLY: int = 5000

# Panen & Pertanian (Langkah 4)
const WHEAT_PER_HARVEST: int = 10
var wheat_inventory: int = 0
var wheat_price: int = 1200 # Acak Rp 800 - Rp 1.500 / unit

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
var money: int = 150000
var population: int = 0
var month: int = 1
var year: int = 1

# Ekonomi & Pajak (Langkah 3)
var tax_rate: float = 0.08 # 8% default (5% - 13%)
var happiness: float = 70.0 # 0 - 100 (mulai 70)
var popularity: float = 70.0 # 0 - 100 (mulai 70, terpisah dari kebahagiaan)
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
	for y in range(GRID_SIZE):
		var row: Array = []
		for x in range(GRID_SIZE):
			row.append({
				"type": TileType.EMPTY,
				"level": 0,
				"zone": BuildingZone.RESIDENTIAL,
				"has_utility": true
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
		"zone": zone,
		"has_utility": true
	}

static func tile_to_world_pos(x: int, y: int) -> Vector3:
	return Vector3(float(x) * TILE_SIZE + TILE_SIZE * 0.5, 0.0, float(y) * TILE_SIZE + TILE_SIZE * 0.5)

static func world_pos_to_tile(pos: Vector3) -> Vector2i:
	return Vector2i(int(floor(pos.x / TILE_SIZE)), int(floor(pos.z / TILE_SIZE)))

func is_valid_tile(x: int, y: int) -> bool:
	return x >= 0 and x < GRID_SIZE and y >= 0 and y < GRID_SIZE

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

## Hitung total utilitas dan tandai bangunan yang kebagian / kekurangan
func update_utilities() -> void:
	var plant_count := 0
	var tower_count := 0

	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var t: int = tiles[y][x].get("type", TileType.EMPTY)
			if t == TileType.POWER_PLANT:
				plant_count += 1
			elif t == TileType.WATER_TOWER:
				tower_count += 1

	power_supply = plant_count * SUPPLY_POWER_PER_PLANT
	water_supply = tower_count * SUPPLY_WATER_PER_TOWER

	var current_power_used := 0
	var current_water_used := 0

	# Iterasi semua bangunan untuk alokasi supply
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile: Dictionary = tiles[y][x]
			var level: int = tile.get("level", 0)
			if level > 0:
				var zone: int = tile.get("zone", BuildingZone.RESIDENTIAL)
				var req_p := USAGE_R_POWER
				var req_w := USAGE_R_WATER
				if zone == BuildingZone.COMMERCIAL:
					req_p = USAGE_C_POWER
					req_w = USAGE_C_WATER
				elif zone == BuildingZone.INDUSTRIAL:
					req_p = USAGE_I_POWER
					req_w = USAGE_I_WATER

				# Tambahkan ke total pemakaian
				current_power_used += req_p
				current_water_used += req_w

				# Cek apakah bangunan ini teraliri listrik & air
				if current_power_used <= power_supply and current_water_used <= water_supply:
					tile["has_utility"] = true
				else:
					tile["has_utility"] = false
			else:
				tile["has_utility"] = true

	power_used = current_power_used
	water_used = current_water_used

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
			var nx := cx + dx
			var ny := cy + dy
			if is_valid_tile(nx, ny):
				if tiles[ny][nx].get("type", TileType.EMPTY) == TileType.PARK:
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

	return clampf(base, 0.0, 100.0)

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
