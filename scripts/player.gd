# Player.gd
extends CharacterBody3D

var highGlassScene: PackedScene = preload("res://scenes/high_glass.tscn")
var shotGlassScene: PackedScene = preload("res://scenes/shot_glass.tscn")
var rocksGlassScene: PackedScene = preload("res://scenes/rocks_glass.tscn")

var glassContainer: NodePath = "../Glasses"

const SPEED = 5.0
const MOUSE_SENSITIVITY = 0.5
enum Target {ZONE, PICKABLE, ROCKS_GLASS, HIGH_GLASS, SHOT_GLASS, CUSTOMER}

# Define the Target Orientations
# This creates a rotation of 0 on Y
var upright_quad = Quaternion(Vector3.UP, deg_to_rad(0))

# "Pouring" position (60 on Y, 135 on Z)
var pour_quat_right = Quaternion(Vector3.UP, deg_to_rad(-60)) * Quaternion(Vector3.LEFT, deg_to_rad(-135))
var pour_juice_right = Quaternion(Vector3.UP, deg_to_rad(-60)) * Quaternion(Vector3.LEFT, deg_to_rad(-110))
var pour_quat_left = Quaternion(Vector3.UP, deg_to_rad(60)) * Quaternion(Vector3.RIGHT, deg_to_rad(135))
var pour_juice_left = Quaternion(Vector3.UP, deg_to_rad(60)) * Quaternion(Vector3.RIGHT, deg_to_rad(110))
@onready var camera: Camera3D = $Camera3D
var pitch := 0.0
var yaw := 0.0
var pickedObjectRight: Area3D
var pickedObjectLeft: Area3D
var mouse_visible := false
var is_in_cutscene: bool = false
var cutscene_timer = 0.0
var glass_spawn_location

func _ready() -> void:
	# Mouse invisible in game (only crosshair)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if is_in_cutscene and event.is_action_pressed("pick"):
		if cutscene_timer > 0.5:
			reset_pour()
			#is_in_cutscene = false
			cutscene_timer = 0.0
			return
	# Handle mouse interaction (left button)
	if event.is_action_pressed("pick") and !is_in_cutscene:
		#if clicked - check if zone vs pickable
		var target = ZonePickableOrGlass()
		# if zone - check if holding smth
		if target == Target.ZONE:
			if pickedObjectRight or pickedObjectLeft:
				drop_object()
		#if glass - pick up a glass
		elif target == Target.HIGH_GLASS or target == Target.SHOT_GLASS or target == Target.ROCKS_GLASS:
			pick_glass(target)
		#if pickable - check if u can pick up
		elif target == Target.PICKABLE:
			var object = get_pointed_object()
			
			if object:
				if (object.is_in_group("shaker") or object.is_in_group("glass")) and (pickedObjectLeft or pickedObjectRight):
					start_pouring(object)
				else:
					pick_up_object(object)
		elif target == Target.CUSTOMER:
			var customer = get_pointed_object_customer()
			print(customer)
			var held_glass = pickedObjectRight if pickedObjectRight else pickedObjectLeft
			if held_glass and held_glass.is_in_group("glass") and customer.has_method("try_accept_drink"):
				var accepted = customer.try_accept_drink(held_glass)
				if accepted:
					if pickedObjectRight == held_glass:
						pickedObjectRight = null
					else:
						pickedObjectLeft = null
			
	

# Handle camera rotation with mouse movement
func _unhandled_input(event: InputEvent) -> void:
	if is_in_cutscene:
		return
	if event is InputEventMouseMotion:
		var sens = Settings.mouse_sens
		# Horizontal
		rotation_degrees.y -= event.relative.x * sens
		
		# Vertical
		pitch -= event.relative.y * sens
		pitch = clamp(pitch, -90, 90)
		camera.rotation_degrees.x = pitch
		
	if event.is_action_pressed("debug_spawn_drink"):
		debug_spawn_matching_drink()

