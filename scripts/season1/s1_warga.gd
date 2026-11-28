class_name S1Warga
extends Node3D

## Season 1 (S1-1, S1-2, S1-3): Warga Biasa -> Ketua RT -> Ketua RW -> Lurah -> Camat

const SAVE_S1_PATH: String = "user://save_season1.cfg"
const LIVING_COST: int = 1000000

# Data Pemain Season 1
var nama: String = ""
var umur: int = 20
var pekerjaan: String = ""
var uang: int = 500000
var kesehatan: int = 80
var kebahagiaan: int = 70
var popularitas: int = 5
var integritas: int = 80
var bulan: int = 1
var riwayat_pekerjaan: Array = []

# Data Jabatan S1-2 & S1-3 (RT -> RW -> Lurah -> Camat)
var jabatan: String = "Warga" # "Warga" | "Ketua RT 03" | "Ketua RW 01" | "Lurah" | "Camat"
var bulan_jadi_rt: int = 0
var bulan_jadi_rw: int = 0
var bulan_jadi_lurah: int = 0
var bulan_jadi_camat: int = 0
var kas_rt: int = 0
var kas_rw: int = 0
var anggaran_kelurahan: int = 0
var anggaran_kecamatan: int = 0
var season1_selesai: bool = false
var kas_rt_ever_minus: bool = false
var pemilu_cooldown_until: int = 0
var ronda_months: int = 0
var clean_months: int = 0
var active_complaints: Array = [] # [{ "id", "title", "cost", "rt_label", "months_ignored", "escalated" }]
var _complaint_seq: int = 0

# Kamera sederhana
@onready var cam: Camera3D = $Camera3D
@onready var world_root: Node3D = $WorldRoot
@onready var ui_layer: CanvasLayer = $CanvasLayer

var _cam_target: Vector3 = Vector3(0.0, 0.6, 0.0)
var _cam_dragging: bool = false

# UI Referensi
var setup_modal: PanelContainer = null
var hud_root: Control = null
var lbl_stats: Label = null
var lbl_profile: Label = null
var lbl_event: Label = null
var btn_election: Button = null
var lbl_election_hint: Label = null
var lbl_job_panel_title: Label = null
var jobs_vbox: VBoxContainer = null
var _job_buttons: Array = []
var s1_done_modal: PanelContainer = null
var lbl_s1_done_summary: Label = null
var pause_modal: PanelContainer = null
var settings_modal: PanelContainer = null
var _villagers: Array = [] # [{ "rig": Dict, "start_x": float, "end_x": float, "z": float, "dir": float, "speed": float, "phase": float }]
var lbl_val_uang: Label = null
var lbl_val_kas: Label = null
var kas_icon_node: Control = null
var lbl_val_sehat: Label = null
var lbl_val_senang: Label = null
var lbl_val_pop: Label = null
var lbl_val_integ: Label = null
var s1_toast_label: Label = null
var s1_toast_timer: float = 0.0
var _blink_time: float = 0.0

# Panel Pemerintahan (RT / RW / Lurah / Camat)
var gov_panel: PanelContainer = null
var lbl_gov_title: Label = null
var lbl_gov_info: Label = null
var gov_actions_vbox: VBoxContainer = null
var gov_complaints_vbox: VBoxContainer = null
var weather_helper: WeatherCycleHelper = null
var s1_waktu_jam: float = 12.0
var s1_cuaca: String = "cerah"
var lbl_s1_clock: Label = null
var s1_weather_icon: S1VisualBuilder.StatIcon = null
var _s1_weather_accum: float = 0.0
var s1_photo_helper: PhotoModeHelper = null
var s1_photo_paused: bool = false
var s1_ambient: AmbientLifeHelper = null

var posisi_pemain: Vector3 = Vector3(0.6, 0.0, 1.2)
var warga_ditemui: Array = []
var pernah_adegan_barista: bool = false
var _player_rig: Dictionary = {}
var _player_node: Node3D = null
var _player_phase: float = 0.0
var _player_colliders: Array = []
var _s1_trees: Array[Node3D] = []
var _world_bound: float = 6.0
var _warung_pos: Vector3 = Vector3(3.2, 0.0, -0.4)
var _has_warung: bool = false
var _joystick: S1SimpleJoystick = null
var _tap_down_pos: Vector2 = Vector2.ZERO
var _tap_active: bool = false
var villager_modal: PanelContainer = null
var lbl_vm_title: Label = null
var lbl_vm_info: Label = null
var _barista_scene_active: bool = false
var _barista_skipped: bool = false
var _barista_overlay: Control = null

class S1SimpleJoystick extends Control:
	var joy_vec: Vector2 = Vector2.ZERO
	var _touch_idx: int = -1
	var _center: Vector2 = Vector2(55.0, 55.0)
	var _radius: float = 46.0

	func _init() -> void:
		custom_minimum_size = Vector2(110.0, 110.0)
		size = Vector2(110.0, 110.0)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			var st: InputEventScreenTouch = event as InputEventScreenTouch
			if st.pressed and _touch_idx == -1:
				_touch_idx = st.index
				_update_knob(st.position)
				accept_event()
			elif not st.pressed and st.index == _touch_idx:
				_touch_idx = -1
				joy_vec = Vector2.ZERO
				queue_redraw()
				accept_event()
		elif event is InputEventScreenDrag:
			var sd: InputEventScreenDrag = event as InputEventScreenDrag
			if sd.index == _touch_idx:
				_update_knob(sd.position)
				accept_event()
		elif event is InputEventMouseButton:
			var mb: InputEventMouseButton = event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if mb.pressed:
					_touch_idx = 0
					_update_knob(mb.position)
				else:
					_touch_idx = -1
					joy_vec = Vector2.ZERO
					queue_redraw()
				accept_event()
		elif event is InputEventMouseMotion and _touch_idx == 0:
			var mm: InputEventMouseMotion = event as InputEventMouseMotion
			_update_knob(mm.position)
			accept_event()

	func _update_knob(pos: Vector2) -> void:
		var delta_v: Vector2 = pos - _center
		if delta_v.length() > _radius:
			delta_v = delta_v.normalized() * _radius
		joy_vec = delta_v / _radius
		queue_redraw()

	func _draw() -> void:
		draw_circle(_center, _radius, Color(0.10, 0.12, 0.18, 0.65))
		draw_arc(_center, _radius, 0.0, TAU, 24, Color(0.95, 0.80, 0.28, 0.80), 2.0)
		draw_circle(_center + joy_vec * (_radius * 0.65), 18.0, Color(0.96, 0.82, 0.30, 0.90))

func _ready() -> void:
	_build_ui()
	if SaveManager.s1_load_on_start:
		SaveManager.s1_load_on_start = false
		if _load_s1():
			setup_modal.visible = false
			hud_root.visible = true
			lbl_event.text = "Selamat datang kembali, %s!" % nama
			_refresh_hud()
	_rebuild_world()
	_update_camera(Vector2.ZERO)
	weather_helper = WeatherCycleHelper.new()
	add_child(weather_helper)
	var w_env := find_child("WorldEnvironment", true, false) as WorldEnvironment
	var d_light := find_child("DirectionalLight3D", true, false) as DirectionalLight3D
	weather_helper.setup(w_env, d_light, s1_waktu_jam, s1_cuaca)
	s1_ambient = AmbientLifeHelper.new()
	add_child(s1_ambient)
	s1_ambient.setup(false)

func _process(delta: float) -> void:
	if s1_photo_paused:
		return
	if s1_ambient:
		s1_ambient.tick(delta, {}, {})
	if weather_helper and hud_root and hud_root.visible:
		weather_helper.tick(delta, 1.0, Vector3.ZERO)
		s1_waktu_jam = weather_helper.waktu_jam
		s1_cuaca = weather_helper.cuaca_saat_ini
		_s1_weather_accum += delta
		if _s1_weather_accum >= 0.5:
			_s1_weather_accum = 0.0
			if lbl_s1_clock:
				lbl_s1_clock.text = "%02d:00" % int(s1_waktu_jam)
			if s1_weather_icon:
				var ic := "sun" if s1_cuaca == "cerah" else ("cloud" if s1_cuaca == "berawan" else "rain")
				if s1_weather_icon.icon_type != ic:
					s1_weather_icon.icon_type = ic
					s1_weather_icon.queue_redraw()
	var move := Vector2.ZERO
	if not _barista_scene_active and hud_root and hud_root.visible:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			move.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			move.x += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			move.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			move.y += 1.0
		if _joystick and _joystick.joy_vec.length() > 0.1:
			move += _joystick.joy_vec
	if move != Vector2.ZERO and _player_node and is_instance_valid(_player_node):
		_move_player(move.normalized(), delta)
		_cam_target = _cam_target.lerp(Vector3(_player_node.position.x, 0.0, _player_node.position.z), clampf(delta * 5.0, 0.0, 1.0))
		_update_camera(Vector2.ZERO)
	elif not _barista_scene_active and _player_node and is_instance_valid(_player_node):
		_cam_target = _cam_target.lerp(Vector3(_player_node.position.x, 0.0, _player_node.position.z), clampf(delta * 3.5, 0.0, 1.0))
		_update_camera(Vector2.ZERO)

	# Animasi jalan sederhana untuk warga kampung + bubble chat jarak dekat
	for v in _villagers:
		var rig: Dictionary = v["rig"]
		var root: Node3D = rig["root"]
		if not is_instance_valid(root):
			continue
		var spd: float = float(v["speed"])
		var dir: float = float(v["dir"])
		root.position.x += dir * spd * delta
		if root.position.x > float(v["end_x"]):
			v["dir"] = -1.0
			v["target_rot"] = -PI * 0.5
		elif root.position.x < float(v["start_x"]):
			v["dir"] = 1.0
			v["target_rot"] = PI * 0.5
		var t_rot: float = float(v.get("target_rot", PI * 0.5 if dir > 0.0 else -PI * 0.5))
		root.rotation.y = lerp_angle(root.rotation.y, t_rot, clampf(delta * 6.0, 0.0, 1.0))

		v["phase"] = float(v["phase"]) + delta * spd * 6.5
		var ph: float = float(v["phase"])
		var swing: float = sin(ph) * 0.45
		(rig["pivot"] as Node3D).position.y = abs(sin(ph)) * 0.05
		(rig["leg_l"] as MeshInstance3D).rotation.x = swing
		(rig["leg_r"] as MeshInstance3D).rotation.x = -swing
		(rig["arm_l"] as MeshInstance3D).rotation.x = -swing * 0.8
		(rig["arm_r"] as MeshInstance3D).rotation.x = swing * 0.8

		# Cek jarak ke pemain untuk bubble chat & catat warga ditemui
		v["cooldown"] = maxf(0.0, float(v.get("cooldown", 0.0)) - delta)
		var b_lbl: Label3D = v.get("bubble", null)
		if _player_node and is_instance_valid(_player_node) and b_lbl and is_instance_valid(b_lbl):
			var dist: float = _player_node.position.distance_to(root.position)
			if b_lbl.visible:
				v["bubble_timer"] = float(v.get("bubble_timer", 0.0)) - delta
				if float(v["bubble_timer"]) <= 0.0 or dist > 3.8:
					b_lbl.visible = false
			elif dist < 2.0 and float(v["cooldown"]) <= 0.0 and not _barista_scene_active:
				var quotes: Array = v.get("quotes", [])
				var q: String = str(quotes[randi() % quotes.size()]) if not quotes.is_empty() else "Halo!"
				b_lbl.text = "%s: %s" % [str(v.get("name", "Warga")), q]
				b_lbl.visible = true
				v["bubble_timer"] = 4.0
				v["cooldown"] = 12.0
				var vname: String = str(v.get("name", ""))
				if not vname.is_empty() and not (vname in warga_ditemui):
					warga_ditemui.append(vname)
					_refresh_hud()

	# Kedip pelan jika Kesehatan kritis (< 20) & timer toast & goyang pohon lembut
	_blink_time += delta
	for ti in range(_s1_trees.size()):
		var tr_n: Node3D = _s1_trees[ti]
		if is_instance_valid(tr_n):
			tr_n.rotation.z = sin(_blink_time * 1.1 + float(ti) * 1.3) * 0.022
	if lbl_val_sehat and is_instance_valid(lbl_val_sehat):
		if kesehatan < 20:
			lbl_val_sehat.modulate = Color(1.0, 0.3, 0.3, 0.55 + 0.45 * abs(sin(_blink_time * 4.0)))
		else:
			lbl_val_sehat.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if s1_toast_timer > 0.0:
		s1_toast_timer -= delta
		if s1_toast_timer <= 0.0 and s1_toast_label:
			s1_toast_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _barista_scene_active:
			_barista_skipped = true
			get_viewport().set_input_as_handled()
			return
		if villager_modal and villager_modal.visible:
			villager_modal.visible = false
			get_viewport().set_input_as_handled()
			return
		if settings_modal and settings_modal.visible:
			settings_modal.visible = false
			if pause_modal:
				pause_modal.visible = true
		elif pause_modal and hud_root and hud_root.visible:
			pause_modal.visible = not pause_modal.visible
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_tap_active = true
				_tap_down_pos = mb.position
				_cam_dragging = true
			else:
				_cam_dragging = false
				if _tap_active and mb.position.distance_to(_tap_down_pos) < 8.0:
					_try_click_villager(mb.position)
				_tap_active = false
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_cam_dragging = mb.pressed
	elif event is InputEventMouseMotion and _cam_dragging and not _barista_scene_active:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		_update_camera(Vector2(-mm.relative.x * 0.025, -mm.relative.y * 0.025))

