class_name SaveManager
extends RefCounted

static var load_on_start: bool = false
static var s1_load_on_start: bool = false
static var s2_carryover_from_s1: bool = false
static var selected_landscape: String = "dataran"

## Mengelola Save/Load per Season (Season 1, 2, 3) secara offline-first dengan ConfigFile

const SAVE_SEASON1_PATH: String = "user://save_season1.cfg"
const SAVE_SEASON2_PATH: String = "user://save_season2.cfg"
const SAVE_SEASON3_PATH: String = "user://save_season3.cfg"
const LEGACY_SAVE_PATH: String = "user://save.cfg"
const SETTINGS_PATH: String = "user://settings.cfg"

static func has_save() -> bool:
	return has_save_s2()

static func has_save_s1() -> bool:
	return FileAccess.file_exists(SAVE_SEASON1_PATH)

static func has_save_s2() -> bool:
	return FileAccess.file_exists(SAVE_SEASON2_PATH) or FileAccess.file_exists(LEGACY_SAVE_PATH)

static func has_save_s3() -> bool:
	return FileAccess.file_exists(SAVE_SEASON3_PATH)

static func is_season1_completed() -> bool:
	if not FileAccess.file_exists(SAVE_SEASON1_PATH):
		return false
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_SEASON1_PATH) != OK:
		return false
	return bool(cfg.get_value("warga", "season1_selesai", false))

static func get_s1_carryover_data() -> Dictionary:
	var result: Dictionary = {
		"mayor_name": "Walikota",
		"mayor_age": 25,
		"popularity": 70.0,
		"integrity": 80.0,
		"starting_money": 500000
	}
	if not FileAccess.file_exists(SAVE_SEASON1_PATH):
		return result
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_SEASON1_PATH) != OK:
		return result
	if not bool(cfg.get_value("warga", "season1_selesai", false)):
		return result

	var s1_name: String = str(cfg.get_value("warga", "nama", "Walikota"))
	if not s1_name.is_empty():
		result["mayor_name"] = s1_name
	result["mayor_age"] = int(cfg.get_value("warga", "umur", 25))
	result["popularity"] = float(cfg.get_value("warga", "popularitas", 70.0))
	result["integrity"] = float(cfg.get_value("warga", "integritas", 80.0))
	var s1_uang: int = int(cfg.get_value("warga", "uang", 0))
	result["starting_money"] = mini(5000000, 500000 + int(float(s1_uang) * 0.10))
	return result

static func save_season3_placeholder() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("presiden", "initialized", false)
	return cfg.save(SAVE_SEASON3_PATH) == OK

static func load_season3_placeholder() -> bool:
	if not FileAccess.file_exists(SAVE_SEASON3_PATH):
		return false
	var cfg := ConfigFile.new()
	return cfg.load(SAVE_SEASON3_PATH) == OK

