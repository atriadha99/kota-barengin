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
	var bubble_text: String = ""
	var complaint_order: int = 0
	var active_complaint: Dictionary = {}
	var thank_you_timer: float = 0.0

var walkers: Array = []
var city_data: CityData
var _complaint_seq: int = 0

func setup(p_city_data: CityData) -> void:
	city_data = p_city_data
	_create_citizens()

func restore_from_save() -> void:
	if not city_data:
		return
	for comp in city_data.active_complaints:
		var cid: String = comp.get("citizen_id", "")
		for walker in walkers:
			if walker.citizen_data.get("id", "") == cid:
				walker.active_complaint = comp.duplicate(true)
				_show_bubble(walker, comp.get("quote", ""), false)
				break

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
		var umb := Node3D.new()
		umb.name = "Umbrella"
		umb.visible = false
		var pole := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.03, 0.45, 0.03)
		pole.mesh = pm
		pole.position = Vector3(0.10, 0.85, 0.0)
		umb.add_child(pole)
		var cap := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(0.45, 0.08, 0.45)
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color = Color(0.22, 0.58, 0.92) if i % 2 == 0 else Color(0.92, 0.35, 0.35)
		cap.mesh = cm
		cap.material_override = cmat
		cap.position = Vector3(0.10, 1.08, 0.0)
		umb.add_child(cap)
		w_node.add_child(umb)
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

	# Batasi jumlah pejalan kaki aktif sesuai jumlah jalan agar tidak menumpuk di 1-2 tile
	var max_active: int = mini(walkers.size(), maxi(2, road_tiles.size()))

	for i in range(walkers.size()):
		var walker: WalkerNPC = walkers[i]

		if i >= max_active:
			walker.node.visible = false
			walker.active = false
			continue

		if not walker.active or not _is_road(walker.current_tile) or not _is_road(walker.target_tile):
			var start: Vector2i = road_tiles[(i * 3) % road_tiles.size()]
			walker.current_tile = start
			walker.target_tile = _pick_next_road(start)
			walker.progress = float(i % 4) * 0.2
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
						var nx: int = x + dir.x
						var ny: int = y + dir.y
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

	# Pemicu 4: Tidak ada Sekolah (Pop >= 100)
	if city_data.population >= 100 and not city_data.has_working_public(CityData.TileType.SCHOOL) and walkers.size() > 3:
		var w_school: WalkerNPC = walkers[3]
		if w_school.thank_you_timer <= 0.0:
			_set_complaint(w_school, ComplaintsData.COMPLAINT_NO_SCHOOL, "Area Perumahan")

	# Pemicu 5: Tidak ada tempat berobat (Pop >= 50, tanpa Puskesmas & RS)
	if city_data.population >= 50 and not city_data.has_working_public(CityData.TileType.CLINIC) and not city_data.has_working_public(CityData.TileType.HOSPITAL) and walkers.size() > 4:
		var w_health: WalkerNPC = walkers[4]
		if w_health.thank_you_timer <= 0.0:
			_set_complaint(w_health, ComplaintsData.COMPLAINT_NO_HEALTH, "Lingkungan Kota")

	# Pemicu 6: Tidak aman (Keamanan < 40)
	if city_data.security < 40.0 and walkers.size() > 5:
		var w_sec: WalkerNPC = walkers[5]
		if w_sec.thank_you_timer <= 0.0:
			_set_complaint(w_sec, ComplaintsData.COMPLAINT_INSECURE, "Jl. Sudirman")

	# Pemicu 7: Takut kebakaran (Pop >= 100, tanpa Damkar)
	if city_data.population >= 100 and not city_data.has_working_public(CityData.TileType.FIRE_STATION) and walkers.size() > 6:
		var w_fire: WalkerNPC = walkers[6]
		if w_fire.thank_you_timer <= 0.0:
			_set_complaint(w_fire, ComplaintsData.COMPLAINT_NO_FIRE, "Area Kota")

	# Pemicu 8: Angkot Ngetem (Pop >= 50, tanpa Halte Angkot)
	if city_data.population >= 50 and city_data.count_public_type(CityData.TileType.STOP_ANGKOT) == 0 and walkers.size() > 7:
		var w_angkot: WalkerNPC = walkers[7]
		if w_angkot.thank_you_timer <= 0.0:
			_set_complaint(w_angkot, ComplaintsData.COMPLAINT_ANGKOT_NGETEM, "Jalan Raya")

	# Pemicu 9: Masalah Indonesia Lainnya (Pungli, Polusi, Banjir, Mati Listrik, Air Kotor, Jalan Rusak, Harga Naik, Pengangguran, Tidak Ada Transportasi, Kebisingan Bandara)
	if city_data.population >= 100 and walkers.size() > 3:
		if city_data.power_used > city_data.power_supply:
			_set_complaint(walkers[3], ComplaintsData.COMPLAINT_BLACKOUT, "Gardu Kota")
		elif city_data.water_used > city_data.water_supply:
			_set_complaint(walkers[4], ComplaintsData.COMPLAINT_DIRTY_WATER, "Saluran Air")
		elif city_data.count_public_type(CityData.TileType.STOP_ANGKOT) == 0 and city_data.count_public_type(CityData.TileType.STOP_BUS) == 0 and city_data.count_public_type(CityData.TileType.TRAIN_STATION) == 0:
			_set_complaint(walkers[5], ComplaintsData.COMPLAINT_NO_TRANSIT, "Pusat Kota")
		elif randf() < 0.25:
			var sys_pool := [
				ComplaintsData.COMPLAINT_PUNGLI,
				ComplaintsData.COMPLAINT_POLLUTION,
				ComplaintsData.COMPLAINT_FLOOD,
				ComplaintsData.COMPLAINT_BAD_ROAD,
				ComplaintsData.COMPLAINT_INFLATION,
				ComplaintsData.COMPLAINT_UNEMPLOYMENT
			]
			var picked: String = sys_pool[randi() % sys_pool.size()]
			_set_complaint(walkers[randi() % walkers.size()], picked, "Wilayah Kota")

	# Pemicu 10: Kebisingan Bandara (rumah dalam radius 5 tile dari Landasan)
	var runways := city_data.get_public_positions(CityData.TileType.RUNWAY)
	if not runways.is_empty() and walkers.size() > 2:
		var near_noise := false
		for rpos in runways:
			for dy in range(-5, 6):
				for dx in range(-5, 6):
					var t: Dictionary = city_data.get_tile(rpos.x + dx, rpos.y + dy)
					if t.get("level", 0) > 0 and t.get("zone", CityData.BuildingZone.RESIDENTIAL) == CityData.BuildingZone.RESIDENTIAL:
						near_noise = true
						break
				if near_noise:
					break
			if near_noise:
				break
		if near_noise:
			_set_complaint(walkers[2], ComplaintsData.COMPLAINT_AIRPORT_NOISE, "Dekat Landasan")

