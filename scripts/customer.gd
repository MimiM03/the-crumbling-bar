extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D

enum {IDLE, WALK, SIT}
var curAnim = IDLE
@export var blend_speed = 15
@export var turn_speed := 8.0
var exit_position = null
var target_seat = null
var target_wait_area = null
var target_table = null
const SPEED := 2.0
const TICKET_SCENE := preload("res://scenes/ticket.tscn")

static var _ticket_zones: Array = []
static var _next_ticket_slot: int = 0
static var _ticket_zones_scene: Node = null

var isGroup: bool = false
var group_members: Array = [] # To keep track of who is in the group
var is_leader: bool = false
var is_moving: bool = false
enum ChairType {CHAIR, TABLE4, TABLE2, BAR}
var type: ChairType
var is_sitting: bool = false
var has_ordered: bool = false
var has_been_served = false
var drink = null
var order_ticket: Area3D = null
var walk_value_anim := 0.0
var sit_value_anim := 0.0
var _at_wait_area := false
var _bar_wait_handled := false
const WAIT_AREA_ARRIVE_DISTANCE := 0.45

@onready var bubble_sprite = $OrderLabel/Sprite3D
@onready var drink_label = $OrderLabel/SubViewport/Panel/Label
@onready var bubble_viewport = $OrderLabel/SubViewport
@onready var animation_tree: AnimationTree = $fox/Armature/Skeleton3D/Thisle_Sketchfab_Clothing_Thistle_Clothing_0/AnimationTree

func _ready() -> void:
	# Wait for the first physics frame so the NavigationServer is ready
	await get_tree().physics_frame
	
	# Initially hide the bubble
	bubble_sprite.visible = false
	# Link the Sprite3D to the Viewport
	bubble_sprite.texture = bubble_viewport.get_texture()
	animation_tree.active = true
	# spawn_group() may already have set curAnim = WALK before this _ready() resumes.
	if not is_moving:
		curAnim = IDLE
	
	add_to_group("customers")

func _physics_process(_delta):
	_update_locomotion_anim()
	handle_animation(_delta)
	_update_facing(_delta)
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
		if !is_sitting:
			if target_wait_area and type == ChairType.BAR:
				var wait_dist := global_position.distance_to(target_wait_area.global_position)
				if wait_dist <= WAIT_AREA_ARRIVE_DISTANCE:
					_arrive_at_wait_area()
					return
			if distance < 1 and _can_sit_in_target_seat():
				is_sitting = true
				is_moving = false
				sit()
				return
			
			nav_agent.set_velocity(new_velocity)


func _update_locomotion_anim() -> void:
	if is_sitting or _at_wait_area:
		return
	if is_moving and (target_seat != null or target_wait_area != null):
		curAnim = WALK
	elif not is_moving and not is_sitting:
		curAnim = IDLE


func _update_facing(delta: float) -> void:
	if is_sitting or _at_wait_area:
		return

	var flat_velocity := Vector3(velocity.x, 0.0, velocity.z)
	if flat_velocity.length_squared() < 0.0001:
		return

	var target_yaw := atan2(flat_velocity.x, flat_velocity.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, turn_speed * delta))

func start_looking_for_seat():
	if target_seat:
		target_seat.is_occupied = true # Claim the seat immediately
		is_moving = true
		curAnim = WALK
		nav_agent.target_position = target_seat.global_position

func _can_sit_in_target_seat() -> bool:
	return (
		type != ChairType.BAR
		and target_seat != null
		and target_seat.has_node("sitMarker")
	)


func start_looking_for_bar_space():
	if target_wait_area:
		is_moving = true
		curAnim = WALK
		nav_agent.target_position = target_wait_area.global_position

