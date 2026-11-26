class_name MainMenu
extends Node3D

## Menu Utama Townverse (Season 2: Mode Walikota) dengan background kota 3D contoh + kamera orbit pelan

@onready var orbit_camera: Camera3D = $OrbitCamera
@onready var showcase_city: Node3D = $ShowcaseCity
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

func _ready() -> void:
	_build_showcase_city()

	btn_continue.disabled = not SaveManager.has_save()

	btn_new_game.pressed.connect(func():
		SaveManager.load_on_start = false
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)

	btn_continue.pressed.connect(func():
		if SaveManager.has_save():
			SaveManager.load_on_start = true
			get_tree().change_scene_to_file("res://scenes/main.tscn")
	)

	btn_settings.pressed.connect(_open_settings)
	btn_exit.pressed.connect(func(): get_tree().quit())

	sl_master.value_changed.connect(func(v: float): lbl_master.text = "Volume Utama: %d%%" % int(v))
	sl_music.value_changed.connect(func(v: float): lbl_music.text = "Volume Musik: %d%%" % int(v))
	sl_sfx.value_changed.connect(func(v: float): lbl_sfx.text = "Volume SFX: %d%%" % int(v))
	btn_settings_close.pressed.connect(_save_and_close_settings)

	settings_modal.visible = false
	_update_camera(0.0)

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
	settings_modal.visible = false
