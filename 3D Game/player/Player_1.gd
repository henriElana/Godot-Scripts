extends KinematicBody

var game_manager

# States manager
enum State {GROUNDED,AIRBORNE,SHOCK,DODGE,CLIMB,FOCUS,RUSH,ATTACK}
var current_state = State.GROUNDED

var directional_input := Vector3()
var last_dir_input := Vector3(0, 0, -1)
var aim_input := Vector3()
var dodge_input := Vector3()
var is_dodge_started = false
var is_jump_input = false
var is_dodge_input = false
var is_shoot_input = false
var is_mortar_input = false
var is_rush_input = false

var can_attack = true
const GUN_COOLDOWN = 0.2 # Direct attack
const MORTAR_COOLDOWN = 0.8 # Vertical attack

var can_rush = true
const STRAIGHT_RUSH_COOLDOWN = 0.5 # Direct attack
const SLAM_RUSH_COOLDOWN = 1.0 # Vertical attack
const SLAM_COLLIDER_OFFSET = Vector3(0, -1, -1)
const STRAIGHT_COLLIDER_OFFSET = Vector3(0,0,-2)
const SLAM_COLLIDER_RADIUS = 2.0
const STRAIGHT_COLLIDER_RADIUS = 1.0

var rush_start_position := Vector3()
var rush_target_position := Vector3()

var current_velocity: Vector3
var h_current_velocity: Vector3
const MAX_SPEED = 15
const CLIMBING_SPEED = 10
const JUMP_SPEED = 20
const ACCELERATION = 5
const CAMERA_ACCELERATION = 2
const GRAVITY = -30
const ROTATION_SPEED = 10

var MOUSE_SENSITIVITY = 0.05


const MAX_HEALTH = 100
var current_health = 100
const MAX_ENERGY = 100
const RECOVERY_RATE = 5
var current_energy = 100
var is_regenerating = true
const DASH_COST = -30
const DASH_FACTOR = 2.0
const DODGE_COST = -10.0
const DODGE_SPEED = 30
const DODGE_JUMP_SPEED = 10.0
var dodge_roll_angle = 0.0
var dodge_initial_facing = Vector3.ZERO
var rollaxis = Vector3.LEFT
var regen_timer :Timer
var attacks_timer :Timer

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
var collider_radius = 0.8

var my_model: Spatial
var model_mount :Spatial

var climb_ray: RayCast

# Weapons
var gun_mount: Spatial
var aiming_ray: RayCast
var target_pointer: Spatial
var mat_pointer_yellow = preload("res://materials/fx_yellow.material")
var mat_pointer_green = preload("res://materials/fx_green.material")
var mat_pointer_blue = preload("res://materials/fx_cyan.material")


# Called when the node enters the scene tree for the first time.
func _ready():
	game_manager = get_parent()
	make_camera()
	make_collision_shape()
	make_model()
	make_climb_ray()
	make_timers()
	make_gun()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):
	process_input(delta)
	match current_state:
		State.GROUNDED:
			process_grounded_movement(delta)
		State.AIRBORNE:
			process_airborne_movement(delta)
		State.SHOCK:
			pass
		State.DODGE:
			process_dodge_movement(delta)
		State.CLIMB:
			process_climb_movement(delta)
		State.FOCUS:
			pass
		State.RUSH:
			pass
		State.ATTACK:
			pass
	update_camera(delta)
	if is_regenerating:
		regenerate_energy_health(delta)


func process_input(delta):

	directional_input = Vector3()
	
	var cam_xform = my_camera.get_global_transform()
	aim_input = -cam_xform.basis.z

	var input_movement_vector = Vector3()

	is_jump_input = false
	is_dodge_input = false
	is_shoot_input = false	
	is_mortar_input = false	
	is_rush_input = false	
	
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
		is_jump_input = true
	if Input.is_action_pressed("ui_duck"):
		is_dodge_input = true
	if Input.is_action_pressed("ui_lmb"):
		is_shoot_input = true
	if Input.is_action_pressed("ui_rmb"):
		is_rush_input = true
	if Input.is_action_pressed("ui_mmb"):
		is_mortar_input = true

	input_movement_vector = input_movement_vector.normalized()

	# Basis vectors are already normalized.
	directional_input += cam_xform.basis.x * input_movement_vector.x
	directional_input += cam_xform.basis.z * input_movement_vector.z
	directional_input.y = 0.0
	directional_input = directional_input.normalized()
	# ----------------------------------
	if directional_input != Vector3.ZERO:
		last_dir_input = directional_input

	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# ----------------------------------

