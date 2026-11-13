extends Node

const MAIN_MENU_PATH: String = "res://scenes/ui/MainMenu.tscn"


func change_scene(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_error("Scene does not exist: %s" % path)
		return

	get_tree().paused = false
	var error: Error = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Could not change scene to %s (error %d)." % [path, error])


func reload_current_scene() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func go_to_menu() -> void:
	change_scene(MAIN_MENU_PATH)
