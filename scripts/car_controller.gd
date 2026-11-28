class_name CarController
extends Node3D

## Mengontrol 3 mobil low-poly sederhana yang melaju di atas tile Jalan

class SimpleCar:
	var node: Node3D
	var prev_tile: Vector2i = Vector2i(-1, -1)
	var current_tile: Vector2i = Vector2i(-1, -1)
	var target_tile: Vector2i = Vector2i(-1, -1)
	var progress: float = 0.0
	var speed: float = 2.2 # tile per detik
	var active: bool = false
	var last_dir: Vector2i = Vector2i.ZERO

var cars: Array = []
var transit_vehicles: Array = [] # Angkot, Kopaja, Busway, Train
var airplanes: Array = []
var city_data: CityData
var speed_multiplier: float = 1.0
var is_angkot_ngetem_active: bool = false
var traffic_red_light: bool = false

func setup(p_city_data: CityData) -> void:
	city_data = p_city_data
	_create_car_models()
	_create_transit_models()

func _create_car_models() -> void:
	var colors = [
		Color(0.85, 0.2, 0.2), # Merah
		Color(0.2, 0.5, 0.9), # Biru
		Color(0.9, 0.75, 0.1) # Kuning
	]

	for i in range(3):
		var car_node := Node3D.new()
		car_node.visible = false

		# Bodi mobil
		var body := MeshInstance3D.new()
		var body_box := BoxMesh.new()
		body_box.size = Vector3(0.45, 0.20, 0.8)
		var body_mat := StandardMaterial3D.new()
		body_mat.albedo_color = colors[i]
		body.mesh = body_box
		body.position = Vector3(0.0, 0.16, 0.0)
		car_node.add_child(body)

		# Kabin kaca
		var roof := MeshInstance3D.new()
		var roof_box := BoxMesh.new()
		roof_box.size = Vector3(0.38, 0.16, 0.42)
		var roof_mat := StandardMaterial3D.new()
		roof_mat.albedo_color = Color(0.8, 0.9, 0.95)
		roof.mesh = roof_box
		roof.position = Vector3(0.0, 0.32, -0.05)
		car_node.add_child(roof)

		# 4 Roda hitam
		for wx in [-0.22, 0.22]:
			for wz in [-0.24, 0.24]:
				var wheel := MeshInstance3D.new()
				var wheel_box := BoxMesh.new()
				wheel_box.size = Vector3(0.08, 0.12, 0.16)
				var wheel_mat := StandardMaterial3D.new()
				wheel_mat.albedo_color = Color(0.15, 0.15, 0.15)
				wheel.mesh = wheel_box
				wheel.position = Vector3(wx, 0.08, wz)
				car_node.add_child(wheel)

		add_child(car_node)

		var car_obj := SimpleCar.new()
		car_obj.node = car_node
		cars.append(car_obj)

func _process(delta: float) -> void:
	if not city_data:
		return

	var road_tiles: Array = []
	for y in range(CityData.GRID_SIZE):
		for x in range(CityData.GRID_SIZE):
			if city_data.get_tile(x, y).get("type", CityData.TileType.EMPTY) == CityData.TileType.ROAD:
				road_tiles.append(Vector2i(x, y))

	# Jika tidak ada jalan sama sekali, sembunyikan semua mobil
	if road_tiles.is_empty():
		for car in cars:
			car.active = false
			car.node.visible = false
		return

	# Update tiap mobil
	for i in range(cars.size()):
		var car: SimpleCar = cars[i]
		if not car.active or not _is_road(car.current_tile) or not _is_road(car.target_tile):
			# Respawn mobil di salah satu tile jalan acak
			var start_tile: Vector2i = road_tiles[(i * 3 + randi()) % road_tiles.size()]
			car.prev_tile = start_tile
			car.current_tile = start_tile
			car.target_tile = _pick_next_road(car.current_tile, Vector2i.ZERO)
			car.progress = 0.0
			car.active = true
			car.node.visible = true

		var flood_slow := 0.5 if city_data.event_aktif.get("id", "") == "banjir" else 1.0
		var light_mult := 0.0 if (traffic_red_light and _is_intersection_tile(car.current_tile)) else 1.0
		car.progress += car.speed * speed_multiplier * flood_slow * light_mult * delta
		if car.progress >= 1.0:
			car.progress = 0.0
			car.prev_tile = car.current_tile
			car.current_tile = car.target_tile
			var move_dir := car.current_tile - car.prev_tile
			car.target_tile = _pick_next_road(car.current_tile, move_dir)

		# Kurva Bezier halus agar mobil belok mengikuti tikungan & persimpangan
		var p_mid := CityData.tile_to_world_pos(car.current_tile.x, car.current_tile.y)
		var p_in := CityData.tile_to_world_pos(car.prev_tile.x, car.prev_tile.y).lerp(p_mid, 0.5) if _is_road(car.prev_tile) else p_mid
		var p_out := p_mid.lerp(CityData.tile_to_world_pos(car.target_tile.x, car.target_tile.y), 0.5)
		var q0 := p_in.lerp(p_mid, car.progress)
		var q1 := p_mid.lerp(p_out, car.progress)
		var cur_pos := q0.lerp(q1, car.progress)
		var on_flyover: bool = city_data.flyovers.has(car.current_tile) or city_data.flyovers.has(car.target_tile)
		cur_pos.y = 1.08 if on_flyover else 0.04
		car.node.global_position = cur_pos

		# Rotasi halus mengikuti arah tikungan
		var dir := (q1 - q0).normalized()
		if dir.length_squared() > 0.001:
			var target_rot_y := atan2(-dir.x, -dir.z)
			car.node.rotation.y = lerp_angle(car.node.rotation.y, target_rot_y, clampf(delta * 10.0, 0.0, 1.0))

	_process_transit(delta, road_tiles)
	_process_airplanes(delta)

