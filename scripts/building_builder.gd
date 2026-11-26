class_name BuildingBuilder
extends RefCounted

## Generator visual 3D prosedural untuk tile, zona, dan bangunan low-poly (Godot 4.7)

static func create_tile_node(type: CityData.TileType, level: int = 0, zone: CityData.BuildingZone = CityData.BuildingZone.RESIDENTIAL, has_util: bool = true) -> Node3D:
	var root := Node3D.new()

	match type:
		CityData.TileType.ROAD:
			root.add_child(_create_road_mesh())
		CityData.TileType.ZONE_R:
			if level == 0:
				root.add_child(_create_zone_marker(Color(0.2, 0.8, 0.25, 0.45)))
			else:
				root.add_child(_create_residential_building(level))
		CityData.TileType.ZONE_C:
			if level == 0:
				root.add_child(_create_zone_marker(Color(0.2, 0.45, 0.95, 0.45)))
			else:
				root.add_child(_create_commercial_building(level))
		CityData.TileType.ZONE_I:
			if level == 0:
				root.add_child(_create_zone_marker(Color(0.95, 0.65, 0.1, 0.45)))
			else:
				root.add_child(_create_industrial_building(level))
		CityData.TileType.BUILDING:
			match zone:
				CityData.BuildingZone.RESIDENTIAL:
					root.add_child(_create_residential_building(level))
				CityData.BuildingZone.COMMERCIAL:
					root.add_child(_create_commercial_building(level))
				CityData.BuildingZone.INDUSTRIAL:
					root.add_child(_create_industrial_building(level))
		CityData.TileType.POWER_PLANT:
			root.add_child(_create_power_plant_mesh())
		CityData.TileType.WATER_TOWER:
			root.add_child(_create_water_tower_mesh())
		CityData.TileType.PARK:
			root.add_child(_create_park_mesh())
		CityData.TileType.FARM:
			root.add_child(_create_farm_mesh(level))
		CityData.TileType.OFFICIAL_PARKING:
			root.add_child(_create_official_parking_mesh())
		CityData.TileType.TOWNHALL:
			root.add_child(_create_townhall_mesh())

	# Indikator jika bangunan tidak mendapat suplai utilitas (listrik / air)
	if not has_util and (type == CityData.TileType.BUILDING or (level > 0 and type in [CityData.TileType.ZONE_R, CityData.TileType.ZONE_C, CityData.TileType.ZONE_I])):
		var badge := Label3D.new()
		badge.text = "⚠️"
		badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		badge.font_size = 28
		badge.modulate = Color(1.0, 0.3, 0.3)
		badge.outline_render_priority = 1
		badge.outline_size = 4
		badge.outline_modulate = Color(0.1, 0.1, 0.1)
		badge.no_depth_test = true
		badge.position = Vector3(0.0, 0.8 + float(level) * 0.7, 0.0)
		root.add_child(badge)

	return root

static func _create_zone_marker(color: Color) -> Node3D:
	var node := Node3D.new()
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.9, 0.02, 1.9)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.8
	mesh_inst.mesh = box
	mesh_inst.position = Vector3(0.0, 0.015, 0.0)
	node.add_child(mesh_inst)
	return node

static func _create_road_mesh() -> Node3D:
	var node := Node3D.new()
	# Permukaan aspal
	var road_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.0, 0.03, 2.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.22, 0.24)
	mat.roughness = 0.9
	road_inst.mesh = box
	road_inst.position = Vector3(0.0, 0.015, 0.0)
	node.add_child(road_inst)

	# Marka jalan (garis tengah putih)
	var stripe_inst := MeshInstance3D.new()
	var stripe_box := BoxMesh.new()
	stripe_box.size = Vector3(0.2, 0.035, 1.2)
	var stripe_mat := StandardMaterial3D.new()
	stripe_mat.albedo_color = Color(0.9, 0.9, 0.9)
	stripe_inst.mesh = stripe_box
	stripe_inst.position = Vector3(0.0, 0.02, 0.0)
	node.add_child(stripe_inst)

	return node

