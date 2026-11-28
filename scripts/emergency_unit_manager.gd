class_name EmergencyUnitManager
extends Node3D

## Mengelola unit darurat low-poly (Damkar, Polisi, Ambulans, Truk TNI) yang bergerak di jalan

signal unit_arrived(kind: String, target_pos: Vector2i)
signal unit_returned(kind: String)

class EmergencyUnit:
	var id: String = ""
	var kind: String = "damkar" # "damkar" | "polisi" | "ambulans" | "tni"
	var home_name: String = ""
	var home_pos: Vector2i = Vector2i.ZERO
	var status: String = "Siaga di markas" # "Siaga di markas" | "Berangkat" | "Di Lokasi" | "Kembali"
	var target_pos: Vector2i = Vector2i(-1, -1)
	var path: Array[Vector2i] = []
	var path_idx: int = 0
	var progress: float = 0.0
	var speed: float = 3.2
	var patrol_cur: Vector2i = Vector2i(-1, -1)
	var patrol_nxt: Vector2i = Vector2i(-1, -1)
	var node: Node3D = null
	var lamp_node: MeshInstance3D = null
	var spray_node: MeshInstance3D = null
	var status_label: Label3D = null

var units: Array[EmergencyUnit] = []
var city_data: CityData = null
var speed_multiplier: float = 1.0
var _blink_accum: float = 0.0
var _shared_mats: Dictionary = {}
var _shared_boxes: Dictionary = {}

func setup(p_city_data: CityData) -> void:
	city_data = p_city_data
	sync_units()

func sync_units() -> void:
	if not city_data:
		return
	var desired: Array[Dictionary] = []

	# 1. Mobil Damkar (maks 2, 1 per gedung Damkar yang tersambung pipa air)
	var damkars: Array[Vector2i] = city_data.get_working_public_positions(CityData.TileType.FIRE_STATION)
	for i in range(mini(damkars.size(), 2)):
		desired.append({"id": "damkar_%d" % i, "kind": "damkar", "home_name": "Damkar", "home_pos": damkars[i], "speed": 3.4})

	# 2. Mobil Polisi / Patroli (maks 3, 1 per Kantor Polisi)
	var polices: Array[Vector2i] = city_data.get_public_positions(CityData.TileType.POLICE)
	for i in range(mini(polices.size(), 3)):
		desired.append({"id": "polisi_%d" % i, "kind": "polisi", "home_name": "Kantor Polisi", "home_pos": polices[i], "speed": 3.6})

	# 3. Ambulans (1 dari RS, atau 1 lebih lambat dari Puskesmas)
	var hospitals: Array[Vector2i] = city_data.get_public_positions(CityData.TileType.HOSPITAL)
	if not hospitals.is_empty():
		desired.append({"id": "ambulans_0", "kind": "ambulans", "home_name": "Rumah Sakit", "home_pos": hospitals[0], "speed": 3.6})
	else:
		var clinics: Array[Vector2i] = city_data.get_public_positions(CityData.TileType.CLINIC)
		if not clinics.is_empty():
			desired.append({"id": "ambulans_0", "kind": "ambulans", "home_name": "Puskesmas", "home_pos": clinics[0], "speed": 2.4})

	# 4. Truk TNI Bantuan (1 dari Markas TNI)
	var tnis: Array[Vector2i] = city_data.get_public_positions(CityData.TileType.MILITARY)
	if not tnis.is_empty():
		desired.append({"id": "tni_0", "kind": "tni", "home_name": "Markas TNI", "home_pos": tnis[0], "speed": 2.8})

	# Pertahankan state unit lama yang ID-nya masih ada
	var old_map: Dictionary = {}
	for u in units:
		old_map[u.id] = u
	for sv in city_data.unit_status:
		if sv is Dictionary:
			var sid: String = str(sv.get("id", ""))
			if not sid.is_empty() and not old_map.has(sid):
				var dummy := EmergencyUnit.new()
				dummy.id = sid
				dummy.status = str(sv.get("status", "Siaga di markas"))
				var tp_v = sv.get("target_pos", Vector2i(-1, -1))
				dummy.target_pos = tp_v if tp_v is Vector2i else Vector2i(-1, -1)
				old_map[sid] = dummy

	var new_units: Array[EmergencyUnit] = []
	for d in desired:
		var uid: String = str(d["id"])
		var unit := EmergencyUnit.new()
		unit.id = uid
		unit.kind = str(d["kind"])
		unit.home_name = str(d["home_name"])
		unit.home_pos = d["home_pos"] as Vector2i
		unit.speed = float(d["speed"])
		if old_map.has(uid):
			var prev: EmergencyUnit = old_map[uid] as EmergencyUnit
			if prev.node and is_instance_valid(prev.node):
				unit.node = prev.node
				unit.lamp_node = prev.lamp_node
				unit.status_label = prev.status_label
				unit.path = prev.path
				unit.path_idx = prev.path_idx
				unit.progress = prev.progress
				unit.patrol_cur = prev.patrol_cur
				unit.patrol_nxt = prev.patrol_nxt
			unit.status = prev.status
			unit.target_pos = prev.target_pos
			if unit.status == "Berangkat" and city_data.insiden_aktif.is_empty():
				unit.status = "Siaga di markas"
				unit.target_pos = Vector2i(-1, -1)
		if unit.node == null or not is_instance_valid(unit.node):
			_create_unit_visual(unit)
		new_units.append(unit)

	# Hapus visual unit yang gedungnya sudah dibongkar
	var keep_ids: Dictionary = {}
	for nu in new_units:
		keep_ids[nu.id] = true
	for ou in units:
		if not keep_ids.has(ou.id) and ou.node and is_instance_valid(ou.node):
			ou.node.queue_free()

	units = new_units
	_save_unit_statuses()

