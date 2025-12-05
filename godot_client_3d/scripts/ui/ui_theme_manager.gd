extends Node
class_name UIThemeManager

## Менеджер темы UI в морском стиле Isleborn Online

static var marine_theme: Theme

static func get_marine_theme() -> Theme:
	if marine_theme:
		return marine_theme
	
	marine_theme = Theme.new()
	_setup_theme(marine_theme)
	return marine_theme

static func _setup_theme(theme: Theme) -> void:
	# Настройка Button
	var button_normal := StyleBoxFlat.new()
	button_normal.bg_color = Color(0.1, 0.3, 0.5, 0.8)
	button_normal.border_width_left = 2
	button_normal.border_width_top = 2
	button_normal.border_width_right = 2
	button_normal.border_width_bottom = 2
	button_normal.border_color = Color(0.2, 0.6, 0.9, 1)
	button_normal.corner_radius_top_left = 4
	button_normal.corner_radius_top_right = 4
	button_normal.corner_radius_bottom_right = 4
	button_normal.corner_radius_bottom_left = 4
	button_normal.shadow_color = Color(0, 0, 0, 0.3)
	button_normal.shadow_size = 2
	theme.set_stylebox("normal", "Button", button_normal)
	
	var button_hover := button_normal.duplicate()
	button_hover.bg_color = Color(0.15, 0.4, 0.6, 0.9)
	button_hover.border_color = Color(0.3, 0.7, 1, 1)
	button_hover.shadow_size = 3
	theme.set_stylebox("hover", "Button", button_hover)
	
	var button_pressed := button_normal.duplicate()
	button_pressed.bg_color = Color(0.2, 0.5, 0.7, 1)
	button_pressed.border_color = Color(0.4, 0.8, 1, 1)
	theme.set_stylebox("pressed", "Button", button_pressed)
	
	# Цвета Button
	theme.set_color("font_color", "Button", Color(0.95, 0.95, 0.95, 1))
	theme.set_color("font_hover_color", "Button", Color(1, 1, 1, 1))
	theme.set_color("font_pressed_color", "Button", Color(0.8, 0.9, 1, 1))
	theme.set_font_size("font_size", "Button", 18)
	
	# Настройка Label
	theme.set_color("font_color", "Label", Color(0.9, 0.95, 1, 1))
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.5))
	theme.set_font_size("font_size", "Label", 20)
	
	# Настройка LineEdit
	var line_edit_normal := StyleBoxFlat.new()
	line_edit_normal.bg_color = Color(0.05, 0.15, 0.25, 0.7)
	line_edit_normal.border_width_left = 1
	line_edit_normal.border_width_top = 1
	line_edit_normal.border_width_right = 1
	line_edit_normal.border_width_bottom = 1
	line_edit_normal.border_color = Color(0.2, 0.5, 0.7, 0.8)
	line_edit_normal.corner_radius_top_left = 3
	line_edit_normal.corner_radius_top_right = 3
	line_edit_normal.corner_radius_bottom_right = 3
	line_edit_normal.corner_radius_bottom_left = 3
	theme.set_stylebox("normal", "LineEdit", line_edit_normal)
	
	theme.set_color("font_color", "LineEdit", Color(0.95, 0.95, 0.95, 1))
	theme.set_color("font_selected_color", "LineEdit", Color(1, 1, 1, 1))
	theme.set_font_size("font_size", "LineEdit", 16)
	
	# Настройка OptionButton
	theme.set_stylebox("normal", "OptionButton", button_normal)
	theme.set_stylebox("hover", "OptionButton", button_hover)
	theme.set_stylebox("pressed", "OptionButton", button_pressed)
	theme.set_color("font_color", "OptionButton", Color(0.95, 0.95, 0.95, 1))
	theme.set_font_size("font_size", "OptionButton", 16)

static func apply_theme_to_control(control: Control) -> void:
	control.theme = get_marine_theme()
