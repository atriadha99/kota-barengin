class_name HUD
extends CanvasLayer

## Mengontrol UI informasi kota, status utilitas detail, kontrol waktu, slider pajak, panel gudang gandum, modal Balai Kota, profil warga, dan dialog Pak Slamet (Langkah 5)

@export var city_manager: CityManager

# Top Panel
@onready var label_money: Label = $TopPanel/HBox/LabelMoney
@onready var label_pop: Label = $TopPanel/HBox/LabelPop
@onready var label_happiness: Label = $TopPanel/HBox/LabelHappiness
@onready var label_popularity: Label = $TopPanel/HBox/LabelPopularity
@onready var label_power: Label = $TopPanel/HBox/LabelPower
@onready var label_water: Label = $TopPanel/HBox/LabelWater
@onready var label_date: Label = $TopPanel/HBox/LabelDate
@onready var label_tier: Label = $TopPanel/HBox/LabelTier
@onready var btn_townhall: Button = $TopPanel/HBox/BtnTownHall

# Right Panel
@onready var bar_r: ProgressBar = $RightPanel/VBoxRCI/BarR
@onready var bar_c: ProgressBar = $RightPanel/VBoxRCI/BarC
@onready var bar_i: ProgressBar = $RightPanel/VBoxRCI/BarI

# Time & Tax Panels
@onready var btn_pause: Button = $TimeSpeedPanel/HBoxSpeed/BtnPause
@onready var btn_1x: Button = $TimeSpeedPanel/HBoxSpeed/Btn1x
@onready var btn_3x: Button = $TimeSpeedPanel/HBoxSpeed/Btn3x
@onready var tax_slider: HSlider = $TaxPanel/VBoxTax/TaxSlider
@onready var label_tax: Label = $TaxPanel/VBoxTax/LabelTax

# Gudang Gandum
@onready var label_wheat: Label = $FarmPanel/VBoxFarm/LabelWheat
@onready var label_price: Label = $FarmPanel/VBoxFarm/LabelPrice
@onready var btn_sell_wheat: Button = $FarmPanel/VBoxFarm/BtnSellWheat

# Toast
@onready var toast_label: Label = $ToastLabel
@onready var toast_timer: Timer = $ToastTimer

# Bottom Palette
@onready var btn_road: Button = $BottomPalette/HBox/BtnRoad
@onready var btn_zone_r: Button = $BottomPalette/HBox/BtnZoneR
@onready var btn_zone_c: Button = $BottomPalette/HBox/BtnZoneC
@onready var btn_zone_i: Button = $BottomPalette/HBox/BtnZoneI
@onready var btn_power: Button = $BottomPalette/HBox/BtnPower
@onready var btn_water: Button = $BottomPalette/HBox/BtnWater
@onready var btn_park: Button = $BottomPalette/HBox/BtnPark
@onready var btn_farm: Button = $BottomPalette/HBox/BtnFarm
@onready var btn_bulldozer: Button = $BottomPalette/HBox/BtnBulldozer

# Modal Dialogs (Langkah 5) — diinisialisasi aman dengan get_node_or_null() di _ready()
var pak_slamet_modal: PanelContainer = null
var btn_ps_expel: Button = null
var btn_ps_parking: Button = null
var btn_ps_ignore: Button = null
var btn_ps_close: Button = null

var townhall_modal: PanelContainer = null
var th_stats_label: Label = null
var th_complaints_container: VBoxContainer = null
var btn_th_close: Button = null

var citizen_modal: PanelContainer = null
var label_cp_name: Label = null
var label_cp_job: Label = null
var label_cp_address: Label = null
var label_cp_traits: Label = null
var label_cp_history: Label = null
var label_cp_complaint: Label = null
var btn_cp_open_th: Button = null
var btn_cp_close: Button = null

var tool_buttons: Dictionary = {}
var speed_buttons: Dictionary = {}
var btn_power_cable: Button = null
var btn_water_pipe: Button = null
var btn_underground: Button = null
var label_security: Label = null
var public_tool_defs: Array = []

# Overlay Bubble Chat 2D (Langkah 5: maks 3 bubble, anti-tumpuk, clamp viewport)
const MAX_BUBBLES: int = 3
var bubble_layer: Control = null
var bubble_slots: Array = [] # [{ "panel": PanelContainer, "label": Label, "data": Dictionary }]

# Panel Misi, Pause Menu, dan Settings (Langkah 6)
var mission_vbox: VBoxContainer = null
var pause_modal: PanelContainer = null
var settings_modal: PanelContainer = null
var _prev_speed_before_pause: float = 1.0
var region_buy_modal: PanelContainer = null
var lbl_region_buy: Label = null
var _pending_region: Vector2i = Vector2i.ZERO

