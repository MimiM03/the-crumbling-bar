extends Marker3D

var customerScene: PackedScene = preload("res://scenes/customer.tscn")
var customerContainer: NodePath = "../Customers"
func _ready():
	# For testing: spawn something every 5 seconds
	while true:
		await get_tree().create_timer(2.0).timeout
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
	var available_areas = get_tree().get_nodes_in_group("wait_area").filter(
		func(area): return !area.is_occupied
	)
	print(available_areas.size())
	
	# RULE: If not enough spots for the whole group, they don't enter
	if available_areas.size() < size:
		print("Not enough room at the bar for a group of ", size)
		return
	var members = []
	# If size is 1, they aren't technically a "group" in your logic
	var isGroup = size > 1
	
	for i in range(size):
		var customer = customerScene.instantiate()
		get_node(customerContainer).add_child(customer, true)
		
		# Set their position at the entrance with a tiny bit of random offset
		# so they don't spawn inside each other
		customer.global_position = global_position + Vector3(randf_range(0.4,0.6), 0, randf_range(0.4,0.6))
		
		if isGroup:
			# Assign a specific wait spot to each member immediately
			var area = available_areas[i]
			area.is_occupied = true
			customer.target_wait_area = area
		
		if i == 0: customer.is_leader = true
		members.append(customer)
		# Give every member a list of their friends
		for member in members:
			member.group_members = members
		# Pass the variables to your Customer script
		customer.isGroup = isGroup
		
