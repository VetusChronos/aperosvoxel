extends Node

const BlockyGame = preload("./blocky_game.gd")
const BlockyGameScene = preload("./blocky_game.tscn")
const MainMenu = preload("./main_menu.gd")
const UPNPHelper = preload("./upnp_helper.gd")

@onready var _main_menu : MainMenu = get_node("GUI")

@onready var _texture_material = preload("res://src/blocks/terrain_material.tres")
@onready var _texture_material_foliage = preload("res://src/blocks/terrain_material_foliage.tres")
@onready var _texture_material_transparent = preload("res://src/blocks/terrain_material_transparent.tres")

@onready var http_request: HTTPRequest = $AssetsDownloadHTTP
@onready var timer : Timer = $Timer
@onready var assets_label : Label = $GUI/WarningAssets

var _game : BlockyGame
var _upnp_helper : UPNPHelper

var zip_url = "https://github.com/YunaSatoy/aperosvoxel/releases/download/0.0.1.alpha/assets.zip"


func _ready() -> void:
	if not folder_exists("user://resources"):
		var dir : DirAccess = DirAccess.open("user://")
		dir.make_dir("user://resources")
		print("Folder 'resources' not found. Creating...")
		
	if not folder_exists("user://assets"):
		print("Folder 'assets' not found. Starting download...")
		update_label("Folder 'assets' not found. Starting download...")
		download_zip()
	else:
		# Set the images if can find the "assets" folder
		var image = Image.load_from_file("user://assets/textures/terrain.png")
		var texture = ImageTexture.create_from_image(image)
		_texture_material.albedo_texture = texture
		_texture_material_foliage.albedo_texture = texture
		_texture_material_transparent.albedo_texture = texture
		
		var background = Image.load_from_file("user://assets/menu/background.png")
		var background_texture = ImageTexture.create_from_image(background)
		$GUI/Background.texture = background_texture
		print("Folder 'assets' found.")


func update_label(text: String) -> void:
	assets_label.text = text
	assets_label.show()


func _on_main_menu_singleplayer_requested():
	_game = BlockyGameScene.instantiate()
	_game.set_network_mode(BlockyGame.NETWORK_MODE_SINGLEPLAYER)
	add_child(_game)
	_main_menu.hide()


func _on_main_menu_connect_to_server_requested(ip: String, port: int):
	_game = BlockyGameScene.instantiate()
	_game.set_ip(ip)
	_game.set_port(port)
	_game.set_network_mode(BlockyGame.NETWORK_MODE_CLIENT)
	add_child(_game)
	_main_menu.hide()
	get_viewport().get_window().title = "Client"


func _on_main_menu_host_server_requested(port: int):
	if _upnp_helper != null and not _upnp_helper.is_setup():
		_upnp_helper.setup(port, PackedStringArray(["UDP"]), "AperosVoxel", 20 * 60)
	_game = BlockyGameScene.instantiate()
	_game.set_port(port)
	_game.set_network_mode(BlockyGame.NETWORK_MODE_HOST)
	add_child(_game)
	_main_menu.hide()
	get_viewport().get_window().title = "Server"


func _on_main_menu_upnp_toggled(pressed: bool):
	if pressed:
		if _upnp_helper == null:
			_upnp_helper = UPNPHelper.new()
			add_child(_upnp_helper)
	else:
		if _upnp_helper != null:
			_upnp_helper.queue_free()
			_upnp_helper = null


# TODO: Move these methods to separate scripts
func download_zip():
	var err = http_request.request(zip_url)
	if err != OK:
		print("Failed to start the request: ", err)


func folder_exists(path: String) -> bool:
	var dir = DirAccess.open(path)
	if dir:
		return true
	return false


func unzip(path_to_zip: String, destination: String) -> void:
	var zip : ZIPReader = ZIPReader.new()
	
	if zip.open(path_to_zip) == OK:
		for filepath in zip.get_files():
			var zip_directory : String = destination
			
			var dir : DirAccess = DirAccess.open(zip_directory)
			if not dir:
				dir.make_dir_recursive(zip_directory)
				dir = DirAccess.open(zip_directory)
			
			dir.make_dir_recursive(filepath.get_base_dir())
			
			var full_path = "%s/%s" % [zip_directory, filepath]
			print(full_path)
			var file : FileAccess = FileAccess.open(full_path, FileAccess.WRITE)
			if file:
				file.store_buffer(zip.read_file(filepath))
				file.close()
		zip.close()
		print("Extraction complete.")
		update_label("Download and extraction complete.")
		timer.start(5.0)
	else:
		printerr("Error opening zip file: ", zip.open(path_to_zip))


func _on_assets_download_request_completed(result: int, response_code: int, \
	headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var file = FileAccess.open("user://assets.zip", FileAccess.WRITE)
		if file:
			file.store_buffer(body)
			file.close()
			unzip("user://assets.zip", "user://")
		else:
			print("Error saving zip file.")
	else:
		print("Download failed with response code: ", response_code)


func _on_timer_timeout() -> void:
	assets_label.hide()