func _update_camera(offset: Vector2) -> void:
	var bound: float = 4.5
	var dist_mul: float = 1.0
	match jabatan:
		"Warga":
			bound = 4.5
			dist_mul = 1.0
		"Ketua RT 03":
			bound = 9.0
			dist_mul = 1.45
		"Ketua RW 01":
			bound = 15.0
			dist_mul = 2.0
		"Lurah":
			bound = 24.0
			dist_mul = 2.8
		"Camat":
			bound = 30.0
			dist_mul = 3.4
	_cam_target.x = clampf(_cam_target.x + offset.x, -bound, bound)
	_cam_target.z = clampf(_cam_target.z + offset.y, -bound, bound)
	if cam:
		cam.position = _cam_target + Vector3(5.5, 4.8, 6.5) * dist_mul
		cam.look_at(_cam_target, Vector3.UP)

## Bangun dunia kecil sesuai jabatan (Warga = 1, RT = 10, RW = 30, Lurah = 100, Camat = 3 Kelurahan)
func _rebuild_world() -> void:
	_villagers.clear()
	_player_colliders.clear()
	_s1_trees.clear()
	for child in world_root.get_children():
		world_root.remove_child(child)
		child.queue_free()

	var ground_size: float = 14.0
	match jabatan:
		"Ketua RT 03": ground_size = 26.0
		"Ketua RW 01": ground_size = 40.0
		"Lurah": ground_size = 64.0
		"Camat": ground_size = 80.0
	_world_bound = ground_size * 0.5 - 0.8

	var ground := MeshInstance3D.new()
	var g_mesh := BoxMesh.new()
	g_mesh.size = Vector3(ground_size, 0.2, ground_size)
	var g_mat := StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.26, 0.48, 0.24)
	g_mat.roughness = 0.92
	ground.mesh = g_mesh
	ground.material_override = g_mat
	ground.position = Vector3(0.0, -0.1, 0.0)
	world_root.add_child(ground)

	# Jalan utama kampung + tepi jalan lebih jelas
	var road_w: float = 2.2 if jabatan == "Warga" else 2.8
	var curb := MeshInstance3D.new()
	var c_mesh := BoxMesh.new()
	c_mesh.size = Vector3(ground_size, 0.03, road_w + 0.45)
	var c_mat := StandardMaterial3D.new()
	c_mat.albedo_color = Color(0.48, 0.46, 0.42)
	curb.mesh = c_mesh
	curb.material_override = c_mat
	curb.position = Vector3(0.0, 0.015, 2.4)
	world_root.add_child(curb)

	var road := MeshInstance3D.new()
	var r_mesh := BoxMesh.new()
	r_mesh.size = Vector3(ground_size, 0.05, road_w)
	var r_mat := StandardMaterial3D.new()
	r_mat.albedo_color = Color(0.48, 0.39, 0.28) if jabatan == "Warga" else Color(0.32, 0.33, 0.36)
	road.mesh = r_mesh
	road.material_override = r_mat
	road.position = Vector3(0.0, 0.025, 2.4)
	world_root.add_child(road)

	if jabatan == "Warga":
		var h := S1VisualBuilder.create_house(0, true)
		h.position = Vector3(-1.4, 0.0, -0.6)
		world_root.add_child(h)
		_player_colliders.append({"pos": Vector2(-1.4, -0.6), "radius": 1.35})
	elif jabatan == "Ketua RT 03":
		_spawn_rt_cluster(Vector3(0.0, 0.0, 0.0), "RT 03", 10, true)
		_spawn_pos_ronda(Vector3(7.5, 0.0, 0.2))
		_spawn_signboard(Vector3(-7.0, 0.0, 0.8), "Papan RT 03")
	elif jabatan == "Ketua RW 01":
		_spawn_rt_cluster(Vector3(0.0, 0.0, 0.0), "RT 03", 10, true)
		_spawn_rt_cluster(Vector3(-11.5, 0.0, -9.5), "RT 01", 10, false)
		_spawn_rt_cluster(Vector3(11.5, 0.0, -9.5), "RT 02", 10, false)
		_spawn_pos_ronda(Vector3(7.5, 0.0, 0.2))
		_spawn_balai_rw(Vector3(0.0, 0.0, -9.0))
	elif jabatan == "Lurah":
		_spawn_rt_cluster(Vector3(0.0, 0.0, 12.0), "RW 03", 34, true)
		_spawn_rt_cluster(Vector3(-18.0, 0.0, -14.0), "RW 01", 33, false)
		_spawn_rt_cluster(Vector3(18.0, 0.0, -14.0), "RW 02", 33, false)
		_spawn_civic_building(Vector3(0.0, 0.0, -2.0), "Kantor Kelurahan", Color(0.18, 0.42, 0.72), Vector3(4.2, 2.3, 3.2))
		_spawn_civic_building(Vector3(-7.5, 0.0, -2.0), "Posyandu", Color(0.85, 0.28, 0.32), Vector3(2.4, 1.5, 2.0))
		_spawn_lapangan(Vector3(8.5, 0.0, -2.0))
	else:
		_spawn_rt_cluster(Vector3(0.0, 0.0, 16.0), "Kelurahan A", 30, true)
		_spawn_rt_cluster(Vector3(-22.0, 0.0, -16.0), "Kelurahan B", 30, false)
		_spawn_rt_cluster(Vector3(22.0, 0.0, -16.0), "Kelurahan C", 30, false)
		_spawn_civic_building(Vector3(0.0, 0.0, -2.0), "Kantor Kecamatan", Color(0.78, 0.62, 0.16), Vector3(5.0, 2.8, 3.8))
		_spawn_civic_building(Vector3(-9.5, 0.0, -2.0), "Puskesmas", Color(0.20, 0.65, 0.42), Vector3(3.2, 1.9, 2.6))

	# Lingkungan kampung: pohon variatif, lampu jalan, 1 warung kecil, tempat sampah
	var tree_spots := [Vector3(-4.8, 0.0, -3.5), Vector3(4.2, 0.0, -3.5), Vector3(-5.2, 0.0, 4.8), Vector3(5.4, 0.0, 4.8)]
	if jabatan != "Warga":
		tree_spots.append_array([Vector3(-9.5, 0.0, 4.5), Vector3(9.5, 0.0, 4.5), Vector3(-10.5, 0.0, -3.5), Vector3(10.5, 0.0, -3.5)])
	for ti in range(tree_spots.size()):
		var tr_node: Node3D = S1VisualBuilder.create_tree(ti)
		tr_node.position = tree_spots[ti]
		world_root.add_child(tr_node)
		_s1_trees.append(tr_node)
		_player_colliders.append({"pos": Vector2(tree_spots[ti].x, tree_spots[ti].z), "radius": 0.65})

	for lx in [-4.5, 0.5, 5.5]:
		var lmp := S1VisualBuilder.create_street_lamp()
		lmp.position = Vector3(lx, 0.0, 1.0)
		world_root.add_child(lmp)

	var warung := S1VisualBuilder.create_warung()
	_warung_pos = Vector3(3.2, 0.0, -0.4)
	_has_warung = true
	warung.position = _warung_pos
	world_root.add_child(warung)
	_player_colliders.append({"pos": Vector2(_warung_pos.x, _warung_pos.z), "radius": 1.1})

	var bin := S1VisualBuilder.create_trash_bin()
	bin.position = Vector3(1.8, 0.0, 1.0)
	world_root.add_child(bin)

	# Karakter pemain + 6 warga bernama dengan model & sifat berbeda
	_spawn_player_character(posisi_pemain)
	var walk_span: float = 5.2 if jabatan == "Warga" else 10.0
	var villager_defs: Array = [
		{"name": "Mbak Sari", "gender": "F", "age": 27, "job": "Penjual Sayur", "trait": "Ramah", "history": "Pernah membantu warga saat banjir kecil di RT.", "shirt": Color(0.88, 0.35, 0.45), "head": Color(0.92, 0.72, 0.80), "h": 0.96, "quotes": ["Pagi! Sayurnya segar-segar nih.", "Semoga jalan kampung segera diaspal rata."]},
		{"name": "Pak Budi", "gender": "M", "age": 42, "job": "Sopir Ojek", "trait": "Rajin", "history": "Pernah keseleo ringan saat menghindar lubang jalan.", "shirt": Color(0.22, 0.58, 0.38), "head": Color(0.24, 0.30, 0.38), "h": 1.04, "quotes": ["Pak, jalannya rusak nih di tikungan.", "Hari ini orderan lumayan ramai!"]},
		{"name": "Mas Dimas", "gender": "M", "age": 24, "job": "Karyawan Toko", "trait": "Suka ngobrol", "history": "Sering ikut kerja bakti membersihkan selokan.", "shirt": Color(0.26, 0.52, 0.85), "head": Color(0.78, 0.32, 0.22), "h": 1.00, "quotes": ["duh ini macet banget sih di simpang depan.", "Enak nih sore-sore jalan kaki di kampung."]},
		{"name": "Bu Rina", "gender": "F", "age": 36, "job": "Penjahit", "trait": "Teliti", "history": "Pernah menjahit seragam panitia 17-an kampung.", "shirt": Color(0.65, 0.42, 0.80), "head": Color(0.22, 0.16, 0.12), "h": 0.94, "quotes": ["Harga bahan pokok agak naik bulan ini.", "Lingkungan bersih bikin kerja jadi tenang."]},
		{"name": "Pak Agus", "gender": "M", "age": 48, "job": "Montir Bengkel", "trait": "Sabar", "history": "Selalu siap membantu menambal ban tetangga.", "shirt": Color(0.85, 0.62, 0.22), "head": Color(0.32, 0.36, 0.42), "h": 1.07, "quotes": ["Tong sampah di ujung gang perlu ditambah.", "Jangan lupa cek kesehatan tiap bulan ya."]},
		{"name": "Mbak Dewi", "gender": "F", "age": 29, "job": "Perawat Klinik", "trait": "Peduli", "history": "Aktif mengedukasi warga soal kebersihan air.", "shirt": Color(0.20, 0.70, 0.68), "head": Color(0.85, 0.88, 0.94), "h": 0.98, "quotes": ["Jangan buang sampah ke selokan ya.", "Semangat kerjanya hari ini!"]}
	]
	for vi in range(villager_defs.size()):
		var vd: Dictionary = villager_defs[vi]
		var rig: Dictionary = S1VisualBuilder.create_citizen_rig(vi + 1, false, str(vd["gender"]), float(vd["h"]), vd["shirt"], vd["head"])
		var rnode: Node3D = rig["root"]
		var start_x: float = -walk_span + float(vi) * 1.8
		var dir_v: float = 1.0 if (vi % 2 == 0) else -1.0
		rnode.position = Vector3(start_x, 0.0, 1.8 + float(vi % 3) * 0.55)
		rnode.rotation.y = PI * 0.5 if dir_v > 0.0 else -PI * 0.5
		world_root.add_child(rnode)

		var b_lbl: Label3D = Label3D.new()
		b_lbl.visible = false
		b_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		b_lbl.font_size = 20
		b_lbl.outline_size = 4
		b_lbl.outline_modulate = Color(0.06, 0.08, 0.12)
		b_lbl.position = Vector3(0.0, 1.75, 0.0)
		b_lbl.no_depth_test = true
		rnode.add_child(b_lbl)

		_villagers.append({
			"rig": rig,
			"bubble": b_lbl,
			"bubble_timer": 0.0,
			"cooldown": 0.0,
			"name": vd["name"],
			"gender": vd["gender"],
			"age": vd["age"],
			"job": vd["job"],
			"trait": vd["trait"],
			"history": vd["history"],
			"quotes": vd["quotes"],
			"start_x": -walk_span,
			"end_x": walk_span,
			"dir": dir_v,
			"speed": 0.95 + float(vi % 3) * 0.18,
			"phase": float(vi) * 1.4
		})

