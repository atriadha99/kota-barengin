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
var category_popup: PanelContainer = null
var category_buttons: Dictionary = {}
var category_containers: Dictionary = {}
var open_category_id: String = ""
var tool_to_category: Dictionary = {}
var btn_rotate_preview: Button = null
var btn_cancel_move: Button = null
var building_info_modal: PanelContainer = null
var lbl_bi_title: Label = null
var lbl_bi_info: Label = null
var btn_bi_rotate: Button = null
var btn_bi_move: Button = null
var btn_bi_townhall: Button = null
var _selected_building_pos: Vector2i = Vector2i(-1, -1)
var weather_icon: S1VisualBuilder.StatIcon = null
var event_modal: PanelContainer = null
var lbl_event_info: Label = null
var stats_backdrop: ColorRect = null
var stats_modal: PanelContainer = null
var stats_vbox: VBoxContainer = null
var photo_helper: PhotoModeHelper = null
var _prev_speed_before_photo: float = 1.0
var farm_info_modal: PanelContainer = null
var lbl_fi_title: Label = null
var lbl_fi_status: Label = null
var lbl_fi_reason: Label = null
var lbl_fi_warehouse: Label = null
var btn_fi_harvest: Button = null
var _selected_farm_pos: Vector2i = Vector2i(-1, -1)

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
var unit_modal: PanelContainer = null
var unit_vbox: VBoxContainer = null
var incident_modal: PanelContainer = null
var incident_vbox: VBoxContainer = null
var _pending_region: Vector2i = Vector2i.ZERO

func _ready() -> void:
	if city_manager:
		city_manager.city_updated.connect(_on_city_updated)
		city_manager.show_toast.connect(_show_toast)
		city_manager.open_pak_slamet_modal.connect(open_pak_slamet_dialog)
		city_manager.open_citizen_modal.connect(open_citizen_profile_dialog)
		city_manager.open_townhall_modal.connect(open_townhall_dialog)
		city_manager.open_region_buy_modal.connect(_open_region_buy_dialog)
		city_manager.open_building_info_modal.connect(_open_building_info_dialog)
		city_manager.move_mode_changed.connect(_on_move_mode_changed)
		city_manager.map_tapped.connect(_close_category_popup)
		city_manager.time_weather_updated.connect(_on_time_weather_updated)
		city_manager.open_farm_info_modal.connect(_open_farm_info_dialog)
		city_manager.open_incident_modal.connect(_open_incident_dialog)

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
	_setup_unit_and_incident_modals()
	_setup_touch_controls()
	_polish_hud_topbar()
	_select_tool(CityManager.ToolMode.ROAD)
	_select_speed(1.0)
	if city_manager and city_manager.city_data:
		_on_city_updated(city_manager.city_data)

func _select_tool(mode: CityManager.ToolMode) -> void:
	var final_mode: CityManager.ToolMode = mode
	if city_manager and city_manager.current_tool == mode and mode != CityManager.ToolMode.NONE:
		final_mode = CityManager.ToolMode.NONE
	if city_manager and city_manager.current_tool != final_mode:
		AudioManager.play_sfx(self, "click")
	if city_manager:
		city_manager.set_tool(final_mode)

	for m in tool_buttons:
		var btn: Button = tool_buttons[m]
		var is_sel: bool = (m == final_mode)
		var sb: StyleBoxFlat = UIThemeHelper.make_panel_style(is_sel, 12, 8.0, 6.0, 0.96 if is_sel else 0.88)
		if is_sel:
			sb.bg_color = Color(0.20, 0.22, 0.30, 0.98)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)

	_refresh_category_highlights()
	if btn_rotate_preview and city_manager:
		btn_rotate_preview.visible = city_manager._is_rotatable_tool(final_mode) or (city_manager.moving_from_pos != Vector2i(-1, -1))

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
	if photo_helper and photo_helper.active:
		return
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

	label_power.text = "%d/%d" % [data.power_used, data.power_supply]
	if data.power_used > data.power_supply:
		label_power.modulate = Color(1.0, 0.3, 0.3)
	else:
		label_power.modulate = Color(0.9, 0.9, 0.9)

	label_water.text = "%d/%d" % [data.water_used, data.water_supply]
	if data.water_used > data.water_supply:
		label_water.modulate = Color(1.0, 0.3, 0.3)
	else:
		label_water.modulate = Color(0.9, 0.9, 0.9)

	label_date.text = "Bln %d Th %d • %s • %02d:00" % [data.month, data.year, data.city_level, int(data.waktu_jam)]
	_update_weather_icon(data.cuaca_saat_ini)
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
		var cid: String = str(c_info.get("id", ""))
		var wish_line := ""
		if city_manager and city_manager.city_data and city_manager.city_data.keinginan_warga.has(cid):
			var w: Dictionary = city_manager.city_data.keinginan_warga[cid]
			var w_status := "Terpenuhi!" if bool(w.get("fulfilled", false)) else "Belum terpenuhi"
			wish_line = "\nKeinginan: %s (%s)" % [str(w.get("text", "-")), w_status]
		if not history.is_empty():
			label_cp_history.text = "Catatan: \"" + history[0] + "\"" + wish_line
		else:
			label_cp_history.text = "Catatan: Warga biasa yang taat aturan." + wish_line

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
	var w_total := data.keinginan_warga.size()
	var w_done := 0
	var w_counts := {}
	for k in data.keinginan_warga.keys():
		var wd: Dictionary = data.keinginan_warga[k]
		if bool(wd.get("fulfilled", false)):
			w_done += 1
		var wt: String = str(wd.get("text", ""))
		w_counts[wt] = int(w_counts.get(wt, 0)) + 1
	var top_wishes := ""
	var shown_w := 0
	for wt in w_counts.keys():
		if shown_w >= 3:
			break
		top_wishes += (", " if shown_w > 0 else "") + wt
		shown_w += 1
	th_stats_label.text = "Popularitas: %d%%  |  Kebahagiaan: %d%%  |  Kas: Rp %s\nKeinginan Warga: %d terpenuhi / %d total (%s)" % [
		int(round(data.popularity)),
		int(round(data.happiness)),
		_format_number(data.money),
		w_done,
		w_total,
		top_wishes if not top_wishes.is_empty() else "-"
	]

	# Bersihkan daftar kartu lama
	for child in th_complaints_container.get_children():
		child.queue_free()

	var has_items := false

	# 0. Kartu Insiden Aktif (Kebakaran / Kemalingan / Kerusuhan / Demo)
	if not data.insiden_aktif.is_empty():
		has_items = true
		var inc_title: String = str(data.insiden_aktif.get("title", "Insiden"))
		var inc_pos: Vector2i = data.insiden_aktif.get("pos", Vector2i(0, 0))
		var inc_status: String = str(data.insiden_aktif.get("status", "Aktif"))
		var inc_action := func():
			townhall_modal.visible = false
			_open_incident_dialog()
		var inc_card := _create_complaint_card(
			"INSIDEN: %s" % inc_title,
			"Blok (%d, %d)" % [inc_pos.x, inc_pos.y],
			"Butuh penanganan unit darurat / keputusan Walikota!",
			inc_status,
			Color(0.96, 0.30, 0.25),
			[
				{
					"title": "Tangani / Kirim Unit",
					"action": inc_action
				}
			]
		)
		th_complaints_container.add_child(inc_card)

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
	for p_name in ["RightPanel", "TimeSpeedPanel", "TaxPanel", "FarmPanel", "BottomPalette"]:
		var p_node := get_node_or_null(p_name) as PanelContainer
		if p_node:
			p_node.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(false, 16, 12.0, 8.0, 0.92))

	var top_panel := get_node_or_null("TopPanel") as PanelContainer
	if top_panel:
		top_panel.anchor_left = 0.0
		top_panel.anchor_right = 1.0
		top_panel.offset_left = 8.0
		top_panel.offset_right = -8.0
		top_panel.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(false, 14, 6.0, 4.0, 0.92))

	var top_hbox := get_node_or_null("TopPanel/HBox") as HBoxContainer
	if not top_hbox:
		return

	top_hbox.add_theme_constant_override("separation", 3)
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	for child in top_hbox.get_children():
		if child is VSeparator:
			child.visible = false

	var icon_map := {
		"LabelMoney": "money",
		"LabelPop": "pop",
		"LabelHappiness": "happy",
		"LabelPopularity": "pop",
		"LabelPower": "power",
		"LabelWater": "water",
		"LabelDate": "date"
	}
	var chip_style: StyleBoxFlat = UIThemeHelper.make_chip_style()
	chip_style.content_margin_left = 6.0
	chip_style.content_margin_right = 6.0
	chip_style.content_margin_top = 3.0
	chip_style.content_margin_bottom = 3.0
	for lbl in [label_money, label_pop, label_happiness, label_popularity, label_power, label_water, label_date, label_tier]:
		if not lbl or not is_instance_valid(lbl):
			continue
		lbl.add_theme_font_size_override("font_size", 12)
		var idx: int = lbl.get_index()
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", chip_style)
		var chbox := HBoxContainer.new()
		chbox.add_theme_constant_override("separation", 3)
		chip.add_child(chbox)
		if icon_map.has(lbl.name):
			var ic := S1VisualBuilder.StatIcon.new(icon_map[lbl.name])
			chbox.add_child(ic)
			if lbl.name == "LabelDate":
				weather_icon = S1VisualBuilder.StatIcon.new("sun")
				chbox.add_child(weather_icon)
		top_hbox.remove_child(lbl)
		chbox.add_child(lbl)
		top_hbox.add_child(chip)
		top_hbox.move_child(chip, idx)
		if lbl == label_tier:
			chip.visible = false

	if btn_townhall:
		btn_townhall.custom_minimum_size = Vector2(82, 28)
		btn_townhall.add_theme_font_size_override("font_size", 11)

	if btn_sell_wheat:
		UIThemeHelper.apply_btn_primary(btn_sell_wheat, 40.0)

	# Chip Keamanan (0-100) di TopPanel
	if not label_security:
		label_security = Label.new()
		label_security.name = "LabelSecurity"
		label_security.text = "Aman: 50%"
		label_security.add_theme_font_size_override("font_size", 12)
		var sec_chip := PanelContainer.new()
		sec_chip.add_theme_stylebox_override("panel", chip_style)
		var sch := HBoxContainer.new()
		sch.add_theme_constant_override("separation", 3)
		sch.add_child(S1VisualBuilder.StatIcon.new("security"))
		sch.add_child(label_security)
		sec_chip.add_child(sch)
		top_hbox.add_child(sec_chip)
		var pop_chip: Node = label_popularity.get_parent().get_parent()
		if pop_chip and pop_chip.get_parent() == top_hbox:
			top_hbox.move_child(sec_chip, pop_chip.get_index() + 1)

