extends KinematicBody

var target_direction := Vector3()
var current_velocity: Vector3
const MAX_SPEED = 20 
var my_camera: Camera


var MOUSE_SENSITIVITY = 0.05

# Called when the node enters the scene tree for the first time.
func _ready():
	my_camera = Camera.new()
	my_camera.far = 620
	add_child(my_camera)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):
	process_input(delta)
	process_movement(delta)


func process_input(delta):

	target_direction = Vector3()
	var cam_xform = my_camera.get_global_transform()

	var input_movement_vector = Vector3()

	if Input.is_action_pressed("ui_up"):
		input_movement_vector.z -= 1
	if Input.is_action_pressed("ui_down"):
		input_movement_vector.z += 1
	if Input.is_action_pressed("ui_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_movement_vector.x += 1
	if Input.is_action_pressed("ui_jump"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("ui_duck"):
		input_movement_vector.y -= 1

	input_movement_vector = input_movement_vector.normalized()

	# Basis vectors are already normalized.
	target_direction += cam_xform.basis.x * input_movement_vector.x
	target_direction += cam_xform.basis.y * input_movement_vector.y
	target_direction += cam_xform.basis.z * input_movement_vector.z
	# ----------------------------------

	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# ----------------------------------

func process_movement(delta):
	current_velocity = target_direction*MAX_SPEED
	current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		my_camera.rotate_x(deg2rad(-event.relative.y * MOUSE_SENSITIVITY))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))

		var camera_rot = my_camera.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		my_camera.rotation_degrees = camera_rot