func _ready() -> void:
	if city_manager:
		city_manager.city_updated.connect(_on_city_updated)
		city_manager.show_toast.connect(_show_toast)
		city_manager.open_pak_slamet_modal.connect(open_pak_slamet_dialog)
		city_manager.open_citizen_modal.connect(open_citizen_profile_dialog)
		city_manager.open_townhall_modal.connect(open_townhall_dialog)
		city_manager.open_region_buy_modal.connect(_open_region_buy_dialog)

	tool_buttons = {
		CityManager.ToolMode.ROAD: btn_road,
		CityManager.ToolMode.ZONE_R: btn_zone_r,
		CityManager.ToolMode.ZONE_C: btn_zone_c,
		CityManager.ToolMode.ZONE_I: btn_zone_i,
		CityManager.ToolMode.POWER_PLANT: btn_power,
		CityManager.ToolMode.WATER_TOWER: btn_water,
		CityManager.ToolMode.PARK: btn_park,
		CityManager.ToolMode.FARM: btn_farm,
		CityManager.ToolMode.BULLDOZER: btn_bulldozer
	}

	_setup_utility_buttons()
	tool_buttons[CityManager.ToolMode.POWER_CABLE] = btn_power_cable
	tool_buttons[CityManager.ToolMode.WATER_PIPE] = btn_water_pipe

	btn_road.pressed.connect(func(): _select_tool(CityManager.ToolMode.ROAD))
	btn_zone_r.pressed.connect(func(): _select_tool(CityManager.ToolMode.ZONE_R))
	btn_zone_c.pressed.connect(func(): _select_tool(CityManager.ToolMode.ZONE_C))
	btn_zone_i.pressed.connect(func(): _select_tool(CityManager.ToolMode.ZONE_I))
	btn_power.pressed.connect(func(): _select_tool(CityManager.ToolMode.POWER_PLANT))
	btn_water.pressed.connect(func(): _select_tool(CityManager.ToolMode.WATER_TOWER))
	btn_power_cable.pressed.connect(func(): _select_tool(CityManager.ToolMode.POWER_CABLE))
	btn_water_pipe.pressed.connect(func(): _select_tool(CityManager.ToolMode.WATER_PIPE))
	btn_park.pressed.connect(func(): _select_tool(CityManager.ToolMode.PARK))
	btn_farm.pressed.connect(func(): _select_tool(CityManager.ToolMode.FARM))
	btn_bulldozer.pressed.connect(func(): _select_tool(CityManager.ToolMode.BULLDOZER))

	speed_buttons = {
		0.0: btn_pause,
		1.0: btn_1x,
		3.0: btn_3x
	}
	btn_pause.pressed.connect(func(): _select_speed(0.0))
	btn_1x.pressed.connect(func(): _select_speed(1.0))
	btn_3x.pressed.connect(func(): _select_speed(3.0))

	tax_slider.value_changed.connect(_on_tax_slider_changed)
	tax_slider.value = 8.0
	label_tax.text = "Pajak: 8%"

	btn_sell_wheat.pressed.connect(func():
		if city_manager:
			city_manager.sell_all_wheat()
	)

	btn_townhall.pressed.connect(open_townhall_dialog)

	# Inisialisasi aman modal Langkah 5 dengan get_node_or_null() + guard
	pak_slamet_modal = get_node_or_null("PakSlametModal") as PanelContainer
	if pak_slamet_modal:
		btn_ps_expel = pak_slamet_modal.get_node_or_null("VBox/HBoxActions/BtnExpel") as Button
		btn_ps_parking = pak_slamet_modal.get_node_or_null("VBox/HBoxActions/BtnOfficialParking") as Button
		btn_ps_ignore = pak_slamet_modal.get_node_or_null("VBox/HBoxActions/BtnIgnore") as Button
		btn_ps_close = pak_slamet_modal.get_node_or_null("VBox/BtnClosePS") as Button
		pak_slamet_modal.visible = false
	else:
		push_error("HUD: PakSlametModal tidak ditemukan di hud.tscn")

	townhall_modal = get_node_or_null("TownHallModal") as PanelContainer
	if townhall_modal:
		th_stats_label = townhall_modal.get_node_or_null("VBox/LabelStats") as Label
		th_complaints_container = townhall_modal.get_node_or_null("VBox/Scroll/VBoxComplaints") as VBoxContainer
		btn_th_close = townhall_modal.get_node_or_null("VBox/BtnCloseTH") as Button
		townhall_modal.visible = false
	else:
		push_error("HUD: TownHallModal tidak ditemukan di hud.tscn")

	citizen_modal = get_node_or_null("CitizenProfileModal") as PanelContainer
	if citizen_modal:
		label_cp_name = citizen_modal.get_node_or_null("VBox/LabelName") as Label
		label_cp_job = citizen_modal.get_node_or_null("VBox/LabelJob") as Label
		label_cp_address = citizen_modal.get_node_or_null("VBox/LabelAddress") as Label
		label_cp_traits = citizen_modal.get_node_or_null("VBox/LabelTraits") as Label
		label_cp_history = citizen_modal.get_node_or_null("VBox/LabelHistory") as Label
		label_cp_complaint = citizen_modal.get_node_or_null("VBox/LabelComplaint") as Label
		btn_cp_open_th = citizen_modal.get_node_or_null("VBox/HBoxCP/BtnOpenTH") as Button
		btn_cp_close = citizen_modal.get_node_or_null("VBox/HBoxCP/BtnCloseCP") as Button
		citizen_modal.visible = false
	else:
		push_error("HUD: CitizenProfileModal tidak ditemukan di hud.tscn")

	# Setup tombol modal Pak Slamet
	if btn_ps_expel:
		btn_ps_expel.pressed.connect(func():
			if city_manager and city_manager.pak_slamet_manager:
				if city_manager.pak_slamet_manager.action_expel() and pak_slamet_modal:
					pak_slamet_modal.visible = false
		)
	else:
		push_error("HUD: BtnExpel tidak ditemukan di PakSlametModal")

	if btn_ps_parking:
		btn_ps_parking.pressed.connect(func():
			if city_manager and city_manager.pak_slamet_manager:
				if city_manager.pak_slamet_manager.action_build_official_parking() and pak_slamet_modal:
					pak_slamet_modal.visible = false
		)
	else:
		push_error("HUD: BtnOfficialParking tidak ditemukan di PakSlametModal")

	if btn_ps_ignore:
		btn_ps_ignore.pressed.connect(func():
			if city_manager and city_manager.pak_slamet_manager:
				city_manager.pak_slamet_manager.action_ignore()
			if pak_slamet_modal:
				pak_slamet_modal.visible = false
		)
	else:
		push_error("HUD: BtnIgnore tidak ditemukan di PakSlametModal")

	if btn_ps_close:
		btn_ps_close.pressed.connect(func():
			if pak_slamet_modal:
				pak_slamet_modal.visible = false
		)
	else:
		push_error("HUD: BtnClosePS tidak ditemukan di PakSlametModal")

	# Setup tombol Balai Kota & Profil Warga
	if btn_th_close:
		btn_th_close.pressed.connect(func():
			if townhall_modal:
				townhall_modal.visible = false
		)
	else:
		push_error("HUD: BtnCloseTH tidak ditemukan di TownHallModal")

	if btn_cp_close:
		btn_cp_close.pressed.connect(func():
			if citizen_modal:
				citizen_modal.visible = false
		)
	else:
		push_error("HUD: BtnCloseCP tidak ditemukan di CitizenProfileModal")

	if btn_cp_open_th:
		btn_cp_open_th.pressed.connect(func():
			if citizen_modal:
				citizen_modal.visible = false
			open_townhall_dialog()
		)
	else:
		push_error("HUD: BtnOpenTH tidak ditemukan di CitizenProfileModal")

	toast_timer.timeout.connect(func(): toast_label.visible = false)
	toast_label.visible = false

	_setup_bubble_overlay()
	_setup_menu_button()
	_setup_mission_panel()
	_setup_pause_and_settings()
	_setup_region_buy_modal()
	_setup_touch_controls()
	_polish_hud_topbar()
	_select_tool(CityManager.ToolMode.ROAD)
	_select_speed(1.0)
	if city_manager and city_manager.city_data:
		_on_city_updated(city_manager.city_data)

func _select_tool(mode: CityManager.ToolMode) -> void:
	if city_manager and city_manager.current_tool != mode:
		AudioManager.play_sfx(self, "click")
	if city_manager:
		city_manager.set_tool(mode)

	for m in tool_buttons:
		var btn: Button = tool_buttons[m]
		var is_sel: bool = (m == mode)
		var sb := UIThemeHelper.make_panel_style(is_sel, 12, 8.0, 6.0, 0.96 if is_sel else 0.88)
		if is_sel:
			sb.bg_color = Color(0.20, 0.22, 0.30, 0.98)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)

func _select_speed(speed: float) -> void:
	if city_manager:
		city_manager.set_game_speed(speed)

	for s in speed_buttons:
		var btn: Button = speed_buttons[s]
		if is_equal_approx(s, speed):
			btn.modulate = Color(1.2, 1.2, 0.5)
		else:
			btn.modulate = Color(1.0, 1.0, 1.0)

func _on_tax_slider_changed(val: float) -> void:
	var rounded_pct := int(round(val))
	label_tax.text = "Pajak: %d%%" % rounded_pct
	if city_manager:
		city_manager.set_tax_rate(float(rounded_pct) / 100.0)