func _physics_process(delta: float) -> void:
	if is_in_cutscene:
		cutscene_timer += delta
	if !is_in_cutscene:
		# Get the input direction and handle the movement/deceleration.		
		var input_dir := Input.get_vector("left", "right", "forward", "back")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			# Smoothly stop the character
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
		move_and_slide()
	var rotation_speed =  deg_to_rad(135) / 0.25
		# Handle pouring (Q left hand/E right hand):
	if pickedObjectRight:
		var target_right
		var target = pour_quat_right
		if Input.is_action_pressed("pour_right"):
			if pickedObjectRight.is_in_group("juice") or pickedObjectRight.is_in_group("shaker") or pickedObjectRight.is_in_group("glass"):
				target_right = pour_juice_right
				target = pour_juice_right
			else:
				target_right = pour_quat_right
		else:
			target_right = upright_quad
		
		# Smoothly interpolate the entire rotation at once
		# slerp handles all axes simultaneously for a "perfect" arc
		pickedObjectRight.quaternion = pickedObjectRight.quaternion.slerp(target_right, rotation_speed * delta)
		can_pour(pickedObjectRight, Input.is_action_pressed("pour_right"), target, delta)
	if pickedObjectLeft:
		var target_left
		var target = pour_quat_left
		if Input.is_action_pressed("pour_left"):
			if pickedObjectLeft.is_in_group("juice") or pickedObjectLeft.is_in_group("shaker") or pickedObjectLeft.is_in_group("glass"):
				target_left = pour_juice_left
				target = pour_juice_left
			else:
				target_left = pour_quat_left
		else:
			target_left = upright_quad
			
		pickedObjectLeft.quaternion = pickedObjectLeft.quaternion.slerp(target_left, rotation_speed * delta)
		can_pour(pickedObjectLeft, Input.is_action_pressed("pour_left"), target, delta)
	
	
	
# Gets the object on the crosshair
func get_pointed_object():
	if $Camera3D/RayCast3D.is_colliding():
		var hit = $Camera3D/RayCast3D.get_collider()
		
		# can only pick up if object is pickable
		if hit.is_in_group("pickables"):
			return hit
	return null

# Handles picking up an object
func pick_up_object(object):
	var directionRight: bool
	# if hands empty - pick up with right hand
	if !pickedObjectRight and !pickedObjectLeft:
		directionRight = true
	# if right hand full, left hand empty - pick up with left hand
	elif !pickedObjectLeft:
		directionRight = false
	# if left hand full, right hand empty - pick up with right hand
	elif !pickedObjectRight:
		directionRight = true
	else:
		# Both hands full — do not set is_in_cutscene (would freeze movement with no tween to clear it).
		return

	is_in_cutscene = true
	# Make the zone empty
	var parent = object.get_parent()
	if parent.has_method("release_object"):
		parent.release_object()
	
	
	# Fix position and parent
	var tween = create_tween()
	$Camera3D/RayCast3D.add_exception(object)
	if directionRight:
		object.reparent(%CarryObjectRightMarker)
		tween.tween_property(object, "global_transform", %CarryObjectRightMarker.global_transform, 0.2)
		pickedObjectRight = object
	else:
		object.reparent(%CarryObjectLeftMarker)
		tween.tween_property(object, "global_transform", %CarryObjectLeftMarker.global_transform, 0.2)
		pickedObjectLeft = object
	
	tween.finished.connect(func():
		is_in_cutscene = false
	)
	
	print("Obejct picked:" )
	print(object)

