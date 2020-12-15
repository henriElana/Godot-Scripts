extends KinematicBody

var target_direction := Vector3()
var current_velocity: Vector3
var h_current_velocity: Vector3
const MAX_SPEED = 15
const JUMP_SPEED = 20
const ACCELERATION = 5
const CAMERA_ACCELERATION = 2
const GRAVITY = -30
const ROTATION_SPEED = 5
const MAX_ALTITUDE = 112 # 7 cells * 16 m/cell


var MOUSE_SENSITIVITY = 0.05

var is_jump_pressed = false
var is_dash_pressed = false

const MAX_STAMINA = 100
const MIN_STAMINA = -5
const RECOVERY_RATE = 5
var current_stamina = 0.0
const DASH_COST = 30
const JUMP_COST = 30
const DASH_FACTOR = 4.0

var my_camera: Camera
var camera_mount: Spatial
var camera_localposition = Vector3(0.5, 0.5, 2.0)
var target_camera_localposition = Vector3(0.5, 0.5, 2.0)
var cam_up_offset = 1.5
var cam_down_offset = 0.5
var cam_side_offset = 0.5
var cam_forward_offset = 1.5
var cam_back_offset = 2.5
var increment = 0.1

var my_collisionshape: CollisionShape

var my_model: Spatial

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
	update_stamina(delta)


func process_input(delta):

	target_direction = Vector3()
	var cam_xform = my_camera.get_global_transform()

	var input_movement_vector = Vector3()

	is_jump_pressed = false
	is_dash_pressed = false
	if Input.is_action_pressed("ui_up"):
		input_movement_vector.z -= 1
		if target_camera_localposition.z < cam_back_offset:
			target_camera_localposition.z += increment
	if Input.is_action_pressed("ui_down"):
		input_movement_vector.z += 1
		if target_camera_localposition.z > cam_forward_offset:
			target_camera_localposition.z -= increment
	if Input.is_action_pressed("ui_left"):
		input_movement_vector.x -= 1
		if target_camera_localposition.x > -cam_side_offset:
			target_camera_localposition.x -= increment
	if Input.is_action_pressed("ui_right"):
		input_movement_vector.x += 1
		if target_camera_localposition.x < cam_side_offset:
			target_camera_localposition.x += increment
	if Input.is_action_pressed("ui_jump"):
		is_jump_pressed = true
		if target_camera_localposition.y < cam_up_offset:
			target_camera_localposition.y = cam_up_offset
	if Input.is_action_pressed("ui_duck"):
		is_dash_pressed = true
		if target_camera_localposition.y > cam_down_offset:
			target_camera_localposition.y = cam_down_offset

	input_movement_vector = input_movement_vector.normalized()

	# Basis vectors are already normalized.
	target_direction += cam_xform.basis.x * input_movement_vector.x
	target_direction += cam_xform.basis.z * input_movement_vector.z
	# ----------------------------------

	# Jumping
	if is_on_floor() or (current_stamina > 0.0):
		if is_jump_pressed:
			current_velocity.y = JUMP_SPEED

	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# ----------------------------------

func process_movement(delta):
	target_direction.y = 0.0
	target_direction = target_direction.normalized()
	
	# Movement management when already moving
	if h_current_velocity.length_squared() > 2:
		interpolate_velocity(delta)
		
		# Orient model
		my_model.look_at(translation + h_current_velocity, Vector3.UP)
	# Model still and no input
	elif target_direction.length_squared() < 0.5:
		manage_freefall(delta)
	# When still an movement input, align model with target_direction before moving
	else:
		# Sinus of angle from model front to target direction ; positive -> rotate left -> positive angle.
		var model_forward = -my_model.global_transform.basis.z*Vector3.ONE
		var sinus = model_forward.cross(target_direction).y
		var angle = model_forward.angle_to(target_direction)
		# is model aligned with target_direction ?
		if angle < 0.05:
			# Yes : start normal movement
			interpolate_velocity(delta)
			# Orient model
			my_model.look_at(translation + h_current_velocity, Vector3.UP)
		else:
			# No : rotate model. sinus > 0 --> positive rotation
			var rotation_sign = 2*int(sinus > 0)-1
			my_model.rotate_y(rotation_sign*ROTATION_SPEED*delta)
			manage_freefall(delta)
	
	
	# Update camera local position
	camera_localposition = camera_localposition.linear_interpolate(target_camera_localposition, CAMERA_ACCELERATION * delta)

func interpolate_velocity(delta):
	if current_velocity.y > -30:
		current_velocity.y += delta*GRAVITY
	
	h_current_velocity = current_velocity
	h_current_velocity.y = 0.0
	
	var target_velocity = target_direction*MAX_SPEED
	if is_dash_pressed and (current_stamina > 0.0):
		target_velocity *= DASH_FACTOR
	
	# Max altitude management
	if translation.y > MAX_ALTITUDE:
		target_velocity.y = -20
		
	h_current_velocity = h_current_velocity.linear_interpolate(target_velocity, ACCELERATION * delta)
	current_velocity.x = h_current_velocity.x
	current_velocity.z = h_current_velocity.z
	
	current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))

func manage_freefall(delta):
	# Just to be sure.
	current_velocity.x = 0.0
	current_velocity.z = 0.0
	
	if current_velocity.y > -30:
		current_velocity.y += delta*GRAVITY
	
	current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))


func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var v_input = deg2rad(-event.relative.y * MOUSE_SENSITIVITY)
		var h_input = deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1)
		camera_mount.rotate_x(v_input)
		self.rotate_y(h_input)
		# Compensate model rotation when still
		if target_direction.length_squared() < 0.1:
			my_model.rotate_y(-h_input)

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
				
		# Update camera x offset
		if h_input > 0.01:
			if target_camera_localposition.x < cam_side_offset:
				target_camera_localposition.x += increment
		elif h_input < -0.01:
			if target_camera_localposition.x > -cam_side_offset:
				target_camera_localposition.x -= increment

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

func update_stamina(delta):
	if current_stamina < MAX_STAMINA:
		current_stamina += RECOVERY_RATE*delta
	if current_stamina > MAX_STAMINA:
		current_stamina = MAX_STAMINA
	if is_jump_pressed:
		current_stamina -= JUMP_COST*delta
	if is_dash_pressed:
		current_stamina -= DASH_COST*delta
	if current_stamina < MIN_STAMINA:
		current_stamina = MIN_STAMINA
