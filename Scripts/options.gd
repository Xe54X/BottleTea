extends CanvasLayer

@onready var color_picker: ColorPicker = $ScrollContainer/VBoxContainer/Color/ColorPicker            # Выбор цвета
@onready var apply_button: Button = $ScrollContainer/VBoxContainer/Color/Buttons/ApplyButton         # Применить цвет
@onready var reset_button: Button = $ScrollContainer/VBoxContainer/Color/Buttons/ResetButton         # Сбросить цвет

# === Исправленные пути к узлам MaxBottle ===
@onready var max_bottle_label: Label = $ScrollContainer/VBoxContainer/MaxBottle/Label
@onready var max_bottle_line_edit: LineEdit = $ScrollContainer/VBoxContainer/MaxBottle/LineEdit      # Поле ввода
@onready var max_bottle_apply_button: Button = $ScrollContainer/VBoxContainer/MaxBottle/ApplyButton  # Кнопка "Применить"

const SETTINGS_PATH = "user://settings.cfg"

func _ready() -> void:
	_load_color()
	_load_max_bottles()
	
	if apply_button:
		apply_button.pressed.connect(_apply_color)
	if reset_button:
		reset_button.pressed.connect(_reset_color)
	if color_picker:
		color_picker.color_changed.connect(_on_color_changed)
	
	# === Подключаем сигналы для настройки максимума банок ===
	if max_bottle_apply_button:
		max_bottle_apply_button.pressed.connect(_apply_max_bottles)
	
	# Обработка нажатия Enter в поле ввода
	if max_bottle_line_edit:
		max_bottle_line_edit.text_submitted.connect(_apply_max_bottles)

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

# ============================================
# === НОВЫЕ ФУНКЦИИ ДЛЯ МАКСИМУМА БАНОК ===
# ============================================

# === Применить максимальное количество банок ===
func _apply_max_bottles():
	if max_bottle_line_edit == null:
		print("Ошибка: поле ввода не найдено!")
		return
	
	var text = max_bottle_line_edit.text
	var max_value = text.to_int()
	
	# Проверяем корректность ввода
	if max_value <= 0:
		print("Ошибка: максимальное количество должно быть больше 0!")
		max_bottle_line_edit.text = str(_get_current_max_bottles())
		return
	
	# Получаем ссылку на основную сцену и обновляем лимит
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("set_max_bottles"):
		main_scene.set_max_bottles(max_value)
		_save_max_bottles(max_value)
		print("Максимум банок изменен на: ", max_value)
	else:
		print("Ошибка: не удалось найти основную сцену!")
		max_bottle_line_edit.text = str(_get_current_max_bottles())

# === Сохранение максимального количества банок ===
func _save_max_bottles(max_value: int):
	var config = ConfigFile.new()
	
	# Загружаем существующий файл, чтобы не потерять другие настройки
	var error = config.load(SETTINGS_PATH)
	if error != OK:
		print("Создаю новый файл настроек")
	
	config.set_value("game", "max_bottles", max_value)
	
	error = config.save(SETTINGS_PATH)
	if error == OK:
		print("Максимум банок сохранен: ", max_value)
	else:
		print("Ошибка сохранения максимума банок: ", error)

# === Загрузка максимального количества банок ===
func _load_max_bottles():
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	
	var max_value = 450  # Значение по умолчанию
	
	if error == OK:
		max_value = config.get_value("game", "max_bottles", 450)
		print("Загружен максимум банок: ", max_value)
	else:
		print("Файл настроек не найден, использую стандартный максимум: 450")
	
	# Обновляем поле ввода
	if max_bottle_line_edit:
		max_bottle_line_edit.text = str(max_value)
	
	# Обновляем лимит в основной сцене
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("set_max_bottles"):
		main_scene.set_max_bottles(max_value)

# === Получение текущего максимума банок ===
func _get_current_max_bottles() -> int:
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("get_max_bottles"):
		return main_scene.get_max_bottles()
	return 450
