class_name PakSlametManager
extends Node3D

## Mengelola kemunculan, aksi parkir liar, kemacetan, dan opsi kebijakan Pak Slamet

signal pak_slamet_event(type: String, message: String)
signal open_pak_slamet_dialog()

var city_data: CityData
var car_controller: CarController
var city_manager: Node

var active_mesh: Node3D = null
var illegal_cars_mesh: Node3D = null
var bubble_mesh: Node3D = null

func setup(p_city_data: CityData, p_car_controller: CarController, p_city_manager: Node) -> void:
	city_data = p_city_data
	car_controller = p_car_controller
	city_manager = p_city_manager

func on_month_passed() -> void:
	if not city_data:
		return

	var status: Dictionary = city_data.pak_slamet_status

	# Jika sudah jadi petugas parkir resmi, berikan pemasukan bulanan Rp5.000
	if status.get("state") == "official":
		city_data.money += CityData.REVENUE_OFFICIAL_PARKING_MONTHLY
		return

	# Jika sedang aktif parkir liar:
	if status.get("state") == "active":
		status["months_ignored"] = status.get("months_ignored", 0) + 1
		# Jika dibiarkan 2 bulan berturut-turut, warga kesal dan pindah
		if status["months_ignored"] >= 2:
			var lost_pop := mini(5, city_data.population)
			city_data.population = maxi(0, city_data.population - lost_pop)
			city_data.happiness = clampf(city_data.happiness - 8.0, 0.0, 100.0)
			city_data.popularity = clampf(city_data.popularity - 5.0, 0.0, 100.0)
			pak_slamet_event.emit("warga_pindah", "Kemacetan parkir liar dibiarkan! %d warga pindah dari Jl. Merdeka." % lost_pop)
		return

	# Jika status idle: hitung cooldown
	var cd: int = status.get("cooldown_months", 2)
	cd -= 1
	status["cooldown_months"] = cd

	# Muncul pertama kali di bulan 3, lalu berkala tiap 2-3 bulan
	if cd <= 0 and city_data.month >= 3:
		_spawn_pak_slamet()

func _find_busiest_road_tile() -> Vector2i:
	var best_tile := Vector2i(-1, -1)
	var max_neighbors := -1

	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			if city_data.get_tile(x, y).get("type", CityData.TileType.EMPTY) == CityData.TileType.ROAD:
				var neighbors := 0
				for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n: Vector2i = Vector2i(x, y) + dir
					if city_data.is_valid_tile(n.x, n.y):
						if city_data.get_tile(n.x, n.y).get("type", CityData.TileType.EMPTY) == CityData.TileType.ROAD:
							neighbors += 1
				if neighbors > max_neighbors:
					max_neighbors = neighbors
					best_tile = Vector2i(x, y)

	return best_tile

func _spawn_pak_slamet() -> void:
	var target_tile := _find_busiest_road_tile()
	if target_tile == Vector2i(-1, -1):
		return

	var status: Dictionary = city_data.pak_slamet_status
	status["state"] = "active"
	status["active_tile"] = target_tile
	status["street_name"] = "Jl. Merdeka"
	status["months_ignored"] = 0

	_refresh_visuals()

	# Perlambat mobil 50% di jalan
	if car_controller and "speed_multiplier" in car_controller:
		car_controller.speed_multiplier = 0.5

	# Turunkan kebahagiaan setempat
	city_data.happiness = clampf(city_data.happiness - 5.0, 0.0, 100.0)

	pak_slamet_event.emit("spawn", "Pak Slamet lagi parkir liar di Jl. Merdeka!")
	open_pak_slamet_dialog.emit()

func _refresh_visuals() -> void:
	_clear_visuals()
	var status: Dictionary = city_data.pak_slamet_status

	if status.get("state") == "active":
		var tile: Vector2i = status.get("active_tile", Vector2i(-1, -1))
		if tile != Vector2i(-1, -1):
			var world_pos := CityData.tile_to_world_pos(tile.x, tile.y)

			# Mobil parkir liar
			illegal_cars_mesh = BuildingBuilder.create_illegal_parking_mesh()
			illegal_cars_mesh.position = world_pos
			add_child(illegal_cars_mesh)

			# Karakter Pak Slamet
			active_mesh = BuildingBuilder.create_pak_slamet_node()
			active_mesh.position = world_pos + Vector3(0.55, 0.0, -0.55)
			add_child(active_mesh)

	elif status.get("state") == "official":
		var tiles: Array = status.get("official_parking_tiles", [])
		if not tiles.is_empty():
			var tile: Vector2i = tiles[0]
			var world_pos := CityData.tile_to_world_pos(tile.x, tile.y)
			active_mesh = BuildingBuilder.create_pak_slamet_node()
			active_mesh.position = world_pos + Vector3(0.6, 0.0, 0.6)
			add_child(active_mesh)

			bubble_mesh = BuildingBuilder.create_bubble_chat("Pak Slamet: Parkiran tertib dan aman, Pak Wali!", true)
			bubble_mesh.position = active_mesh.position
			add_child(bubble_mesh)