func interpolate_velocity(delta):
	
	if is_jump_input:
		current_velocity.y = JUMP_SPEED
	elif current_velocity.y > -60:
		current_velocity.y += delta*GRAVITY
	
	h_current_velocity = current_velocity
	h_current_velocity.y = 0.0
	
	var target_velocity = directional_input*MAX_SPEED
	if is_dodge_input:
		if current_energy > 0.0:
			dodge_input = directional_input
			is_dodge_started = false
			edit_energy(DODGE_COST)
			current_state = State.DODGE
	
	h_current_velocity = h_current_velocity.linear_interpolate(target_velocity, ACCELERATION * delta)
	current_velocity.x = h_current_velocity.x
	current_velocity.z = h_current_velocity.z
	
	current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))

func process_grounded_movement(delta):
	
	update_gun_pointer()
	
	if !is_on_floor():
		current_state = State.AIRBORNE
		activate_aim()
	elif climb_ray.is_colliding():
		current_state = State.CLIMB
		deactivate_aim()
	else:
		# Movement management when already moving
		if h_current_velocity.length_squared() > 2:
			interpolate_velocity(delta)
			# Orient model
			model_mount.look_at(translation + h_current_velocity, Vector3.UP)
			
		# When still and movement input, align model with directional_input before moving
		elif directional_input.length_squared() > 0.1:
			# Angle from model front to target direction ; positive -> rotate left -> positive angle.
			var model_forward = -model_mount.global_transform.basis.z*Vector3.ONE
			var sinus = model_forward.cross(directional_input).y
			var angle = model_forward.angle_to(directional_input)
			# is model aligned with directional_input ?
			if angle < 0.2:
				# Yes : start normal movement
				interpolate_velocity(delta)
				# Orient model
				model_mount.look_at(translation + h_current_velocity, Vector3.UP)
			else:
				# No : rotate model. sinus > 0 --> positive rotation
				var rotation_sign = 2*int(sinus > 0)-1
				model_mount.rotate_y(rotation_sign*ROTATION_SPEED*delta)
				
				# But can still dodge !
				if is_dodge_input:
					if current_energy > 0.0:
						dodge_input = directional_input
						is_dodge_started = false
						edit_energy(DODGE_COST)
						current_state = State.DODGE
				
		else:
			interpolate_velocity(delta)
			
			# Orient model
			model_mount.look_at(translation + last_dir_input, Vector3.UP)


func process_airborne_movement(delta):
	
	update_gun_pointer()
	
	if is_on_floor():
		current_state = State.GROUNDED
		activate_aim()
	elif (directional_input.length_squared() > 0.1) and (climb_ray.is_colliding()):
		current_state = State.CLIMB
		deactivate_aim()
	else:
		# Manage freefall
		if current_velocity.y > -60:
			current_velocity.y += delta*GRAVITY
		
		current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))
		


func process_climb_movement(delta):
		
	if ! climb_ray.is_colliding():
		current_state = State.AIRBORNE
		activate_aim()
		# Orient model
		model_mount.look_at(translation + last_dir_input, Vector3.UP)
	else :
		if directional_input.length_squared() < 0.1:
			# Orient model
			model_mount.look_at(translation + last_dir_input, Vector3.UP)
			current_state = State.AIRBORNE
			activate_aim()
		else:
			var wall_normal = climb_ray.get_collision_normal()
			var cosinus = wall_normal.dot(directional_input)
			if cosinus < 0.0:
				# Input towards wall : climb
				current_velocity.y = CLIMBING_SPEED
				h_current_velocity = current_velocity
				h_current_velocity.y = 0.0
				
				var target_velocity = directional_input*MAX_SPEED
				
				h_current_velocity = h_current_velocity.linear_interpolate(target_velocity, ACCELERATION * delta)
				current_velocity.x = h_current_velocity.x
				current_velocity.z = h_current_velocity.z
				
				current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))
				
				# Orient model
				model_mount.look_at(translation - wall_normal, current_velocity)
				
			else:
				# Input away from wall : drop
				if current_velocity.y > -60:
					current_velocity.y += delta*GRAVITY
				h_current_velocity = current_velocity
				h_current_velocity.y = 0.0
				
				var target_velocity = directional_input*MAX_SPEED
				
				h_current_velocity = h_current_velocity.linear_interpolate(target_velocity, ACCELERATION * delta)
				current_velocity.x = h_current_velocity.x
				current_velocity.z = h_current_velocity.z
				
				current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))

