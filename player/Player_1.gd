extends KinematicBody

var game_manager

# States manager
enum State {GROUNDED,AIRBORNE,SHOCK,DODGE,CLIMB,FOCUS,RUSH,SMASH_STARTUP,SMASH_COOLDOWN}
var current_state = State.GROUNDED

var directional_input := Vector3()
var last_dir_input := Vector3(0, 0, -1)
var aim_input := Vector3()
var dodge_input := Vector3()
var is_dodge_started = false
var shock_speed := Vector3()
var shock_rot_axis := Vector3()
var is_shock_started = false
var is_smash_input = false
var is_dodge_input = false
var is_shoot_input = false
var is_bolt_input = false
var is_mortar_input = false
var is_rush_input = false

#const CLOSE_COMBAT_RAY_RANGE = 2.5

#const RECOIL_SPEED = 20

var rush_start_position := Vector3()
var rush_target_position := Vector3()
var rush_distance_squared = 0.0

var current_velocity: Vector3
var h_current_velocity: Vector3
const MAX_SPEED = 10
const CLIMBING_SPEED = 10
const JUMP_SPEED = 20
const ACCELERATION = 5
const CAMERA_ACCELERATION = 6
const GRAVITY = -30
const DODGE_GRAVITY = -60
const ROTATION_SPEED = 10

var MOUSE_SENSITIVITY = 0.05


const MAX_HEALTH = 100
var current_health = 100
const MAX_ENERGY = 100
const RECOVERY_RATE = 5
var current_energy = 100
var is_regenerating = true
#const DASH_COST = -30
#const DASH_FACTOR = 2.0
var rush_timer = 0.0
const RUSH_MAX_DURATION = 2
const RUSH_COST = 10
const RUSH_SPEED = 30
const DODGE_COST = 5.0
const DODGE_SPEED = 30
const DODGE_JUMP_SPEED = 20.0
const EXPLOSION_SPEED = 10.0
#const SMASH_SPEED = 15.0
var dodge_roll_angle = 0.0
var dodge_initial_facing = Vector3.ZERO
var rollaxis = Vector3.LEFT
var regen_timer :Timer
var attacks_timer :Timer

var my_camera: Camera
var camera_mount: Spatial
var camera_localposition = Vector3(0.5, 0.5, 2.0)
var target_camera_localposition = Vector3(0.5, 0.5, 2.0)
var cam_up_offset = 0.8
var cam_down_offset = 0.4
var cam_side_offset = 0.6
var cam_forward_offset = 1.2
var cam_back_offset = 1.6
const CAMPOS_INPUT_DELTA = 0.2
const CAMPOS_AUTO_DELTA = 0.02
const CAM_UP_OFFSET_TARGET = 0.6
const CAM_BACK_OFFSET_TARGET = 1.4
var my_collisionshape: CollisionShape
const COLLIDER_RADIUS = 0.8
var v_input = 0.0
var h_input = 0.0
var trauma_x_start = 0.0 # Camera rotation
var trauma_y_start = 0.0
var trauma_x_end = 0.0 # Camera rotation
var trauma_y_end = 0.0
var trauma_x = 0.0
var trauma_y = 0.0
const TRAUMA_DAMPING_FACTOR = -0.5
const TRAUMA_SPEED = 3
var trauma_random_sign = 1.0
var trauma_fall_speed = 0.0

var my_model
var model_mount :Spatial
var model_look_at :Vector3
var model_up :Vector3
var climb_ray: RayCast
var groundcheck_ray: RayCast
var is_moving = false
var is_still_and_turning = false

# Weapons
var aiming_ray_point :Vector3
var aiming_ray_normal :Vector3
var terrain_hit = false
var is_cc_startup = false
var is_cc_cooldown = false
var has_smashed = false
var smash_weapon: Area
var smash_target_object
var smash_target_location: Vector3
const SMASH_MAX_RANGE = 30
var smash_max_range_sqrd: float
const SMASH_JUMP_RANGE = 20
var smash_jump_range_sqrd: float
const SMASH_JUMP_SPEED = 20
var current_smash_jump_speed: float
var smash_target: Sprite3D
var weapon_mount: Spatial
var gun_mount_offset = Vector3(0.0, 0.7, 0.0)
var aiming_ray: RayCast
var focus_direction: Vector3
var can_attack = true
const GUN_COOLDOWN = 0.2 # Direct attack
const MORTAR_COOLDOWN = 0.5 # Vertical attack
const BOLT_COOLDOWN = 1.0 # Direct attack
const CLOSE_COMBAT_COOLDOWN = 0.3
const SHOCK_COOLDOWN = 1.0
const BULLET_DAMAGE = 10
const BULLET_COST = 1
const MORTAR_COST = 8
const BOLT_COST = 8
const SMASH_COST = 4

