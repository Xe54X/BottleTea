extends VBoxContainer

@onready var spawn_bottle_label: Label = $SpawnBottle                            # Сейчас заспавнено
@onready var all_spawn_bottle_label: Label = $AllSawnBottle                      # Всего заспавнено

var current_bottles: int = 0
var total_bottles_spawned: int = 0

const STATS_PATH = "user://bottle_stats.cfg"

func _ready() -> void:
	_load_stats()
	_update_ui()
	if spawn_bottle_label == null:
		print("Ошибка: узел SpawnBottle не найден!")
	if all_spawn_bottle_label == null:
		print("Ошибка: узел AllSpawnBottle не найден!")

# === Обновление статистики при спавне ===
func on_bottle_spawned():
	current_bottles += 1
	total_bottles_spawned += 1
	_update_ui()
	_save_stats()
	print("Банка создана! Текущее количество: ", current_bottles, ", Всего создано: ", total_bottles_spawned)

# === Обновление статистики при удалении одной банки ===
func on_bottle_removed():
	current_bottles -= 1
	if current_bottles < 0:
		current_bottles = 0
	_update_ui()
	_save_stats()
	print("Банка удалена! Текущее количество: ", current_bottles)

# === Обновление статистики при очистке всех банок ===
func on_all_bottles_cleared():
	current_bottles = 0
	_update_ui()
	_save_stats()
	print("Все банки удалены! Текущее количество: ", current_bottles)

# === Обновление текущего количества (при загрузке) ===
func update_current_count(count: int):
	current_bottles = count
	_update_ui()
	print("Обновлено текущее количество банок: ", current_bottles)

# === Обновление UI ===
func _update_ui():
	if spawn_bottle_label:
		spawn_bottle_label.text = "Сейчас банок: " + str(current_bottles)
	else:
		print("Ошибка: spawn_bottle_label не найден!")
	if all_spawn_bottle_label:
		all_spawn_bottle_label.text = "Всего заспавнено: " + str(total_bottles_spawned)
	else:
		print("Ошибка: all_spawn_bottle_label не найден!")

# === Сохранение статистики ===
func _save_stats():
	var config = ConfigFile.new()
	config.set_value("stats", "total_bottles_spawned", total_bottles_spawned)
	var error = config.save(STATS_PATH)
	if error == OK:
		print("Статистика сохранена: Всего банок - ", total_bottles_spawned)
	else:
		print("Ошибка сохранения статистики: ", error)

# === Загрузка статистики ===
func _load_stats():
	var config = ConfigFile.new()
	var error = config.load(STATS_PATH)
	if error == OK:
		total_bottles_spawned = config.get_value("stats", "total_bottles_spawned", 0)
		print("Статистика загружена: Всего банок - ", total_bottles_spawned)
	else:
		print("Файл статистики не найден, начинаем с нуля")
		total_bottles_spawned = 0

# === Сброс статистики ===
func reset_stats():
	current_bottles = 0
	total_bottles_spawned = 0
	_update_ui()
	_save_stats()
	print("Статистика сброшена!")

# === Получение текущих значений ===
func get_current_bottles() -> int:
	return current_bottles

func get_total_bottles_spawned() -> int:
	return total_bottles_spawned