static func save_season2(data: CityData) -> bool:
	if not data:
		return false

	var cfg := ConfigFile.new()

	# Data utama kota
	cfg.set_value("city", "mayor_name", data.mayor_name)
	cfg.set_value("city", "mayor_age", data.mayor_age)
	cfg.set_value("city", "map_landscape", data.map_landscape)
	cfg.set_value("city", "unlocked_regions", data.unlocked_regions.duplicate())
	cfg.set_value("city", "regions_bought", data.regions_bought)
	cfg.set_value("city", "money", data.money)
	cfg.set_value("city", "population", data.population)
	cfg.set_value("city", "month", data.month)
	cfg.set_value("city", "year", data.year)
	cfg.set_value("city", "tax_rate", data.tax_rate)
	cfg.set_value("city", "happiness", data.happiness)
	cfg.set_value("city", "popularity", data.popularity)
	cfg.set_value("city", "integrity", data.integrity)
	cfg.set_value("city", "city_level", data.city_level)
	cfg.set_value("city", "wheat_inventory", data.wheat_inventory)
	cfg.set_value("city", "wheat_price", data.wheat_price)
	cfg.set_value("city", "wheat_harvest_count", data.wheat_harvest_count)
	cfg.set_value("city", "demand_r", data.demand_r)
	cfg.set_value("city", "demand_c", data.demand_c)
	cfg.set_value("city", "demand_i", data.demand_i)
	cfg.set_value("city", "consecutive_growth_months", data.consecutive_growth_months)
	cfg.set_value("city", "prev_population", data.prev_population)

	# Misi
	cfg.set_value("missions", "claimed", data.missions_claimed.duplicate(true))

	# Data Langkah 5 (Pak Slamet, pengaduan aktif, warga)
	cfg.set_value("langkah5", "pak_slamet_status", data.pak_slamet_status.duplicate(true))
	cfg.set_value("langkah5", "active_complaints", data.active_complaints.duplicate(true))
	cfg.set_value("langkah5", "citizens_data", data.citizens_data.duplicate(true))

	# Grid tile 16x16 (simpan tile yang tidak kosong)
	cfg.set_value("tiles", "grid_size", CityData.GRID_SIZE)
	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			var t: Dictionary = data.get_tile(x, y)
			var t_type: int = t.get("type", CityData.TileType.EMPTY)
			if t_type != CityData.TileType.EMPTY:
				var key: String = "t_%d_%d" % [x, y]
				cfg.set_value("tiles", key, [
					t_type,
					t.get("level", 0),
					t.get("zone", CityData.BuildingZone.RESIDENTIAL),
					t.get("rotation", 0)
				])
	# Simpan tile di wilayah perluasan
	var extra_arr: Array = []
	for k in data.extra_tiles.keys():
		var tv: Dictionary = data.extra_tiles[k]
		if tv.get("type", CityData.TileType.EMPTY) != CityData.TileType.EMPTY:
			extra_arr.append([k.x, k.y, tv.get("type", 0), tv.get("level", 0), tv.get("zone", 0), tv.get("rotation", 0)])
	cfg.set_value("tiles", "extra_tiles", extra_arr)
	cfg.set_value("tiles", "power_cables", data.power_cables.keys())
	cfg.set_value("tiles", "water_pipes", data.water_pipes.keys())
	cfg.set_value("city", "security", data.security)
	cfg.set_value("city", "health", data.health)
	cfg.set_value("city", "fire_cooldown_months", data.fire_cooldown_months)
	cfg.set_value("city", "active_fire", data.active_fire.duplicate(true))
	cfg.set_value("city", "public_buildings", data.get_public_buildings_list())
	cfg.set_value("city", "military_zones", data.get_military_zones_list())
	cfg.set_value("city", "transport", {
		"bus_kopaja": data.bus_kopaja_count,
		"busway": data.busway_count
	})
	cfg.set_value("city", "wide_roads", data.wide_roads.keys())
	cfg.set_value("city", "flyovers", data.flyovers.keys())
	cfg.set_value("city", "airport", {
		"airplanes": data.airplane_count
	})
	cfg.set_value("city", "waktu_jam", data.waktu_jam)
	cfg.set_value("city", "cuaca_saat_ini", data.cuaca_saat_ini)
	cfg.set_value("city", "event_aktif", data.event_aktif.duplicate(true))
	cfg.set_value("city", "event_cooldown", data.event_cooldown)
	cfg.set_value("city", "last_event_id", data.last_event_id)
	cfg.set_value("city", "flood_cooldown", data.flood_cooldown)
	cfg.set_value("city", "riwayat_event", data.riwayat_event.duplicate(true))
	cfg.set_value("city", "keinginan_warga", data.keinginan_warga.duplicate(true))
	cfg.set_value("city", "riwayat_statistik", data.riwayat_statistik.duplicate(true))

	var err := cfg.save(SAVE_SEASON2_PATH)
	return err == OK

