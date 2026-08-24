extends CanvasLayer

#===================================#
@onready var color_picker: ColorPicker = $ScrollContainer/VBoxContainer/Color/Color/ColorPicker
@onready var color_apply_button: Button = $ScrollContainer/VBoxContainer/Color/Color/Buttons/ApplyButton
@onready var color_reset_button: Button = $ScrollContainer/VBoxContainer/Color/Color/Buttons/ResetButton
@onready var max_bottle_line_edit: LineEdit = $ScrollContainer/VBoxContainer/MaxBottle/MaxBottle/LineEdit
@onready var max_bottle_apply_button: Button = $ScrollContainer/VBoxContainer/MaxBottle/MaxBottle/ApplyButton
@onready var image_add_button: Button = $ScrollContainer/VBoxContainer/CustomBottle/HBoxContainer/Buttons/Add
@onready var image_clear_button: Button = $ScrollContainer/VBoxContainer/CustomBottle/HBoxContainer/Buttons/Clear
@onready var image_label: Label = $ScrollContainer/VBoxContainer/CustomBottle/HBoxContainer/Preview/ImagePathLabel
@onready var image_preview: TextureRect = $ScrollContainer/VBoxContainer/CustomBottle/HBoxContainer/Preview/ImagePreview/TextureRect
@onready var zoom_slider: HSlider = $ScrollContainer/VBoxContainer/Zoom/HBoxContainer2/HBoxContainer/HSlider
@onready var zoom_label: Label = $ScrollContainer/VBoxContainer/Zoom/HBoxContainer2/HBoxContainer/Label
@onready var zoom_reset_button: Button = $ScrollContainer/VBoxContainer/Zoom/HBoxContainer2/Button
@onready var language_eng_button: Button = $ScrollContainer/VBoxContainer/Localization/Buttons/ENG
@onready var language_rus_button: Button = $ScrollContainer/VBoxContainer/Localization/Buttons/RUS
@onready var language_jpn_button: Button = $ScrollContainer/VBoxContainer/Localization/Buttons/JPN

#===================================#
const SETTINGS_PATH = "user://Config.cfg"

#===================================#
var camera_scroll_speed: float = 10.0
var camera_min_y: float = -1000.0
var camera_max_y: float = 1000.0
var current_language := "en"
var zoom_step: float = 0.1  # Шаг изменения зума

#===================================#
func _ready() -> void:
	_load_settings()
	_load_window_size()
	_load_saved_zoom()
	_signal_connect()
	if image_preview:
		image_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image_preview.custom_minimum_size = Vector2(100, 100)
	if zoom_slider:
		zoom_slider.min_value = 0.1
		zoom_slider.max_value = 3.0
		zoom_slider.step = 0.1
		zoom_slider.value = 1.0
	get_tree().root.size_changed.connect(_on_window_size_changed)
	call_deferred("_load_saved_image_deferred")

#===================================#
# Подключение всех сигналов
func _signal_connect():
	color_apply_button.pressed.connect(_apply_color)
	color_reset_button.pressed.connect(_reset_color)
	color_picker.color_changed.connect(_on_color_changed)
	max_bottle_apply_button.pressed.connect(_apply_max_bottles)
	max_bottle_line_edit.text_submitted.connect(_apply_max_bottles)
	image_add_button.pressed.connect(_add_image)
	image_clear_button.pressed.connect(_clear_image)
	zoom_slider.value_changed.connect(_on_zoom_changed)
	zoom_reset_button.pressed.connect(_reset_zoom)
	language_eng_button.pressed.connect(func(): _set_language("en"))
	language_rus_button.pressed.connect(func(): _set_language("ru"))
	language_jpn_button.pressed.connect(func(): _set_language("ja"))

#===================================#
# Установка языка
func _set_language(lang: String):
	current_language = lang
	TranslationServer.set_locale(lang)
	_save_language(lang)
	_update_ui()
	_update_image_label()

#===================================#
# Обновление текста label с картинкой
func _update_image_label():
	if image_label == null:
		return
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	if error == OK:
		var saved_path = config.get_value("settings", "custom_bottle_texture", "")
		if saved_path != "" and FileAccess.file_exists(saved_path):
			image_label.text = tr("loc_File") + ": " + saved_path.get_file()
		else:
			image_label.text = tr("loc_FileNone")
	else:
		image_label.text = tr("loc_FileNone")