# Called when the node enters the scene tree for the first time.
func _ready():
	game_manager = get_parent()
	make_camera()
	make_collision_shape()
	make_model()
	make_climb_ray()
	make_groundcheck_ray()
	make_timers()
	make_weapon()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	h_current_velocity = Vector3.ZERO


func _physics_process(delta):
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
		State.SMASH_STARTUP:
			process_smash_startup_state(delta)
		State.SMASH_COOLDOWN:
			process_smash_cooldown_state(delta)
	update_camera(delta)
	if is_regenerating:
		regenerate_energy_health(delta)


func process_input(delta):

	directional_input = Vector3()
	

	var input_movement_vector = Vector3()

	is_smash_input = false
	is_dodge_input = false
	is_shoot_input = false
	is_mortar_input = false
	is_bolt_input = false	
	is_rush_input = false
	
	if Input.is_action_pressed("ui_up"):
		input_movement_vector.z -= 1
		if target_camera_localposition.z < cam_back_offset:
			target_camera_localposition.z += CAMPOS_INPUT_DELTA
	if Input.is_action_pressed("ui_down"):
		input_movement_vector.z += 1
		if target_camera_localposition.z > cam_forward_offset:
			target_camera_localposition.z -= CAMPOS_INPUT_DELTA
	if Input.is_action_pressed("ui_left"):
		input_movement_vector.x -= 1
		if target_camera_localposition.x > -cam_side_offset:
			target_camera_localposition.x -= CAMPOS_INPUT_DELTA
	if Input.is_action_pressed("ui_right"):
		input_movement_vector.x += 1
		if target_camera_localposition.x < cam_side_offset:
			target_camera_localposition.x += CAMPOS_INPUT_DELTA
	if Input.is_action_pressed("ui_jump"):
		is_dodge_input = true
	if Input.is_action_pressed("ui_duck"):
		is_rush_input = true
	if Input.is_action_pressed("ui_lmb"):
		is_shoot_input = true
	if Input.is_action_pressed("ui_rmb"):
		is_smash_input = true
	if Input.is_action_pressed("ui_mmb"):
		is_bolt_input = true
	if Input.is_action_pressed("ui_end"):
		is_mortar_input = true

	input_movement_vector = input_movement_vector.normalized()

	var cam_xform = my_camera.get_global_transform()
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

func rotY_model_towards(delta, direction_):
	direction_.y = 0.0
	# Angle from model front to target direction ; positive -> rotate left -> positive angle.
	var model_forward = -model_mount.get_global_transform().basis.z
	var sinus = model_forward.cross(direction_).y
	var angle = model_forward.angle_to(direction_)
	# is model aligned with directional_input ?
	if angle < 0.2:
		# Orient model
		model_mount.look_at(translation + direction_, Vector3.UP)
		
	else:
		# No : rotate model. sinus > 0 --> positive rotation
		var rotation_sign = 2*int(sinus > 0)-1
		model_mount.rotate_y(rotation_sign*2*ROTATION_SPEED*delta)


func interpolate_velocity(delta):
	
	if current_velocity.y > -60:
		current_velocity.y += delta*GRAVITY
	
	h_current_velocity = current_velocity
	h_current_velocity.y = 0.0
	
	var target_velocity = directional_input*MAX_SPEED
	if current_energy > 0.0:
		if is_dodge_input:
			is_dodge_input = false
			dodge_input = directional_input
			is_dodge_started = false
			edit_energy(-DODGE_COST)
			current_state = State.DODGE
			
			my_model.play_ball()
	
	h_current_velocity = h_current_velocity.linear_interpolate(target_velocity, ACCELERATION * delta)
	current_velocity.x = h_current_velocity.x
	current_velocity.z = h_current_velocity.z
	
	current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))

