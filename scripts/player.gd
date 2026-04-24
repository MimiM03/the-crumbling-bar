# Player.gd
extends CharacterBody3D

@onready var order_gen = $OrderGen


const SPEED = 5.0
const MOUSE_SENSITIVITY = 0.1
enum Target {ZONE, PICKABLE}

@onready var camera: Camera3D = $Camera3D
var pitch := 0.0
var yaw := 0.0
var pickedObjectRight: Area3D
var pickedObjectLeft: Area3D
var mouse_visible := false

func _ready() -> void:
	# Mouse invisible in game (only crosshair)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Handle mouse interaction (left button)
	if event.is_action_pressed("pick"):
		#if clicked - check if zone vs pickable
		var target = ZoneOrPickable()
		print(target)
		# if zone - check if holding smth
		if target == Target.ZONE:
			if pickedObjectRight or pickedObjectLeft:
				drop_object()
		#if pickable - check if u can pick up
		elif target == Target.PICKABLE:
			var object = get_pointed_object()
			if object:
				pick_up_object(object)
				
	# Handle mouse visibility in game
	if event.is_action_pressed("mouse_vis"):
		if mouse_visible:
			mouse_visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			mouse_visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
	if event.is_action_pressed("order"):
		var _order = order_gen.repick(4)

# Handle camera rotation with mouse movement
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Horizontal
		rotation_degrees.y -= event.relative.x * MOUSE_SENSITIVITY
		
		# Vertical
		pitch -= event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, -90, 90)
		camera.rotation_degrees.x = pitch

func _physics_process(delta: float) -> void:
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

	var rotation_speed =  deg_to_rad(135) / 0.25
	# Handle pouring (Q left hand/E right hand):
	if pickedObjectRight:
		if Input.is_action_pressed("pour_right"):
			pickedObjectRight.rotation.x = move_toward(pickedObjectRight.rotation.x, deg_to_rad(-135),  rotation_speed * delta)
		else:
			# Return to upright (0 degrees)
			pickedObjectRight.rotation.x = move_toward(pickedObjectRight.rotation.x, 0, rotation_speed * delta)
	if pickedObjectLeft:
		if Input.is_action_pressed("pour_left"):
			pickedObjectLeft.rotation.x = move_toward(pickedObjectLeft.rotation.x, deg_to_rad(135),  rotation_speed * delta)
		else:
			# Return to upright (0 degrees)
			pickedObjectLeft.rotation.x = move_toward(pickedObjectLeft.rotation.x, 0, rotation_speed * delta)

	
	move_and_slide()
	
# Gets the object on the crosshair
func get_pointed_object():
	if $Camera3D/RayCast3D.is_colliding():
		var hit = $Camera3D/RayCast3D.get_collider()
		print(hit)
		
		# can only pick up if object is pickable
		if hit.is_in_group("pickables"):
			print("Picked up")
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
	else:
		return
	
	# Make the zone empty
	var parent = object.get_parent()
	print(parent)
	if parent.has_method("release_object"):
		parent.release_object()
	
	
	# Fix position and parent
	object.reparent(self)
	$Camera3D/RayCast3D.add_exception(object)
	if directionRight:
		object.global_position = %CarryObjectRightMarker.global_position
		object.global_rotation = %CarryObjectRightMarker.global_rotation
		await get_tree().create_timer(0.1).timeout
		pickedObjectRight = object
	else:
		object.global_position = %CarryObjectLeftMarker.global_position
		object.global_rotation = %CarryObjectLeftMarker.global_rotation
		await get_tree().create_timer(0.1).timeout
		pickedObjectLeft = object
	
	
	print("Obejct picked:" )
	print(object)
	

# Handles putting down an object
func drop_object():
	# Check if the zone is the correct
	var zone = get_nearby_zone()
	
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


func ZoneOrPickable():
	if $Camera3D/RayCast3D.is_colliding():
		var hit_collider = $Camera3D/RayCast3D.get_collider()
		
		if hit_collider.has_method("can_accept"):
			return Target.ZONE
		elif hit_collider.is_in_group("pickables"):
			return Target.PICKABLE
	return null
