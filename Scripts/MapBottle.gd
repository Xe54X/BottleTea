extends StaticBody2D

@onready var jars_container = $SpawnBottle
@onready var options: CanvasLayer = $Options
@onready var stats: VBoxContainer = $Options/ScrollContainer/VBoxContainer/StatisticsBottle

const SETTINGS_PATH = "user://Config.cfg"
const BOTTLES_DATA_PATH = "user://BottlesData.cfg"

@export var bottle_scene: PackedScene = preload("res://Tscn/Bottle.tscn")        ## Банка
@export var spawn_center: Vector2 = Vector2(500, 300)                            ## Центр спавна
@export var spawn_radius: float = 20.0                                           ## Радиус спавна
@export var min_distance_between_bottles: float = 40.0                           ## Минимальное расстояние между банками
@export var max_spawn_attempts: int = 30                                         ## Максимальное количество попыток найти свободное место
@export var max_bottles: int = 450                                               ## Максимальное количество банок

# Флаг для блокировки игрового ввода
var game_input_blocked: bool = false

func _ready() -> void:
	options.visible = false
	_load_bottles()
	_load_stats_from_config()
	if stats:
		stats.update_current_count(jars_container.get_child_count())

func _process(_delta: float) -> void:
	# Клавиша O должна работать ВСЕГДА (для открытия/закрытия настроек)
	if Input.is_action_just_pressed("options"):
		_toggle_options()
		return  # Важно: после обработки O выходим
	
	# Если игра на паузе - не обрабатываем остальной игровой ввод
	if game_input_blocked:
		return
	
	if Input.is_action_just_pressed("spawn_bottle"):
		_spawn_bottle()
	if Input.is_action_just_pressed("despawn_bottle"):
		_despawn_last_bottle()
	if Input.is_action_just_pressed("clear_bottle"):
		_clear_all_bottles()
	if Input.is_action_just_pressed("save_game"):
		_save_game()
	if Input.is_action_just_pressed("load_game"):
		_load_game()

# === Переключение настроек ===
func _toggle_options():
	if options.visible:
		# Закрываем настройки
		options.visible = false
		game_input_blocked = false
		# Возвращаем обычный режим курсора (показываем курсор)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		print("Настройки закрыты, игра продолжается")
	else:
		# Открываем настройки
		options.visible = true
		game_input_blocked = true
		# Показываем курсор для работы с настройками
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		print("Настройки открыты, игра на паузе")

func set_custom_texture_for_bottle(texture_path: String):
	print("Путь: ", texture_path)
	if jars_container == null:
		print("Ошибка: jars_container не инициализирован!")
		return
	if not FileAccess.file_exists(texture_path):
		print("Ошибка: файл не существует - ", texture_path)
		return
	var count = 0
	for child in jars_container.get_children():
		if child.has_method("load_custom_texture"):
			child.load_custom_texture(texture_path)
			count += 1
			print("Картинка применена к банке: ", child.name)
	print("Применено к ", count, " банкам")
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("settings", "custom_bottle_texture", texture_path)
	config.save(SETTINGS_PATH)
	print("Картинка сохранена для будущих банок")

func clear_custom_texture_for_bottle():
	print("=== clear_custom_texture_for_bottle ===")
	if jars_container == null:
		print("Ошибка: jars_container не инициализирован!")
		return
	var count = 0
	for child in jars_container.get_children():
		if child.has_method("clear_custom_texture"):
			child.clear_custom_texture()
			count += 1
			print("Картинка очищена у банки: ", child.name)
	print("Очищено у ", count, " банок")
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("settings", "custom_bottle_texture", "")
	config.save(SETTINGS_PATH)
	print("Картинка очищена у всех банок")

func _spawn_bottle():
	if jars_container == null:
		print("Ошибка: контейнер не найден!")
		return
	if jars_container.get_child_count() >= max_bottles:
		print("Достигнут лимит банок: ", max_bottles)
		return
	var new_bottle = bottle_scene.instantiate()
	var spawn_position = _find_free_position()
	if spawn_position == Vector2.ZERO and jars_container.get_child_count() > 0:
		print("Не удалось найти свободное место для банки!")
		new_bottle.queue_free()
		return
	new_bottle.position = spawn_position
	_disable_physics_for_bottle(new_bottle)
	new_bottle.rotation = randf_range(-0.3, 0.3)
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	var saved_texture = config.get_value("settings", "custom_bottle_texture", "")
	if saved_texture != "" and FileAccess.file_exists(saved_texture):
		if new_bottle.has_method("load_custom_texture"):
			new_bottle.load_custom_texture(saved_texture)
			print("Загружена картинка для новой банки")
	jars_container.add_child(new_bottle)
	if stats:
		stats.on_bottle_spawned()
		_save_stats_to_config()
	print("Создана банка! Всего: ", jars_container.get_child_count())