func process_grounded_movement(delta):
	
	if !(is_on_floor() or groundcheck_ray.is_colliding()):
		current_state = State.AIRBORNE
		
		# Animations
		if h_current_velocity.length_squared() > 1.0:
			my_model.play_jump()
		else :
			my_model.play_airborne()
		
		is_moving = false
		is_still_and_turning = false
#	elif climb_ray.is_colliding():
#		current_state = State.CLIMB
#
#		my_model.play_wallrun()
	
	else:
		# Movement management when already moving
		if h_current_velocity.length_squared() > 4:
			interpolate_velocity(delta)
			# Orient model
			model_look_at = translation + h_current_velocity
			model_mount.look_at(model_look_at, Vector3.UP)
			
			if is_still_and_turning:
					is_still_and_turning = false
			
			if !is_moving:
				is_moving = true
				
				my_model.play_run()
			
			if (directional_input.length_squared() > 0.1) and (climb_ray.is_colliding()):
				current_state = State.CLIMB
				
				my_model.play_wallrun()
			
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
#				model_mount.look_at(translation + h_current_velocity, Vector3.UP)
				
				
				if is_still_and_turning:
					is_still_and_turning = false
#					is_moving = false
#
#					my_model.play_turn_still()
				if climb_ray.is_colliding():
					current_state = State.CLIMB
					
					my_model.play_wallrun()
			else:
				# No : rotate model. sinus > 0 --> positive rotation
				var rotation_sign = 2*int(sinus > 0)-1
				model_mount.rotate_y(rotation_sign*ROTATION_SPEED*delta)
				
				if !is_still_and_turning:
					is_still_and_turning = true
					is_moving = false
					
					my_model.play_turn_still()
				
				# But can still dodge !
				if current_energy > 0.0:
					
					if is_dodge_input:
						is_dodge_input = false
						dodge_input = directional_input
						is_dodge_started = false
						edit_energy(-DODGE_COST)
						current_state = State.DODGE
						
						my_model.play_ball()
				
		else:
			interpolate_velocity(delta)
			
			# Orient model
			model_mount.look_at(translation + last_dir_input, Vector3.UP)
			
			if is_moving:
				is_moving = false
				
				my_model.play_idle()
	
	update_weapon()


func process_airborne_movement(delta):
	
	if is_on_floor() or groundcheck_ray.is_colliding():
		current_state = State.GROUNDED
		my_model.rotation = Vector3.ZERO
		# Animations
		if directional_input.length_squared() > 0.5:
			my_model.play_run()
		else :
			my_model.play_idle()
		
		# Trauma
		set_camera_trauma(Vector3(0.0, trauma_fall_speed, 0.0))
		
	elif (directional_input.length_squared() > 0.1) and (climb_ray.is_colliding()):
		current_state = State.CLIMB
		
		my_model.play_wallrun()
	else:
		# Manage freefall
		var vertical_velocity = current_velocity.y
		if vertical_velocity > -60:
			current_velocity.y += delta*GRAVITY
		
		current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))
		
		# Trauma management
		if vertical_velocity <0.0:
			trauma_fall_speed = vertical_velocity
		else:
			trauma_fall_speed = 0.0
#		# Orient model
#		var facing_ = current_velocity
#		facing_.y = 0.0
#		if facing_.length_squared() > 0.1 :
#			model_mount.look_at(translation + facing_, Vector3.UP)
	
	update_weapon()


func process_shock_movement(delta):
		
	if !is_shock_started:
		#init shock
		can_attack = false
		attacks_timer.set_wait_time(SHOCK_COOLDOWN)
		attacks_timer.start()
		current_velocity = shock_speed
		
		is_shock_started = true
		my_model.play_ball()
		
		set_camera_trauma(shock_speed)
	
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
		
		# Animations
		if h_current_velocity.length_squared() > 1.0:
			my_model.play_jump()
		else :
			my_model.play_airborne()
	
	else :
		if directional_input.length_squared() < 0.1:
			# Orient model mount
			model_mount.look_at(translation + last_dir_input, Vector3.UP)
			
			my_model.rotation = Vector3.ZERO
			
			current_state = State.AIRBORNE
			
			# Animations
			if h_current_velocity.length_squared() > 1.0:
				my_model.play_jump()
			else :
				my_model.play_airborne()
		
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
		if dodge_input ==Vector3.ZERO:
			dodge_input = last_dir_input
		current_velocity = dodge_input*DODGE_SPEED
		current_velocity.y = DODGE_JUMP_SPEED
		dodge_roll_angle = 0.0
		rollaxis = (Vector3.UP.cross(dodge_input)).normalized()
		is_dodge_started = true
	
	
	current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))

	if current_velocity.y > -60:
		current_velocity.y += delta*DODGE_GRAVITY
		
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
		
		# Animations
		if h_current_velocity.length_squared() > 1.0:
			my_model.play_jump()
		else :
			my_model.play_airborne()


