class_name MainMenu
extends Node3D

## Menu Utama Townverse (Season 2: Mode Walikota) dengan background kota 3D contoh + kamera orbit pelan

@onready var orbit_camera: Camera3D = $OrbitCamera
@onready var showcase_city: Node3D = $ShowcaseCity
@onready var menu_vbox: VBoxContainer = $CanvasLayer/MenuCard/VBox
@onready var btn_new_game: Button = $CanvasLayer/MenuCard/VBox/BtnNewGame
@onready var btn_continue: Button = $CanvasLayer/MenuCard/VBox/BtnContinue
@onready var btn_settings: Button = $CanvasLayer/MenuCard/VBox/BtnSettings
@onready var btn_exit: Button = $CanvasLayer/MenuCard/VBox/BtnExit
@onready var settings_modal: PanelContainer = $CanvasLayer/SettingsModal
@onready var sl_master: HSlider = $CanvasLayer/SettingsModal/VBox/SliderMaster
@onready var sl_music: HSlider = $CanvasLayer/SettingsModal/VBox/SliderMusic
@onready var sl_sfx: HSlider = $CanvasLayer/SettingsModal/VBox/SliderSFX
@onready var lbl_master: Label = $CanvasLayer/SettingsModal/VBox/LabelMaster
@onready var lbl_music: Label = $CanvasLayer/SettingsModal/VBox/LabelMusic
@onready var lbl_sfx: Label = $CanvasLayer/SettingsModal/VBox/LabelSFX
@onready var chk_mute: CheckButton = $CanvasLayer/SettingsModal/VBox/CheckMute
@onready var btn_settings_close: Button = $CanvasLayer/SettingsModal/VBox/BtnSaveSettings

var _orbit_angle: float = 0.6
var mode_container: VBoxContainer = null
var career_container: VBoxContainer = null
var solo_container: VBoxContainer = null
var map_container: VBoxContainer = null
var solo_confirm_modal: PanelContainer = null
var _chosen_map: String = "dataran"
var _map_return_view: String = "career"
var _map_carryover: bool = false
var _map_cards: Dictionary = {}

func _ready() -> void:
	_build_showcase_city()

	btn_new_game.visible = false
	btn_continue.visible = false
	_build_mode_and_season_views()
	_build_solo_confirm_modal()

	UIThemeHelper.apply_btn_secondary(btn_settings, 48.0)
	UIThemeHelper.apply_btn_danger(btn_exit, 48.0)
	btn_settings.pressed.connect(func():
		AudioManager.play_sfx(self, "click")
		_open_settings()
	)
	btn_exit.pressed.connect(func(): get_tree().quit())

	sl_master.value_changed.connect(func(v: float): lbl_master.text = "Volume Utama: %d%%" % int(v))
	sl_music.value_changed.connect(func(v: float): lbl_music.text = "Volume Musik: %d%%" % int(v))
	sl_sfx.value_changed.connect(func(v: float): lbl_sfx.text = "Volume SFX: %d%%" % int(v))
	btn_settings_close.pressed.connect(_save_and_close_settings)

	settings_modal.visible = false
	_update_camera(0.0)

