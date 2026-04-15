extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D

var target_seat = null
var target_wait_area = null
const SPEED := 3.0
var isGroup: bool = false
var group_members: Array = [] # To keep track of who is in the group
var is_leader: bool = false
var is_moving: bool = false
enum ChairType {CHAIR, TABLE4, TABLE2, BAR}
var type: ChairType

func _ready() -> void:
	# Wait for the first physics frame so the NavigationServer is ready
	await get_tree().physics_frame
	if !isGroup:
		type = ChairType.CHAIR
		start_looking_for_seat()
	else:
		type = ChairType.BAR
		start_looking_for_bar_space()

func _physics_process(_delta):
	if target_seat or target_wait_area:
		# Get the next point in the path
		var current_pos = global_position
		var next_pos = nav_agent.get_next_path_position()
		var distance = global_position.distance_to(nav_agent.target_position)
		
		# SLOW DOWN when getting close to prevent overshooting
		var current_speed = SPEED
		if distance < 0.5:
			current_speed = SPEED * (distance / 0.5) # Gradually slow to 0
			current_speed = max(current_speed, 0.5)   # Don't let it go to total zero
		# Calculate velocity and move
		var new_velocity = (next_pos - current_pos).normalized() * current_speed
		
		nav_agent.set_velocity(new_velocity)

func start_looking_for_seat():
	#target_seat = find_empty_seat()
	if target_seat:
		target_seat.is_occupied = true # Claim the seat immediately
		is_moving = true
		nav_agent.target_position = target_seat.global_position

#func find_empty_seat():
	#var available_seats = get_tree().get_nodes_in_group("seats").filter(
		#func(seat): return  seat.get_parent() and seat.get_parent().name == "Bar chairs" and !seat.is_occupied
	#)
	##var available_seats = []
	##
	##for seat in all_seats:
		##var parent = seat.get_parent()
		##if parent and parent.name == "Bar chairs":
			##available_seats.append(seat)
#
	#if available_seats.size() > 0:
		## Pick a random seat
		#return available_seats[randi() % available_seats.size()]
		#
	#return null
				

#func get_closest_seat(seats_array):
	#var closest = seats_array[0]
	#for seat in seats_array:
		#if global_position.distance_to(seat.global_position) < global_position.distance_to(closest.global_position):
			#closest = seat
	#return closest

func start_looking_for_bar_space():
	if target_wait_area:
		is_moving = true
		nav_agent.target_position = target_wait_area.global_position

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = velocity.move_toward(safe_velocity, 0.25)
	move_and_slide()

func _on_navigation_agent_3d_target_reached() -> void:
	# Snap to the exact marker position
	var final_pos = target_wait_area.global_position if target_wait_area else target_seat.global_position
	global_position = final_pos
	is_moving = false
	# Stop moving
	velocity = Vector3.ZERO
	# TODO: Rotate them to face the bar/counter
	
	match type:
		ChairType.CHAIR:
			# TODO: sit()
			# then, Order()
			pass
		ChairType.BAR:
			# If I'm the leader, I manage the group timing
			var all_arrived := false
			if is_leader:
				while !all_arrived:
					await get_tree().process_frame
					all_arrived = true
					for m in group_members:
						if m.is_moving:
							all_arrived = false
							break # Someone is still moving, keep waiting
							
			print("all at bar")
			# TODO: change wait time -> Order()
			await get_tree().create_timer(5.0).timeout
			print("all leaving bar")
			# After order served: move to table
			if group_members.size() == 2:
				type = ChairType.TABLE2
			else:
				type = ChairType.TABLE4
			if is_leader: dispatch_group_to_table()
		ChairType.TABLE4 or ChairType.TABLE2:
			# TODO: sit()
			pass

func check_group_arrival() -> bool:
	print("checking if all arrived")
	# Wait for all members to be 'finished' with their nav
	for m in group_members:
		if m.is_moving:
			print(m, " is moving")
			return false
	
	return true

func dispatch_group_to_table():
	# 1. Find a table large enough for the whole group
	var table = find_free_table_for_size(group_members.size())

	if table:
		table.is_occupied = true
		var chairs = get_tree().get_nodes_in_group("seats").filter(
			func(node): return table.is_ancestor_of(node)
		)
		# 2. Assign members one by one with a small delay
		for i in range(group_members.size()):
			var member = group_members[i]
			var seat = chairs[i] # Assign the i-th chair
			member.move_to_assigned_seat(seat)
			await get_tree().create_timer(0.8).timeout # The "one-by-one" feel
			

func find_free_table_for_size(size: int):
	var free_tables_this_size = get_tree().get_nodes_in_group(ChairType.keys()[type]).filter(
		func(table): return !table.is_occupied
	)

	if free_tables_this_size.size() > 0:
		# Pick a random seat
		return free_tables_this_size[randi() % free_tables_this_size.size()]
		
	return null

func move_to_assigned_seat(seat_marker: StaticBody3D):
	target_seat = seat_marker
	target_wait_area.is_occupied = false
	target_wait_area = null # Clear the old bar target

	nav_agent.target_position = target_seat.global_position