func process_focus_movement(delta):
#	print("focus in progress")
	# Angle from model front to target direction ; positive -> rotate left -> positive angle.
	var model_forward = -model_mount.get_global_transform().basis.z
#	if model_forward.y != 0.0:
#		print("model mount tilted !!")
	var sinus = model_forward.cross(focus_direction).y
	var angle = model_forward.angle_to(focus_direction)
	# is model aligned with directional_input ?
	if angle < 0.3:
		# Yes : start rush movement
		rush_timer = 0.0
		current_state = State.RUSH
		model_mount.look_at(translation + focus_direction, Vector3.UP)
#		print("switch to rush")
		
		my_model.play_jump()
		
	else:
		# No : rotate model. sinus > 0 --> positive rotation
		var rotation_sign = 2*int(sinus > 0)-1
		model_mount.rotate_y(rotation_sign*ROTATION_SPEED*delta)
		model_mount.set_transform(model_mount.get_transform().orthonormalized())
#		print("rotate")
	# But keeps moving and falling !
	if current_velocity.y > -60:
		current_velocity.y += delta*GRAVITY
		
	current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))


func process_rush_movement(delta):
	var displacement_remaining = rush_target_position - translation
	rush_timer += delta
	if rush_timer > RUSH_MAX_DURATION:
		current_velocity = current_velocity.normalized()*MAX_SPEED
		var target_facing = current_velocity
		target_facing.y = 0.0
		# Orient model
		my_model.look_at(translation + target_facing, Vector3.UP)
		current_state = State.AIRBORNE
	elif displacement_remaining.length_squared() > 1.0:
		var target_velocity = displacement_remaining.normalized()
		
		target_velocity *= RUSH_SPEED
		current_velocity = current_velocity.linear_interpolate(target_velocity, ACCELERATION * delta)
		current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))
		# Orient model
		my_model.look_at(translation + target_velocity, Vector3.UP)
	else:
		current_velocity = current_velocity.normalized()*MAX_SPEED
		var target_facing = directional_input
		target_facing.y = 0.0
		# Orient model
		if target_facing !=Vector3.ZERO:
			my_model.look_at(translation + target_facing, Vector3.UP)
		current_state = State.AIRBORNE
	
	update_weapon()


func process_smash_startup_state(delta):
	
	var displacement_remaining = smash_target_location - translation
	
	if !is_cc_startup:
#		print("hulk smash!")
		is_cc_startup = true
		has_smashed = false
		my_model.play_smash_start()
		
		var distance_left_sqrd = displacement_remaining.length_squared()
		if distance_left_sqrd < smash_jump_range_sqrd:
			current_smash_jump_speed = SMASH_JUMP_SPEED
			current_velocity.y = SMASH_JUMP_SPEED
		
		smash_target.set_translation(smash_target_location)
		smash_target.show()
		
		is_cc_cooldown = false
	
	if smash_target_object !=null:
		smash_target_location = smash_target_object.translation
	
	if displacement_remaining.length_squared() > 4.0:
		smash_target.set_translation(smash_target_location)
		var target_velocity = displacement_remaining.normalized()
		
		target_velocity *= RUSH_SPEED
		if current_smash_jump_speed > 0:
			current_smash_jump_speed += delta*GRAVITY
			current_velocity.y = current_smash_jump_speed
		current_velocity = current_velocity.linear_interpolate(target_velocity, ACCELERATION * delta)
		current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))
		# Orient model
		var smash_target_location_xz = smash_target_location
		smash_target_location_xz.y = 0.0
		if smash_target_location_xz != Vector3.ZERO:
