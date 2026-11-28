class_name S1VisualBuilder
extends RefCounted

## Builder visual low-poly prosedural untuk Season 1 (shared mesh/material untuk performa 60 FPS)

static var _mats: Dictionary = {}
static var _meshes: Dictionary = {}

static func _get_mat(key: String, color: Color, roughness: float = 0.85, emission_energy: float = 0.0) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_energy
	_mats[key] = mat
	return mat

static func _get_box(key: String, size_v: Vector3) -> BoxMesh:
	if _meshes.has(key):
		return _meshes[key]
	var m := BoxMesh.new()
	m.size = size_v
	_meshes[key] = m
	return m

static func _get_prism(key: String, size_v: Vector3) -> PrismMesh:
	if _meshes.has(key):
		return _meshes[key]
	var m := PrismMesh.new()
	m.size = size_v
	_meshes[key] = m
	return m

static func _get_limasan(key: String, top_r: float, bot_r: float, height: float) -> CylinderMesh:
	if _meshes.has(key):
		return _meshes[key]
	var m := CylinderMesh.new()
	m.top_radius = top_r
	m.bottom_radius = bot_r
	m.height = height
	m.radial_segments = 4
	_meshes[key] = m
	return m

static func _get_sphere(key: String, radius: float) -> SphereMesh:
	if _meshes.has(key):
		return _meshes[key]
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 8
	m.rings = 4
	_meshes[key] = m
	return m

