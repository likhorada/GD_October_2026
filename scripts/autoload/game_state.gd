extends Node

signal lives_changed(lives: int, max_lives: int)
signal run_started()
signal run_finished(won: bool)
signal checkpoint_changed(checkpoint_id: String)

const MAX_LIVES: int = 3

var lives: int = MAX_LIVES
var checkpoint_id: String = ""
var checkpoint_position: Vector2 = Vector2.ZERO
var current_level: PackedScene = null
var medkits_collected: int = 0


func reset_run() -> void:
	lives = MAX_LIVES
	checkpoint_id = ""
	checkpoint_position = Vector2.ZERO
	medkits_collected = 0
	lives_changed.emit(lives, MAX_LIVES)
	run_started.emit()


func set_checkpoint(id: String, position: Vector2) -> void:
	checkpoint_id = id
	checkpoint_position = position
	checkpoint_changed.emit(checkpoint_id)


func damage(amount: int = 1) -> bool:
	if lives <= 0:
		return true

	lives = clampi(lives - amount, 0, MAX_LIVES)
	lives_changed.emit(lives, MAX_LIVES)

	if lives == 0:
		run_finished.emit(false)
		return true

	return false


func heal(amount: int = 1) -> bool:
	if lives >= MAX_LIVES:
		return false

	lives = clampi(lives + amount, 0, MAX_LIVES)
	medkits_collected += 1
	lives_changed.emit(lives, MAX_LIVES)
	return true


func finish_run(won: bool) -> void:
	run_finished.emit(won)