func _save_unit_statuses() -> void:
	if not city_data:
		return
	var arr: Array = []
	for u in units:
		arr.append({
			"id": u.id,
			"kind": u.kind,
			"home_name": u.home_name,
			"home_pos": u.home_pos,
			"status": u.status,
			"target_pos": u.target_pos
		})
	city_data.unit_status = arr

func has_patrol_active() -> bool:
	for u in units:
		if u.kind == "polisi":
			return true
	return false

func is_any_unit_busy(kind: String) -> bool:
	for u in units:
		if u.kind == kind and u.status != "Siaga di markas":
			return true
	return false

func has_unit_kind(kind: String) -> bool:
	for u in units:
		if u.kind == kind:
			return true
	return false

func get_unit_eta_text(kind: String) -> String:
	for u in units:
		if u.kind == kind and u.status == "Berangkat":
			var rem: int = maxi(1, u.path.size() - u.path_idx)
			return "%d tile (~%d dtk)" % [rem, maxi(1, int(ceil(float(rem) / u.speed)))]
		elif u.kind == kind and u.status == "Di Lokasi":
			return "Di lokasi"
		elif u.kind == kind and u.status == "Kembali":
			return "Kembali ke markas"
	return "Siaga"

func dispatch_unit(kind: String, target_pos: Vector2i) -> Dictionary:
	if not city_data:
		return {"ok": false, "reason": "Kota belum siap"}
	var has_kind: bool = false
	for u in units:
		if u.kind == kind:
			has_kind = true
			if u.status == "Siaga di markas":
				u.target_pos = target_pos
				u.status = "Berangkat"
				u.path = _find_road_path(u.home_pos, target_pos)
				u.path_idx = 0
				u.progress = 0.0
				if u.node and is_instance_valid(u.node):
					var start_p: Vector3 = CityData.tile_to_world_pos(u.home_pos.x, u.home_pos.y)
					start_p.y = 0.06
					u.node.global_position = start_p
					u.node.visible = true
				_update_unit_label(u)
				_save_unit_statuses()
				return {"ok": true, "reason": "Unit berangkat"}
	if not has_kind:
		match kind:
			"damkar":
				if city_data.count_public_type(CityData.TileType.FIRE_STATION) > 0:
					return {"ok": false, "reason": "Sambungkan pipa air ke Damkar dulu"}
				return {"ok": false, "reason": "Bangun Damkar dulu"}
			"polisi":
				return {"ok": false, "reason": "Bangun Kantor Polisi dulu"}
			"ambulans":
				return {"ok": false, "reason": "Bangun RS / Puskesmas dulu"}
			"tni":
				return {"ok": false, "reason": "Bangun Markas TNI dulu"}
	return {"ok": false, "reason": "Unit sedang bertugas"}

