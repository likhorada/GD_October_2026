extends Node2D

const HAIR_SCENE: PackedScene = preload("res://scenes/game/HairStrand.tscn")
const HAZARD_SCENE: PackedScene = preload("res://scenes/game/TestHazard.tscn")

@onready var _hair_field: HairField = $HairField
@onready var _louse: Louse = $Louse
@onready var _debug_label: Label = %DebugLabel
@onready var _status_label: Label = %StatusLabel

var _debug_visible: bool = true


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.93, 0.81, 0.7))
	_spawn_strands()
	_spawn_hazards()

	_louse.set_spawn_position(Vector2(455.0, 125.0))
	_louse.set_debug_draw(_debug_visible)
	_louse.attached.connect(_on_louse_attached)
	_louse.detached.connect(_on_louse_detached)
	_louse.hurt.connect(_on_louse_hurt)
	_louse.died.connect(_on_louse_died)
	_louse.respawned.connect(_on_louse_respawned)

	_debug_label.visible = _debug_visible
	_status_label.text = "Space — зацепиться за волос. A/D — ползти и переползать. Space — отпустить."
	_update_debug()


func _process(_delta: float) -> void:
	_update_debug()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		GameState.reset_run()
		SceneRouter.reload_current_scene()
	elif event.is_action_pressed("debug_toggle"):
		_debug_visible = not _debug_visible
		_debug_label.visible = _debug_visible
		_louse.set_debug_draw(_debug_visible)
	elif event.is_action_pressed("pause"):
		SceneRouter.go_to_menu()


func _spawn_strands() -> void:
	var strands: Array[Dictionary] = [
		{"position": Vector2(180, 95), "length": 540.0, "bend": 60.0, "lean": -30.0, "rotation": -3.0},
		{"position": Vector2(280, 70), "length": 610.0, "bend": -90.0, "lean": 20.0, "rotation": 2.0},
		{"position": Vector2(380, 105), "length": 500.0, "bend": 110.0, "lean": -10.0, "rotation": -2.0},
		{"position": Vector2(480, 85), "length": 620.0, "bend": -70.0, "lean": 30.0, "rotation": 3.0},
		{"position": Vector2(580, 120), "length": 470.0, "bend": 80.0, "lean": -20.0, "rotation": -1.0},
		{"position": Vector2(680, 75), "length": 590.0, "bend": -110.0, "lean": 15.0, "rotation": 2.0},
		{"position": Vector2(780, 100), "length": 530.0, "bend": 95.0, "lean": -25.0, "rotation": -2.0},
		{"position": Vector2(880, 80), "length": 630.0, "bend": -60.0, "lean": 25.0, "rotation": 3.0},
		{"position": Vector2(980, 115), "length": 480.0, "bend": 120.0, "lean": -15.0, "rotation": -2.0},
		{"position": Vector2(1080, 90), "length": 560.0, "bend": -85.0, "lean": 20.0, "rotation": 2.0},
		{"position": Vector2(1180, 110), "length": 510.0, "bend": 75.0, "lean": -20.0, "rotation": -1.0},
		{"position": Vector2(240, 300), "length": 840.0, "bend": 25.0, "lean": 0.0, "rotation": -80.0, "thickness": 12.0},
		{"position": Vector2(340, 470), "length": 760.0, "bend": -20.0, "lean": 0.0, "rotation": -100.0, "thickness": 12.0},
	]

	for index in range(strands.size()):
		var data: Dictionary = strands[index]
		var strand: HairStrand = HAIR_SCENE.instantiate() as HairStrand
		strand.name = "Strand_%02d" % index
		strand.position = data["position"]
		strand.strand_length = data["length"]
		strand.bend = data["bend"]
		strand.lean = data["lean"]
		strand.rotation = deg_to_rad(data["rotation"])
		strand.thickness = data.get("thickness", 9.0)
		strand.sway_amplitude = 7.0 + float(index % 4) * 2.5
		strand.sway_phase = float(index) * 0.7
		strand.sway_waves = 1.0 + float(index % 2) * 0.35
		_hair_field.add_child(strand)


func _spawn_hazards() -> void:
	var hazards: Array[Dictionary] = [
		{"position": Vector2(360, 430), "rotation": 0.0},
		{"position": Vector2(880, 505), "rotation": 8.0},
		{"position": Vector2(1080, 380), "rotation": -6.0},
		{"position": Vector2(700, 370), "rotation": -80.0},
		{"position": Vector2(620, 430), "rotation": -99.0},
	]

	for data in hazards:
		var hazard: Area2D = HAZARD_SCENE.instantiate() as Area2D
		hazard.position = data["position"]
		hazard.rotation = deg_to_rad(data["rotation"])
		add_child(hazard)


func _update_debug() -> void:
	if not _debug_visible:
		return
	_debug_label.text = "M2: HAIR TEST\n%s\nF1 — отладка, R — рестарт, Esc — меню" % _louse.get_debug_text()


func _on_louse_attached(strand: HairStrand, strand_t: float) -> void:
	_status_label.text = "Захват: %s, t=%.2f. A/D — ползти, Space — отпустить." % [strand.name, strand_t]


func _on_louse_detached() -> void:
	_status_label.text = "Отцепление. Space рядом с волосом — снова зацепиться."


func _on_louse_hurt() -> void:
	_status_label.text = "Урон! Жизней осталось: %d/%d." % [GameState.lives, GameState.MAX_LIVES]


func _on_louse_died() -> void:
	_status_label.text = "Вошь погибла. R — начать тест заново."


func _on_louse_respawned() -> void:
	_status_label.text = "Возрождение на последнем безопасном волосе. Жизни: %d/%d." % [
		GameState.lives,
		GameState.MAX_LIVES,
	]
