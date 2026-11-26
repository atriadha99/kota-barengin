class_name CitizenManager
extends Node3D

## Mengelola pergerakan pejalan kaki low-poly, bubble chat keluhan, dan profil warga tetap

signal citizen_selected(citizen_info: Dictionary, complaint_info: Dictionary)

class WalkerNPC:
	var node: Node3D
	var citizen_data: Dictionary
	var current_tile: Vector2i = Vector2i(-1, -1)
	var target_tile: Vector2i = Vector2i(-1, -1)
	var progress: float = 0.0
	var speed: float = 0.8 # Pejalan kaki lebih santai dari mobil
	var active: bool = false
	var side_offset: Vector3 = Vector3(0.5, 0.0, 0.5) # Berjalan di pinggir jalan/trotoar
	var bubble_node: Node3D = null
	var active_complaint: Dictionary = {}
	var thank_you_timer: float = 0.0

var walkers: Array = []
var city_data: CityData

func setup(p_city_data: CityData) -> void:
	city_data = p_city_data
	_create_citizens()

func _create_citizens() -> void:
	for child in get_children():
		child.queue_free()
	walkers.clear()

	var profiles: Array = city_data.citizens_data
	for i in range(mini(profiles.size(), 8)):
		var w_node := Node3D.new()
		w_node.visible = false

		var body := BuildingBuilder.create_citizen_node(i)
		w_node.add_child(body)
		add_child(w_node)

		var walker := WalkerNPC.new()
		walker.node = w_node
		walker.citizen_data = profiles[i]
		# Variasi offset sisi trotoar
		var ox: float = 0.6 if (i % 2 == 0) else -0.6
		var oz: float = 0.6 if (i % 3 == 0) else -0.6
		walker.side_offset = Vector3(ox, 0.0, oz)
		walkers.append(walker)

func _process(delta: float) -> void:
	if not city_data:
		return

	var road_tiles: Array[Vector2i] = []
	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			if city_data.get_tile(x, y).get("type", CityData.TileType.EMPTY) == CityData.TileType.ROAD:
				road_tiles.append(Vector2i(x, y))

	if road_tiles.is_empty():
		for w in walkers:
			w.node.visible = false
			w.active = false
		return

	for i in range(walkers.size()):
		var walker: WalkerNPC = walkers[i]

		if not walker.active or not _is_road(walker.current_tile) or not _is_road(walker.target_tile):
			var start: Vector2i = road_tiles[(i * 2 + randi()) % road_tiles.size()]
			walker.current_tile = start
			walker.target_tile = _pick_next_road(start)
			walker.progress = 0.0
			walker.active = true
			walker.node.visible = true

		walker.progress += walker.speed * delta
		if walker.progress >= 1.0:
			walker.progress = 0.0
			walker.current_tile = walker.target_tile
			walker.target_tile = _pick_next_road(walker.current_tile)

		var p1 := CityData.tile_to_world_pos(walker.current_tile.x, walker.current_tile.y) + walker.side_offset
		var p2 := CityData.tile_to_world_pos(walker.target_tile.x, walker.target_tile.y) + walker.side_offset
		var cur_pos := p1.lerp(p2, walker.progress)
		cur_pos.y = 0.03
		walker.node.global_position = cur_pos

		var dir := (p2 - p1).normalized()
		if dir.length_squared() > 0.001:
			walker.node.rotation.y = atan2(-dir.x, -dir.z)

		# Update timer terima kasih jika keluhan baru diselesaikan
		if walker.thank_you_timer > 0.0:
			walker.thank_you_timer -= delta
			if walker.thank_you_timer <= 0.0:
				_remove_bubble(walker)

func _is_road(tile: Vector2i) -> bool:
	if not city_data.is_valid_tile(tile.x, tile.y):
		return false
	return city_data.get_tile(tile.x, tile.y).get("type", CityData.TileType.EMPTY) == CityData.TileType.ROAD

func _pick_next_road(from_tile: Vector2i) -> Vector2i:
	var neighbors: Array[Vector2i] = [
		Vector2i(from_tile.x + 1, from_tile.y),
		Vector2i(from_tile.x - 1, from_tile.y),
		Vector2i(from_tile.x, from_tile.y + 1),
		Vector2i(from_tile.x, from_tile.y - 1)
	]
	var roads: Array[Vector2i] = []
	for n in neighbors:
		if _is_road(n):
			roads.append(n)

	if not roads.is_empty():
		return roads[randi() % roads.size()]
	return from_tile

