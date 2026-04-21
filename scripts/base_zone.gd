# PlacementZone.gd
extends Area3D

@export var required_group: String = ""
var is_occupied: bool = true
var current_object: Area3D

# Returns true only if the zone is empty AND the object is acceptable
func can_accept(object: Area3D) -> bool:
	if !object:
		return false
	# `required_group` acts as a simple type filter for zone compatibility.
	print(!is_occupied)
	print(object.is_in_group(required_group))
	return !is_occupied and object.is_in_group(required_group)

# Places object on it's marker
func place_object(object: Area3D):
	if !is_occupied:
		is_occupied = true
		current_object = object
		
		var tween = create_tween()
		# Snap the bottle to the SnapPoint
		var bottle_snap_point = current_object.get_node("SnapPoint")
		var offset = - bottle_snap_point.position	
		
		print(offset)
		var tween = create_tween().set_parallel(true)
		tween.tween_property(current_object, "global_position", $SnapPoint.global_position + offset, 0.3)
		tween.tween_property(current_object, "global_rotation", $SnapPoint.global_rotation, 0.3)

func release_object():
	is_occupied = false
	current_object = null
	print("Zone is now empty")
