extends CharacterBody3D


const SPEED = 13
const JUMP_VELOCITY = 13

@onready var standCol = $standingCollision
@onready var airCol = $airCollision

@onready var camera = $camera_anchor
@onready var model = $main
const cam_spd = 2.5
var cam_vert = 0

@onready var animationes = $AnimationTree
var jumping_whole = 0.0
var running_whole = 0.0

func omni_whole(whole: float, speed: float, reverse: bool, delta: float):
	var limit = 1
	if (whole < limit) and not reverse:
		whole += speed * delta
	elif (whole > 0) and reverse:
		whole += -speed * delta
	return clamp(whole,0,limit)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * 2 * delta
		jumping_whole = omni_whole(jumping_whole,2.5,false,delta)
		if jumping_whole == 1 and airCol.disabled == true:
			standCol.disabled = true
			airCol.disabled = false
	else:
		jumping_whole = omni_whole(jumping_whole,6,true,delta)
		if jumping_whole == 0 and standCol.disabled == true:
			standCol.disabled = false
			airCol.disabled = false

	# Handle jump.
	if Input.is_action_just_pressed("ActionA") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	#camera (bwarp bwapr) (Aided by chatgpt)
	var based = camera.global_transform.basis
	var max_vert = deg_to_rad(55)
	var min_vert = -max_vert
	var cam_input = {
		"hor": Input.get_axis("RstickRight","RstickLeft"),
		"ver": Input.get_axis("RstickDown", "RstickUp")
	}
	var cam_dir = Vector2(cam_input.hor,cam_input.ver)
	
	if cam_dir:
		camera.rotation.y += (cam_dir.x * cam_spd) * delta
		cam_vert += (cam_dir.y * cam_spd) * delta
	else:
		camera.rotation.y = camera.rotation.y
	
	cam_vert = clamp(cam_vert,min_vert,max_vert)
	camera.rotation.x = cam_vert

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir: Vector2 = Input.get_vector("LstickLeft","LstickRight","LstickUp","LstickDown")
	var direction: Vector3 = (based.x * input_dir.x + based.z * input_dir.y).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	#what am i staring at? you or the sun?
	if direction.length() > 0.1:
		var pinch = atan2(direction.z,-direction.x)
		model.rotation.y = lerp_angle(model.rotation.y,pinch,7*delta)
	
	#me see anim input
	if input_dir:
		running_whole = omni_whole(running_whole,2.3,false,delta)
	else:
		running_whole = omni_whole(running_whole,2.7,true,delta)
	
	animationes.set("parameters/blend_grounded/blend_amount", jumping_whole)
	animationes.set("parameters/blend_movement/blend_amount", running_whole)
	
	move_and_slide()