static func load_season2(data: CityData) -> bool:
	if not data:
		return false

	var cfg := ConfigFile.new()
	var loaded_from_legacy := false

	if FileAccess.file_exists(SAVE_SEASON2_PATH):
		if cfg.load(SAVE_SEASON2_PATH) != OK:
			return false
	elif FileAccess.file_exists(LEGACY_SAVE_PATH):
		if cfg.load(LEGACY_SAVE_PATH) != OK:
			return false
		loaded_from_legacy = true
	else:
		return false

	# Data kota dengan nilai default aman
	data.mayor_name = str(cfg.get_value("city", "mayor_name", "Walikota"))
	data.mayor_age = int(cfg.get_value("city", "mayor_age", 25))
	data.map_landscape = str(cfg.get_value("city", "map_landscape", "dataran"))
	var reg_val = cfg.get_value("city", "unlocked_regions", [Vector2i(0, 0)])
	if reg_val is Array and not reg_val.is_empty():
		data.unlocked_regions = reg_val.duplicate()
	else:
		data.unlocked_regions = [Vector2i(0, 0)]
	data.regions_bought = int(cfg.get_value("city", "regions_bought", 0))
	data.money = int(cfg.get_value("city", "money", 500000))
	data.population = int(cfg.get_value("city", "population", 0))
	data.month = int(cfg.get_value("city", "month", 1))
	data.year = int(cfg.get_value("city", "year", 1))
	data.tax_rate = float(cfg.get_value("city", "tax_rate", 0.08))
	data.happiness = float(cfg.get_value("city", "happiness", 70.0))
	data.popularity = float(cfg.get_value("city", "popularity", 70.0))
	data.integrity = float(cfg.get_value("city", "integrity", 80.0))
	data.security = float(cfg.get_value("city", "security", 50.0))
	data.health = float(cfg.get_value("city", "health", 70.0))
	data.fire_cooldown_months = int(cfg.get_value("city", "fire_cooldown_months", 0))
	var af = cfg.get_value("city", "active_fire", {})
	data.active_fire = af.duplicate(true) if af is Dictionary else {}
	data.city_level = str(cfg.get_value("city", "city_level", CityData.get_city_tier(data.population)))
	data.wheat_inventory = int(cfg.get_value("city", "wheat_inventory", 0))
	data.wheat_price = int(cfg.get_value("city", "wheat_price", 1200))
	data.wheat_harvest_count = int(cfg.get_value("city", "wheat_harvest_count", 0))
	data.demand_r = float(cfg.get_value("city", "demand_r", 85.0))
	data.demand_c = float(cfg.get_value("city", "demand_c", 25.0))
	data.demand_i = float(cfg.get_value("city", "demand_i", 45.0))
	data.consecutive_growth_months = int(cfg.get_value("city", "consecutive_growth_months", 0))
	data.prev_population = int(cfg.get_value("city", "prev_population", data.population))

	# Misi
	var claimed_val = cfg.get_value("missions", "claimed", {})
	if claimed_val is Dictionary:
		data.missions_claimed = claimed_val.duplicate(true)
	else:
		data.missions_claimed = {}

	# Data Langkah 5 dengan nilai default bila memuat save lama
	var default_ps: Dictionary = {
		"state": "idle",
		"active_tile": Vector2i(-1, -1),
		"street_name": "Jl. Merdeka",
		"months_active": 0,
		"months_ignored": 0,
		"cooldown_months": 2,
		"has_official_parking": false,
		"official_parking_tiles": []
	}
	var loaded_ps = cfg.get_value("langkah5", "pak_slamet_status", default_ps)
	if loaded_ps is Dictionary:
		data.pak_slamet_status = default_ps.duplicate(true)
		for k in loaded_ps.keys():
			data.pak_slamet_status[k] = loaded_ps[k]
	else:
		data.pak_slamet_status = default_ps

	var loaded_comp = cfg.get_value("langkah5", "active_complaints", [])
	if loaded_comp is Array:
		data.active_complaints = loaded_comp.duplicate(true)
	else:
		data.active_complaints = []

	var loaded_cit = cfg.get_value("langkah5", "citizens_data", [])
	if loaded_cit is Array and not loaded_cit.is_empty():
		data.citizens_data = loaded_cit.duplicate(true)
	else:
		data.init_citizens_data()

	# Pulihkan grid tile
	data.reset_grid()
	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			var key: String = "t_%d_%d" % [x, y]
			if cfg.has_section_key("tiles", key):
				var arr = cfg.get_value("tiles", key, null)
				if arr is Array and arr.size() >= 3:
					var rot: int = int(arr[3]) if arr.size() >= 4 else 0
					data.set_tile(x, y, int(arr[0]), int(arr[1]), int(arr[2]), rot)
	var extra_loaded = cfg.get_value("tiles", "extra_tiles", [])
	if extra_loaded is Array:
		for item in extra_loaded:
			if item is Array and item.size() >= 5:
				var rot: int = int(item[5]) if item.size() >= 6 else 0
				data.set_tile(int(item[0]), int(item[1]), int(item[2]), int(item[3]), int(item[4]), rot)

	# Muat kabel & pipa (save lama tanpa key dianggap tersambung otomatis)
	if cfg.has_section_key("tiles", "power_cables"):
		var pc = cfg.get_value("tiles", "power_cables", [])
		if pc is Array:
			for p in pc:
				if p is Vector2i:
					data.power_cables[p] = true
	else:
		for y in range(CityData.GRID_SIZE):
			for x in range(CityData.GRID_SIZE):
				var t: Dictionary = data.get_tile(x, y)
				if t.get("type", CityData.TileType.EMPTY) != CityData.TileType.EMPTY:
					data.power_cables[Vector2i(x, y)] = true

	if cfg.has_section_key("tiles", "water_pipes"):
		var wp = cfg.get_value("tiles", "water_pipes", [])
		if wp is Array:
			for p in wp:
				if p is Vector2i:
					data.water_pipes[p] = true
	else:
		for y in range(CityData.GRID_SIZE):
			for x in range(CityData.GRID_SIZE):
				var t: Dictionary = data.get_tile(x, y)
				if t.get("type", CityData.TileType.EMPTY) != CityData.TileType.EMPTY:
					data.water_pipes[Vector2i(x, y)] = true

	data.security = float(cfg.get_value("city", "security", 50.0))
	data.health = float(cfg.get_value("city", "health", 70.0))
	data.fire_cooldown_months = int(cfg.get_value("city", "fire_cooldown_months", 0))
	var af2 = cfg.get_value("city", "active_fire", {})
	data.active_fire = af2.duplicate(true) if af2 is Dictionary else {}
	var tr_data = cfg.get_value("city", "transport", {})
	if tr_data is Dictionary:
		data.bus_kopaja_count = int(tr_data.get("bus_kopaja", 0))
		data.busway_count = int(tr_data.get("busway", 0))
	var wr = cfg.get_value("city", "wide_roads", [])
	if wr is Array:
		for p in wr:
			if p is Vector2i:
				data.wide_roads[p] = true
	var fl = cfg.get_value("city", "flyovers", [])
	if fl is Array:
		for p in fl:
			if p is Vector2i:
				data.flyovers[p] = true
	var ap = cfg.get_value("city", "airport", {})
	if ap is Dictionary:
		data.airplane_count = int(ap.get("airplanes", 0))
	data.waktu_jam = float(cfg.get_value("city", "waktu_jam", 12.0))
	data.cuaca_saat_ini = str(cfg.get_value("city", "cuaca_saat_ini", "cerah"))
	var ev_a = cfg.get_value("city", "event_aktif", {})
	data.event_aktif = ev_a.duplicate(true) if ev_a is Dictionary else {}
	data.event_cooldown = int(cfg.get_value("city", "event_cooldown", 2))
	data.last_event_id = str(cfg.get_value("city", "last_event_id", ""))
	data.flood_cooldown = int(cfg.get_value("city", "flood_cooldown", 0))
	var ev_r = cfg.get_value("city", "riwayat_event", [])
	data.riwayat_event = ev_r.duplicate(true) if ev_r is Array else []
	var kw = cfg.get_value("city", "keinginan_warga", {})
	data.keinginan_warga = kw.duplicate(true) if kw is Dictionary else {}
	data.ensure_citizen_wishes()
	var rs = cfg.get_value("city", "riwayat_statistik", [])
	data.riwayat_statistik = rs.duplicate(true) if rs is Array else []

	data.update_utilities()
	data.city_level = CityData.get_city_tier(data.population)

	# Jika berasal dari save lama user://save.cfg, migrasikan sekali ke save_season2.cfg
	if loaded_from_legacy:
		save_season2(data)

	return true

static func save_settings(settings: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", float(settings.get("master_volume", 80.0)))
	cfg.set_value("audio", "music_volume", float(settings.get("music_volume", 70.0)))
	cfg.set_value("audio", "sfx_volume", float(settings.get("sfx_volume", 85.0)))
	cfg.set_value("audio", "muted", bool(settings.get("muted", false)))
	cfg.set_value("display", "camera_mode", str(settings.get("camera_mode", "theotown")))
	cfg.save(SETTINGS_PATH)

static func load_settings() -> Dictionary:
	var result: Dictionary = {
		"master_volume": 80.0,
		"music_volume": 70.0,
		"sfx_volume": 85.0,
		"muted": false,
		"camera_mode": "theotown"
	}
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(SETTINGS_PATH) and cfg.load(SETTINGS_PATH) == OK:
		result["master_volume"] = float(cfg.get_value("audio", "master_volume", 80.0))
		result["music_volume"] = float(cfg.get_value("audio", "music_volume", 70.0))
		result["sfx_volume"] = float(cfg.get_value("audio", "sfx_volume", 85.0))
		result["muted"] = bool(cfg.get_value("audio", "muted", false))
		result["camera_mode"] = str(cfg.get_value("display", "camera_mode", "theotown"))
	return result