func recall_units_for_resolved_incident() -> void:
	for u in units:
		if u.status == "Berangkat" or u.status == "Di Lokasi":
			u.status = "Kembali"
			u.path = _find_road_path(u.target_pos, u.home_pos)
			u.path_idx = 0
			u.progress = 0.0
			_update_unit_label(u)
	_save_unit_statuses()

func _process(delta: float) -> void:
	if not city_data:
		return
	_blink_accum += delta * 6.0
	var lamp_on: bool = sin(_blink_accum) > 0.0
	var patrol_assigned: bool = false

	for u in units:
		if not u.node or not is_instance_valid(u.node):
			continue

		# Jika target insiden sudah tidak ada (misal dibulldoze/selesai), unit kembali ke markas
		if (u.status == "Berangkat" or u.status == "Di Lokasi") and city_data.insiden_aktif.is_empty():
			u.status = "Kembali"
			u.path = _find_road_path(u.target_pos, u.home_pos)
			u.path_idx = 0
			u.progress = 0.0
			_update_unit_label(u)
			_save_unit_statuses()

		if u.status == "Berangkat" or u.status == "Kembali":
			u.node.visible = true
			if u.lamp_node and is_instance_valid(u.lamp_node):
				u.lamp_node.visible = lamp_on
			if u.spray_node and is_instance_valid(u.spray_node):
				u.spray_node.visible = false
			_move_along_path(u, delta)
		elif u.status == "Di Lokasi":
			u.node.visible = true
			if u.lamp_node and is_instance_valid(u.lamp_node):
				u.lamp_node.visible = lamp_on
			if u.spray_node and is_instance_valid(u.spray_node):
				u.spray_node.visible = (u.kind == "damkar")
			_update_unit_label(u)
		else:
			if u.spray_node and is_instance_valid(u.spray_node):
				u.spray_node.visible = false
			# Siaga di markas: 1 mobil polisi berpatroli pelan keliling kota jika ada jalan
			if u.kind == "polisi" and not patrol_assigned and city_data.insiden_aktif.is_empty():
				patrol_assigned = true
				_process_patrol(u, delta)
			else:
				u.node.visible = false
				if u.lamp_node and is_instance_valid(u.lamp_node):
					u.lamp_node.visible = false

func _move_along_path(u: EmergencyUnit, delta: float) -> void:
	if u.path.size() < 2 or u.path_idx >= u.path.size() - 1:
		if u.status == "Berangkat":
			u.status = "Di Lokasi"
			var tp: Vector3 = CityData.tile_to_world_pos(u.target_pos.x, u.target_pos.y)
			tp.y = 0.06
			u.node.global_position = tp
			_update_unit_label(u)
			_save_unit_statuses()
			unit_arrived.emit(u.kind, u.target_pos)
		else:
			u.status = "Siaga di markas"
			u.target_pos = Vector2i(-1, -1)
			u.node.visible = false
			_update_unit_label(u)
			_save_unit_statuses()
			unit_returned.emit(u.kind)
		return

	u.progress += u.speed * speed_multiplier * delta
	while u.progress >= 1.0 and u.path_idx < u.path.size() - 1:
		u.progress -= 1.0
		u.path_idx += 1

	if u.path_idx >= u.path.size() - 1:
		u.progress = 1.0
		var end_p: Vector3 = CityData.tile_to_world_pos(u.path[u.path.size() - 1].x, u.path[u.path.size() - 1].y)
		end_p.y = 0.06
		u.node.global_position = end_p
		return

	var t1: Vector2i = u.path[u.path_idx]
	var t2: Vector2i = u.path[u.path_idx + 1]
	var p1: Vector3 = CityData.tile_to_world_pos(t1.x, t1.y)
	var p2: Vector3 = CityData.tile_to_world_pos(t2.x, t2.y)
	var cur: Vector3 = p1.lerp(p2, u.progress)
	cur.y = 0.06
	u.node.global_position = cur
	var d: Vector3 = (p2 - p1).normalized()
	if d.length_squared() > 0.001:
		u.node.rotation.y = lerp_angle(u.node.rotation.y, atan2(-d.x, -d.z), clampf(delta * 10.0, 0.0, 1.0))