func _spawn_rt_cluster(origin: Vector3, label_txt: String, count: int = 10, has_player_house: bool = false) -> void:
	var cols: int = 5 if count <= 10 else 7
	for i in range(count):
		var col: int = i % cols
		var row: int = i / cols
		var pos := origin + Vector3((col - cols * 0.5) * 2.9, 0.0, (row - 1) * 2.8)
		var is_p: bool = (has_player_house and i == 0)
		var h := S1VisualBuilder.create_house(i % 4, is_p)
		h.position = pos
		world_root.add_child(h)
	_spawn_signboard(origin + Vector3(-cols * 1.45 - 1.5, 0.0, 0.0), label_txt)

func _spawn_civic_building(pos: Vector3, title_txt: String, roof_color: Color, size_vec: Vector3) -> void:
	var node := Node3D.new()
	node.position = pos
	var body := MeshInstance3D.new()
	var b_mesh := BoxMesh.new()
	b_mesh.size = size_vec
	var b_mat := StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.94, 0.93, 0.88)
	body.mesh = b_mesh
	body.material_override = b_mat
	body.position = Vector3(0.0, size_vec.y * 0.5, 0.0)
	node.add_child(body)

	var roof := MeshInstance3D.new()
	var r_mesh := PrismMesh.new()
	r_mesh.size = Vector3(size_vec.x + 0.4, 1.1, size_vec.z + 0.4)
	var r_mat := StandardMaterial3D.new()
	r_mat.albedo_color = roof_color
	roof.mesh = r_mesh
	roof.material_override = r_mat
	roof.position = Vector3(0.0, size_vec.y + 0.55, 0.0)
	node.add_child(roof)

	var lbl := Label3D.new()
	lbl.text = title_txt
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 28
	lbl.modulate = Color(1.0, 0.88, 0.3)
	lbl.position = Vector3(0.0, size_vec.y + 1.6, 0.0)
	node.add_child(lbl)
	world_root.add_child(node)

func _spawn_lapangan(pos: Vector3) -> void:
	var field := MeshInstance3D.new()
	var f_mesh := BoxMesh.new()
	f_mesh.size = Vector3(6.0, 0.05, 4.2)
	var f_mat := StandardMaterial3D.new()
	f_mat.albedo_color = Color(0.22, 0.70, 0.28)
	field.mesh = f_mesh
	field.material_override = f_mat
	field.position = pos + Vector3(0.0, 0.025, 0.0)
	world_root.add_child(field)

	var lbl := Label3D.new()
	lbl.text = "Lapangan Desa"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 24
	lbl.position = pos + Vector3(0.0, 1.4, 0.0)
	world_root.add_child(lbl)

	for bx in [-2.0, 2.0]:
		var bench := S1VisualBuilder.create_bench()
		bench.position = pos + Vector3(bx, 0.0, 2.4)
		world_root.add_child(bench)

func _spawn_house(pos: Vector3, roof_color: Color) -> void:
	var house := Node3D.new()
	house.position = pos

	var wall := MeshInstance3D.new()
	var w_mesh := BoxMesh.new()
	w_mesh.size = Vector3(2.2, 1.4, 2.0)
	var w_mat := StandardMaterial3D.new()
	w_mat.albedo_color = Color(0.95, 0.90, 0.80)
	wall.mesh = w_mesh
	wall.material_override = w_mat
	wall.position = Vector3(0.0, 0.7, 0.0)
	house.add_child(wall)

	var roof := MeshInstance3D.new()
	var rf_mesh := PrismMesh.new()
	rf_mesh.size = Vector3(2.5, 0.9, 2.3)
	var rf_mat := StandardMaterial3D.new()
	rf_mat.albedo_color = roof_color
	roof.mesh = rf_mesh
	roof.material_override = rf_mat
	roof.position = Vector3(0.0, 1.85, 0.0)
	house.add_child(roof)

	var door := MeshInstance3D.new()
	var d_mesh := BoxMesh.new()
	d_mesh.size = Vector3(0.45, 0.88, 0.08)
	var d_mat := StandardMaterial3D.new()
	d_mat.albedo_color = Color(0.42, 0.25, 0.14)
	door.mesh = d_mesh
	door.material_override = d_mat
	door.position = Vector3(0.0, 0.44, 1.02)
	house.add_child(door)

	world_root.add_child(house)

func _spawn_pos_ronda(pos: Vector3) -> void:
	var pos_node := Node3D.new()
	pos_node.position = pos
	var base := MeshInstance3D.new()
	var b_mesh := BoxMesh.new()
	b_mesh.size = Vector3(1.6, 1.2, 1.6)
	var b_mat := StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.55, 0.38, 0.20)
	base.mesh = b_mesh
	base.material_override = b_mat
	base.position = Vector3(0.0, 0.6, 0.0)
	pos_node.add_child(base)

	var lbl := Label3D.new()
	lbl.text = "Pos Ronda"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 24
	lbl.position = Vector3(0.0, 1.7, 0.0)
	pos_node.add_child(lbl)
	world_root.add_child(pos_node)

func _spawn_balai_rw(pos: Vector3) -> void:
	_spawn_civic_building(pos, "Balai RW 01", Color(0.20, 0.45, 0.78), Vector3(3.6, 2.0, 2.8))

func _spawn_signboard(pos: Vector3, text: String) -> void:
	var sign_node := Node3D.new()
	sign_node.position = pos
	var post := MeshInstance3D.new()
	var p_mesh := BoxMesh.new()
	p_mesh.size = Vector3(0.14, 1.2, 0.14)
	post.mesh = p_mesh
	post.position = Vector3(0.0, 0.6, 0.0)
	sign_node.add_child(post)

	var lbl := Label3D.new()
	lbl.text = text
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 24
	lbl.modulate = Color(1.0, 0.9, 0.4)
	lbl.position = Vector3(0.0, 1.5, 0.0)
	sign_node.add_child(lbl)
	world_root.add_child(sign_node)

func _spawn_player_character(pos: Vector3) -> void:
	_player_rig = S1VisualBuilder.create_citizen_rig(0, true)
	_player_node = _player_rig["root"]
	_player_node.position = pos
	posisi_pemain = pos
	world_root.add_child(_player_node)

func _is_pos_blocked(p2: Vector2) -> bool:
	if absf(p2.x) > _world_bound or absf(p2.y) > _world_bound:
		return true
	for col in _player_colliders:
		var cpos: Vector2 = col["pos"]
		var crad: float = float(col["radius"])
		if p2.distance_to(cpos) < crad:
			return true
	return false

func _move_player(dir2: Vector2, delta: float) -> void:
	var spd: float = 3.2
	var cur: Vector3 = _player_node.position
	var step: Vector2 = dir2 * spd * delta
	var try_x: Vector2 = Vector2(cur.x + step.x, cur.z)
	if not _is_pos_blocked(try_x):
		cur.x = try_x.x
	var try_z: Vector2 = Vector2(cur.x, cur.z + step.y)
	if not _is_pos_blocked(try_z):
		cur.z = try_z.y
	_player_node.position = cur
	posisi_pemain = cur
	_player_node.rotation.y = atan2(dir2.x, dir2.y)

	_player_phase += delta * spd * 4.5
	var swing: float = sin(_player_phase) * 0.45
	(_player_rig["pivot"] as Node3D).position.y = abs(sin(_player_phase)) * 0.05
	(_player_rig["leg_l"] as MeshInstance3D).rotation.x = swing
	(_player_rig["leg_r"] as MeshInstance3D).rotation.x = -swing
	(_player_rig["arm_l"] as MeshInstance3D).rotation.x = -swing * 0.8
	(_player_rig["arm_r"] as MeshInstance3D).rotation.x = swing * 0.8

func _try_click_villager(screen_pos: Vector2) -> void:
	if not cam or _barista_scene_active:
		return
	var ro: Vector3 = cam.project_ray_origin(screen_pos)
	var rd: Vector3 = cam.project_ray_normal(screen_pos)
	if absf(rd.y) < 0.0001:
		return
	var t: float = -ro.y / rd.y
	if t <= 0.0:
		return
	var hit: Vector3 = ro + rd * t
	for v in _villagers:
		var rig: Dictionary = v["rig"]
		var rnode: Node3D = rig["root"]
		if rnode and is_instance_valid(rnode) and rnode.position.distance_to(hit) <= 1.2:
			_open_villager_modal(v)
			return

func _open_villager_modal(v: Dictionary) -> void:
	if not villager_modal:
		return
	var vname: String = str(v.get("name", "Warga"))
	if not (vname in warga_ditemui):
		warga_ditemui.append(vname)
		_refresh_hud()
	lbl_vm_title.text = vname
	lbl_vm_info.text = "Umur: %d tahun\nPekerjaan: %s\nSifat: %s\nRiwayat: %s" % [
		int(v.get("age", 30)),
		str(v.get("job", "-")),
		str(v.get("trait", "-")),
		str(v.get("history", "-"))
	]
	villager_modal.visible = true

func _make_stylebox(bg: Color, radius: int = 10, pad_h: float = 12.0, pad_v: float = 10.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.30, 0.38, 0.52, 0.9)
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_right = radius
	sb.corner_radius_bottom_left = radius
	sb.content_margin_left = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_right = pad_h
	sb.content_margin_bottom = pad_v
	return sb

