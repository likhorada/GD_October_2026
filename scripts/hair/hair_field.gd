class_name HairField
extends Node2D

@export var gravity: Vector2 = Vector2(0.0, 520.0)

var _sway_time: float = 0.0


func _ready() -> void:
	add_to_group("hair_field")


func _process(delta: float) -> void:
	_sway_time += delta
	for strand in _get_strands():
		strand.set_sway_time(_sway_time)


func get_strand_count() -> int:
	return _get_strands().size()


func find_nearest(world_position: Vector2, max_distance: float = INF) -> Dictionary:
	var best: Dictionary = {}

	for strand in _get_strands():
		var candidate: Dictionary = strand.get_closest_point(world_position)
		if candidate.is_empty():
			continue
		if candidate["distance"] > max_distance:
			continue
		if best.is_empty() or candidate["distance"] < best["distance"]:
			best = candidate

	return best


func find_next_strand(
	anchor: Vector2,
	current_strand: HairStrand,
	direction: Vector2,
	max_distance: float,
	max_angle_degrees: float
) -> Dictionary:
	var best: Dictionary = {}
	var normalized_direction: Vector2 = direction.normalized()
	var minimum_dot: float = cos(deg_to_rad(max_angle_degrees))

	for strand in _get_strands():
		if strand == current_strand:
			continue

		var candidate: Dictionary = strand.get_closest_point(anchor)
		if candidate.is_empty():
			continue

		var delta: Vector2 = candidate["point"] - anchor
		var distance: float = delta.length()
		if distance > max_distance:
			continue

		var alignment: float = 1.0
		if distance > 5.0:
			alignment = normalized_direction.dot(delta / distance)
			if alignment < minimum_dot:
				continue

		candidate["approach"] = distance
		candidate["alignment"] = alignment
		var score: float = distance + (1.0 - alignment) * 24.0
		if best.is_empty() or score < best["score"]:
			candidate["score"] = score
			best = candidate

	return best


func get_all_strands() -> Array[HairStrand]:
	return _get_strands()


func _get_strands() -> Array[HairStrand]:
	var strands: Array[HairStrand] = []
	for node in get_tree().get_nodes_in_group("hair_strand"):
		if node is HairStrand and is_instance_valid(node):
			strands.append(node)
	return strands