## Evaluasi dan picu Bubble Chat sesuai kondisi kota saat ini
func update_citizen_complaints() -> void:
	if not city_data or walkers.is_empty():
		return

	var status: Dictionary = city_data.pak_slamet_status
	var pak_slamet_active: bool = (status.get("state") == "active")

	# Pemicu 1: Macet (Pak Slamet aktif)
	if pak_slamet_active:
		var w_macet: WalkerNPC = walkers[0] # Mas Dimas
		if w_macet.thank_you_timer <= 0.0:
			_set_complaint(w_macet, ComplaintsData.COMPLAINT_TRAFFIC, "Jl. Merdeka")

	# Pemicu 2: Sampah (Populasi > 100 dan ada rumah tanpa taman)
	if city_data.population >= 100:
		var has_trash_issue := false
		var trash_loc := "Jl. Melati"
		for y in range(CityData.GRID_SIZE):
			for x in range(CityData.GRID_SIZE):
				var t: Dictionary = city_data.get_tile(x, y)
				if t.get("level", 0) > 0 and t.get("zone", CityData.BuildingZone.RESIDENTIAL) == CityData.BuildingZone.RESIDENTIAL:
					if not city_data.has_nearby_park(x, y, 3):
						has_trash_issue = true
						break
			if has_trash_issue:
				break

		if has_trash_issue and walkers.size() > 2:
			var w_trash: WalkerNPC = walkers[2] # Pak Budi
			if w_trash.thank_you_timer <= 0.0:
				_set_complaint(w_trash, ComplaintsData.COMPLAINT_TRASH, trash_loc)

	# Pemicu 3: Lampu Merah Lama (Persimpangan 3+ jalan dan populasi sekitar > 50)
	if city_data.population >= 50 and walkers.size() > 1:
		var has_junction := false
		for y in range(CityData.GRID_SIZE):
			for x in range(CityData.GRID_SIZE):
				if city_data.get_tile(x, y).get("type", CityData.TileType.EMPTY) == CityData.TileType.ROAD:
					var road_count := 0
					for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						var nx := x + dir.x
						var ny := y + dir.y
						if city_data.is_valid_tile(nx, ny) and city_data.get_tile(nx, ny).get("type", CityData.TileType.EMPTY) == CityData.TileType.ROAD:
							road_count += 1
					if road_count >= 3:
						has_junction = true
						break
			if has_junction:
				break

		if has_junction:
			var w_light: WalkerNPC = walkers[1] # Mbak Sari
			if w_light.thank_you_timer <= 0.0:
				_set_complaint(w_light, ComplaintsData.COMPLAINT_TRAFFIC_LIGHT, "Simpang Utama")

func _set_complaint(walker: WalkerNPC, complaint_type: String, location: String) -> void:
	if walker.active_complaint.get("type", "") == complaint_type:
		return # Sudah aktif

	var quote: String = ComplaintsData.get_random_quote(complaint_type, walker.citizen_data.get("name", "Warga"))
	walker.active_complaint = {
		"id": str(randi()),
		"type": complaint_type,
		"citizen_id": walker.citizen_data.get("id", ""),
		"citizen_name": walker.citizen_data.get("name", "Warga"),
		"location": location,
		"quote": quote,
		"status": "active"
	}

	# Sinkronkan ke daftar pengaduan aktif di city_data
	var already_logged := false
	for c in city_data.active_complaints:
		if c.get("type") == complaint_type and c.get("citizen_id") == walker.citizen_data.get("id"):
			already_logged = true
			break
	if not already_logged:
		city_data.active_complaints.append(walker.active_complaint)

	_show_bubble(walker, quote, false)

func _show_bubble(walker: WalkerNPC, text: String, is_pak_slamet: bool) -> void:
	_remove_bubble(walker)
	var bubble := BuildingBuilder.create_bubble_chat(text, is_pak_slamet)
	walker.node.add_child(bubble)
	walker.bubble_node = bubble

func _remove_bubble(walker: WalkerNPC) -> void:
	if walker.bubble_node and is_instance_valid(walker.bubble_node):
		walker.bubble_node.queue_free()
		walker.bubble_node = null

## Ketika pengaduan diselesaikan, bubble berubah jadi terima kasih
func resolve_complaint(complaint_type: String) -> void:
	for walker in walkers:
		if walker.active_complaint.get("type", "") == complaint_type:
			walker.active_complaint.clear()
			walker.thank_you_timer = 3.5
			_show_bubble(walker, "%s: Makasih, Pak Wali!" % walker.citizen_data.get("name", "Warga"), false)

## Cari warga terdekat dari posisi klik mouse untuk membuka profil
func check_click_hit(world_hit: Vector3) -> bool:
	for walker in walkers:
		if walker.active and walker.node.visible:
			if walker.node.global_position.distance_to(world_hit) <= 1.2:
				citizen_selected.emit(walker.citizen_data, walker.active_complaint)
				return true
	return false