func _build_ui() -> void:
	# 1. Layar "Buat Warga"
	setup_modal = PanelContainer.new()
	setup_modal.set_anchors_preset(Control.PRESET_CENTER)
	setup_modal.offset_left = -190.0
	setup_modal.offset_top = -150.0
	setup_modal.offset_right = 190.0
	setup_modal.offset_bottom = 150.0
	setup_modal.add_theme_stylebox_override("panel", _make_stylebox(Color(0.08, 0.10, 0.16, 0.95), 14, 22.0, 20.0))
	ui_layer.add_child(setup_modal)

	var svbox := VBoxContainer.new()
	svbox.add_theme_constant_override("separation", 12)
	setup_modal.add_child(svbox)

	var stitle := Label.new()
	stitle.text = "Buat Warga Baru (Season 1)"
	stitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stitle.add_theme_font_size_override("font_size", 20)
	stitle.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	svbox.add_child(stitle)

	var lbl_name_in := Label.new()
	lbl_name_in.text = "Nama Warga:"
	svbox.add_child(lbl_name_in)

	var name_input := LineEdit.new()
	name_input.text = JobsData.NAME_POOL[randi() % JobsData.NAME_POOL.size()]
	name_input.placeholder_text = "Masukkan nama..."
	svbox.add_child(name_input)

	var lbl_age_in := Label.new()
	lbl_age_in.text = "Umur Awal: 20 tahun"
	svbox.add_child(lbl_age_in)

	var age_slider := HSlider.new()
	age_slider.min_value = 18.0
	age_slider.max_value = 25.0
	age_slider.step = 1.0
	age_slider.value = 20.0
	age_slider.value_changed.connect(func(v: float): lbl_age_in.text = "Umur Awal: %d tahun" % int(v))
	svbox.add_child(age_slider)

	var btn_start := Button.new()
	btn_start.text = "Mulai Hidup"
	btn_start.custom_minimum_size = Vector2(0, 40)
	btn_start.pressed.connect(func():
		var clean_name := name_input.text.strip_edges()
		if clean_name.is_empty():
			clean_name = JobsData.NAME_POOL[randi() % JobsData.NAME_POOL.size()]
		nama = clean_name
		umur = int(age_slider.value)
		pekerjaan = ""
		uang = 500000
		kesehatan = 80
		kebahagiaan = 70
		popularitas = 5
		integritas = 80
		bulan = 1
		riwayat_pekerjaan = []
		jabatan = "Warga"
		bulan_jadi_rt = 0
		bulan_jadi_rw = 0
		bulan_jadi_lurah = 0
		bulan_jadi_camat = 0
		kas_rt = 0
		kas_rw = 0
		anggaran_kelurahan = 0
		anggaran_kecamatan = 0
		season1_selesai = false
		kas_rt_ever_minus = false
		pemilu_cooldown_until = 0
		ronda_months = 0
		clean_months = 0
		active_complaints = []
		setup_modal.visible = false
		hud_root.visible = true
		_rebuild_world()
		_update_camera(Vector2.ZERO)
		_refresh_hud()
		_save_s1()
	)
	svbox.add_child(btn_start)

	# 2. HUD Season 1
	hud_root = Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.visible = false
	ui_layer.add_child(hud_root)

	# Top Bar 5 Stat + Anggaran
	var top_bar := PanelContainer.new()
	top_bar.anchor_right = 1.0
	top_bar.offset_left = 8.0
	top_bar.offset_top = 10.0
	top_bar.offset_right = -8.0
	top_bar.offset_bottom = 54.0
	top_bar.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(false, 12, 6.0, 4.0, 0.90))
	hud_root.add_child(top_bar)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 3)
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_child(top_hbox)

	var chip_style: StyleBoxFlat = UIThemeHelper.make_chip_style()
	chip_style.content_margin_left = 6.0
	chip_style.content_margin_right = 6.0
	chip_style.content_margin_top = 3.0
	chip_style.content_margin_bottom = 3.0

	lbl_val_uang = _add_stat_chip(top_hbox, chip_style, "money", Color(1.0, 0.88, 0.32))
	var kas_chip := PanelContainer.new()
	kas_chip.add_theme_stylebox_override("panel", chip_style)
	var kas_h := HBoxContainer.new()
	kas_h.add_theme_constant_override("separation", 5)
	kas_chip.add_child(kas_h)
	kas_icon_node = S1VisualBuilder.StatIcon.new("kas")
	kas_h.add_child(kas_icon_node)
	lbl_val_kas = Label.new()
	lbl_val_kas.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_val_kas.add_theme_font_size_override("font_size", 13)
	lbl_val_kas.add_theme_color_override("font_color", Color(0.98, 0.78, 0.32))
	kas_h.add_child(lbl_val_kas)
	kas_chip.name = "KasChip"
	top_hbox.add_child(kas_chip)

	lbl_val_sehat = _add_stat_chip(top_hbox, chip_style, "health", Color(0.95, 0.96, 0.98))
	lbl_val_senang = _add_stat_chip(top_hbox, chip_style, "happy", Color(0.95, 0.96, 0.98))
	lbl_val_pop = _add_stat_chip(top_hbox, chip_style, "pop", Color(0.95, 0.96, 0.98))
	lbl_val_integ = _add_stat_chip(top_hbox, chip_style, "integ", Color(0.95, 0.96, 0.98))

	var w_chip := PanelContainer.new()
	w_chip.add_theme_stylebox_override("panel", chip_style)
	var wh := HBoxContainer.new()
	wh.add_theme_constant_override("separation", 4)
	w_chip.add_child(wh)
	s1_weather_icon = S1VisualBuilder.StatIcon.new("sun")
	wh.add_child(s1_weather_icon)
	lbl_s1_clock = Label.new()
	lbl_s1_clock.text = "12:00"
	lbl_s1_clock.add_theme_font_size_override("font_size", 13)
	wh.add_child(lbl_s1_clock)
	top_hbox.add_child(w_chip)

	var btn_s1_cam := Button.new()
	var s1_cm: String = str(SaveManager.load_settings().get("camera_mode", "theotown"))
	btn_s1_cam.text = "Kam: Bebas" if s1_cm == "bebas" else "Kam: Theo"
	btn_s1_cam.custom_minimum_size = Vector2(76, 30)
	UIThemeHelper.apply_btn_secondary(btn_s1_cam, 30.0)
	btn_s1_cam.add_theme_font_size_override("font_size", 11)
	btn_s1_cam.pressed.connect(func():
		var s := SaveManager.load_settings()
		var next_m := "bebas" if str(s.get("camera_mode", "theotown")) == "theotown" else "theotown"
		s["camera_mode"] = next_m
		SaveManager.save_settings(s)
		btn_s1_cam.text = "Kam: Bebas" if next_m == "bebas" else "Kam: Theo"
	)
	top_hbox.add_child(btn_s1_cam)

	var btn_s1_photo := Button.new()
	btn_s1_photo.text = "Foto"
	btn_s1_photo.custom_minimum_size = Vector2(54, 32)
	UIThemeHelper.apply_btn_secondary(btn_s1_photo, 32.0)
	btn_s1_photo.add_theme_font_size_override("font_size", 12)
	btn_s1_photo.pressed.connect(func():
		if s1_photo_helper:
			s1_photo_helper.enter_photo_mode()
	)
	top_hbox.add_child(btn_s1_photo)

	s1_photo_helper = PhotoModeHelper.new()
	s1_photo_helper.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_layer.add_child(s1_photo_helper)
	s1_photo_helper.setup([hud_root], func() -> Dictionary:
		return {
			"tier": jabatan,
			"pop": 1,
			"date": "Bulan %d" % bulan
		}
	)
	s1_photo_helper.photo_mode_toggled.connect(func(is_on: bool):
		s1_photo_paused = is_on
		if get_tree():
			get_tree().paused = is_on
	)

	# Virtual Joystick di kiri bawah untuk layar sentuh HP
	_joystick = S1SimpleJoystick.new()
	_joystick.anchor_left = 0.0
	_joystick.anchor_top = 1.0
	_joystick.anchor_right = 0.0
	_joystick.anchor_bottom = 1.0
	_joystick.offset_left = 18.0
	_joystick.offset_top = -128.0
	_joystick.offset_right = 128.0
	_joystick.offset_bottom = -18.0
	hud_root.add_child(_joystick)

	# Modal Profil Warga Kampung
	villager_modal = PanelContainer.new()
	villager_modal.visible = false
	villager_modal.set_anchors_preset(Control.PRESET_CENTER)
	villager_modal.offset_left = -180.0
	villager_modal.offset_top = -110.0
	villager_modal.offset_right = 180.0
	villager_modal.offset_bottom = 110.0
	villager_modal.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(true, 16, 18.0, 14.0, 0.96))
	ui_layer.add_child(villager_modal)
	var vmvb: VBoxContainer = VBoxContainer.new()
	vmvb.add_theme_constant_override("separation", 8)
	villager_modal.add_child(vmvb)
	lbl_vm_title = Label.new()
	lbl_vm_title.add_theme_font_size_override("font_size", 18)
	lbl_vm_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.28))
	vmvb.add_child(lbl_vm_title)
	lbl_vm_info = Label.new()
	lbl_vm_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_vm_info.add_theme_font_size_override("font_size", 13)
	vmvb.add_child(lbl_vm_info)
	var btn_vm_close: Button = Button.new()
	btn_vm_close.text = "Tutup"
	UIThemeHelper.apply_btn_secondary(btn_vm_close, 36.0)
	btn_vm_close.pressed.connect(func(): villager_modal.visible = false)
	vmvb.add_child(btn_vm_close)

	# Overlay Adegan Kerja Barista (5-10 detik + tombol Lewati)
	_barista_overlay = Control.new()
	_barista_overlay.visible = false
	_barista_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_barista_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(_barista_overlay)
	var bar_panel: PanelContainer = PanelContainer.new()
	bar_panel.anchor_left = 0.5
	bar_panel.anchor_top = 1.0
	bar_panel.anchor_right = 0.5
	bar_panel.anchor_bottom = 1.0
	bar_panel.offset_left = -260.0
	bar_panel.offset_top = -78.0
	bar_panel.offset_right = 260.0
	bar_panel.offset_bottom = -16.0
	bar_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(true, 14, 14.0, 10.0, 0.94))
	_barista_overlay.add_child(bar_panel)
	var bar_hb: HBoxContainer = HBoxContainer.new()
	bar_hb.add_theme_constant_override("separation", 12)
	bar_panel.add_child(bar_hb)
	var bar_lbl: Label = Label.new()
	bar_lbl.text = "Menyeduh kopi untuk pelanggan..."
	bar_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_lbl.add_theme_font_size_override("font_size", 14)
	bar_hb.add_child(bar_lbl)
	var btn_skip: Button = Button.new()
	btn_skip.text = "Lewati (Esc)"
	btn_skip.custom_minimum_size = Vector2(115, 38)
	UIThemeHelper.apply_btn_secondary(btn_skip, 38.0)
	btn_skip.pressed.connect(func(): _barista_skipped = true)
	bar_hb.add_child(btn_skip)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer)

	var btn_menu := Button.new()
	btn_menu.text = "Menu"
	btn_menu.custom_minimum_size = Vector2(76, 32)
	UIThemeHelper.apply_btn_secondary(btn_menu, 32.0)
	btn_menu.add_theme_font_size_override("font_size", 12)
	btn_menu.pressed.connect(func():
		if pause_modal:
			pause_modal.visible = not pause_modal.visible
	)
	top_hbox.add_child(btn_menu)

	# Toast feedback singkat di atas layar
	s1_toast_label = Label.new()
	s1_toast_label.visible = false
	s1_toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	s1_toast_label.offset_left = -220.0
	s1_toast_label.offset_top = 64.0
	s1_toast_label.offset_right = 220.0
	s1_toast_label.offset_bottom = 102.0
	s1_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s1_toast_label.add_theme_font_size_override("font_size", 14)
	hud_root.add_child(s1_toast_label)

	# Panel Profil, Pemilu & Kejadian (Kiri)
	var left_panel := PanelContainer.new()
	left_panel.offset_left = 12.0
	left_panel.offset_top = 66.0
	left_panel.offset_right = 330.0
	left_panel.offset_bottom = 570.0
	left_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(true, 14, 14.0, 12.0, 0.90))
	hud_root.add_child(left_panel)

	var lvbox := VBoxContainer.new()
	lvbox.add_theme_constant_override("separation", 8)
	left_panel.add_child(lvbox)

	var prof_hdr := UIThemeHelper.make_panel_header("Profil Warga", "pop")
	lvbox.add_child(prof_hdr)
	lvbox.add_child(HSeparator.new())

	lbl_profile = Label.new()
	lbl_profile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_profile.add_theme_font_size_override("font_size", 12)
	lvbox.add_child(lbl_profile)

	btn_election = Button.new()
	btn_election.add_theme_font_size_override("font_size", 13)
	UIThemeHelper.apply_btn_primary(btn_election, 48.0)
	btn_election.pressed.connect(_on_election_pressed)
	lvbox.add_child(btn_election)

	lbl_election_hint = Label.new()
	lbl_election_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_election_hint.add_theme_font_size_override("font_size", 11)
	lbl_election_hint.add_theme_color_override("font_color", Color(0.68, 0.73, 0.80))
	lvbox.add_child(lbl_election_hint)

	lvbox.add_child(HSeparator.new())

	lbl_event = Label.new()
	lbl_event.text = "Pilih pekerjaan di panel 'Cari Kerja', lalu klik 'Jalani 1 Bulan'."
	lbl_event.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_event.add_theme_font_size_override("font_size", 12)
	lbl_event.add_theme_color_override("font_color", Color(0.90, 0.94, 0.98))
	lbl_event.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lvbox.add_child(lbl_event)

	var btn_next_month := Button.new()
	btn_next_month.text = "+ Jalani 1 Bulan"
	btn_next_month.add_theme_font_size_override("font_size", 15)
	UIThemeHelper.apply_btn_primary(btn_next_month, 48.0)
	btn_next_month.pressed.connect(_on_next_month_pressed)
	lvbox.add_child(btn_next_month)

	# Panel Pemerintahan (RT / RW / Lurah / Camat)
	gov_panel = PanelContainer.new()
	gov_panel.visible = false
	gov_panel.offset_left = 342.0
	gov_panel.offset_top = 340.0
	gov_panel.offset_right = 918.0
	gov_panel.offset_bottom = 708.0
	gov_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(true, 14, 14.0, 12.0, 0.92))
	hud_root.add_child(gov_panel)

	var gvbox := VBoxContainer.new()
	gvbox.add_theme_constant_override("separation", 6)
	gov_panel.add_child(gvbox)

	lbl_gov_title = Label.new()
	lbl_gov_title.add_theme_font_size_override("font_size", 16)
	lbl_gov_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.28))
	gvbox.add_child(lbl_gov_title)
	gvbox.add_child(HSeparator.new())

	lbl_gov_info = Label.new()
	lbl_gov_info.add_theme_font_size_override("font_size", 12)
	lbl_gov_info.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	gvbox.add_child(lbl_gov_info)

	var gscroll := ScrollContainer.new()
	gscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gvbox.add_child(gscroll)

	var gcontent := VBoxContainer.new()
	gcontent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gcontent.add_theme_constant_override("separation", 6)
	gscroll.add_child(gcontent)

	gov_actions_vbox = VBoxContainer.new()
	gov_actions_vbox.add_theme_constant_override("separation", 4)
	gcontent.add_child(gov_actions_vbox)

	gcontent.add_child(HSeparator.new())

	gov_complaints_vbox = VBoxContainer.new()
	gov_complaints_vbox.add_theme_constant_override("separation", 4)
	gcontent.add_child(gov_complaints_vbox)

	# Panel Cari Kerja (Kanan)
	var job_panel := PanelContainer.new()
	job_panel.anchor_left = 1.0
	job_panel.anchor_right = 1.0
	job_panel.anchor_bottom = 1.0
	job_panel.offset_left = -350.0
	job_panel.offset_top = 62.0
	job_panel.offset_right = -12.0
	job_panel.offset_bottom = -12.0
	job_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(false, 14, 14.0, 12.0, 0.90))
	hud_root.add_child(job_panel)

	var jvbox := VBoxContainer.new()
	jvbox.add_theme_constant_override("separation", 8)
	job_panel.add_child(jvbox)

	lbl_job_panel_title = Label.new()
	lbl_job_panel_title.text = "Cari Kerja (Bebas, Tanpa Syarat)"
	lbl_job_panel_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_job_panel_title.add_theme_font_size_override("font_size", 16)
	lbl_job_panel_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.28))
	jvbox.add_child(lbl_job_panel_title)
	jvbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	jvbox.add_child(scroll)

	jobs_vbox = VBoxContainer.new()
	jobs_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	jobs_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(jobs_vbox)

	for job in JobsData.JOBS:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _make_stylebox(Color(0.14, 0.17, 0.24, 0.9), 6, 8.0, 6.0))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		card.add_child(row)

		var info_lbl := Label.new()
		info_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_lbl.add_theme_font_size_override("font_size", 12)
		info_lbl.text = "%s\nGaji: Rp %s/bln | %s" % [
			job["title"],
			_format_number(job["salary"]),
			job["effects_text"]
		]
		row.add_child(info_lbl)

		var btn_pick := Button.new()
		btn_pick.text = "Pilih"
		btn_pick.custom_minimum_size = Vector2(104, 44)
		UIThemeHelper.apply_btn_secondary(btn_pick, 44.0)
		var j_title: String = job["title"]
		btn_pick.pressed.connect(func(): _select_job(j_title))
		row.add_child(btn_pick)

		_job_buttons.append({ "title": j_title, "button": btn_pick })
		jobs_vbox.add_child(card)

	# Modal "Season 1 Selesai!" (S1-3)
	s1_done_modal = PanelContainer.new()
	s1_done_modal.visible = false
	s1_done_modal.set_anchors_preset(Control.PRESET_CENTER)
	s1_done_modal.offset_left = -220.0
	s1_done_modal.offset_top = -150.0
	s1_done_modal.offset_right = 220.0
	s1_done_modal.offset_bottom = 150.0
	s1_done_modal.add_theme_stylebox_override("panel", _make_stylebox(Color(0.08, 0.12, 0.18, 0.96), 14, 22.0, 20.0))
	ui_layer.add_child(s1_done_modal)

	var dvbox := VBoxContainer.new()
	dvbox.add_theme_constant_override("separation", 12)
	s1_done_modal.add_child(dvbox)

	var dtitle := Label.new()
	dtitle.text = "Season 1 Selesai!"
	dtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dtitle.add_theme_font_size_override("font_size", 22)
	dtitle.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	dvbox.add_child(dtitle)

	lbl_s1_done_summary = Label.new()
	lbl_s1_done_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_s1_done_summary.add_theme_font_size_override("font_size", 13)
	dvbox.add_child(lbl_s1_done_summary)

	var btn_s2 := Button.new()
	btn_s2.text = "Lanjut ke Season 2"
	btn_s2.custom_minimum_size = Vector2(0, 38)
	btn_s2.pressed.connect(func():
		season1_selesai = true
		_save_s1()
		SaveManager.s2_carryover_from_s1 = true
		SaveManager.load_on_start = false
		s1_done_modal.visible = false
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	dvbox.add_child(btn_s2)

	var btn_stay := Button.new()
	btn_stay.text = "Tutup"
	btn_stay.pressed.connect(func(): s1_done_modal.visible = false)
	dvbox.add_child(btn_stay)

	_build_pause_and_settings_s1()

func _select_job(job_title: String) -> void:
	if jabatan in ["Lurah", "Camat"]:
		_show_s1_toast("Jabatan saat ini tidak bisa mengambil kerja sampingan!", true)
		return
	if pekerjaan == job_title:
		return
	pekerjaan = job_title
	if riwayat_pekerjaan.is_empty() or riwayat_pekerjaan[-1] != job_title:
		riwayat_pekerjaan.append(job_title)
	lbl_event.text = "Kamu mulai bekerja sebagai %s." % job_title
	_show_s1_toast("Pekerjaan: %s" % job_title, false)
	_refresh_hud()
	_save_s1()

func _on_election_pressed() -> void:
	if bulan < pemilu_cooldown_until:
		return

	if jabatan == "Warga":
		if bulan < 12 or popularitas < 50:
			return
		var win_chance: float = clampf(0.35 + (float(popularitas) - 50.0) * 0.012, 0.35, 0.92)
		var won: bool = randf() < win_chance
		var player_votes: int = randi_range(26, 38) if won else randi_range(14, 24)
		var opp_votes: int = 50 - player_votes
		if won:
			jabatan = "Ketua RT 03"
			bulan_jadi_rt = bulan
			kas_rt = 0
			active_complaints.clear()
			lbl_event.text = "PEMILU RT: Menang! %d suara vs %d suara. Kamu resmi jadi Ketua RT 03!" % [player_votes, opp_votes]
			_rebuild_world()
			_update_camera(Vector2.ZERO)
		else:
			pemilu_cooldown_until = bulan + 6
			lbl_event.text = "PEMILU RT: Kalah (%d suara vs %d suara). Coba lagi 6 bulan kemudian." % [player_votes, opp_votes]
	elif jabatan == "Ketua RT 03":
		if (bulan - bulan_jadi_rt) < 12 or popularitas < 65 or kas_rt_ever_minus:
			return
		var win_chance_rw: float = clampf(0.28 + (float(popularitas) - 65.0) * 0.015, 0.28, 0.88)
		var won_rw: bool = randf() < win_chance_rw
		var p_votes: int = randi_range(52, 74) if won_rw else randi_range(28, 48)
		var o_votes: int = 100 - p_votes
		if won_rw:
			jabatan = "Ketua RW 01"
			bulan_jadi_rw = bulan
			kas_rw = 0
			lbl_event.text = "PEMILU RW: Menang! %d suara vs %d suara. Kamu resmi jadi Ketua RW 01!" % [p_votes, o_votes]
			_rebuild_world()
			_update_camera(Vector2.ZERO)
		else:
			pemilu_cooldown_until = bulan + 6
			lbl_event.text = "PEMILU RW: Kalah (%d suara vs %d suara). Tetap jadi RT, coba lagi 6 bulan lagi." % [p_votes, o_votes]
	elif jabatan == "Ketua RW 01":
		if (bulan - bulan_jadi_rw) < 12 or popularitas < 75 or integritas < 60:
			return
		var win_chance_l: float = clampf(0.25 + (float(popularitas) - 75.0) * 0.018, 0.25, 0.85)
		var won_l: bool = randf() < win_chance_l
		var l_votes: int = randi_range(1080, 1450) if won_l else randi_range(650, 1020)
		var lo_votes: int = 2100 - l_votes
		if won_l:
			jabatan = "Lurah"
			bulan_jadi_lurah = bulan
			kas_rt = 0
			kas_rw = 0
			anggaran_kelurahan = 0
			active_complaints.clear()
			lbl_event.text = "PEMILIHAN LURAH: Menang! %s suara vs %s suara. Kamu resmi jadi Lurah!" % [_format_number(l_votes), _format_number(lo_votes)]
			_rebuild_world()
			_update_camera(Vector2.ZERO)
		else:
			pemilu_cooldown_until = bulan + 6
			lbl_event.text = "PEMILIHAN LURAH: Kalah (%s suara vs %s suara). Tetap jadi Ketua RW, coba lagi 6 bulan lagi." % [_format_number(l_votes), _format_number(lo_votes)]
	elif jabatan == "Lurah":
		if (bulan - bulan_jadi_lurah) < 12 or popularitas < 85 or integritas < 70:
			return
		var win_chance_c: float = clampf(0.22 + (float(popularitas) - 85.0) * 0.025, 0.22, 0.82)
		var won_c: bool = randf() < win_chance_c
		var c_votes: int = randi_range(2600, 3400) if won_c else randi_range(1500, 2400)
		var co_votes: int = 5000 - c_votes
		if won_c:
			jabatan = "Camat"
			bulan_jadi_camat = bulan
			anggaran_kecamatan = 0
			active_complaints.clear()
			lbl_event.text = "PEMILIHAN CAMAT: Menang! %s suara vs %s suara. Kamu resmi jadi Camat!" % [_format_number(c_votes), _format_number(co_votes)]
			_rebuild_world()
			_update_camera(Vector2.ZERO)
		else:
			pemilu_cooldown_until = bulan + 6
			lbl_event.text = "PEMILIHAN CAMAT: Kalah (%s suara vs %s suara). Tetap jadi Lurah, coba lagi 6 bulan lagi." % [_format_number(c_votes), _format_number(co_votes)]

	_refresh_hud()
	_save_s1()

func _on_next_month_pressed() -> void:
	if _barista_scene_active:
		return
	if pekerjaan == "Barista" and not (jabatan in ["Lurah", "Camat"]) and _has_warung and world_root:
		await _play_barista_scene()
	_execute_monthly_step()

func _play_barista_scene() -> void:
	_barista_scene_active = true
	_barista_skipped = false
	var saved_pos: Vector3 = _player_node.position if (_player_node and is_instance_valid(_player_node)) else posisi_pemain
	var saved_cam_target: Vector3 = _cam_target
	if hud_root:
		hud_root.visible = false
	if _barista_overlay:
		_barista_overlay.visible = true

	if _player_node and is_instance_valid(_player_node):
		_player_node.position = _warung_pos + Vector3(0.0, 0.0, -0.75)
		_player_node.rotation.y = 0.0

	var cust_rig: Dictionary = S1VisualBuilder.create_citizen_rig(2, false, "F", 0.98)
	var cust_node: Node3D = cust_rig["root"]
	cust_node.position = _warung_pos + Vector3(0.0, 0.0, 0.95)
	cust_node.rotation.y = PI
	world_root.add_child(cust_node)

	var cup: MeshInstance3D = MeshInstance3D.new()
	var cup_box: BoxMesh = BoxMesh.new()
	cup_box.size = Vector3(0.14, 0.16, 0.14)
	var cup_mat: StandardMaterial3D = StandardMaterial3D.new()
	cup_mat.albedo_color = Color(0.95, 0.95, 0.96)
	cup.mesh = cup_box
	cup.material_override = cup_mat
	cup.position = _warung_pos + Vector3(0.0, 0.85, 0.25)
	world_root.add_child(cup)

	var steam: MeshInstance3D = MeshInstance3D.new()
	var st_box: BoxMesh = BoxMesh.new()
	st_box.size = Vector3(0.08, 0.12, 0.08)
	var st_mat: StandardMaterial3D = StandardMaterial3D.new()
	st_mat.albedo_color = Color(0.96, 0.96, 0.98, 0.70)
	st_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	steam.mesh = st_box
	steam.material_override = st_mat
	steam.position = cup.position + Vector3(0.0, 0.20, 0.0)
	world_root.add_child(steam)

	var elapsed: float = 0.0
	while elapsed < 6.0 and not _barista_skipped:
		if not get_tree():
			break
		await get_tree().process_frame
		var dt: float = get_process_delta_time()
		elapsed += dt
		_cam_target = _cam_target.lerp(_warung_pos, clampf(dt * 3.5, 0.0, 1.0))
		if cam:
			cam.position = _cam_target + Vector3(3.2, 2.8, 3.8)
			cam.look_at(_cam_target + Vector3(0.0, 0.7, 0.0), Vector3.UP)
		if is_instance_valid(steam):
			steam.position.y = cup.position.y + 0.18 + fmod(elapsed * 0.45, 0.45)

	if is_instance_valid(cust_node):
		cust_node.queue_free()
	if is_instance_valid(cup):
		cup.queue_free()
	if is_instance_valid(steam):
		steam.queue_free()
	if _player_node and is_instance_valid(_player_node):
		_player_node.position = saved_pos
	_cam_target = saved_cam_target
	_update_camera(Vector2.ZERO)
	if _barista_overlay:
		_barista_overlay.visible = false
	if hud_root:
		hud_root.visible = true
	pernah_adegan_barista = true
	_barista_scene_active = false

func _execute_monthly_step() -> void:
	var salary: int = 0
	var log_lines: Array[String] = []

	if jabatan == "Lurah":
		salary = S1GovernanceData.LURAH_SALARY
		log_lines.append("Gaji Lurah: +Rp %s" % _format_number(salary))
	elif jabatan == "Camat":
		salary = S1GovernanceData.CAMAT_SALARY
		log_lines.append("Gaji Camat: +Rp %s" % _format_number(salary))
	else:
		var job: Dictionary = JobsData.get_job_by_title(pekerjaan)
		if not job.is_empty():
			if job.get("variable_salary", false):
				salary = randi_range(int(job.get("salary_min", 2000000)), int(job.get("salary_max", 4500000)))
			else:
				salary = int(job["salary"])
			kesehatan = clampi(kesehatan + int(job.get("kesehatan", 0)), 0, 100)
			kebahagiaan = clampi(kebahagiaan + int(job.get("kebahagiaan", 0)), 0, 100)
			popularitas = clampi(popularitas + int(job.get("popularitas", 0)), 0, 100)
			integritas = clampi(integritas + int(job.get("integritas", 0)), 0, 100)
			log_lines.append("Gaji (%s): +Rp %s" % [pekerjaan, _format_number(salary)])
		else:
			log_lines.append("Belum bekerja bulan ini (Gaji: Rp 0).")

	uang = maxi(0, uang + salary - LIVING_COST)
	log_lines.append("Biaya hidup: -Rp %s" % _format_number(LIVING_COST))

	if jabatan == "Ketua RT 03":
		kesehatan = clampi(kesehatan - 1, 0, 100)
		kas_rt += S1GovernanceData.RT_DUES_MONTHLY
		log_lines.append("Kas RT 03: +Rp %s (iuran 10 rumah). Kesehatan -1 (tugas RT)." % _format_number(S1GovernanceData.RT_DUES_MONTHLY))
		_process_monthly_complaints(log_lines, 1)
	elif jabatan == "Ketua RW 01":
		kesehatan = clampi(kesehatan - 1, 0, 100)
		kas_rw += S1GovernanceData.RW_DUES_MONTHLY
		log_lines.append("Kas RW 01: +Rp %s (iuran 30 rumah). Kesehatan -1 (tugas RW)." % _format_number(S1GovernanceData.RW_DUES_MONTHLY))
		_process_monthly_complaints(log_lines, randi_range(1, 2))
	elif jabatan == "Lurah":
		kesehatan = clampi(kesehatan - 1, 0, 100)
		anggaran_kelurahan += S1GovernanceData.LURAH_BUDGET_MONTHLY
		log_lines.append("Anggaran Kelurahan: +Rp %s. Kesehatan -1 (tugas Lurah)." % _format_number(S1GovernanceData.LURAH_BUDGET_MONTHLY))
		_process_monthly_complaints(log_lines, 2)
	elif jabatan == "Camat":
		kesehatan = clampi(kesehatan - 1, 0, 100)
		anggaran_kecamatan += S1GovernanceData.CAMAT_BUDGET_MONTHLY
		log_lines.append("Anggaran Kecamatan: +Rp %s. Kesehatan -1 (tugas Camat)." % _format_number(S1GovernanceData.CAMAT_BUDGET_MONTHLY))
		_process_monthly_complaints(log_lines, randi_range(2, 3))

	if ronda_months > 0:
		ronda_months -= 1
	if clean_months > 0:
		clean_months -= 1

	if integritas < 40:
		popularitas = clampi(popularitas - 10, 0, 100)
		log_lines.append("Integritas rendah (<40): Popularitas -10! Tangani pengaduan/program untuk memulihkan.")

	if kesehatan <= 0:
		kebahagiaan = clampi(kebahagiaan - 10, 0, 100)
		log_lines.append("PERINGATAN: Kamu sakit, istirahat dulu! (Kebahagiaan -10)")

	var ev: Dictionary = JobsData.MONTHLY_EVENTS[randi() % JobsData.MONTHLY_EVENTS.size()]
	kebahagiaan = clampi(kebahagiaan + int(ev.get("kebahagiaan", 0)), 0, 100)
	popularitas = clampi(popularitas + int(ev.get("popularitas", 0)), 0, 100)
	log_lines.append("Kejadian: " + ev["text"])

	bulan += 1
	if (bulan - 1) % 12 == 0:
		umur += 1
		log_lines.append("Selamat ulang tahun! Umurmu sekarang %d tahun." % umur)

	if jabatan == "Camat" and (bulan - bulan_jadi_camat) >= 6 and not season1_selesai:
		season1_selesai = true
		var s2_modal_awal: int = mini(5000000, 500000 + int(float(uang) * 0.10))
		lbl_s1_done_summary.text = "Perjalanan Selesai: Warga -> RT -> RW -> Lurah -> Camat!\nTotal Bulan: %d (Umur %d tahun)\nPopularitas Akhir: %d/100 | Integritas Akhir: %d/100\nModal awal kotamu (Season 2): Rp %s" % [
			bulan, umur, popularitas, integritas, _format_number(s2_modal_awal)
		]
		s1_done_modal.visible = true

	lbl_event.text = "\n".join(log_lines)
	_refresh_hud()
	_save_s1()

func _process_monthly_complaints(log_lines: Array[String], max_new: int) -> void:
	for c in active_complaints:
		c["months_ignored"] = int(c.get("months_ignored", 0)) + 1
		if int(c["months_ignored"]) >= 2 and not bool(c.get("escalated", false)):
			c["escalated"] = true
			if jabatan == "Ketua RT 03":
				log_lines.append("Pengaduan '%s' diabaikan 2 bulan -> naik menjadi pengaduan resmi ke RW!" % c["title"])
			elif jabatan == "Lurah":
				log_lines.append("Pengaduan '%s' diabaikan 2 bulan -> naik menjadi laporan ke Kecamatan!" % c["title"])

	var pool: Array[Dictionary] = S1GovernanceData.LURAH_COMPLAINTS if jabatan in ["Lurah", "Camat"] else S1GovernanceData.RT_COMPLAINTS
	if active_complaints.size() < 5 and randf() < 0.80:
		for _k in range(max_new):
			if active_complaints.size() >= 5:
				break
			var pick: Dictionary = pool[randi() % pool.size()]
			if pick["type"] == "pencurian" and ronda_months > 0 and randf() < 0.75:
				pick = pool[1]
			if pick["type"] == "sampah" and clean_months > 0 and randf() < 0.75:
				pick = pool[2]
			_complaint_seq += 1
			var area_lbl: String = "RT 03"
			if jabatan == "Ketua RW 01" or jabatan == "Lurah":
				area_lbl = ["RT 01", "RT 02", "RT 03"][randi() % 3]
			elif jabatan == "Camat":
				area_lbl = ["Kelurahan A", "Kelurahan B", "Kelurahan C"][randi() % 3]
			var cost_mul: int = 3 if jabatan == "Camat" else 1
			active_complaints.append({
				"id": _complaint_seq,
				"title": pick["title"],
				"cost": int(pick["cost"]) * cost_mul,
				"rt_label": area_lbl,
				"months_ignored": 0,
				"escalated": false
			})

func _get_cur_budget() -> int:
	match jabatan:
		"Ketua RT 03": return kas_rt
		"Ketua RW 01": return kas_rw
		"Lurah": return anggaran_kelurahan
		"Camat": return anggaran_kecamatan
	return 0

func _add_cur_budget(delta_val: int) -> void:
	match jabatan:
		"Ketua RT 03": kas_rt += delta_val
		"Ketua RW 01": kas_rw += delta_val
		"Lurah": anggaran_kelurahan += delta_val
		"Camat": anggaran_kecamatan += delta_val

func _get_budget_label() -> String:
	match jabatan:
		"Ketua RT 03": return "Kas RT"
		"Ketua RW 01": return "Kas RW"
		"Lurah": return "Anggaran Kelurahan"
		"Camat": return "Anggaran Kecamatan"
	return "Kas"

func _do_gov_action(act: Dictionary) -> void:
	var cost: int = int(act["cost"])
	if _get_cur_budget() < cost:
		var err_msg := "%s tidak cukup! (Butuh Rp %s)" % [_get_budget_label(), _format_number(cost)]
		lbl_event.text = err_msg
		_show_s1_toast(err_msg, true)
		return

	_add_cur_budget(-cost)
	kesehatan = clampi(kesehatan + int(act.get("health", 0)), 0, 100)
	kebahagiaan = clampi(kebahagiaan + int(act.get("happy", 0)), 0, 100)
	popularitas = clampi(popularitas + int(act.get("pop", 0)), 0, 100)
	integritas = clampi(integritas + int(act.get("integ", 0)), 0, 100)
	if bool(act.get("ronda", false)):
		ronda_months = 3
	if bool(act.get("clean", false)):
		clean_months = 3

	lbl_event.text = "%s berhasil dilaksanakan! (%s)" % [act["title"], act["desc"]]
	_show_s1_toast("%s selesai!" % act["title"], false)
	_refresh_hud()
	_save_s1()

func _take_personal_kas() -> void:
	var amount: int = 50000
	var integ_loss: int = 15
	var catch_prob: float = 0.20
	var catch_msg: String = "Warga mulai bertanya soal kas... (Integritas -5 tambahan)"
	var pop_loss_caught: int = 0
	var integ_loss_caught: int = 5

	if jabatan == "Lurah":
		amount = 200000
		integ_loss = 20
		catch_prob = 0.25
		catch_msg = "Warga melapor ke kecamatan... (Popularitas -15)"
		pop_loss_caught = 15
		integ_loss_caught = 0
	elif jabatan == "Camat":
		amount = 500000
		integ_loss = 25
		catch_prob = 0.30
		catch_msg = "Laporan warga sampai ke inspektorat! (Popularitas -20, Integritas -10 tambahan)"
		pop_loss_caught = 20
		integ_loss_caught = 10

	if _get_cur_budget() < amount:
		var err_k := "%s tidak cukup untuk diambil (butuh Rp %s)." % [_get_budget_label(), _format_number(amount)]
		lbl_event.text = err_k
		_show_s1_toast(err_k, true)
		return

	_add_cur_budget(-amount)
	uang += amount
	integritas = clampi(integritas - integ_loss, 0, 100)

	var msg: String = "Mengambil Rp %s dari %s ke Uang Pribadi. Integritas -%d." % [_format_number(amount), _get_budget_label(), integ_loss]
	if randf() < catch_prob:
		popularitas = clampi(popularitas - pop_loss_caught, 0, 100)
		integritas = clampi(integritas - integ_loss_caught, 0, 100)
		msg += "\nPERINGATAN: " + catch_msg
		_show_s1_toast(catch_msg, true)
	else:
		_show_s1_toast("+Rp %s (Integritas -%d)" % [_format_number(amount), integ_loss], false)
	lbl_event.text = msg
	_refresh_hud()
	_save_s1()

func _resolve_complaint(comp_id: int, handle: bool) -> void:
	var idx: int = -1
	for i in range(active_complaints.size()):
		if int(active_complaints[i]["id"]) == comp_id:
			idx = i
			break
	if idx == -1:
		return

	var comp: Dictionary = active_complaints[idx]
	if handle:
		var cost: int = int(comp["cost"])
		if _get_cur_budget() < cost:
			var err_c := "%s tidak cukup untuk menangani '%s' (Butuh Rp %s)." % [_get_budget_label(), comp["title"], _format_number(cost)]
			lbl_event.text = err_c
			_show_s1_toast(err_c, true)
			return
		_add_cur_budget(-cost)
		popularitas = clampi(popularitas + 3, 0, 100)
		integritas = clampi(integritas + 2, 0, 100)
		lbl_event.text = "Pengaduan '%s' (%s) ditangani! Popularitas +3, Integritas +2." % [comp["title"], comp["rt_label"]]
		_show_s1_toast("Pengaduan ditangani! (+3 Populer)", false)
	else:
		popularitas = clampi(popularitas - 5, 0, 100)
		kebahagiaan = clampi(kebahagiaan - 3, 0, 100)
		lbl_event.text = "Pengaduan '%s' diabaikan. Popularitas -5, Kebahagiaan -3." % comp["title"]
		_show_s1_toast("Pengaduan diabaikan (-5 Populer)", true)

	active_complaints.remove_at(idx)
	_refresh_hud()
	_save_s1()

func _refresh_hud() -> void:
	lbl_val_uang.text = "Rp %s" % _format_number(uang)
	var kas_chip := lbl_val_kas.get_parent().get_parent() as Control
	if jabatan == "Ketua RT 03":
		kas_chip.visible = true
		lbl_val_kas.text = "Kas RT: Rp %s" % _format_number(kas_rt)
	elif jabatan == "Ketua RW 01":
		kas_chip.visible = true
		lbl_val_kas.text = "Kas RW: Rp %s" % _format_number(kas_rw)
	elif jabatan == "Lurah":
		kas_chip.visible = true
		lbl_val_kas.text = "RW: 0 | Kel: Rp %s" % _format_number(anggaran_kelurahan)
	elif jabatan == "Camat":
		kas_chip.visible = true
		lbl_val_kas.text = "Kec: Rp %s" % _format_number(anggaran_kecamatan)
	else:
		kas_chip.visible = false

	lbl_val_sehat.text = "%d" % kesehatan
	lbl_val_senang.text = "%d" % kebahagiaan
	lbl_val_pop.text = "%d" % popularitas
	lbl_val_pop.modulate = Color(1.0, 0.3, 0.3) if popularitas < 20 else Color(1.0, 1.0, 1.0)
	lbl_val_integ.text = "%d" % integritas

	var cur_job_txt: String = jabatan if jabatan in ["Lurah", "Camat"] else (pekerjaan if not pekerjaan.is_empty() else "Belum bekerja")
	var hist_txt: String = ", ".join(riwayat_pekerjaan) if not riwayat_pekerjaan.is_empty() else "-"
	var met_txt: String = ", ".join(warga_ditemui) if not warga_ditemui.is_empty() else "-"
	lbl_profile.text = "Nama: %s (%d tahun)\nJabatan: %s\nBulan ke-%d | Kerja: %s\nRiwayat: %s\nWarga ditemui: %s" % [
		nama, umur, jabatan, bulan, cur_job_txt, hist_txt, met_txt
	]

	var cd_left: int = maxi(0, pemilu_cooldown_until - bulan)
	if jabatan == "Warga":
		btn_election.visible = true
		btn_election.text = "Calonkan diri jadi Ketua RT"
		if cd_left > 0:
			btn_election.disabled = true
			lbl_election_hint.text = "Cooldown pemilu RT: tunggu %d bulan lagi." % cd_left
		elif bulan >= 12 and popularitas >= 50:
			btn_election.disabled = false
			lbl_election_hint.text = "Syarat terpenuhi! Klik tombol hijau untuk Pemilu RT."
		else:
			btn_election.disabled = true
			lbl_election_hint.text = "Syarat RT: Bulan >= 12 (%d/12) & Pop >= 50 (%d/50)" % [bulan, popularitas]
	elif jabatan == "Ketua RT 03":
		btn_election.visible = true
		btn_election.text = "Calonkan diri jadi Ketua RW"
		var months_rt: int = bulan - bulan_jadi_rt
		if cd_left > 0:
			btn_election.disabled = true
			lbl_election_hint.text = "Cooldown pemilu RW: tunggu %d bulan lagi." % cd_left
		elif months_rt >= 12 and popularitas >= 65 and not kas_rt_ever_minus:
			btn_election.disabled = false
			lbl_election_hint.text = "Syarat terpenuhi! Klik tombol hijau untuk Pemilu RW."
		else:
			btn_election.disabled = true
			lbl_election_hint.text = "Syarat RW: RT >= 12 bln (%d/12), Pop >= 65 (%d/65), Kas aman" % [months_rt, popularitas]
	elif jabatan == "Ketua RW 01":
		btn_election.visible = true
		btn_election.text = "Calonkan diri jadi Lurah"
		var months_rw: int = bulan - bulan_jadi_rw
		if cd_left > 0:
			btn_election.disabled = true
			lbl_election_hint.text = "Cooldown pemilihan Lurah: tunggu %d bulan lagi." % cd_left
		elif months_rw >= 12 and popularitas >= 75 and integritas >= 60:
			btn_election.disabled = false
			lbl_election_hint.text = "Syarat terpenuhi! Klik tombol hijau untuk Pemilihan Lurah."
		else:
			btn_election.disabled = true
			lbl_election_hint.text = "Syarat Lurah: RW >= 12 bln (%d/12), Pop >= 75 (%d/75), Integ >= 60 (%d/60)" % [months_rw, popularitas, integritas]
	elif jabatan == "Lurah":
		btn_election.visible = true
		btn_election.text = "Calonkan diri jadi Camat"
		var months_l: int = bulan - bulan_jadi_lurah
		if cd_left > 0:
			btn_election.disabled = true
			lbl_election_hint.text = "Cooldown pemilihan Camat: tunggu %d bulan lagi." % cd_left
		elif months_l >= 12 and popularitas >= 85 and integritas >= 70:
			btn_election.disabled = false
			lbl_election_hint.text = "Syarat terpenuhi! Klik tombol hijau untuk Pemilihan Camat."
		else:
			btn_election.disabled = true
			lbl_election_hint.text = "Syarat Camat: Lurah >= 12 bln (%d/12), Pop >= 85 (%d/85), Integ >= 70 (%d/70)" % [months_l, popularitas, integritas]
	else:
		btn_election.visible = false
		var months_c: int = bulan - bulan_jadi_camat
		lbl_election_hint.text = "Jabatan Tertinggi Season 1: Camat (%d/6 bulan menuju selesai)" % mini(months_c, 6)

	var lock_jobs: bool = jabatan in ["Lurah", "Camat"]
	lbl_job_panel_title.text = ("Kamu sekarang %s, fokus mengurus wilayah" % jabatan) if lock_jobs else "Cari Kerja (Bebas, Tanpa Syarat)"
	for jb in _job_buttons:
		var btn: Button = jb["button"]
		if lock_jobs:
			btn.text = "Terkunci"
			btn.disabled = true
		elif jb["title"] == pekerjaan:
			btn.text = "Sedang dijalani"
			btn.disabled = true
		else:
			btn.text = "Pilih"
			btn.disabled = false

	_refresh_gov_panel()

func _refresh_gov_panel() -> void:
	if jabatan == "Warga":
		gov_panel.visible = false
		return

	gov_panel.visible = true
	var acts: Array[Dictionary] = S1GovernanceData.RT_ACTIONS
	var take_amt: int = 50000
	var income_monthly: int = S1GovernanceData.RT_DUES_MONTHLY
	match jabatan:
		"Ketua RT 03":
			lbl_gov_title.text = "Panel Ketua RT 03 (10 Rumah)"
			acts = S1GovernanceData.RT_ACTIONS
			income_monthly = S1GovernanceData.RT_DUES_MONTHLY
			take_amt = 50000
		"Ketua RW 01":
			lbl_gov_title.text = "Panel Ketua RW 01 (30 Rumah)"
			acts = S1GovernanceData.RW_ACTIONS
			income_monthly = S1GovernanceData.RW_DUES_MONTHLY
			take_amt = 50000
		"Lurah":
			lbl_gov_title.text = "Panel Lurah / Desa (~100 Rumah, 3 RW)"
			acts = S1GovernanceData.LURAH_ACTIONS
			income_monthly = S1GovernanceData.LURAH_BUDGET_MONTHLY
			take_amt = 200000
		"Camat":
			lbl_gov_title.text = "Panel Camat (3 Kelurahan)"
			acts = S1GovernanceData.CAMAT_ACTIONS
			income_monthly = S1GovernanceData.CAMAT_BUDGET_MONTHLY
			take_amt = 500000

	lbl_gov_info.text = "%s: Rp %s | Dana Masuk: +Rp %s/bln | Kesehatan -1/bln" % [
		_get_budget_label(),
		_format_number(_get_cur_budget()),
		_format_number(income_monthly)
	]

	for child in gov_actions_vbox.get_children():
		child.queue_free()

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 6)
	for act in acts:
		var btn := Button.new()
		btn.text = "%s\n(Rp %s)" % [act["title"], _format_number(act["cost"])]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 11)
		UIThemeHelper.apply_btn_secondary(btn, 44.0)
		var a_copy: Dictionary = act
		btn.pressed.connect(func(): _do_gov_action(a_copy))
		action_row.add_child(btn)

	var btn_ambil := Button.new()
	btn_ambil.text = "Ambil %s\n(Rp %s)" % ["Anggaran" if jabatan in ["Lurah", "Camat"] else "Kas", _format_number(take_amt)]
	btn_ambil.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_ambil.add_theme_font_size_override("font_size", 11)
	UIThemeHelper.apply_btn_danger(btn_ambil, 44.0)
	btn_ambil.pressed.connect(_take_personal_kas)
	action_row.add_child(btn_ambil)
	gov_actions_vbox.add_child(action_row)

	for child in gov_complaints_vbox.get_children():
		child.queue_free()

	var c_header := Label.new()
	c_header.text = "Pengaduan Warga (%d):" % active_complaints.size()
	c_header.add_theme_font_size_override("font_size", 12)
	c_header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	gov_complaints_vbox.add_child(c_header)

	if active_complaints.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Belum ada pengaduan warga saat ini."
		empty_lbl.add_theme_font_size_override("font_size", 11)
		gov_complaints_vbox.add_child(empty_lbl)
	else:
		for comp in active_complaints:
			var crow := HBoxContainer.new()
			crow.add_theme_constant_override("separation", 6)
			var clbl := Label.new()
			clbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			clbl.add_theme_font_size_override("font_size", 11)
			clbl.text = "[%s] %s (Biaya: Rp %s)" % [comp["rt_label"], comp["title"], _format_number(comp["cost"])]
			crow.add_child(clbl)

			var cid: int = int(comp["id"])
			var btn_fix := Button.new()
			btn_fix.text = "Tangani"
			btn_fix.add_theme_font_size_override("font_size", 11)
			UIThemeHelper.apply_btn_primary(btn_fix, 44.0)
			btn_fix.pressed.connect(func(): _resolve_complaint(cid, true))
			crow.add_child(btn_fix)

			var btn_ign := Button.new()
			btn_ign.text = "Abaikan"
			btn_ign.add_theme_font_size_override("font_size", 11)
			UIThemeHelper.apply_btn_danger(btn_ign, 44.0)
			btn_ign.pressed.connect(func(): _resolve_complaint(cid, false))
			crow.add_child(btn_ign)

			gov_complaints_vbox.add_child(crow)