func _on_city_updated(data: CityData) -> void:
	label_money.text = "Rp " + _format_number(data.money)
	label_pop.text = "Pop: " + str(data.population)

	label_happiness.text = "Senang: %d%%" % int(round(data.happiness))
	if data.happiness >= 65.0:
		label_happiness.modulate = Color(0.3, 0.9, 0.4)
	elif data.happiness >= 45.0:
		label_happiness.modulate = Color(0.9, 0.8, 0.3)
	else:
		label_happiness.modulate = Color(1.0, 0.3, 0.3)

	label_popularity.text = "Populer: %d%%" % int(round(data.popularity))
	if data.popularity >= 65.0:
		label_popularity.modulate = Color(0.3, 0.85, 0.95)
	elif data.popularity >= 45.0:
		label_popularity.modulate = Color(0.95, 0.85, 0.3)
	else:
		label_popularity.modulate = Color(1.0, 0.4, 0.4)

	if label_security:
		label_security.text = "Aman: %d%%" % int(round(data.security))
		if data.security >= 70.0:
			label_security.modulate = Color(0.35, 0.90, 0.50)
		elif data.security >= 30.0:
			label_security.modulate = Color(0.95, 0.85, 0.30)
		else:
			label_security.modulate = Color(1.0, 0.35, 0.35)

	label_power.text = "Listrik: %d/%d" % [data.power_used, data.power_supply]
	if data.power_used > data.power_supply:
		label_power.modulate = Color(1.0, 0.3, 0.3)
	else:
		label_power.modulate = Color(0.9, 0.9, 0.9)

	label_water.text = "Air: %d/%d" % [data.water_used, data.water_supply]
	if data.water_used > data.water_supply:
		label_water.modulate = Color(1.0, 0.3, 0.3)
	else:
		label_water.modulate = Color(0.9, 0.9, 0.9)

	label_date.text = "Bulan %d, Th %d" % [data.month, data.year]
	label_tier.text = "[" + data.city_level + "]"

	bar_r.value = data.demand_r
	bar_c.value = data.demand_c
	bar_i.value = data.demand_i

	label_wheat.text = "Gandum: %d unit" % data.wheat_inventory
	label_price.text = "Harga: Rp %s / unit" % _format_number(data.wheat_price)

	var tax_pct: int = int(round(data.tax_rate * 100.0))
	if int(round(tax_slider.value)) != tax_pct:
		tax_slider.set_value_no_signal(float(tax_pct))
	label_tax.text = "Pajak: %d%%" % tax_pct

	_refresh_missions()

	# Update jumlah pengaduan di tombol Balai Kota
	var complaint_count := data.active_complaints.size()
	if data.pak_slamet_status.get("state") == "active":
		complaint_count += 1
	if complaint_count > 0:
		btn_townhall.text = "Balai Kota (%d)" % complaint_count
		UIThemeHelper.apply_btn_primary(btn_townhall, 32.0)
	else:
		btn_townhall.text = "Balai Kota"
		UIThemeHelper.apply_btn_secondary(btn_townhall, 32.0)

	# Tandai harga tool yang tidak mampu dibeli (merah pudar)
	var tool_costs := {
		CityManager.ToolMode.ROAD: CityData.COST_ROAD,
		CityManager.ToolMode.ZONE_R: CityData.COST_ZONE_R,
		CityManager.ToolMode.ZONE_C: CityData.COST_ZONE_C,
		CityManager.ToolMode.ZONE_I: CityData.COST_ZONE_I,
		CityManager.ToolMode.POWER_PLANT: CityData.COST_POWER_PLANT,
		CityManager.ToolMode.WATER_TOWER: CityData.COST_WATER_TOWER,
		CityManager.ToolMode.POWER_CABLE: CityData.COST_POWER_CABLE,
		CityManager.ToolMode.WATER_PIPE: CityData.COST_WATER_PIPE,
		CityManager.ToolMode.PARK: CityData.COST_PARK,
		CityManager.ToolMode.FARM: CityData.COST_FARM,
		CityManager.ToolMode.BULLDOZER: 0
	}
	for m in tool_buttons:
		var tbtn: Button = tool_buttons[m]
		var tcost: int = int(tool_costs.get(m, 0))
		if tcost > 0 and data.money < tcost:
			tbtn.add_theme_color_override("font_color", Color(0.95, 0.45, 0.45))
		else:
			tbtn.add_theme_color_override("font_color", Color(0.96, 0.96, 0.98))

	for pdef in public_tool_defs:
		var p_btn: Button = pdef["btn"]
		var p_type: int = pdef["tile_type"]
		var p_cost: int = pdef["cost"]
		var p_name: String = pdef["label"]
		var p_price_txt: String = pdef["price_txt"]
		var u_info: Dictionary = data.is_public_building_unlocked(p_type)
		if not u_info.get("unlocked", false):
			p_btn.disabled = true
			p_btn.text = "%s\n%s" % [p_name, str(u_info.get("reason", "Terkunci"))]
			p_btn.add_theme_color_override("font_color", Color(0.55, 0.58, 0.65))
		else:
			p_btn.disabled = false
			p_btn.text = "%s\n%s" % [p_name, p_price_txt]
			if data.money < p_cost:
				p_btn.add_theme_color_override("font_color", Color(0.95, 0.45, 0.45))
			else:
				p_btn.add_theme_color_override("font_color", Color(0.96, 0.96, 0.98))

	# Jika Balai Kota sedang terbuka, refresh daftarnya
	if townhall_modal and townhall_modal.visible:
		_refresh_townhall_list()

func open_pak_slamet_dialog() -> void:
	if pak_slamet_modal:
		pak_slamet_modal.visible = true

func open_citizen_profile_dialog(c_info: Dictionary, comp_info: Dictionary) -> void:
	if not citizen_modal:
		return
	if label_cp_name:
		label_cp_name.text = c_info.get("name", "Warga Kota")
	if label_cp_job:
		label_cp_job.text = "Pekerjaan: " + c_info.get("occupation", "-")
	if label_cp_address:
		label_cp_address.text = "Alamat: " + c_info.get("address", "-")
	if label_cp_traits:
		label_cp_traits.text = "Sifat: " + c_info.get("traits", "-")

	var history: Array = c_info.get("history", [])
	if label_cp_history:
		if not history.is_empty():
			label_cp_history.text = "Catatan: \"" + history[0] + "\""
		else:
			label_cp_history.text = "Catatan: Warga biasa yang taat aturan."

	if label_cp_complaint and btn_cp_open_th:
		if not comp_info.is_empty():
			label_cp_complaint.text = "Keluhan Saat Ini: \"" + comp_info.get("quote", "") + "\""
			label_cp_complaint.visible = true
			btn_cp_open_th.visible = true
		else:
			label_cp_complaint.visible = false
			btn_cp_open_th.visible = false

	_update_citizen_traffic_buttons(comp_info.get("type", "") == ComplaintsData.COMPLAINT_TRAFFIC)

	citizen_modal.visible = true