## --- RESIDENTIAL (Rumah kecil warna pastel + atap merah/coklat) ---
static func _create_residential_building(level: int) -> Node3D:
	var node := Node3D.new()

	var wall_color := Color(0.94, 0.88, 0.78) # Krem pastel
	var roof_color := Color(0.75, 0.26, 0.20) # Terracotta merah

	if level <= 1:
		# Rumah Lv 1: Dinding kecil + Atap pelana
		var wall := MeshInstance3D.new()
		var wall_box := BoxMesh.new()
		wall_box.size = Vector3(1.2, 0.8, 1.2)
		var wall_mat := StandardMaterial3D.new()
		wall_mat.albedo_color = wall_color
		wall.mesh = wall_box
		wall.position = Vector3(0.0, 0.4, 0.0)
		node.add_child(wall)

		var roof := MeshInstance3D.new()
		var roof_prism := PrismMesh.new()
		roof_prism.size = Vector3(1.3, 0.5, 1.3)
		var roof_mat := StandardMaterial3D.new()
		roof_mat.albedo_color = roof_color
		roof.mesh = roof_prism
		roof.position = Vector3(0.0, 1.05, 0.0)
		node.add_child(roof)

		# Pintu coklat
		var door := MeshInstance3D.new()
		var door_box := BoxMesh.new()
		door_box.size = Vector3(0.25, 0.4, 0.05)
		var door_mat := StandardMaterial3D.new()
		door_mat.albedo_color = Color(0.4, 0.25, 0.15)
		door.mesh = door_box
		door.position = Vector3(0.0, 0.2, 0.6)
		node.add_child(door)

	elif level == 2:
		# Rumah Lv 2: Dupleks 2 lantai + teras samping
		var wall := MeshInstance3D.new()
		var wall_box := BoxMesh.new()
		wall_box.size = Vector3(1.3, 1.5, 1.3)
		var wall_mat := StandardMaterial3D.new()
		wall_mat.albedo_color = Color(0.85, 0.90, 0.95) # Biru muda pastel
		wall.mesh = wall_box
		wall.position = Vector3(0.0, 0.75, 0.0)
		node.add_child(wall)

		var roof := MeshInstance3D.new()
		var roof_prism := PrismMesh.new()
		roof_prism.size = Vector3(1.4, 0.6, 1.4)
		var roof_mat := StandardMaterial3D.new()
		roof_mat.albedo_color = Color(0.65, 0.22, 0.18)
		roof.mesh = roof_prism
		roof.position = Vector3(0.0, 1.8, 0.0)
		node.add_child(roof)

		# Jendela tingkat 2
		var win := MeshInstance3D.new()
		var win_box := BoxMesh.new()
		win_box.size = Vector3(0.7, 0.35, 0.05)
		var win_mat := StandardMaterial3D.new()
		win_mat.albedo_color = Color(0.3, 0.6, 0.85)
		win.mesh = win_box
		win.position = Vector3(0.0, 1.1, 0.65)
		node.add_child(win)

	else:
		# Rumah Lv 3: Townhouse modern 3 lantai + balkon
		var wall := MeshInstance3D.new()
		var wall_box := BoxMesh.new()
		wall_box.size = Vector3(1.4, 2.2, 1.4)
		var wall_mat := StandardMaterial3D.new()
		wall_mat.albedo_color = Color(0.92, 0.94, 0.92)
		wall.mesh = wall_box
		wall.position = Vector3(0.0, 1.1, 0.0)
		node.add_child(wall)

		var roof := MeshInstance3D.new()
		var roof_prism := PrismMesh.new()
		roof_prism.size = Vector3(1.5, 0.5, 1.5)
		var roof_mat := StandardMaterial3D.new()
		roof_mat.albedo_color = Color(0.35, 0.35, 0.40) # Atap modern gelap
		roof.mesh = roof_prism
		roof.position = Vector3(0.0, 2.45, 0.0)
		node.add_child(roof)

		# Balkon lantai 2
		var balc := MeshInstance3D.new()
		var balc_box := BoxMesh.new()
		balc_box.size = Vector3(0.9, 0.15, 0.3)
		var balc_mat := StandardMaterial3D.new()
		balc_mat.albedo_color = Color(0.3, 0.3, 0.3)
		balc.mesh = balc_box
		balc.position = Vector3(0.0, 1.2, 0.75)
		node.add_child(balc)

	return node