## Simpan otomatis Season 1 ke user://save_season1.cfg (dengan field S1-2 & S1-3)
func _save_s1() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("warga", "nama", nama)
	cfg.set_value("warga", "umur", umur)
	cfg.set_value("warga", "pekerjaan", pekerjaan)
	cfg.set_value("warga", "uang", uang)
	cfg.set_value("warga", "kesehatan", kesehatan)
	cfg.set_value("warga", "kebahagiaan", kebahagiaan)
	cfg.set_value("warga", "popularitas", popularitas)
	cfg.set_value("warga", "integritas", integritas)
	cfg.set_value("warga", "bulan", bulan)
	cfg.set_value("warga", "riwayat_pekerjaan", riwayat_pekerjaan.duplicate())

	# Field S1-2
	cfg.set_value("warga", "jabatan", jabatan)
	cfg.set_value("warga", "bulan_jadi_rt", bulan_jadi_rt)
	cfg.set_value("warga", "bulan_jadi_rw", bulan_jadi_rw)
	cfg.set_value("warga", "kas_rt", kas_rt)
	cfg.set_value("warga", "kas_rw", kas_rw)

	# Field S1-3
	cfg.set_value("warga", "bulan_jadi_lurah", bulan_jadi_lurah)
	cfg.set_value("warga", "bulan_jadi_camat", bulan_jadi_camat)
	cfg.set_value("warga", "anggaran_kelurahan", anggaran_kelurahan)
	cfg.set_value("warga", "anggaran_kecamatan", anggaran_kecamatan)
	cfg.set_value("warga", "season1_selesai", season1_selesai)

	# State tambahan S1-4 agar Continue akurat
	cfg.set_value("warga", "kas_rt_ever_minus", kas_rt_ever_minus)
	cfg.set_value("warga", "pemilu_cooldown_until", pemilu_cooldown_until)
	cfg.set_value("warga", "ronda_months", ronda_months)
	cfg.set_value("warga", "clean_months", clean_months)
	cfg.set_value("warga", "active_complaints", active_complaints.duplicate(true))
	cfg.set_value("warga", "waktu_jam", s1_waktu_jam)
	cfg.set_value("warga", "cuaca_saat_ini", s1_cuaca)
	cfg.set_value("warga", "posisi_pemain", posisi_pemain)
	cfg.set_value("warga", "warga_ditemui", warga_ditemui.duplicate())
	cfg.set_value("warga", "pernah_adegan_barista", pernah_adegan_barista)
	cfg.save(SAVE_S1_PATH)

