extends VBoxContainer

#===================================#
@onready var spawn_bottle_label: Label = $SpawnBottle                            # Сейчас заспавнено
@onready var all_spawn_bottle_label: Label = $AllSawnBottle                      # Всего заспавнено

#===================================#
var current_bottles: int = 0
var total_bottles_spawned: int = 0

#===================================#
const CONFIG_PATH = "user://Config.cfg"

#===================================#
func _ready() -> void:
	add_to_group("localizable")
	_load_stats()
	_update_ui()

#===================================#
#Обновление статистики при спавне
func on_bottle_spawned():
	current_bottles += 1
	total_bottles_spawned += 1
	_update_ui()
	_save_stats()

#===================================#
#Обновление статистики при удалении одной банки
func on_bottle_removed():
	current_bottles -= 1
	if current_bottles < 0:
		current_bottles = 0
	_update_ui()
	_save_stats()

#===================================#
#Обновление статистики при очистке всех банок
func on_all_bottles_cleared():
	current_bottles = 0
	_update_ui()
	_save_stats()

#===================================#
#Обновление текущего количества (при загрузке)
func update_current_count(count: int):
	current_bottles = count
	_update_ui()
	_save_stats()

#===================================#
#Загрузка статистики из общего файла
func load_stats(total: int, current: int):
	total_bottles_spawned = total
	current_bottles = current
	_update_ui()

#===================================#
#Обновление UI
func _update_ui():
	if spawn_bottle_label:
		spawn_bottle_label.text = tr("loc_CurrentBottles") + ": " + str(current_bottles)
	if all_spawn_bottle_label:
		all_spawn_bottle_label.text = tr("loc_AllBottles") + ": " + str(total_bottles_spawned)

#===================================#
#Сохранение статистики в общий файл
func _save_stats():
	var config = ConfigFile.new()
	var error = config.load(CONFIG_PATH)
	if error != OK:
		config = ConfigFile.new()
	config.set_value("stats", "total_bottles_spawned", total_bottles_spawned)
	config.set_value("stats", "current_bottles", current_bottles)
	config.save(CONFIG_PATH)

#===================================#
#Загрузка статистики из общего файла
func _load_stats():
	var config = ConfigFile.new()
	var error = config.load(CONFIG_PATH)
	if error == OK:
		total_bottles_spawned = config.get_value("stats", "total_bottles_spawned", 0)
		current_bottles = config.get_value("stats", "current_bottles", 0)
	else:
		total_bottles_spawned = 0
		current_bottles = 0

#===================================#
#Сброс статистики
func reset_stats():
	current_bottles = 0
	total_bottles_spawned = 0
	_update_ui()
	_save_stats()

#===================================#
#Получение текущих значений
func get_current_bottles() -> int:
	return current_bottles

#===================================#
func get_total_bottles_spawned() -> int:
	return total_bottles_spawned

#===================================#
#Обновление локализации
func update_localization():
	_update_ui()