func trigger_fire_complaint(loc: String) -> void:
	if walkers.is_empty():
		return
	var w: WalkerNPC = walkers[walkers.size() - 1]
	_set_complaint(w, ComplaintsData.COMPLAINT_FIRE, loc)

func trigger_custom_complaint(c_type: String, loc: String) -> void:
	if walkers.is_empty():
		return
	var w: WalkerNPC = walkers[randi() % walkers.size()]
	_set_complaint(w, c_type, loc)

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

func _show_bubble(walker: WalkerNPC, text: String, _is_pak_slamet: bool) -> void:
	_complaint_seq += 1
	walker.bubble_text = text
	walker.complaint_order = _complaint_seq

func _remove_bubble(walker: WalkerNPC) -> void:
	walker.bubble_text = ""
	if walker.bubble_node and is_instance_valid(walker.bubble_node):
		walker.bubble_node.queue_free()
		walker.bubble_node = null

## Ambil daftar warga yang memiliki bubble aktif, diurutkan dari keluhan terbaru
func get_active_bubble_entries() -> Array:
	var entries: Array = []
	for walker in walkers:
		if walker.active and walker.node.visible and not walker.bubble_text.is_empty():
			entries.append({
				"world_pos": walker.node.global_position + Vector3(0.0, 1.15, 0.0),
				"text": walker.bubble_text,
				"is_pak_slamet": false,
				"order": walker.complaint_order,
				"walker": walker
			})
	entries.sort_custom(func(a, b): return a["order"] > b["order"])
	return entries

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

func set_rain_umbrellas(raining: bool) -> void:
	for walker in walkers:
		if walker.node and is_instance_valid(walker.node):
			var u: Node3D = walker.node.get_node_or_null("Umbrella") as Node3D
			if u:
				u.visible = raining
