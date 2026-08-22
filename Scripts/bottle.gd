extends StaticBody2D

# Загружаем сцену банки
@export var bottle_scene: PackedScene = preload("res://Tscn/Bottle.tscn")

# Ссылка на контейнер для банок
@onready var jars_container = $SpawnBottle

@onready var options: CanvasLayer = $Options

# Путь к файлу сохранения
const SAVE_PATH = "user://bottles_save.cfg"

# Настройки спавна
@export var spawn_center: Vector2 = Vector2(500, 300)
@export var spawn_radius: float = 20.0
@export var min_distance_between_bottles: float = 40.0
@export var max_spawn_attempts: int = 30
@export var max_bottles: int = 450

func _ready() -> void:
	options.visible = false
	
	# === Загружаем максимум банок из настроек ===
	_load_max_bottles_from_settings()
	
	_load_bottles()
	_disable_physics_for_all_bottles()  # Отключаем физику после загрузки

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("spawn_bottle"):
		_spawn_bottle()
	
	if Input.is_action_just_pressed("despawn_bottle"):
		_despawn_last_bottle()
	
	if Input.is_action_just_pressed("clear_bottle"):
		_clear_all_bottles()
	
	if Input.is_action_just_pressed("save_game"):
		_save_bottles()
	
	if Input.is_action_just_pressed("load_game"):
		_load_bottles()
	
	if Input.is_action_just_pressed("options"):
		_toggle_options()

# ============================================
# === НОВЫЕ ФУНКЦИИ ДЛЯ РАБОТЫ С НАСТРОЙКАМИ ===
# ============================================

# === Загрузка максимума банок из настроек ===
func _load_max_bottles_from_settings():
	var config = ConfigFile.new()
	var error = config.load("user://settings.cfg")
	
	if error == OK:
		var saved_max = config.get_value("game", "max_bottles", 450)
		max_bottles = saved_max
		print("Загружен лимит банок из настроек: ", max_bottles)
	else:
		print("Настройки не найдены, использую стандартный лимит: ", max_bottles)

# === Установка нового максимума (вызывается из настроек) ===
func set_max_bottles(new_max: int):
	if new_max > 0:
		max_bottles = new_max
		print("Новый максимум банок: ", max_bottles)
		
		# Если текущих банок больше нового лимита, удаляем лишние
		if jars_container:
			while jars_container.get_child_count() > max_bottles:
				var last_bottle = jars_container.get_child(jars_container.get_child_count() - 1)
				last_bottle.queue_free()
				print("Удалена лишняя банка (превышен лимит)")
	else:
		print("Ошибка: максимальное количество должно быть больше 0!")

# === Получение текущего максимума ===
func get_max_bottles() -> int:
	return max_bottles

# ============================================
# === ОСТАЛЬНЫЕ ФУНКЦИИ (без изменений) ===
# ============================================

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
	new_bottle.rotation = randf_range(-0.3, 0.3)
	
	# Отключаем физику для новой банки
	_disable_physics_for_bottle(new_bottle)
	
	jars_container.add_child(new_bottle)
	print("Создана банка! Всего: ", jars_container.get_child_count(), " / ", max_bottles)

func _disable_physics_for_bottle(bottle: Node) -> void:
	if bottle is StaticBody2D:
		bottle.collision_layer = 0
		bottle.collision_mask = 0
		bottle.set_physics_process(false)
		
		# Отключаем все CollisionShape2D
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

func _despawn_last_bottle():
	if jars_container == null or jars_container.get_child_count() == 0:
		return
	
	var last_bottle = jars_container.get_child(jars_container.get_child_count() - 1)
	last_bottle.queue_free()
	print("Удалена банка! Осталось: ", jars_container.get_child_count() - 1)

func _clear_all_bottles():
	if jars_container == null:
		return
	
	for child in jars_container.get_children():
		child.queue_free()
	print("Удалены все банки!")

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
	
	var error = config.save(SAVE_PATH)
	if error == OK:
		print("Сохранено банок: ", jars_container.get_child_count())
	else:
		print("Ошибка сохранения: ", error)

func _load_bottles():
	if jars_container == null:
		return
	
	_clear_all_bottles()
	
	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)
	
	if error != OK:
		print("Файл сохранения не найден")
		return
	
	var count = config.get_value("bottles", "count", 0)
	
	for i in range(count):
		var new_bottle = bottle_scene.instantiate()
		new_bottle.position = Vector2(
			config.get_value("bottle_" + str(i), "position_x", 0),
			config.get_value("bottle_" + str(i), "position_y", 0)
		)
		new_bottle.rotation = config.get_value("bottle_" + str(i), "rotation", 0)
		
		# Отключаем физику для загруженных банок
		_disable_physics_for_bottle(new_bottle)
		
		jars_container.add_child(new_bottle)
	
	print("Загружено банок: ", count)
	_disable_physics_for_all_bottles()  # Дополнительно отключаем физику

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_bottles()

func _toggle_options():
	if options.visible:
		options.visible = false
	else:
		options.visible = true