## 4 varian rumah low-poly dengan shared mesh/material; rumah pemain punya pot bunga di depan pintu
static func create_house(variant: int, is_player_house: bool = false) -> Node3D:
	var house := Node3D.new()

	var wall_colors := [
		["w_white", Color(0.95, 0.95, 0.93)],
		["w_cream", Color(0.94, 0.89, 0.76)],
		["w_blue", Color(0.80, 0.88, 0.96)],
		["w_yellow", Color(0.96, 0.92, 0.72)]
	]
	var roof_colors := [
		["r_red", Color(0.76, 0.27, 0.21)],
		["r_brown", Color(0.52, 0.32, 0.18)],
		["r_grey", Color(0.42, 0.45, 0.48)]
	]
	var wc: Array = wall_colors[variant % wall_colors.size()]
	var rc: Array = roof_colors[(variant / 2 + variant) % roof_colors.size()]

	# Dinding
	var wall := MeshInstance3D.new()
	wall.mesh = _get_box("house_wall", Vector3(2.2, 1.4, 2.0))
	wall.material_override = _get_mat(wc[0], wc[1])
	wall.position = Vector3(0.0, 0.7, 0.0)
	house.add_child(wall)

	# Atap: pelana (genap) atau limasan sederhana (ganjil)
	var roof := MeshInstance3D.new()
	if variant % 2 == 0:
		roof.mesh = _get_prism("house_roof_pelana", Vector3(2.5, 0.9, 2.3))
		roof.position = Vector3(0.0, 1.85, 0.0)
	else:
		roof.mesh = _get_limasan("house_roof_limasan", 0.35, 1.75, 0.85)
		roof.rotation_degrees.y = 45.0
		roof.position = Vector3(0.0, 1.82, 0.0)
	roof.material_override = _get_mat(rc[0], rc[1])
	house.add_child(roof)

	# Pintu
	var door := MeshInstance3D.new()
	door.mesh = _get_box("house_door", Vector3(0.45, 0.88, 0.08))
	door.material_override = _get_mat("door_wood", Color(0.42, 0.25, 0.14))
	door.position = Vector3(0.0, 0.44, 1.02)
	house.add_child(door)

	# Jendela gelap sedikit mengkilap (shared mesh & material)
	var win_mat: StandardMaterial3D = _get_mat("window_glass", Color(0.14, 0.20, 0.28), 0.16)
	win_mat.metallic = 0.15
	for wx in [-0.62, 0.62]:
		var win := MeshInstance3D.new()
		win.mesh = _get_box("house_window", Vector3(0.34, 0.34, 0.06))
		win.material_override = win_mat
		win.position = Vector3(wx, 0.82, 1.01)
		house.add_child(win)

	# Cerobong atau antena kecil di atap beberapa rumah
	if variant % 3 == 0:
		var chim := MeshInstance3D.new()
		chim.mesh = _get_box("house_chimney", Vector3(0.22, 0.45, 0.22))
		chim.material_override = _get_mat("chimney_brick", Color(0.55, 0.30, 0.24))
		chim.position = Vector3(0.65, 2.08, -0.35)
		house.add_child(chim)
	elif variant % 3 == 1:
		var ant := MeshInstance3D.new()
		ant.mesh = _get_box("house_antenna", Vector3(0.04, 0.55, 0.04))
		ant.material_override = _get_mat("iron_dark", Color(0.22, 0.24, 0.28))
		ant.position = Vector3(-0.55, 2.15, -0.25)
		house.add_child(ant)

	# Teras kecil + tiang untuk varian 1 & 3
	if variant % 2 == 1:
		var porch := MeshInstance3D.new()
		porch.mesh = _get_box("porch_floor", Vector3(2.2, 0.10, 0.55))
		porch.material_override = _get_mat("porch_stone", Color(0.72, 0.72, 0.70))
		porch.position = Vector3(0.0, 0.05, 1.25)
		house.add_child(porch)
		for px in [-0.95, 0.95]:
			var post := MeshInstance3D.new()
			post.mesh = _get_box("porch_post", Vector3(0.10, 1.35, 0.10))
			post.material_override = _get_mat("wood_trim", Color(0.55, 0.38, 0.22))
			post.position = Vector3(px, 0.68, 1.45)
			house.add_child(post)

	# Pagar bambu rendah untuk varian 2 & 3
	if variant >= 2:
		var fence := MeshInstance3D.new()
		fence.mesh = _get_box("bamboo_fence", Vector3(2.5, 0.32, 0.08))
		fence.material_override = _get_mat("bamboo", Color(0.68, 0.58, 0.34))
		fence.position = Vector3(0.0, 0.16, 1.58)
		house.add_child(fence)

	# Pot bunga di depan pintu khusus rumah pemain
	if is_player_house:
		var pot := MeshInstance3D.new()
		pot.mesh = _get_box("flower_pot", Vector3(0.24, 0.22, 0.24))
		pot.material_override = _get_mat("terracotta", Color(0.75, 0.35, 0.20))
		pot.position = Vector3(0.52, 0.11, 1.22)
		house.add_child(pot)

		var flower := MeshInstance3D.new()
		flower.mesh = _get_sphere("flower_top", 0.14)
		flower.material_override = _get_mat("flower_pink", Color(0.95, 0.35, 0.55))
		flower.position = Vector3(0.52, 0.30, 1.22)
		house.add_child(flower)

	return house

## 3 varian pohon low-poly (tinggi/pendek, hijau tua/muda)
static func create_tree(variant: int) -> Node3D:
	var tree := Node3D.new()
	var is_tall: bool = (variant % 2 == 0)
	var trunk_h: float = 1.1 if is_tall else 0.75

	var trunk := MeshInstance3D.new()
	trunk.mesh = _get_box("trunk_%s" % ("tall" if is_tall else "short"), Vector3(0.22, trunk_h, 0.22))
	trunk.material_override = _get_mat("tree_trunk", Color(0.44, 0.28, 0.16))
	trunk.position = Vector3(0.0, trunk_h * 0.5, 0.0)
	tree.add_child(trunk)

	var leaf_key: String = "leaf_dark" if (variant % 3 == 0) else "leaf_light"
	var leaf_col: Color = Color(0.16, 0.48, 0.18) if (variant % 3 == 0) else Color(0.26, 0.64, 0.24)
	var leaves := MeshInstance3D.new()
	if variant % 3 == 2:
		leaves.mesh = _get_sphere("leaf_sphere", 0.55)
	else:
		leaves.mesh = _get_box("leaf_box_%s" % ("tall" if is_tall else "short"), Vector3(0.95, 0.85, 0.95) if is_tall else Vector3(0.75, 0.65, 0.75))
	leaves.material_override = _get_mat(leaf_key, leaf_col)
	leaves.position = Vector3(0.0, trunk_h + 0.35, 0.0)
	tree.add_child(leaves)

	return tree

