class_name AmbientLifeHelper
extends Node3D

## Detail hidup ringan (burung V, goyang pohon pelan, ombak pantai, kapal laut, arus sungai, asap pabrik)

var _birds_root: Node3D = null
var _bird_timer: float = 18.0
var _bird_flying: bool = false
var _bird_progress: float = 0.0

var _boat_node: Node3D = null
var _boat_timer: float = 25.0
var _boat_moving: bool = false
var _boat_x: float = -12.0
var _has_sea: bool = false

var _wave_node: Node3D = null
var _river_flow_node: Node3D = null
var _time_acc: float = 0.0

func setup(has_sea: bool, wave_node: Node3D = null, river_flow_node: Node3D = null) -> void:
	_has_sea = has_sea
	_wave_node = wave_node
	_river_flow_node = river_flow_node
	_create_birds()
	if _has_sea:
		_create_boat()

func _create_birds() -> void:
	_birds_root = Node3D.new()
	_birds_root.visible = false
	add_child(_birds_root)
	var wing_mesh := BoxMesh.new()
	wing_mesh.size = Vector3(0.28, 0.04, 0.10)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.20, 0.24)
	for idx in range(3):
		var b := Node3D.new()
		b.position = Vector3(float(idx) * 1.1, float(idx % 2) * 0.4, float(idx) * 0.8)
		var w1 := MeshInstance3D.new()
		w1.mesh = wing_mesh
		w1.material_override = mat
		w1.rotation_degrees.z = 24.0
		w1.position = Vector3(-0.12, 0.0, 0.0)
		var w2 := MeshInstance3D.new()
		w2.mesh = wing_mesh
		w2.material_override = mat
		w2.rotation_degrees.z = -24.0
		w2.position = Vector3(0.12, 0.0, 0.0)
		b.add_child(w1)
		b.add_child(w2)
		_birds_root.add_child(b)

func _create_boat() -> void:
	_boat_node = Node3D.new()
	_boat_node.visible = false
	add_child(_boat_node)
	var hull := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(1.2, 0.22, 0.45)
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.88, 0.90, 0.94)
	hull.mesh = hb
	hull.material_override = hmat
	hull.position = Vector3(0.0, 0.12, 0.0)
	_boat_node.add_child(hull)
	var cabin := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(0.45, 0.24, 0.32)
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.85, 0.35, 0.20)
	cabin.mesh = cb
	cabin.material_override = cmat
	cabin.position = Vector3(0.0, 0.34, 0.0)
	_boat_node.add_child(cabin)

func tick(delta: float, tree_dict: Dictionary, tile_visuals: Dictionary) -> void:
	_time_acc += delta

	# 1. Burung V lewat berkala
	if _bird_flying:
		_bird_progress += delta * 4.5
		_birds_root.position = Vector3(-12.0 + _bird_progress, 12.5, 8.0 + sin(_time_acc) * 1.5)
		if _bird_progress > 56.0:
			_bird_flying = false
			_birds_root.visible = false
			_bird_timer = randf_range(50.0, 95.0)
	else:
		_bird_timer -= delta
		if _bird_timer <= 0.0:
			_bird_flying = true
			_bird_progress = 0.0
			_birds_root.visible = true

	# 2. Kapal laut lewat (hanya peta Pantai)
	if _has_sea and _boat_node:
		if _boat_moving:
			_boat_x += delta * 2.2
			_boat_node.position = Vector3(_boat_x, 0.04, 1.5)
			if _boat_x > 46.0:
				_boat_moving = false
				_boat_node.visible = false
				_boat_timer = randf_range(75.0, 140.0)
		else:
			_boat_timer -= delta
			if _boat_timer <= 0.0:
				_boat_moving = true
				_boat_x = -14.0
				_boat_node.visible = true

	# 3. Ombak putih tepi pantai & arus sungai mengalir pelan
	if _wave_node and is_instance_valid(_wave_node):
		_wave_node.position.z = 3.95 + sin(_time_acc * 1.4) * 0.25
	if _river_flow_node and is_instance_valid(_river_flow_node):
		_river_flow_node.position.z = fmod(_time_acc * 0.8, 2.0)

	# 4. Pohon goyang sangat pelan
	var sway := sin(_time_acc * 1.1) * 0.022
	for k in tree_dict.keys():
		var tree_node: Node3D = tree_dict[k]
		if tree_node and is_instance_valid(tree_node):
			tree_node.rotation.z = sway

	# 5. Asap cerobong pabrik naik pelan
	var puff_y := fmod(_time_acc * 0.6, 0.9)
	for k in tile_visuals.keys():
		var nd: Node3D = tile_visuals[k]
		if nd and is_instance_valid(nd):
			var sm := nd.find_child("SmokePuff", true, false) as Node3D
			if sm:
				sm.position.y += delta * 0.45
				if sm.position.y > 3.2:
					sm.position.y = 1.45 + puff_y * 0.2