func _setup_utility_buttons() -> void:
	var palette := get_node_or_null("BottomPalette") as PanelContainer
	var hbox := get_node_or_null("BottomPalette/HBox") as HBoxContainer
	if not palette or not hbox:
		return

	# Sesuaikan lebar BottomPalette agar 6 kategori + tombol Bawah Tanah muat tanpa scroll di 1280x720
	palette.offset_left = -540.0
	palette.offset_right = 540.0
	palette.offset_top = -70.0
	palette.offset_bottom = -8.0

	btn_power_cable = Button.new()
	btn_power_cable.name = "BtnPowerCable"
	btn_power_cable.text = "Kabel\nRp 1.000"
	btn_power_cable.custom_minimum_size = Vector2(90, 44)
	btn_power_cable.add_theme_font_size_override("font_size", 11)
	tool_buttons[CityManager.ToolMode.POWER_CABLE] = btn_power_cable

	btn_water_pipe = Button.new()
	btn_water_pipe.name = "BtnWaterPipe"
	btn_water_pipe.text = "Pipa\nRp 1.000"
	btn_water_pipe.custom_minimum_size = Vector2(90, 44)
	btn_water_pipe.add_theme_font_size_override("font_size", 11)
	tool_buttons[CityManager.ToolMode.WATER_PIPE] = btn_water_pipe

	var pub_specs := [
		{"name": "BtnSchool", "label": "Sekolah", "price_txt": "Rp75rb", "mode": CityManager.ToolMode.SCHOOL, "tile_type": CityData.TileType.SCHOOL, "cost": CityData.COST_SCHOOL, "cat": "publik"},
		{"name": "BtnClinic", "label": "Puskesmas", "price_txt": "Rp60rb", "mode": CityManager.ToolMode.CLINIC, "tile_type": CityData.TileType.CLINIC, "cost": CityData.COST_CLINIC, "cat": "publik"},
		{"name": "BtnHospital", "label": "Rumah Sakit", "price_txt": "Rp250rb", "mode": CityManager.ToolMode.HOSPITAL, "tile_type": CityData.TileType.HOSPITAL, "cost": CityData.COST_HOSPITAL, "cat": "publik"},
		{"name": "BtnPolice", "label": "Polisi", "price_txt": "Rp100rb", "mode": CityManager.ToolMode.POLICE, "tile_type": CityData.TileType.POLICE, "cost": CityData.COST_POLICE, "cat": "publik"},
		{"name": "BtnMilitary", "label": "Markas TNI", "price_txt": "Rp200rb", "mode": CityManager.ToolMode.MILITARY, "tile_type": CityData.TileType.MILITARY, "cost": CityData.COST_MILITARY, "cat": "publik"},
		{"name": "BtnMayorOffice", "label": "Ktr Walikota", "price_txt": "Rp150rb", "mode": CityManager.ToolMode.MAYOR_OFFICE, "tile_type": CityData.TileType.MAYOR_OFFICE, "cost": CityData.COST_MAYOR_OFFICE, "cat": "publik"},
		{"name": "BtnFireStation", "label": "Damkar", "price_txt": "Rp120rb", "mode": CityManager.ToolMode.FIRE_STATION, "tile_type": CityData.TileType.FIRE_STATION, "cost": CityData.COST_FIRE_STATION, "cat": "publik"},
		{"name": "BtnZoneMilitary", "label": "Z. Militer", "price_txt": "Rp2rb", "mode": CityManager.ToolMode.ZONE_MILITARY, "tile_type": CityData.TileType.ZONE_MILITARY, "cost": CityData.COST_ZONE_MILITARY, "cat": "zona"},
		{"name": "BtnTrainStation", "label": "Stasiun", "price_txt": "Rp150rb", "mode": CityManager.ToolMode.TRAIN_STATION, "tile_type": CityData.TileType.TRAIN_STATION, "cost": CityData.COST_TRAIN_STATION, "cat": "transport"},
		{"name": "BtnRail", "label": "Rel Kereta", "price_txt": "Rp3rb", "mode": CityManager.ToolMode.RAIL, "tile_type": CityData.TileType.RAIL, "cost": CityData.COST_RAIL, "cat": "transport"},
		{"name": "BtnStopAngkot", "label": "Hlt Angkot", "price_txt": "Rp10rb", "mode": CityManager.ToolMode.STOP_ANGKOT, "tile_type": CityData.TileType.STOP_ANGKOT, "cost": CityData.COST_STOP_ANGKOT, "cat": "transport"},
		{"name": "BtnStopBus", "label": "Hlt Bus", "price_txt": "Rp15rb", "mode": CityManager.ToolMode.STOP_BUS, "tile_type": CityData.TileType.STOP_BUS, "cost": CityData.COST_STOP_BUS, "cat": "transport"},
		{"name": "BtnBuswayLane", "label": "Jlr Busway", "price_txt": "Rp8rb", "mode": CityManager.ToolMode.BUSWAY_LANE, "tile_type": CityData.TileType.BUSWAY_LANE, "cost": CityData.COST_BUSWAY_LANE, "cat": "transport"},
		{"name": "BtnStopBusway", "label": "Hlt Busway", "price_txt": "Rp25rb", "mode": CityManager.ToolMode.STOP_BUSWAY, "tile_type": CityData.TileType.STOP_BUSWAY, "cost": CityData.COST_STOP_BUSWAY, "cat": "transport"},
		{"name": "BtnWidenRoad", "label": "Lebarin Jln", "price_txt": "Rp3rb", "mode": CityManager.ToolMode.WIDEN_ROAD, "tile_type": CityData.TileType.ROAD, "cost": CityData.COST_WIDEN_ROAD, "cat": "jalan"},
		{"name": "BtnFlyover", "label": "Flyover", "price_txt": "Rp20rb", "mode": CityManager.ToolMode.FLYOVER, "tile_type": CityData.TileType.FLYOVER, "cost": CityData.COST_FLYOVER, "cat": "jalan"},
		{"name": "BtnRunway", "label": "Landasan", "price_txt": "Rp5rb", "mode": CityManager.ToolMode.RUNWAY, "tile_type": CityData.TileType.RUNWAY, "cost": CityData.COST_RUNWAY, "cat": "transport"},
		{"name": "BtnTerminal", "label": "Terminal", "price_txt": "Rp300rb", "mode": CityManager.ToolMode.AIRPORT_TERMINAL, "tile_type": CityData.TileType.AIRPORT_TERMINAL, "cost": CityData.COST_AIRPORT_TERMINAL, "cat": "transport"}
	]
	public_tool_defs.clear()
	var extra_cat_btns := {}
	for spec in pub_specs:
		var b := Button.new()
		b.name = spec["name"]
		b.text = "%s\n%s" % [spec["label"], spec["price_txt"]]
		b.custom_minimum_size = Vector2(102, 46)
		b.add_theme_font_size_override("font_size", 11)
		var m_val: CityManager.ToolMode = spec["mode"]
		b.pressed.connect(func(): _select_tool(m_val))
		tool_buttons[m_val] = b
		tool_to_category[m_val] = spec["cat"]
		if not extra_cat_btns.has(spec["cat"]):
			extra_cat_btns[spec["cat"]] = []
		extra_cat_btns[spec["cat"]].append(b)
		public_tool_defs.append({
			"btn": b,
			"label": spec["label"],
			"price_txt": spec["price_txt"],
			"tile_type": spec["tile_type"],
			"cost": spec["cost"]
		})

	# Petakan tool bawaan ke kategori masing-masing
	tool_to_category[CityManager.ToolMode.ROAD] = "jalan"
	tool_to_category[CityManager.ToolMode.BULLDOZER] = "jalan"
	tool_to_category[CityManager.ToolMode.ZONE_R] = "zona"
	tool_to_category[CityManager.ToolMode.ZONE_C] = "zona"
	tool_to_category[CityManager.ToolMode.ZONE_I] = "zona"
	tool_to_category[CityManager.ToolMode.POWER_PLANT] = "utilitas"
	tool_to_category[CityManager.ToolMode.WATER_TOWER] = "utilitas"
	tool_to_category[CityManager.ToolMode.POWER_CABLE] = "utilitas"
	tool_to_category[CityManager.ToolMode.WATER_PIPE] = "utilitas"
	tool_to_category[CityManager.ToolMode.PARK] = "taman"
	tool_to_category[CityManager.ToolMode.FARM] = "taman"

	# Buat panel popup kategori di atas BottomPalette
	category_popup = PanelContainer.new()
	category_popup.name = "CategoryPopup"
	category_popup.visible = false
	category_popup.anchor_left = 0.5
	category_popup.anchor_right = 0.5
	category_popup.anchor_top = 1.0
	category_popup.anchor_bottom = 1.0
	category_popup.offset_top = -180.0
	category_popup.offset_bottom = -78.0
	category_popup.grow_horizontal = Control.GROW_DIRECTION_BOTH
	category_popup.grow_vertical = Control.GROW_DIRECTION_BEGIN
	category_popup.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(true, 16, 12.0, 10.0, 0.96))
	add_child(category_popup)

	var popup_wrap := VBoxContainer.new()
	popup_wrap.add_theme_constant_override("separation", 6)
	category_popup.add_child(popup_wrap)

	var cat_defs := [
		{"id": "jalan", "title": "Jalan", "w": 115},
		{"id": "zona", "title": "Zona", "w": 115},
		{"id": "utilitas", "title": "Utilitas", "w": 115},
		{"id": "publik", "title": "Layanan Publik", "w": 145},
		{"id": "transport", "title": "Transportasi", "w": 135},
		{"id": "taman", "title": "Taman & Alam", "w": 135}
	]

	for cd in cat_defs:
		var cid: String = cd["id"]
		var grid := GridContainer.new()
		grid.columns = 6 if cid == "transport" else (4 if cid in ["jalan", "zona", "utilitas", "publik"] else 2)
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		grid.visible = false
		popup_wrap.add_child(grid)
		category_containers[cid] = grid

	# Pindahkan tombol bawaan dari BottomPalette/HBox ke container kategorinya
	var move_pairs := [
		[btn_road, "jalan"], [btn_bulldozer, "jalan"],
		[btn_zone_r, "zona"], [btn_zone_c, "zona"], [btn_zone_i, "zona"],
		[btn_power, "utilitas"], [btn_water, "utilitas"], [btn_power_cable, "utilitas"], [btn_water_pipe, "utilitas"],
		[btn_park, "taman"], [btn_farm, "taman"]
	]
	for mp in move_pairs:
		var b_node: Button = mp[0]
		var target_cid: String = mp[1]
		if b_node and b_node.get_parent():
			b_node.get_parent().remove_child(b_node)
		if b_node:
			b_node.custom_minimum_size = Vector2(102, 46)
			b_node.add_theme_font_size_override("font_size", 11)
			category_containers[target_cid].add_child(b_node)

	for cid in extra_cat_btns.keys():
		for b_node in extra_cat_btns[cid]:
			category_containers[cid].add_child(b_node)

	# Urutkan ulang Jalan: Jalan, Lebarin Jln, Flyover, Bulldozer
	var g_jalan: GridContainer = category_containers["jalan"]
	g_jalan.move_child(btn_bulldozer, g_jalan.get_child_count() - 1)

	# Tombol beli armada di kategori Transportasi
	var buy_specs := [
		{"name": "BtnBuyKopaja", "text": "+Kopaja\nRp80rb", "fn": func(): if city_manager: city_manager.buy_kopaja_bus()},
		{"name": "BtnBuyBusway", "text": "+Busway\nRp120rb", "fn": func(): if city_manager: city_manager.buy_busway_unit()},
		{"name": "BtnBuyPlane", "text": "+Pesawat\nRp200rb", "fn": func(): if city_manager: city_manager.buy_airplane()}
	]
	for bsp in buy_specs:
		var bb := Button.new()
		bb.name = bsp["name"]
		bb.text = bsp["text"]
		bb.custom_minimum_size = Vector2(102, 46)
		bb.add_theme_font_size_override("font_size", 11)
		UIThemeHelper.apply_btn_secondary(bb, 46.0)
		bb.pressed.connect(bsp["fn"])
		category_containers["transport"].add_child(bb)

	# Isi BottomPalette/HBox dengan 6 tombol kategori + toggle Bawah Tanah
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	category_buttons.clear()
	for cd in cat_defs:
		var cid: String = cd["id"]
		var cb := Button.new()
		cb.text = cd["title"]
		cb.custom_minimum_size = Vector2(cd["w"], 44)
		cb.add_theme_font_size_override("font_size", 13)
		UIThemeHelper.apply_btn_secondary(cb, 44.0)
		cb.pressed.connect(func(): _toggle_category(cid))
		hbox.add_child(cb)
		category_buttons[cid] = cb

	btn_underground = Button.new()
	btn_underground.name = "BtnUnderground"
	btn_underground.toggle_mode = true
	btn_underground.text = "Bawah Tanah"
	btn_underground.custom_minimum_size = Vector2(120, 44)
	btn_underground.add_theme_font_size_override("font_size", 12)
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

	_setup_rotate_move_controls()
	_setup_building_info_modal()
	_setup_farm_info_modal()
	_setup_event_modal()
	_setup_stats_modal()
	_setup_photo_mode()

