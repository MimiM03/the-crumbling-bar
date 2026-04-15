extends Marker3D

var customerScene: PackedScene = preload("res://scenes/customer.tscn")
var customerContainer: NodePath = "../Customers"


func _ready():
	# For testing: spawn something every 5 seconds
	while true:
		spawn_random_arrival()
		await get_tree().create_timer(3.0).timeout
		

func spawn_random_arrival():
	var available_areas = get_tree().get_nodes_in_group("wait_area").filter(
		func(area): return !area.is_occupied
		)
	var available_seats = get_tree().get_nodes_in_group("seats").filter(
		func(seat): return  seat.get_parent() and seat.get_parent().name == "Bar chairs" and !seat.is_occupied
	)
	# RULE: If not enough spots for the whole group, they don't enter	
	var has_spawned := false
	while !has_spawned:
		await get_tree().process_frame
		# no spawn if no space
		if available_seats.size() < 1 and available_areas.size() < 2:
			break
		# spawn only groups, if no space for individuals
		elif available_seats.size() < 1:
			if available_areas.size() >= 4:
				var chance_group = randf()
				if chance_group < 0.5:
					#50% chance for a group of 2
					print("Spawned 2")
					spawn_group(2, available_areas)
					has_spawned = true
				else:
					# 50% chance for a group of 3-4
					print("Spawned 2+")
					spawn_group(randi_range(3, 4), available_areas)
					has_spawned = true
			else:
				print("Spawned 2")
				spawn_group(2, available_areas)
				has_spawned = true
				
		# spawn only individuals, if no space for groups
		elif available_areas.size() < 2:
			print("Spawned 1")
			spawn_group(1, available_seats)
			has_spawned = true
			
		# spawn either
		else:
			var chance = randf()
			if chance < 0.5:
				print("Spawned 1")
				spawn_group(1, available_seats)
				has_spawned = true
			elif chance < 0.75 and available_areas.size() >= 4:
				print("Spawned 2+")
				spawn_group(randi_range(3, 4), available_areas)
				has_spawned = true
			else:
				print("Spawned 2")
				spawn_group(2, available_areas)
				has_spawned = true

func spawn_group(size: int, available_areas: Array):
	var members = []
	# If size is 1, they aren't technically a "group"
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
		else:
			if available_areas.size() > 0:
				# Pick a random seat
				customer.target_seat = available_areas[randi() % available_areas.size()]
		
		if i == 0: customer.is_leader = true
		members.append(customer)
		# Give every member a list of their friends
		for member in members:
			member.group_members = members
			member.isGroup = isGroup
		
		await get_tree().create_timer(0.8).timeout		