func _is_road(tile: Vector2i) -> bool:
	if not city_data.is_valid_tile(tile.x, tile.y):
		return false
	var tp: int = city_data.get_tile(tile.x, tile.y).get("type", CityData.TileType.EMPTY)
	return tp in [CityData.TileType.ROAD, CityData.TileType.STOP_ANGKOT, CityData.TileType.STOP_BUS, CityData.TileType.FLYOVER]

func _is_intersection_tile(tile: Vector2i) -> bool:
	var adj := 0
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if _is_road(tile + d):
			adj += 1
	return adj >= 3

func _create_transit_models() -> void:
	var specs := [
		{"kind": "angkot", "color": Color(0.22, 0.72, 0.90), "size": Vector3(0.46, 0.28, 0.85)},
		{"kind": "kopaja", "color": Color(0.95, 0.52, 0.14), "size": Vector3(0.52, 0.36, 1.15)},
		{"kind": "kopaja", "color": Color(0.95, 0.52, 0.14), "size": Vector3(0.52, 0.36, 1.15)},
		{"kind": "kopaja", "color": Color(0.95, 0.52, 0.14), "size": Vector3(0.52, 0.36, 1.15)},
		{"kind": "busway", "color": Color(0.88, 0.18, 0.18), "size": Vector3(0.54, 0.38, 1.35)},
		{"kind": "busway", "color": Color(0.88, 0.18, 0.18), "size": Vector3(0.54, 0.38, 1.35)},
		{"kind": "train", "color": Color(0.92, 0.94, 0.96), "size": Vector3(0.62, 0.44, 1.65)}
	]
	for sp in specs:
		var n := Node3D.new()
		n.visible = false
		var m := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = sp["size"]
		var mat := StandardMaterial3D.new()
		mat.albedo_color = sp["color"]
		m.mesh = b
		m.material_override = mat
		m.position = Vector3(0.0, sp["size"].y * 0.5 + 0.06, 0.0)
		n.add_child(m)
		add_child(n)
		transit_vehicles.append({
			"kind": sp["kind"],
			"node": n,
			"cur": Vector2i(-1, -1),
			"nxt": Vector2i(-1, -1),
			"progress": 0.0,
			"pause": 0.0,
			"dir": Vector2i.ZERO
		})

	for _a in range(2):
		var ap := BuildingBuilder.create_airplane_node()
		ap.visible = false
		add_child(ap)
		airplanes.append({"node": ap, "timer": randf() * 12.0})

