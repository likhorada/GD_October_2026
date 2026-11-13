extends Control

@onready var back_button: Button = %BackButton
@onready var info_label: Label = %InfoLabel


func _ready() -> void:
	back_button.pressed.connect(SceneRouter.go_to_menu)
	info_label.text = "Жизни: %d/%d" % [GameState.lives, GameState.MAX_LIVES]
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		SceneRouter.go_to_menu()
