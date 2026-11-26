class_name CarController
extends Node3D

## Mengontrol 3 mobil low-poly sederhana yang melaju di atas tile Jalan

class SimpleCar:
	var node: Node3D
	var current_tile: Vector2i = Vector2i(-1, -1)
	var target_tile: Vector2i = Vector2i(-1, -1)
	var progress: float = 0.0
	var speed: float = 2.2 # tile per detik
	var active: bool = false
	var last_dir: Vector2i = Vector2i.ZERO

var cars: Array = []
var city_data: CityData
var speed_multiplier: float = 1.0

func setup(p_city_data: CityData) -> void:
	city_data = p_city_data
	_create_car_models()

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
			car.current_tile = start_tile
			car.target_tile = _pick_next_road(start_tile, Vector2i.ZERO)
			car.progress = 0.0
			car.active = true
			car.node.visible = true

		car.progress += car.speed * speed_multiplier * delta
		if car.progress >= 1.0:
			car.progress = 0.0
			var prev_tile := car.current_tile
			car.current_tile = car.target_tile
			var move_dir := car.target_tile - prev_tile
			car.target_tile = _pick_next_road(car.current_tile, move_dir)

		# Interpolasi posisi
		var p1 := CityData.tile_to_world_pos(car.current_tile.x, car.current_tile.y)
		var p2 := CityData.tile_to_world_pos(car.target_tile.x, car.target_tile.y)
		var cur_pos := p1.lerp(p2, car.progress)
		cur_pos.y = 0.04
		car.node.global_position = cur_pos

		# Rotasi menghadap arah jalan
		var dir := (p2 - p1).normalized()
		if dir.length_squared() > 0.001:
			var target_rot_y := atan2(-dir.x, -dir.z)
			car.node.rotation.y = target_rot_y

func _is_road(tile: Vector2i) -> bool:
	if not city_data.is_valid_tile(tile.x, tile.y):
		return false
	return city_data.get_tile(tile.x, tile.y).get("type", CityData.TileType.EMPTY) == CityData.TileType.ROAD

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