func _build_mode_and_season_views() -> void:
	var insert_idx: int = btn_settings.get_index()

	var view_scroll := ScrollContainer.new()
	view_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_vbox.add_child(view_scroll)
	menu_vbox.move_child(view_scroll, insert_idx)

	var view_root := VBoxContainer.new()
	view_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view_scroll.add_child(view_root)

	# 1. Layar Pilihan Mode (Karier / Barengan / Solo)
	mode_container = VBoxContainer.new()
	mode_container.add_theme_constant_override("separation", 8)
	view_root.add_child(mode_container)

	# Mode Karier (Aktif)
	mode_container.add_child(_make_mode_card(
		"Mode Karier",
		"pop",
		"Satu perjalanan: warga biasa sampai Presiden. Main sendiri.",
		"",
		true,
		"Main Mode Karier",
		func():
			AudioManager.play_sfx(self, "click")
			_show_menu_view("career")
	))

	# Mode Barengan (Terkunci / Segera Hadir — Phase 2)
	mode_container.add_child(_make_mode_card(
		"Mode Barengan",
		"happy",
		"Main bareng di satu negara: karier sendiri-sendiri atau bangun satu kota bareng.\n• Pasangan — kepala + pasangan hidup: urus kebijakan/anggaran vs citra publik/sosial; harmonis = Popularitas naik cepat, konflik = turun; pasangan bisa maju sendiri\n• Kepala + Wakil — satu tiket (Walikota/Gubernur/Presiden + Wakil), wewenang beda; bisa koalisi, rival, atau berebut jabatan\n• Partner Bangun Kota — satu kota dibangun bareng (sandbox tanpa karier/pemilu, kota & sumber daya milik bersama)",
		"Segera Hadir — Multiplayer dibuka setelah Season 1 stabil (Phase 2)",
		false,
		"Segera Hadir",
		func(): pass
	))

	# Mode Solo (Aktif — Sandbox City-Builder)
	mode_container.add_child(_make_mode_card(
		"Mode Solo",
		"money",
		"Bangun kota KotaBareng bebas, tanpa karier dan tanpa pemilu. Sandbox.",
		"",
		true,
		"Main Mode Solo",
		func():
			AudioManager.play_sfx(self, "click")
			_show_menu_view("solo")
	))

	# 2. Layar Mode Karier (Season 1 / Season 2 / Season 3)
	career_container = VBoxContainer.new()
	career_container.visible = false
	career_container.add_theme_constant_override("separation", 8)
	view_root.add_child(career_container)

	# Season 1 — Warga sampai Camat (Life-Sim)
	career_container.add_child(_make_season_card(
		"Season 1 — Warga sampai Camat",
		"Simulasi kehidupan & karier (RT -> RW -> Lurah -> Camat)",
		true,
		SaveManager.has_save_s1(),
		"",
		func():
			AudioManager.play_sfx(self, "click")
			SaveManager.s1_load_on_start = false
			get_tree().change_scene_to_file("res://scenes/season1/s1_warga.tscn"),
		func():
			AudioManager.play_sfx(self, "click")
			SaveManager.s1_load_on_start = true
			get_tree().change_scene_to_file("res://scenes/season1/s1_warga.tscn")
	))

	# Season 2 — Walikota sampai Gubernur (City-Builder, KotaBareng)
	var s1_done: bool = SaveManager.is_season1_completed()
	var has_s2: bool = SaveManager.has_save_s2()
	var can_new_s2: bool = s1_done or has_s2
	var s2_hint: String = "" if can_new_s2 else "Selesaikan Season 1 dulu (jadi Camat)"
	career_container.add_child(_make_season_card(
		"Season 2 — Walikota sampai Gubernur",
		"Bangun kota KotaBareng (City-Builder)",
		can_new_s2,
		has_s2,
		s2_hint,
		func():
			AudioManager.play_sfx(self, "click")
			_open_map_picker("career", s1_done),
		func():
			AudioManager.play_sfx(self, "click")
			SaveManager.load_on_start = true
			SaveManager.s2_carryover_from_s1 = false
			get_tree().change_scene_to_file("res://scenes/main.tscn")
	))

	# Season 3 — Presiden (Terkunci)
	career_container.add_child(_make_season_card(
		"Season 3 — Presiden (Terkunci)",
		"Kepemimpinan nasional",
		false,
		false,
		"Dibuka setelah Season 2 selesai",
		func(): pass,
		func(): pass
	))

	var btn_back_career := Button.new()
	btn_back_career.text = "Kembali"
	UIThemeHelper.apply_btn_secondary(btn_back_career, 48.0)
	btn_back_career.pressed.connect(func():
		AudioManager.play_sfx(self, "click")
		_show_menu_view("mode")
	)
	career_container.add_child(btn_back_career)

	# 3. Layar Mode Solo (Sandbox City-Builder)
	solo_container = VBoxContainer.new()
	solo_container.visible = false
	solo_container.add_theme_constant_override("separation", 10)
	view_root.add_child(solo_container)

	var solo_hint: String = "" if has_s2 else "Belum ada kota"
	var solo_card := _make_season_card(
		"Mode Solo — KotaBareng",
		"Bangun kota bebas tanpa karier & pemilu (Modal awal Rp 500.000, Popularitas 70)",
		true,
		has_s2,
		solo_hint,
		func():
			AudioManager.play_sfx(self, "click")
			if SaveManager.has_save_s2():
				solo_confirm_modal.visible = true
			else:
				_open_map_picker("solo", false),
		func():
			AudioManager.play_sfx(self, "click")
			SaveManager.load_on_start = true
			SaveManager.s2_carryover_from_s1 = false
			get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	solo_container.add_child(solo_card)

	var btn_back_solo := Button.new()
	btn_back_solo.text = "Kembali"
	UIThemeHelper.apply_btn_secondary(btn_back_solo, 48.0)
	btn_back_solo.pressed.connect(func():
		AudioManager.play_sfx(self, "click")
		_show_menu_view("mode")
	)
	solo_container.add_child(btn_back_solo)

	# 4. Layar Pilih Peta / Landscape (5 peta ala Township)
	map_container = VBoxContainer.new()
	map_container.visible = false
	map_container.add_theme_constant_override("separation", 8)
	view_root.add_child(map_container)

	var map_hdr := UIThemeHelper.make_panel_header("Pilih Peta Kota", "date")
	map_container.add_child(map_hdr)
	map_container.add_child(HSeparator.new())

	var maps_def := [
		{ "id": "pantai", "name": "Pantai", "desc": "Kota di tepi laut", "icon": "water" },
		{ "id": "pegunungan", "name": "Pegunungan", "desc": "Kota di kaki bukit", "icon": "warn" },
		{ "id": "sungai", "name": "Sungai", "desc": "Kota dibelah sungai", "icon": "water" },
		{ "id": "dataran", "name": "Dataran Hijau", "desc": "Peta klasik", "icon": "happy" },
		{ "id": "hutan", "name": "Hutan", "desc": "Kota di tengah hutan", "icon": "pop" }
	]
	for md in maps_def:
		var mid: String = md["id"]
		var mcard := _make_map_card(mid, md["name"], md["desc"], md["icon"])
		_map_cards[mid] = mcard
		map_container.add_child(mcard)
	_select_map_card("dataran")

	var btn_start_map := Button.new()
	btn_start_map.text = "Mulai Bangun"
	UIThemeHelper.apply_btn_primary(btn_start_map, 48.0)
	btn_start_map.pressed.connect(func():
		AudioManager.play_sfx(self, "click")
		SaveManager.selected_landscape = _chosen_map
		SaveManager.load_on_start = false
		SaveManager.s2_carryover_from_s1 = _map_carryover
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	map_container.add_child(btn_start_map)

	var btn_back_map := Button.new()
	btn_back_map.text = "Kembali"
	UIThemeHelper.apply_btn_secondary(btn_back_map, 48.0)
	btn_back_map.pressed.connect(func():
		AudioManager.play_sfx(self, "click")
		_show_menu_view(_map_return_view)
	)
	map_container.add_child(btn_back_map)

func _show_menu_view(view_name: String) -> void:
	mode_container.visible = (view_name == "mode")
	career_container.visible = (view_name == "career")
	solo_container.visible = (view_name == "solo")
	if map_container:
		map_container.visible = (view_name == "map")

func _open_map_picker(return_view: String, carryover: bool) -> void:
	_map_return_view = return_view
	_map_carryover = carryover
	_select_map_card("dataran")
	_show_menu_view("map")

func _select_map_card(map_id: String) -> void:
	_chosen_map = map_id
	for k in _map_cards:
		var c: PanelContainer = _map_cards[k]
		c.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(k == map_id, 18, 12.0, 8.0, 0.94))

class MapPreviewBox extends Control:
	var map_id: String = "dataran"
	func _init(p_id: String) -> void:
		map_id = p_id
		custom_minimum_size = Vector2(56, 42)
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 56, 42), Color(0.28, 0.58, 0.25))
		match map_id:
			"pantai":
				draw_rect(Rect2(0, 0, 56, 12), Color(0.14, 0.48, 0.85))
				draw_rect(Rect2(0, 12, 56, 10), Color(0.92, 0.84, 0.56))
			"pegunungan":
				draw_rect(Rect2(0, 0, 56, 16), Color(0.22, 0.46, 0.22))
				for px in [10, 28, 46]:
					draw_colored_polygon(PackedVector2Array([Vector2(px - 10, 18), Vector2(px, 2), Vector2(px + 10, 18)]), Color(0.50, 0.44, 0.38))
			"sungai":
				draw_rect(Rect2(22, 0, 12, 42), Color(0.16, 0.52, 0.88))
				draw_rect(Rect2(20, 12, 16, 5), Color(0.58, 0.40, 0.22))
				draw_rect(Rect2(20, 28, 16, 5), Color(0.58, 0.40, 0.22))
			"hutan":
				draw_rect(Rect2(0, 0, 56, 42), Color(0.20, 0.45, 0.20))
				for pt in [Vector2(10, 10), Vector2(44, 12), Vector2(16, 30), Vector2(38, 32), Vector2(28, 18)]:
					draw_circle(pt, 5.0, Color(0.12, 0.34, 0.14))

