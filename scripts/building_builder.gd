class_name BuildingBuilder
extends RefCounted

## Generator visual 3D prosedural untuk tile, zona, dan bangunan low-poly (Godot 4.7)

static func create_tile_node(type: CityData.TileType, level: int = 0, zone: CityData.BuildingZone = CityData.BuildingZone.RESIDENTIAL) -> Node3D:
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