func _process_patrol(u: EmergencyUnit, delta: float) -> void:
	var road_tiles: Array[Vector2i] = []
	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			if _is_road_tile(Vector2i(x, y)):
				road_tiles.append(Vector2i(x, y))
	if road_tiles.is_empty():
		u.node.visible = false
		return
	if not _is_road_tile(u.patrol_cur) or not _is_road_tile(u.patrol_nxt):
		u.patrol_cur = road_tiles[0]
		u.patrol_nxt = _pick_patrol_neighbor(u.patrol_cur)
		u.progress = 0.0
	u.progress += 1.4 * speed_multiplier * delta
	if u.progress >= 1.0:
		u.progress = 0.0
		u.patrol_cur = u.patrol_nxt
		u.patrol_nxt = _pick_patrol_neighbor(u.patrol_cur)
	var p1: Vector3 = CityData.tile_to_world_pos(u.patrol_cur.x, u.patrol_cur.y)
	var p2: Vector3 = CityData.tile_to_world_pos(u.patrol_nxt.x, u.patrol_nxt.y)
	var pos: Vector3 = p1.lerp(p2, u.progress)
	pos.y = 0.06
	u.node.global_position = pos
	u.node.visible = true
	if u.status_label:
		u.status_label.text = "Patroli"
		u.status_label.visible = true
	var d: Vector3 = (p2 - p1).normalized()
	if d.length_squared() > 0.001:
		u.node.rotation.y = lerp_angle(u.node.rotation.y, atan2(-d.x, -d.z), clampf(delta * 8.0, 0.0, 1.0))

func _pick_patrol_neighbor(tile: Vector2i) -> Vector2i:
	var opts: Array[Vector2i] = []
	for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nxt: Vector2i = tile + dir
		if _is_road_tile(nxt):
			opts.append(nxt)
	if opts.is_empty():
		return tile
	return opts[randi() % opts.size()]

func _is_road_tile(t: Vector2i) -> bool:
	if not city_data or not city_data.is_valid_tile(t.x, t.y):
		return false
	var tp: int = int(city_data.get_tile(t.x, t.y).get("type", CityData.TileType.EMPTY))
	return tp in [CityData.TileType.ROAD, CityData.TileType.STOP_ANGKOT, CityData.TileType.STOP_BUS, CityData.TileType.FLYOVER]

func _find_road_path(start_t: Vector2i, goal_t: Vector2i) -> Array[Vector2i]:
	var start_road: Vector2i = _nearest_road_tile(start_t)
	var goal_road: Vector2i = _nearest_road_tile(goal_t)
	if start_road == Vector2i(-1, -1) or goal_road == Vector2i(-1, -1):
		return [start_t, goal_t]
	var queue: Array[Vector2i] = [start_road]
	var came_from: Dictionary = {start_road: start_road}
	var found: bool = false
	var limit: int = 0
	while not queue.is_empty() and limit < 1200:
		limit += 1
		var cur: Vector2i = queue.pop_front() as Vector2i
		if cur == goal_road:
			found = true
			break
		for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nxt: Vector2i = cur + dir
			if not came_from.has(nxt) and _is_road_tile(nxt):
				came_from[nxt] = cur
				queue.append(nxt)
	if not found:
		return [start_t, goal_t]
	var rev: Array[Vector2i] = []
	var step: Vector2i = goal_road
	while step != start_road:
		rev.append(step)
		step = came_from[step] as Vector2i
	rev.append(start_road)
	rev.reverse()
	var result: Array[Vector2i] = [start_t]
	result.append_array(rev)
	result.append(goal_t)
	return result