func _toggle_category(cid: String) -> void:
	AudioManager.play_sfx(self, "click")
	if open_category_id == cid and category_popup.visible:
		_close_category_popup()
		return
	open_category_id = cid
	for k in category_containers.keys():
		category_containers[k].visible = (k == cid)
	category_popup.visible = true
	_refresh_category_highlights()

func _close_category_popup() -> void:
	if category_popup:
		category_popup.visible = false
	open_category_id = ""
	_refresh_category_highlights()

func _refresh_category_highlights() -> void:
	var active_cat: String = str(tool_to_category.get(city_manager.current_tool if city_manager else CityManager.ToolMode.ROAD, ""))
	for cid in category_buttons.keys():
		var cb: Button = category_buttons[cid]
		var is_hl: bool = (cid == open_category_id) or (cid == active_cat)
		if is_hl:
			UIThemeHelper.apply_btn_primary(cb, 44.0)
		else:
			UIThemeHelper.apply_btn_secondary(cb, 44.0)

func _setup_rotate_move_controls() -> void:
	var ctrl_box := HBoxContainer.new()
	ctrl_box.anchor_left = 1.0
	ctrl_box.anchor_top = 1.0
	ctrl_box.anchor_right = 1.0
	ctrl_box.anchor_bottom = 1.0
	ctrl_box.offset_left = -250.0
	ctrl_box.offset_top = -124.0
	ctrl_box.offset_right = -14.0
	ctrl_box.offset_bottom = -80.0
	ctrl_box.alignment = BoxContainer.ALIGNMENT_END
	ctrl_box.add_theme_constant_override("separation", 8)
	add_child(ctrl_box)

	btn_rotate_preview = Button.new()
	btn_rotate_preview.text = "Putar (R)"
	btn_rotate_preview.visible = false
	btn_rotate_preview.custom_minimum_size = Vector2(105, 38)
	UIThemeHelper.apply_btn_primary(btn_rotate_preview, 38.0)
	btn_rotate_preview.pressed.connect(func():
		if city_manager:
			city_manager.rotate_preview()
	)
	ctrl_box.add_child(btn_rotate_preview)

	btn_cancel_move = Button.new()
	btn_cancel_move.text = "Batal (Esc)"
	btn_cancel_move.visible = false
	btn_cancel_move.custom_minimum_size = Vector2(105, 38)
	UIThemeHelper.apply_btn_secondary(btn_cancel_move, 38.0)
	btn_cancel_move.pressed.connect(func():
		if city_manager:
			city_manager.cancel_move_building()
	)
	ctrl_box.add_child(btn_cancel_move)

