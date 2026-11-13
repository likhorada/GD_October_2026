class_name HairStrand
extends Node2D

@export_group("Shape")
@export var strand_length: float = 480.0
@export var thickness: float = 10.0
@export var bend: float = 50.0
@export var lean: float = 0.0
@export var segments: int = 24
@export var wiggle: float = 6.0
@export var wiggle_waves: float = 2.0

@export_group("Sway")
@export var sway_amplitude: float = 14.0
@export var sway_speed: float = 1.1
@export var sway_phase: float = 0.0
@export var sway_waves: float = 1.0

@export_group("Visuals")
@export var main_color: Color = Color(0.27, 0.15, 0.1, 1.0)
@export var highlight_color: Color = Color(0.47, 0.29, 0.19, 1.0)
@export var show_highlight: bool = true

var sway_time: float = 0.0

var _base_points: PackedVector2Array = PackedVector2Array()
var _main_line: Line2D
var _highlight_line: Line2D


func _ready() -> void:
	add_to_group("hair_strand")
	_generate_base_points()
	_build_lines()
	_update_visuals()


func get_point_at(t: float) -> Vector2:
	var clamped_t: float = clampf(t, 0.0, 1.0)
	var local_point: Vector2 = _sample_base_point(clamped_t)
	local_point.x += _sway_offset(clamped_t)
	return to_global(local_point)


func get_tangent_at(t: float) -> Vector2:
	var before: Vector2 = get_point_at(t - 0.015)
	var after: Vector2 = get_point_at(t + 0.015)
	var tangent: Vector2 = after - before

	if tangent.length_squared() < 0.0001:
		return Vector2.DOWN

	return tangent.normalized()


func get_root_global() -> Vector2:
	return to_global(Vector2.ZERO)


func get_closest_point(global_position_to_check: Vector2) -> Dictionary:
	if _base_points.size() < 2:
		return {}

	var local_position: Vector2 = to_local(global_position_to_check)
	var closest_distance: float = INF
	var closest_t: float = 0.0
	var closest_local_point: Vector2 = Vector2.ZERO

	for index in range(_base_points.size() - 1):
		var t0: float = float(index) / float(_base_points.size() - 1)
		var t1: float = float(index + 1) / float(_base_points.size() - 1)
		var a: Vector2 = _base_points[index]
		var b: Vector2 = _base_points[index + 1]
		a.x += _sway_offset(t0)
		b.x += _sway_offset(t1)

		var candidate: Vector2 = Geometry2D.get_closest_point_to_segment(local_position, a, b)
		var distance: float = local_position.distance_squared_to(candidate)

		if distance < closest_distance:
			closest_distance = distance
			var segment_length_squared: float = a.distance_squared_to(b)
			var segment_t: float = 0.0
			if segment_length_squared > 0.0001:
				segment_t = clampf((candidate - a).dot(b - a) / segment_length_squared, 0.0, 1.0)
			closest_t = lerpf(t0, t1, segment_t)
			closest_local_point = candidate

	return {
		"strand": self,
		"point": to_global(closest_local_point),
		"t": closest_t,
		"distance": sqrt(closest_distance),
	}


func set_sway_time(value: float) -> void:
	sway_time = value
	_update_visuals()


func _generate_base_points() -> void:
	_base_points.clear()
	var point_count: int = maxi(segments, 2)

	for index in range(point_count + 1):
		var t: float = float(index) / float(point_count)
		var x: float = lean * t + bend * t * t
		x += sin(t * PI * wiggle_waves) * wiggle * t
		_base_points.append(Vector2(x, strand_length * t))


func _sample_base_point(t: float) -> Vector2:
	if _base_points.is_empty():
		return Vector2.ZERO

	var last_index: int = _base_points.size() - 1
	var scaled_t: float = clampf(t, 0.0, 1.0) * float(last_index)
	var index: int = int(floor(scaled_t))
	var next_index: int = mini(index + 1, last_index)
	var local_t: float = scaled_t - float(index)
	return _base_points[index].lerp(_base_points[next_index], local_t)


func _sway_offset(t: float) -> float:
	if is_zero_approx(sway_amplitude):
		return 0.0

	var wave: float = sin(sway_time * sway_speed + sway_phase + t * TAU * sway_waves)
	return wave * sway_amplitude * t * t


func _build_lines() -> void:
	_main_line = Line2D.new()
	_main_line.name = "MainLine"
	_main_line.width = thickness
	_main_line.default_color = main_color
	_main_line.antialiased = false
	_main_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_main_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_main_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_main_line)

	_highlight_line = Line2D.new()
	_highlight_line.name = "HighlightLine"
	_highlight_line.width = maxf(1.0, thickness * 0.28)
	_highlight_line.default_color = highlight_color
	_highlight_line.antialiased = false
	_highlight_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_highlight_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_highlight_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_highlight_line.visible = show_highlight
	_main_line.add_child(_highlight_line)


func _update_visuals() -> void:
	if _main_line == null or _base_points.is_empty():
		return

	var points: PackedVector2Array = PackedVector2Array()
	for index in range(_base_points.size()):
		var t: float = float(index) / float(_base_points.size() - 1)
		var point: Vector2 = _base_points[index]
		point.x += _sway_offset(t)
		points.append(point)

	_main_line.points = points
	_highlight_line.points = points
	_highlight_line.width = maxf(1.0, thickness * 0.28)
	_highlight_line.default_color = highlight_color
	_highlight_line.visible = show_highlight
