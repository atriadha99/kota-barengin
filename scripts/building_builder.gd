class_name BuildingBuilder
extends RefCounted

## Generator visual 3D prosedural untuk tile, zona, dan bangunan low-poly (Godot 4.7)

static var _shared_mats: Dictionary = {}
static var _shared_boxes: Dictionary = {}

static func create_tile_node(type: CityData.TileType, level: int = 0, zone: CityData.BuildingZone = CityData.BuildingZone.RESIDENTIAL, has_util: bool = true, variant: int = 0) -> Node3D:
	var root := Node3D.new()

	match type:
		CityData.TileType.ROAD:
			root.add_child(_create_road_mesh())
		CityData.TileType.ZONE_R:
			if level == 0:
				root.add_child(_create_zone_marker(Color(0.2, 0.8, 0.25, 0.45)))
			else:
				root.add_child(_create_residential_building(level, variant))
		CityData.TileType.ZONE_C:
			if level == 0:
				root.add_child(_create_zone_marker(Color(0.2, 0.45, 0.95, 0.45)))
			else:
				root.add_child(_create_commercial_building(level, variant))
		CityData.TileType.ZONE_I:
			if level == 0:
				root.add_child(_create_zone_marker(Color(0.95, 0.65, 0.1, 0.45)))
			else:
				root.add_child(_create_industrial_building(level, variant))
		CityData.TileType.BUILDING:
			match zone:
				CityData.BuildingZone.RESIDENTIAL:
					root.add_child(_create_residential_building(level, variant))
				CityData.BuildingZone.COMMERCIAL:
					root.add_child(_create_commercial_building(level, variant))
				CityData.BuildingZone.INDUSTRIAL:
					root.add_child(_create_industrial_building(level, variant))
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
		CityData.TileType.SCHOOL:
			root.add_child(_create_school_mesh())
		CityData.TileType.CLINIC:
			root.add_child(_create_clinic_mesh())
		CityData.TileType.HOSPITAL:
			root.add_child(_create_hospital_mesh())
		CityData.TileType.POLICE:
			root.add_child(_create_police_mesh())
		CityData.TileType.MILITARY:
			root.add_child(_create_military_mesh())
		CityData.TileType.MAYOR_OFFICE:
			root.add_child(_create_mayor_office_mesh())
		CityData.TileType.FIRE_STATION:
			root.add_child(_create_fire_station_mesh())
		CityData.TileType.ZONE_MILITARY:
			if level == 0:
				root.add_child(_create_zone_marker(Color(0.28, 0.45, 0.22, 0.45)))
			else:
				root.add_child(_create_military_zone_mesh(level))
		CityData.TileType.TRAIN_STATION:
			root.add_child(_create_train_station_mesh())
		CityData.TileType.RAIL:
			root.add_child(_create_rail_mesh())
		CityData.TileType.STOP_ANGKOT:
			root.add_child(_create_road_mesh())
			root.add_child(_create_stop_mesh(Color(0.22, 0.72, 0.88)))
		CityData.TileType.STOP_BUS:
			root.add_child(_create_road_mesh())
			root.add_child(_create_stop_mesh(Color(0.95, 0.58, 0.16)))
		CityData.TileType.BUSWAY_LANE:
			root.add_child(_create_busway_lane_mesh())
		CityData.TileType.STOP_BUSWAY:
			root.add_child(_create_busway_lane_mesh())
			root.add_child(_create_stop_busway_mesh())
		CityData.TileType.FLYOVER:
			root.add_child(_create_road_mesh())
			root.add_child(_create_flyover_mesh())
		CityData.TileType.RUNWAY:
			root.add_child(_create_runway_mesh())
		CityData.TileType.AIRPORT_TERMINAL:
			root.add_child(_create_airport_terminal_mesh())
		CityData.TileType.KOSAN:
			root.add_child(_create_kosan_mesh())
		CityData.TileType.UNIVERSITAS:
			root.add_child(_create_universitas_mesh())

	# Indikator jika bangunan tidak mendapat suplai utilitas (listrik / air)
	var needs_util_badge: bool = (type == CityData.TileType.BUILDING or (level > 0 and type in [CityData.TileType.ZONE_R, CityData.TileType.ZONE_C, CityData.TileType.ZONE_I, CityData.TileType.ZONE_MILITARY]) or (type in CityData.PUBLIC_BUILDING_TYPES) or (type in [CityData.TileType.TRAIN_STATION, CityData.TileType.STOP_BUSWAY, CityData.TileType.AIRPORT_TERMINAL]))
	if not has_util and needs_util_badge:
		var badge := Label3D.new()
		badge.text = "!" if ((type in CityData.PUBLIC_BUILDING_TYPES) or (type in [CityData.TileType.ZONE_MILITARY, CityData.TileType.TRAIN_STATION, CityData.TileType.STOP_BUSWAY, CityData.TileType.AIRPORT_TERMINAL])) else "⚠️"
		badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		badge.font_size = 32 if (type in CityData.PUBLIC_BUILDING_TYPES) else 28
		badge.modulate = Color(1.0, 0.25, 0.25)
		badge.outline_render_priority = 1
		badge.outline_size = 4
		badge.outline_modulate = Color(0.1, 0.1, 0.1)
		badge.no_depth_test = true
		badge.position = Vector3(0.0, 1.8 if (type in CityData.PUBLIC_BUILDING_TYPES) else (0.8 + float(level) * 0.7), 0.0)
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
	# Trotoar terang di pinggir jalan
	_add_box(node, Vector3(2.0, 0.025, 2.0), Vector3(0.0, 0.012, 0.0), Color(0.45, 0.47, 0.50))
	# Permukaan aspal gelap di tengah
	_add_box(node, Vector3(1.62, 0.032, 2.0), Vector3(0.0, 0.016, 0.0), Color(0.18, 0.19, 0.21))
	# Marka jalan putus-putus
	_add_box(node, Vector3(0.10, 0.036, 0.55), Vector3(0.0, 0.020, -0.45), Color(0.92, 0.92, 0.90))
	_add_box(node, Vector3(0.10, 0.036, 0.55), Vector3(0.0, 0.020, 0.45), Color(0.92, 0.92, 0.90))
	return node

