extends KinematicBody

var target_direction := Vector3()
var last_direction := Vector3()
var current_velocity: Vector3
var current_speed: float
const MIN_SPEED = 40
const MAX_SPEED = 80
const ACCELERATION = 1
const MAX_ALTITUDE = 112 # 7 cells * 16 m/cell
var is_braking = false

var my_camera: Camera
var camera_mount: Spatial
var camera_localposition = Vector3(0.5, 0.5, 2.0)
var target_camera_localposition = Vector3(0.5, 0.5, 2.0)
var cam_up_offset = 0.5
var cam_down_offset = -0.5
var cam_side_offset = 0.5
var cam_forward_offset = 1.5
var cam_back_offset = 2.5
var increment = 0.1

# Banking angle management
var banking_angle = 0.0
var target_banking_angle = 0.0
var ui_bankleft = false
var ui_bankright = false
var mouse_bankleft = false
var mouse_bankright = false



var my_collisionshape: CollisionShape

var my_model: Spatial

var MOUSE_SENSITIVITY = 0.05

# Called when the node enters the scene tree for the first time.
func _ready():
	make_camera()
	make_collision_shape()
	make_model()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):
	process_input(delta)
	process_movement(delta)
	update_camera()

func _process(delta):
	pass


func process_input(delta):

	target_direction = Vector3()
	var cam_xform = my_camera.get_global_transform()

	# Left/right input banking angle management
	ui_bankleft = false
	ui_bankright = false
	
	var input_movement_vector = Vector3()
	if Input.is_action_pressed("ui_up"):
		input_movement_vector.z -= 1
		if target_camera_localposition.z < cam_back_offset:
			target_camera_localposition.z += increment
	is_braking = false
	if Input.is_action_pressed("ui_down"):
		is_braking = true
		if target_camera_localposition.z > cam_forward_offset:
			target_camera_localposition.z -= increment
	if Input.is_action_pressed("ui_left"):
		input_movement_vector.x -= 1
		ui_bankleft = true
		if target_camera_localposition.x > -cam_side_offset:
			target_camera_localposition.x -= increment
	if Input.is_action_pressed("ui_right"):
		input_movement_vector.x += 1
		ui_bankright = true
		if target_camera_localposition.x < cam_side_offset:
			target_camera_localposition.x += increment
	if Input.is_action_pressed("ui_jump"):
		input_movement_vector.y += 1
		if target_camera_localposition.y < cam_up_offset:
			target_camera_localposition.y += increment
	if Input.is_action_pressed("ui_duck"):
		input_movement_vector.y -= 1
#		if target_camera_localposition.y > cam_down_offset:
#			target_camera_localposition.y -= increment

	input_movement_vector = input_movement_vector.normalized()

	# Basis vectors are already normalized.
	target_direction += cam_xform.basis.x * input_movement_vector.x
	target_direction += cam_xform.basis.y * input_movement_vector.y
	target_direction += cam_xform.basis.z * input_movement_vector.z
	
	# Record last directional input for residual movement
	if target_direction != Vector3.ZERO:
		last_direction = target_direction
	# ----------------------------------
	
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# ----------------------------------

func process_movement(delta):
	var target_velocity
	if (target_direction != Vector3.ZERO):
		if not is_braking:
			target_velocity = target_direction*MAX_SPEED
		else:
			target_velocity = target_direction*MIN_SPEED*0.5
	else:
		# Align movement to camera
		var cam_xform = my_camera.get_global_transform()
		target_velocity = Vector3()
		# Basis vectors are already normalized.
		target_velocity -= cam_xform.basis.z
		if not is_braking:
			target_velocity = target_velocity*MIN_SPEED
		else:
			target_velocity = target_velocity*MIN_SPEED*0.5
			
	# Max altitude management
	if translation.y > MAX_ALTITUDE:
		target_velocity.y = -20
	
	current_velocity = current_velocity.linear_interpolate(target_velocity, 2.0*ACCELERATION * delta)
	current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))
		
	# Orient model
	target_banking_angle = 0.75*(-(float(ui_bankleft) + float(mouse_bankleft)) + (float(ui_bankright) + float(mouse_bankright)))
	banking_angle = lerp_angle(banking_angle, target_banking_angle, ACCELERATION * delta)
	my_model.look_at(translation + current_velocity, (Vector3.UP).rotated(current_velocity.normalized(), banking_angle))
	
	# Update camera local position
	camera_localposition = camera_localposition.linear_interpolate(target_camera_localposition, ACCELERATION * delta)


