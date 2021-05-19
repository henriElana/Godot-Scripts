extends KinematicBody

var game_manager

# States manager
enum State {GROUNDED,AIRBORNE,SHOCK,DODGE,CLIMB,FOCUS,RUSH,SMASH}
var current_state = State.GROUNDED

var directional_input := Vector3()
var last_dir_input := Vector3(0, 0, -1)
var aim_input := Vector3()
var dodge_input := Vector3()
var is_dodge_started = false
var shock_speed := Vector3()
var shock_rot_axis := Vector3()
var is_shock_started = false
var is_jump_input = false
var is_dodge_input = false
var is_shoot_input = false
var is_mortar_input = false
var is_rush_input = false

const RUSH_COLLIDER_RADIUS = 1.5
const RUSH_SPEED = 40


var rush_start_position := Vector3()
var rush_target_position := Vector3()
var rush_distance_squared = 0.0

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
const EXPLOSION_SPEED = 10.0
const SMASH_SPEED = 15.0
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
var cam_rush_offset = Vector3.ZERO

var my_collisionshape: CollisionShape
var collider_radius = 0.8

var my_model: Spatial
var model_mount :Spatial

var climb_ray: RayCast

# Weapons
var is_aiming_gun = true
var is_processing_inputs = true
var is_rushing = false
var is_smashing = false
var weapon_mount: Spatial
var gun_mount_offset = Vector3(0.0, 0.3, 0.0)
var aiming_ray: RayCast
var target_pointer: Spatial
var pointer_mesh
var pointer_knob: Spatial
var knob_mesh
var mat_pointer_red = preload("res://materials/fx_red.material")
var mat_pointer_green = preload("res://materials/fx_green.material")
var mat_pointer_purple = preload("res://materials/fx_magenta.material")
const CLOSE_COMBAT_RANGE_SQUARED = 400.0
var is_cc_range = false
var is_critical_hit = false
var can_attack = true
const GUN_COOLDOWN = 0.2 # Direct attack
const MORTAR_COOLDOWN = 0.5 # Vertical attack
const CLOSE_COMBAT_COOLDOWN = 0.2
const SHOCK_COOLDOWN = 1.0
const BULLET_DAMAGE = 10
const MORTAR_DAMAGE = 20
const CLOSE_COMBAT_DAMAGE = 20
const BULLET_COST = 1
const MORTAR_COST = 2
const CLOSE_COMBAT_COST = 4

# Called when the node enters the scene tree for the first time.
func _ready():
	game_manager = get_parent()
	make_camera()
	make_collision_shape()
	make_model()
	make_climb_ray()
	make_timers()
	make_weapon()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):
	# No inputs processed if shocked or close combat states (focus, rush, smash)
	if is_processing_inputs:
		process_input(delta)
		
	match current_state:
		State.GROUNDED:
			process_grounded_movement(delta)
		State.AIRBORNE:
			process_airborne_movement(delta)
		State.SHOCK:
			process_shock_movement(delta)
		State.DODGE:
			process_dodge_movement(delta)
		State.CLIMB:
			process_climb_movement(delta)
		State.FOCUS:
			process_focus_movement(delta)
		State.RUSH:
			process_rush_movement(delta)
		State.SMASH:
			process_smash_state(delta)
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
		is_jump_input = false
		current_velocity.y = JUMP_SPEED
	elif current_velocity.y > -60:
		current_velocity.y += delta*GRAVITY
	
	h_current_velocity = current_velocity
	h_current_velocity.y = 0.0
	
	var target_velocity = directional_input*MAX_SPEED
	if is_dodge_input:
		is_dodge_input = false
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
	
	if !is_on_floor():
		current_state = State.AIRBORNE
	elif climb_ray.is_colliding():
		current_state = State.CLIMB
	else:
		# Movement management when already moving
		if h_current_velocity.length_squared() > 2:
			interpolate_velocity(delta)
			# Orient model
			model_mount.look_at(translation + h_current_velocity, Vector3.UP)
			
		# When still and movement input, align model with directional_input before moving
		elif directional_input.length_squared() > 0.1:
			# Angle from model front to target direction ; positive -> rotate left -> positive angle.
			var model_forward = -model_mount.get_global_transform().basis.z
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
					is_dodge_input = false
					if current_energy > 0.0:
						dodge_input = directional_input
						is_dodge_started = false
						edit_energy(DODGE_COST)
						current_state = State.DODGE
				
		else:
			interpolate_velocity(delta)
			
			# Orient model
			model_mount.look_at(translation + last_dir_input, Vector3.UP)
	
	update_weapon()