func _on_move_mode_changed(active: bool) -> void:
	if btn_cancel_move:
		btn_cancel_move.visible = active
	if btn_rotate_preview and city_manager:
		btn_rotate_preview.visible = active or city_manager._is_rotatable_tool(city_manager.current_tool)

func _setup_building_info_modal() -> void:
	building_info_modal = PanelContainer.new()
	building_info_modal.visible = false
	building_info_modal.set_anchors_preset(Control.PRESET_CENTER)
	building_info_modal.custom_minimum_size = Vector2(360, 0)
	building_info_modal.offset_left = -180.0
	building_info_modal.offset_top = -110.0
	building_info_modal.offset_right = 180.0
	building_info_modal.offset_bottom = 110.0
	building_info_modal.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(true, 16, 18.0, 14.0, 0.96))
	add_child(building_info_modal)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	building_info_modal.add_child(vb)

	lbl_bi_title = Label.new()
	lbl_bi_title.add_theme_font_size_override("font_size", 17)
	lbl_bi_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.28))
	vb.add_child(lbl_bi_title)

	lbl_bi_info = Label.new()
	lbl_bi_info.add_theme_font_size_override("font_size", 13)
	vb.add_child(lbl_bi_info)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	vb.add_child(hb)

	btn_bi_rotate = Button.new()
	btn_bi_rotate.text = "Putar 90°"
	UIThemeHelper.apply_btn_primary(btn_bi_rotate, 38.0)
	btn_bi_rotate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_bi_rotate.pressed.connect(func():
		if city_manager and _selected_building_pos != Vector2i(-1, -1):
			city_manager.rotate_building_at(_selected_building_pos)
			var t := city_manager.city_data.get_tile(_selected_building_pos.x, _selected_building_pos.y)
			_update_building_info_text(t)
	)
	hb.add_child(btn_bi_rotate)

	btn_bi_move = Button.new()
	btn_bi_move.text = "Pindah"
	UIThemeHelper.apply_btn_secondary(btn_bi_move, 38.0)
	btn_bi_move.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_bi_move.pressed.connect(func():
		building_info_modal.visible = false
		if city_manager and _selected_building_pos != Vector2i(-1, -1):
			city_manager.start_move_building(_selected_building_pos)
	)
	hb.add_child(btn_bi_move)

	btn_bi_townhall = Button.new()
	btn_bi_townhall.text = "Buka Balai Kota"
	UIThemeHelper.apply_btn_secondary(btn_bi_townhall, 38.0)
	btn_bi_townhall.visible = false
	btn_bi_townhall.pressed.connect(func():
		building_info_modal.visible = false
		open_townhall_dialog()
	)
	vb.add_child(btn_bi_townhall)

	var btn_close := Button.new()
	btn_close.text = "Tutup"
	UIThemeHelper.apply_btn_secondary(btn_close, 36.0)
	btn_close.pressed.connect(func(): building_info_modal.visible = false)
	vb.add_child(btn_close)

