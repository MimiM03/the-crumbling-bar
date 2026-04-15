extends Marker3D

var customerScene: PackedScene = preload("res://scenes/customer.tscn")
var customerContainer: NodePath = "../Customers"
func _ready():
	# For testing: spawn something every 5 seconds
	while true:
		await get_tree().create_timer(5.0).timeout
		spawn_random_arrival()

func spawn_random_arrival():
	var chance = randf()
	
	if chance < 0.5:
		# 50% chance for a lone customer
		print("Spawned 1")
		spawn_group(1)
	elif chance < 0.75:
		# 25% chance for a group of 2
		print("Spawned 2")
		spawn_group(2)
	else:
		# 25% chance for a group of 3-4
		print("Spawned 2+")
		spawn_group(randi_range(3, 4))

func spawn_group(size: int):
	# If size is 1, they aren't technically a "group" in your logic
	var isGroup = size > 1
	
	for i in range(size):
		var customer = customerScene.instantiate()
		get_node(customerContainer).add_child(customer, true)
		
		# Set their position at the entrance with a tiny bit of random offset
		# so they don't spawn inside each other
		customer.global_position = global_position + Vector3(randf_range(0.4,0.6), 0, randf_range(0.4,0.6))
		
		# Pass the variables to your Customer script
		customer.isGroup = isGroup
		
		# If you want them to pick the SAME table, you'd find a table here 
		# and pass it to all of them, but for now, they will just 
		# go to the wait area then find individual table seats.