#===================================#
# Сохранение языка
func _save_language(lang: String):
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	if error != OK:
		config = ConfigFile.new()
	config.set_value("settings", "language", lang)
	config.save(SETTINGS_PATH)

#===================================#
func _input(event: InputEvent) -> void:
	if visible:
		return
	
	if event is InputEventMouseButton:
		if event.pressed:
			# Проверяем, зажат ли Ctrl
			if Input.is_key_pressed(KEY_CTRL):
				# Если Ctrl зажат - меняем зум
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					_zoom_in()
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					_zoom_out()
			else:
				# Если Ctrl не зажат - скроллим камеру
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					_scroll_camera(-camera_scroll_speed)
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					_scroll_camera(camera_scroll_speed)

#===================================#
# Увеличение зума
func _zoom_in():
	if zoom_slider:
		var new_zoom = zoom_slider.value + zoom_step
		zoom_slider.value = clamp(new_zoom, zoom_slider.min_value, zoom_slider.max_value)

#===================================#
# Уменьшение зума
func _zoom_out():
	if zoom_slider:
		var new_zoom = zoom_slider.value - zoom_step
		zoom_slider.value = clamp(new_zoom, zoom_slider.min_value, zoom_slider.max_value)

#===================================#
#Переключение видимости настроек с паузой
func toggle_settings():
	visible = not visible

#===================================#
#Скролл камеры
func _scroll_camera(amount: float):
	var camera = _get_camera()
	if camera:
		var new_position = camera.position
		new_position.y += amount
		new_position.y = clamp(new_position.y, camera_min_y, camera_max_y)
		camera.position = new_position

#===================================#
#Обработка изменения размера окна
func _on_window_size_changed():
	_save_window_size()

#===================================#
#Сохранение размера окна
func _save_window_size():
	var window_size = DisplayServer.window_get_size()
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("window", "width", window_size.x)
	config.set_value("window", "height", window_size.y)
	config.save(SETTINGS_PATH)

#===================================#
#Загрузка размера окна
func _load_window_size():
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	if error == OK:
		var width = config.get_value("window", "width", 1152)
		var height = config.get_value("window", "height", 648)
		DisplayServer.window_set_size(Vector2i(width, height))

#===================================#
#Обработка изменения зума
func _on_zoom_changed(value: float):
	var camera = _get_camera()
	if camera:
		camera.zoom = Vector2(value, value)
		if zoom_label:
			zoom_label.text = str(round(value * 100)) + "%"
		_save_zoom(value)

#===================================#
#Сброс зума
func _reset_zoom():
	if zoom_slider:
		zoom_slider.value = 1.0
	_on_zoom_changed(1.0)

#===================================#
#Получение камеры
func _get_camera():
	var viewport = get_viewport()
	if viewport:
		return viewport.get_camera_2d()
	return null

#===================================#
#Сохранение зума
func _save_zoom(value: float):
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("settings", "zoom", value)
	config.save(SETTINGS_PATH)

#===================================#
#Загрузка зума
func _load_saved_zoom():
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	if error == OK:
		var saved_zoom = config.get_value("settings", "zoom", 1.0)
		if zoom_slider:
			zoom_slider.value = saved_zoom
		_on_zoom_changed(saved_zoom)

#===================================#
#Применение выбранного цвета
func _apply_color():
	if color_picker:
		var selected_color = color_picker.color
		RenderingServer.set_default_clear_color(selected_color)
		_save_settings()

#===================================#
#Сброс цвета к стандартному
func _reset_color():
	var default_color = Color(0.3, 0.3, 0.3, 1.0)
	if color_picker:
		color_picker.color = default_color
	RenderingServer.set_default_clear_color(default_color)
	_save_settings()

#===================================#
#Обработка изменения цвета в ColorPicker
func _on_color_changed(color: Color):
	RenderingServer.set_default_clear_color(color)

#===================================#
#Применить максимальное количество банок
func _apply_max_bottles(_text: String = ""):
	if max_bottle_line_edit == null:
		return
	var max_value = max_bottle_line_edit.text.to_int()
	if max_value <= 0:
		max_bottle_line_edit.text = str(_get_current_max_bottles())
		return
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("set_max_bottles"):
		main_scene.set_max_bottles(max_value)
		_save_settings()