func _open_building_info_dialog(tile_pos: Vector2i, tile_info: Dictionary) -> void:
	if not building_info_modal:
		return
	_selected_building_pos = tile_pos
	lbl_bi_title.text = "Info Bangunan (%d, %d)" % [tile_pos.x, tile_pos.y]
	_update_building_info_text(tile_info)
	btn_bi_move.visible = CityManager.is_movable_building(tile_info)
	var tp: int = tile_info.get("type", CityData.TileType.EMPTY)
	btn_bi_townhall.visible = (tp == CityData.TileType.TOWNHALL or tp == CityData.TileType.MAYOR_OFFICE)
	building_info_modal.visible = true

func _update_building_info_text(tile_info: Dictionary) -> void:
	var rot: int = int(tile_info.get("rotation", 0))
	var util_txt: String = "Aktif" if tile_info.get("has_utility", true) else "Kurang Listrik/Air!"
	lbl_bi_info.text = "Arah hadap: %d°  |  Utilitas: %s" % [rot, util_txt]

func _setup_farm_info_modal() -> void:
	farm_info_modal = PanelContainer.new()
	farm_info_modal.visible = false
	farm_info_modal.set_anchors_preset(Control.PRESET_CENTER)
	farm_info_modal.custom_minimum_size = Vector2(360, 0)
	farm_info_modal.offset_left = -180.0
	farm_info_modal.offset_top = -125.0
	farm_info_modal.offset_right = 180.0
	farm_info_modal.offset_bottom = 125.0
	farm_info_modal.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(true, 16, 18.0, 14.0, 0.96))
	add_child(farm_info_modal)

	var vb: VBoxContainer = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	farm_info_modal.add_child(vb)

	lbl_fi_title = Label.new()
	lbl_fi_title.text = "Lahan Gandum"
	lbl_fi_title.add_theme_font_size_override("font_size", 18)
	lbl_fi_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.28))
	vb.add_child(lbl_fi_title)

	lbl_fi_status = Label.new()
	lbl_fi_status.add_theme_font_size_override("font_size", 14)
	vb.add_child(lbl_fi_status)

	lbl_fi_warehouse = Label.new()
	lbl_fi_warehouse.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_fi_warehouse.add_theme_font_size_override("font_size", 12)
	lbl_fi_warehouse.add_theme_color_override("font_color", Color(0.80, 0.84, 0.90))
	vb.add_child(lbl_fi_warehouse)

	btn_fi_harvest = Button.new()
	btn_fi_harvest.text = "Panen"
	UIThemeHelper.apply_btn_primary(btn_fi_harvest, 44.0)
	btn_fi_harvest.pressed.connect(func():
		if city_manager and _selected_farm_pos != Vector2i(-1, -1):
			if city_manager.harvest_farm_at(_selected_farm_pos.x, _selected_farm_pos.y):
				farm_info_modal.visible = false
	)
	vb.add_child(btn_fi_harvest)

	lbl_fi_reason = Label.new()
	lbl_fi_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_fi_reason.add_theme_font_size_override("font_size", 12)
	lbl_fi_reason.add_theme_color_override("font_color", Color(0.70, 0.74, 0.80))
	vb.add_child(lbl_fi_reason)

	var hb: HBoxContainer = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	vb.add_child(hb)

	var btn_del: Button = Button.new()
	btn_del.text = "Hapus Lahan"
	btn_del.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIThemeHelper.apply_btn_secondary(btn_del, 36.0)
	btn_del.pressed.connect(func():
		if city_manager and _selected_farm_pos != Vector2i(-1, -1):
			city_manager.bulldoze_farm_at(_selected_farm_pos.x, _selected_farm_pos.y)
		farm_info_modal.visible = false
	)
	hb.add_child(btn_del)

	var btn_close: Button = Button.new()
	btn_close.text = "Tutup"
	btn_close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIThemeHelper.apply_btn_secondary(btn_close, 36.0)
	btn_close.pressed.connect(func(): farm_info_modal.visible = false)
	hb.add_child(btn_close)

func _open_farm_info_dialog(tile_pos: Vector2i, tile_info: Dictionary) -> void:
	if not farm_info_modal or not city_manager or not city_manager.city_data:
		return
	_selected_farm_pos = tile_pos
	var lv: int = int(tile_info.get("level", 1))
	lbl_fi_title.text = "Lahan Gandum (%d, %d)" % [tile_pos.x, tile_pos.y]
	if lv >= 3:
		lbl_fi_status.text = "Siap Panen!"
		btn_fi_harvest.disabled = false
		lbl_fi_reason.visible = false
	elif lv == 2:
		lbl_fi_status.text = "Tumbuh — siap panen dalam 1 bulan"
		btn_fi_harvest.disabled = true
		lbl_fi_reason.text = "Belum siap — 1 bulan lagi"
		lbl_fi_reason.visible = true
	else:
		lbl_fi_status.text = "Benih — siap panen dalam 2 bulan"
		btn_fi_harvest.disabled = true
		lbl_fi_reason.text = "Belum siap — 2 bulan lagi"
		lbl_fi_reason.visible = true
	var d: CityData = city_manager.city_data
	lbl_fi_warehouse.text = "Gudang: %d unit gandum — harga jual saat ini Rp %s/unit" % [d.wheat_inventory, _format_number(d.wheat_price)]
	farm_info_modal.visible = true

func _on_time_weather_updated(month: int, year: int, jam: float, cuaca: String) -> void:
	if photo_helper and photo_helper.active:
		return
	if label_date:
		label_date.text = "Bln %d Th %d • %02d:00" % [month, year, int(jam)]
	_update_weather_icon(cuaca)

func _update_weather_icon(cuaca: String) -> void:
	if not weather_icon:
		return
	var target_icon := "sun"
	if cuaca == "berawan":
		target_icon = "cloud"
	elif cuaca == "hujan":
		target_icon = "rain"
	if weather_icon.icon_type != target_icon:
		weather_icon.icon_type = target_icon
		weather_icon.queue_redraw()

