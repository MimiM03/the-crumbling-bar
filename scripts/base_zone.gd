# PlacementZone.gd
extends Area3D

@export var required_group: String = ""
@export var is_occupied: bool = true
var current_object: Area3D

func _physics_process(_delta: float) -> void:
	if is_occupied:
		$CollisionShape3D.disabled = true
	else:
		$CollisionShape3D.disabled = false
# Returns true only if the zone is empty AND the object is acceptable
func can_accept(object: Area3D) -> bool:
	if !object:
		return false
	# `required_group` acts as a simple type filter for zone compatibility.
	return !is_occupied and object.is_in_group(required_group)

# Places object on it's marker
func place_object(object: Area3D):
	if !is_occupied:
		is_occupied = true
		current_object = object
		# Carry/hand uses world scale ~1; reset so scaled zones (ticket rail) don't inflate the object.
		current_object.scale = Vector3.ONE
		
		# Snap in local space so parent scale (e.g. ticket rail) is preserved.
		var object_snap_point = current_object.get_node("SnapPoint")
		var offset = -object_snap_point.position
		var end_pos = $SnapPoint.position + offset
		var from_q: Quaternion = current_object.quaternion
		var to_q: Quaternion = $SnapPoint.quaternion
		# Same orientation as -to_q; pick the hemisphere so slerp takes the short arc (~≤180°).
		if from_q.dot(to_q) < 0.0:
			to_q = -to_q

		var tween = create_tween().set_parallel(true)
		tween.tween_property(current_object, "position", end_pos, 0.3)
		var placed := current_object
		tween.tween_method(
			func(t: float) -> void:
				placed.quaternion = from_q.slerp(to_q, t),
			0.0, 1.0, 0.3
		)

func release_object():
	is_occupied = false
	current_object = null
	print("Zone is now empty")