## Lampu jalan (tiang + bola lampu menyala hangat)
static func create_street_lamp() -> Node3D:
	var lamp := Node3D.new()
	var pole := MeshInstance3D.new()
	pole.mesh = _get_box("lamp_pole", Vector3(0.10, 2.2, 0.10))
	pole.material_override = _get_mat("iron_dark", Color(0.22, 0.24, 0.28))
	pole.position = Vector3(0.0, 1.1, 0.0)
	lamp.add_child(pole)

	var bulb := MeshInstance3D.new()
	bulb.mesh = _get_sphere("lamp_bulb", 0.14)
	bulb.material_override = _get_mat("lamp_glow", Color(1.0, 0.90, 0.58), 0.3, 0.85)
	bulb.position = Vector3(0.0, 2.25, 0.0)
	lamp.add_child(bulb)
	return lamp

static func _enable_shadows_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for child in node.get_children():
		_enable_shadows_recursive(child)

## Warung kecil visual (model 3D res://assets/models/warung.glb + fallback)
static func create_warung() -> Node3D:
	const WARUNG_GLB: String = "res://assets/models/warung.glb"
	if ResourceLoader.exists(WARUNG_GLB):
		var scene_res: PackedScene = load(WARUNG_GLB) as PackedScene
		if scene_res:
			var model: Node3D = scene_res.instantiate() as Node3D
			if model:
				_enable_shadows_recursive(model)
				return model
	var w := Node3D.new()
	var body := MeshInstance3D.new()
	body.mesh = _get_box("warung_body", Vector3(2.0, 1.3, 1.6))
	body.material_override = _get_mat("warung_wood", Color(0.82, 0.72, 0.55))
	body.position = Vector3(0.0, 0.65, 0.0)
	w.add_child(body)

	var awning := MeshInstance3D.new()
	awning.mesh = _get_box("warung_roof", Vector3(2.3, 0.16, 2.1))
	awning.material_override = _get_mat("warung_blue", Color(0.15, 0.48, 0.85))
	awning.position = Vector3(0.0, 1.42, 0.15)
	w.add_child(awning)

	var lbl := Label3D.new()
	lbl.text = "WARUNG"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 24
	lbl.modulate = Color(1.0, 0.90, 0.35)
	lbl.position = Vector3(0.0, 2.0, 0.0)
	w.add_child(lbl)
	return w

## Bangku taman / lapangan + tempat sampah sudut jalan
static func create_bench() -> Node3D:
	var b := Node3D.new()
	var seat := MeshInstance3D.new()
	seat.mesh = _get_box("bench_seat", Vector3(1.1, 0.12, 0.36))
	seat.material_override = _get_mat("wood_trim", Color(0.55, 0.38, 0.22))
	seat.position = Vector3(0.0, 0.28, 0.0)
	b.add_child(seat)
	for lx in [-0.42, 0.42]:
		var leg := MeshInstance3D.new()
		leg.mesh = _get_box("bench_leg", Vector3(0.10, 0.28, 0.32))
		leg.material_override = _get_mat("iron_dark", Color(0.22, 0.24, 0.28))
		leg.position = Vector3(lx, 0.14, 0.0)
		b.add_child(leg)
	return b

static func create_trash_bin() -> Node3D:
	var tb := Node3D.new()
	var bin := MeshInstance3D.new()
	bin.mesh = _get_box("trash_bin", Vector3(0.32, 0.48, 0.32))
	bin.material_override = _get_mat("bin_green", Color(0.20, 0.55, 0.28))
	bin.position = Vector3(0.0, 0.24, 0.0)
	tb.add_child(bin)
	return tb