# Handles putting down an object
func drop_object():
	# Check if the zone is the correct
	var zone = get_nearby_zone()
	if !zone:
		# Avoid calling can_accept() on null when the raycast hits nothing.
		print("No valid zone in sight!")
		return
	
	# Handle left and right 
	if pickedObjectRight and zone.can_accept(pickedObjectRight):
		$Camera3D/RayCast3D.remove_exception(pickedObjectRight)
		# Move the object out of the Player's hierarchy and into the zone
		pickedObjectRight.reparent(zone)
		
		# Tell the zone to handle the snapping
		zone.place_object(pickedObjectRight)
		
		pickedObjectRight = null
	elif pickedObjectLeft and zone.can_accept(pickedObjectLeft):
		$Camera3D/RayCast3D.remove_exception(pickedObjectLeft)
		# Move the object out of the Player's hierarchy and into the zone
		pickedObjectLeft.reparent(zone)
		
		# Tell the zone to handle the snapping
		zone.place_object(pickedObjectLeft)
		
		pickedObjectLeft = null
	else:
		#print(zone.can_accept(pickedObjectRight))
		# If the raycast isn't hitting a valid zone, do nothing 
		print("No valid zone in sight!")

# Check if the raycast is hitting anything right now
func get_nearby_zone():
	if $Camera3D/RayCast3D.is_colliding():
		var hit_collider = $Camera3D/RayCast3D.get_collider()
		
		# Check if the thing we hit has our 'can_accept' function
		if hit_collider.has_method("can_accept"):
			return hit_collider
	return null

func ZonePickableOrGlass():
	if $Camera3D/RayCast3D.is_colliding():
		var hit_collider = $Camera3D/RayCast3D.get_collider()
		
		if hit_collider.is_in_group("pickables"):
			return Target.PICKABLE
		elif hit_collider.is_in_group("glass"):
			# Future feat. maybe?: uncomment the following +
			# give glasses.gd to '*_glasses'
			#if hit_collider.has_method("decrease_num") and (!pickedObjectLeft or !pickedObjectRight):
				#hit_collider.decrease_num()
			glass_spawn_location = hit_collider.global_position
			if hit_collider.is_in_group("highGlass"):
				return Target.HIGH_GLASS
			elif hit_collider.is_in_group("shotGlass"):
				return Target.SHOT_GLASS
			elif hit_collider.is_in_group("rocksGlass"):
				return Target.ROCKS_GLASS
		elif hit_collider.has_method("can_accept"):
			return Target.ZONE
		elif hit_collider.is_in_group("customers"):
			return Target.CUSTOMER
		elif hit_collider.is_in_group("trash"):
			print("caught group")
			trash_item()
		
	return null