## --- COMMERCIAL (Toko / kantor box lebih tinggi + jendela) ---
static func _create_commercial_building(level: int) -> Node3D:
	var node := Node3D.new()

	if level <= 1:
		# Toko retail Lv 1
		var base := MeshInstance3D.new()
		var base_box := BoxMesh.new()
		base_box.size = Vector3(1.3, 1.2, 1.3)
		var base_mat := StandardMaterial3D.new()
		base_mat.albedo_color = Color(0.85, 0.92, 0.98) # Cyan lembut
		base.mesh = base_box
		base.position = Vector3(0.0, 0.6, 0.0)
		node.add_child(base)

		# Kaca etalase toko
		var glass := MeshInstance3D.new()
		var glass_box := BoxMesh.new()
		glass_box.size = Vector3(1.0, 0.5, 0.05)
		var glass_mat := StandardMaterial3D.new()
		glass_mat.albedo_color = Color(0.15, 0.55, 0.85)
		glass.mesh = glass_box
		glass.position = Vector3(0.0, 0.4, 0.65)
		node.add_child(glass)

		# Plang toko / kanopi
		var canopy := MeshInstance3D.new()
		var canopy_box := BoxMesh.new()
		canopy_box.size = Vector3(1.1, 0.15, 0.3)
		var canopy_mat := StandardMaterial3D.new()
		canopy_mat.albedo_color = Color(0.15, 0.65, 0.45) # Hijau toska
		canopy.mesh = canopy_box
		canopy.position = Vector3(0.0, 0.75, 0.72)
		node.add_child(canopy)

	elif level == 2:
		# Kantor tingkat menengah Lv 2
		var base := MeshInstance3D.new()
		var base_box := BoxMesh.new()
		base_box.size = Vector3(1.3, 2.0, 1.3)
		var base_mat := StandardMaterial3D.new()
		base_mat.albedo_color = Color(0.70, 0.82, 0.95)
		base.mesh = base_box
		base.position = Vector3(0.0, 1.0, 0.0)
		node.add_child(base)

		# Jalur kaca jendela tingkat
		for fl in [0.6, 1.2, 1.6]:
			var band := MeshInstance3D.new()
			var band_box := BoxMesh.new()
			band_box.size = Vector3(1.1, 0.25, 1.32)
			var band_mat := StandardMaterial3D.new()
			band_mat.albedo_color = Color(0.12, 0.45, 0.75)
			band.mesh = band_box
			band.position = Vector3(0.0, fl, 0.0)
			node.add_child(band)

	else:
		# Menara perkantoran modern Lv 3
		var base := MeshInstance3D.new()
		var base_box := BoxMesh.new()
		base_box.size = Vector3(1.3, 3.2, 1.3)
		var base_mat := StandardMaterial3D.new()
		base_mat.albedo_color = Color(0.20, 0.40, 0.65) # Kaca biru tua
		base.mesh = base_box
		base.position = Vector3(0.0, 1.6, 0.0)
		node.add_child(base)

		# Rooftop antenna
		var ant := MeshInstance3D.new()
		var ant_box := BoxMesh.new()
		ant_box.size = Vector3(0.08, 0.7, 0.08)
		var ant_mat := StandardMaterial3D.new()
		ant_mat.albedo_color = Color(0.8, 0.2, 0.2)
		ant.mesh = ant_box
		ant.position = Vector3(0.0, 3.55, 0.0)
		node.add_child(ant)

	return node

## --- INDUSTRIAL (Pabrik box abu-abu + cerobong asap) ---
static func _create_industrial_building(level: int) -> Node3D:
	var node := Node3D.new()
	var factory_color := Color(0.48, 0.48, 0.52) # Abu-abu pabrik

	if level <= 1:
		# Pabrik kecil Lv 1 + 1 Cerobong
		var base := MeshInstance3D.new()
		var base_box := BoxMesh.new()
		base_box.size = Vector3(1.5, 0.8, 1.3)
		var base_mat := StandardMaterial3D.new()
		base_mat.albedo_color = factory_color
		base.mesh = base_box
		base.position = Vector3(0.0, 0.4, 0.0)
		node.add_child(base)

		var stack := MeshInstance3D.new()
		var stack_box := BoxMesh.new()
		stack_box.size = Vector3(0.25, 0.7, 0.25)
		var stack_mat := StandardMaterial3D.new()
		stack_mat.albedo_color = Color(0.3, 0.3, 0.32)
		stack.mesh = stack_box
		stack.position = Vector3(0.45, 0.95, 0.35)
		node.add_child(stack)

	elif level == 2:
		# Fasilitas industri Lv 2 + 2 Cerobong + gudang samping
		var base := MeshInstance3D.new()
		var base_box := BoxMesh.new()
		base_box.size = Vector3(1.5, 1.3, 1.4)
		var base_mat := StandardMaterial3D.new()
		base_mat.albedo_color = Color(0.42, 0.42, 0.46)
		base.mesh = base_box
		base.position = Vector3(0.0, 0.65, 0.0)
		node.add_child(base)

		for offset_x in [-0.4, 0.4]:
			var stack := MeshInstance3D.new()
			var stack_box := BoxMesh.new()
			stack_box.size = Vector3(0.22, 1.0, 0.22)
			var stack_mat := StandardMaterial3D.new()
			stack_mat.albedo_color = Color(0.65, 0.35, 0.2) # Bata/besi berkarat
			stack.mesh = stack_box
			stack.position = Vector3(offset_x, 1.5, 0.4)
			node.add_child(stack)

	else:
		# Kompleks manufaktur berat Lv 3
		var base := MeshInstance3D.new()
		var base_box := BoxMesh.new()
		base_box.size = Vector3(1.6, 1.8, 1.5)
		var base_mat := StandardMaterial3D.new()
		base_mat.albedo_color = Color(0.35, 0.38, 0.42)
		base.mesh = base_box
		base.position = Vector3(0.0, 0.9, 0.0)
		node.add_child(base)

		# Tangki silinder / tangki kimia
		var tank := MeshInstance3D.new()
		var tank_box := BoxMesh.new()
		tank_box.size = Vector3(0.6, 1.2, 0.6)
		var tank_mat := StandardMaterial3D.new()
		tank_mat.albedo_color = Color(0.85, 0.70, 0.20) # Kuning industri
		tank.mesh = tank_box
		tank.position = Vector3(-0.45, 0.6, -0.35)
		node.add_child(tank)

		var stack := MeshInstance3D.new()
		var stack_box := BoxMesh.new()
		stack_box.size = Vector3(0.3, 1.4, 0.3)
		var stack_mat := StandardMaterial3D.new()
		stack_mat.albedo_color = Color(0.25, 0.25, 0.28)
		stack.mesh = stack_box
		stack.position = Vector3(0.45, 2.0, 0.35)
		node.add_child(stack)

	return node