func _clear_visuals() -> void:
	if active_mesh and is_instance_valid(active_mesh):
		active_mesh.queue_free()
		active_mesh = null
	if illegal_cars_mesh and is_instance_valid(illegal_cars_mesh):
		illegal_cars_mesh.queue_free()
		illegal_cars_mesh = null
	if bubble_mesh and is_instance_valid(bubble_mesh):
		bubble_mesh.queue_free()
		bubble_mesh = null

## Opsi 1: USIR (Biaya Rp50.000)
func action_expel() -> bool:
	if city_data.money < CityData.COST_PAK_SLAMET_EXPEL:
		pak_slamet_event.emit("error", "Uang tidak cukup untuk menertibkan Pak Slamet! (Butuh Rp50.000)")
		return false

	city_data.money -= CityData.COST_PAK_SLAMET_EXPEL
	city_data.happiness = clampf(city_data.happiness + 3.0, 0.0, 100.0)
	city_data.popularity = clampf(city_data.popularity + 4.0, 0.0, 100.0)

	var status: Dictionary = city_data.pak_slamet_status
	status["state"] = "idle"
	status["cooldown_months"] = randi_range(2, 3) # Balik lagi 2-3 bulan kemudian
	status["months_ignored"] = 0

	if car_controller and "speed_multiplier" in car_controller:
		car_controller.speed_multiplier = 1.0

	_clear_visuals()
	pak_slamet_event.emit("expel", "Pak Slamet: Ya udah, saya pindah dulu... nanti balik lagi ya, Pak Wali!")
	return true

## Opsi 2: BANGUN LAHAN PARKIR RESMI (Biaya Rp150.000 / tile, butuh 2 tile kosong)
func action_build_official_parking() -> bool:
	var status: Dictionary = city_data.pak_slamet_status
	var center_tile: Vector2i = status.get("active_tile", Vector2i(-1, -1))
	if center_tile == Vector2i(-1, -1):
		return false

	# Cari 2 tile KOSONG di dekat jalan itu (radius 2)
	var empty_tiles: Array[Vector2i] = []
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var cur := center_tile + Vector2i(dx, dy)
			if city_data.is_valid_tile(cur.x, cur.y):
				if city_data.get_tile(cur.x, cur.y).get("type", CityData.TileType.EMPTY) == CityData.TileType.EMPTY:
					empty_tiles.append(cur)
					if empty_tiles.size() >= 2:
						break
		if empty_tiles.size() >= 2:
			break

	if empty_tiles.size() < 2:
		pak_slamet_event.emit("error", "Tidak ada 2 tile kosong di dekat jalan untuk parkir resmi!")
		return false

	var total_cost: int = CityData.COST_OFFICIAL_PARKING_TILE * 2 # Rp300.000
	if city_data.money < total_cost:
		pak_slamet_event.emit("error", "Uang tidak cukup! (Butuh Rp300.000 untuk 2 tile parkir resmi)")
		return false

	city_data.money -= total_cost
	for t in empty_tiles:
		city_data.set_tile(t.x, t.y, CityData.TileType.OFFICIAL_PARKING, 0)
		if city_manager and city_manager.has_method("_update_tile_visual"):
			city_manager._update_tile_visual(t.x, t.y)

	status["state"] = "official"
	status["has_official_parking"] = true
	status["official_parking_tiles"] = empty_tiles

	if car_controller and "speed_multiplier" in car_controller:
		car_controller.speed_multiplier = 1.0

	city_data.happiness = clampf(city_data.happiness + 8.0, 0.0, 100.0)
	city_data.popularity = clampf(city_data.popularity + 10.0, 0.0, 100.0)

	_refresh_visuals()
	pak_slamet_event.emit("official", "Pak Slamet: Wah, parkiran resmi! Makasih, Pak Wali. Saya jaga beneran sekarang.")
	return true

## Opsi 3: BIARIN AJA (Biaya Rp0)
func action_ignore() -> void:
	pak_slamet_event.emit("ignore", "Parkir liar dibiarkan. Kemacetan masih berlanjut di Jl. Merdeka.")