static func create_intersection_props_node(is_green: bool = true) -> Node3D:
	var node := Node3D.new()
	node.name = "IntersectionProps"
	_add_box(node, Vector3(0.06, 0.65, 0.06), Vector3(0.78, 0.33, 0.78), Color(0.25, 0.26, 0.30))
	var lamp := _add_box(node, Vector3(0.14, 0.18, 0.14), Vector3(0.78, 0.72, 0.78), Color(0.20, 0.92, 0.30) if is_green else Color(0.95, 0.22, 0.20), true)
	lamp.name = "TrafficLamp"
	return node

static func create_road_node(shape: String, is_wide: bool = false, is_green: bool = true) -> Node3D:
	var node := Node3D.new()
	var w_asp: float = 1.86 if is_wide else 1.62
	var asp_col := Color(0.18, 0.19, 0.21)
	var line_col := Color(0.96, 0.85, 0.25) if is_wide else Color(0.92, 0.92, 0.90)

	# Trotoar dasar
	_add_box(node, Vector3(2.0, 0.025, 2.0), Vector3(0.0, 0.012, 0.0), Color(0.45, 0.47, 0.50))

	if shape == "tikungan":
		# L-turn: Utara (z=-1) ke Timur (x=+1)
		var arm_len: float = 1.0 + w_asp * 0.5
		_add_box(node, Vector3(w_asp, 0.032, arm_len), Vector3(0.0, 0.016, -1.0 + arm_len * 0.5), asp_col)
		_add_box(node, Vector3(arm_len, 0.032, w_asp), Vector3(1.0 - arm_len * 0.5, 0.016, 0.0), asp_col)
		# Marka tengah melengkung 90 derajat
		_add_box(node, Vector3(0.10, 0.038, 0.48), Vector3(0.0, 0.021, -0.72), line_col)
		var mid_seg := _add_box(node, Vector3(0.10, 0.038, 0.42), Vector3(0.22, 0.021, -0.22), line_col)
		mid_seg.rotation_degrees.y = -45.0
		_add_box(node, Vector3(0.48, 0.038, 0.10), Vector3(0.72, 0.021, 0.0), line_col)
		if is_wide:
			_add_box(node, Vector3(0.05, 0.038, 1.0 + w_asp * 0.5), Vector3(-w_asp * 0.44, 0.021, -1.0 + (1.0 + w_asp * 0.5) * 0.5), Color(0.92, 0.92, 0.92))
			_add_box(node, Vector3(1.0 + w_asp * 0.5, 0.038, 0.05), Vector3(1.0 - (1.0 + w_asp * 0.5) * 0.5, 0.021, w_asp * 0.44), Color(0.92, 0.92, 0.92))
	elif shape == "t_junction":
		# T-junction: Utara + Selatan + Timur
		_add_box(node, Vector3(w_asp, 0.032, 2.0), Vector3(0.0, 0.016, 0.0), asp_col)
		_add_box(node, Vector3(1.0, 0.032, w_asp), Vector3(0.5, 0.016, 0.0), asp_col)
		_add_zebra_leg(node, Vector2(0.0, -0.76), false)
		_add_zebra_leg(node, Vector2(0.0, 0.76), false)
		_add_zebra_leg(node, Vector2(0.76, 0.0), true)
		node.add_child(create_intersection_props_node(is_green))
	elif shape == "perempatan":
		# Perempatan 4 arah
		_add_box(node, Vector3(w_asp, 0.032, 2.0), Vector3(0.0, 0.016, 0.0), asp_col)
		_add_box(node, Vector3(2.0, 0.032, w_asp), Vector3(0.0, 0.016, 0.0), asp_col)
		_add_zebra_leg(node, Vector2(0.0, -0.76), false)
		_add_zebra_leg(node, Vector2(0.0, 0.76), false)
		_add_zebra_leg(node, Vector2(-0.76, 0.0), true)
		_add_zebra_leg(node, Vector2(0.76, 0.0), true)
		node.add_child(create_intersection_props_node(is_green))
	else:
		if is_wide:
			return create_wide_road_mesh()
		_add_box(node, Vector3(w_asp, 0.032, 2.0), Vector3(0.0, 0.016, 0.0), asp_col)
		_add_box(node, Vector3(0.10, 0.036, 0.55), Vector3(0.0, 0.020, -0.45), line_col)
		_add_box(node, Vector3(0.10, 0.036, 0.55), Vector3(0.0, 0.020, 0.45), line_col)

	return node

static func _add_zebra_leg(node: Node3D, pos2: Vector2, rotated_ew: bool) -> void:
	for s in [-0.45, -0.15, 0.15, 0.45]:
		if rotated_ew:
			_add_box(node, Vector3(0.32, 0.038, 0.14), Vector3(pos2.x, 0.022, s), Color(0.94, 0.94, 0.94))
		else:
			_add_box(node, Vector3(0.14, 0.038, 0.32), Vector3(s, 0.022, pos2.y), Color(0.94, 0.94, 0.94))