## --- UTILITAS: PEMBANGKIT LISTRIK ---
static func _create_power_plant_mesh() -> Node3D:
	var node := Node3D.new()
	# Gedung turbin
	var base := MeshInstance3D.new()
	var base_box := BoxMesh.new()
	base_box.size = Vector3(1.4, 1.0, 1.4)
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.85, 0.75, 0.25) # Kuning cerah khas listrik
	base.mesh = base_box
	base.position = Vector3(0.0, 0.5, 0.0)
	node.add_child(base)

	# Transformator / menara transmisi
	var tower := MeshInstance3D.new()
	var tower_box := BoxMesh.new()
	tower_box.size = Vector3(0.3, 1.2, 0.3)
	var tower_mat := StandardMaterial3D.new()
	tower_mat.albedo_color = Color(0.3, 0.3, 0.35)
	tower.mesh = tower_box
	tower.position = Vector3(0.35, 1.1, 0.35)
	node.add_child(tower)
	return node

## --- UTILITAS: MENARA AIR ---
static func _create_water_tower_mesh() -> Node3D:
	var node := Node3D.new()
	# Tiang penyangga menara
	var legs := MeshInstance3D.new()
	var legs_box := BoxMesh.new()
	legs_box.size = Vector3(0.8, 1.4, 0.8)
	var legs_mat := StandardMaterial3D.new()
	legs_mat.albedo_color = Color(0.6, 0.6, 0.65)
	legs.mesh = legs_box
	legs.position = Vector3(0.0, 0.7, 0.0)
	node.add_child(legs)

	# Tangki air bulat / kubus biru di atas
	var tank := MeshInstance3D.new()
	var tank_box := BoxMesh.new()
	tank_box.size = Vector3(1.2, 0.9, 1.2)
	var tank_mat := StandardMaterial3D.new()
	tank_mat.albedo_color = Color(0.2, 0.5, 0.9) # Biru air
	tank.mesh = tank_box
	tank.position = Vector3(0.0, 1.7, 0.0)
	node.add_child(tank)
	return node

## --- TAMAN KOTA LOW-POLY ---
static func _create_park_mesh() -> Node3D:
	var node := Node3D.new()

	# Alas rumput hijau 1 tile
	var grass := MeshInstance3D.new()
	var grass_box := BoxMesh.new()
	grass_box.size = Vector3(1.9, 0.04, 1.9)
	var grass_mat := StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.28, 0.65, 0.25)
	grass_mat.roughness = 0.95
	grass.mesh = grass_box
	grass.material_override = grass_mat
	grass.position = Vector3(0.0, 0.02, 0.0)
	node.add_child(grass)

	# Jalan setapak batu
	var path := MeshInstance3D.new()
	var path_box := BoxMesh.new()
	path_box.size = Vector3(0.42, 0.045, 1.9)
	var path_mat := StandardMaterial3D.new()
	path_mat.albedo_color = Color(0.76, 0.73, 0.66)
	path.mesh = path_box
	path.material_override = path_mat
	path.position = Vector3(0.0, 0.024, 0.0)
	node.add_child(path)

	# 2 Pohon kecil low-poly (batang + daun)
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.45, 0.28, 0.16)
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.18, 0.52, 0.20)

	var tree_positions = [Vector3(-0.55, 0.0, -0.45), Vector3(0.55, 0.0, 0.40)]
	for pos in tree_positions:
		var trunk := MeshInstance3D.new()
		var trunk_box := BoxMesh.new()
		trunk_box.size = Vector3(0.16, 0.45, 0.16)
		trunk.mesh = trunk_box
		trunk.material_override = trunk_mat
		trunk.position = pos + Vector3(0.0, 0.24, 0.0)
		node.add_child(trunk)

		var leaves := MeshInstance3D.new()
		var leaves_box := BoxMesh.new()
		leaves_box.size = Vector3(0.52, 0.50, 0.52)
		leaves.mesh = leaves_box
		leaves.material_override = leaf_mat
		leaves.position = pos + Vector3(0.0, 0.65, 0.0)
		node.add_child(leaves)

	# 1 Bangku taman kecil
	var bench_mat := StandardMaterial3D.new()
	bench_mat.albedo_color = Color(0.58, 0.36, 0.18)
	var bench_seat := MeshInstance3D.new()
	var seat_box := BoxMesh.new()
	seat_box.size = Vector3(0.22, 0.08, 0.50)
	bench_seat.mesh = seat_box
	bench_seat.material_override = bench_mat
	bench_seat.position = Vector3(-0.45, 0.12, 0.45)
	node.add_child(bench_seat)

	return node