func dispatch_group_to_table():
	# 1. Find a table large enough for the whole group
	target_table = find_free_table_for_size(group_members.size())

	if target_table:
		target_table.is_occupied = true
		var chairs = get_tree().get_nodes_in_group("seats").filter(
			func(node): return target_table.is_ancestor_of(node)
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
	_at_wait_area = false
	_bar_wait_handled = false

	is_moving = true
	curAnim = WALK
	nav_agent.target_position = target_seat.global_position

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = velocity.move_toward(safe_velocity, 0.25)
	move_and_slide()

func _on_navigation_agent_3d_target_reached() -> void:
	# If we're already in the sit sequence, don't overwrite position/anim with
	# "arrived at seat center" logic.
	if is_sitting:
		return

	if target_wait_area:
		_arrive_at_wait_area()
		_handle_bar_wait_arrived()
		return

	# Snap to the exact marker position
	var final_pos
	if target_seat:
		final_pos = target_seat.global_position
	else:
		final_pos = exit_position
	global_position = final_pos
	is_moving = false
	curAnim = IDLE
	velocity = Vector3.ZERO


func _arrive_at_wait_area() -> void:
	if _at_wait_area or target_wait_area == null:
		return
	_at_wait_area = true
	is_moving = false
	curAnim = IDLE
	velocity = Vector3.ZERO
	nav_agent.set_velocity(Vector3.ZERO)
	nav_agent.target_position = target_wait_area.global_position
	global_position = target_wait_area.global_position
	scale = Vector3.ONE
	_face_bar_counter()


func _face_bar_counter() -> void:
	# Match walk facing convention: yaw 0 = world +Z.
	rotation.y = 0.0


func _handle_bar_wait_arrived() -> void:
	if type != ChairType.BAR or _bar_wait_handled:
		return
	_bar_wait_handled = true
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

	order()
	await get_tree().create_timer(5.0).timeout
	# After order served: move to table
	if group_members.size() == 2:
		type = ChairType.TABLE2
	else:
		type = ChairType.TABLE4
	# Only the leader dispatches to avoid duplicate seat assignments.
	if is_leader:
		dispatch_group_to_table()

func sit():
	if not _can_sit_in_target_seat():
		return
	var seat_marker := target_seat.get_node("sitMarker") as Marker3D
	# Disable nav agent so it doesn't try to keep walking
	nav_agent.target_position = global_position
	curAnim = SIT
	# Smoothly move them into the chair over 1 seconds
	var tween = create_tween()
	tween.tween_property(self, "global_position", seat_marker.global_position - Vector3(0, 0.248, 0), 1)
	tween.parallel().tween_property(self, "global_rotation", seat_marker.global_rotation, 1)
	# if at the bar:
	if type == ChairType.CHAIR:
	#TODO: order()
		tween.finished.connect(func():
			order()
		)
	#TODO: be served()
	#if at table: just drink it (this func shouldnt be called in this case, but check in case
	else:
		await get_tree().create_timer(5.0).timeout
	
	
	# then leave

func order():
	if !is_leader:
		return

	# Wait until all members are in group_members (spawn_group assigns after all await)
	while group_members.size() < 1 or group_members.any(func(m): return m == null):
		await get_tree().process_frame
	
	var orders = OrderGen.repick(group_members.size())
	for i in range(orders.size()):
		group_members[i].drink = orders[i]
		group_members[i].has_ordered = true
		group_members[i].show_order_bubble()
	_spawn_order_ticket(orders)


func _spawn_order_ticket(orders: Array) -> void:
	if orders.is_empty():
		return
	var zone: Area3D = _find_free_ticket_zone(get_tree())
	if zone == null:
		return
	var ticket := TICKET_SCENE.instantiate()
	zone.add_child(ticket)
	if ticket.has_method("set_orders"):
		ticket.set_orders(_ticket_header(), orders)
	zone.place_object(ticket)
	for member in group_members:
		member.order_ticket = ticket


static func _find_free_ticket_zone(tree: SceneTree) -> Area3D:
	_ensure_ticket_zones(tree)
	var count := _ticket_zones.size()
	if count == 0:
		return null
	for i in count:
		var zone: Area3D = _ticket_zones[(_next_ticket_slot + i) % count]
		if not is_instance_valid(zone):
			continue
		if !zone.is_occupied:
			_next_ticket_slot = (_next_ticket_slot + i + 1) % count
			return zone
	return null


static func _ensure_ticket_zones(tree: SceneTree) -> void:
	var scene_root := tree.current_scene
	var stale := _ticket_zones_scene != scene_root
	if not stale:
		for zone in _ticket_zones:
			if not is_instance_valid(zone):
				stale = true
				break
	if not stale and not _ticket_zones.is_empty():
		return

	_ticket_zones_scene = scene_root
	_next_ticket_slot = 0
	_ticket_zones.clear()
	for node in tree.get_nodes_in_group("ticket_zone"):
		if node is Area3D and node.has_method("place_object"):
			_ticket_zones.append(node)
	_ticket_zones.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	if _ticket_zones.is_empty():
		push_warning("Customer: no nodes in group 'ticket_zone'.")


func _ticket_header() -> String:
	if isGroup:
		return "Table2" if group_members.size() == 2 else "Table4"
	return _bar_chair_header()


func _bar_chair_header() -> String:
	var chair_num := _bar_chair_number()
	if chair_num > 0:
		return "Bar %d" % chair_num
	return "Bar"


func _bar_chair_number() -> int:
	if target_seat == null:
		return 0
	var bar_chairs: Array = []
	for node in get_tree().get_nodes_in_group("seats"):
		if node.get_parent() and node.get_parent().name == "Bar chairs":
			bar_chairs.append(node)
	bar_chairs.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	for i in bar_chairs.size():
		if bar_chairs[i] == target_seat:
			return i + 1
	return 0


func show_order_bubble():
	if drink.is_empty():
		return
	
	# Get the name using your static helper
	var drink_name = OrderGen.get_name_drink(drink)

	# Update the UI
	drink_label.text = drink_name
	
	# Show the bubble
	bubble_sprite.visible = true
	
	# Optional: Hide it after a few seconds
	#await get_tree().create_timer(5.0).timeout
	#bubble_sprite.visible = false
	


const POUR_TOLERANCE := 0.20  # allow ±20% on each ingredient

func try_accept_drink(glass: Area3D) -> bool:
	# Build the list of unserved members to check against.
	# For solo customers, group_members contains just themselves.
	# For groups, it contains all members assigned by the leader.
	var candidates: Array = group_members.filter(
		func(m): return m.has_ordered and not m.has_been_served and not m.drink.is_empty()
	)
	
	if candidates.is_empty():
		print("No unserved members with orders.")
		return false

	for member in candidates:
		if _drink_matches(glass, member.drink):
			# Mark this member as served
			member.has_been_served = true
			member.has_ordered = false
			member.bubble_sprite.visible = false
			glass.queue_free()
			print("Served %s their drink!" % member.name)
			
			# Check if the whole group is now served
			var all_served = group_members.all(func(m): return m.has_been_served)
			if all_served:
				_clear_order_ticket()
				_dismiss_group()
			
			return true

	print("Glass contents don't match any pending order.")
	return false

func _drink_matches(glass: Area3D, order: Dictionary) -> bool:
	var required: Array = order.get("ingredients", [])
	if required.is_empty():
		return false

	var contents: Dictionary = glass.liquid.amount_per_drink_type
	
	print("[MATCH] Glass contents: ", contents)
	print("[MATCH] Required: ", required)

	for ingredient in required:
		var item: String = ingredient.get("item", "")
		var needed: float = ingredient.get("amount", 0.0)
		var tolerance: float = needed * POUR_TOLERANCE
		
		if item not in contents:
			return false

		if abs(contents[item] - needed) > tolerance:
			return false
	
	return true
	
	
func _clear_order_ticket() -> void:
	var ticket := order_ticket
	if ticket == null or not is_instance_valid(ticket):
		for member in group_members:
			member.order_ticket = null
		return
	order_ticket = null
	for member in group_members:
		member.order_ticket = null
	var zone := ticket.get_parent()
	if zone != null and zone.has_method("release_object") and zone.current_object == ticket:
		zone.release_object()
	ticket.queue_free()


func _dismiss_group() -> void:
	for member in group_members:
		member._float_and_vanish()
	
	
func _float_and_vanish() -> void:
	# Disable physics so they don't slide/collide during the animation
	set_physics_process(false)
	if nav_agent:
		nav_agent.set_physics_process(false)

	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)

	# Rise up 2 units over 1.2 seconds
	tween.tween_property(self, "global_position", global_position + Vector3(0, 2.0, 0), 1.2)

	# Fade out — requires the character mesh to use a material with alpha
	# Works if your customer model uses a StandardMaterial3D with transparency enabled
	for child in find_children("*", "MeshInstance3D", true, false):
		var mat = child.get_active_material(0)
		if mat:
			var unique_mat = mat.duplicate() as Material
			child.set_surface_override_material(0, unique_mat)
			tween.tween_property(unique_mat, "albedo_color:a", 0.0, 1.0)

		tween.finished.connect(func():
			# Free seat/wait_area so new customers can use them
			if target_seat:
				target_seat.is_occupied = false
			if target_wait_area:
				target_wait_area.is_occupied = false
			queue_free()
		)

func handle_animation(delta:float):
	match curAnim:
		IDLE:
			walk_value_anim = lerpf(walk_value_anim, 0, delta * blend_speed)
			sit_value_anim = lerpf(sit_value_anim, 0, delta * blend_speed)
		WALK:
			walk_value_anim = lerpf(walk_value_anim, 1, delta * blend_speed)
			sit_value_anim = lerpf(sit_value_anim, 0, delta * blend_speed)
		SIT:
			walk_value_anim = lerpf(walk_value_anim, 0, delta * blend_speed)
			sit_value_anim = lerpf(sit_value_anim, 1, delta * blend_speed / 5)
	update_tree()

func update_tree():
	if not is_instance_valid(animation_tree):
		return
	animation_tree["parameters/Walk/blend_amount"] = walk_value_anim
	animation_tree["parameters/Sit/blend_amount"] = sit_value_anim