func _find_free_position() -> Vector2:
	for attempt in range(max_spawn_attempts):
		var random_angle = randf_range(0, 2 * PI)
		var random_distance = randf_range(0, spawn_radius)
		var candidate_position = spawn_center + Vector2(
			cos(random_angle) * random_distance,
			sin(random_angle) * random_distance
		)
		if _is_position_free(candidate_position):
			return candidate_position
	return Vector2.ZERO

func _is_position_free(position_to_check: Vector2) -> bool:
	for child in jars_container.get_children():
		if child is StaticBody2D:
			var distance = position_to_check.distance_to(child.position)
			if distance < min_distance_between_bottles:
				return false
	return true

func _disable_physics_for_bottle(bottle: Node) -> void:
	if bottle is StaticBody2D:
		bottle.collision_layer = 0
		bottle.collision_mask = 0
		bottle.set_physics_process(false)
		for child in bottle.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)
			elif child is CollisionPolygon2D:
				child.set_deferred("disabled", true)

func _disable_physics_for_all_bottles() -> void:
	if jars_container == null:
		return
	for child in jars_container.get_children():
		_disable_physics_for_bottle(child)

func _despawn_last_bottle():
	if jars_container == null or jars_container.get_child_count() == 0:
		return
	var last_bottle = jars_container.get_child(jars_container.get_child_count() - 1)
	last_bottle.queue_free()
	if stats:
		stats.on_bottle_removed()
		_save_stats_to_config()
	print("Удалена банка! Осталось: ", jars_container.get_child_count() - 1)

func _clear_all_bottles():
	if jars_container == null:
		return
	for child in jars_container.get_children():
		child.queue_free()
	if stats:
		stats.on_all_bottles_cleared()
		_save_stats_to_config()
	print("Удалены все банки!")

func _save_game():
	_save_bottles()
	_save_stats_to_config()
	print("Игра сохранена!")

func _load_game():
	_load_bottles()
	_load_stats_from_config()
	print("Игра загружена!")

func _save_bottles():
	if jars_container == null:
		return
	var config = ConfigFile.new()
	config.set_value("bottles", "count", jars_container.get_child_count())
	for i in range(jars_container.get_child_count()):
		var bottle = jars_container.get_child(i)
		config.set_value("bottle_" + str(i), "position_x", bottle.position.x)
		config.set_value("bottle_" + str(i), "position_y", bottle.position.y)
		config.set_value("bottle_" + str(i), "rotation", bottle.rotation)
	var error = config.save(BOTTLES_DATA_PATH)
	if error == OK:
		print("Сохранено банок: ", jars_container.get_child_count(), " в файл: ", BOTTLES_DATA_PATH)
	else:
		print("Ошибка сохранения банок: ", error)

func _load_bottles():
	if jars_container == null:
		return
	_clear_all_bottles()
	var config = ConfigFile.new()
	var error = config.load(BOTTLES_DATA_PATH)
	if error != OK:
		print("Файл данных банок не найден: ", BOTTLES_DATA_PATH)
		return
	var count = config.get_value("bottles", "count", 0)
	var settings_config = ConfigFile.new()
	settings_config.load(SETTINGS_PATH)
	var saved_texture = settings_config.get_value("settings", "custom_bottle_texture", "")
	for i in range(count):
		var new_bottle = bottle_scene.instantiate()
		new_bottle.position = Vector2(
			config.get_value("bottle_" + str(i), "position_x", 0),
			config.get_value("bottle_" + str(i), "position_y", 0)
		)
		new_bottle.rotation = config.get_value("bottle_" + str(i), "rotation", 0)
		_disable_physics_for_bottle(new_bottle)
		if saved_texture != "" and FileAccess.file_exists(saved_texture):
			if new_bottle.has_method("load_custom_texture"):
				new_bottle.load_custom_texture(saved_texture)
		jars_container.add_child(new_bottle)
	if stats:
		stats.update_current_count(count)
	print("Загружено банок: ", count, " из файла: ", BOTTLES_DATA_PATH)

func _save_stats_to_config():
	if stats == null:
		return
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	if error != OK:
		config = ConfigFile.new()
	config.set_value("stats", "total_bottles_spawned", stats.get_total_bottles_spawned())
	config.set_value("stats", "current_bottles", stats.get_current_bottles())
	error = config.save(SETTINGS_PATH)
	if error == OK:
		print("Статистика сохранена в Config")
	else:
		print("Ошибка сохранения статистики: ", error)

func _load_stats_from_config():
	if stats == null:
		return
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	if error == OK:
		var total = config.get_value("stats", "total_bottles_spawned", 0)
		var current = config.get_value("stats", "current_bottles", 0)
		stats.load_stats(total, current)
		print("Статистика загружена из Config: Всего - ", total, ", Сейчас - ", current)
	else:
		print("Файл Config не найден, статистика не загружена")

func set_max_bottles(value: int):
	max_bottles = value
	print("Максимум банок установлен: ", max_bottles)

func get_max_bottles() -> int:
	return max_bottles

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_game()