static func create_flyover_node(shape: String) -> Node3D:
	var node := Node3D.new()
	var deck_col := Color(0.32, 0.34, 0.38)
	var rail_col := Color(0.78, 0.80, 0.82)
	if shape == "tikungan":
		_add_box(node, Vector3(0.32, 0.90, 0.32), Vector3(-0.65, 0.45, 0.65), Color(0.62, 0.64, 0.68))
		_add_box(node, Vector3(1.75, 0.16, 1.85), Vector3(0.0, 0.95, -0.08), deck_col)
		_add_box(node, Vector3(1.85, 0.16, 1.75), Vector3(0.08, 0.95, 0.0), deck_col)
		_add_box(node, Vector3(0.08, 0.18, 1.85), Vector3(-0.82, 1.05, -0.08), rail_col)
		_add_box(node, Vector3(1.85, 0.18, 0.08), Vector3(0.08, 1.05, 0.82), rail_col)
	elif shape == "t_junction" or shape == "perempatan":
		_add_box(node, Vector3(0.32, 0.90, 0.32), Vector3(-0.65, 0.45, -0.65), Color(0.62, 0.64, 0.68))
		_add_box(node, Vector3(0.32, 0.90, 0.32), Vector3(0.65, 0.45, 0.65), Color(0.62, 0.64, 0.68))
		_add_box(node, Vector3(1.75, 0.16, 2.0), Vector3(0.0, 0.95, 0.0), deck_col)
		_add_box(node, Vector3(2.0, 0.16, 1.75), Vector3(0.0, 0.95, 0.0), deck_col)
	else:
		return _create_flyover_mesh()
	return node

## --- RESIDENTIAL (3 varian per level) ---
static func _create_residential_building(level: int, variant: int = 0) -> Node3D:
	var node := Node3D.new()
	var v: int = variant % 3
	var wall_pal := [Color(0.94, 0.88, 0.78), Color(0.86, 0.92, 0.96), Color(0.96, 0.93, 0.78)]
	var roof_pal := [Color(0.75, 0.26, 0.20), Color(0.45, 0.30, 0.22), Color(0.32, 0.42, 0.56)]
	var wall_color: Color = wall_pal[v]
	var roof_color: Color = roof_pal[v]

	if level <= 1:
		var sz := Vector3(1.15, 0.75, 1.15) if v == 0 else (Vector3(1.25, 0.70, 1.05) if v == 1 else Vector3(1.05, 0.80, 1.25))
		_add_box(node, sz, Vector3(0.0, sz.y * 0.5, 0.0), wall_color)
		_add_prism_roof(node, Vector3(sz.x + 0.12, 0.42, sz.z + 0.12), Vector3(0.0, sz.y + 0.21, 0.0), roof_color)
		_add_box(node, Vector3(0.24, 0.38, 0.05), Vector3(0.0, 0.19, sz.z * 0.5 + 0.01), Color(0.42, 0.26, 0.16))
		_add_box(node, Vector3(0.22, 0.22, 0.04), Vector3(-0.34, 0.42, sz.z * 0.5 + 0.01), Color(0.14, 0.20, 0.28))
		_add_box(node, Vector3(0.22, 0.22, 0.04), Vector3(0.34, 0.42, sz.z * 0.5 + 0.01), Color(0.14, 0.20, 0.28))
	elif level == 2:
		_add_box(node, Vector3(1.35, 1.45, 1.25), Vector3(0.0, 0.725, 0.0), wall_color)
		if v == 0:
			_add_prism_roof(node, Vector3(1.45, 0.50, 1.35), Vector3(0.0, 1.70, 0.0), roof_color)
			_add_box(node, Vector3(0.24, 0.16, 0.14), Vector3(0.45, 1.05, 0.65), Color(0.85, 0.88, 0.90))
		elif v == 1:
			_add_box(node, Vector3(1.42, 0.14, 1.32), Vector3(0.0, 1.52, 0.0), roof_color)
			_add_box(node, Vector3(0.04, 0.45, 0.04), Vector3(-0.35, 1.80, -0.25), Color(0.65, 0.68, 0.72))
		else:
			_add_prism_roof(node, Vector3(1.45, 0.45, 1.35), Vector3(0.0, 1.68, 0.0), Color(0.24, 0.56, 0.44))
		for wx in [-0.35, 0.35]:
			_add_box(node, Vector3(0.22, 0.24, 0.05), Vector3(wx, 1.05, 0.63), Color(0.32, 0.62, 0.88))
	else:
		_add_box(node, Vector3(1.45, 2.15, 1.35), Vector3(0.0, 1.075, -0.05), wall_color)
		_add_prism_roof(node, Vector3(1.55, 0.55, 1.45), Vector3(0.0, 2.42, -0.05), roof_color)
		for fl in [0.65, 1.25, 1.80]:
			for wx in [-0.38, 0.38]:
				_add_box(node, Vector3(0.24, 0.26, 0.05), Vector3(wx, fl, 0.63), Color(0.30, 0.65, 0.92))
		_add_box(node, Vector3(1.65, 0.14, 0.06), Vector3(0.0, 0.07, 0.85), Color(0.90, 0.90, 0.88))
		_add_box(node, Vector3(0.35, 0.18, 0.25), Vector3(-0.55, 0.10, 0.72), Color(0.22, 0.65, 0.28))
		_add_box(node, Vector3(0.08, 0.28, 0.08), Vector3(0.55, 0.18, 0.72), Color(1.0, 0.88, 0.35), true)

	return node