func _setup_event_modal() -> void:
	var top_hbox := get_node_or_null("TopPanel/HBox") as HBoxContainer
	if top_hbox and btn_townhall:
		var btn_ev := Button.new()
		btn_ev.name = "BtnEvent"
		btn_ev.text = "Event"
		btn_ev.custom_minimum_size = Vector2(46, 28)
		btn_ev.add_theme_font_size_override("font_size", 11)
		UIThemeHelper.apply_btn_secondary(btn_ev, 28.0)
		btn_ev.pressed.connect(_open_event_modal)
		top_hbox.add_child(btn_ev)
		top_hbox.move_child(btn_ev, btn_townhall.get_index())

	event_modal = PanelContainer.new()
	event_modal.visible = false
	event_modal.set_anchors_preset(Control.PRESET_CENTER)
	event_modal.offset_left = -220.0
	event_modal.offset_top = -150.0
	event_modal.offset_right = 220.0
	event_modal.offset_bottom = 150.0
	event_modal.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(true, 16, 18.0, 14.0, 0.96))
	add_child(event_modal)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	event_modal.add_child(vb)

	var title := Label.new()
	title.text = "Kalender Event Kota"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.28))
	vb.add_child(title)

	lbl_event_info = Label.new()
	lbl_event_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_event_info.add_theme_font_size_override("font_size", 13)
	vb.add_child(lbl_event_info)

	var btn_close := Button.new()
	btn_close.text = "Tutup"
	UIThemeHelper.apply_btn_secondary(btn_close, 36.0)
	btn_close.pressed.connect(func(): event_modal.visible = false)
	vb.add_child(btn_close)

func _open_event_modal() -> void:
	if not event_modal or not city_manager or not city_manager.city_data:
		return
	var d := city_manager.city_data
	var cur_txt := "Tidak ada event berjalan" if d.event_aktif.is_empty() else "%s (%d bln tersisa)" % [str(d.event_aktif.get("title", "")), int(d.event_aktif.get("months_left", 1))]
	var next_txt := "Sedang berlangsung" if not d.event_aktif.is_empty() else "Perkiraan %d bulan lagi" % maxi(1, d.event_cooldown)
	var hist_lines := ""
	for i in range(mini(3, d.riwayat_event.size())):
		hist_lines += "\n- %s" % str(d.riwayat_event[i])
	if hist_lines.is_empty():
		hist_lines = "\n- Belum ada riwayat event"
	lbl_event_info.text = "Event Berjalan: %s\nEvent Berikutnya: %s\n\n3 Riwayat Terakhir:%s" % [cur_txt, next_txt, hist_lines]
	event_modal.visible = true

class StatsLineChart extends Control:
	var values: Array = []

	func _init(p_vals: Array) -> void:
		values = p_vals
		custom_minimum_size = Vector2(460, 72)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.10, 0.15, 0.85))
		if values.is_empty():
			draw_string(ThemeDB.fallback_font, Vector2(12, 40), "Belum ada data bulanan", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.65, 0.68, 0.74))
			return
		var min_v: float = float(values[0])
		var max_v: float = float(values[0])
		for v in values:
			min_v = minf(min_v, float(v))
			max_v = maxf(max_v, float(v))
		var span: float = maxf(1.0, max_v - min_v)
		var pad_x: float = 14.0
		var pad_y: float = 10.0
		var w: float = size.x - pad_x * 2.0
		var h: float = size.y - pad_y * 2.0
		var pts: Array[Vector2] = []
		var n: int = values.size()
		for i in range(n):
			var x: float = pad_x + (w * float(i) / float(maxi(1, n - 1))) if n > 1 else pad_x + w * 0.5
			var y: float = pad_y + h - ((float(values[i]) - min_v) / span) * h
			pts.append(Vector2(x, y))
		var line_col := Color(0.32, 0.88, 0.45)
		if n >= 2 and float(values[n - 1]) < float(values[n - 2]):
			line_col = Color(0.95, 0.35, 0.35)
		for i in range(pts.size() - 1):
			draw_line(pts[i], pts[i + 1], line_col, 2.2)
		for pt in pts:
			draw_circle(pt, 3.5, line_col)

func _setup_stats_modal() -> void:
	var top_hbox := get_node_or_null("TopPanel/HBox") as HBoxContainer
	if top_hbox and btn_townhall:
		var btn_st := Button.new()
		btn_st.name = "BtnStats"
		btn_st.text = "Stat"
		btn_st.custom_minimum_size = Vector2(42, 28)
		btn_st.add_theme_font_size_override("font_size", 11)
		UIThemeHelper.apply_btn_secondary(btn_st, 28.0)
		btn_st.pressed.connect(_open_stats_modal)
		top_hbox.add_child(btn_st)
		top_hbox.move_child(btn_st, btn_townhall.get_index())

	stats_backdrop = ColorRect.new()
	stats_backdrop.visible = false
	stats_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	stats_backdrop.color = Color(0.0, 0.0, 0.0, 0.45)
	stats_backdrop.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_close_stats_modal()
	)
	add_child(stats_backdrop)

	stats_modal = PanelContainer.new()
	stats_modal.visible = false
	stats_modal.set_anchors_preset(Control.PRESET_CENTER)
	stats_modal.offset_left = -280.0
	stats_modal.offset_top = -230.0
	stats_modal.offset_right = 280.0
	stats_modal.offset_bottom = 230.0
	stats_modal.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(true, 16, 16.0, 14.0, 0.96))
	add_child(stats_modal)

	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 8)
	stats_modal.add_child(wrap)

	var hdr := HBoxContainer.new()
	var ttl := Label.new()
	ttl.text = "Statistik Kota (12 Bulan Terakhir)"
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.add_theme_font_size_override("font_size", 17)
	ttl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.28))
	hdr.add_child(ttl)
	var btn_x := Button.new()
	btn_x.text = "X"
	btn_x.custom_minimum_size = Vector2(36, 30)
	UIThemeHelper.apply_btn_secondary(btn_x, 30.0)
	btn_x.pressed.connect(_close_stats_modal)
	hdr.add_child(btn_x)
	wrap.add_child(hdr)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(510, 360)
	wrap.add_child(scroll)

	stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(stats_vbox)

func _close_stats_modal() -> void:
	if stats_modal:
		stats_modal.visible = false
	if stats_backdrop:
		stats_backdrop.visible = false

