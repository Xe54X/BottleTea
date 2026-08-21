extends StaticBody2D

# Загружаем сцену банки
@export var bottle_scene: PackedScene = preload("res://Tscn/Bottle.tscn")

# Ссылка на контейнер для банок
@onready var jars_container = $SpawnBottle

# Путь к файлу сохранения
const SAVE_PATH = "user://bottles_save.cfg"

# Настройки спавна
@export var spawn_center: Vector2 = Vector2(500, 300)  # Центральная точка спавна
@export var spawn_radius: float = 20.0  # Радиус спавна вокруг точки

func _ready() -> void:
	# Автоматическая загрузка при старте
	_load_bottles()

func _process(_delta: float) -> void:
	# Спавн банки
	if Input.is_action_just_pressed("spawn_bottle"):
		_spawn_bottle()
	
	# Удалить последнюю банку
	if Input.is_action_just_pressed("despawn_bottle"):
		_despawn_last_bottle()
	
	# Удалить все банки
	if Input.is_action_just_pressed("clear_bottle"):
		_clear_all_bottles()
	
	# Сохранить
	if Input.is_action_just_pressed("save_game"):
		_save_bottles()
	
	# Загрузить
	if Input.is_action_just_pressed("load_game"):
		_load_bottles()

# === Спавн одной банки ===
func _spawn_bottle():
	if jars_container == null:
		print("Ошибка: контейнер не найден!")
		return
	
	var new_bottle = bottle_scene.instantiate()
	
	# Случайная позиция вокруг точки с радиусом 20
	var random_angle = randf_range(0, 2 * PI)  # Случайный угол
	var random_distance = randf_range(0, spawn_radius)  # Случайное расстояние от 0 до 20
	
	new_bottle.position = spawn_center + Vector2(
		cos(random_angle) * random_distance,
		sin(random_angle) * random_distance
	)
	
	# Небольшой случайный наклон
	new_bottle.rotation = randf_range(-0.3, 0.3)
	
	jars_container.add_child(new_bottle)
	print("Создана банка! Всего: ", jars_container.get_child_count())

# === Удалить последнюю банку ===
func _despawn_last_bottle():
	if jars_container == null or jars_container.get_child_count() == 0:
		return
	
	var last_bottle = jars_container.get_child(jars_container.get_child_count() - 1)
	last_bottle.queue_free()
	print("Удалена банка! Осталось: ", jars_container.get_child_count() - 1)

# === Удалить все банки ===
func _clear_all_bottles():
	if jars_container == null:
		return
	
	for child in jars_container.get_children():
		child.queue_free()
	print("Удалены все банки!")

# === Сохранить с помощью ConfigFile ===
func _save_bottles():
	if jars_container == null:
		return
	
	var config = ConfigFile.new()
	
	config.set_value("bottles", "count", jars_container.get_child_count())
	
	for i in range(jars_container.get_child_count()):
		var bottle = jars_container.get_child(i)
		# Сохраняем position, а не global_position
		config.set_value("bottle_" + str(i), "position_x", bottle.position.x)
		config.set_value("bottle_" + str(i), "position_y", bottle.position.y)
		config.set_value("bottle_" + str(i), "rotation", bottle.rotation)
	
	var error = config.save(SAVE_PATH)
	if error == OK:
		print("Сохранено банок: ", jars_container.get_child_count())
	else:
		print("Ошибка сохранения: ", error)

# === Загрузить с помощью ConfigFile ===
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
		# Используем position вместо global_position
		new_bottle.position = Vector2(
			config.get_value("bottle_" + str(i), "position_x", 0),
			config.get_value("bottle_" + str(i), "position_y", 0)
		)
		new_bottle.rotation = config.get_value("bottle_" + str(i), "rotation", 0)
		jars_container.add_child(new_bottle)
	
	print("Загружено банок: ", count)

# === Автосохранение при выходе ===
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_bottles()