#			look_at(smash_target_location_xz, Vector3.UP)
			my_model.look_at(smash_target_location, Vector3.UP)
			
			camera_mount.look_at(smash_target_location, Vector3.UP)
		
	else:
		
		current_state = State.SMASH_COOLDOWN


func process_smash_cooldown_state(delta):
	if !is_cc_cooldown:
		
		smash_target.hide()
		attacks_timer.set_wait_time(CLOSE_COMBAT_COOLDOWN)
		attacks_timer.start()
		smash_weapon.activate_smash()
		my_model.play_smash_end()
		is_cc_cooldown = true
		is_cc_startup = false
		
		# Orient model, before...
		var target_facing = current_velocity
		target_facing.y = 0.0
		if target_facing != Vector3.ZERO:
			my_model.look_at(translation + target_facing, Vector3.UP)
		else:
			my_model.set_rotation(Vector3.ZERO)
		camera_mount.set_rotation(Vector3.ZERO)
		
		# ...Rebound
		current_velocity = -0.5*current_velocity
		current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))
		
	
	# Manage freefall and bounce
	if current_velocity.y > -60:
		current_velocity.y += delta*GRAVITY
	current_velocity = move_and_slide(current_velocity, Vector3(0, 1, 0))
	


func _input(event):
	if current_state != State.SMASH_STARTUP:
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			v_input = deg2rad(-event.relative.y * MOUSE_SENSITIVITY)
			h_input = deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1)
			camera_mount.rotate_x(v_input)
			self.rotate_y(h_input)
			# Compensate model rotation when no input or airborne or rushing or smashing
			var compensate_rotation_ = (directional_input.length_squared() < 0.1)
			compensate_rotation_ = compensate_rotation_ or (current_state == State.AIRBORNE)
			compensate_rotation_ = compensate_rotation_ or (current_state == State.RUSH)
			compensate_rotation_ = compensate_rotation_ or (current_state == State.SMASH_STARTUP)
			compensate_rotation_ = compensate_rotation_ or (current_state == State.SMASH_COOLDOWN)
			if compensate_rotation_:
				model_mount.rotate_y(-h_input)

			var camera_rot = camera_mount.rotation_degrees
			camera_rot.x = clamp(camera_rot.x, -80, 70)
			camera_mount.rotation_degrees = camera_rot



func make_model():
	model_mount = Spatial.new()
	add_child(model_mount)
	var pkscn_  = preload("res://Animations/player_model_1.tscn")
	my_model = pkscn_.instance()
	model_mount.add_child(my_model)
	pkscn_ = preload("res://weapons/SmashBlast.tscn")
	smash_weapon = pkscn_.instance()
	camera_mount.add_child(smash_weapon)
	smash_weapon.set_translation(Vector3(0, 0, -1))
	smash_weapon.set_owner(self)
	smash_weapon.set_manager(game_manager)
	
	pkscn_ = preload("res://visual_effects/RedTarget.tscn")
	smash_target = pkscn_.instance()
	game_manager.add_child(smash_target)
	smash_target.hide()


func make_collision_shape():
	my_collisionshape = CollisionShape.new()
	add_child(my_collisionshape)
	my_collisionshape.shape = SphereShape.new()
	my_collisionshape.shape.set_radius(COLLIDER_RADIUS)
	CollisionManager.setup_player_layer_mask(self)


func make_camera():
	camera_mount = Spatial.new()
	add_child(camera_mount)
	my_camera = Camera.new()
	my_camera.far = 620
	camera_mount.add_child(my_camera)
	my_camera.set_translation(camera_localposition)