func _open_stats_modal() -> void:
	if not stats_modal or not stats_vbox or not city_manager or not city_manager.city_data:
		return
	for ch in stats_vbox.get_children():
		stats_vbox.remove_child(ch)
		ch.queue_free()
	var d := city_manager.city_data
	var hist: Array = d.riwayat_statistik
	var metrics := [
		{"key": "pop", "title": "Populasi", "cur": d.population, "suffix": ""},
		{"key": "money", "title": "Uang Kota", "cur": d.money, "suffix": " Rp"},
		{"key": "happy", "title": "Kebahagiaan", "cur": int(round(d.happiness)), "suffix": "%"},
		{"key": "popu", "title": "Popularitas", "cur": int(round(d.popularity)), "suffix": "%"},
		{"key": "sec", "title": "Keamanan", "cur": int(round(d.security)), "suffix": "%"}
	]
	for mt in metrics:
		var arr: Array = []
		for row in hist:
			arr.append(row.get(mt["key"], 0))
		var chart := StatsLineChart.new(arr)
		stats_vbox.add_child(chart)
		var delta_txt := ""
		if arr.size() >= 2:
			var diff: int = int(arr[arr.size() - 1]) - int(arr[arr.size() - 2])
			delta_txt = " (%s%s dari bulan lalu)" % ["+" if diff >= 0 else "", _format_number(diff) if mt["key"] == "money" else str(diff)]
		var cur_str := ("Rp %s" % _format_number(int(mt["cur"]))) if mt["key"] == "money" else ("%d%s" % [int(mt["cur"]), mt["suffix"]])
		var lbl := Label.new()
		lbl.text = "%s: %s%s" % [mt["title"], cur_str, delta_txt]
		lbl.add_theme_font_size_override("font_size", 12)
		stats_vbox.add_child(lbl)

	var sum_lbl := Label.new()
	sum_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sum_lbl.add_theme_font_size_override("font_size", 12)
	var sum_txt := "Ringkasan 3 Bulan Terakhir:"
	var start_i := maxi(0, hist.size() - 3)
	for i in range(hist.size() - 1, start_i - 1, -1):
		var r: Dictionary = hist[i]
		sum_txt += "\nBln %d Th %d: Pop %d, Uang Rp %s, Senang %d%%, Populer %d%%, Aman %d%%" % [
			int(r.get("month", 1)), int(r.get("year", 1)), int(r.get("pop", 0)),
			_format_number(int(r.get("money", 0))), int(r.get("happy", 0)), int(r.get("popu", 0)), int(r.get("sec", 0))
		]
	if hist.is_empty():
		sum_txt += "\nBelum ada ringkasan bulanan."
	sum_lbl.text = sum_txt
	stats_vbox.add_child(sum_lbl)
	stats_backdrop.visible = true
	stats_modal.visible = true

func _setup_photo_mode() -> void:
	var top_hbox := get_node_or_null("TopPanel/HBox") as HBoxContainer
	var btn_ph := Button.new()
	if top_hbox and btn_townhall:
		var btn_cam := Button.new()
		btn_cam.name = "BtnCamMode"
		var cur_cm: String = city_manager.camera_controller.camera_mode if (city_manager and city_manager.camera_controller) else "theotown"
		btn_cam.text = "Kam: Bebas" if cur_cm == "bebas" else "Kam: Theo"
		btn_cam.custom_minimum_size = Vector2(72, 28)
		btn_cam.add_theme_font_size_override("font_size", 11)
		UIThemeHelper.apply_btn_secondary(btn_cam, 28.0)
		btn_cam.pressed.connect(func():
			if city_manager and city_manager.camera_controller:
				var next_m := "bebas" if city_manager.camera_controller.camera_mode == "theotown" else "theotown"
				city_manager.camera_controller.set_camera_mode(next_m)
				btn_cam.text = "Kam: Bebas" if next_m == "bebas" else "Kam: Theo"
		)
		top_hbox.add_child(btn_cam)
		top_hbox.move_child(btn_cam, btn_townhall.get_index())

		btn_ph.name = "BtnPhotoMode"
		btn_ph.text = "Foto"
		btn_ph.custom_minimum_size = Vector2(42, 28)
		btn_ph.add_theme_font_size_override("font_size", 11)
		UIThemeHelper.apply_btn_secondary(btn_ph, 28.0)
		btn_ph.pressed.connect(func():
			if photo_helper:
				photo_helper.enter_photo_mode()
		)
		top_hbox.add_child(btn_ph)
		top_hbox.move_child(btn_ph, btn_townhall.get_index())

	var hide_list: Array = []
	for p_name in ["TopPanel", "RightPanel", "TimeSpeedPanel", "TaxPanel", "FarmPanel", "BottomPalette", "MissionPanel", "BubbleOverlay", "CategoryPopup", "TouchControls", "CameraRotateBox", "ToastLabel"]:
		var nd: Node = get_node_or_null(p_name)
		if nd:
			hide_list.append(nd)

	photo_helper = PhotoModeHelper.new()
	photo_helper.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(photo_helper)
	photo_helper.setup(hide_list, func() -> Dictionary:
		if not city_manager or not city_manager.city_data:
			return {}
		var d: CityData = city_manager.city_data
		return {
			"tier": d.city_level,
			"pop": d.population,
			"date": "Bln %d Th %d" % [d.month, d.year]
		}
	)
	photo_helper.photo_mode_toggled.connect(func(is_on: bool):
		if is_on:
			_close_category_popup()
			_close_stats_modal()
			if event_modal:
				event_modal.visible = false
			if building_info_modal:
				building_info_modal.visible = false
		if get_tree():
			get_tree().paused = is_on
		if city_manager and city_manager.camera_controller:
			city_manager.camera_controller.process_mode = Node.PROCESS_MODE_ALWAYS if is_on else Node.PROCESS_MODE_INHERIT
	)
	photo_helper.rotate_camera_requested.connect(func():
		if city_manager and city_manager.camera_controller:
			city_manager.camera_controller.yaw = fposmod(city_manager.camera_controller.yaw + 45.0, 360.0)
			city_manager.camera_controller._update_transform()
	)

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
	if photo_helper and photo_helper.active:
		return
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
		elif building_info_modal and building_info_modal.visible:
			building_info_modal.visible = false
		elif farm_info_modal and farm_info_modal.visible:
			farm_info_modal.visible = false
		elif stats_modal and stats_modal.visible:
			_close_stats_modal()
		elif event_modal and event_modal.visible:
			event_modal.visible = false
		elif category_popup and category_popup.visible:
			_close_category_popup()
		elif city_manager and city_manager.current_tool != CityManager.ToolMode.NONE:
			_select_tool(CityManager.ToolMode.NONE)
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

