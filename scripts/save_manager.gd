extends Node

## Autoload SaveManager: Mengelola Save/Load Season 2 (Mode Walikota) secara offline-first dengan ConfigFile
## Save Season 2 disimpan di user://save_season2.cfg (terpisah dari save_season1.cfg)

const SAVE_SEASON2_PATH: String = "user://save_season2.cfg"
const LEGACY_SAVE_PATH: String = "user://save.cfg"
const SETTINGS_PATH: String = "user://settings.cfg"

## Flag lintas-scene: true jika pemain menekan "Lanjutkan" di Main Menu
var load_on_start: bool = false

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_SEASON2_PATH) or FileAccess.file_exists(LEGACY_SAVE_PATH)

func save_season2(data: CityData) -> bool:
	if not data:
		return false

	var cfg := ConfigFile.new()

	# Data utama kota
	cfg.set_value("city", "money", data.money)
	cfg.set_value("city", "population", data.population)
	cfg.set_value("city", "month", data.month)
	cfg.set_value("city", "year", data.year)
	cfg.set_value("city", "tax_rate", data.tax_rate)
	cfg.set_value("city", "happiness", data.happiness)
	cfg.set_value("city", "popularity", data.popularity)
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
					t.get("zone", CityData.BuildingZone.RESIDENTIAL)
				])

	var err := cfg.save(SAVE_SEASON2_PATH)
	return err == OK

func load_season2(data: CityData) -> bool:
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
	data.money = int(cfg.get_value("city", "money", 150000))
	data.population = int(cfg.get_value("city", "population", 0))
	data.month = int(cfg.get_value("city", "month", 1))
	data.year = int(cfg.get_value("city", "year", 1))
	data.tax_rate = float(cfg.get_value("city", "tax_rate", 0.08))
	data.happiness = float(cfg.get_value("city", "happiness", 70.0))
	data.popularity = float(cfg.get_value("city", "popularity", 70.0))
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
					data.set_tile(x, y, int(arr[0]), int(arr[1]), int(arr[2]))

	data.update_utilities()
	data.city_level = CityData.get_city_tier(data.population)

	# Jika berasal dari save lama user://save.cfg, migrasikan sekali ke save_season2.cfg
	if loaded_from_legacy:
		save_season2(data)

	return true

func save_settings(settings: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", float(settings.get("master_volume", 80.0)))
	cfg.set_value("audio", "music_volume", float(settings.get("music_volume", 70.0)))
	cfg.set_value("audio", "sfx_volume", float(settings.get("sfx_volume", 85.0)))
	cfg.set_value("audio", "muted", bool(settings.get("muted", false)))
	cfg.save(SETTINGS_PATH)

func load_settings() -> Dictionary:
	var result: Dictionary = {
		"master_volume": 80.0,
		"music_volume": 70.0,
		"sfx_volume": 85.0,
		"muted": false
	}
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(SETTINGS_PATH) and cfg.load(SETTINGS_PATH) == OK:
		result["master_volume"] = float(cfg.get_value("audio", "master_volume", 80.0))
		result["music_volume"] = float(cfg.get_value("audio", "music_volume", 70.0))
		result["sfx_volume"] = float(cfg.get_value("audio", "sfx_volume", 85.0))
		result["muted"] = bool(cfg.get_value("audio", "muted", false))
	return result
