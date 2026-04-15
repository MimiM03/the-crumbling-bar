extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D

var target_seat = null
const SPEED := 3.0
var isGroup: bool = false
var isGroupLeader: bool = false
enum ChairType {BAR, TABLE4, TABLE2}

func _ready() -> void:
	# Wait for the first physics frame so the NavigationServer is ready
	await get_tree().physics_frame
	if !isGroup:
		start_looking_for_seat(ChairType.BAR)
	else:
		start_looking_for_seat(ChairType.TABLE4)

func _physics_process(_delta):
	if target_seat:
		# Get the next point in the path
		var current_pos = global_position
		var next_pos = nav_agent.get_next_path_position()
		
		# Calculate velocity and move
		var new_velocity = (next_pos - current_pos).normalized() * SPEED
		velocity = new_velocity
		
		# Check if we arrived
		if nav_agent.is_navigation_finished():
			# TODO: SIT
			print("finished")
			velocity = Vector3(0,0,0)
			
		move_and_slide()
			

func start_looking_for_seat(type: ChairType):
	target_seat = find_empty_seat(type)
	if target_seat:
		target_seat.is_occupied = true # Claim the seat immediately
		nav_agent.target_position = target_seat.global_position

func find_empty_seat(type: ChairType):
	var all_seats = get_tree().get_nodes_in_group("seats")
	var available_seats = []
	
	for seat in all_seats:
		var parent = seat.get_parent()
		if parent: 
			match type:
				ChairType.BAR:
					if parent.name == "Bar chairs" and not seat.is_occupied:
						available_seats.append(seat)
				ChairType.TABLE4:
					print("Chair for Table4")
				ChairType.TABLE2:
					print("Chair for Table2")
			
	if available_seats.size() > 0:
		# Option A: Pick the closest seat
		# return get_closest_seat(available_seats)
		# Option B: Pick a random seat
		return available_seats[randi() % available_seats.size()]
		
	return null

func get_closest_seat(seats_array):
	var closest = seats_array[0]
	for seat in seats_array:
		if global_position.distance_to(seat.global_position) < global_position.distance_to(closest.global_position):
			closest = seat
	return closest