## --- PERTANIAN GANDUM (3 Tahap: Benih -> Tumbuh -> Siap Panen) ---
static func _create_farm_mesh(stage: int) -> Node3D:
	var node := Node3D.new()

	# Tanah gembur pertanian berpetak
	var soil := MeshInstance3D.new()
	var soil_box := BoxMesh.new()
	soil_box.size = Vector3(1.9, 0.04, 1.9)
	var soil_mat := StandardMaterial3D.new()
	soil_mat.albedo_color = Color(0.38, 0.24, 0.14) # Coklat tanah gembur
	soil_mat.roughness = 0.95
	soil.mesh = soil_box
	soil.position = Vector3(0.0, 0.02, 0.0)
	node.add_child(soil)

	# Alur bajak tanah (furrows)
	for fz in [-0.5, 0.0, 0.5]:
		var ridge := MeshInstance3D.new()
		var ridge_box := BoxMesh.new()
		ridge_box.size = Vector3(1.8, 0.03, 0.25)
		var ridge_mat := StandardMaterial3D.new()
		ridge_mat.albedo_color = Color(0.28, 0.17, 0.10)
		ridge.mesh = ridge_box
		ridge.position = Vector3(0.0, 0.04, fz)
		node.add_child(ridge)

	var safe_stage := clampi(stage, 1, 3)

	if safe_stage == 1:
		# Tahap 1: Benih (tunas hijau kecil)
		var sprout_mat := StandardMaterial3D.new()
		sprout_mat.albedo_color = Color(0.35, 0.82, 0.25)
		for fz in [-0.5, 0.0, 0.5]:
			for fx in [-0.6, -0.2, 0.2, 0.6]:
				var sp := MeshInstance3D.new()
				var sp_box := BoxMesh.new()
				sp_box.size = Vector3(0.08, 0.14, 0.08)
				sp.mesh = sp_box
				sp.material_override = sprout_mat
				sp.position = Vector3(fx, 0.08, fz)
				node.add_child(sp)

	elif safe_stage == 2:
		# Tahap 2: Tumbuh (tanaman hijau setengah tinggi)
		var plant_mat := StandardMaterial3D.new()
		plant_mat.albedo_color = Color(0.22, 0.68, 0.24)
		for fz in [-0.5, 0.0, 0.5]:
			for fx in [-0.5, 0.0, 0.5]:
				var stalk := MeshInstance3D.new()
				var stalk_box := BoxMesh.new()
				stalk_box.size = Vector3(0.25, 0.45, 0.25)
				stalk.mesh = stalk_box
				stalk.material_override = plant_mat
				stalk.position = Vector3(fx, 0.25, fz)
				node.add_child(stalk)

	else:
		# Tahap 3: Siap Panen (gandum kuning tinggi + bulir emas jelas dari jauh)
		var wheat_mat := StandardMaterial3D.new()
		wheat_mat.albedo_color = Color(0.95, 0.78, 0.18) # Kuning keemasan

		for fz in [-0.5, 0.0, 0.5]:
			for fx in [-0.5, 0.0, 0.5]:
				var stalk := MeshInstance3D.new()
				var stalk_box := BoxMesh.new()
				stalk_box.size = Vector3(0.24, 0.85, 0.24)
				stalk.mesh = stalk_box
				stalk.material_override = wheat_mat
				stalk.position = Vector3(fx, 0.46, fz)
				node.add_child(stalk)

				var head := MeshInstance3D.new()
				var head_prism := PrismMesh.new()
				head_prism.size = Vector3(0.3, 0.35, 0.3)
				var head_mat := StandardMaterial3D.new()
				head_mat.albedo_color = Color(1.0, 0.88, 0.25)
				head.mesh = head_prism
				head.material_override = head_mat
				head.position = Vector3(fx, 0.95, fz)
				node.add_child(head)

		# Ikon visual "SIAP PANEN" kuning keemasan melayang di atas lahan
		var ready_badge := MeshInstance3D.new()
		var badge_box := BoxMesh.new()
		badge_box.size = Vector3(0.4, 0.4, 0.4)
		var badge_mat := StandardMaterial3D.new()
		badge_mat.albedo_color = Color(1.0, 0.85, 0.1)
		badge_mat.emission_enabled = true
		badge_mat.emission = Color(1.0, 0.85, 0.1)
		badge_mat.emission_energy_multiplier = 1.6
		badge_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ready_badge.mesh = badge_box
		ready_badge.rotation_degrees = Vector3(45, 45, 0)
		ready_badge.position = Vector3(0.0, 1.45, 0.0)
		node.add_child(ready_badge)

	return node

