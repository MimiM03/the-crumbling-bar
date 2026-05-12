extends Area3D

var glasses: Array

func _ready():
	get_glasses_in_order()

func decrease_num():
	if glasses.size() > 0:
		var glass = glasses.pop_front()
		glass.queue_free()
		if glasses.size() == 0:
			queue_free()

func get_glasses_in_order():
	glasses = get_children().filter(not_collisiion)
	
	glasses.sort_custom(func(a, b): 
		return a.name.naturalnocasecmp_to(b.name) > 0
	)
		
func not_collisiion(child_node: Node):
	return child_node.name != "CollisionShape3D"
