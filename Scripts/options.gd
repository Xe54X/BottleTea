extends CanvasLayer

@onready var color_picker: ColorPicker = $ScrollContainer/VBoxContainer/Color/Color/ColorPicker
@onready var apply_button: Button = $ScrollContainer/VBoxContainer/Color/Color/Buttons/ApplyButton
@onready var reset_button: Button = $ScrollContainer/VBoxContainer/Color/Color/Buttons/ResetButton
@onready var max_bottle_line_edit: LineEdit = $ScrollContainer/VBoxContainer/VBoxContainer/MaxBottle/LineEdit
@onready var max_bottle_apply_button: Button = $ScrollContainer/VBoxContainer/VBoxContainer/MaxBottle/ApplyButton

const SETTINGS_PATH = "user://Config.cfg"

func _ready() -> void:
	_load_settings()
	if apply_button:
		apply_button.pressed.connect(_apply_color)
	if reset_button:
		reset_button.pressed.connect(_reset_color)
	if color_picker:
		color_picker.color_changed.connect(_on_color_changed)
	if max_bottle_apply_button:
		max_bottle_apply_button.pressed.connect(_apply_max_bottles)
	if max_bottle_line_edit:
		max_bottle_line_edit.text_submitted.connect(_apply_max_bottles)

# === Применение выбранного цвета ===
func _apply_color():
	if color_picker:
		var selected_color = color_picker.color
		RenderingServer.set_default_clear_color(selected_color)
		_save_settings()
		print("Цвет фона изменен на: ", selected_color)

# === Сброс цвета к стандартному ===
func _reset_color():
	var default_color = Color(0.3, 0.3, 0.3, 1.0)
	if color_picker:
		color_picker.color = default_color
	RenderingServer.set_default_clear_color(default_color)
	_save_settings()
	print("Цвет фона сброшен к стандартному")

# === Обработка изменения цвета в ColorPicker ===
func _on_color_changed(color: Color):
	RenderingServer.set_default_clear_color(color)

# === Применить максимальное количество банок ===
func _apply_max_bottles(_text: String = ""):
	if max_bottle_line_edit == null:
		print("Ошибка: поле ввода не найдено!")
		return
	var max_value = max_bottle_line_edit.text.to_int()
	if max_value <= 0:
		print("Ошибка: максимальное количество должно быть больше 0!")
		max_bottle_line_edit.text = str(_get_current_max_bottles())
		return
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("set_max_bottles"):
		main_scene.set_max_bottles(max_value)
		_save_settings()
		print("Максимум банок изменен на: ", max_value)
	else:
		print("Ошибка: не удалось найти основную сцену!")

# === Сохранение всех настроек ===
func _save_settings():
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	if error != OK:
		config = ConfigFile.new()
	
	# Сохраняем цвет
	if color_picker:
		config.set_value("settings", "color_r", color_picker.color.r)
		config.set_value("settings", "color_g", color_picker.color.g)
		config.set_value("settings", "color_b", color_picker.color.b)
		config.set_value("settings", "color_a", color_picker.color.a)
	
	# Сохраняем максимум банок
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("get_max_bottles"):
		config.set_value("settings", "max_bottles", main_scene.get_max_bottles())
	
	error = config.save(SETTINGS_PATH)
	if error == OK:
		print("Настройки сохранены")
	else:
		print("Ошибка сохранения настроек: ", error)

# === Загрузка всех настроек ===
func _load_settings():
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	if error != OK:
		print("Файл настроек не найден, использую стандартные настройки")
		return
	
	# Загружаем цвет
	var color = Color(
		config.get_value("settings", "color_r", 0.3),
		config.get_value("settings", "color_g", 0.3),
		config.get_value("settings", "color_b", 0.3),
		config.get_value("settings", "color_a", 1.0)
	)
	RenderingServer.set_default_clear_color(color)
	if color_picker:
		color_picker.color = color
	
	# Загружаем максимум банок
	var max_value = config.get_value("settings", "max_bottles", 450)
	if max_bottle_line_edit:
		max_bottle_line_edit.text = str(max_value)
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("set_max_bottles"):
		main_scene.set_max_bottles(max_value)
	
	print("Настройки загружены")

# === Получение текущего максимума банок ===
func _get_current_max_bottles() -> int:
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("get_max_bottles"):
		return main_scene.get_max_bottles()
	return 450