func _update_citizen_traffic_buttons(is_traffic: bool) -> void:
	if not citizen_modal:
		return
	var box := citizen_modal.get_node_or_null("TrafficSolBox") as HBoxContainer
	if not box and btn_cp_open_th and btn_cp_open_th.get_parent():
		box = HBoxContainer.new()
		box.name = "TrafficSolBox"
		box.add_theme_constant_override("separation", 8)
		var b_widen := Button.new()
		b_widen.text = "Lebarin Jalan (Rp3.000/tile)"
		b_widen.add_theme_font_size_override("font_size", 12)
		UIThemeHelper.apply_btn_secondary(b_widen, 36.0)
		b_widen.pressed.connect(func():
			citizen_modal.visible = false
			_select_tool(CityManager.ToolMode.WIDEN_ROAD)
		)
		var b_fly := Button.new()
		b_fly.text = "Bikin Flyover (Rp20.000/tile, Pop 500)"
		b_fly.add_theme_font_size_override("font_size", 12)
		UIThemeHelper.apply_btn_secondary(b_fly, 36.0)
		b_fly.pressed.connect(func():
			citizen_modal.visible = false
			_select_tool(CityManager.ToolMode.FLYOVER)
		)
		box.add_child(b_widen)
		box.add_child(b_fly)
		btn_cp_open_th.get_parent().add_child(box)
		btn_cp_open_th.get_parent().move_child(box, btn_cp_open_th.get_index())
	if box:
		box.visible = is_traffic

func open_townhall_dialog() -> void:
	if not townhall_modal:
		return
	townhall_modal.visible = true
	_refresh_townhall_list()

func _refresh_townhall_list() -> void:
	if not city_manager or not city_manager.city_data or not th_stats_label or not th_complaints_container:
		return

	var data: CityData = city_manager.city_data
	th_stats_label.text = "Popularitas: %d%%  |  Kebahagiaan: %d%%  |  Kas: Rp %s" % [
		int(round(data.popularity)),
		int(round(data.happiness)),
		_format_number(data.money)
	]

	# Bersihkan daftar kartu lama
	for child in th_complaints_container.get_children():
		child.queue_free()

	var has_items := false

	# 1. Kartu Parkir Liar Pak Slamet (jika sedang aktif)
	if data.pak_slamet_status.get("state") == "active":
		has_items = true
		var pak_slamet_action := func():
			townhall_modal.visible = false
			open_pak_slamet_dialog()
		var card := _create_complaint_card(
			"Pak Slamet (Tukang Parkir)",
			"Jl. Merdeka (Parkir Liar)",
			"Maju dikit, Pak, maju dikit! Parkir sini aja, aman!",
			"Aktif (Macet)",
			Color(1.0, 0.6, 0.1),
			[
				{
					"title": "Buka Opsi Penataan Pak Slamet",
					"action": pak_slamet_action
				}
			]
		)
		th_complaints_container.add_child(card)

	# 2. Kartu Pengaduan Warga Aktif
	for comp in data.active_complaints:
		has_items = true
		var comp_id: String = comp.get("id", "")
		var comp_type: String = comp.get("type", "")
		var citizen_name: String = comp.get("citizen_name", "Warga")
		var loc: String = comp.get("location", "Area Kota")
		var quote: String = comp.get("quote", "")
		var is_late: bool = (comp.get("status") == "late")

		var status_text := "Terlambat (Pop -5)" if is_late else "Aktif"
		var status_color := Color(1.0, 0.3, 0.3) if is_late else Color(0.3, 0.9, 0.4)

		var solutions: Array = ComplaintsData.COMPLAINT_SOLUTIONS.get(comp_type, [])
		var actions: Array = []

		for s_idx in range(solutions.size()):
			var sol: Dictionary = solutions[s_idx]
			var opt_title: String = "%s (Rp %s)" % [sol.get("title", ""), _format_number(sol.get("cost", 0))]
			var opt_idx := s_idx
			var opt_action := func():
				if city_manager:
					city_manager.resolve_complaint(comp_id, opt_idx)
			actions.append({
				"title": opt_title,
				"action": opt_action
			})

		var card := _create_complaint_card(citizen_name, loc, quote, status_text, status_color, actions)
		th_complaints_container.add_child(card)

	if not has_items:
		var empty_lbl := Label.new()
		empty_lbl.text = "Tidak ada pengaduan aktif saat ini. Kota tertib dan warga merasa puas!"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.modulate = Color(0.8, 0.9, 0.8)
		th_complaints_container.add_child(empty_lbl)

func _create_complaint_card(citizen: String, loc: String, quote: String, status_text: String, status_color: Color, actions: Array) -> PanelContainer:
	var card := PanelContainer.new()
	var sbox := StyleBoxFlat.new()
	sbox.bg_color = Color(0.14, 0.16, 0.22, 0.92)
	sbox.corner_radius_top_left = 6
	sbox.corner_radius_top_right = 6
	sbox.corner_radius_bottom_right = 6
	sbox.corner_radius_bottom_left = 6
	sbox.content_margin_left = 10.0
	sbox.content_margin_top = 8.0
	sbox.content_margin_right = 10.0
	sbox.content_margin_bottom = 8.0
	card.add_theme_stylebox_override("panel", sbox)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	# Header: Nama Warga + Status
	var hbox_header := HBoxContainer.new()
	var lbl_name := Label.new()
	lbl_name.text = citizen + " — " + loc
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_name.add_theme_font_size_override("font_size", 14)
	lbl_name.modulate = Color(1.0, 0.9, 0.4)
	hbox_header.add_child(lbl_name)

	var lbl_status := Label.new()
	lbl_status.text = status_text
	lbl_status.modulate = status_color
	lbl_status.add_theme_font_size_override("font_size", 12)
	hbox_header.add_child(lbl_status)
	vbox.add_child(hbox_header)

	# Kutipan Keluhan
	var lbl_quote := Label.new()
	lbl_quote.text = "\"" + quote + "\""
	lbl_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_quote.add_theme_font_size_override("font_size", 13)
	vbox.add_child(lbl_quote)

	# Tombol Tindakan
	if not actions.is_empty():
		var hbox_btns := HBoxContainer.new()
		hbox_btns.add_theme_constant_override("separation", 8)
		for act in actions:
			var btn := Button.new()
			btn.text = act.get("title", "Tanggapi")
			btn.custom_minimum_size = Vector2(0, 30)
			btn.pressed.connect(act.get("action"))
			hbox_btns.add_child(btn)
		vbox.add_child(hbox_btns)

	card.add_child(vbox)
	return card

func _show_toast(msg: String) -> void:
	var low := msg.to_lower()
	var is_err: bool = ("tidak cukup" in low) or ("kosong" in low) or ("kurang" in low) or ("harus" in low) or ("gagal" in low)
	toast_label.add_theme_stylebox_override("normal", UIThemeHelper.make_toast_style(is_err))
	toast_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45) if is_err else Color(0.98, 0.98, 0.98))
	toast_label.text = msg
	toast_label.visible = true
	toast_timer.start(3.0)

