extends CanvasLayer

@onready var color_picker: ColorPicker = $ScrollContainer/VBoxContainer/Color/Color/ColorPicker
@onready var apply_button: Button = $ScrollContainer/VBoxContainer/Color/Color/Buttons/ApplyButton
@onready var reset_button: Button = $ScrollContainer/VBoxContainer/Color/Color/Buttons/ResetButton
@onready var max_bottle_line_edit: LineEdit = $ScrollContainer/VBoxContainer/VBoxContainer/MaxBottle/LineEdit
@onready var max_bottle_apply_button: Button = $ScrollContainer/VBoxContainer/VBoxContainer/MaxBottle/ApplyButton
@onready var add_image_button: Button = $ScrollContainer/VBoxContainer/CustomBottle/HBoxContainer/Buttons/Add
@onready var clear_image_button: Button = $ScrollContainer/VBoxContainer/CustomBottle/HBoxContainer/Buttons/Clear
@onready var image_label: Label = $ScrollContainer/VBoxContainer/CustomBottle/HBoxContainer/Preview/ImagePathLabel
@onready var image_preview: TextureRect = $ScrollContainer/VBoxContainer/CustomBottle/HBoxContainer/Preview/ImagePreview/TextureRect

# === Новые узлы для зума ===
@onready var zoom_slider: HSlider = $ScrollContainer/VBoxContainer/Zoom/HBoxContainer2/HBoxContainer/HSlider
@onready var zoom_label: Label = $ScrollContainer/VBoxContainer/Zoom/HBoxContainer2/HBoxContainer/Label
@onready var zoom_reset_button: Button = $ScrollContainer/VBoxContainer/Zoom/HBoxContainer2/Button

const SETTINGS_PATH = "user://Config.cfg"

func _ready() -> void:
	_load_settings()
	_load_window_size()  # Загружаем размер окна
	_load_saved_zoom()   # Загружаем зум
	
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
	if image_preview:
		image_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image_preview.custom_minimum_size = Vector2(100, 100)
	
	# === Подключаем зум ===
	if zoom_slider:
		zoom_slider.min_value = 0.1
		zoom_slider.max_value = 3.0
		zoom_slider.step = 0.1
		zoom_slider.value = 1.0
		zoom_slider.value_changed.connect(_on_zoom_changed)
	if zoom_reset_button:
		zoom_reset_button.pressed.connect(_reset_zoom)
	
	# Подключаем сигнал изменения размера окна
	get_tree().root.size_changed.connect(_on_window_size_changed)
	
	call_deferred("_load_saved_image_deferred")

# === Обработка изменения размера окна ===
func _on_window_size_changed():
	_save_window_size()

# === Сохранение размера окна ===
func _save_window_size():
	var window_size = DisplayServer.window_get_size()
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("window", "width", window_size.x)
	config.set_value("window", "height", window_size.y)
	config.save(SETTINGS_PATH)

# === Загрузка размера окна ===
func _load_window_size():
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	if error == OK:
		var width = config.get_value("window", "width", 1152)
		var height = config.get_value("window", "height", 648)
		DisplayServer.window_set_size(Vector2i(width, height))
		print("Размер окна загружен: ", width, "x", height)

# === Обработка изменения зума ===
func _on_zoom_changed(value: float):
	var camera = _get_camera()
	if camera:
		camera.zoom = Vector2(value, value)
		if zoom_label:
			zoom_label.text = "Зум: " + str(round(value * 100)) + "%"
		_save_zoom(value)
	else:
		print("Камера не найдена!")

# === Сброс зума ===
func _reset_zoom():
	if zoom_slider:
		zoom_slider.value = 1.0
	_on_zoom_changed(1.0)

# === Получение камеры ===
func _get_camera():
	var viewport = get_viewport()
	if viewport:
		return viewport.get_camera_2d()
	return null

# === Сохранение зума ===
func _save_zoom(value: float):
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("settings", "zoom", value)
	config.save(SETTINGS_PATH)

# === Загрузка зума ===
func _load_saved_zoom():
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	if error == OK:
		var saved_zoom = config.get_value("settings", "zoom", 1.0)
		if zoom_slider:
			zoom_slider.value = saved_zoom
		_on_zoom_changed(saved_zoom)

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
	if status and selected_paths.size() > 0:
		var source_path = selected_paths[0]
		if not FileAccess.file_exists(source_path):
			print("Ошибка: файл не существует! Путь: ", source_path)
			return
		print("Файл найден: ", source_path)
		var user_path = _copy_image_to_user_dir(source_path)
		if user_path != "":
			if image_label:
				image_label.text = "Файл: " + user_path.get_file()
			_update_image_preview(user_path)
			var main_scene = get_tree().current_scene
			if main_scene and main_scene.has_method("set_custom_texture_for_bottle"):
				main_scene.set_custom_texture_for_bottle(user_path)
				print("Картинка применена ко всем банкам: ", user_path)
			var config = ConfigFile.new()
			config.load(SETTINGS_PATH)
			config.set_value("settings", "custom_bottle_texture", user_path)
			config.save(SETTINGS_PATH)
			print("Картинка сохранена: ", user_path)
		else:
			print("Ошибка копирования файла!")

# === Копирование изображения в user:// директорию ===
func _copy_image_to_user_dir(source_path: String) -> String:
	var file_name = source_path.get_file()
	var user_dir = "user://images/"
	if not DirAccess.dir_exists_absolute(user_dir):
		DirAccess.make_dir_recursive_absolute(user_dir)
	var target_path = user_dir + file_name
	var source_file = FileAccess.open(source_path, FileAccess.READ)
	if source_file == null:
		print("Ошибка: не удалось открыть файл - ", source_path)
		return ""
	var file_data = source_file.get_buffer(source_file.get_length())
	source_file.close()
	var target_file = FileAccess.open(target_path, FileAccess.WRITE)
	if target_file == null:
		print("Ошибка: не удалось создать файл - ", target_path)
		return ""
	target_file.store_buffer(file_data)
	target_file.close()
	print("Файл скопирован: ", target_path)
	return target_path

# === Обновление превью картинки ===
func _update_image_preview(path: String):
	if image_preview == null:
		return
	if path == "" or not FileAccess.file_exists(path):
		image_preview.texture = null
		image_preview.visible = false
		return
	var image = Image.load_from_file(path)
	if image:
		var texture = ImageTexture.create_from_image(image)
		image_preview.texture = texture
		image_preview.visible = true
		print("Превью обновлено: ", path)
	else:
		print("Ошибка загрузки изображения для превью!")
		image_preview.texture = null
		image_preview.visible = false

# === Очистка картинки ===
func _clear_image():
	print("=== _clear_image ===")
	if image_label:
		image_label.text = "Файл: нет"
	if image_preview:
		image_preview.texture = null
		image_preview.visible = false
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("clear_custom_texture_for_bottle"):
		main_scene.clear_custom_texture_for_bottle()
		print("Картинка очищена у всех банок")
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
			_update_image_preview(saved_path)
			var main_scene = get_tree().current_scene
			if main_scene and main_scene.has_method("set_custom_texture_for_bottle"):
				main_scene.set_custom_texture_for_bottle(saved_path)
				print("Загружена сохранённая картинка: ", saved_path)
		else:
			if image_label:
				image_label.text = "Файл: нет"
			if image_preview:
				image_preview.visible = false
			print("Сохранённая картинка не найдена")

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
