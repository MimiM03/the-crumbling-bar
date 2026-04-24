# Player.gd
extends CharacterBody3D

@onready var order_gen = $OrderGen


const SPEED = 5.0
const MOUSE_SENSITIVITY = 0.1
enum Target {ZONE, PICKABLE}

# Define the Target Orientations
# This creates a rotation of 0 on Y
var upright_quad = Quaternion(Vector3.UP, deg_to_rad(0))

# "Pouring" position (60 on Y, 135 on Z)
var pour_quat_right = Quaternion(Vector3.UP, deg_to_rad(-60)) * Quaternion(Vector3.LEFT, deg_to_rad(-135))
var pour_quat_left = Quaternion(Vector3.UP, deg_to_rad(60)) * Quaternion(Vector3.RIGHT, deg_to_rad(135))
@onready var camera: Camera3D = $Camera3D
var pitch := 0.0
var yaw := 0.0
var pickedObjectRight: Area3D
var pickedObjectLeft: Area3D
var mouse_visible := false
var is_in_cutscene: bool = false
var cutscene_timer = 0.0

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
		var target = ZoneOrPickable()
		# if zone - check if holding smth
		if target == Target.ZONE:
			if pickedObjectRight or pickedObjectLeft:
				drop_object()
		#if pickable - check if u can pick up
		elif target == Target.PICKABLE:
			var object = get_pointed_object()
			
			if object:
				if object.is_in_group("shaker") and (pickedObjectLeft or pickedObjectRight):
					start_pouring(object)
				else:
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
	if is_in_cutscene:
		return
	if event is InputEventMouseMotion:
		# Horizontal
		rotation_degrees.y -= event.relative.x * MOUSE_SENSITIVITY
		
		# Vertical
		pitch -= event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, -90, 90)
		camera.rotation_degrees.x = pitch

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
		var target_right = pour_quat_right if Input.is_action_pressed("pour_right") else upright_quad
		
		# Smoothly interpolate the entire rotation at once
		# slerp handles all axes simultaneously for a "perfect" arc
		pickedObjectRight.quaternion = pickedObjectRight.quaternion.slerp(target_right, rotation_speed * delta)
		
	if pickedObjectLeft:
		var target_left = pour_quat_left if Input.is_action_pressed("pour_left") else upright_quad
		pickedObjectLeft.quaternion = pickedObjectLeft.quaternion.slerp(target_left, rotation_speed * delta)
	
	
	
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
	is_in_cutscene = true
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
		return
	
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
		
		if hit_collider.is_in_group("pickables"):
			return Target.PICKABLE
		elif hit_collider.has_method("can_accept"):
			return Target.ZONE
		
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
	tween.tween_property(self, "quaternion", Quaternion.IDENTITY, 0.3)
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