func _make_map_card(map_id: String, title_txt: String, desc_txt: String, icon_name: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			AudioManager.play_sfx(self, "click")
			_select_map_card(map_id)
	)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)

	hbox.add_child(MapPreviewBox.new(map_id))

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	hbox.add_child(v)

	v.add_child(UIThemeHelper.make_panel_header(title_txt, icon_name))
	var ld := Label.new()
	ld.text = desc_txt
	ld.add_theme_font_size_override("font_size", 11)
	ld.add_theme_color_override("font_color", Color(0.75, 0.80, 0.86))
	v.add_child(ld)
	return card

func _make_mode_card(title_txt: String, icon_name: String, desc_txt: String, lock_hint: String, is_active: bool, btn_label: String, on_click: Callable) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(is_active, 18, 14.0, 10.0, 0.92 if is_active else 0.65))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	card.add_child(vbox)

	var hdr := UIThemeHelper.make_panel_header(title_txt, icon_name)
	if not is_active:
		(hdr.get_child(1) as Label).add_theme_color_override("font_color", Color(0.60, 0.63, 0.68))
	vbox.add_child(hdr)
	vbox.add_child(HSeparator.new())

	var lbl_d := Label.new()
	lbl_d.text = desc_txt
	lbl_d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_d.add_theme_font_size_override("font_size", 11)
	lbl_d.add_theme_color_override("font_color", Color(0.75, 0.80, 0.86))
	vbox.add_child(lbl_d)

	if not lock_hint.is_empty():
		var lbl_h := Label.new()
		lbl_h.text = lock_hint
		lbl_h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_h.add_theme_font_size_override("font_size", 11)
		lbl_h.add_theme_color_override("font_color", Color(1.0, 0.48, 0.42))
		vbox.add_child(lbl_h)

	var btn := Button.new()
	btn.text = btn_label
	if is_active:
		UIThemeHelper.apply_btn_primary(btn, 48.0)
	else:
		UIThemeHelper.apply_btn_secondary(btn, 48.0)
		btn.disabled = true
	btn.pressed.connect(on_click)
	vbox.add_child(btn)
	return card