#===================================#
#Добавить картинку через нативный диалог Windows
func _add_image():
	var filters = PackedStringArray()
	filters.append("*.png")
	filters.append("*.jpg")
	filters.append("*.jpeg")
	filters.append("*.bmp")
	filters.append("*.webp")
	filters.append("*.svg")
	DisplayServer.file_dialog_show(
		tr("loc_ChooseImage"),
		_get_desktop_path(),
		"",
		false,
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
		filters,
		_on_image_selected
	)

#===================================#
#Получение пути к рабочему столу
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

#===================================#
#Обработка выбора картинки
func _on_image_selected(status: bool, selected_paths: PackedStringArray, _selected_filter_index: int):
	if status and selected_paths.size() > 0:
		var source_path = selected_paths[0]
		if not FileAccess.file_exists(source_path):
			return
		var user_path = _copy_image_to_user_dir(source_path)
		if user_path != "":
			if image_label:
				image_label.text = tr("loc_File") + ": " + user_path.get_file()
			_update_image_preview(user_path)
			var main_scene = get_tree().current_scene
			if main_scene and main_scene.has_method("set_custom_texture_for_bottle"):
				main_scene.set_custom_texture_for_bottle(user_path)
			var config = ConfigFile.new()
			config.load(SETTINGS_PATH)
			config.set_value("settings", "custom_bottle_texture", user_path)
			config.save(SETTINGS_PATH)

#===================================#
#Копирование изображения в user:// директорию
func _copy_image_to_user_dir(source_path: String) -> String:
	var file_name = source_path.get_file()
	var user_dir = "user://images/"
	if not DirAccess.dir_exists_absolute(user_dir):
		DirAccess.make_dir_recursive_absolute(user_dir)
	var target_path = user_dir + file_name
	var source_file = FileAccess.open(source_path, FileAccess.READ)
	if source_file == null:
		return ""
	var file_data = source_file.get_buffer(source_file.get_length())
	source_file.close()
	var target_file = FileAccess.open(target_path, FileAccess.WRITE)
	if target_file == null:
		return ""
	target_file.store_buffer(file_data)
	target_file.close()
	return target_path

#===================================#
#Обновление превью картинки
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
	else:
		image_preview.texture = null
		image_preview.visible = false

#===================================#
#Очистка картинки
func _clear_image():
	if image_label:
		image_label.text = tr("loc_FileNone")
	if image_preview:
		image_preview.texture = null
		image_preview.visible = false
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("clear_custom_texture_for_bottle"):
		main_scene.clear_custom_texture_for_bottle()
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("settings", "custom_bottle_texture", "")
	config.save(SETTINGS_PATH)

#===================================#
#Отложенная загрузка сохранённой картинки
func _load_saved_image_deferred():
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	if error == OK:
		var saved_path = config.get_value("settings", "custom_bottle_texture", "")
		if saved_path != "" and FileAccess.file_exists(saved_path):
			if image_label:
				image_label.text = tr("loc_File") + ": " + saved_path.get_file()
			_update_image_preview(saved_path)
			var main_scene = get_tree().current_scene
			if main_scene and main_scene.has_method("set_custom_texture_for_bottle"):
				main_scene.set_custom_texture_for_bottle(saved_path)
		else:
			if image_label:
				image_label.text = tr("loc_FileNone")
			if image_preview:
				image_preview.visible = false

#===================================#
#Сохранение всех настроек
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
	config.set_value("settings", "language", current_language)
	config.save(SETTINGS_PATH)

#===================================#
#Загрузка всех настроек
func _load_settings():
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	if error != OK:
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
	
	# Загружаем язык
	var saved_language = config.get_value("settings", "language", "en")
	if saved_language in ["ru", "en", "ja"]:
		current_language = saved_language
		TranslationServer.set_locale(current_language)

#===================================#
#Получение текущего максимума банок
func _get_current_max_bottles() -> int:
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("get_max_bottles"):
		return main_scene.get_max_bottles()
	return 450

#===================================#
#Обновление UI
func _update_ui():
	get_tree().call_group("localizable", "update_localization")
	_update_image_label()

#===================================#