func _polish_hud_topbar() -> void:
	for p_name in ["TopPanel", "RightPanel", "TimeSpeedPanel", "TaxPanel", "FarmPanel", "BottomPalette"]:
		var p_node := get_node_or_null(p_name) as PanelContainer
		if p_node:
			p_node.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(false, 16, 12.0, 8.0, 0.92))

	var top_hbox := get_node_or_null("TopPanel/HBox") as HBoxContainer
	if not top_hbox:
		return

	var icon_map := {
		"LabelMoney": "money",
		"LabelPop": "pop",
		"LabelHappiness": "happy",
		"LabelPopularity": "pop",
		"LabelPower": "power",
		"LabelWater": "water",
		"LabelDate": "date"
	}
	var chip_style := UIThemeHelper.make_chip_style()
	for lbl in [label_money, label_pop, label_happiness, label_popularity, label_power, label_water, label_date, label_tier]:
		if not lbl or not is_instance_valid(lbl):
			continue
		var idx: int = lbl.get_index()
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", chip_style)
		var chbox := HBoxContainer.new()
		chbox.add_theme_constant_override("separation", 5)
		chip.add_child(chbox)
		if icon_map.has(lbl.name):
			chbox.add_child(S1VisualBuilder.StatIcon.new(icon_map[lbl.name]))
		top_hbox.remove_child(lbl)
		chbox.add_child(lbl)
		top_hbox.add_child(chip)
		top_hbox.move_child(chip, idx)

	if btn_sell_wheat:
		UIThemeHelper.apply_btn_primary(btn_sell_wheat, 40.0)

	# Chip Keamanan (0-100) di TopPanel
	if not label_security:
		label_security = Label.new()
		label_security.name = "LabelSecurity"
		label_security.text = "Aman: 50%"
		var sec_chip := PanelContainer.new()
		sec_chip.add_theme_stylebox_override("panel", chip_style)
		var sch := HBoxContainer.new()
		sch.add_theme_constant_override("separation", 5)
		sch.add_child(S1VisualBuilder.StatIcon.new("security"))
		sch.add_child(label_security)
		sec_chip.add_child(sch)
		top_hbox.add_child(sec_chip)
		var pop_chip := label_popularity.get_parent().get_parent()
		if pop_chip and pop_chip.get_parent() == top_hbox:
			top_hbox.move_child(sec_chip, pop_chip.get_index() + 1)

func _setup_utility_buttons() -> void:
	var palette := get_node_or_null("BottomPalette") as PanelContainer
	var hbox := get_node_or_null("BottomPalette/HBox") as HBoxContainer
	if not hbox:
		return

	# Bungkus HBox dengan ScrollContainer agar 19 tombol muat rapi di 1280x720
	if palette and hbox.get_parent() == palette:
		var scroll := ScrollContainer.new()
		scroll.name = "ToolScroll"
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.custom_minimum_size = Vector2(1180, 54)
		palette.remove_child(hbox)
		scroll.add_child(hbox)
		palette.add_child(scroll)

	btn_power_cable = Button.new()
	btn_power_cable.name = "BtnPowerCable"
	btn_power_cable.text = "Kabel\nRp 1.000"
	btn_power_cable.custom_minimum_size = Vector2(76, 44)
	btn_power_cable.add_theme_font_size_override("font_size", 11)
	hbox.add_child(btn_power_cable)
	hbox.move_child(btn_power_cable, btn_bulldozer.get_index())

	btn_water_pipe = Button.new()
	btn_water_pipe.name = "BtnWaterPipe"
	btn_water_pipe.text = "Pipa\nRp 1.000"
	btn_water_pipe.custom_minimum_size = Vector2(76, 44)
	btn_water_pipe.add_theme_font_size_override("font_size", 11)
	hbox.add_child(btn_water_pipe)
	hbox.move_child(btn_water_pipe, btn_bulldozer.get_index())

	var pub_specs := [
		{"name": "BtnSchool", "label": "Sekolah", "price_txt": "Rp75rb", "mode": CityManager.ToolMode.SCHOOL, "tile_type": CityData.TileType.SCHOOL, "cost": CityData.COST_SCHOOL},
		{"name": "BtnClinic", "label": "Puskesmas", "price_txt": "Rp60rb", "mode": CityManager.ToolMode.CLINIC, "tile_type": CityData.TileType.CLINIC, "cost": CityData.COST_CLINIC},
		{"name": "BtnHospital", "label": "Rumah Sakit", "price_txt": "Rp250rb", "mode": CityManager.ToolMode.HOSPITAL, "tile_type": CityData.TileType.HOSPITAL, "cost": CityData.COST_HOSPITAL},
		{"name": "BtnPolice", "label": "Polisi", "price_txt": "Rp100rb", "mode": CityManager.ToolMode.POLICE, "tile_type": CityData.TileType.POLICE, "cost": CityData.COST_POLICE},
		{"name": "BtnMilitary", "label": "Markas TNI", "price_txt": "Rp200rb", "mode": CityManager.ToolMode.MILITARY, "tile_type": CityData.TileType.MILITARY, "cost": CityData.COST_MILITARY},
		{"name": "BtnMayorOffice", "label": "Ktr Walikota", "price_txt": "Rp150rb", "mode": CityManager.ToolMode.MAYOR_OFFICE, "tile_type": CityData.TileType.MAYOR_OFFICE, "cost": CityData.COST_MAYOR_OFFICE},
		{"name": "BtnFireStation", "label": "Damkar", "price_txt": "Rp120rb", "mode": CityManager.ToolMode.FIRE_STATION, "tile_type": CityData.TileType.FIRE_STATION, "cost": CityData.COST_FIRE_STATION},
		{"name": "BtnZoneMilitary", "label": "Z. Militer", "price_txt": "Rp2rb", "mode": CityManager.ToolMode.ZONE_MILITARY, "tile_type": CityData.TileType.ZONE_MILITARY, "cost": CityData.COST_ZONE_MILITARY},
		{"name": "BtnTrainStation", "label": "Stasiun", "price_txt": "Rp150rb", "mode": CityManager.ToolMode.TRAIN_STATION, "tile_type": CityData.TileType.TRAIN_STATION, "cost": CityData.COST_TRAIN_STATION},
		{"name": "BtnRail", "label": "Rel Kereta", "price_txt": "Rp3rb", "mode": CityManager.ToolMode.RAIL, "tile_type": CityData.TileType.RAIL, "cost": CityData.COST_RAIL},
		{"name": "BtnStopAngkot", "label": "Hlt Angkot", "price_txt": "Rp10rb", "mode": CityManager.ToolMode.STOP_ANGKOT, "tile_type": CityData.TileType.STOP_ANGKOT, "cost": CityData.COST_STOP_ANGKOT},
		{"name": "BtnStopBus", "label": "Hlt Bus", "price_txt": "Rp15rb", "mode": CityManager.ToolMode.STOP_BUS, "tile_type": CityData.TileType.STOP_BUS, "cost": CityData.COST_STOP_BUS},
		{"name": "BtnBuswayLane", "label": "Jlr Busway", "price_txt": "Rp8rb", "mode": CityManager.ToolMode.BUSWAY_LANE, "tile_type": CityData.TileType.BUSWAY_LANE, "cost": CityData.COST_BUSWAY_LANE},
		{"name": "BtnStopBusway", "label": "Hlt Busway", "price_txt": "Rp25rb", "mode": CityManager.ToolMode.STOP_BUSWAY, "tile_type": CityData.TileType.STOP_BUSWAY, "cost": CityData.COST_STOP_BUSWAY},
		{"name": "BtnWidenRoad", "label": "Lebarin Jln", "price_txt": "Rp3rb", "mode": CityManager.ToolMode.WIDEN_ROAD, "tile_type": CityData.TileType.ROAD, "cost": CityData.COST_WIDEN_ROAD},
		{"name": "BtnFlyover", "label": "Flyover", "price_txt": "Rp20rb", "mode": CityManager.ToolMode.FLYOVER, "tile_type": CityData.TileType.FLYOVER, "cost": CityData.COST_FLYOVER},
		{"name": "BtnRunway", "label": "Landasan", "price_txt": "Rp5rb", "mode": CityManager.ToolMode.RUNWAY, "tile_type": CityData.TileType.RUNWAY, "cost": CityData.COST_RUNWAY},
		{"name": "BtnTerminal", "label": "Terminal", "price_txt": "Rp300rb", "mode": CityManager.ToolMode.AIRPORT_TERMINAL, "tile_type": CityData.TileType.AIRPORT_TERMINAL, "cost": CityData.COST_AIRPORT_TERMINAL}
	]
	public_tool_defs.clear()
	for spec in pub_specs:
		var b := Button.new()
		b.name = spec["name"]
		b.text = "%s\n%s" % [spec["label"], spec["price_txt"]]
		b.custom_minimum_size = Vector2(96, 44)
		b.add_theme_font_size_override("font_size", 10)
		var m_val: CityManager.ToolMode = spec["mode"]
		b.pressed.connect(func(): _select_tool(m_val))
		hbox.add_child(b)
		hbox.move_child(b, btn_bulldozer.get_index())
		tool_buttons[m_val] = b
		public_tool_defs.append({
			"btn": b,
			"label": spec["label"],
			"price_txt": spec["price_txt"],
			"tile_type": spec["tile_type"],
			"cost": spec["cost"]
		})

	btn_underground = Button.new()
	btn_underground.name = "BtnUnderground"
	btn_underground.toggle_mode = true
	btn_underground.text = "Bawah\nTanah"
	btn_underground.custom_minimum_size = Vector2(74, 44)
	btn_underground.add_theme_font_size_override("font_size", 11)
	UIThemeHelper.apply_btn_secondary(btn_underground, 44.0)
	btn_underground.toggled.connect(func(pressed_on: bool):
		AudioManager.play_sfx(self, "click")
		if pressed_on:
			UIThemeHelper.apply_btn_primary(btn_underground, 44.0)
		else:
			UIThemeHelper.apply_btn_secondary(btn_underground, 44.0)
		if city_manager:
			city_manager.set_underground_view(pressed_on)
	)
	hbox.add_child(btn_underground)

	var buy_specs := [
		{"name": "BtnBuyKopaja", "text": "+Kopaja\nRp80rb", "fn": func(): if city_manager: city_manager.buy_kopaja_bus()},
		{"name": "BtnBuyBusway", "text": "+Busway\nRp120rb", "fn": func(): if city_manager: city_manager.buy_busway_unit()},
		{"name": "BtnBuyPlane", "text": "+Pesawat\nRp200rb", "fn": func(): if city_manager: city_manager.buy_airplane()}
	]
	for bsp in buy_specs:
		var bb := Button.new()
		bb.name = bsp["name"]
		bb.text = bsp["text"]
		bb.custom_minimum_size = Vector2(78, 44)
		bb.add_theme_font_size_override("font_size", 10)
		UIThemeHelper.apply_btn_secondary(bb, 44.0)
		bb.pressed.connect(bsp["fn"])
		hbox.add_child(bb)

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

