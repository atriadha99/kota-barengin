class_name HUD
extends CanvasLayer

## Mengontrol UI informasi kota, status utilitas detail, kontrol waktu, slider pajak, panel gudang gandum, dan palette tool

@export var city_manager: CityManager

@onready var label_money: Label = $TopPanel/HBox/LabelMoney
@onready var label_pop: Label = $TopPanel/HBox/LabelPop
@onready var label_happiness: Label = $TopPanel/HBox/LabelHappiness
@onready var label_power: Label = $TopPanel/HBox/LabelPower
@onready var label_water: Label = $TopPanel/HBox/LabelWater
@onready var label_date: Label = $TopPanel/HBox/LabelDate
@onready var label_tier: Label = $TopPanel/HBox/LabelTier

@onready var bar_r: ProgressBar = $RightPanel/VBoxRCI/BarR
@onready var bar_c: ProgressBar = $RightPanel/VBoxRCI/BarC
@onready var bar_i: ProgressBar = $RightPanel/VBoxRCI/BarI

@onready var btn_pause: Button = $TimeSpeedPanel/HBoxSpeed/BtnPause
@onready var btn_1x: Button = $TimeSpeedPanel/HBoxSpeed/Btn1x
@onready var btn_3x: Button = $TimeSpeedPanel/HBoxSpeed/Btn3x

@onready var tax_slider: HSlider = $TaxPanel/VBoxTax/TaxSlider
@onready var label_tax: Label = $TaxPanel/VBoxTax/LabelTax

# Gudang Pertanian & Jual Gandum (Langkah 4)
@onready var label_wheat: Label = $FarmPanel/VBoxFarm/LabelWheat
@onready var label_price: Label = $FarmPanel/VBoxFarm/LabelPrice
@onready var btn_sell_wheat: Button = $FarmPanel/VBoxFarm/BtnSellWheat

@onready var toast_label: Label = $ToastLabel
@onready var toast_timer: Timer = $ToastTimer

@onready var btn_road: Button = $BottomPalette/HBox/BtnRoad
@onready var btn_zone_r: Button = $BottomPalette/HBox/BtnZoneR
@onready var btn_zone_c: Button = $BottomPalette/HBox/BtnZoneC
@onready var btn_zone_i: Button = $BottomPalette/HBox/BtnZoneI
@onready var btn_power: Button = $BottomPalette/HBox/BtnPower
@onready var btn_water: Button = $BottomPalette/HBox/BtnWater
@onready var btn_park: Button = $BottomPalette/HBox/BtnPark
@onready var btn_farm: Button = $BottomPalette/HBox/BtnFarm
@onready var btn_bulldozer: Button = $BottomPalette/HBox/BtnBulldozer

var tool_buttons: Dictionary = {}
var speed_buttons: Dictionary = {}

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
		CityManager.ToolMode.PARK: btn_park,
		CityManager.ToolMode.FARM: btn_farm,
		CityManager.ToolMode.BULLDOZER: btn_bulldozer
	}

	btn_road.pressed.connect(func(): _select_tool(CityManager.ToolMode.ROAD))
	btn_zone_r.pressed.connect(func(): _select_tool(CityManager.ToolMode.ZONE_R))
	btn_zone_c.pressed.connect(func(): _select_tool(CityManager.ToolMode.ZONE_C))
	btn_zone_i.pressed.connect(func(): _select_tool(CityManager.ToolMode.ZONE_I))
	btn_power.pressed.connect(func(): _select_tool(CityManager.ToolMode.POWER_PLANT))
	btn_water.pressed.connect(func(): _select_tool(CityManager.ToolMode.WATER_TOWER))
	btn_park.pressed.connect(func(): _select_tool(CityManager.ToolMode.PARK))
	btn_farm.pressed.connect(func(): _select_tool(CityManager.ToolMode.FARM))
	btn_bulldozer.pressed.connect(func(): _select_tool(CityManager.ToolMode.BULLDOZER))

	# Kecepatan waktu
	speed_buttons = {
		0.0: btn_pause,
		1.0: btn_1x,
		3.0: btn_3x
	}
	btn_pause.pressed.connect(func(): _select_speed(0.0))
	btn_1x.pressed.connect(func(): _select_speed(1.0))
	btn_3x.pressed.connect(func(): _select_speed(3.0))

	# Slider Pajak
	tax_slider.value_changed.connect(_on_tax_slider_changed)
	tax_slider.value = 8.0
	label_tax.text = "Pajak: 8%"

	# Jual Gandum
	btn_sell_wheat.pressed.connect(func():
		if city_manager:
			city_manager.sell_all_wheat()
	)

	toast_timer.timeout.connect(func(): toast_label.visible = false)
	toast_label.visible = false

	_select_tool(CityManager.ToolMode.ROAD)
	_select_speed(1.0)

func _select_tool(mode: CityManager.ToolMode) -> void:
	if city_manager:
		city_manager.set_tool(mode)

	for m in tool_buttons:
		var btn: Button = tool_buttons[m]
		if m == mode:
			btn.modulate = Color(1.2, 1.2, 0.5)
		else:
			btn.modulate = Color(1.0, 1.0, 1.0)

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

	label_date.text = "Bulan %d, Tahun %d" % [data.month, data.year]
	label_tier.text = "[" + data.city_level + "]"

	bar_r.value = data.demand_r
	bar_c.value = data.demand_c
	bar_i.value = data.demand_i

	# Info Gudang Pertanian
	label_wheat.text = "Gandum: %d unit" % data.wheat_inventory
	label_price.text = "Harga: Rp %s / unit" % _format_number(data.wheat_price)

func _show_toast(msg: String) -> void:
	toast_label.text = msg
	toast_label.visible = true
	toast_timer.start(2.5)

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