func _load_s1() -> bool:
	if not FileAccess.file_exists(SAVE_S1_PATH):
		return false
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_S1_PATH) != OK:
		return false

	nama = str(cfg.get_value("warga", "nama", ""))
	if nama.is_empty():
		return false
	umur = int(cfg.get_value("warga", "umur", 20))
	pekerjaan = str(cfg.get_value("warga", "pekerjaan", ""))
	uang = int(cfg.get_value("warga", "uang", 500000))
	kesehatan = int(cfg.get_value("warga", "kesehatan", 80))
	kebahagiaan = int(cfg.get_value("warga", "kebahagiaan", 70))
	popularitas = int(cfg.get_value("warga", "popularitas", 5))
	integritas = int(cfg.get_value("warga", "integritas", 80))
	bulan = int(cfg.get_value("warga", "bulan", 1))
	var hist_val = cfg.get_value("warga", "riwayat_pekerjaan", [])
	riwayat_pekerjaan = hist_val.duplicate() if hist_val is Array else []

	jabatan = str(cfg.get_value("warga", "jabatan", "Warga"))
	bulan_jadi_rt = int(cfg.get_value("warga", "bulan_jadi_rt", 0))
	bulan_jadi_rw = int(cfg.get_value("warga", "bulan_jadi_rw", 0))
	kas_rt = int(cfg.get_value("warga", "kas_rt", 0))
	kas_rw = int(cfg.get_value("warga", "kas_rw", 0))

	bulan_jadi_lurah = int(cfg.get_value("warga", "bulan_jadi_lurah", 0))
	bulan_jadi_camat = int(cfg.get_value("warga", "bulan_jadi_camat", 0))
	anggaran_kelurahan = int(cfg.get_value("warga", "anggaran_kelurahan", 0))
	anggaran_kecamatan = int(cfg.get_value("warga", "anggaran_kecamatan", 0))
	season1_selesai = bool(cfg.get_value("warga", "season1_selesai", false))

	kas_rt_ever_minus = bool(cfg.get_value("warga", "kas_rt_ever_minus", false))
	pemilu_cooldown_until = int(cfg.get_value("warga", "pemilu_cooldown_until", 0))
	ronda_months = int(cfg.get_value("warga", "ronda_months", 0))
	clean_months = int(cfg.get_value("warga", "clean_months", 0))
	var comp_val = cfg.get_value("warga", "active_complaints", [])
	active_complaints = comp_val.duplicate(true) if comp_val is Array else []
	s1_waktu_jam = float(cfg.get_value("warga", "waktu_jam", 12.0))
	s1_cuaca = str(cfg.get_value("warga", "cuaca_saat_ini", "cerah"))
	var pos_val: Variant = cfg.get_value("warga", "posisi_pemain", Vector3(0.6, 0.0, 1.2))
	posisi_pemain = pos_val if pos_val is Vector3 else Vector3(0.6, 0.0, 1.2)
	var wd_val: Variant = cfg.get_value("warga", "warga_ditemui", [])
	warga_ditemui = wd_val.duplicate() if wd_val is Array else []
	pernah_adegan_barista = bool(cfg.get_value("warga", "pernah_adegan_barista", false))
	return true

