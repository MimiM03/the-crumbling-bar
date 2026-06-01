extends Marker3D

var customerScene: PackedScene = preload("res://scenes/customer.scn")
var customerContainer: NodePath = "../Customers"

@export var max_customers := 6
@export var spawn_interval_sec := 25.0


func _ready() -> void:
	while true:
		spawn_random_arrival()
		await get_tree().create_timer(spawn_interval_sec).timeout


func _customer_count() -> int:
	return get_tree().get_nodes_in_group("customers").size()


func _room_for_spawn() -> int:
	return maxi(0, max_customers - _customer_count())


func spawn_random_arrival() -> void:
	if _room_for_spawn() <= 0:
		return

	# RULE: If not enough spots for the whole group, they don't enter
	var has_spawned := false
	while !has_spawned:
		await get_tree().process_frame
		# Recompute every loop so occupancy changes from previous spawns are reflected.
		var available_areas = get_tree().get_nodes_in_group("wait_area").filter(
			func(area): return !area.is_occupied
		)
		var available_seats = get_tree().get_nodes_in_group("seats").filter(
			func(seat): return seat.get_parent() and seat.get_parent().name == "Bar chairs" and !seat.is_occupied
		)
		# no spawn if no space
		if available_seats.size() < 1 and available_areas.size() < 2:
			break
		# spawn only groups, if no space for individuals
		elif available_seats.size() < 1:
			if available_areas.size() >= 4:
				var chance_group = randf()
				if chance_group < 0.5:
					print("Spawned 2")
					has_spawned = _try_spawn_group(2, available_areas)
				else:
					print("Spawned 2+")
					has_spawned = _try_spawn_group(randi_range(3, 4), available_areas)
			else:
				print("Spawned 2")
				has_spawned = _try_spawn_group(2, available_areas)
				
		# spawn only individuals, if no space for groups
		elif available_areas.size() < 2:
			print("Spawned 1")
			has_spawned = _try_spawn_group(1, available_seats)
			
		# spawn either
		else:
			var chance = randf()
			if chance < 0.5:
				print("Spawned 1")
				has_spawned = _try_spawn_group(1, available_seats)
			elif chance < 0.75 and available_areas.size() >= 4:
				print("Spawned 2+")
				has_spawned = _try_spawn_group(randi_range(3, 4), available_areas)
			else:
				print("Spawned 2")
				has_spawned = _try_spawn_group(2, available_areas)


func _try_spawn_group(size: int, available_areas: Array) -> bool:
	var room := _room_for_spawn()
	if room <= 0:
		return false
	size = mini(size, room)
	if size <= 0:
		return false
	if size > available_areas.size():
		return false
	spawn_group(size, available_areas)
	return true


func spawn_group(size: int, spots: Array) -> void:
	var members = []
	var is_group := size > 1

	for i in range(size):
		var customer = customerScene.instantiate()
		customer.isGroup = is_group
		var spawn_offset := Vector3(randf_range(0.4, 0.6), 0, randf_range(0.4, 0.6))
		customer.exit_position = global_position + Vector3(9.88, 0, 0)

		if is_group:
			customer.type = customer.ChairType.BAR
			var area = spots[i]
			area.is_occupied = true
			customer.target_wait_area = area
			customer.target_seat = null
		else:
			customer.type = customer.ChairType.CHAIR
			var seat = spots[randi() % spots.size()]
			if not seat.has_node("sitMarker"):
				push_warning("spawn_group: spot is not a chair with sitMarker, skipping.")
				continue
			seat.is_occupied = true
			customer.target_seat = seat
			customer.target_wait_area = null

		get_node(customerContainer).add_child(customer, true)
		customer.global_position = global_position + spawn_offset
		# Run after customer _ready() (which awaits a physics frame) so curAnim isn't reset.
		if is_group:
			customer.call_deferred("start_looking_for_bar_space")
		else:
			customer.call_deferred("start_looking_for_seat")

		if i == 0:
			customer.is_leader = true
		members.append(customer)

		await get_tree().create_timer(0.8).timeout

	for member in members:
		member.group_members = members
		member.isGroup = is_group
