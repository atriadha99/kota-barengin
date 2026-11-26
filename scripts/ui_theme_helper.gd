class_name UIThemeHelper
extends RefCounted

## Helper tema UI Townverse (StyleBoxFlat prosedural tanpa aset eksternal)

static func make_panel_style(accent_gold: bool = false, radius: int = 16, pad_h: float = 16.0, pad_v: float = 14.0, bg_alpha: float = 0.92) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.16, bg_alpha)
	sb.border_width_left = 2 if accent_gold else 1
	sb.border_width_top = 2 if accent_gold else 1
	sb.border_width_right = 2 if accent_gold else 1
	sb.border_width_bottom = 2 if accent_gold else 1
	sb.border_color = Color(0.96, 0.78, 0.22, 0.96) if accent_gold else Color(0.28, 0.34, 0.46, 0.88)
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_right = radius
	sb.corner_radius_bottom_left = radius
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0.0, 4.0)
	sb.content_margin_left = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_right = pad_h
	sb.content_margin_bottom = pad_v
	return sb

static func make_panel_header(title_text: String, icon_type: String = "") -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	if not icon_type.is_empty():
		hb.add_child(S1VisualBuilder.StatIcon.new(icon_type))
	var lbl := Label.new()
	lbl.text = title_text
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.28))
	hb.add_child(lbl)
	return hb

static func make_chip_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.16, 0.24, 0.95)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.28, 0.34, 0.46, 0.85)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	sb.content_margin_left = 8.0
	sb.content_margin_top = 4.0
	sb.content_margin_right = 10.0
	sb.content_margin_bottom = 4.0
	return sb

static func _make_btn_box(bg: Color, border: Color, press_shift: float = 0.0, radius: int = 14) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = border
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_right = radius
	sb.corner_radius_bottom_left = radius
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(0.0, 2.0)
	sb.content_margin_left = 14.0
	sb.content_margin_top = 8.0 + press_shift
	sb.content_margin_right = 14.0
	sb.content_margin_bottom = 8.0 - press_shift * 0.5
	return sb

static func apply_btn_primary(btn: Button, min_h: float = 48.0) -> void:
	if not btn:
		return
	btn.custom_minimum_size.y = maxf(btn.custom_minimum_size.y, min_h)
	btn.add_theme_stylebox_override("normal", _make_btn_box(Color(0.95, 0.77, 0.20, 1.0), Color(1.0, 0.88, 0.45, 1.0)))
	btn.add_theme_stylebox_override("hover", _make_btn_box(Color(1.0, 0.85, 0.32, 1.0), Color(1.0, 0.94, 0.65, 1.0)))
	btn.add_theme_stylebox_override("pressed", _make_btn_box(Color(0.80, 0.63, 0.14, 1.0), Color(0.92, 0.75, 0.25, 1.0), 2.0))
	btn.add_theme_stylebox_override("disabled", _make_btn_box(Color(0.18, 0.20, 0.25, 0.78), Color(0.28, 0.30, 0.36, 0.6)))
	btn.add_theme_color_override("font_color", Color(0.10, 0.11, 0.14))
	btn.add_theme_color_override("font_hover_color", Color(0.06, 0.07, 0.10))
	btn.add_theme_color_override("font_pressed_color", Color(0.10, 0.11, 0.14))
	btn.add_theme_color_override("font_disabled_color", Color(0.48, 0.50, 0.55))

static func apply_btn_secondary(btn: Button, min_h: float = 48.0) -> void:
	if not btn:
		return
	btn.custom_minimum_size.y = maxf(btn.custom_minimum_size.y, min_h)
	btn.add_theme_stylebox_override("normal", _make_btn_box(Color(0.16, 0.19, 0.27, 0.96), Color(0.34, 0.40, 0.52, 0.9)))
	btn.add_theme_stylebox_override("hover", _make_btn_box(Color(0.22, 0.26, 0.36, 1.0), Color(0.48, 0.56, 0.72, 1.0)))
	btn.add_theme_stylebox_override("pressed", _make_btn_box(Color(0.12, 0.14, 0.20, 1.0), Color(0.30, 0.36, 0.48, 1.0), 2.0))
	btn.add_theme_stylebox_override("disabled", _make_btn_box(Color(0.14, 0.15, 0.19, 0.65), Color(0.24, 0.26, 0.31, 0.5)))
	btn.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.47, 0.52))

static func apply_btn_danger(btn: Button, min_h: float = 48.0) -> void:
	if not btn:
		return
	btn.custom_minimum_size.y = maxf(btn.custom_minimum_size.y, min_h)
	btn.add_theme_stylebox_override("normal", _make_btn_box(Color(0.56, 0.16, 0.18, 0.96), Color(0.78, 0.28, 0.30, 0.9)))
	btn.add_theme_stylebox_override("hover", _make_btn_box(Color(0.70, 0.22, 0.24, 1.0), Color(0.92, 0.38, 0.40, 1.0)))
	btn.add_theme_stylebox_override("pressed", _make_btn_box(Color(0.44, 0.12, 0.14, 1.0), Color(0.68, 0.22, 0.24, 1.0), 2.0))
	btn.add_theme_stylebox_override("disabled", _make_btn_box(Color(0.20, 0.16, 0.17, 0.65), Color(0.30, 0.24, 0.25, 0.5)))
	btn.add_theme_color_override("font_color", Color(0.98, 0.96, 0.96))
	btn.add_theme_color_override("font_disabled_color", Color(0.50, 0.46, 0.47))

static func make_toast_style(is_error: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.07, 0.08, 0.94) if is_error else Color(0.08, 0.10, 0.16, 0.94)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.95, 0.30, 0.30, 0.95) if is_error else Color(0.95, 0.78, 0.22, 0.9)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left = 10
	sb.content_margin_left = 16.0
	sb.content_margin_top = 8.0
	sb.content_margin_right = 16.0
	sb.content_margin_bottom = 8.0
	return sb