func process_dodge_movement(delta):
	
	update_gun_pointer()
	
	if !is_dodge_started:
		current_velocity = dodge_input*DODGE_SPEED
		current_velocity.y = DODGE_JUMP_SPEED
		is_dodge_started = true
		dodge_roll_angle = 0.0
		# Roll axis ; 0.7 simeq sqrt(2)/2
		var model_forward = -model_mount.global_transform.basis.z*Vector3.ONE
		var cosinus = model_forward.dot(dodge_input)
		var sinus =  model_forward.cross(dodge_input).y
		if cosinus >= 0.7:
			rollaxis = Vector3.LEFT
		elif cosinus <= -0.7 :
			rollaxis = Vector3.RIGHT
		elif sinus < 0.0:
			rollaxis = Vector3.FORWARD
		elif sinus > 0.0:
			rollaxis = Vector3.BACK
		else:
			rollaxis = Vector3.RIGHT
	
	
	current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))

	if current_velocity.y > -60:
		current_velocity.y += delta*GRAVITY
		
	# Model roll
	if dodge_roll_angle < 6:
		var angle = ROTATION_SPEED*delta
		dodge_roll_angle += angle
		my_model.rotate_object_local(rollaxis,angle)
	else:
		# Orient model
		my_model.rotation = Vector3.ZERO
		
		current_state = State.AIRBORNE
		activate_aim()
		is_dodge_started = false

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var v_input = deg2rad(-event.relative.y * MOUSE_SENSITIVITY)
		var h_input = deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1)
		camera_mount.rotate_x(v_input)
		self.rotate_y(h_input)
		# Compensate model rotation when no input or airborne
		if (directional_input.length_squared() < 0.1) or (current_state == State.AIRBORNE):
			model_mount.rotate_y(-h_input)

		var camera_rot = camera_mount.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		camera_mount.rotation_degrees = camera_rot
		
		# Update camera y offset
		if v_input > 0.01:
			if target_camera_localposition.y > cam_down_offset:
				target_camera_localposition.y -= increment
		elif v_input < -0.01:
			if target_camera_localposition.y < cam_up_offset:
				target_camera_localposition.y += increment
				
		# Update camera x offset
		if h_input > 0.01:
			if target_camera_localposition.x < cam_side_offset:
				target_camera_localposition.x += increment
		elif h_input < -0.01:
			if target_camera_localposition.x > -cam_side_offset:
				target_camera_localposition.x -= increment

func make_model():
	model_mount = Spatial.new()
	add_child(model_mount)
	
	my_model = Spatial.new()
	model_mount.add_child(my_model)
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
	my_collisionshape.shape = SphereShape.new()
	my_collisionshape.shape.set_radius(collider_radius)
	setup_player_layer_mask(self)

func set_collision_shape_radius(_radius):
	my_collisionshape.set_radius(_radius)

func make_camera():
	camera_mount = Spatial.new()
	add_child(camera_mount)
	my_camera = Camera.new()
	my_camera.far = 620
	camera_mount.add_child(my_camera)
	my_camera.set_translation(camera_localposition)

# Uses raycast, call in _physics_process
func update_camera(delta):
	# Interpolate camera local position
	camera_localposition = camera_localposition.linear_interpolate(target_camera_localposition, CAMERA_ACCELERATION * delta)
	
	# If wallcheck raycast collides, snap to position without interpolation to maybe stay out of wall
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(translation, camera_mount.to_global(camera_localposition),[self])
	if result:
		my_camera.set_translation(camera_mount.to_local(result.position))
	else:
		my_camera.set_translation(camera_localposition)

func regenerate_energy_health(delta):
	if current_energy < MAX_ENERGY:
		current_energy += RECOVERY_RATE*delta
	else:
		if current_health < MAX_HEALTH:
			current_health += RECOVERY_RATE*delta
	
	game_manager.update_energy(current_energy)
	game_manager.update_life(current_health)

func edit_health(_value):
	is_regenerating = false
	regen_timer.start()
	current_health += _value
	if current_health > MAX_HEALTH:
		current_health = MAX_HEALTH
	elif current_health < 0:
		game_manager.player_dead()
	
	game_manager.update_life(current_health)

