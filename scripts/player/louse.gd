class_name Louse
extends CharacterBody2D

signal attached(strand: HairStrand, strand_t: float)
signal detached
signal hurt
signal died
signal respawned

enum State {
	FREE,
	ATTACHED,
	HURT,
	DEAD,
}

@export_group("Movement")
@export var crawl_speed: float = 165.0
@export var fall_gravity_scale: float = 1.0
@export var air_drag: float = 180.0
@export var grab_radius: float = 155.0
@export var transfer_radius: float = 42.0
@export var transfer_angle_degrees: float = 72.0
@export var grab_buffer_time: float = 0.15
@export var detach_cooldown_time: float = 0.18

@export_group("Health")
@export var invulnerability_time: float = 1.5
@export var hurt_lock_time: float = 0.3
@export var safe_point_interval: float = 0.4
@export var debug_draw: bool = false

@onready var _sprite: Sprite2D = $Sprite2D

var _state: State = State.FREE
var _current_strand: HairStrand = null
var _current_t: float = 0.0
var _safe_strand: HairStrand = null
var _safe_t: float = 0.0
var _spawn_position: Vector2 = Vector2.ZERO
var _hair_field: HairField = null
var _grab_buffer: float = 0.0
var _detach_cooldown: float = 0.0
var _invulnerability: float = 0.0
var _hurt_timer: float = 0.0
var _safe_timer: float = 0.0
var _flash_time: float = 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_spawn_position = global_position
	_find_hair_field()
	queue_redraw()


func set_spawn_position(value: Vector2) -> void:
	_spawn_position = value


func set_debug_draw(enabled: bool) -> void:
	debug_draw = enabled
	queue_redraw()


func is_attached() -> bool:
	return _state == State.ATTACHED and _current_strand != null


func get_state_name() -> String:
	match _state:
		State.FREE:
			return "FREE"
		State.ATTACHED:
			return "ATTACHED"
		State.HURT:
			return "HURT"
		State.DEAD:
			return "DEAD"
	return "UNKNOWN"


func get_debug_text() -> String:
	var strand_text: String = "—"
	if _current_strand != null and is_instance_valid(_current_strand):
		strand_text = "%s, t=%.2f" % [_current_strand.name, _current_t]

	return "Состояние: %s\nВолос: %s\nЖизни: %d/%d\nСкорость: %.0f" % [
		get_state_name(),
		strand_text,
		GameState.lives,
		GameState.MAX_LIVES,
		velocity.length(),
	]


func take_damage(amount: int = 1) -> void:
	if _state == State.DEAD or _invulnerability > 0.0:
		return

	var run_ended: bool = GameState.damage(amount)
	_invulnerability = invulnerability_time
	_hurt_timer = hurt_lock_time
	_flash_time = 0.0

	if _current_strand != null and is_instance_valid(_current_strand):
		var tangent: Vector2 = _current_strand.get_tangent_at(_current_t)
		_detach(tangent * 45.0 + Vector2.UP * 90.0)

	_state = State.HURT

	if run_ended:
		_die()
	else:
		hurt.emit()


func fall_into_death_zone() -> void:
	if _state == State.DEAD:
		return
	respawn_at_safe_point()


func respawn_at_safe_point() -> void:
	_state = State.FREE
	_current_strand = null
	velocity = Vector2.ZERO
	_grab_buffer = 0.0
	_detach_cooldown = detach_cooldown_time
	_hurt_timer = 0.0
	_invulnerability = 0.8
	_flash_time = 0.0

	if _safe_strand != null and is_instance_valid(_safe_strand):
		_attach_to(_safe_strand, _safe_t)
		_invulnerability = 1.0
	else:
		global_position = _spawn_position
		rotation = 0.0

	respawned.emit()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return

	_invulnerability = maxf(0.0, _invulnerability - delta)
	_detach_cooldown = maxf(0.0, _detach_cooldown - delta)
	_flash_time += delta
	_update_flash()

	if _state == State.ATTACHED:
		_update_attached(delta)
	else:
		_update_free(delta)

	if debug_draw:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("grab"):
		if _state == State.ATTACHED:
			_detach(Vector2.ZERO)
		elif _state == State.FREE:
			_grab_buffer = grab_buffer_time


func _update_attached(delta: float) -> void:
	if _current_strand == null or not is_instance_valid(_current_strand):
		_current_strand = null
		_state = State.FREE
		return

	var horizontal: float = Input.get_axis("move_left", "move_right")
	var vertical: float = Input.get_axis("move_up", "move_down")
	var along: float = clampf(vertical + horizontal, -1.0, 1.0)

	if absf(horizontal) > 0.01 and _detach_cooldown <= 0.0:
		if _try_transfer(signf(horizontal)):
			return

	if absf(along) > 0.01:
		var strand_length: float = maxf(_current_strand.strand_length, 1.0)
		_current_t = clampf(
			_current_t + along * (crawl_speed / strand_length) * delta,
			0.0,
			1.0
		)

		if _current_t >= 1.0 and along > 0.0:
			_detach(Vector2.ZERO)
			return

	_update_attached_transform()
	_update_safe_point(delta)