## --- COMMERCIAL (3 varian per level) ---
static func _create_commercial_building(level: int, variant: int = 0) -> Node3D:
	var node := Node3D.new()
	var v: int = variant % 3
	var c_pal := [Color(0.84, 0.92, 0.98), Color(0.95, 0.90, 0.82), Color(0.86, 0.95, 0.88)]

	if level <= 1:
		_add_box(node, Vector3(1.25, 1.10, 1.25), Vector3(0.0, 0.55, 0.0), c_pal[v])
		_add_box(node, Vector3(0.95, 0.45, 0.05), Vector3(0.0, 0.38, 0.63), Color(0.18, 0.56, 0.86))
		if v == 1:
			_add_prism_roof(node, Vector3(1.32, 0.35, 1.32), Vector3(0.0, 1.28, 0.0), Color(0.75, 0.35, 0.22))
	elif level == 2:
		_add_box(node, Vector3(1.32, 2.05, 1.32), Vector3(0.0, 1.025, 0.0), c_pal[v])
		for fl in [0.60, 1.15, 1.65]:
			_add_box(node, Vector3(1.12, 0.24, 1.35), Vector3(0.0, fl, 0.0), Color(0.15, 0.48, 0.78))
		_add_box(node, Vector3(0.28, 0.18, 0.22), Vector3(0.35, 2.14, 0.0), Color(0.72, 0.75, 0.78))
	else:
		_add_box(node, Vector3(1.38, 3.25, 1.38), Vector3(0.0, 1.625, 0.0), Color(0.22, 0.42, 0.68) if v != 2 else Color(0.28, 0.52, 0.62))
		_add_box(node, Vector3(0.08, 0.72, 0.08), Vector3(0.0, 3.60, 0.0), Color(0.85, 0.22, 0.22))
		_add_box(node, Vector3(1.55, 0.12, 0.25), Vector3(0.0, 0.06, 0.80), Color(0.25, 0.68, 0.30))

	return node

## --- INDUSTRIAL (3 varian per level + penanda asap cerobong) ---
static func _create_industrial_building(level: int, variant: int = 0) -> Node3D:
	var node := Node3D.new()
	var v: int = variant % 3
	var f_pal := [Color(0.50, 0.50, 0.54), Color(0.56, 0.48, 0.44), Color(0.44, 0.48, 0.54)]

	if level <= 1:
		_add_box(node, Vector3(1.45, 0.80, 1.25), Vector3(0.0, 0.40, 0.0), f_pal[v])
		_add_box(node, Vector3(0.24, 0.70, 0.24), Vector3(0.45, 0.95, 0.35), Color(0.30, 0.30, 0.32))
		var sm := _add_box(node, Vector3(0.24, 0.24, 0.24), Vector3(0.45, 1.45, 0.35), Color(0.92, 0.92, 0.94))
		sm.name = "SmokePuff"
	elif level == 2:
		_add_box(node, Vector3(1.50, 1.30, 1.35), Vector3(0.0, 0.65, 0.0), f_pal[v])
		for ox in [-0.40, 0.40]:
			_add_box(node, Vector3(0.22, 0.95, 0.22), Vector3(ox, 1.45, 0.35), Color(0.62, 0.35, 0.22))
		var sm := _add_box(node, Vector3(0.28, 0.28, 0.28), Vector3(0.40, 2.10, 0.35), Color(0.92, 0.92, 0.94))
		sm.name = "SmokePuff"
	else:
		_add_box(node, Vector3(1.58, 1.80, 1.48), Vector3(0.0, 0.90, 0.0), f_pal[v])
		_add_box(node, Vector3(0.55, 1.15, 0.55), Vector3(-0.45, 0.58, -0.35), Color(0.85, 0.70, 0.20))
		_add_box(node, Vector3(0.28, 1.35, 0.28), Vector3(0.45, 1.98, 0.35), Color(0.25, 0.25, 0.28))
		var sm := _add_box(node, Vector3(0.34, 0.34, 0.34), Vector3(0.45, 2.85, 0.35), Color(0.94, 0.94, 0.96))
		sm.name = "SmokePuff"

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
	legs_mat.albedo_color = Color(0.55, 0.56, 0.60)
	legs.mesh = legs_box
	legs.material_override = legs_mat
	legs.position = Vector3(0.0, 0.7, 0.0)
	node.add_child(legs)

	# Tangki air bulat / kubus biru lembut di atas
	var tank := MeshInstance3D.new()
	var tank_box := BoxMesh.new()
	tank_box.size = Vector3(1.2, 0.9, 1.2)
	var tank_mat := StandardMaterial3D.new()
	tank_mat.albedo_color = Color(0.26, 0.52, 0.78) # Biru air lembut
	tank.mesh = tank_box
	tank.material_override = tank_mat
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
	grass_mat.albedo_color = Color(0.26, 0.52, 0.24)
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