func _setup_bubble_overlay() -> void:
	bubble_layer = Control.new()
	bubble_layer.name = "BubbleOverlay"
	bubble_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	bubble_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bubble_layer)
	move_child(bubble_layer, 0)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.10, 0.16, 0.92)
	bg_style.border_width_left = 2
	bg_style.border_width_top = 2
	bg_style.border_width_right = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.95, 0.78, 0.25, 0.95)
	bg_style.corner_radius_top_left = 14
	bg_style.corner_radius_top_right = 14
	bg_style.corner_radius_bottom_right = 14
	bg_style.corner_radius_bottom_left = 14
	bg_style.shadow_color = Color(0.0, 0.0, 0.0, 0.40)
	bg_style.shadow_size = 5
	bg_style.shadow_offset = Vector2(0.0, 3.0)
	bg_style.content_margin_left = 12.0
	bg_style.content_margin_top = 7.0
	bg_style.content_margin_right = 12.0
	bg_style.content_margin_bottom = 7.0

	for i in range(MAX_BUBBLES):
		var panel := PanelContainer.new()
		panel.visible = false
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.add_theme_stylebox_override("panel", bg_style)

		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.98, 0.98, 0.98))
		panel.add_child(lbl)

		var slot_idx: int = i
		panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_bubble_clicked(slot_idx)
		)

		bubble_layer.add_child(panel)
		bubble_slots.append({
			"panel": panel,
			"label": lbl,
			"data": {}
		})

func _on_bubble_clicked(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= bubble_slots.size():
		return
	var entry: Dictionary = bubble_slots[slot_idx]["data"]
	if entry.is_empty():
		return
	if entry.get("is_pak_slamet", false):
		open_pak_slamet_dialog()
	else:
		var walker = entry.get("walker", null)
		if walker != null:
			open_citizen_profile_dialog(walker.citizen_data, walker.active_complaint)

func _process(_delta: float) -> void:
	_update_screen_bubbles()

func _update_screen_bubbles() -> void:
	if not bubble_layer or bubble_slots.is_empty():
		return

	var modal_open: bool = (
		(pak_slamet_modal and pak_slamet_modal.visible) or
		(townhall_modal and townhall_modal.visible) or
		(citizen_modal and citizen_modal.visible) or
		(pause_modal and pause_modal.visible) or
		(settings_modal and settings_modal.visible)
	)
	if modal_open or not city_manager or not city_manager.city_data:
		for slot in bubble_slots:
			(slot["panel"] as PanelContainer).visible = false
		return

	var cam: Camera3D = get_viewport().get_camera_3d()
	if not cam:
		for slot in bubble_slots:
			(slot["panel"] as PanelContainer).visible = false
		return

	# Kumpulkan maksimal 3 bubble: Prioritas 1 = Pak Slamet, sisanya keluhan warga terbaru
	var entries: Array = []
	var data: CityData = city_manager.city_data
	if data.pak_slamet_status.get("state") == "active":
		var ps_tile: Vector2i = data.pak_slamet_status.get("active_tile", Vector2i(-1, -1))
		if ps_tile != Vector2i(-1, -1):
			var ps_pos: Vector3 = CityData.tile_to_world_pos(ps_tile.x, ps_tile.y) + Vector3(0.55, 1.35, -0.55)
			entries.append({
				"world_pos": ps_pos,
				"text": "Pak Slamet: Maju dikit, Pak, maju dikit! Parkir sini aja, aman!",
				"is_pak_slamet": true
			})

	if city_manager.citizen_manager:
		var citizen_entries: Array = city_manager.citizen_manager.get_active_bubble_entries()
		for ce in citizen_entries:
			if entries.size() >= MAX_BUBBLES:
				break
			entries.append(ce)

	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var placed_rects: Array[Rect2] = []

	for i in range(MAX_BUBBLES):
		var slot: Dictionary = bubble_slots[i]
		var panel: PanelContainer = slot["panel"]
		var lbl: Label = slot["label"]

		if i >= entries.size():
			panel.visible = false
			slot["data"] = {}
			continue

		var entry: Dictionary = entries[i]
		var world_pos: Vector3 = entry["world_pos"]
		if cam.is_position_behind(world_pos):
			panel.visible = false
			slot["data"] = {}
			continue

		var txt: String = entry["text"]
		lbl.text = txt
		if entry.get("is_pak_slamet", false):
			lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.28))
		else:
			lbl.add_theme_color_override("font_color", Color(0.98, 0.98, 0.98))

		# Sesuaikan ukuran bubble dengan panjang teks (wrap bila > 220px)
		var font: Font = lbl.get_theme_default_font()
		var str_w: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x if font else 220.0
		if str_w > 220.0:
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl.custom_minimum_size = Vector2(220.0, 0.0)
		else:
			lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
			lbl.custom_minimum_size = Vector2.ZERO

		panel.reset_size()
		var p_size: Vector2 = panel.get_combined_minimum_size()
		var screen_pos: Vector2 = cam.unproject_position(world_pos)
		var pos := Vector2(screen_pos.x - p_size.x * 0.5, screen_pos.y - p_size.y - 8.0)

		# Stagger vertikal bila bertumpuk dengan bubble lain yang sudah ditempatkan
		var candidate := Rect2(pos, p_size)
		var guard := 0
		while guard < 4:
			var hit := false
			for r in placed_rects:
				if candidate.intersects(r):
					pos.y = r.position.y - p_size.y - 6.0
					candidate = Rect2(pos, p_size)
					hit = true
					break
			if not hit:
				break
			guard += 1

		# Clamp ke dalam viewport (hindari top bar & toolbar bawah)
		pos.x = clampf(pos.x, 8.0, maxf(8.0, vp_size.x - p_size.x - 8.0))
		pos.y = clampf(pos.y, 60.0, maxf(60.0, vp_size.y - p_size.y - 90.0))

		panel.position = pos
		panel.visible = true
		slot["data"] = entry
		placed_rects.append(Rect2(pos, p_size))