func _process_transit(delta: float, road_tiles: Array) -> void:
	is_angkot_ngetem_active = false
	var kopaja_idx := 0
	var busway_idx := 0
	var busway_tiles := city_data.get_public_positions(CityData.TileType.BUSWAY_LANE)
	busway_tiles.append_array(city_data.get_public_positions(CityData.TileType.STOP_BUSWAY))
	var rail_tiles := city_data.get_public_positions(CityData.TileType.RAIL)
	rail_tiles.append_array(city_data.get_public_positions(CityData.TileType.TRAIN_STATION))
	var has_angkot_stop := city_data.count_public_type(CityData.TileType.STOP_ANGKOT) > 0
	var has_2_stations := city_data.get_working_public_positions(CityData.TileType.TRAIN_STATION).size() >= 2

	for tv in transit_vehicles:
		var kind: String = tv["kind"]
		var n: Node3D = tv["node"]
		var pool: Array = []
		var allowed := false
		if kind == "angkot":
			allowed = city_data.population >= 50 and not road_tiles.is_empty()
			pool = road_tiles
		elif kind == "kopaja":
			allowed = kopaja_idx < city_data.bus_kopaja_count and not road_tiles.is_empty()
			kopaja_idx += 1
			pool = road_tiles
		elif kind == "busway":
			allowed = busway_idx < city_data.busway_count and not busway_tiles.is_empty() and city_data.has_working_public(CityData.TileType.STOP_BUSWAY)
			busway_idx += 1
			pool = busway_tiles
		elif kind == "train":
			allowed = has_2_stations and not rail_tiles.is_empty()
			pool = rail_tiles

		if not allowed:
			n.visible = false
			continue

		if tv["pause"] > 0.0:
			tv["pause"] -= delta * speed_multiplier
			if kind == "angkot" and not has_angkot_stop:
				is_angkot_ngetem_active = true
			continue

		var cur: Vector2i = tv["cur"]
		var nxt: Vector2i = tv["nxt"]
		if not (cur in pool) or not (nxt in pool):
			cur = pool[randi() % pool.size()]
			nxt = _pick_next_from_pool(cur, tv["dir"], pool)
			tv["cur"] = cur
			tv["nxt"] = nxt
			tv["progress"] = 0.0

		tv["progress"] += 1.9 * speed_multiplier * delta
		if tv["progress"] >= 1.0:
			tv["progress"] = 0.0
			var prev := cur
			cur = nxt
			tv["dir"] = nxt - prev
			nxt = _pick_next_from_pool(cur, tv["dir"], pool)
			tv["cur"] = cur
			tv["nxt"] = nxt
			if kind == "angkot" and not has_angkot_stop and randf() < 0.25:
				tv["pause"] = 2.5
				is_angkot_ngetem_active = true

		var p1 := CityData.tile_to_world_pos(cur.x, cur.y)
		var p2 := CityData.tile_to_world_pos(nxt.x, nxt.y)
		var pos: Vector3 = p1.lerp(p2, float(tv["progress"]))
		pos.y = 0.05
		n.global_position = pos
		n.visible = true
		var d := (p2 - p1).normalized()
		if d.length_squared() > 0.001:
			n.rotation.y = lerp_angle(n.rotation.y, atan2(-d.x, -d.z), clampf(delta * 10.0, 0.0, 1.0))

func _pick_next_from_pool(from_tile: Vector2i, prev_dir: Vector2i, pool: Array) -> Vector2i:
	var opts: Array[Vector2i] = []
	var non_rev: Array[Vector2i] = []
	for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nxt: Vector2i = from_tile + dir
		if nxt in pool:
			opts.append(nxt)
			if prev_dir != Vector2i.ZERO and dir != -prev_dir:
				non_rev.append(nxt)
	if not non_rev.is_empty():
		return non_rev[randi() % non_rev.size()]
	if not opts.is_empty():
		return opts[randi() % opts.size()]
	return from_tile

func _process_airplanes(delta: float) -> void:
	var runways := city_data.get_public_positions(CityData.TileType.RUNWAY)
	var airport_ok := city_data.has_working_airport() and not runways.is_empty()
	for idx in range(airplanes.size()):
		var ap: Dictionary = airplanes[idx]
		var node: Node3D = ap["node"]
		if idx >= city_data.airplane_count or runways.is_empty():
			node.visible = false
			continue
		var base_tile: Vector2i = runways[mini(idx * 3, runways.size() - 1)]
		var base_pos := CityData.tile_to_world_pos(base_tile.x, base_tile.y)
		if not airport_ok:
			node.visible = true
			node.global_position = base_pos + Vector3(0.0, 0.05, 0.0)
			continue
		ap["timer"] = fmod(float(ap["timer"]) + delta * speed_multiplier, 24.0)
		var t: float = float(ap["timer"])
		if t < 6.0:
			node.visible = true
			node.global_position = base_pos + Vector3(0.0, 0.05, 0.0)
		elif t < 12.0:
			var k: float = (t - 6.0) / 6.0
			node.visible = true
			node.global_position = base_pos + Vector3(0.0, 0.05 + k * 14.0, k * 18.0)
		elif t < 18.0:
			node.visible = false
		else:
			var k: float = (24.0 - t) / 6.0
			node.visible = true
			node.global_position = base_pos + Vector3(0.0, 0.05 + k * 14.0, -k * 18.0)

func _pick_next_road(from_tile: Vector2i, prev_dir: Vector2i) -> Vector2i:
	var neighbors: Array[Vector2i] = [
		Vector2i(from_tile.x + 1, from_tile.y),
		Vector2i(from_tile.x - 1, from_tile.y),
		Vector2i(from_tile.x, from_tile.y + 1),
		Vector2i(from_tile.x, from_tile.y - 1)
	]
	var valid_roads: Array[Vector2i] = []
	var non_reverse_roads: Array[Vector2i] = []

	for n: Vector2i in neighbors:
		if _is_road(n):
			valid_roads.append(n)
			var d: Vector2i = n - from_tile
			# Hindari langsung putar balik jika ada opsi belok/lurus lain
			if prev_dir != Vector2i.ZERO and d != -prev_dir:
				non_reverse_roads.append(n)

	if not non_reverse_roads.is_empty():
		return non_reverse_roads[randi() % non_reverse_roads.size()]
	elif not valid_roads.is_empty():
		return valid_roads[randi() % valid_roads.size()]
	else:
		return from_tile
