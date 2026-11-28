class_name PhotoModeHelper
extends Control

## Foto Mode & Kartu Pos Kota (Season 2 & Season 1, tanpa ubah file save)

signal photo_mode_toggled(active: bool)
signal rotate_camera_requested()

var active: bool = false
var _hidden_nodes: Array = []
var _prev_visibilities: Array[bool] = []
var _meta_provider: Callable
var _overlay: Control = null
var _postcard_modal: PanelContainer = null
var _pc_tex: TextureRect = null
var _pc_lbl: Label = null
var _err_lbl: Label = null
var _last_img: Image = null
var _is_capturing: bool = false

func setup(hidden_nodes: Array, meta_provider: Callable) -> void:
	_hidden_nodes = hidden_nodes
	_meta_provider = meta_provider
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	var btn_exit: Button = Button.new()
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

	var btn_rot: Button = Button.new()
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

	var btn_snap: Button = Button.new()
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

	_err_lbl = Label.new()
	_err_lbl.visible = false
	_err_lbl.anchor_left = 0.5
	_err_lbl.anchor_top = 1.0
	_err_lbl.anchor_right = 0.5
	_err_lbl.anchor_bottom = 1.0
	_err_lbl.offset_left = -190.0
	_err_lbl.offset_top = -104.0
	_err_lbl.offset_right = 190.0
	_err_lbl.offset_bottom = -72.0
	_err_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_err_lbl.add_theme_font_size_override("font_size", 14)
	_err_lbl.add_theme_color_override("font_color", Color(1.0, 0.38, 0.38))
	_overlay.add_child(_err_lbl)

	_build_postcard_modal()

func _build_postcard_modal() -> void:
	_postcard_modal = PanelContainer.new()
	_postcard_modal.visible = false
	_postcard_modal.set_anchors_preset(Control.PRESET_CENTER)
	_postcard_modal.offset_left = -270.0
	_postcard_modal.offset_top = -220.0
	_postcard_modal.offset_right = 270.0
	_postcard_modal.offset_bottom = 220.0
	var sb: StyleBoxFlat = StyleBoxFlat.new()
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

	var vb: VBoxContainer = VBoxContainer.new()
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

	var hb: HBoxContainer = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)

	var b_save: Button = Button.new()
	b_save.text = "Simpan"
	b_save.custom_minimum_size = Vector2(130, 40)
	UIThemeHelper.apply_btn_primary(b_save, 40.0)
	b_save.pressed.connect(func():
		if _last_img and not _last_img.is_empty():
			var path: String = _save_image(_last_img, "kartupos_")
			if not path.is_empty():
				_pc_lbl.text += "\nTersimpan: %s" % path
			else:
				_pc_lbl.text += "\nGagal menyimpan kartu pos"
	)
	hb.add_child(b_save)

	var b_close: Button = Button.new()
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
	if _err_lbl:
		_err_lbl.visible = false
	_prev_visibilities.clear()
	for n in _hidden_nodes:
		if n and is_instance_valid(n):
			_prev_visibilities.append(bool(n.visible))
			n.visible = false
		else:
			_prev_visibilities.append(false)
	photo_mode_toggled.emit(true)

func exit_photo_mode() -> void:
	if not active:
		return
	active = false
	visible = false
	_postcard_modal.visible = false
	if _err_lbl:
		_err_lbl.visible = false
	for i in range(_hidden_nodes.size()):
		var n: Node = _hidden_nodes[i]
		if n and is_instance_valid(n):
			var prev_v: bool = _prev_visibilities[i] if i < _prev_visibilities.size() else true
			n.visible = prev_v
	_prev_visibilities.clear()
	photo_mode_toggled.emit(false)

func _unhandled_input(event: InputEvent) -> void:
	if active and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _postcard_modal.visible:
			_postcard_modal.visible = false
			_overlay.visible = true
		else:
			exit_photo_mode()

func _show_photo_error(msg: String) -> void:
	if _err_lbl:
		_err_lbl.text = msg
		_err_lbl.visible = true
	_postcard_modal.visible = false
	_overlay.visible = true

func _take_photo() -> void:
	if _is_capturing or not active:
		return
	_is_capturing = true
	if _err_lbl:
		_err_lbl.visible = false
	_overlay.visible = false
	if get_tree():
		await get_tree().process_frame
		await get_tree().process_frame
	if not active:
		_is_capturing = false
		return

	var vp: Viewport = get_viewport()
	var tex: ViewportTexture = vp.get_texture() if vp else null
	var img: Image = tex.get_image() if tex else null
	if img == null or img.is_empty():
		_is_capturing = false
		_show_photo_error("Gagal mengambil foto, coba lagi")
		return

	var saved_path: String = _save_image(img, "townverse_")
	if saved_path.is_empty():
		_is_capturing = false
		_show_photo_error("Gagal mengambil foto, coba lagi")
		return

	_last_img = img
	_pc_tex.texture = ImageTexture.create_from_image(img)
	var meta: Dictionary = _meta_provider.call() if _meta_provider.is_valid() else {}
	_pc_lbl.text = "KotaBareng — %s  |  Pop: %s  |  %s\n\"your city, your rule\"" % [
		str(meta.get("tier", "Desa")),
		str(meta.get("pop", 0)),
		str(meta.get("date", "Bln 1 Th 1"))
	]
	_postcard_modal.visible = true
	_is_capturing = false

func _ensure_photo_dir() -> bool:
	var dir_path: String = "user://foto_townverse"
	var global_dir: String = ProjectSettings.globalize_path(dir_path)
	if not DirAccess.dir_exists_absolute(global_dir):
		var err: Error = DirAccess.make_dir_recursive_absolute(global_dir)
		if err != OK:
			var ud: DirAccess = DirAccess.open("user://")
			if ud == null or ud.make_dir_recursive("foto_townverse") != OK:
				return false
	return true

func _save_image(img: Image, prefix: String) -> String:
	if img == null or img.is_empty():
		return ""
	if not _ensure_photo_dir():
		return ""
	var dt: Dictionary = Time.get_datetime_dict_from_system()
	var fname: String = "%s%04d%02d%02d_%02d%02d%02d.png" % [
		prefix, int(dt.get("year", 2026)), int(dt.get("month", 1)), int(dt.get("day", 1)),
		int(dt.get("hour", 0)), int(dt.get("minute", 0)), int(dt.get("second", 0))
	]
	var full_path: String = "user://foto_townverse/%s" % fname
	var err: Error = img.save_png(full_path)
	if err != OK:
		return ""
	return full_path