# Mouse input management
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var v_input = deg2rad(-event.relative.y * MOUSE_SENSITIVITY)
		var h_input = deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1)
		camera_mount.rotate_x(v_input)
		self.rotate_y(h_input)

		var camera_rot = camera_mount.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		camera_mount.rotation_degrees = camera_rot
		
		# Update camera y offset
		if v_input > 0.01:
			if target_camera_localposition.y < cam_up_offset:
				target_camera_localposition.y += increment
		elif v_input < -0.01:
			if target_camera_localposition.y > cam_down_offset:
				target_camera_localposition.y -= increment
				
		# Update target banking angle and camera x offset
		mouse_bankleft = false
		mouse_bankright = false
		if h_input > 0.01:
			mouse_bankleft = true
			if target_camera_localposition.x < cam_side_offset:
				target_camera_localposition.x += increment
		elif h_input < -0.01:
			mouse_bankright = true
			if target_camera_localposition.x > -cam_side_offset:
				target_camera_localposition.x -= increment
		else:
			target_banking_angle = 0
	else:
		target_banking_angle = 0

func make_model():
	my_model = Spatial.new()
	add_child(my_model)
	
	# Body
	var meshinstance = MeshInstance.new()
	my_model.add_child(meshinstance)
	meshinstance.mesh = SphereMesh.new()
	meshinstance.mesh.set_radius(0.5)
	meshinstance.mesh.set_height(1)
	meshinstance.mesh.set_radial_segments(4)
	meshinstance.mesh.set_rings(1)
	meshinstance.set_scale(Vector3(0.8, 0.8, 0.8))
	var mat = preload("res://materials/gray_v10.material")
	meshinstance.mesh.set_material(mat)
	
	# Base
	meshinstance = MeshInstance.new()
	my_model.add_child(meshinstance)
	meshinstance.mesh = SphereMesh.new()
	meshinstance.mesh.set_radius(0.5)
	meshinstance.mesh.set_height(1)
	meshinstance.mesh.set_radial_segments(4)
	meshinstance.mesh.set_rings(1)
	meshinstance.set_translation(Vector3(0.0, -0.25, 0.0))
	meshinstance.set_scale(Vector3(0.5, 0.5, 0.5))
	mat = preload("res://materials/gray_v10.material")
	meshinstance.mesh.set_material(mat)
	
	# Thruster
	meshinstance = MeshInstance.new()
	my_model.add_child(meshinstance)
	meshinstance.mesh = SphereMesh.new()
	meshinstance.mesh.set_radius(0.5)
	meshinstance.mesh.set_height(1)
	meshinstance.mesh.set_radial_segments(4)
	meshinstance.mesh.set_rings(1)
	meshinstance.set_translation(Vector3(0.0, 0.0, 0.25))
	meshinstance.set_scale(Vector3(0.4, 0.4, 0.4))
	mat = preload("res://materials/fx_yellow.material")
	meshinstance.mesh.set_material(mat)
	
	# Cockpit
	meshinstance = MeshInstance.new()
	my_model.add_child(meshinstance)
	meshinstance.mesh = SphereMesh.new()
	meshinstance.mesh.set_radius(0.5)
	meshinstance.mesh.set_height(1)
	meshinstance.mesh.set_radial_segments(4)
	meshinstance.mesh.set_rings(1)
	meshinstance.set_translation(Vector3(0.0, 0.1, -0.2))
	meshinstance.set_scale(Vector3(0.3, 0.3, 0.3))
	mat = preload("res://materials/pastel_cyan.material")
	meshinstance.mesh.set_material(mat)

func set_model_scale(_scale):
	my_model.scale = _scale

func make_collision_shape():
	my_collisionshape = CollisionShape.new()
	add_child(my_collisionshape)
	my_collisionshape.shape = CapsuleShape.new()
	my_collisionshape.shape.set_radius(0.5)
	my_collisionshape.shape.set_height(0.5)

func set_collision_shape_radius_height(_radius, _height):
	my_collisionshape.set_radius(_radius)
	my_collisionshape.set_height(_height)

func make_camera():
	camera_mount = Spatial.new()
	add_child(camera_mount)
	my_camera = Camera.new()
	my_camera.far = 620
	camera_mount.add_child(my_camera)
	my_camera.set_translation(camera_localposition)

# Uses raycast, call in _physics_process
func update_camera():
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(translation, camera_mount.to_global(camera_localposition),[self])
	if result:
		my_camera.set_translation(camera_mount.to_local(result.position))
	else:
		my_camera.set_translation(camera_localposition)