func _build_pause_and_settings_s1() -> void:
	pause_modal = PanelContainer.new()
	pause_modal.visible = false
	pause_modal.set_anchors_preset(Control.PRESET_CENTER)
	pause_modal.offset_left = -155.0
	pause_modal.offset_top = -145.0
	pause_modal.offset_right = 155.0
	pause_modal.offset_bottom = 145.0
	pause_modal.add_theme_stylebox_override("panel", _make_stylebox(Color(0.08, 0.10, 0.16, 0.96), 12, 20.0, 18.0))
	ui_layer.add_child(pause_modal)

	var pvbox := VBoxContainer.new()
	pvbox.add_theme_constant_override("separation", 10)
	pause_modal.add_child(pvbox)

	var ptitle := Label.new()
	ptitle.text = "Menu Season 1"
	ptitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ptitle.add_theme_font_size_override("font_size", 18)
	ptitle.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	pvbox.add_child(ptitle)

	var btn_resume := Button.new()
	btn_resume.text = "Lanjut"
	btn_resume.custom_minimum_size = Vector2(0, 36)
	btn_resume.pressed.connect(func(): pause_modal.visible = false)
	pvbox.add_child(btn_resume)

	var btn_settings := Button.new()
	btn_settings.text = "Pengaturan"
	btn_settings.custom_minimum_size = Vector2(0, 36)
	btn_settings.pressed.connect(func():
		pause_modal.visible = false
		settings_modal.visible = true
	)
	pvbox.add_child(btn_settings)

	var btn_save := Button.new()
	btn_save.text = "Simpan"
	btn_save.custom_minimum_size = Vector2(0, 36)
	btn_save.pressed.connect(func():
		_save_s1()
		if lbl_event:
			lbl_event.text = "Permainan Season 1 tersimpan ke save_season1.cfg!"
		pause_modal.visible = false
	)
	pvbox.add_child(btn_save)

	var btn_exit := Button.new()
	btn_exit.text = "Keluar ke Menu Utama"
	btn_exit.custom_minimum_size = Vector2(0, 36)
	btn_exit.pressed.connect(func():
		_save_s1()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	pvbox.add_child(btn_exit)

	# Settings Modal (berbagi user://settings.cfg untuk semua season)
	settings_modal = PanelContainer.new()
	settings_modal.visible = false
	settings_modal.set_anchors_preset(Control.PRESET_CENTER)
	settings_modal.offset_left = -180.0
	settings_modal.offset_top = -155.0
	settings_modal.offset_right = 180.0
	settings_modal.offset_bottom = 155.0
	settings_modal.add_theme_stylebox_override("panel", _make_stylebox(Color(0.08, 0.10, 0.16, 0.96), 12, 20.0, 18.0))
	ui_layer.add_child(settings_modal)

	var svbox := VBoxContainer.new()
	svbox.add_theme_constant_override("separation", 10)
	settings_modal.add_child(svbox)

	var stitle := Label.new()
	stitle.text = "Pengaturan"
	stitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stitle.add_theme_font_size_override("font_size", 18)
	stitle.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	svbox.add_child(stitle)

	var cur_s: Dictionary = SaveManager.load_settings()

	var lbl_m := Label.new()
	lbl_m.text = "Volume Utama: %d%%" % int(cur_s["master_volume"])
	svbox.add_child(lbl_m)
	var sl_m := HSlider.new()
	sl_m.value = float(cur_s["master_volume"])
	sl_m.value_changed.connect(func(v: float): lbl_m.text = "Volume Utama: %d%%" % int(v))
	svbox.add_child(sl_m)

	var lbl_mu := Label.new()
	lbl_mu.text = "Volume Musik: %d%%" % int(cur_s["music_volume"])
	svbox.add_child(lbl_mu)
	var sl_mu := HSlider.new()
	sl_mu.value = float(cur_s["music_volume"])
	sl_mu.value_changed.connect(func(v: float): lbl_mu.text = "Volume Musik: %d%%" % int(v))
	svbox.add_child(sl_mu)

	var lbl_sx := Label.new()
	lbl_sx.text = "Volume SFX: %d%%" % int(cur_s["sfx_volume"])
	svbox.add_child(lbl_sx)
	var sl_sx := HSlider.new()
	sl_sx.value = float(cur_s["sfx_volume"])
	sl_sx.value_changed.connect(func(v: float): lbl_sx.text = "Volume SFX: %d%%" % int(v))
	svbox.add_child(sl_sx)

	var chk_mt := CheckButton.new()
	chk_mt.text = "Senyapkan Semua (Mute)"
	chk_mt.button_pressed = bool(cur_s["muted"])
	svbox.add_child(chk_mt)

	var btn_save_set := Button.new()
	btn_save_set.text = "Simpan & Kembali"
	btn_save_set.custom_minimum_size = Vector2(0, 34)
	btn_save_set.pressed.connect(func():
		SaveManager.save_settings({
			"master_volume": sl_m.value,
			"music_volume": sl_mu.value,
			"sfx_volume": sl_sx.value,
			"muted": chk_mt.button_pressed
		})
		settings_modal.visible = false
		pause_modal.visible = true
	)
	svbox.add_child(btn_save_set)

func _format_number(val: int) -> String:
	var s := str(val)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "." + result
	return result

func _add_stat_chip(parent: HBoxContainer, chip_style: StyleBoxFlat, icon_name: String, text_col: Color) -> Label:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", chip_style)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 5)
	chip.add_child(hb)
	hb.add_child(S1VisualBuilder.StatIcon.new(icon_name))
	var lbl := Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", text_col)
	hb.add_child(lbl)
	parent.add_child(chip)
	return lbl

func _show_s1_toast(msg: String, is_error: bool = false) -> void:
	if not s1_toast_label:
		return
	s1_toast_label.add_theme_stylebox_override("normal", UIThemeHelper.make_toast_style(is_error))
	s1_toast_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45) if is_error else Color(0.98, 0.98, 0.98))
	s1_toast_label.text = msg
	s1_toast_label.visible = true
	s1_toast_timer = 2.6