func _update_free(delta: float) -> void:
	if _state == State.HURT:
		_hurt_timer = maxf(0.0, _hurt_timer - delta)
		if _hurt_timer <= 0.0:
			_state = State.FREE

	if _grab_buffer > 0.0:
		_grab_buffer = maxf(0.0, _grab_buffer - delta)
		if _state == State.FREE and _try_attach():
			return

	var gravity: Vector2 = Vector2(0.0, 520.0)
	if _hair_field != null:
		gravity = _hair_field.gravity

	velocity += gravity * fall_gravity_scale * delta
	velocity.x = move_toward(velocity.x, 0.0, air_drag * delta)
	move_and_slide()


func _try_attach() -> bool:
	var nearest: Dictionary = _find_nearest_hair(grab_radius)
	if nearest.is_empty():
		return false
	if nearest["distance"] > grab_radius:
		return false

	_attach_to(nearest["strand"], nearest["t"])
	return true


func _find_nearest_hair(max_distance: float) -> Dictionary:
	if _hair_field == null:
		_find_hair_field()
	if _hair_field == null:
		return {}
	return _hair_field.find_nearest(global_position, max_distance)


func _try_transfer(horizontal_direction: float) -> bool:
	if _hair_field == null or _current_strand == null:
		return false

	var anchor: Vector2 = _current_strand.get_point_at(_current_t)
	var direction: Vector2 = Vector2(horizontal_direction, 0.0)
	var candidate: Dictionary = _hair_field.find_next_strand(
		anchor,
		_current_strand,
		direction,
		transfer_radius,
		transfer_angle_degrees
	)

	if candidate.is_empty():
		return false

	_attach_to(candidate["strand"], candidate["t"])
	return true


func _attach_to(strand: HairStrand, strand_t: float) -> void:
	if strand == null or not is_instance_valid(strand):
		return

	_current_strand = strand
	_current_t = clampf(strand_t, 0.0, 1.0)
	_state = State.ATTACHED
	velocity = Vector2.ZERO
	_grab_buffer = 0.0
	_detach_cooldown = detach_cooldown_time
	_hurt_timer = 0.0
	_safe_timer = 0.0
	_update_attached_transform()
	attached.emit(_current_strand, _current_t)
	queue_redraw()


func _detach(push_velocity: Vector2) -> void:
	if _current_strand == null:
		return

	var tangent: Vector2 = _current_strand.get_tangent_at(_current_t)
	_current_strand = null
	_state = State.FREE
	_detach_cooldown = detach_cooldown_time

	if push_velocity == Vector2.ZERO:
		velocity = tangent * 55.0 + Vector2.UP * 45.0
	else:
		velocity = push_velocity

	detached.emit()
	queue_redraw()


func _update_attached_transform() -> void:
	if _current_strand == null:
		return

	var reference_tangent: Vector2 = _current_strand.get_tangent_at(_current_t)
	global_position = _current_strand.get_point_at(_current_t)
	rotation = reference_tangent.angle()


func _update_safe_point(delta: float) -> void:
	if _current_strand == null:
		return

	_safe_timer += delta
	if _safe_timer < safe_point_interval:
		return
	_safe_timer = 0.0

	if _current_t < 0.05 or _current_t > 0.94:
		return
	if _is_touching_hazard(global_position):
		return

	_safe_strand = _current_strand
	_safe_t = _current_t


func _is_touching_hazard(world_position: Vector2) -> bool:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collision_mask = 2
	query.collide_with_areas = true
	query.collide_with_bodies = false
	return not space.intersect_point(query, 1).is_empty()


func _find_hair_field() -> void:
	_hair_field = get_tree().get_first_node_in_group("hair_field") as HairField
	if _hair_field == null:
		_hair_field = get_parent().get_node_or_null("HairField") as HairField


func _update_flash() -> void:
	if _sprite == null:
		return

	if _invulnerability <= 0.0:
		_sprite.modulate.a = 1.0
		return

	var flash: float = 0.45 + 0.55 * absf(sin(_flash_time * 22.0))
	_sprite.modulate.a = flash


func _die() -> void:
	_state = State.DEAD
	_current_strand = null
	velocity = Vector2.ZERO
	if _sprite != null:
		_sprite.modulate = Color(0.65, 0.25, 0.2, 1.0)
	died.emit()
	queue_redraw()


func _draw() -> void:
	if not debug_draw:
		return

	draw_arc(Vector2.ZERO, grab_radius, 0.0, TAU, 64, Color(0.3, 0.8, 1.0, 0.25), 1.5)
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.9, 0.25, 0.9))

	if _current_strand != null and is_instance_valid(_current_strand):
		draw_line(Vector2.ZERO, to_local(_current_strand.get_root_global()), Color(0.9, 0.7, 0.25, 0.35), 1.0)