## Warga low-poly bervariasi (baju, kulit, tinggi, gender rambut/hijab/topi) dengan referensi anggota badan
static func create_citizen_rig(seed_idx: int, is_player: bool = false, gender: String = "", height_scale: float = 1.0, custom_shirt: Color = Color(-1, 0, 0), custom_head: Color = Color(-1, 0, 0)) -> Dictionary:
	var root := Node3D.new()

	var shirt_list := [
		["sh_blue", Color(0.24, 0.56, 0.85)],
		["sh_red", Color(0.84, 0.28, 0.30)],
		["sh_green", Color(0.26, 0.68, 0.36)],
		["sh_yellow", Color(0.92, 0.76, 0.22)],
		["sh_purple", Color(0.60, 0.36, 0.78)]
	]
	var skin_list := [
		["sk_1", Color(0.92, 0.78, 0.64)],
		["sk_2", Color(0.86, 0.69, 0.53)],
		["sk_3", Color(0.74, 0.56, 0.40)],
		["sk_4", Color(0.60, 0.42, 0.28)]
	]

	var sh: Array = shirt_list[0] if is_player else shirt_list[seed_idx % shirt_list.size()]
	var sk: Array = skin_list[seed_idx % skin_list.size()]
	var sh_mat: StandardMaterial3D = _get_mat(sh[0], sh[1])
	if custom_shirt.r >= 0.0:
		sh_mat = StandardMaterial3D.new()
		sh_mat.albedo_color = custom_shirt

	var body_pivot := Node3D.new()
	body_pivot.scale = Vector3(1.0, height_scale, 1.0)
	root.add_child(body_pivot)

	# Bayangan lembut di bawah warga agar tidak terlihat melayang
	var sh_mesh: CylinderMesh
	if _meshes.has("cit_blob_shadow"):
		sh_mesh = _meshes["cit_blob_shadow"] as CylinderMesh
	else:
		sh_mesh = CylinderMesh.new()
		sh_mesh.top_radius = 0.24
		sh_mesh.bottom_radius = 0.24
		sh_mesh.height = 0.012
		sh_mesh.radial_segments = 10
		_meshes["cit_blob_shadow"] = sh_mesh
	var sh_blob_mat: StandardMaterial3D
	if _mats.has("cit_blob_mat"):
		sh_blob_mat = _mats["cit_blob_mat"] as StandardMaterial3D
	else:
		sh_blob_mat = StandardMaterial3D.new()
		sh_blob_mat.albedo_color = Color(0.05, 0.06, 0.08, 0.32)
		sh_blob_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sh_blob_mat.roughness = 1.0
		_mats["cit_blob_mat"] = sh_blob_mat
	var blob_shadow := MeshInstance3D.new()
	blob_shadow.mesh = sh_mesh
	blob_shadow.material_override = sh_blob_mat
	blob_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	blob_shadow.position = Vector3(0.0, 0.01, 0.0)
	root.add_child(blob_shadow)

	# Kaki kiri & kanan (berayun saat jalan)
	var leg_l := MeshInstance3D.new()
	leg_l.mesh = _get_box("cit_leg", Vector3(0.13, 0.46, 0.13))
	leg_l.material_override = _get_mat("pants_dark", Color(0.18, 0.22, 0.30))
	leg_l.position = Vector3(-0.10, 0.23, 0.0)
	body_pivot.add_child(leg_l)

	var leg_r := MeshInstance3D.new()
	leg_r.mesh = _get_box("cit_leg", Vector3(0.13, 0.46, 0.13))
	leg_r.material_override = _get_mat("pants_dark", Color(0.18, 0.22, 0.30))
	leg_r.position = Vector3(0.10, 0.23, 0.0)
	body_pivot.add_child(leg_r)

	# Badan
	var torso := MeshInstance3D.new()
	torso.mesh = _get_box("cit_torso", Vector3(0.40, 0.50, 0.22))
	torso.material_override = sh_mat
	torso.position = Vector3(0.0, 0.71, 0.0)
	body_pivot.add_child(torso)

	# Lengan kiri & kanan (berayun berlawanan kaki)
	var arm_l := MeshInstance3D.new()
	arm_l.mesh = _get_box("cit_arm", Vector3(0.11, 0.42, 0.11))
	arm_l.material_override = sh_mat
	arm_l.position = Vector3(-0.27, 0.72, 0.0)
	body_pivot.add_child(arm_l)

	var arm_r := MeshInstance3D.new()
	arm_r.mesh = _get_box("cit_arm", Vector3(0.11, 0.42, 0.11))
	arm_r.material_override = sh_mat
	arm_r.position = Vector3(0.27, 0.72, 0.0)
	body_pivot.add_child(arm_r)

	# Kepala
	var head := MeshInstance3D.new()
	head.mesh = _get_box("cit_head", Vector3(0.28, 0.28, 0.28))
	head.material_override = _get_mat(sk[0], sk[1])
	head.position = Vector3(0.0, 1.12, 0.0)
	body_pivot.add_child(head)

	# Model gender berbeda: perempuan (hijab / rambut panjang) vs laki-laki (topi / rambut pendek)
	var h_col: Color = custom_head if custom_head.r >= 0.0 else Color(0.88, 0.78, 0.85)
	var h_mat: StandardMaterial3D = StandardMaterial3D.new()
	h_mat.albedo_color = h_col
	if not is_player and gender == "F":
		if seed_idx % 2 == 0:
			var kerudung := MeshInstance3D.new()
			kerudung.mesh = _get_box("cit_hijab", Vector3(0.32, 0.34, 0.32))
			kerudung.material_override = h_mat
			kerudung.position = Vector3(0.0, 1.12, -0.02)
			body_pivot.add_child(kerudung)
		else:
			var hair := MeshInstance3D.new()
			hair.mesh = _get_box("cit_long_hair", Vector3(0.32, 0.42, 0.16))
			hair.material_override = h_mat
			hair.position = Vector3(0.0, 1.06, -0.10)
			body_pivot.add_child(hair)
	elif not is_player and (gender == "M" or seed_idx % 3 == 1):
		var cap := MeshInstance3D.new()
		cap.mesh = _get_box("cit_cap", Vector3(0.31, 0.09, 0.31))
		cap.material_override = h_mat if custom_head.r >= 0.0 else _get_mat("cap_col", Color(0.25, 0.30, 0.38))
		cap.position = Vector3(0.0, 1.29, 0.0)
		body_pivot.add_child(cap)
	elif not is_player and seed_idx % 3 == 2:
		var kerudung := MeshInstance3D.new()
		kerudung.mesh = _get_box("cit_hijab", Vector3(0.32, 0.32, 0.32))
		kerudung.material_override = _get_mat("hijab_col", Color(0.88, 0.78, 0.85))
		kerudung.position = Vector3(0.0, 1.14, -0.02)
		body_pivot.add_child(kerudung)

	# Tas / Ember kecil di tangan kanan
	if not is_player and seed_idx % 2 == 1:
		var bag := MeshInstance3D.new()
		bag.mesh = _get_box("cit_bag", Vector3(0.16, 0.20, 0.16))
		bag.material_override = _get_mat("bag_col", Color(0.55, 0.36, 0.20))
		bag.position = Vector3(0.30, 0.45, 0.06)
		body_pivot.add_child(bag)

	return {
		"root": root,
		"pivot": body_pivot,
		"leg_l": leg_l,
		"leg_r": leg_r,
		"arm_l": arm_l,
		"arm_r": arm_r
	}