# Uses raycast, call in _physics_process
func update_camera(delta):
	# Prevent camera from staying right behind player
	if target_camera_localposition.x >= 0.0:
		if target_camera_localposition.x < COLLIDER_RADIUS:
			target_camera_localposition.x += CAMPOS_AUTO_DELTA
	else:
		if target_camera_localposition.x > -COLLIDER_RADIUS:
			target_camera_localposition.x -= CAMPOS_AUTO_DELTA
	
	# Pull camera towards default offsets
	if target_camera_localposition.y > CAM_UP_OFFSET_TARGET:
		target_camera_localposition.y -= CAMPOS_AUTO_DELTA
	else:
		target_camera_localposition.y += CAMPOS_AUTO_DELTA
	
	if target_camera_localposition.z > CAM_BACK_OFFSET_TARGET:
		target_camera_localposition.z -= CAMPOS_AUTO_DELTA
	else:
		target_camera_localposition.z += CAMPOS_AUTO_DELTA
	
	# Update camera y offset
	if v_input < -0.01:
		if target_camera_localposition.y > cam_down_offset:
			target_camera_localposition.y -= CAMPOS_INPUT_DELTA
	elif v_input > 0.01:
		if target_camera_localposition.y < cam_up_offset:
			target_camera_localposition.y += CAMPOS_INPUT_DELTA
	
	# Update camera x offset
	if h_input > 0.01:
		if target_camera_localposition.x < cam_side_offset:
			target_camera_localposition.x += CAMPOS_INPUT_DELTA
	elif h_input < -0.01:
		if target_camera_localposition.x > -cam_side_offset:
			target_camera_localposition.x -= CAMPOS_INPUT_DELTA
	
	
	# Interpolate camera local position
	camera_localposition = camera_localposition.linear_interpolate(target_camera_localposition, CAMERA_ACCELERATION * delta)
	
	# If wallcheck raycast collides, snap to position without interpolation to maybe stay out of wall
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(translation, camera_mount.to_global(camera_localposition),[self])
	if result:
		my_camera.set_translation(camera_mount.to_local(result.position))
	else:
		my_camera.set_translation(camera_localposition)
	update_camera_trauma(delta)


func set_camera_trauma(direction_):
	direction_ = 0.01*direction_
	var cam_x_axis = my_camera.get_global_transform().basis.x
	var cam_y_axis = my_camera.get_global_transform().basis.y
	trauma_x_start = direction_.dot(cam_x_axis)
	trauma_x = 0.0
	trauma_x_end = TRAUMA_DAMPING_FACTOR*trauma_x_start
	trauma_y_start = direction_.dot(cam_y_axis)
	trauma_y = 0.0
	trauma_y_end = TRAUMA_DAMPING_FACTOR*trauma_y_start
	
	# Tilt angle randomization
	trauma_random_sign *= -1

func update_camera_trauma(delta):
	var has_trauma = false
	
	if trauma_x_start != 0.0:
		has_trauma = true
		if trauma_x_start > trauma_x_end:
			trauma_x -= TRAUMA_SPEED*delta
			if trauma_x < trauma_x_end:
				trauma_x_start = trauma_x_end
				trauma_x_end = TRAUMA_DAMPING_FACTOR*trauma_x_start
				if abs(trauma_x_end) < 0.01:
					trauma_x_start = 0.0
					trauma_x_end = 0.0
					trauma_x = 0.0
		else:
			trauma_x += TRAUMA_SPEED*delta
			if trauma_x > trauma_x_end:
				trauma_x_start = trauma_x_end
				trauma_x_end = TRAUMA_DAMPING_FACTOR*trauma_x_start
				if abs(trauma_x_end) < 0.01:
					trauma_x_start = 0.0
					trauma_x_end = 0.0
					trauma_x = 0.0
	
	if trauma_y_start != 0.0:
		has_trauma = true
		if trauma_y_start > trauma_y_end:
			trauma_y -= TRAUMA_SPEED*delta
			if trauma_y < trauma_y_end:
				trauma_y_start = trauma_y_end
				trauma_y_end = TRAUMA_DAMPING_FACTOR*trauma_y_start
				if abs(trauma_y_end) < 0.01:
					trauma_y_start = 0.0
					trauma_y_end = 0.0
					trauma_y = 0.0
		else:
			trauma_y += TRAUMA_SPEED*delta
			if trauma_y > trauma_y_end:
				trauma_y_start = trauma_y_end
				trauma_y_end = TRAUMA_DAMPING_FACTOR*trauma_y_start
				if abs(trauma_y_end) < 0.01:
					trauma_y_start = 0.0
					trauma_y_end = 0.0
					trauma_y = 0.0
	
	if has_trauma:
		var tilt_ = 0.5*(trauma_random_sign*trauma_y + trauma_x)
		my_camera.set_rotation(Vector3(trauma_y, trauma_x, tilt_))


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
		current_health = 0
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
	climb_ray.set_cast_to(Vector3(0,-0.8*COLLIDER_RADIUS,-1.5*COLLIDER_RADIUS))
	climb_ray.add_exception(self)
	CollisionManager.setup_terrain_mask(climb_ray)
	climb_ray.set_enabled(true)
	