## Popup melayang "+10 Gandum" saat lahan dipanen
static func create_harvest_popup(amount: int) -> Label3D:
	var label := Label3D.new()
	label.text = "+%d Gandum" % amount
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32
	label.modulate = Color(1.0, 0.92, 0.25)
	label.outline_render_priority = 1
	label.outline_size = 4
	label.outline_modulate = Color(0.1, 0.1, 0.1)
	label.no_depth_test = true
	label.position = Vector3(0.0, 1.6, 0.0)
	return label

## --- LAHAN PARKIR RESMI (Solusi Kebijakan Pak Slamet) ---
static func _create_official_parking_mesh() -> Node3D:
	var node := Node3D.new()
	# Aspal abu-abu rapi
	var ground := MeshInstance3D.new()
	var g_box := BoxMesh.new()
	g_box.size = Vector3(1.95, 0.03, 1.95)
	var g_mat := StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.24, 0.24, 0.26)
	ground.mesh = g_box
	ground.position = Vector3(0.0, 0.015, 0.0)
	node.add_child(ground)

	# Marka garis parkir putih rapi
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.95, 0.95, 0.95)
	for px in [-0.65, 0.0, 0.65]:
		var line := MeshInstance3D.new()
		var l_box := BoxMesh.new()
		l_box.size = Vector3(0.06, 0.035, 1.4)
		line.mesh = l_box
		line.material_override = line_mat
		line.position = Vector3(px, 0.02, 0.0)
		node.add_child(line)

	# Plang Rambu Parkir Resmi "P"
	var sign_pole := MeshInstance3D.new()
	var sp_box := BoxMesh.new()
	sp_box.size = Vector3(0.06, 0.9, 0.06)
	sign_pole.mesh = sp_box
	sign_pole.position = Vector3(0.8, 0.45, -0.8)
	node.add_child(sign_pole)

	var sign_board := MeshInstance3D.new()
	var sb_box := BoxMesh.new()
	sb_box.size = Vector3(0.25, 0.25, 0.04)
	var sb_mat := StandardMaterial3D.new()
	sb_mat.albedo_color = Color(0.15, 0.45, 0.85) # Biru khas rambu P
	sign_board.mesh = sb_box
	sign_board.material_override = sb_mat
	sign_board.position = Vector3(0.8, 0.9, -0.8)
	node.add_child(sign_board)

	# 1 Mobil terparkir rapi
	var parked_car := MeshInstance3D.new()
	var pc_box := BoxMesh.new()
	pc_box.size = Vector3(0.42, 0.22, 0.75)
	var pc_mat := StandardMaterial3D.new()
	pc_mat.albedo_color = Color(0.85, 0.85, 0.85)
	parked_car.mesh = pc_box
	parked_car.material_override = pc_mat
	parked_car.position = Vector3(-0.32, 0.12, 0.0)
	node.add_child(parked_car)

	return node

