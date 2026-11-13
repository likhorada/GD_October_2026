extends Control

@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton
@onready var exit_button: Button = %ExitButton
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	exit_button.visible = not OS.has_feature("web")
	status_label.text = ""

	start_button.grab_focus()


func _on_start_pressed() -> void:
	GameState.reset_run()
	SceneRouter.change_scene("res://scenes/dev/PlaceholderGame.tscn")


func _on_settings_pressed() -> void:
	status_label.text = "Настройки будут добавлены в итерации M3."


func _on_exit_pressed() -> void:
	if OS.has_feature("web"):
		SceneRouter.go_to_menu()
	else:
		get_tree().quit()