func _build_solo_confirm_modal() -> void:
	solo_confirm_modal = PanelContainer.new()
	solo_confirm_modal.visible = false
	solo_confirm_modal.set_anchors_preset(Control.PRESET_CENTER)
	solo_confirm_modal.offset_left = -200.0
	solo_confirm_modal.offset_top = -100.0
	solo_confirm_modal.offset_right = 200.0
	solo_confirm_modal.offset_bottom = 100.0
	solo_confirm_modal.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(true, 18, 20.0, 18.0, 0.96))
	$CanvasLayer.add_child(solo_confirm_modal)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	solo_confirm_modal.add_child(vbox)

	vbox.add_child(UIThemeHelper.make_panel_header("Konfirmasi Kota Baru", "warn"))
	vbox.add_child(HSeparator.new())

	var lbl := Label.new()
	lbl.text = "Mulai kota baru? Save Season 2 yang lama akan diganti."
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(lbl)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)

	var btn_yes := Button.new()
	btn_yes.text = "Ya, Mulai Baru"
	btn_yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIThemeHelper.apply_btn_danger(btn_yes, 48.0)
	btn_yes.pressed.connect(func():
		AudioManager.play_sfx(self, "click")
		solo_confirm_modal.visible = false
		_open_map_picker("solo", false)
	)
	hbox.add_child(btn_yes)

	var btn_no := Button.new()
	btn_no.text = "Batal"
	btn_no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIThemeHelper.apply_btn_secondary(btn_no, 48.0)
	btn_no.pressed.connect(func():
		AudioManager.play_sfx(self, "click")
		solo_confirm_modal.visible = false
	)
	hbox.add_child(btn_no)

