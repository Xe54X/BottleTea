extends CanvasLayer

@onready var color_picker: ColorPicker = $Color/ColorPicker                      # Выбор цвета
@onready var apply_button: Button = $Color/Buttons/ApplyButton                   # Применить цвет
@onready var reset_button: Button = $Color/Buttons/ResetButton                   # Сбросить цвет

const SETTINGS_PATH = "user://settings.cfg"

func _ready() -> void:
	_load_color()
	if apply_button:
		apply_button.pressed.connect(_apply_color)
	if reset_button:
		reset_button.pressed.connect(_reset_color)
	if color_picker:
		color_picker.color_changed.connect(_on_color_changed)

# === Применение выбранного цвета ===
func _apply_color():
	if color_picker:
		var selected_color = color_picker.color
		RenderingServer.set_default_clear_color(selected_color)
		_save_color(selected_color)
		print("Цвет фона изменен на: ", selected_color)

# === Сброс цвета к стандартному ===
func _reset_color():
	var default_color = Color(0.3, 0.3, 0.3, 1.0)  # Стандартный серый цвет Godot
	if color_picker:
		color_picker.color = default_color
	RenderingServer.set_default_clear_color(default_color)
	_save_color(default_color)
	print("Цвет фона сброшен к стандартному")

# === Обработка изменения цвета в ColorPicker ===
func _on_color_changed(color: Color):
	# Можно применять цвет сразу при изменении
	RenderingServer.set_default_clear_color(color)

# === Сохранение цвета ===
func _save_color(color: Color):
	var config = ConfigFile.new()
	config.set_value("background", "color_r", color.r)
	config.set_value("background", "color_g", color.g)
	config.set_value("background", "color_b", color.b)
	config.set_value("background", "color_a", color.a)
	
	var error = config.save(SETTINGS_PATH)
	if error == OK:
		print("Цвет сохранен")
	else:
		print("Ошибка сохранения цвета: ", error)

# === Загрузка цвета ===
func _load_color():
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	
	if error != OK:
		print("Файл настроек не найден, использую стандартный цвет")
		return
	
	var color = Color(
		config.get_value("background", "color_r", 0.3),
		config.get_value("background", "color_g", 0.3),
		config.get_value("background", "color_b", 0.3),
		config.get_value("background", "color_a", 1.0)
	)
	
	RenderingServer.set_default_clear_color(color)
	if color_picker:
		color_picker.color = color
	print("Цвет загружен: ", color)