static func _get_shared_mat(color: Color, emissive: bool = false) -> StandardMaterial3D:
	var key: String = "%s_%s" % [color.to_html(), str(emissive)]
	if _shared_mats.has(key):
		return _shared_mats[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.18 if (color.r < 0.25 and color.b > color.r and not emissive) else 0.85
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.8
	_shared_mats[key] = mat
	return mat

static func _add_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, emissive: bool = false) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bkey: String = "%.3f_%.3f_%.3f" % [size.x, size.y, size.z]
	var box: BoxMesh
	if _shared_boxes.has(bkey):
		box = _shared_boxes[bkey] as BoxMesh
	else:
		box = BoxMesh.new()
		box.size = size
		_shared_boxes[bkey] = box
	m.mesh = box
	m.material_override = _get_shared_mat(color, emissive)
	m.position = pos
	parent.add_child(m)
	return m

static func _add_prism_roof(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = size
	m.mesh = prism
	m.material_override = _get_shared_mat(color, false)
	m.position = pos
	parent.add_child(m)
	return m

static func _create_school_mesh() -> Node3D:
	var node := Node3D.new()
	_add_box(node, Vector3(1.8, 0.10, 1.8), Vector3(0.0, 0.05, 0.0), Color(0.75, 0.75, 0.72))
	_add_box(node, Vector3(1.5, 0.90, 1.2), Vector3(0.0, 0.55, -0.1), Color(0.95, 0.88, 0.55))
	_add_prism_roof(node, Vector3(1.6, 0.45, 1.3), Vector3(0.0, 1.22, -0.1), Color(0.85, 0.40, 0.20))
	_add_box(node, Vector3(0.55, 0.16, 0.06), Vector3(0.0, 0.95, 0.52), Color(0.18, 0.42, 0.78)) # Papan nama
	_add_box(node, Vector3(0.04, 0.65, 0.04), Vector3(-0.65, 0.42, 0.65), Color(0.85, 0.85, 0.88)) # Tiang bendera
	_add_box(node, Vector3(0.18, 0.08, 0.02), Vector3(-0.55, 0.70, 0.65), Color(0.90, 0.12, 0.12))
	_add_box(node, Vector3(0.18, 0.08, 0.02), Vector3(-0.55, 0.62, 0.65), Color(0.96, 0.96, 0.96))
	return node

static func _create_clinic_mesh() -> Node3D:
	var node := Node3D.new()
	_add_box(node, Vector3(1.7, 0.10, 1.7), Vector3(0.0, 0.05, 0.0), Color(0.78, 0.80, 0.80))
	_add_box(node, Vector3(1.35, 0.85, 1.2), Vector3(0.0, 0.52, 0.0), Color(0.96, 0.97, 0.98))
	_add_prism_roof(node, Vector3(1.45, 0.40, 1.3), Vector3(0.0, 1.15, 0.0), Color(0.18, 0.68, 0.55))
	# Palang hijau puskesmas
	_add_box(node, Vector3(0.10, 0.30, 0.05), Vector3(0.0, 0.75, 0.62), Color(0.15, 0.72, 0.42))
	_add_box(node, Vector3(0.30, 0.10, 0.05), Vector3(0.0, 0.75, 0.62), Color(0.15, 0.72, 0.42))
	return node

static func _create_hospital_mesh() -> Node3D:
	var node := Node3D.new()
	_add_box(node, Vector3(1.9, 0.12, 1.9), Vector3(0.0, 0.06, 0.0), Color(0.76, 0.78, 0.82))
	_add_box(node, Vector3(1.6, 1.45, 1.4), Vector3(0.0, 0.84, 0.0), Color(0.95, 0.96, 0.99))
	_add_box(node, Vector3(0.9, 0.55, 0.9), Vector3(0.0, 1.84, 0.0), Color(0.90, 0.93, 0.97))
	# Helipad di atap
	_add_box(node, Vector3(0.75, 0.04, 0.75), Vector3(0.0, 2.13, 0.0), Color(0.28, 0.34, 0.42))
	# Palang merah besar di depan
	_add_box(node, Vector3(0.14, 0.44, 0.06), Vector3(0.0, 1.15, 0.72), Color(0.90, 0.18, 0.18))
	_add_box(node, Vector3(0.44, 0.14, 0.06), Vector3(0.0, 1.15, 0.72), Color(0.90, 0.18, 0.18))
	return node

static func _create_police_mesh() -> Node3D:
	var node := Node3D.new()
	_add_box(node, Vector3(1.75, 0.10, 1.75), Vector3(0.0, 0.05, 0.0), Color(0.70, 0.72, 0.76))
	_add_box(node, Vector3(1.4, 0.95, 1.25), Vector3(0.0, 0.57, 0.0), Color(0.84, 0.87, 0.92))
	_add_box(node, Vector3(1.44, 0.18, 1.29), Vector3(0.0, 0.96, 0.0), Color(0.16, 0.30, 0.62)) # List biru polisi
	_add_box(node, Vector3(1.48, 0.10, 1.32), Vector3(0.0, 1.10, 0.0), Color(0.20, 0.25, 0.35))
	_add_box(node, Vector3(0.20, 0.14, 0.16), Vector3(0.0, 1.22, 0.35), Color(0.20, 0.55, 1.0), true) # Sirene biru
	return node

static func _create_military_mesh() -> Node3D:
	var node := Node3D.new()
	_add_box(node, Vector3(1.85, 0.10, 1.85), Vector3(0.0, 0.05, 0.0), Color(0.55, 0.55, 0.50))
	_add_box(node, Vector3(1.45, 0.95, 1.35), Vector3(-0.08, 0.57, 0.0), Color(0.32, 0.42, 0.26))
	_add_box(node, Vector3(1.52, 0.12, 1.42), Vector3(-0.08, 1.10, 0.0), Color(0.24, 0.30, 0.18))
	# Menara pantau mini
	_add_box(node, Vector3(0.35, 1.55, 0.35), Vector3(0.62, 0.87, -0.45), Color(0.38, 0.46, 0.30))
	_add_box(node, Vector3(0.45, 0.12, 0.45), Vector3(0.62, 1.70, -0.45), Color(0.25, 0.30, 0.20))
	# Tiang bendera merah-putih
	_add_box(node, Vector3(0.04, 0.60, 0.04), Vector3(-0.62, 1.45, 0.45), Color(0.85, 0.85, 0.88))
	_add_box(node, Vector3(0.18, 0.08, 0.02), Vector3(-0.52, 1.70, 0.45), Color(0.90, 0.12, 0.12))
	_add_box(node, Vector3(0.18, 0.08, 0.02), Vector3(-0.52, 1.62, 0.45), Color(0.96, 0.96, 0.96))
	return node

static func _create_mayor_office_mesh() -> Node3D:
	var node := Node3D.new()
	_add_box(node, Vector3(1.85, 0.14, 1.85), Vector3(0.0, 0.07, 0.0), Color(0.82, 0.80, 0.74))
	_add_box(node, Vector3(1.50, 1.20, 1.35), Vector3(0.0, 0.74, 0.0), Color(0.95, 0.93, 0.86))
	for px in [-0.52, -0.18, 0.18, 0.52]:
		_add_box(node, Vector3(0.10, 1.05, 0.10), Vector3(px, 0.66, 0.70), Color(0.92, 0.76, 0.25))
	_add_prism_roof(node, Vector3(1.60, 0.50, 1.45), Vector3(0.0, 1.59, 0.0), Color(0.68, 0.22, 0.20))
	_add_box(node, Vector3(0.36, 0.36, 0.36), Vector3(0.0, 2.02, 0.0), Color(0.92, 0.76, 0.25))
	return node

static func _create_fire_station_mesh() -> Node3D:
	var node := Node3D.new()
	_add_box(node, Vector3(1.80, 0.10, 1.80), Vector3(0.0, 0.05, 0.0), Color(0.68, 0.68, 0.70))
	_add_box(node, Vector3(1.45, 0.95, 1.30), Vector3(-0.08, 0.57, 0.0), Color(0.86, 0.22, 0.20))
	_add_box(node, Vector3(0.85, 0.55, 0.08), Vector3(-0.12, 0.38, 0.66), Color(0.75, 0.78, 0.82)) # Pintu garasi
	_add_box(node, Vector3(0.36, 1.50, 0.36), Vector3(0.58, 0.85, -0.35), Color(0.78, 0.20, 0.18)) # Menara selang
	_add_box(node, Vector3(0.20, 0.14, 0.16), Vector3(-0.10, 1.12, 0.45), Color(1.0, 0.32, 0.18), true) # Sirene merah
	return node

static func create_fire_effect_node() -> Node3D:
	var root := Node3D.new()
	root.name = "FireEffect"
	_add_box(root, Vector3(0.55, 0.75, 0.55), Vector3(0.0, 1.25, 0.0), Color(1.0, 0.35, 0.10), true)
	_add_box(root, Vector3(0.35, 0.95, 0.35), Vector3(0.15, 1.45, 0.12), Color(1.0, 0.72, 0.15), true)
	_add_box(root, Vector3(0.30, 0.60, 0.30), Vector3(-0.18, 1.15, -0.12), Color(0.95, 0.22, 0.08), true)
	var lbl := Label3D.new()
	lbl.text = "KEBAKARAN!"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 28
	lbl.modulate = Color(1.0, 0.40, 0.15)
	lbl.outline_size = 4
	lbl.outline_modulate = Color(0.1, 0.05, 0.05)
	lbl.no_depth_test = true
	lbl.position = Vector3(0.0, 2.35, 0.0)
	root.add_child(lbl)
	return root

static func create_damaged_badge_node(is_heavy: bool) -> Node3D:
	var root := Node3D.new()
	root.name = "FireDamagedBadge"
	var lbl := Label3D.new()
	lbl.text = "Rusak Berat! Rp25rb" if is_heavy else "Rusak Ringan! Rp10rb"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 24
	lbl.modulate = Color(1.0, 0.35, 0.35) if is_heavy else Color(1.0, 0.75, 0.25)
	lbl.outline_size = 4
	lbl.outline_modulate = Color(0.1, 0.1, 0.1)
	lbl.no_depth_test = true
	lbl.position = Vector3(0.0, 2.0, 0.0)
	root.add_child(lbl)
	return root

static func create_wide_road_mesh() -> Node3D:
	var node := Node3D.new()
	_add_box(node, Vector3(2.0, 0.028, 2.0), Vector3(0.0, 0.014, 0.0), Color(0.45, 0.47, 0.50))
	_add_box(node, Vector3(1.86, 0.038, 2.0), Vector3(0.0, 0.019, 0.0), Color(0.18, 0.19, 0.22))
	_add_box(node, Vector3(0.08, 0.045, 1.85), Vector3(0.0, 0.024, 0.0), Color(0.96, 0.85, 0.25))
	_add_box(node, Vector3(0.05, 0.045, 1.90), Vector3(-0.84, 0.024, 0.0), Color(0.92, 0.92, 0.92))
	_add_box(node, Vector3(0.05, 0.045, 1.90), Vector3(0.84, 0.024, 0.0), Color(0.92, 0.92, 0.92))
	return node

static func _create_military_zone_mesh(level: int) -> Node3D:
	var node := Node3D.new()
	_add_box(node, Vector3(1.9, 0.06, 1.9), Vector3(0.0, 0.03, 0.0), Color(0.32, 0.38, 0.25))
	# Pagar hijau army di sekeliling
	_add_box(node, Vector3(1.9, 0.20, 0.06), Vector3(0.0, 0.12, -0.92), Color(0.24, 0.30, 0.18))
	_add_box(node, Vector3(1.9, 0.20, 0.06), Vector3(0.0, 0.12, 0.92), Color(0.24, 0.30, 0.18))
	if level == 1:
		_add_box(node, Vector3(1.2, 0.55, 0.8), Vector3(0.0, 0.32, 0.0), Color(0.35, 0.46, 0.28))
		_add_prism_roof(node, Vector3(1.25, 0.25, 0.85), Vector3(0.0, 0.72, 0.0), Color(0.26, 0.34, 0.20))
	elif level == 2:
		_add_box(node, Vector3(1.3, 0.70, 1.0), Vector3(0.0, 0.40, 0.0), Color(0.38, 0.45, 0.30))
		_add_box(node, Vector3(1.35, 0.12, 1.05), Vector3(0.0, 0.80, 0.0), Color(0.25, 0.30, 0.20))
	else:
		_add_box(node, Vector3(0.75, 0.65, 0.75), Vector3(-0.4, 0.36, -0.3), Color(0.35, 0.45, 0.28))
		_add_box(node, Vector3(0.75, 0.08, 0.75), Vector3(0.4, 0.08, 0.35), Color(0.55, 0.52, 0.38)) # Lapangan latihan
	return node

static func _create_rail_mesh() -> Node3D:
	var node := Node3D.new()
	_add_box(node, Vector3(1.6, 0.03, 2.0), Vector3(0.0, 0.015, 0.0), Color(0.35, 0.30, 0.25))
	for z in [-0.7, -0.25, 0.25, 0.7]:
		_add_box(node, Vector3(1.2, 0.05, 0.14), Vector3(0.0, 0.04, z), Color(0.45, 0.30, 0.18))
	_add_box(node, Vector3(0.10, 0.07, 2.0), Vector3(-0.35, 0.07, 0.0), Color(0.68, 0.70, 0.74))
	_add_box(node, Vector3(0.10, 0.07, 2.0), Vector3(0.35, 0.07, 0.0), Color(0.68, 0.70, 0.74))
	return node

static func _create_train_station_mesh() -> Node3D:
	var node := Node3D.new()
	_add_box(node, Vector3(1.85, 0.12, 1.85), Vector3(0.0, 0.06, 0.0), Color(0.70, 0.72, 0.75))
	_add_box(node, Vector3(1.5, 0.85, 1.1), Vector3(0.0, 0.55, -0.15), Color(0.88, 0.90, 0.94))
	_add_prism_roof(node, Vector3(1.65, 0.45, 1.25), Vector3(0.0, 1.20, -0.15), Color(0.22, 0.45, 0.75))
	_add_box(node, Vector3(0.8, 0.20, 0.06), Vector3(0.0, 0.95, 0.42), Color(0.15, 0.35, 0.65))
	return node

static func _create_stop_mesh(color: Color) -> Node3D:
	var node := Node3D.new()
	_add_box(node, Vector3(0.95, 0.55, 0.45), Vector3(0.45, 0.30, -0.55), Color(0.88, 0.90, 0.94))
	_add_box(node, Vector3(1.05, 0.10, 0.55), Vector3(0.45, 0.60, -0.55), color)
	return node

static func _create_busway_lane_mesh() -> Node3D:
	var node := Node3D.new()
	_add_box(node, Vector3(2.0, 0.035, 2.0), Vector3(0.0, 0.018, 0.0), Color(0.75, 0.25, 0.18))
	_add_box(node, Vector3(0.12, 0.045, 1.8), Vector3(0.0, 0.025, 0.0), Color(0.96, 0.85, 0.25))
	return node

static func _create_stop_busway_mesh() -> Node3D:
	var node := Node3D.new()
	_add_box(node, Vector3(1.2, 0.65, 0.70), Vector3(0.0, 0.35, 0.0), Color(0.90, 0.28, 0.20))
	_add_box(node, Vector3(1.3, 0.10, 0.80), Vector3(0.0, 0.72, 0.0), Color(0.95, 0.78, 0.22))
	return node

static func _create_flyover_mesh() -> Node3D:
	var node := Node3D.new()
	_add_box(node, Vector3(0.32, 0.90, 0.32), Vector3(-0.65, 0.45, 0.0), Color(0.62, 0.64, 0.68))
	_add_box(node, Vector3(0.32, 0.90, 0.32), Vector3(0.65, 0.45, 0.0), Color(0.62, 0.64, 0.68))
	_add_box(node, Vector3(2.0, 0.16, 1.75), Vector3(0.0, 0.95, 0.0), Color(0.32, 0.34, 0.38))
	_add_box(node, Vector3(1.9, 0.18, 0.08), Vector3(0.0, 1.05, -0.82), Color(0.78, 0.80, 0.82))
	_add_box(node, Vector3(1.9, 0.18, 0.08), Vector3(0.0, 1.05, 0.82), Color(0.78, 0.80, 0.82))
	return node

static func _create_runway_mesh() -> Node3D:
	var node := Node3D.new()
	_add_box(node, Vector3(2.0, 0.04, 2.0), Vector3(0.0, 0.02, 0.0), Color(0.16, 0.17, 0.20))
	_add_box(node, Vector3(1.3, 0.05, 0.14), Vector3(0.0, 0.028, 0.0), Color(0.95, 0.95, 0.95))
	return node

static func _create_airport_terminal_mesh() -> Node3D:
	var node := Node3D.new()
	_add_box(node, Vector3(1.95, 0.14, 1.95), Vector3(0.0, 0.07, 0.0), Color(0.78, 0.80, 0.84))
	_add_box(node, Vector3(1.75, 1.40, 1.30), Vector3(0.0, 0.84, 0.0), Color(0.94, 0.96, 0.98))
	_add_box(node, Vector3(1.78, 0.55, 1.34), Vector3(0.0, 0.85, 0.0), Color(0.35, 0.68, 0.92)) # Kaca biru
	_add_box(node, Vector3(1.85, 0.18, 1.40), Vector3(0.0, 1.62, 0.0), Color(0.84, 0.88, 0.92)) # Atap
	# Menara kontrol mini
	_add_box(node, Vector3(0.35, 2.25, 0.35), Vector3(0.70, 1.25, -0.55), Color(0.90, 0.92, 0.95))
	_add_box(node, Vector3(0.55, 0.35, 0.55), Vector3(0.70, 2.45, -0.55), Color(0.28, 0.62, 0.88))
	var lbl := Label3D.new()
	lbl.text = "BANDARA KOTABARENG"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 20
	lbl.modulate = Color(0.98, 0.88, 0.28)
	lbl.outline_size = 3
	lbl.outline_modulate = Color(0.08, 0.08, 0.12)
	lbl.position = Vector3(0.0, 2.1, 0.0)
	node.add_child(lbl)
	return node

static func create_airplane_node() -> Node3D:
	var node := Node3D.new()
	_add_box(node, Vector3(0.32, 0.28, 1.45), Vector3(0.0, 0.28, 0.0), Color(0.96, 0.97, 0.99))
	_add_box(node, Vector3(1.65, 0.06, 0.38), Vector3(0.0, 0.26, 0.05), Color(0.88, 0.90, 0.94))
	_add_box(node, Vector3(0.08, 0.38, 0.28), Vector3(0.0, 0.52, -0.58), Color(0.18, 0.45, 0.85))
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

static func _create_kosan_mesh() -> Node3D:
	var node := Node3D.new()
	# Bangunan Kosan 2 lantai + parkiran motor di depan + papan KOSAN
	_add_box(node, Vector3(2.8, 0.08, 2.8), Vector3(0.0, 0.04, 0.0), Color(0.55, 0.56, 0.58))
	_add_box(node, Vector3(2.3, 1.55, 1.7), Vector3(0.0, 0.85, -0.35), Color(0.92, 0.86, 0.72))
	_add_prism_roof(node, Vector3(2.45, 0.55, 1.85), Vector3(0.0, 1.90, -0.35), Color(0.72, 0.30, 0.22))
	for fl in [0.55, 1.25]:
		for wx in [-0.75, -0.25, 0.25, 0.75]:
			_add_box(node, Vector3(0.26, 0.28, 0.05), Vector3(wx, fl, 0.51), Color(0.14, 0.22, 0.32))
	# Parkiran motor kecil di depan
	_add_box(node, Vector3(1.8, 0.04, 0.7), Vector3(0.0, 0.09, 0.95), Color(0.32, 0.34, 0.38))
	var lbl := Label3D.new()
	lbl.text = "KOSAN"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 24
	lbl.modulate = Color(1.0, 0.90, 0.35)
	lbl.position = Vector3(0.0, 2.55, 0.0)
	node.add_child(lbl)
	return node

static func _create_universitas_mesh() -> Node3D:
	var node := Node3D.new()
	# Gedung Universitas 3x3 + lapangan/pohon depan + gerbang + papan UNIVERSITAS
	_add_box(node, Vector3(4.6, 0.10, 4.6), Vector3(0.0, 0.05, 0.0), Color(0.62, 0.64, 0.66))
	_add_box(node, Vector3(3.6, 1.85, 2.2), Vector3(0.0, 1.0, -0.8), Color(0.94, 0.92, 0.86))
	_add_prism_roof(node, Vector3(3.8, 0.75, 2.4), Vector3(0.0, 2.30, -0.8), Color(0.22, 0.42, 0.72))
	_add_box(node, Vector3(1.2, 0.65, 1.2), Vector3(0.0, 2.35, -0.8), Color(0.85, 0.68, 0.22))
	# Lapangan + gerbang depan
	_add_box(node, Vector3(2.8, 0.04, 1.5), Vector3(0.0, 0.11, 1.1), Color(0.26, 0.56, 0.26))
	_add_box(node, Vector3(0.22, 0.9, 0.22), Vector3(-0.7, 0.50, 2.0), Color(0.75, 0.32, 0.22))
	_add_box(node, Vector3(0.22, 0.9, 0.22), Vector3(0.7, 0.50, 2.0), Color(0.75, 0.32, 0.22))
	_add_box(node, Vector3(1.7, 0.18, 0.18), Vector3(0.0, 1.0, 2.0), Color(0.22, 0.42, 0.72))
	var lbl := Label3D.new()
	lbl.text = "UNIVERSITAS"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 28
	lbl.modulate = Color(1.0, 0.92, 0.38)
	lbl.position = Vector3(0.0, 3.25, 0.0)
	node.add_child(lbl)
	return node