# Pour feature
func start_pouring(shaker):
	is_in_cutscene = true
	
	var tween = create_tween().set_parallel(true)
	
	var shaker_forward = shaker.global_transform.basis.z
	shaker_forward.y = 0
	shaker_forward = shaker_forward.normalized()

	var target_player_pos = shaker.global_position + (shaker_forward * 1.1)
	target_player_pos.y = self.global_position.y

	tween.tween_property(self, "global_position", target_player_pos, 0.3)
	if shaker.is_in_group("shaker"):
		tween.tween_property(self, "quaternion", Quaternion(Vector3.UP, PI), 0.3)
	else:
		tween.tween_property(self, "quaternion", Quaternion(Vector3.UP, 0), 0.3)
	var tilt_angle = deg_to_rad(-20.0)
	var target_tilt = Quaternion.from_euler(Vector3(tilt_angle, 0, 0))

	tween.tween_property(camera, "quaternion", target_tilt, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(camera, "fov", 60, 0.3).set_trans(Tween.TRANS_SINE)

	if pickedObjectRight:
		var target_transform = shaker.markerRight.global_transform

		pickedObjectRight.reparent(shaker.markerRight)
		# Reparent first, then tween in global space so bottles keep world alignment.
		tween.tween_property(pickedObjectRight, "global_transform", target_transform, 0.3)
		#pickedObjectRight = null
	if pickedObjectLeft:
		var target_transform = shaker.markerLeft.global_transform

		pickedObjectLeft.reparent(shaker.markerLeft)
		# Same for left hand: preserve world-space snap after reparenting.
		tween.tween_property(pickedObjectLeft, "global_transform", target_transform, 0.3)
		#pickedObjectLeft = null

func reset_pour():
	var tween = create_tween().set_parallel(true).set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	if pickedObjectRight:
		pickedObjectRight.reparent(%CarryObjectRightMarker)
		# Tween transform after reparenting back to the camera rig.
		tween.tween_property(pickedObjectRight, "global_transform", %CarryObjectRightMarker.global_transform, 0.2)
	if pickedObjectLeft:
		pickedObjectLeft.reparent(%CarryObjectLeftMarker)
		# Tween transform after reparenting back to the camera rig.
		tween.tween_property(pickedObjectLeft, "global_transform", %CarryObjectLeftMarker.global_transform, 0.2)
	
	# Reset the camera fov
	tween.tween_property(camera, "fov", 65, 0.3).set_trans(Tween.TRANS_SINE)
	
	tween.finished.connect(func():
		# Reset pitch sothe vertical mouse movement starts from the horizon
		pitch = camera.rotation_degrees.x
		
		# Sync the body's yaw (Y rotation) so turning starts from current direction
		rotation_degrees.y = self.rotation_degrees.y
		
		# Now that variables are synced, allow interaction/movement again
		is_in_cutscene = false
	)

func can_pour(object, is_pouring, target_quat, _delta):
	if object == null or not is_pouring:
		return
	
	#Check if bottle is rotated
	const ANGLE_TOLERANCE:= 10.0
	var angle_diff_deg = rad_to_deg(object.quaternion.angle_to(target_quat))
	if angle_diff_deg > ANGLE_TOLERANCE:
		return
		
	object.pour(_delta)

func pick_glass(target):
	if !pickedObjectLeft or !pickedObjectRight:
		var glass
		if target == Target.HIGH_GLASS:
			glass = highGlassScene.instantiate()
		elif target == Target.SHOT_GLASS:
			glass = shotGlassScene.instantiate()
		elif target == Target.ROCKS_GLASS:
			glass = rocksGlassScene.instantiate()
		get_node(glassContainer).add_child(glass, true)
		
		glass.global_position = glass_spawn_location
		pick_up_object(glass)

func trash_item():
	print("trashing")
	if pickedObjectRight:
		pickedObjectRight.queue_free()
	elif pickedObjectLeft:
		pickedObjectLeft.queue_free()
		
func get_pointed_object_customer():
	if $Camera3D/RayCast3D.is_colliding():
		var hit = $Camera3D/RayCast3D.get_collider()
		if hit.is_in_group("customers"):
			return hit
	return null
	
func debug_spawn_matching_drink() -> void:
	# Find the nearest customer with a pending order
	var customers = get_tree().get_nodes_in_group("customers")
	var target_customer = null
	var closest_dist = INF

	for c in customers:
		if c.has_ordered and not c.has_been_served and c.drink and not c.drink.is_empty():
			var d = global_position.distance_to(c.global_position)
			if d < closest_dist:
				closest_dist = d
				target_customer = c

	if not target_customer:
		print("[DEBUG] No customer with a pending order found.")
		return

	var order: Dictionary = target_customer.drink
	var glass_type: String = order.get("glass", "Glass")
	print("[DEBUG] Spawning '%s' for order: %s" % [glass_type, order.get("name", "?")])

	# Pick the right glass scene
	var glass_scene: PackedScene
	match glass_type:
		"Shot Glass":
			glass_scene = shotGlassScene
		"Rocks":
			glass_scene = rocksGlassScene
		_:
			glass_scene = highGlassScene

	# Instantiate and add to scene
	var glass = glass_scene.instantiate()
	get_node(glassContainer).add_child(glass, true)
	glass.global_position = camera.global_position + camera.global_transform.basis.z * -0.5

	# Pre-fill the glass with exact ingredient amounts
	var ingredients: Array = order.get("ingredients", [])
	for ing in ingredients:
		var item: String = ing.get("item", "")
		var amount: float = ing.get("amount", 0.0)
		# Directly write into amount_per_drink_type, bypassing pour physics
		glass.amount_per_drink_type[item] = amount
		glass.current_ml += amount

	glass.update_visual()

	# Put it in whichever hand is free
	pick_up_object(glass)
	print("[DEBUG] Glass ready — walk up to %s and click them." % target_customer.name)