## --- GEDUNG BALAI KOTA (Landmark Pusat Pemerintahan) ---
static func _create_townhall_mesh() -> Node3D:
	var node := Node3D.new()

	# Alas batu marmer / plinth
	var base := MeshInstance3D.new()
	var base_box := BoxMesh.new()
	base_box.size = Vector3(1.85, 0.15, 1.85)
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.80, 0.80, 0.78)
	base.mesh = base_box
	base.position = Vector3(0.0, 0.075, 0.0)
	node.add_child(base)

	# Gedung utama
	var body := MeshInstance3D.new()
	var body_box := BoxMesh.new()
	body_box.size = Vector3(1.5, 1.3, 1.4)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.92, 0.91, 0.86) # Krem putih megah
	body.mesh = body_box
	body.position = Vector3(0.0, 0.8, 0.0)
	node.add_child(body)

	# Pilar pilar teras depan
	var col_mat := StandardMaterial3D.new()
	col_mat.albedo_color = Color(0.98, 0.98, 0.96)
	for cx in [-0.55, -0.2, 0.2, 0.55]:
		var col := MeshInstance3D.new()
		var col_box := BoxMesh.new()
		col_box.size = Vector3(0.10, 1.1, 0.10)
		col.mesh = col_box
		col.material_override = col_mat
		col.position = Vector3(cx, 0.7, 0.72)
		node.add_child(col)

	# Atap pelana segitiga klasik
	var roof := MeshInstance3D.new()
	var roof_prism := PrismMesh.new()
	roof_prism.size = Vector3(1.6, 0.55, 1.5)
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.65, 0.25, 0.22) # Merah marun genteng
	roof.mesh = roof_prism
	roof.position = Vector3(0.0, 1.72, 0.0)
	node.add_child(roof)

	# Kubah kecil / menara jam di atas
	var cupola := MeshInstance3D.new()
	var cupola_box := BoxMesh.new()
	cupola_box.size = Vector3(0.35, 0.45, 0.35)
	cupola.mesh = cupola_box
	cupola.position = Vector3(0.0, 2.2, 0.0)
	node.add_child(cupola)

	# Tiang bendera merah putih mini
	var pole := MeshInstance3D.new()
	var pole_box := BoxMesh.new()
	pole_box.size = Vector3(0.04, 0.5, 0.04)
	pole.mesh = pole_box
	pole.position = Vector3(0.0, 2.65, 0.0)
	node.add_child(pole)

	var flag_red := MeshInstance3D.new()
	var fr_box := BoxMesh.new()
	fr_box.size = Vector3(0.18, 0.08, 0.02)
	var fr_mat := StandardMaterial3D.new()
	fr_mat.albedo_color = Color(0.9, 0.1, 0.1)
	flag_red.mesh = fr_box
	flag_red.material_override = fr_mat
	flag_red.position = Vector3(0.1, 2.85, 0.0)
	node.add_child(flag_red)

	var flag_white := MeshInstance3D.new()
	var fw_box := BoxMesh.new()
	fw_box.size = Vector3(0.18, 0.08, 0.02)
	var fw_mat := StandardMaterial3D.new()
	fw_mat.albedo_color = Color(0.95, 0.95, 0.95)
	flag_white.mesh = fw_box
	flag_white.material_override = fw_mat
	flag_white.position = Vector3(0.1, 2.77, 0.0)
	node.add_child(flag_white)

	return node

## --- KARAKTER PAK SLAMET (Rompi Oranye Pudar, Topi Lusuh, Peluit) ---
static func create_pak_slamet_node() -> Node3D:
	var node := Node3D.new()
	node.name = "PakSlamet"

	# Kaki celana gelap
	var leg_mat := StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.25, 0.28, 0.35)
	for lx in [-0.07, 0.07]:
		var leg := MeshInstance3D.new()
		var leg_box := BoxMesh.new()
		leg_box.size = Vector3(0.09, 0.35, 0.10)
		leg.mesh = leg_box
		leg.material_override = leg_mat
		leg.position = Vector3(lx, 0.175, 0.0)
		node.add_child(leg)

	# Badan: Rompi oranye pudar khas tukang parkir
	var body := MeshInstance3D.new()
	var body_box := BoxMesh.new()
	body_box.size = Vector3(0.28, 0.38, 0.20)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.92, 0.45, 0.15) # Rompi oranye pudar
	body.mesh = body_box
	body.material_override = body_mat
	body.position = Vector3(0.0, 0.54, 0.0)
	node.add_child(body)

	# Peluit perak di dada
	var whistle := MeshInstance3D.new()
	var whistle_box := BoxMesh.new()
	whistle_box.size = Vector3(0.06, 0.08, 0.04)
	var whistle_mat := StandardMaterial3D.new()
	whistle_mat.albedo_color = Color(0.85, 0.88, 0.92) # Perak
	whistle.mesh = whistle_box
	whistle.material_override = whistle_mat
	whistle.position = Vector3(0.0, 0.62, 0.11)
	node.add_child(whistle)

	# Kepala
	var head := MeshInstance3D.new()
	var head_box := BoxMesh.new()
	head_box.size = Vector3(0.20, 0.20, 0.20)
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.85, 0.68, 0.52) # Kulit hangat
	head.mesh = head_box
	head.material_override = head_mat
	head.position = Vector3(0.0, 0.82, 0.0)
	node.add_child(head)

	# Topi lusuh (dull cap) dengan pet lidah topi
	var cap := MeshInstance3D.new()
	var cap_box := BoxMesh.new()
	cap_box.size = Vector3(0.25, 0.08, 0.25)
	var cap_mat := StandardMaterial3D.new()
	cap_mat.albedo_color = Color(0.42, 0.36, 0.30) # Cokelat kusam / lusuh
	cap.mesh = cap_box
	cap.material_override = cap_mat
	cap.position = Vector3(0.0, 0.94, 0.0)
	node.add_child(cap)

	var visor := MeshInstance3D.new()
	var visor_box := BoxMesh.new()
	visor_box.size = Vector3(0.22, 0.03, 0.12)
	visor.mesh = visor_box
	visor.material_override = cap_mat
	visor.position = Vector3(0.0, 0.92, 0.16)
	node.add_child(visor)

	# Lengan mengarahkan parkir
	var arm_r := MeshInstance3D.new()
	var arm_box := BoxMesh.new()
	arm_box.size = Vector3(0.08, 0.32, 0.08)
	arm_r.mesh = arm_box
	arm_r.material_override = body_mat
	arm_r.rotation_degrees = Vector3(45, 0, -25)
	arm_r.position = Vector3(0.20, 0.58, 0.12)
	node.add_child(arm_r)

	return node