func _setup_unit_and_incident_modals() -> void:
	var top_hbox: HBoxContainer = get_node_or_null("TopPanel/HBox") as HBoxContainer
	if top_hbox and btn_townhall:
		var btn_unit := Button.new()
		btn_unit.name = "BtnUnit"
		btn_unit.text = "Unit"
		btn_unit.custom_minimum_size = Vector2(42, 28)
		btn_unit.add_theme_font_size_override("font_size", 11)
		UIThemeHelper.apply_btn_secondary(btn_unit, 28.0)
		btn_unit.pressed.connect(_open_unit_dialog)
		top_hbox.add_child(btn_unit)
		top_hbox.move_child(btn_unit, btn_townhall.get_index())

	unit_modal = PanelContainer.new()
	unit_modal.name = "UnitModal"
	unit_modal.visible = false
	unit_modal.set_anchors_preset(Control.PRESET_CENTER)
	unit_modal.offset_left = -225.0
	unit_modal.offset_top = -170.0
	unit_modal.offset_right = 225.0
	unit_modal.offset_bottom = 170.0
	unit_modal.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(true, 18, 18.0, 14.0, 0.96))
	add_child(unit_modal)

	var u_wrap := VBoxContainer.new()
	u_wrap.add_theme_constant_override("separation", 8)
	unit_modal.add_child(u_wrap)
	u_wrap.add_child(UIThemeHelper.make_panel_header("Unit Darurat Kota", "warn"))
	u_wrap.add_child(HSeparator.new())
	var u_scroll := ScrollContainer.new()
	u_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	u_wrap.add_child(u_scroll)
	unit_vbox = VBoxContainer.new()
	unit_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unit_vbox.add_theme_constant_override("separation", 6)
	u_scroll.add_child(unit_vbox)
	var btn_u_close := Button.new()
	btn_u_close.text = "Tutup"
	UIThemeHelper.apply_btn_secondary(btn_u_close, 40.0)
	btn_u_close.pressed.connect(func(): unit_modal.visible = false)
	u_wrap.add_child(btn_u_close)

	incident_modal = PanelContainer.new()
	incident_modal.name = "IncidentModal"
	incident_modal.visible = false
	incident_modal.set_anchors_preset(Control.PRESET_CENTER)
	incident_modal.offset_left = -225.0
	incident_modal.offset_top = -175.0
	incident_modal.offset_right = 225.0
	incident_modal.offset_bottom = 175.0
	incident_modal.add_theme_stylebox_override("panel", UIThemeHelper.make_panel_style(true, 18, 18.0, 14.0, 0.96))
	add_child(incident_modal)

	var i_wrap := VBoxContainer.new()
	i_wrap.add_theme_constant_override("separation", 8)
	incident_modal.add_child(i_wrap)
	i_wrap.add_child(UIThemeHelper.make_panel_header("Penanganan Insiden", "warn"))
	i_wrap.add_child(HSeparator.new())
	incident_vbox = VBoxContainer.new()
	incident_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	incident_vbox.add_theme_constant_override("separation", 6)
	i_wrap.add_child(incident_vbox)
	var btn_i_close := Button.new()
	btn_i_close.text = "Tutup"
	UIThemeHelper.apply_btn_secondary(btn_i_close, 40.0)
	btn_i_close.pressed.connect(func(): incident_modal.visible = false)
	i_wrap.add_child(btn_i_close)

func _open_unit_dialog() -> void:
	if not unit_modal:
		return
	unit_modal.visible = true
	_refresh_unit_modal()

func _refresh_unit_modal() -> void:
	if not unit_vbox or not city_manager:
		return
	for ch in unit_vbox.get_children():
		ch.queue_free()
	var em: EmergencyUnitManager = city_manager.emergency_manager
	if not em or em.units.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Belum ada unit darurat.\nBangun Damkar, Kantor Polisi, Puskesmas/RS, atau Markas TNI."
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		unit_vbox.add_child(empty_lbl)
		return
	for u in em.units:
		var lbl := Label.new()
		lbl.text = "• %s (%s) — %s" % [u.kind.capitalize(), u.home_name, u.status]
		lbl.add_theme_font_size_override("font_size", 13)
		unit_vbox.add_child(lbl)
	if not city_manager.city_data.insiden_aktif.is_empty():
		var btn_go := Button.new()
		btn_go.text = "Buka Panel Insiden Aktif"
		UIThemeHelper.apply_btn_primary(btn_go, 42.0)
		btn_go.pressed.connect(func():
			unit_modal.visible = false
			_open_incident_dialog()
		)
		unit_vbox.add_child(btn_go)

func _open_incident_dialog() -> void:
	if not incident_modal:
		return
	incident_modal.visible = true
	_refresh_incident_modal()

func _refresh_incident_modal() -> void:
	if not incident_vbox or not city_manager or not city_manager.city_data:
		return
	for ch in incident_vbox.get_children():
		ch.queue_free()
	var data: CityData = city_manager.city_data
	if data.insiden_aktif.is_empty():
		var none_lbl := Label.new()
		none_lbl.text = "Tidak ada insiden aktif saat ini."
		incident_vbox.add_child(none_lbl)
		return

	var inc: Dictionary = data.insiden_aktif
	var inc_type: String = str(inc.get("type", ""))
	var inc_pos: Vector2i = inc.get("pos", Vector2i(0, 0))
	var em: EmergencyUnitManager = city_manager.emergency_manager
	var req_kind: String = "damkar" if inc_type == "kebakaran" else "polisi"
	var eta_txt: String = em.get_unit_eta_text(req_kind) if em else "-"

	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 13)
	info.text = "Jenis: %s\nLokasi: Blok (%d, %d)\nStatus: %s\nETA Unit: %s" % [
		str(inc.get("title", inc_type)),
		inc_pos.x,
		inc_pos.y,
		str(inc.get("status", "Menunggu")),
		eta_txt
	]
	incident_vbox.add_child(info)

	if inc_type == "kebakaran":
		_add_unit_dispatch_btn("Kirim Damkar", "damkar", 0)
	elif inc_type == "kemalingan":
		_add_unit_dispatch_btn("Kirim Polisi", "polisi", 0)
	elif inc_type == "kerusuhan":
		_add_unit_dispatch_btn("Kirim Polisi (Rp 50.000)", "polisi", 50000)
		if em and em.has_unit_kind("tni"):
			_add_unit_dispatch_btn("Kirim Bantuan TNI", "tni", 0)
	elif inc_type == "demo":
		var btn_dem := Button.new()
		if data.money < 30000:
			btn_dem.text = "Uang kota tidak cukup"
			btn_dem.disabled = true
			UIThemeHelper.apply_btn_secondary(btn_dem, 42.0)
		else:
			btn_dem.text = "Dengarkan Tuntutan (Rp 30.000)"
			UIThemeHelper.apply_btn_primary(btn_dem, 42.0)
			btn_dem.pressed.connect(func():
				city_manager.handle_demo_demands()
				incident_modal.visible = false
			)
		incident_vbox.add_child(btn_dem)
		_add_unit_dispatch_btn("Kirim Polisi Menenangkan", "polisi", 0)

	var btn_ign := Button.new()
	btn_ign.text = "Abaikan"
	UIThemeHelper.apply_btn_secondary(btn_ign, 38.0)
	btn_ign.pressed.connect(func():
		city_manager.ignore_active_incident()
		incident_modal.visible = false
	)
	incident_vbox.add_child(btn_ign)

func _add_unit_dispatch_btn(label_txt: String, kind: String, cost: int) -> void:
	var btn := Button.new()
	var data: CityData = city_manager.city_data
	var em: EmergencyUnitManager = city_manager.emergency_manager
	if cost > 0 and data.money < cost:
		btn.text = "Uang kota tidak cukup"
		btn.disabled = true
		UIThemeHelper.apply_btn_secondary(btn, 42.0)
	elif not em or not em.has_unit_kind(kind):
		if kind == "damkar":
			btn.text = "Bangun Damkar dulu"
		elif kind == "polisi":
			btn.text = "Bangun Kantor Polisi dulu"
		elif kind == "tni":
			btn.text = "Bangun Markas TNI dulu"
		else:
			btn.text = "Bangun RS / Puskesmas dulu"
		btn.disabled = true
		UIThemeHelper.apply_btn_secondary(btn, 42.0)
	elif em.is_any_unit_busy(kind):
		btn.text = "Unit sedang bertugas"
		btn.disabled = true
		UIThemeHelper.apply_btn_secondary(btn, 42.0)
	else:
		btn.text = label_txt
		UIThemeHelper.apply_btn_primary(btn, 42.0)
		btn.pressed.connect(func():
			city_manager.dispatch_unit_to_incident(kind)
			_refresh_incident_modal()
		)
	incident_vbox.add_child(btn)