func _make_season_card(title_txt: String, desc_txt: String, can_new: bool, can_continue: bool, lock_hint: String, on_new: Callable, on_cont: Callable) -> PanelContainer:
	var card := PanelContainer.new()
	var is_unlocked: bool = can_new or can_continue
	var sb := UIThemeHelper.make_panel_style(is_unlocked, 18, 16.0, 12.0, 0.92 if is_unlocked else 0.65)
	card.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var icon_t: String = "happy" if "Season 1" in title_txt else ("money" if "Season 2" in title_txt else "integ")
	var hdr := UIThemeHelper.make_panel_header(title_txt, icon_t)
	if not is_unlocked:
		(hdr.get_child(1) as Label).add_theme_color_override("font_color", Color(0.60, 0.63, 0.68))
	vbox.add_child(hdr)

	vbox.add_child(HSeparator.new())

	var lbl_d := Label.new()
	lbl_d.text = desc_txt
	lbl_d.add_theme_font_size_override("font_size", 11)
	lbl_d.add_theme_color_override("font_color", Color(0.72, 0.77, 0.84))
	vbox.add_child(lbl_d)

	if not lock_hint.is_empty():
		var lbl_h := Label.new()
		lbl_h.text = lock_hint
		lbl_h.add_theme_font_size_override("font_size", 11)
		lbl_h.add_theme_color_override("font_color", Color(1.0, 0.45, 0.42))
		vbox.add_child(lbl_h)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox)

	var btn_n := Button.new()
	btn_n.text = "Permainan Baru"
	btn_n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIThemeHelper.apply_btn_primary(btn_n, 48.0)
	btn_n.disabled = not can_new
	btn_n.pressed.connect(on_new)
	hbox.add_child(btn_n)

	var btn_c := Button.new()
	btn_c.text = "> Lanjutkan"
	btn_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIThemeHelper.apply_btn_secondary(btn_c, 48.0)
	btn_c.disabled = not can_continue
	btn_c.pressed.connect(on_cont)
	hbox.add_child(btn_c)

	return card

func _process(delta: float) -> void:
	_update_camera(delta)

func _update_camera(delta: float) -> void:
	if not orbit_camera:
		return
	_orbit_angle += delta * 0.14
	var radius: float = 13.5
	var cam_pos := Vector3(cos(_orbit_angle) * radius, 8.2, sin(_orbit_angle) * radius)
	orbit_camera.position = cam_pos
	orbit_camera.look_at(Vector3(0.0, 0.8, 0.0), Vector3.UP)

