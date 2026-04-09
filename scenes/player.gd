# Player.gd
extends CharacterBody3D


const SPEED = 5.0
const MOUSE_SENSITIVITY = 0.1

@onready var camera: Camera3D = $Camera3D
var pitch := 0.0
var yaw := 0.0
var pickedObjectRight: Area3D
var mouse_visible := false

func _ready() -> void:
	# Mouse invisible in game (only crosshair)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Handle mouse interaction (left button)
	if event.is_action_pressed("pick"):
		if pickedObjectRight:
			drop_object()
		else:
			var target = get_pointed_object()
			if target:
				pick_up_object(target)
				
	# Handle mouse visibility in game
	if event.is_action_pressed("mouse_vis"):
		if mouse_visible:
			mouse_visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			mouse_visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Handle camera rotation with mouse movement
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Horizontal
		yaw -= event.relative.x * MOUSE_SENSITIVITY
		yaw = clamp (yaw, -90, 90)
		rotation_degrees.y = yaw
		
		# Vertical
		pitch -= event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, -90, 90)
		camera.rotation_degrees.x = pitch

func _physics_process(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.		
	var direction := Input.get_axis("left", "right")
	velocity.x = direction * SPEED

	# Handle pouring (Q left hand/E right hand):
	# TODO: add Q: left hand
	if pickedObjectRight:
		if Input.is_action_pressed("pour_right"):
			pickedObjectRight.rotation.x = move_toward(pickedObjectRight.rotation.x, deg_to_rad(-135), deg_to_rad(135) / 0.3 * delta)
		else:
			# Return to upright (0 degrees)
			pickedObjectRight.rotation.x = move_toward(pickedObjectRight.rotation.x, 0, deg_to_rad(135) / 0.3 * delta)
	
	move_and_slide()
	
# Gets the object on the crosshair
func get_pointed_object():
	if $Camera3D/RayCast3D.is_colliding():
		var hit = $Camera3D/RayCast3D.get_collider()
		print(hit)
		
		# can only pick up if object is packable
		if hit.is_in_group("pickables"):
			print("found")
			return hit
	return null

# Handles picking up an object
func pick_up_object(object):
	# Make the zone empty
	var parent = object.get_parent()
	print(parent)
	if parent.has_method("release_object"):
		parent.release_object()
	
	# Fix position and parent
	object.reparent(self)
	$Camera3D/RayCast3D.add_exception(object)
	object.global_position = %CarryObjectRightMarker.global_position
	object.global_rotation = %CarryObjectRightMarker.global_rotation
	
	await get_tree().create_timer(0.1).timeout
	pickedObjectRight = object
	print("Obejct picked:" )
	print(pickedObjectRight)

# Handles putting down an object
func drop_object():
	if !pickedObjectRight: return
	
	# Check if the zone is the correct
	var zone = get_nearby_zone()
	if zone and zone.can_accept(pickedObjectRight):
		$Camera3D/RayCast3D.remove_exception(pickedObjectRight)
		# Move the object out of the Player's hierarchy and into the zone
		pickedObjectRight.reparent(zone)
		
		# Tell the zone to handle the snapping
		zone.place_object(pickedObjectRight)
		
		pickedObjectRight = null
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
