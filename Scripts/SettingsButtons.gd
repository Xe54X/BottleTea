extends ScrollContainer

#===================================#
@onready var button_settings: Button = $VBoxContainer/ButtonSettings/HBoxContainer/Settings
@onready var button_statistic: Button = $VBoxContainer/ButtonSettings/HBoxContainer/Statistic
@onready var button_language: Button = $VBoxContainer/ButtonSettings/HBoxContainer/Language
@onready var button_custom: Button = $VBoxContainer/ButtonSettings/HBoxContainer/Custom

@onready var sattings: VBoxContainer = $VBoxContainer/Sattings
@onready var statistics_bottle: VBoxContainer = $VBoxContainer/StatisticsBottle
@onready var custom: VBoxContainer = $VBoxContainer/Custom
@onready var localization: VBoxContainer = $VBoxContainer/Localization

#===================================#
func _ready() -> void:
	_signal_connect()
	_show_settings()

#===================================#
# Подключение всех сигналов
func _signal_connect():
	button_settings.pressed.connect(_show_settings)
	button_statistic.pressed.connect(_show_statistics)
	button_language.pressed.connect(_show_language)
	button_custom.pressed.connect(_show_custom)

#===================================#
# Показать настройки
func _show_settings():
	_hide_all()
	sattings.visible = true
	_update_button_states(button_settings)

#===================================#
# Показать статистику
func _show_statistics():
	_hide_all()
	statistics_bottle.visible = true
	_update_button_states(button_statistic)

#===================================#
# Показать язык
func _show_language():
	_hide_all()
	localization.visible = true
	_update_button_states(button_language)

#===================================#
# Показать кастомизацию
func _show_custom():
	_hide_all()
	custom.visible = true
	_update_button_states(button_custom)

#===================================#
# Скрыть все вкладки
func _hide_all():
	sattings.visible = false
	statistics_bottle.visible = false
	custom.visible = false
	localization.visible = false

#===================================#
# Обновление состояния кнопок
func _update_button_states(active_button: Button):
	# Сбрасываем все кнопки
	button_settings.button_pressed = false
	button_statistic.button_pressed = false
	button_language.button_pressed = false
	button_custom.button_pressed = false
	
	# Активируем нужную кнопку
	active_button.button_pressed = true

#===================================#