## --- MOBIL PARKIR LIAR SEMBARANGAN (Akibat Pak Slamet) ---
static func create_illegal_parking_mesh() -> Node3D:
	var node := Node3D.new()
	node.name = "IllegalParking"

	var car_colors = [
		Color(0.85, 0.2, 0.2), # Merah
		Color(0.25, 0.25, 0.28), # Abu gelap
		Color(0.85, 0.85, 0.88), # Putih
		Color(0.2, 0.45, 0.75) # Biru
	]

	# 3 Mobil parkir serong miring memakan badan jalan
	var positions = [
		Vector3(-0.62, 0.06, -0.45),
		Vector3(-0.58, 0.06, 0.40),
		Vector3(0.65, 0.06, 0.05)
	]
	var rotations = [28.0, -32.0, 18.0]

	for i in range(3):
		var car := Node3D.new()
		var body := MeshInstance3D.new()
		var b_box := BoxMesh.new()
		b_box.size = Vector3(0.38, 0.18, 0.65)
		var b_mat := StandardMaterial3D.new()
		b_mat.albedo_color = car_colors[i % car_colors.size()]
		body.mesh = b_box
		body.material_override = b_mat
		body.position = Vector3(0.0, 0.10, 0.0)
		car.add_child(body)

		var roof := MeshInstance3D.new()
		var r_box := BoxMesh.new()
		r_box.size = Vector3(0.32, 0.14, 0.35)
		roof.mesh = r_box
		roof.position = Vector3(0.0, 0.24, -0.05)
		car.add_child(roof)

		car.position = positions[i]
		car.rotation_degrees.y = rotations[i]
		node.add_child(car)

	return node

## --- NPC WARGA PEJALAN KAKI SEDERHANA ---
static func create_citizen_node(color_seed: int = 0) -> Node3D:
	var node := Node3D.new()

	var shirt_colors = [
		Color(0.25, 0.55, 0.85), # Biru
		Color(0.85, 0.30, 0.35), # Merah muda
		Color(0.35, 0.75, 0.40), # Hijau
		Color(0.92, 0.75, 0.25), # Kuning
		Color(0.65, 0.40, 0.80), # Ungu
		Color(0.92, 0.55, 0.25)  # Oranye
	]
	var shirt_color: Color = shirt_colors[color_seed % shirt_colors.size()]

	# Kaki
	var leg_mat := StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.20, 0.22, 0.28)
	for lx in [-0.06, 0.06]:
		var leg := MeshInstance3D.new()
		var leg_box := BoxMesh.new()
		leg_box.size = Vector3(0.08, 0.32, 0.08)
		leg.mesh = leg_box
		leg.material_override = leg_mat
		leg.position = Vector3(lx, 0.16, 0.0)
		node.add_child(leg)

	# Baju / Badan
	var body := MeshInstance3D.new()
	var body_box := BoxMesh.new()
	body_box.size = Vector3(0.24, 0.34, 0.16)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = shirt_color
	body.mesh = body_box
	body.material_override = body_mat
	body.position = Vector3(0.0, 0.48, 0.0)
	node.add_child(body)

	# Kepala
	var head := MeshInstance3D.new()
	var head_box := BoxMesh.new()
	head_box.size = Vector3(0.18, 0.18, 0.18)
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.88, 0.72, 0.58)
	head.mesh = head_box
	head.material_override = head_mat
	head.position = Vector3(0.0, 0.74, 0.0)
	node.add_child(head)

	# Rambut
	var hair := MeshInstance3D.new()
	var hair_box := BoxMesh.new()
	hair_box.size = Vector3(0.20, 0.08, 0.20)
	var hair_mat := StandardMaterial3D.new()
	hair_mat.albedo_color = Color(0.18, 0.15, 0.12)
	hair.mesh = hair_box
	hair.material_override = hair_mat
	hair.position = Vector3(0.0, 0.85, -0.01)
	node.add_child(hair)

	return node

## --- BUBBLE CHAT ALA SIMCITY (Billboard 3D) ---
static func create_bubble_chat(text: String, is_pak_slamet: bool = false) -> Node3D:
	var root := Node3D.new()

	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 18
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.width = 260.0
	label.outline_render_priority = 1
	label.outline_size = 3
	label.outline_modulate = Color(0.05, 0.05, 0.05, 0.92)
	label.no_depth_test = false

	if is_pak_slamet:
		label.modulate = Color(1.0, 0.85, 0.28)
		label.position = Vector3(0.0, 1.75, 0.0)
	else:
		label.modulate = Color(0.98, 0.98, 0.98)
		label.position = Vector3(0.0, 1.35, 0.0)

	root.add_child(label)
	return root