func _make_dark_stylebox(alpha: float = 0.88, radius: int = 8, margin_h: float = 12.0, margin_v: float = 10.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.18, alpha)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.28, 0.35, 0.50, 0.9)
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_right = radius
	sb.corner_radius_bottom_left = radius
	sb.content_margin_left = margin_h
	sb.content_margin_top = margin_v
	sb.content_margin_right = margin_h
	sb.content_margin_bottom = margin_v
	return sb

func _setup_menu_button() -> void:
	var top_hbox: HBoxContainer = get_node_or_null("TopPanel/HBox") as HBoxContainer
	if not top_hbox:
		return
	var btn_menu := Button.new()
	btn_menu.name = "BtnPauseMenu"
	btn_menu.text = "☰ Menu"
	btn_menu.custom_minimum_size = Vector2(76, 28)
	btn_menu.add_theme_font_size_override("font_size", 13)
	btn_menu.pressed.connect(_toggle_pause_menu)
	top_hbox.add_child(btn_menu)

func _setup_mission_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "MissionPanel"
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -262.0
	panel.offset_top = 186.0
	panel.offset_right = -12.0
	panel.offset_bottom = 395.0
	panel.add_theme_stylebox_override("panel", _make_dark_stylebox(0.86, 8, 10.0, 8.0))
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Misi Kota"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)

	mission_vbox = VBoxContainer.new()
	mission_vbox.add_theme_constant_override("separation", 4)
	vbox.add_child(mission_vbox)

func _refresh_missions() -> void:
	if not mission_vbox or not city_manager:
		return

	for child in mission_vbox.get_children():
		child.queue_free()

	for m in city_manager.get_missions_status():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var lbl := Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var reward_str: String = "Rp %s" % _format_number(m["reward"])
		if m["claimed"]:
			lbl.text = "✓ %s (Diklaim)" % m["title"]
			lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
			row.add_child(lbl)
		elif m["completed"]:
			lbl.text = "✓ %s" % m["title"]
			lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
			row.add_child(lbl)

			var btn_claim := Button.new()
			btn_claim.text = "Klaim +%s" % reward_str
			btn_claim.add_theme_font_size_override("font_size", 11)
			btn_claim.custom_minimum_size = Vector2(0, 22)
			var mid: String = m["id"]
			btn_claim.pressed.connect(func():
				if city_manager:
					city_manager.claim_mission(mid)
			)
			row.add_child(btn_claim)
		else:
			lbl.text = "○ %s (+%s)" % [m["title"], reward_str]
			lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
			row.add_child(lbl)

		mission_vbox.add_child(row)

