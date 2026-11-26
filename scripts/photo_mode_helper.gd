class_name PhotoModeHelper
extends Control

## Foto Mode & Kartu Pos Kota (Season 2 & Season 1, tanpa ubah file save)

signal photo_mode_toggled(active: bool)
signal rotate_camera_requested()

var active: bool = false
var _hidden_nodes: Array = []
var _meta_provider: Callable
var _overlay: Control = null
var _postcard_modal: PanelContainer = null
var _pc_tex: TextureRect = null
var _pc_lbl: Label = null
var _last_img: Image = null

func setup(hidden_nodes: Array, meta_provider: Callable) -> void:
	_hidden_nodes = hidden_nodes
	_meta_provider = meta_provider
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	var btn_exit := Button.new()
	btn_exit.text = "X (Esc)"
	btn_exit.anchor_left = 1.0
	btn_exit.anchor_right = 1.0
	btn_exit.offset_left = -92.0
	btn_exit.offset_top = 14.0
	btn_exit.offset_right = -14.0
	btn_exit.offset_bottom = 50.0
	UIThemeHelper.apply_btn_secondary(btn_exit, 36.0)
	btn_exit.pressed.connect(exit_photo_mode)
	_overlay.add_child(btn_exit)

	var btn_rot := Button.new()
	btn_rot.text = "Putar Kamera"
	btn_rot.anchor_left = 1.0
	btn_rot.anchor_top = 1.0
	btn_rot.anchor_right = 1.0
	btn_rot.anchor_bottom = 1.0
	btn_rot.offset_left = -140.0
	btn_rot.offset_top = -58.0
	btn_rot.offset_right = -14.0
	btn_rot.offset_bottom = -16.0
	UIThemeHelper.apply_btn_secondary(btn_rot, 42.0)
	btn_rot.pressed.connect(func(): rotate_camera_requested.emit())
	_overlay.add_child(btn_rot)

	var btn_snap := Button.new()
	btn_snap.text = "Ambil Foto"
	btn_snap.anchor_left = 0.5
	btn_snap.anchor_top = 1.0
	btn_snap.anchor_right = 0.5
	btn_snap.anchor_bottom = 1.0
	btn_snap.offset_left = -95.0
	btn_snap.offset_top = -64.0
	btn_snap.offset_right = 95.0
	btn_snap.offset_bottom = -14.0
	UIThemeHelper.apply_btn_primary(btn_snap, 50.0)
	btn_snap.pressed.connect(_take_photo)
	_overlay.add_child(btn_snap)

	_build_postcard_modal()

func _build_postcard_modal() -> void:
	_postcard_modal = PanelContainer.new()
	_postcard_modal.visible = false
	_postcard_modal.set_anchors_preset(Control.PRESET_CENTER)
	_postcard_modal.offset_left = -270.0
	_postcard_modal.offset_top = -220.0
	_postcard_modal.offset_right = 270.0
	_postcard_modal.offset_bottom = 220.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.98, 0.98, 1.0)
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left = 12
	sb.content_margin_left = 16.0
	sb.content_margin_top = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_bottom = 16.0
	_postcard_modal.add_theme_stylebox_override("panel", sb)
	add_child(_postcard_modal)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_postcard_modal.add_child(vb)

	_pc_tex = TextureRect.new()
	_pc_tex.custom_minimum_size = Vector2(500, 280)
	_pc_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pc_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vb.add_child(_pc_tex)

	_pc_lbl = Label.new()
	_pc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pc_lbl.add_theme_font_size_override("font_size", 14)
	_pc_lbl.add_theme_color_override("font_color", Color(0.12, 0.14, 0.20))
	vb.add_child(_pc_lbl)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)

	var b_save := Button.new()
	b_save.text = "Simpan"
	b_save.custom_minimum_size = Vector2(130, 40)
	UIThemeHelper.apply_btn_primary(b_save, 40.0)
	b_save.pressed.connect(func():
		if _last_img:
			var path := _save_image(_last_img, "kartupos_")
			_pc_lbl.text += "\nTersimpan: %s" % path
	)
	hb.add_child(b_save)

	var b_close := Button.new()
	b_close.text = "Tutup"
	b_close.custom_minimum_size = Vector2(130, 40)
	UIThemeHelper.apply_btn_secondary(b_close, 40.0)
	b_close.pressed.connect(func():
		_postcard_modal.visible = false
		_overlay.visible = true
	)
	hb.add_child(b_close)

func enter_photo_mode() -> void:
	if active:
		return
	active = true
	visible = true
	_overlay.visible = true
	_postcard_modal.visible = false
	for n in _hidden_nodes:
		if n and is_instance_valid(n):
			n.visible = false
	photo_mode_toggled.emit(true)

func exit_photo_mode() -> void:
	if not active:
		return
	active = false
	visible = false
	_postcard_modal.visible = false
	for n in _hidden_nodes:
		if n and is_instance_valid(n):
			n.visible = true
	photo_mode_toggled.emit(false)

func _unhandled_input(event: InputEvent) -> void:
	if active and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _postcard_modal.visible:
			_postcard_modal.visible = false
			_overlay.visible = true
		else:
			exit_photo_mode()

func _take_photo() -> void:
	_overlay.visible = false
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img:
		_last_img = img
		_save_image(img, "townverse_")
		_pc_tex.texture = ImageTexture.create_from_image(img)
	var meta: Dictionary = _meta_provider.call() if _meta_provider.is_valid() else {}
	_pc_lbl.text = "KotaBareng — %s  |  Pop: %s  |  %s\n\"your city, your rule\"" % [
		str(meta.get("tier", "Desa")),
		str(meta.get("pop", 0)),
		str(meta.get("date", "Bln 1 Th 1"))
	]
	_postcard_modal.visible = true

func _save_image(img: Image, prefix: String) -> String:
	var dir_path := "user://foto_townverse"
	DirAccess.make_dir_recursive_absolute(dir_path)
	var dt := Time.get_datetime_dict_from_system()
	var fname := "%s%04d%02d%02d_%02d%02d%02d.png" % [
		prefix, int(dt["year"]), int(dt["month"]), int(dt["day"]),
		int(dt["hour"]), int(dt["minute"]), int(dt["second"])
	]
	var full_path := "%s/%s" % [dir_path, fname]
	img.save_png(full_path)
	return full_path
