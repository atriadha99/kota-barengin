class_name HUD
extends CanvasLayer

## Mengontrol UI informasi kota, meter demand RCI, toast notifikasi, dan palette tool

@export var city_manager: CityManager

@onready var label_money: Label = $TopPanel/HBox/LabelMoney
@onready var label_pop: Label = $TopPanel/HBox/LabelPop
@onready var label_date: Label = $TopPanel/HBox/LabelDate
@onready var label_utility: Label = $TopPanel/HBox/LabelUtility

@onready var bar_r: ProgressBar = $RCIPanel/VBox/BarR
@onready var bar_c: ProgressBar = $RCIPanel/VBox/BarC
@onready var bar_i: ProgressBar = $RCIPanel/VBox/BarI

@onready var toast_label: Label = $ToastLabel
@onready var toast_timer: Timer = $ToastTimer

@onready var btn_road: Button = $BottomPalette/HBox/BtnRoad
@onready var btn_zone_r: Button = $BottomPalette/HBox/BtnZoneR
@onready var btn_zone_c: Button = $BottomPalette/HBox/BtnZoneC
@onready var btn_zone_i: Button = $BottomPalette/HBox/BtnZoneI
@onready var btn_power: Button = $BottomPalette/HBox/BtnPower
@onready var btn_water: Button = $BottomPalette/HBox/BtnWater
@onready var btn_bulldozer: Button = $BottomPalette/HBox/BtnBulldozer

var tool_buttons: Dictionary = {}

func _ready() -> void:
	if city_manager:
		city_manager.city_updated.connect(_on_city_updated)
		city_manager.show_toast.connect(_show_toast)

	tool_buttons = {
		CityManager.ToolMode.ROAD: btn_road,
		CityManager.ToolMode.ZONE_R: btn_zone_r,
		CityManager.ToolMode.ZONE_C: btn_zone_c,
		CityManager.ToolMode.ZONE_I: btn_zone_i,
		CityManager.ToolMode.POWER_PLANT: btn_power,
		CityManager.ToolMode.WATER_TOWER: btn_water,
		CityManager.ToolMode.BULLDOZER: btn_bulldozer
	}

	btn_road.pressed.connect(func(): _select_tool(CityManager.ToolMode.ROAD))
	btn_zone_r.pressed.connect(func(): _select_tool(CityManager.ToolMode.ZONE_R))
	btn_zone_c.pressed.connect(func(): _select_tool(CityManager.ToolMode.ZONE_C))
	btn_zone_i.pressed.connect(func(): _select_tool(CityManager.ToolMode.ZONE_I))
	btn_power.pressed.connect(func(): _select_tool(CityManager.ToolMode.POWER_PLANT))
	btn_water.pressed.connect(func(): _select_tool(CityManager.ToolMode.WATER_TOWER))
	btn_bulldozer.pressed.connect(func(): _select_tool(CityManager.ToolMode.BULLDOZER))

	toast_timer.timeout.connect(func(): toast_label.visible = false)
	toast_label.visible = false

	_select_tool(CityManager.ToolMode.ROAD)

func _select_tool(mode: CityManager.ToolMode) -> void:
	if city_manager:
		city_manager.set_tool(mode)

	for m in tool_buttons:
		var btn: Button = tool_buttons[m]
		if m == mode:
			btn.modulate = Color(1.2, 1.2, 0.5) # Highlight aktif
		else:
			btn.modulate = Color(1.0, 1.0, 1.0)

func _on_city_updated(data: CityData) -> void:
	label_money.text = "Uang: Rp " + _format_number(data.money)
	label_pop.text = "Populasi: " + str(data.population)
	label_date.text = "Bulan %d, Th %d" % [data.month, data.year]

	var has_util := data.has_utilities()
	if has_util:
		label_utility.text = "Listrik & Air: SIAP"
		label_utility.modulate = Color(0.3, 0.95, 0.4)
	else:
		label_utility.text = "Listrik & Air: KURANG (Butuh 1 Pembangkit & 1 Menara Air)"
		label_utility.modulate = Color(1.0, 0.4, 0.3)

	bar_r.value = data.demand_r
	bar_c.value = data.demand_c
	bar_i.value = data.demand_i

func _show_toast(msg: String) -> void:
	toast_label.text = msg
	toast_label.visible = true
	toast_timer.start(2.0)

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