## Ikon geometris kecil 2D (tanpa gambar luar, tanpa emoji)
class StatIcon extends Control:
	var icon_type: String = "money"

	func _init(p_type: String) -> void:
		icon_type = p_type
		custom_minimum_size = Vector2(18, 18)

	func _draw() -> void:
		var c := Vector2(9.0, 9.0)
		match icon_type:
			"money":
				draw_circle(c, 8.0, Color(0.95, 0.78, 0.20))
				draw_string(ThemeDB.fallback_font, Vector2(2.5, 13.0), "Rp", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.10, 0.12, 0.16))
			"health":
				draw_rect(Rect2(7.0, 2.0, 4.0, 14.0), Color(0.30, 0.90, 0.45))
				draw_rect(Rect2(2.0, 7.0, 14.0, 4.0), Color(0.30, 0.90, 0.45))
			"happy":
				draw_circle(c, 7.5, Color(1.0, 0.85, 0.28))
				draw_circle(Vector2(6.5, 7.0), 1.2, Color(0.12, 0.12, 0.15))
				draw_circle(Vector2(11.5, 7.0), 1.2, Color(0.12, 0.12, 0.15))
				draw_arc(Vector2(9.0, 9.5), 4.0, 0.2, PI - 0.2, 8, Color(0.12, 0.12, 0.15), 1.5)
			"pop":
				var pts := PackedVector2Array([
					Vector2(9, 1), Vector2(11.3, 6.2), Vector2(17, 6.8), Vector2(12.6, 10.6),
					Vector2(14, 16.5), Vector2(9, 13.2), Vector2(4, 16.5), Vector2(5.4, 10.6),
					Vector2(1, 6.8), Vector2(6.7, 6.2)
				])
				draw_colored_polygon(pts, Color(0.35, 0.85, 0.98))
			"integ":
				var s_pts := PackedVector2Array([
					Vector2(9, 1.5), Vector2(15.5, 4.0), Vector2(14.5, 11.5),
					Vector2(9, 16.5), Vector2(3.5, 11.5), Vector2(2.5, 4.0)
				])
				draw_colored_polygon(s_pts, Color(0.68, 0.55, 0.98))
			"kas":
				draw_rect(Rect2(2.0, 4.0, 14.0, 10.0), Color(0.95, 0.65, 0.22))
				draw_rect(Rect2(5.0, 2.0, 8.0, 3.0), Color(0.75, 0.48, 0.15))
			"power":
				var bolt := PackedVector2Array([
					Vector2(10, 1), Vector2(4, 10), Vector2(9, 10),
					Vector2(7, 17), Vector2(14, 8), Vector2(9, 8)
				])
				draw_colored_polygon(bolt, Color(1.0, 0.85, 0.22))
			"water":
				var drop := PackedVector2Array([
					Vector2(9, 1.5), Vector2(14.5, 9.5), Vector2(13.5, 14.0),
					Vector2(9, 16.5), Vector2(4.5, 14.0), Vector2(3.5, 9.5)
				])
				draw_colored_polygon(drop, Color(0.28, 0.72, 1.0))
			"date":
				draw_rect(Rect2(2.5, 3.5, 13.0, 12.0), Color(0.85, 0.88, 0.94))
				draw_rect(Rect2(2.5, 3.5, 13.0, 3.5), Color(0.90, 0.30, 0.30))
			"warn":
				var tri := PackedVector2Array([
					Vector2(9, 2), Vector2(16, 15.5), Vector2(2, 15.5)
				])
				draw_colored_polygon(tri, Color(1.0, 0.32, 0.32))
			"security":
				var sh := PackedVector2Array([
					Vector2(9, 1.5), Vector2(15.5, 4.0), Vector2(14.5, 11.5),
					Vector2(9, 16.5), Vector2(3.5, 11.5), Vector2(2.5, 4.0)
				])
				draw_colored_polygon(sh, Color(0.28, 0.68, 0.96))
			"sun":
				draw_circle(c, 5.2, Color(1.0, 0.85, 0.22))
			"cloud":
				draw_circle(Vector2(6.5, 10.5), 4.0, Color(0.82, 0.86, 0.92))
				draw_circle(Vector2(10.5, 9.5), 4.5, Color(0.86, 0.90, 0.95))
				draw_circle(Vector2(13.0, 11.0), 3.2, Color(0.80, 0.84, 0.90))
			"rain":
				draw_circle(Vector2(7.0, 8.0), 3.8, Color(0.65, 0.72, 0.82))
				draw_circle(Vector2(11.0, 7.5), 4.2, Color(0.70, 0.76, 0.86))
				draw_line(Vector2(5.5, 12.5), Vector2(4.5, 16.0), Color(0.35, 0.75, 1.0), 1.8)
				draw_line(Vector2(9.5, 12.5), Vector2(8.5, 16.0), Color(0.35, 0.75, 1.0), 1.8)
				draw_line(Vector2(13.5, 12.5), Vector2(12.5, 16.0), Color(0.35, 0.75, 1.0), 1.8)