func _build_showcase_city() -> void:
	if not showcase_city:
		return

	# Mini-kota 5x5 sebagai latar belakang menu utama (tile spacing = 2.0)
	var layout := [
		[Vector2i(0, 0), CityData.TileType.PARK, 0, CityData.BuildingZone.RESIDENTIAL],
		[Vector2i(1, 0), CityData.TileType.ZONE_R, 2, CityData.BuildingZone.RESIDENTIAL],
		[Vector2i(2, 0), CityData.TileType.ROAD, 0, CityData.BuildingZone.RESIDENTIAL],
		[Vector2i(3, 0), CityData.TileType.ZONE_C, 2, CityData.BuildingZone.COMMERCIAL],
		[Vector2i(4, 0), CityData.TileType.FARM, 3, CityData.BuildingZone.RESIDENTIAL],

		[Vector2i(0, 1), CityData.TileType.ZONE_R, 1, CityData.BuildingZone.RESIDENTIAL],
		[Vector2i(1, 1), CityData.TileType.ZONE_R, 3, CityData.BuildingZone.RESIDENTIAL],
		[Vector2i(2, 1), CityData.TileType.ROAD, 0, CityData.BuildingZone.RESIDENTIAL],
		[Vector2i(3, 1), CityData.TileType.TOWNHALL, 0, CityData.BuildingZone.RESIDENTIAL],
		[Vector2i(4, 1), CityData.TileType.PARK, 0, CityData.BuildingZone.RESIDENTIAL],

		[Vector2i(0, 2), CityData.TileType.ROAD, 0, CityData.BuildingZone.RESIDENTIAL],
		[Vector2i(1, 2), CityData.TileType.ROAD, 0, CityData.BuildingZone.RESIDENTIAL],
		[Vector2i(2, 2), CityData.TileType.ROAD, 0, CityData.BuildingZone.RESIDENTIAL],
		[Vector2i(3, 2), CityData.TileType.ROAD, 0, CityData.BuildingZone.RESIDENTIAL],
		[Vector2i(4, 2), CityData.TileType.ROAD, 0, CityData.BuildingZone.RESIDENTIAL],

		[Vector2i(0, 3), CityData.TileType.FARM, 3, CityData.BuildingZone.RESIDENTIAL],
		[Vector2i(1, 3), CityData.TileType.ZONE_C, 3, CityData.BuildingZone.COMMERCIAL],
		[Vector2i(2, 3), CityData.TileType.ROAD, 0, CityData.BuildingZone.RESIDENTIAL],
		[Vector2i(3, 3), CityData.TileType.ZONE_R, 2, CityData.BuildingZone.RESIDENTIAL],
		[Vector2i(4, 3), CityData.TileType.ZONE_I, 2, CityData.BuildingZone.INDUSTRIAL],

		[Vector2i(0, 4), CityData.TileType.PARK, 0, CityData.BuildingZone.RESIDENTIAL],
		[Vector2i(1, 4), CityData.TileType.ZONE_R, 1, CityData.BuildingZone.RESIDENTIAL],
		[Vector2i(2, 4), CityData.TileType.ROAD, 0, CityData.BuildingZone.RESIDENTIAL],
		[Vector2i(3, 4), CityData.TileType.PARK, 0, CityData.BuildingZone.RESIDENTIAL],
		[Vector2i(4, 4), CityData.TileType.POWER_PLANT, 0, CityData.BuildingZone.INDUSTRIAL],
	]

	for item in layout:
		var gp: Vector2i = item[0]
		var node: Node3D = BuildingBuilder.create_tile_node(item[1], item[2], item[3], true)
		node.position = Vector3((gp.x - 2) * 2.0, 0.0, (gp.y - 2) * 2.0)
		showcase_city.add_child(node)

func _open_settings() -> void:
	var s: Dictionary = SaveManager.load_settings()
	sl_master.value = float(s["master_volume"])
	sl_music.value = float(s["music_volume"])
	sl_sfx.value = float(s["sfx_volume"])
	chk_mute.button_pressed = bool(s["muted"])
	lbl_master.text = "Volume Utama: %d%%" % int(sl_master.value)
	lbl_music.text = "Volume Musik: %d%%" % int(sl_music.value)
	lbl_sfx.text = "Volume SFX: %d%%" % int(sl_sfx.value)
	settings_modal.visible = true

func _save_and_close_settings() -> void:
	SaveManager.save_settings({
		"master_volume": sl_master.value,
		"music_volume": sl_music.value,
		"sfx_volume": sl_sfx.value,
		"muted": chk_mute.button_pressed
	})
	AudioManager.play_sfx(self, "click")
	settings_modal.visible = false