func make_groundcheck_ray():
	groundcheck_ray = RayCast.new()
	model_mount.add_child(groundcheck_ray)
	groundcheck_ray.set_cast_to(Vector3(0,-1.1*COLLIDER_RADIUS, 0.0))
	groundcheck_ray.add_exception(self)
	CollisionManager.setup_terrain_mask(groundcheck_ray)
	groundcheck_ray.set_enabled(true)


func make_weapon():
	weapon_mount = Spatial.new()
	weapon_mount.set_translation(gun_mount_offset)
	add_child(weapon_mount)
	
	aiming_ray = RayCast.new()
	my_camera.add_child(aiming_ray)
	aiming_ray.set_cast_to(Vector3(0, 0, -150))
	aiming_ray.add_exception(self)
	CollisionManager.setup_weapon_mask(aiming_ray)
	aiming_ray.set_enabled(false)
	
	# Initialize constants
	smash_max_range_sqrd = SMASH_MAX_RANGE*SMASH_MAX_RANGE
	smash_jump_range_sqrd = SMASH_JUMP_RANGE*SMASH_JUMP_RANGE
	

func update_aiming_ray():
	aiming_ray.force_raycast_update()
	if aiming_ray.is_colliding():
		aiming_ray_point = aiming_ray.get_collision_point()
		aiming_ray_normal = aiming_ray.get_collision_normal()
		aim_input = (aiming_ray.get_collision_point() - weapon_mount.get_global_transform().origin).normalized()
		terrain_hit = (aiming_ray.get_collider().get_collision_layer() == 2)
	else:
		var cam_xform = my_camera.get_global_transform()
		aim_input = -cam_xform.basis.z
		aiming_ray_point = translation + 100*aim_input
		aiming_ray_normal = -aim_input
		terrain_hit = false


func update_weapon():
		
		
	# Attack and rush management
	if current_energy > 0.0:
		if can_attack:
			if is_shoot_input:
				update_aiming_ray()
				can_attack = false
				is_shoot_input = false
				attacks_timer.set_wait_time(GUN_COOLDOWN)
				attacks_timer.start()
				var mf_pos = weapon_mount.get_global_transform().origin + aim_input
				game_manager.add_muzzle_flash(mf_pos, aim_input)
				game_manager.add_impact(aiming_ray_point, aiming_ray_normal)
				var target = aiming_ray.get_collider()
				if (target != null) and target.has_method("take_yellow_damage"):
					target.take_yellow_damage(BULLET_DAMAGE,aiming_ray_point)
				edit_energy(-BULLET_COST)
			
			
			if is_bolt_input:
				update_aiming_ray()
				can_attack = false
				is_bolt_input = false
				attacks_timer.set_wait_time(BOLT_COOLDOWN)
				attacks_timer.start()
				var bolt_muzzle_offset = 2.5*aim_input
				var mf_pos = weapon_mount.get_global_transform().origin + bolt_muzzle_offset
				game_manager.add_muzzle_flash(mf_pos, aim_input)
				game_manager.add_bolt(mf_pos,aim_input)
				edit_energy(-BOLT_COST)
			
			if is_mortar_input:
				update_aiming_ray()
				can_attack = false
				is_mortar_input = false
				attacks_timer.set_wait_time(MORTAR_COOLDOWN)
				attacks_timer.start()
				var mf_pos = weapon_mount.get_global_transform().origin + aim_input
				game_manager.add_muzzle_flash(mf_pos, aim_input + Vector3.UP)
				game_manager.add_mortarshell(aiming_ray_point + 0.1*aiming_ray_normal)
				edit_energy(-MORTAR_COST)
			
			if is_smash_input:
				update_aiming_ray()
				can_attack = false
				is_smash_input = false
				
				var target_ = aiming_ray.get_collider()
				if (target_ != null):
					# Hit something
					if target_.has_method("take_red_damage"):
						# Hit mob
						var distance_sqrd_ = (target_.translation - translation).length_squared()
						if distance_sqrd_<smash_max_range_sqrd:
							# Mob close enough
							smash_target_object = target_
							smash_target_location = target_.translation
							current_state = State.SMASH_STARTUP
							edit_energy(-SMASH_COST)
						else:
							# Mob too far
							smash_target_object = null
							can_attack = true
					else:
						# Hit terrain
						var distance_sqrd_ = (aiming_ray_point - translation).length_squared()
						if distance_sqrd_<smash_max_range_sqrd:
							# spot close enough
							smash_target_object = null
							smash_target_location = aiming_ray_point + aiming_ray_normal*COLLIDER_RADIUS*0.9
							current_state = State.SMASH_STARTUP
							edit_energy(-SMASH_COST)
						else:
							# spot too far
							smash_target_object = null
							can_attack = true
						
				else :
					can_attack = true
	
		if is_rush_input:
			var can_rush_ = (current_state != State.FOCUS) and (current_state != State.RUSH)
			if can_rush_:
				update_aiming_ray()
				is_rush_input = false
				
				if terrain_hit:
					# Offset target position by half collider radius
					rush_target_position = aiming_ray_point #+ 0.9*aiming_ray_normal*COLLIDER_RADIUS
	#					print("terrain hit")
				else:
					rush_target_position = aiming_ray_point
				
				# temporary horizontal direction needed to focus. Updated at rush start
				rush_start_position = self.translation
				focus_direction = rush_target_position - rush_start_position
				rush_distance_squared = focus_direction.length_squared()
				focus_direction.y = 0.0
				focus_direction = focus_direction.normalized()
				edit_energy(-RUSH_COST)
								
				current_state = State.FOCUS
			
				
	


