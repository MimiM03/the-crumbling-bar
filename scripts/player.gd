# Player.gd
extends CharacterBody3D


const SPEED = 5.0
const MOUSE_SENSITIVITY = 0.1
enum Target {ZONE, PICKABLE}

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
			is_in_cutscene = false
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
	object.reparent(camera)
	var tween = create_tween()
	$Camera3D/RayCast3D.add_exception(object)
	if directionRight:
		tween.tween_property(object, "global_transform", %CarryObjectRightMarker.global_transform, 0.2)
		#object.global_position = %CarryObjectRightMarker.global_position
		#object.global_rotation = %CarryObjectRightMarker.global_rotation
		#await get_tree().create_timer(0.1).timeout
		pickedObjectRight = object
	else:
		tween.tween_property(object, "global_transform", %CarryObjectLeftMarker.global_transform, 0.2)
		#object.global_position = %CarryObjectLeftMarker.global_position
		#object.global_rotation = %CarryObjectLeftMarker.global_rotation
		#await get_tree().create_timer(0.1).timeout
		pickedObjectLeft = object
	
	
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
	set_collision_mask_value(2, false)
	is_in_cutscene = true
	
	var tween = create_tween().set_parallel(true)

	var shaker_forward = shaker.global_transform.basis.z
	shaker_forward.y = 0
	shaker_forward = shaker_forward.normalized()

	var target_player_pos = shaker.global_position + (shaker_forward * 0.65)
	target_player_pos.y = self.global_position.y

	tween.tween_property(self, "global_position", target_player_pos, 0.3)
	tween.tween_property(self, "quaternion", Quaternion.IDENTITY, 0.3)
	var tilt_angle = deg_to_rad(-45.0)
	var target_tilt = Quaternion.from_euler(Vector3(tilt_angle, 0, 0))

	tween.tween_property(camera, "quaternion", target_tilt, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(camera, "fov", 75, 0.3).set_trans(Tween.TRANS_SINE)

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
		#pickedObjectRight = shaker.markerRight.get_child(0)
		pickedObjectRight.reparent(camera)
		# Tween local transform after reparenting back to the camera rig.
		var local_target = %CarryObjectRightMarker.transform
		tween.tween_property(pickedObjectRight, "transform", local_target, 0.3)
		
	if pickedObjectLeft:
		#pickedObjectLeft = shaker.markerLeft.get_child(0)
		pickedObjectLeft.reparent(camera)
		# Local-space tween keeps carried offsets stable across camera movement.
		var local_target = %CarryObjectLeftMarker.transform
		tween.tween_property(pickedObjectLeft, "transform", local_target, 0.3)
		
	
	# Get the direction the player is currently facing (which is the shaker)
	# basis.z is 'Backwards' in Godot's coordinate system
	var move_direction = self.global_transform.basis.z
	move_direction.y = 0
	move_direction = move_direction.normalized()
	
	# Move the player back by the 0.45m difference
	# (1.1 total distance - 0.65 current distance)
	var target_pos = self.global_position + (move_direction * 0.45)
	
	tween.tween_property(self, "global_position", target_pos, 0.3)

	# Reset the camera tilt to look straight again
	var tilt_angle = -30.0
	var target_tilt = Quaternion.from_euler(Vector3(deg_to_rad(tilt_angle), 0, 0))
	tween.tween_property(camera, "quaternion", target_tilt, 0.3).set_trans(Tween.TRANS_SINE).from_current()
	tween.tween_property(camera, "fov", 65, 0.3).set_trans(Tween.TRANS_SINE)
	
	tween.finished.connect(func():
		# Reset pitch sothe vertical mouse movement starts from the horizon
		pitch = tilt_angle
		camera.rotation_degrees.x = pitch
		
		# Sync the body's yaw (Y rotation) so turning starts from current direction
		rotation_degrees.y = self.rotation_degrees.y
		
		# Now that variables are synced, allow interaction/movement again
		is_in_cutscene = false
		set_collision_mask_value(2, true)
	)