func _nearest_road_tile(center: Vector2i) -> Vector2i:
	for dir: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var c: Vector2i = center + dir
		if _is_road_tile(c):
			return c
	return Vector2i(-1, -1)

func _update_unit_label(u: EmergencyUnit) -> void:
	if not u.status_label or not is_instance_valid(u.status_label):
		return
	if u.status == "Siaga di markas":
		u.status_label.visible = false
	else:
		u.status_label.text = u.status
		u.status_label.visible = true

func _get_mat(key: String, col: Color, emissive: bool = false) -> StandardMaterial3D:
	if _shared_mats.has(key):
		return _shared_mats[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	if emissive:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 1.6
	_shared_mats[key] = mat
	return mat

func _get_box(key: String, sz: Vector3) -> BoxMesh:
	if _shared_boxes.has(key):
		return _shared_boxes[key] as BoxMesh
	var bm := BoxMesh.new()
	bm.size = sz
	_shared_boxes[key] = bm
	return bm

func _create_unit_visual(u: EmergencyUnit) -> void:
	var root := Node3D.new()
	root.visible = false

	var body_col: Color = Color(0.88, 0.16, 0.14)
	var body_sz: Vector3 = Vector3(0.48, 0.28, 0.96)
	var lamp_col: Color = Color(0.20, 0.65, 1.0)
	if u.kind == "polisi":
		body_col = Color(0.92, 0.94, 0.98)
		body_sz = Vector3(0.44, 0.22, 0.84)
		lamp_col = Color(0.20, 0.55, 1.0)
	elif u.kind == "ambulans":
		body_col = Color(0.96, 0.96, 0.96)
		body_sz = Vector3(0.48, 0.30, 0.92)
		lamp_col = Color(1.0, 0.22, 0.22)
	elif u.kind == "tni":
		body_col = Color(0.28, 0.42, 0.22)
		body_sz = Vector3(0.54, 0.36, 1.10)
		lamp_col = Color(1.0, 0.78, 0.20)

	var body := MeshInstance3D.new()
	body.mesh = _get_box("u_body_%s" % u.kind, body_sz)
	body.material_override = _get_mat("u_mat_%s" % u.kind, body_col)
	body.position = Vector3(0.0, body_sz.y * 0.5 + 0.08, 0.0)
	root.add_child(body)

	var stripe := MeshInstance3D.new()
	var st_col: Color = Color(0.18, 0.42, 0.85) if u.kind == "polisi" else (Color(0.88, 0.18, 0.18) if u.kind == "ambulans" else Color(0.92, 0.92, 0.90))
	stripe.mesh = _get_box("u_stripe_%s" % u.kind, Vector3(body_sz.x + 0.02, 0.06, body_sz.z * 0.65))
	stripe.material_override = _get_mat("u_st_%s" % u.kind, st_col)
	stripe.position = Vector3(0.0, body_sz.y * 0.6 + 0.08, 0.0)
	root.add_child(stripe)

	var lamp := MeshInstance3D.new()
	lamp.mesh = _get_box("u_lamp", Vector3(0.22, 0.08, 0.12))
	lamp.material_override = _get_mat("u_lmp_%s" % u.kind, lamp_col, true)
	lamp.position = Vector3(0.0, body_sz.y + 0.12, 0.10)
	lamp.visible = false
	root.add_child(lamp)

	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 20
	lbl.outline_size = 3
	lbl.modulate = Color(1.0, 0.95, 0.70)
	lbl.position = Vector3(0.0, body_sz.y + 0.45, 0.0)
	lbl.visible = false
	root.add_child(lbl)

	if u.kind == "damkar":
		var spray := MeshInstance3D.new()
		spray.mesh = _get_box("u_water_spray", Vector3(0.08, 0.08, 1.35))
		spray.material_override = _get_mat("u_spray_mat", Color(0.35, 0.78, 1.0), true)
		spray.position = Vector3(0.0, 0.36, -1.05)
		spray.visible = false
		root.add_child(spray)
		u.spray_node = spray

	add_child(root)
	u.node = root
	u.lamp_node = lamp
	u.status_label = lbl