# Called from manager to calculate goal arrow direction:
func get_arrow(_goal_position):
	return my_camera.to_local(_goal_position-my_camera.translation)


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
		is_shock_started = false
		# In case was shocked out of close combat sequence or dodge or...
		is_cc_startup = false
		is_cc_cooldown = false
		smash_target.hide()
		camera_mount.rotation_degrees = Vector3.ZERO
		
		is_dodge_started = false
		is_moving = false
		is_still_and_turning = false
		shock_speed = Vector3.ZERO
		current_state = State.AIRBORNE
		
		# Animations
		if h_current_velocity.length_squared() > 1.0:
			my_model.play_jump()
			model_mount.look_at(translation + h_current_velocity, Vector3.UP)
		else :
			my_model.play_airborne()
		
		# Orient model
		my_model.rotation = Vector3.ZERO
		
	if current_state == State.SMASH_COOLDOWN:
		
		is_cc_cooldown = false
		current_state = State.AIRBORNE
		
		# Animations
		my_model.play_airborne()
#
#		# Orient model
#		my_model.rotation = Vector3.ZERO
#		current_velocity.y = 0.0
#		current_velocity = -0.1*current_velocity


func take_yellow_damage(damage_, center_):
	edit_health(-damage_)
	game_manager.add_splatter_red(center_)


func take_blue_damage(damage_,center_):
	edit_health(-damage_)
	game_manager.add_splatter_red(center_)


func take_explosion_damage(damage_, center_):
	edit_health(-damage_)
	game_manager.add_splatter_red(center_)
	shock_speed += (self.translation - center_).normalized()*EXPLOSION_SPEED
	set_camera_trauma(shock_speed)
	# Gravity correction
	if shock_speed.y > 0.0:
		shock_speed.y *= 3.0
	shock_rot_axis = (Vector3.UP.cross(shock_speed)).normalized()
	is_shock_started = false
	current_state = State.SHOCK


func take_red_damage(damage_, center_):
	edit_health(-damage_)
	game_manager.add_splatter_magenta(center_)
	shock_speed += (self.translation - center_).normalized()*EXPLOSION_SPEED
	set_camera_trauma(shock_speed)
	is_shock_started = false
	shock_rot_axis = (Vector3.UP.cross(shock_speed)).normalized()
	current_state = State.SHOCK

func take_slash_damage(damage_, center_):
	edit_health(-damage_)
	game_manager.add_splatter_red(center_)
	shock_speed += (self.translation - center_).normalized()*EXPLOSION_SPEED
	set_camera_trauma(shock_speed)
	is_shock_started = false
	current_state = State.SHOCK

#for the mobs, rush attacks damage
#func take_CC_damage(damage_, center):
#	pass
func a_player_am_i():
	pass
