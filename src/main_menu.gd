extends Control
class_name MainMenu

signal singleplayer_requested()
signal connect_to_server_requested(ip, port)
signal host_server_requested(port)
signal upnp_toggled(pressed)

@onready var main_menu := $MainMenu
@onready var world_creation := $WorldCreation
@onready var seed_text := $WorldCreation/Seed
@onready var version_text := $Version
@onready var splashes_text := $MainMenu/Splashes

@onready var globals := get_node("/root/Globals")

var save_dir : String = "user://resources/worlds/"
var splashes_dir : String = "user://assets/texts/splashes.txt"


func _ready() -> void:
	# Take a random seed and place arrow in the placeholder
	seed_text.placeholder_text = str(randi())
	globals.random_seed = seed_text.placeholder_text
	
	# Get project version
	version_text.text = ProjectSettings.get_setting("application/config/version")
	
	# TODO: Just delete when the player requests it
	if dir_exists(save_dir):
		delete_dir(save_dir)
		print("'worlds' directory deleted.")
	else:
		print("Directory 'worlds' does not exist.")

	# Splashes texts
	if FileAccess.file_exists(splashes_dir):
		var splash_file = FileAccess.open(splashes_dir, FileAccess.READ)
		var contents := splash_file.get_as_text()
		splash_file.close()
		
		var splashes := contents.split("\n")
		var random_splash := splashes[randi() % splashes.size()]
		
		splashes_text.text = random_splash
	else:
		print("The splashes.txt file was not found.")


func _on_singleplayer_button_pressed():
	main_menu.hide()
	world_creation.show()


func _on_back_button_pressed() -> void:
	main_menu.show()
	world_creation.hide()


func _on_create_pressed() -> void:
	# If the seed is not placed, use the random seed from the placeholder
	if globals._terrain_noise.seed == 0:
		globals.set_noise_seed(int(globals.random_seed))
	else:
		globals.set_noise_seed(int(seed_text.text))
		
	singleplayer_requested.emit()


func dir_exists(dir_path: String) -> bool:
	var dir = DirAccess.open(dir_path)
	return dir != null and dir.dir_exists(dir_path)


func delete_dir(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	print("Delete dir: " + dir_path)
	if dir != null:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var file_path = dir_path + "/" + file_name
			if dir.current_is_dir() and file_name != "." and file_name != "..":
				delete_dir(file_path)  # Recursively delete subdirectories
			elif dir.file_exists(file_path):
				dir.remove(file_path)
			file_name = dir.get_next()
		dir.list_dir_end()
		dir.remove(dir_path)  # Delete the directory
	else:
		printerr("Error trying to open directory: ", dir_path)