func edit_energy(_value):
	is_regenerating = false
	regen_timer.start()
	if _value > 0.0:
		if current_energy < MAX_ENERGY:
			current_energy += _value
			if current_energy > MAX_ENERGY:
				edit_health(current_energy - MAX_ENERGY)
				current_energy = MAX_ENERGY
		else:
			edit_health(_value)
	else:
		if current_energy > 0:
			current_energy += _value
			if current_energy < 0:
				edit_health(current_energy)
				current_energy = 0
		else:
			edit_health(_value)
	
	game_manager.update_energy(current_energy)

func make_climb_ray():
	climb_ray = RayCast.new()
	model_mount.add_child(climb_ray)
	climb_ray.set_cast_to(Vector3(0,0,-1.5*collider_radius))
	climb_ray.add_exception(self)
	climb_ray.set_collision_mask(2) # Only collide with layer 2 : terrain
	climb_ray.set_enabled(true)
	

func make_gun():
	gun_mount = Spatial.new()
	add_child(gun_mount)
	
	aiming_ray = RayCast.new()
	gun_mount.add_child(aiming_ray)
	aiming_ray.set_cast_to(Vector3(0, 0, -200))
	aiming_ray.add_exception(self)
	aiming_ray.set_collision_mask(6) # Collide with layers 2,3 : terrain+mobs
	aiming_ray.set_enabled(true)
	
	target_pointer = Spatial.new()
	game_manager.add_child(target_pointer)
	# Pointer model
	var meshinstance = MeshInstance.new()
	target_pointer.add_child(meshinstance)
	meshinstance.mesh = SphereMesh.new()
	meshinstance.mesh.set_radius(0.20)
	meshinstance.mesh.set_height(0.60)
	meshinstance.mesh.set_radial_segments(4)
	meshinstance.mesh.set_rings(1)
	meshinstance.set_translation(Vector3(0.0, 0.0, -0.30))
	meshinstance.set_rotation_degrees(Vector3(-90.0, 0.0, 0.0))
	meshinstance.mesh.set_material(mat_pointer_yellow)
	

func update_gun_pointer():
	gun_mount.set_rotation(camera_mount.rotation)
	if aiming_ray.is_colliding():
		var point_ = aiming_ray.get_collision_point()
		var normal_ = aiming_ray.get_collision_normal()
		target_pointer.look_at_from_position(point_, point_+normal_, Vector3(1,1,1.5))
		if !target_pointer.is_visible():
			target_pointer.show()
	else:
		if target_pointer.is_visible():
			target_pointer.hide()

func activate_aim():
	aiming_ray.set_cast_to(Vector3(0, 0, -200))
	aiming_ray.set_enabled(true)

func activate_slam_ray():
	gun_mount.set_rotation(model_mount.rotation)
	aiming_ray.set_cast_to(Vector3(0, -2, -2))
	aiming_ray.set_enabled(true)

func activate_thrust_ray():
	gun_mount.set_rotation(model_mount.rotation)
	aiming_ray.set_cast_to(Vector3(0, 0, -3))
	aiming_ray.set_enabled(true)

func deactivate_aim():
	aiming_ray.set_enabled(false)
	target_pointer.hide()

func make_rush_weapons():
	pass

# Called from manager to calculate goal arrow direction:
func get_arrow(_goal_position):
	return my_camera.to_local(_goal_position-my_camera.translation)

func setup_player_layer_mask(_ob):
	_ob.set_collision_layer(1)
	_ob.set_collision_mask(30)

func make_timers():
	regen_timer = Timer.new()
	add_child(regen_timer)
	regen_timer.connect("timeout",self,"on_regen_timer_timeout")
	regen_timer.set_wait_time(5)
	
	attacks_timer = Timer.new()
	add_child(attacks_timer)
	attacks_timer.connect("timeout",self,"on_attacks_timer_timeout")
	attacks_timer.set_wait_time(0.6)

func on_regen_timer_timeout():
	is_regenerating = true

func on_attacks_timer_timeout():
	if !can_attack:
		can_attack = true

func take_bullet_damage(damage_):
	pass

func take_explosion_damage(damage_, center):
	pass

func take_mauling_damage(damage_):
	pass

func take_edgecore_damage(damage_, direction):
	pass

#for the mobs, rush attacks damage
#func take_CC_damage(damage_, center):
#	pass
