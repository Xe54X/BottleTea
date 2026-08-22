extends CanvasLayer

@onready var color_picker: ColorPicker = $ScrollContainer/VBoxContainer/Color/Color/ColorPicker
@onready var apply_button: Button = $ScrollContainer/VBoxContainer/Color/Color/Buttons/ApplyButton
@onready var reset_button: Button = $ScrollContainer/VBoxContainer/Color/Color/Buttons/ResetButton
@onready var max_bottle_line_edit: LineEdit = $ScrollContainer/VBoxContainer/VBoxContainer/MaxBottle/LineEdit
@onready var max_bottle_apply_button: Button = $ScrollContainer/VBoxContainer/VBoxContainer/MaxBottle/ApplyButton
@onready var add_image_button: Button = $ScrollContainer/VBoxContainer/CustomBottle/HBoxContainer/Buttons/Add
@onready var clear_image_button: Button = $ScrollContainer/VBoxContainer/CustomBottle/HBoxContainer/Buttons/Clear
@onready var image_label: Label = $ScrollContainer/VBoxContainer/CustomBottle/HBoxContainer/Label

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
	if add_image_button:
		add_image_button.pressed.connect(_add_image)
	if clear_image_button:
		clear_image_button.pressed.connect(_clear_image)
	call_deferred("_load_saved_image_deferred")

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

# === Добавить картинку через нативный диалог Windows ===
func _add_image():
	print("=== _add_image ===")
	var filters = PackedStringArray()
	filters.append("*.png")
	filters.append("*.jpg")
	filters.append("*.jpeg")
	filters.append("*.bmp")
	filters.append("*.webp")
	filters.append("*.svg")
	DisplayServer.file_dialog_show(
		"Выберите картинку для банки",
		_get_desktop_path(),
		"",
		false,
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
		filters,
		_on_image_selected
	)

# === Получение пути к рабочему столу ===
func _get_desktop_path() -> String:
	match OS.get_name():
		"Windows":
			var user_profile = OS.get_environment("USERPROFILE")
			if user_profile != "":
				return user_profile + "\\Desktop"
		"Linux", "macOS":
			var home = OS.get_environment("HOME")
			if home != "":
				return home + "/Desktop"
	return OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)

# === Обработка выбора картинки ===
func _on_image_selected(status: bool, selected_paths: PackedStringArray, _selected_filter_index: int):
	print("=== _on_image_selected ===")
	print("Статус: ", status)
	print("Выбранные пути: ", selected_paths)
	if status and selected_paths.size() > 0:
		var path = selected_paths[0]
		if not FileAccess.file_exists(path):
			print("Ошибка: файл не существует! Путь: ", path)
			return
		print("Файл найден: ", path)
		if image_label:
			image_label.text = "Файл: " + path.get_file()
		var main_scene = get_tree().current_scene
		if main_scene and main_scene.has_method("set_custom_texture_for_bottle"):
			main_scene.set_custom_texture_for_bottle(path)
			print("Картинка применена ко всем банкам: ", path)
		else:
			print("Ошибка: основная сцена не имеет метода set_custom_texture_for_bottle!")
		var config = ConfigFile.new()
		config.load(SETTINGS_PATH)
		config.set_value("settings", "custom_bottle_texture", path)
		config.save(SETTINGS_PATH)
		print("Картинка сохранена: ", path)
	else:
		print("Выбор картинки отменён или файл не выбран")

# === Очистка картинки ===
func _clear_image():
	print("=== _clear_image ===")
	if image_label:
		image_label.text = "Файл: нет"
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("clear_custom_texture_for_bottle"):
		main_scene.clear_custom_texture_for_bottle()
		print("Картинка очищена у всех банок")
	else:
		print("Ошибка: основная сцена не имеет метода clear_custom_texture_for_bottle!")
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("settings", "custom_bottle_texture", "")
	config.save(SETTINGS_PATH)
	print("Картинка очищена")

# === Отложенная загрузка сохранённой картинки ===
func _load_saved_image_deferred():
	print("=== _load_saved_image_deferred ===")
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	if error == OK:
		var saved_path = config.get_value("settings", "custom_bottle_texture", "")
		print("Сохранённый путь: ", saved_path)
		if saved_path != "" and FileAccess.file_exists(saved_path):
			if image_label:
				image_label.text = "Файл: " + saved_path.get_file()
			var main_scene = get_tree().current_scene
			if main_scene and main_scene.has_method("set_custom_texture_for_bottle"):
				main_scene.set_custom_texture_for_bottle(saved_path)
				print("Загружена сохранённая картинка: ", saved_path)
			else:
				print("Ошибка: основная сцена не имеет метода set_custom_texture_for_bottle!")
		else:
			if image_label:
				image_label.text = "Файл: нет"
			print("Сохранённая картинка не найдена")
	else:
		print("Файл настроек не найден")

# === Сохранение всех настроек ===
func _save_settings():
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	if error != OK:
		config = ConfigFile.new()
	if color_picker:
		config.set_value("settings", "color_r", color_picker.color.r)
		config.set_value("settings", "color_g", color_picker.color.g)
		config.set_value("settings", "color_b", color_picker.color.b)
		config.set_value("settings", "color_a", color_picker.color.a)
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("get_max_bottles"):
		config.set_value("settings", "max_bottles", main_scene.get_max_bottles())
	if image_label and image_label.text != "Файл: нет":
		var current_text = image_label.text
		if current_text.begins_with("Файл: "):
			var path = current_text.replace("Файл: ", "")
			if FileAccess.file_exists(path):
				config.set_value("settings", "custom_bottle_texture", path)
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
	var color = Color(
		config.get_value("settings", "color_r", 0.3),
		config.get_value("settings", "color_g", 0.3),
		config.get_value("settings", "color_b", 0.3),
		config.get_value("settings", "color_a", 1.0)
	)
	RenderingServer.set_default_clear_color(color)
	if color_picker:
		color_picker.color = color
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