func process_airborne_movement(delta):
	
	if is_on_floor():
		current_state = State.GROUNDED
	elif (directional_input.length_squared() > 0.1) and (climb_ray.is_colliding()):
		current_state = State.CLIMB
	else:
		# Manage freefall
		if current_velocity.y > -60:
			current_velocity.y += delta*GRAVITY
		
		current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))
		
		# Orient model
		var facing_ = current_velocity
		facing_.y = 0.0
		if facing_.length_squared() > 0.1 :
			model_mount.look_at(translation + facing_, Vector3.UP)
	
	update_weapon()


func process_shock_movement(delta):
		
	if !is_shock_started:
		#init shock
		can_attack = false
		is_processing_inputs = false
		is_aiming_gun = false
		attacks_timer.set_wait_time(SHOCK_COOLDOWN)
		attacks_timer.start()
		current_velocity = shock_speed
		
		is_shock_started = true
	
	# Manage freefall and bounce
	if current_velocity.y > -60:
		current_velocity.y += delta*GRAVITY
	
	var k_col_ = move_and_collide(current_velocity*delta)
	if k_col_ != null:
		current_velocity = -current_velocity.reflect(k_col_.normal)
	
	# Rotate model
	var angle = ROTATION_SPEED*delta
	my_model.global_rotate(shock_rot_axis,angle)



func process_climb_movement(delta):
	
	if ! climb_ray.is_colliding():
		# Orient model
		model_mount.look_at(translation + last_dir_input, Vector3.UP)
		my_model.rotation = Vector3.ZERO
		
		current_state = State.AIRBORNE
	else :
		if directional_input.length_squared() < 0.1:
			# Orient model mount
			model_mount.look_at(translation + last_dir_input, Vector3.UP)
			my_model.rotation = Vector3.ZERO
			
			current_state = State.AIRBORNE
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
				my_model.look_at(translation - wall_normal, current_velocity)
				
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
	
	update_weapon()

func process_dodge_movement(delta):
	
	if !is_dodge_started:
		current_velocity = dodge_input*DODGE_SPEED
		current_velocity.y = DODGE_JUMP_SPEED
		dodge_roll_angle = 0.0
		rollaxis = (Vector3.UP.cross(dodge_input)).normalized()
		is_dodge_started = true
	
	
	current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))

	if current_velocity.y > -60:
		current_velocity.y += delta*GRAVITY
		
	# Model roll
	if dodge_roll_angle < 6:
		var angle = ROTATION_SPEED*delta
		dodge_roll_angle += angle
		my_model.global_rotate(rollaxis,angle)
	else:
		# Orient model
		my_model.rotation = Vector3.ZERO
		
		current_state = State.AIRBORNE
		is_dodge_started = false


func process_focus_movement(delta):
	print("focus in progress")
	# Angle from model front to target direction ; positive -> rotate left -> positive angle.
	var model_forward = -model_mount.get_global_transform().basis.z
	if model_forward.y != 0.0:
		print("model mount tilted !!")
	var sinus = model_forward.cross(directional_input).y
	var angle = model_forward.angle_to(directional_input)
	# is model aligned with directional_input ?
	if angle < 0.2:
		# Yes : start rush movement
		current_state = State.RUSH
		model_mount.look_at(translation + directional_input, Vector3.UP)
		print("switch to rush")
	else:
		# No : rotate model. sinus > 0 --> positive rotation
		var rotation_sign = 2*int(sinus > 0)-1
		model_mount.rotate_y(rotation_sign*ROTATION_SPEED*delta)
		model_mount.set_transform(model_mount.get_transform().orthonormalized())
		print("rotate")
	# But keeps moving and falling !
	if current_velocity.y > -60:
		current_velocity.y += delta*GRAVITY
		
	current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))


func process_rush_movement(delta):
	
	if !is_rushing:
		rush_start_position = self.translation
		directional_input = rush_target_position - rush_start_position
		# Needed for rush termination if target missed :
		rush_distance_squared = directional_input.length_squared()
		directional_input = directional_input.normalized()
		# Orient model
		my_model.look_at(translation + directional_input, Vector3.UP)
		# Orient weapon raycast
		weapon_mount.set_rotation(my_model.rotation)
		print("rush started")
		last_dir_input = directional_input
		last_dir_input.y = 0.0
		is_rushing = true
	
	if rush_distance_squared < 4.0:
		current_state = State.SMASH
		is_rushing = false
		print("too close hit now")
		
	
	var target_velocity = directional_input*RUSH_SPEED
	current_velocity = move_and_slide(target_velocity, Vector3(0, 1, 0))
	
	cam_rush_offset = rush_start_position - self.translation
	var dist_sqrd_ = cam_rush_offset.length_squared()
	if dist_sqrd_ < 0.5*rush_distance_squared:
		# Camera drags behind
		target_camera_localposition.z = cam_back_offset + cam_rush_offset.length()
		
	
	if dist_sqrd_ > 1.5*rush_distance_squared:
		current_state = State.SMASH
		is_rushing = false
		print("too far hit now")
	
	update_weapon()
	

