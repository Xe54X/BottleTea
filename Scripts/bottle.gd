extends RigidBody2D

#===================================#
@onready var base_bottle: Sprite2D = $Polygon2D/BaseBottle
@onready var custom_bottle: Sprite2D = $Polygon2D/CustomBottle

#===================================#
var custom_texture_path: String = ""

#===================================#
@export var custom_texture_scale: Vector2 = Vector2(0.16, 0.16)

#===================================#
func _ready():
	_setup_custom_bottle()
	_load_custom_texture()

#===================================#
func _setup_custom_bottle():
	if custom_bottle:
		custom_bottle.position = Vector2(0, 0)
		custom_bottle.rotation = 0
		custom_bottle.offset = Vector2(0, 0)
		custom_bottle.centered = true
		custom_bottle.visible = true
		custom_bottle.region_enabled = false
		custom_bottle.scale = custom_texture_scale

#===================================#
#Загрузка картинки из любого места
func load_custom_texture(texture_path: String):
	if custom_bottle == null:
		return
	if texture_path == "" or texture_path == "null":
		clear_custom_texture()
		return
	if not FileAccess.file_exists(texture_path):
		return
	var image = Image.load_from_file(texture_path)
	if image:
		var texture = ImageTexture.create_from_image(image)
		if texture:
			custom_bottle.texture = texture
			custom_bottle.scale = custom_texture_scale
			custom_bottle.rotation = 0
			custom_bottle.offset = Vector2(0, 0)
			custom_bottle.centered = true
			custom_bottle.region_enabled = false
			custom_bottle.visible = true
			if base_bottle:
				base_bottle.visible = false
			custom_texture_path = texture_path
			_save_texture_path()
			return

#===================================#
func clear_custom_texture():
	if custom_bottle:
		custom_bottle.texture = null
		custom_bottle.visible = false
		custom_bottle.region_enabled = false
		custom_bottle.offset = Vector2(0, 0)
		custom_bottle.scale = custom_texture_scale
		custom_texture_path = ""
		if base_bottle:
			base_bottle.visible = true
		_save_texture_path()

#===================================#
func _save_texture_path():
	var config = ConfigFile.new()
	var error = config.load("user://Config.cfg")
	if error != OK:
		config = ConfigFile.new()
	config.set_value("bottle_texture", "path", custom_texture_path)
	config.save("user://Config.cfg")

#===================================#
func _load_custom_texture():
	var config = ConfigFile.new()
	var error = config.load("user://Config.cfg")
	if error == OK:
		var saved_path = config.get_value("bottle_texture", "path", "")
		if saved_path != "" and FileAccess.file_exists(saved_path):
			load_custom_texture(saved_path)
		else:
			if custom_bottle:
				custom_bottle.visible = false
			if base_bottle:
				base_bottle.visible = true

#===================================#
func set_custom_texture_from_file(file_path: String):
	load_custom_texture(file_path)
	_save_texture_path()

#===================================#
func get_custom_texture() -> Texture2D:
	if custom_bottle:
		return custom_bottle.texture
	return null

#===================================#
func get_custom_texture_path() -> String:
	return custom_texture_path