func _setup_pause_and_settings() -> void:
	# 1. Pause Modal
	pause_modal = PanelContainer.new()
	pause_modal.name = "PauseModal"
	pause_modal.visible = false
	pause_modal.set_anchors_preset(Control.PRESET_CENTER)
	pause_modal.offset_left = -155.0
	pause_modal.offset_top = -145.0
	pause_modal.offset_right = 155.0
	pause_modal.offset_bottom = 145.0
	pause_modal.add_theme_stylebox_override("panel", _make_dark_stylebox(0.95, 12, 20.0, 18.0))
	add_child(pause_modal)

	var pvbox := VBoxContainer.new()
	pvbox.add_theme_constant_override("separation", 10)
	pause_modal.add_child(pvbox)

	var ptitle := Label.new()
	ptitle.text = "Permainan Dijeda"
	ptitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ptitle.add_theme_font_size_override("font_size", 18)
	ptitle.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	pvbox.add_child(ptitle)

	var btn_resume := Button.new()
	btn_resume.text = "Lanjut"
	btn_resume.custom_minimum_size = Vector2(0, 36)
	btn_resume.pressed.connect(_close_pause_menu)
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
		if city_manager:
			city_manager.save_game(true)
	)
	pvbox.add_child(btn_save)

	var btn_exit_menu := Button.new()
	btn_exit_menu.text = "Keluar ke Menu Utama"
	btn_exit_menu.custom_minimum_size = Vector2(0, 36)
	btn_exit_menu.pressed.connect(func():
		if city_manager:
			city_manager.save_game(false) # Autosave sebelum keluar
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	pvbox.add_child(btn_exit_menu)

	# 2. Settings Modal (tombol & penyimpanan saja, audio di Langkah 7)
	settings_modal = PanelContainer.new()
	settings_modal.name = "SettingsModal"
	settings_modal.visible = false
	settings_modal.set_anchors_preset(Control.PRESET_CENTER)
	settings_modal.offset_left = -180.0
	settings_modal.offset_top = -155.0
	settings_modal.offset_right = 180.0
	settings_modal.offset_bottom = 155.0
	settings_modal.add_theme_stylebox_override("panel", _make_dark_stylebox(0.96, 12, 20.0, 18.0))
	add_child(settings_modal)

	var svbox := VBoxContainer.new()
	svbox.add_theme_constant_override("separation", 10)
	settings_modal.add_child(svbox)

	var stitle := Label.new()
	stitle.text = "Pengaturan"
	stitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stitle.add_theme_font_size_override("font_size", 18)
	stitle.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	svbox.add_child(stitle)

	var cur_settings: Dictionary = SaveManager.load_settings()

	var lbl_master := Label.new()
	lbl_master.text = "Volume Utama: %d%%" % int(cur_settings["master_volume"])
	svbox.add_child(lbl_master)
	var sl_master := HSlider.new()
	sl_master.min_value = 0.0
	sl_master.max_value = 100.0
	sl_master.value = float(cur_settings["master_volume"])
	sl_master.value_changed.connect(func(v: float): lbl_master.text = "Volume Utama: %d%%" % int(v))
	svbox.add_child(sl_master)

	var lbl_music := Label.new()
	lbl_music.text = "Volume Musik: %d%%" % int(cur_settings["music_volume"])
	svbox.add_child(lbl_music)
	var sl_music := HSlider.new()
	sl_music.min_value = 0.0
	sl_music.max_value = 100.0
	sl_music.value = float(cur_settings["music_volume"])
	sl_music.value_changed.connect(func(v: float): lbl_music.text = "Volume Musik: %d%%" % int(v))
	svbox.add_child(sl_music)

	var lbl_sfx := Label.new()
	lbl_sfx.text = "Volume SFX: %d%%" % int(cur_settings["sfx_volume"])
	svbox.add_child(lbl_sfx)
	var sl_sfx := HSlider.new()
	sl_sfx.min_value = 0.0
	sl_sfx.max_value = 100.0
	sl_sfx.value = float(cur_settings["sfx_volume"])
	sl_sfx.value_changed.connect(func(v: float): lbl_sfx.text = "Volume SFX: %d%%" % int(v))
	svbox.add_child(sl_sfx)

	var chk_mute := CheckButton.new()
	chk_mute.text = "Senyapkan Semua (Mute)"
	chk_mute.button_pressed = bool(cur_settings["muted"])
	svbox.add_child(chk_mute)

	var btn_save_settings := Button.new()
	btn_save_settings.text = "Simpan & Kembali"
	btn_save_settings.custom_minimum_size = Vector2(0, 34)
	btn_save_settings.pressed.connect(func():
		SaveManager.save_settings({
			"master_volume": sl_master.value,
			"music_volume": sl_music.value,
			"sfx_volume": sl_sfx.value,
			"muted": chk_mute.button_pressed
		})
		AudioManager.play_sfx(self, "click")
		settings_modal.visible = false
		pause_modal.visible = true
		_show_toast("Pengaturan disimpan.")
	)
	svbox.add_child(btn_save_settings)

func _toggle_pause_menu() -> void:
	if not pause_modal:
		return
	if pause_modal.visible:
		_close_pause_menu()
	else:
		if city_manager and city_manager.city_data and city_manager.city_data.game_speed > 0.0:
			_prev_speed_before_pause = city_manager.city_data.game_speed
			_select_speed(0.0)
		pause_modal.visible = true

func _close_pause_menu() -> void:
	if pause_modal:
		pause_modal.visible = false
	if city_manager and city_manager.city_data and city_manager.city_data.game_speed == 0.0:
		_select_speed(_prev_speed_before_pause if _prev_speed_before_pause > 0.0 else 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_modal and settings_modal.visible:
			settings_modal.visible = false
			if pause_modal:
				pause_modal.visible = true
		elif pak_slamet_modal and pak_slamet_modal.visible:
			pak_slamet_modal.visible = false
		elif townhall_modal and townhall_modal.visible:
			townhall_modal.visible = false
		elif citizen_modal and citizen_modal.visible:
			citizen_modal.visible = false
		else:
			_toggle_pause_menu()
		get_viewport().set_input_as_handled()

func _setup_touch_controls() -> void:
	# Tombol putar kamera kiri/kanan (semi-transparan, tidak menutupi kota)
	var rot_box := HBoxContainer.new()
	rot_box.name = "CameraRotateBox"
	rot_box.anchor_left = 1.0
	rot_box.anchor_top = 1.0
	rot_box.anchor_right = 1.0
	rot_box.anchor_bottom = 1.0
	rot_box.offset_left = -114.0
	rot_box.offset_top = -126.0
	rot_box.offset_right = -14.0
	rot_box.offset_bottom = -82.0
	rot_box.add_theme_constant_override("separation", 6)
	rot_box.modulate = Color(1.0, 1.0, 1.0, 0.82)
	add_child(rot_box)

	var btn_rot_l := Button.new()
	btn_rot_l.text = "⟲"
	btn_rot_l.custom_minimum_size = Vector2(46, 42)
	btn_rot_l.add_theme_font_size_override("font_size", 18)
	btn_rot_l.pressed.connect(func():
		AudioManager.play_sfx(self, "click")
		if city_manager and city_manager.camera_controller:
			city_manager.camera_controller.rotate_yaw(-30.0)
	)
	rot_box.add_child(btn_rot_l)

	var btn_rot_r := Button.new()
	btn_rot_r.text = "⟳"
	btn_rot_r.custom_minimum_size = Vector2(46, 42)
	btn_rot_r.add_theme_font_size_override("font_size", 18)
	btn_rot_r.pressed.connect(func():
		AudioManager.play_sfx(self, "click")
		if city_manager and city_manager.camera_controller:
			city_manager.camera_controller.rotate_yaw(30.0)
	)
	rot_box.add_child(btn_rot_r)

func _input(event: InputEvent) -> void:
	# 1 jari drag di atas tool palette = pilih tool
	if event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		for m in tool_buttons:
			var btn: Button = tool_buttons[m]
			if btn and btn.visible and btn.get_global_rect().has_point(sd.position):
				if city_manager and city_manager.current_tool != m:
					_select_tool(m)
				break

func _setup_region_buy_modal() -> void:
	region_buy_modal = PanelContainer.new()
	region_buy_modal.name = "RegionBuyModal"
	region_buy_modal.visible = false
	region_buy_modal.set_anchors_preset(Control.PRESET_CENTER)
	region_buy_modal.offset_left = -205.0
	region_buy_modal.offset_top = -105.0
	region_buy_modal.offset_right = 205.0
	region_buy_modal.offset_bottom = 105.0
	region_buy_modal.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(true, 18, 20.0, 18.0, 0.96))
	add_child(region_buy_modal)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	region_buy_modal.add_child(vbox)

	vbox.add_child(UIThemeHelper.make_panel_header("Perluas Wilayah", "money"))
	vbox.add_child(HSeparator.new())

	lbl_region_buy = Label.new()
	lbl_region_buy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_region_buy.add_theme_font_size_override("font_size", 14)
	vbox.add_child(lbl_region_buy)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox)

	var btn_buy := Button.new()
	btn_buy.text = "Beli"
	btn_buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIThemeHelper.apply_btn_primary(btn_buy, 48.0)
	btn_buy.pressed.connect(func():
		region_buy_modal.visible = false
		if city_manager:
			city_manager.buy_region(_pending_region)
	)
	hbox.add_child(btn_buy)

	var btn_cancel := Button.new()
	btn_cancel.text = "Batal"
	btn_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIThemeHelper.apply_btn_secondary(btn_cancel, 48.0)
	btn_cancel.pressed.connect(func():
		AudioManager.play_sfx(self, "click")
		region_buy_modal.visible = false
	)
	hbox.add_child(btn_cancel)

func _open_region_buy_dialog(reg: Vector2i, price: int) -> void:
	_pending_region = reg
	if lbl_region_buy:
		lbl_region_buy.text = "Buka wilayah baru (16x16 tile)? Harga Rp %s. Lanjutkan?" % _format_number(price)
	if region_buy_modal:
		region_buy_modal.visible = true