func process_smash_state(delta):
	if !is_smashing:
		is_rushing = false
		# Camera catches up
		target_camera_localposition.z = cam_back_offset
		
		attacks_timer.set_wait_time(CLOSE_COMBAT_COOLDOWN)
		attacks_timer.start()
		# Add explosion; extra damage from raycast.
		game_manager.add_smashblast(translation + 2.5*directional_input)
		current_velocity = Vector3.ZERO
		move_and_slide(current_velocity, Vector3(0, 1, 0))
		
		print("hulk smash!")
		is_smashing = true
	
	


func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var v_input = deg2rad(-event.relative.y * MOUSE_SENSITIVITY)
		var h_input = deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1)
		camera_mount.rotate_x(v_input)
		self.rotate_y(h_input)
		# Compensate model rotation when no input or airborne or rushing
		var compensate_rotation_ = (directional_input.length_squared() < 0.1)
		compensate_rotation_ = compensate_rotation_ or (current_state == State.AIRBORNE)
		compensate_rotation_ = compensate_rotation_ or (current_state == State.RUSH)
		if compensate_rotation_:
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
	

func make_weapon():
	weapon_mount = Spatial.new()
	weapon_mount.set_translation(gun_mount_offset)
	add_child(weapon_mount)
	
	aiming_ray = RayCast.new()
	weapon_mount.add_child(aiming_ray)
	aiming_ray.set_cast_to(Vector3(0, 0, -150))
	aiming_ray.add_exception(self)
	aiming_ray.set_collision_mask(6) # Collide with layers 2,3 : terrain+mobs
	aiming_ray.set_enabled(true)
	
	# Pointer model
	target_pointer = Spatial.new()
	game_manager.add_child(target_pointer)
	var meshinstance = MeshInstance.new()
	target_pointer.add_child(meshinstance)
	meshinstance.mesh = SphereMesh.new()
	pointer_mesh = meshinstance.mesh
	meshinstance.mesh.set_radius(0.20)
	meshinstance.mesh.set_height(0.60)
	meshinstance.mesh.set_radial_segments(4)
	meshinstance.mesh.set_rings(1)
	meshinstance.set_translation(Vector3(0.0, 0.0, -0.30))
	meshinstance.set_rotation_degrees(Vector3(-90.0, 0.0, 0.0))
	meshinstance.mesh.set_material(mat_pointer_green)
	# knob model
	pointer_knob = Spatial.new()
	target_pointer.add_child(pointer_knob)
	meshinstance = MeshInstance.new()
	pointer_knob.add_child(meshinstance)
	meshinstance.mesh = SphereMesh.new()	
	knob_mesh = meshinstance.mesh
	meshinstance.mesh.set_radius(0.15)
	meshinstance.mesh.set_height(0.3)
	meshinstance.mesh.set_radial_segments(4)
	meshinstance.mesh.set_rings(1)
	meshinstance.set_translation(Vector3(0.0, 0.0, -0.50))
	meshinstance.set_rotation_degrees(Vector3(-90.0, 0.0, 0.0))
	meshinstance.mesh.set_material(mat_pointer_red)

func config_weapon_gun():
	weapon_mount.set_translation(gun_mount_offset)
	aiming_ray.set_cast_to(Vector3(0, 0, -150))
	aiming_ray.set_enabled(true)

	is_aiming_gun = true

func config_weapon_close_combat():
	weapon_mount.set_translation(Vector3.ZERO)
	var range_= collider_radius + RUSH_COLLIDER_RADIUS
	aiming_ray.set_cast_to(Vector3(0, 0, -range_))
	aiming_ray.set_enabled(true)
	
	if target_pointer.is_visible():
		target_pointer.hide()
	is_aiming_gun = false


func update_weapon():
		
	if is_aiming_gun:
		weapon_mount.set_rotation(camera_mount.rotation)
		
	if aiming_ray.is_colliding():
		var point_ = aiming_ray.get_collision_point()
		var normal_ = aiming_ray.get_collision_normal()
		
		target_pointer.look_at_from_position(point_, point_+normal_, Vector3(1,1,1.5))
		if is_aiming_gun and !target_pointer.is_visible():
			target_pointer.show()
		
		# Color code : close combat range
		var target_range_squared_ = (point_ - translation).length_squared()
		if target_range_squared_ < CLOSE_COMBAT_RANGE_SQUARED:
			if !is_cc_range:
				is_cc_range = true
				knob_mesh.set_material(mat_pointer_green)
		else:
			if is_cc_range:
				is_cc_range = false
				knob_mesh.set_material(mat_pointer_red)
		
		# Color code : critical hit angle
		var is_impact_angle_critical = aim_input.dot(-normal_) > 0.95 # Less than 30 degrees
		if is_impact_angle_critical:
			if !is_critical_hit:
				is_critical_hit = true
				pointer_mesh.set_material(mat_pointer_purple)
		else:
			if is_critical_hit:
				is_critical_hit = false
				pointer_mesh.set_material(mat_pointer_green)
		
		# Attack management
		if can_attack:
			if is_shoot_input:
				can_attack = false
				is_shoot_input = false
				attacks_timer.set_wait_time(GUN_COOLDOWN)
				attacks_timer.start()
				var mf_pos = weapon_mount.get_global_transform().origin + aim_input
				game_manager.add_muzzle_flash(mf_pos, aim_input)
				game_manager.add_impact(point_, normal_)
				var target = aiming_ray.get_collider()
				var mult_ = 1
				if is_critical_hit:
					mult_ += 1
				if target.has_method("take_bullet_damage"):
					target.take_bullet_damage(mult_*BULLET_DAMAGE)
				edit_energy(-BULLET_COST)
			
			if is_mortar_input:
				can_attack = false
				is_mortar_input = false
				attacks_timer.set_wait_time(MORTAR_COOLDOWN)
				attacks_timer.start()
				var mf_pos = weapon_mount.get_global_transform().origin + aim_input
				game_manager.add_muzzle_flash(mf_pos, aim_input + Vector3.UP)
				game_manager.add_mortarshell(point_ + 0.1*normal_)
				edit_energy(-MORTAR_COST)
			
			if is_rush_input and is_cc_range:
				can_attack = false
				is_processing_inputs = false
				is_rush_input = false
				
				var terrain_hit = (aiming_ray.get_collider().get_collision_layer() == 2)
				
				if terrain_hit:
					# Offset target position by half collider radius
					rush_target_position = point_ + 0.5*normal_*collider_radius
					print("terrain hit")
				else:
					rush_target_position = point_
				
				# temporary horizontal direction needed to focus. Updated at rush start
				rush_start_position = self.translation
				directional_input = rush_target_position - rush_start_position
				directional_input.y = 0.0
				edit_energy(-CLOSE_COMBAT_COST)
								
				current_state = State.FOCUS
				config_weapon_close_combat()
				
				
		if current_state == State.RUSH and is_rushing:
			# Target detected, apply damage, switch to smash state
			print("target found, hit target")
			current_state = State.SMASH
			is_rushing = false
			var target = aiming_ray.get_collider()
			if target.has_method("take_smashing_damage"):
				target.take_smashing_damage(CLOSE_COMBAT_DAMAGE)
	
	
	else:
		if target_pointer.is_visible():
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
	if current_state == State.SHOCK:
		is_aiming_gun = true
		is_processing_inputs = true
		
		is_shock_started = false
		# In case was shocked out of close combat sequence or dodge
		is_rushing = false
		is_smashing = false
		is_dodge_started = false
		shock_speed = Vector3.ZERO
		current_state = State.AIRBORNE
		
		# Orient model
		my_model.rotation = Vector3.ZERO
		
	if current_state == State.SMASH:
		is_processing_inputs = true
		
		is_smashing = false
		current_state = State.AIRBORNE
		
		# Orient model
		my_model.rotation = Vector3.ZERO
#		directional_input.y = 0.0
#		my_model.look_at(translation + directional_input, Vector3.UP)
		
		config_weapon_gun()

func take_bullet_damage(damage_):
	edit_health(-damage_)

func take_explosion_damage(damage_, center_):
	edit_health(-damage_)
	shock_speed += (self.translation - center_).normalized()*EXPLOSION_SPEED
	shock_rot_axis = (Vector3.UP.cross(shock_speed)).normalized()
	is_shock_started = false
	current_state = State.SHOCK
	

func take_smashing_damage(damage_, direction_):
	edit_health(-damage_)
	shock_speed += direction_.normalized()*SMASH_SPEED
	is_shock_started = false
	current_state = State.SHOCK

func take_edgecore_damage(damage_, direction_):
	edit_health(-damage_)

#for the mobs, rush attacks damage
#func take_CC_damage(damage_, center):
#	pass
