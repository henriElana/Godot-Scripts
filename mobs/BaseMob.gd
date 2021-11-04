extends KinematicBody

var game_manager
# States manager
enum Mood {SHOOTER, SLASHER}
var current_mood = Mood.SHOOTER
enum Movement {SEEK, CIRCLE_IN, CIRCLE_OUT, RUSH, POUNCE, SHOCK}
var current_mvt = Movement.SEEK

const LIFETIME = 100
var life_timer = 0.0

export var MAX_HEALTH = 14
var current_health = 14

var player_direction := Vector3()
var player_direction_xz := Vector3()

var current_velocity = Vector3.ZERO
#var previous_velocity = Vector3.ZERO
var current_root_facing_xz = Vector3.ZERO
var current_root_facing = Vector3.ZERO
export var MAX_SPEED = 10
const CLIMBING_SPEED = 10
export var ACCELERATION = 2
export var ROTATION_SPEED = 2
export var QUAT_ROT_SPEED = 5.0
const GRAVITY = -30

var my_model: CollisionShape
var my_head: Spatial
var CENTER_TO_NECK = 0.0
var my_shield: MeshInstance
var my_visibility_notifier: VisibilityNotifier
var is_visible = false
var player_visible = false

var target_model_rotation := Quat()
export var BANKING_ANGLE = 0.7

var player
var wallcheck_ray

const UPDATE_DELAY = 0.1
var update_timer = 0.0

var dir_rot_angle = 0.0
var rot_update_delay = 2.0
var rot_update_timer = 0.0
var rot_sign = 1.0

var my_gun = preload("res://weapons/Gun.tscn")
var is_shooting = false
var gun_reset_rotation = Vector3(-45, 0, 0)
var target_head_look_at = Vector3.ZERO
var target_gun_look_at = Vector3.ZERO
var gun_look_at = Vector3.ZERO
var head_look_at = Vector3.ZERO
const SHOOTING_RANGE = 100
var shooting_range_sqrd: float
const SHOOTING_MIN_DISTANCE = 8
var shooting_mindist_sqrd: float

var square_dist_to_player: float

var is_shock_started = false
var shock_timer = 0.0
const SHOCK_DURATION = 2.0
var shock_rot_axis: Vector3
const SHOCK_ROT_SPEED = 10
const EXPLOSION_SPEED = 20
var shock_speed = Vector3.ZERO

var my_blade = preload("res://weapons/MobCloseCombatWeapon.tscn")
const CC_RANGE = 10
var cc_range_sqrd: float
export var RUSH_ROT_SPEED = 1
export var RUSH_SPEED = 20
export var RUSH_ACCELERATION = 2
export var RUSH_DURATION = 1
var rush_timer = 0.0
var is_rushing = false

var has_shield = false
enum Sc {red, yellow, green, cyan, blue, magenta}
var shield_color = Sc.yellow
var m_red: Material = preload("res://materials/fx_red.material")
var m_cyan: Material = preload("res://materials/fx_cyan.material")
var m_yellow: Material = preload("res://materials/fx_yellow.material")



# Called when the node enters the scene tree for the first time.
func _ready():
	
	my_head = $CollisionShape/Head
	my_model = $CollisionShape
	CENTER_TO_NECK = my_model.get_shape().get_extents().y -0.3 # Head heigth 30 cm
	my_shield = $CollisionShape/Shield
	my_visibility_notifier = $VisibilityNotifier
	CollisionManager.setup_mob_layer_mask(self)
	make_wallcheck_ray()
	

func choose_weapons():
	if randf()<0.5:
		current_mood = Mood.SLASHER
		setup_cc()
	else:
		setup_gun()
	
	if randf() < 0.2:
		has_shield = true
		my_shield.show()
		var toss_ = randf()
		if toss_ < 0.33:
			shield_color = Sc.red
			my_shield.set_surface_material(1,m_red)
		elif toss_ < 0.66:
			shield_color = Sc.yellow
			my_shield.set_surface_material(1,m_yellow)
		else:
			shield_color = Sc.blue
			my_shield.set_surface_material(1,m_cyan)
	else:
		my_shield.hide()
	var srx_ = 2*(randi()%2)-1
	var sry_ = 2*(randi()%2)-1
	var srz_ = 2*(randi()%2)-1
	shock_rot_axis = Vector3(srx_, sry_, srz_).normalized()


func _physics_process(delta):
	# Lazy update management
	update_timer += delta
	
	if update_timer >= UPDATE_DELAY:
		update_input(delta)
		update_timer = 0.0
	
	life_timer += delta
	
	if life_timer > LIFETIME:
		must_die()
	
	
	match current_mvt:
		Movement.SEEK:
			process_seek_movement(delta)
		Movement.CIRCLE_IN:
			process_circle_in_movement(delta)
		Movement.CIRCLE_OUT:
			process_circle_out_movement(delta)
		Movement.POUNCE:
			process_pounce_movement(delta)
		Movement.RUSH:
			process_rush_movement(delta)
		Movement.SHOCK:
			process_shock_movement(delta)
	
	if is_shooting:
		update_gun(delta)
	
	if player_visible:
		update_head(delta)
	

func update_input(delta):
	my_model.transform.basis = my_model.transform.basis.orthonormalized()
	# Check is mob is roughly visible by  player
	if my_visibility_notifier.is_on_screen():
		if !is_visible:
			is_visible = true
	else:
		if is_visible:
			is_visible = false
	var player_pos_ = player.get_translation()
	
	player_direction = (player_pos_ - translation)
	square_dist_to_player = player_direction.length_squared()
	target_head_look_at = player_direction + my_head.translation
	if current_mood == Mood.SHOOTER:
		target_gun_look_at = player_direction + my_gun.translation
	
	# Normalize for cosine projections
	player_direction = player_direction.normalized()
	var cosinus = -get_global_transform().basis.z.dot(player_direction)
	
	# Project in xz plane and normalize for movement.
	player_direction_xz = player_direction
	player_direction_xz.y = 0.0
	player_direction_xz = player_direction_xz.normalized()
	
	if (current_mood == Mood.SHOOTER) and (square_dist_to_player < shooting_mindist_sqrd):
		current_mvt = Movement.CIRCLE_OUT
	
		
	if cosinus > 0.2: #176 degrees view angle
		# Cast ray from above mob to player
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(translation + 1.5*my_head.translation, player_pos_,[self],3)
		if result:
			if result.collider.has_method("a_player_am_i"):
				if !player_visible:
					player_visible = true
			else:
				if player_visible:
					player_visible = false
					reset_head()
		else:
			if player_visible:
				player_visible = false
				reset_head()
		
	if cosinus > 0.5: #90 degrees view angle
		var start_shooting = (current_mood == Mood.SHOOTER) and player_visible and (square_dist_to_player < shooting_range_sqrd)
		if start_shooting:
			if !is_shooting:
				my_gun.activate_gun()
				is_shooting = true
				current_mvt = Movement.CIRCLE_IN
		else:
			if is_shooting:
				my_gun.deactivate_gun()
				is_shooting = false
				reset_gun()
		var start_rush = (current_mood == Mood.SLASHER) and player_visible and (square_dist_to_player < cc_range_sqrd)
		if start_rush:
			if !is_rushing:
				current_mvt = Movement.RUSH
		
	else:
		if is_shooting:
			my_gun.deactivate_gun()
			is_shooting = false
			reset_gun()
			current_mvt = Movement.SEEK
	


func orient_model(delta):
	target_model_rotation = Quat.IDENTITY
	if current_velocity.dot(current_root_facing_xz) > 0.0:
		target_model_rotation *= Quat(Vector3.LEFT, BANKING_ANGLE)
	else:
		target_model_rotation *= Quat(Vector3.LEFT, -BANKING_ANGLE)
	
	var crossprod_ = current_velocity.cross(current_root_facing_xz).y
	if crossprod_ > 0.1:
		target_model_rotation *= Quat(Vector3.BACK, -BANKING_ANGLE)
	if crossprod_ < -0.1:
		target_model_rotation *= Quat(Vector3.BACK, +BANKING_ANGLE)
	
	var model_rotation = Quat(my_model.transform.basis)
	model_rotation = model_rotation.slerp(target_model_rotation, QUAT_ROT_SPEED * delta)
	my_model.transform.basis = Basis(model_rotation)
	
	
	if current_mvt == Movement.RUSH:
		var target_root_facing = player_direction
		current_root_facing = current_root_facing.linear_interpolate(target_root_facing,RUSH_ROT_SPEED*delta)
		if current_root_facing != Vector3.ZERO:
			look_at(translation + current_root_facing, Vector3.UP)
	else:
		current_root_facing_xz = current_root_facing_xz.linear_interpolate(player_direction_xz,ROTATION_SPEED*delta)
		if current_root_facing_xz != Vector3.ZERO:
			look_at(translation + current_root_facing_xz, Vector3.UP)

func process_movement(delta):
	
#	previous_velocity = current_velocity
	# Must climb ?
#	wallcheck_ray.force_raycast_update()
	if wallcheck_ray.is_colliding():
		current_velocity.y = CLIMBING_SPEED
	else:
		if current_velocity.y > -30:
			current_velocity.y += delta*GRAVITY
	
	update_dir_rot_angle(delta)
	var target_velocity = player_direction_xz.rotated(Vector3.UP,dir_rot_angle)*MAX_SPEED
	target_velocity.y = current_velocity.y
	current_velocity = current_velocity.linear_interpolate(target_velocity, ACCELERATION * delta)
	
	move_and_slide(current_velocity, Vector3(0, 1, 0))
	# Orient model
	orient_model(delta)

func process_seek_movement(delta):
	process_movement(delta)


func process_circle_in_movement(delta):
	process_movement(delta)


func process_circle_out_movement(delta):
	process_movement(delta)


func process_rush_movement(delta):
	if !is_rushing:
		my_blade.activate_ccw()
		is_rushing = true
		current_velocity = Vector3.ZERO
		look_at(translation + player_direction, Vector3.UP)
	
	rush_timer += delta
	if rush_timer < RUSH_DURATION:
		if current_velocity.y > -30:
			current_velocity.y += delta*GRAVITY
		var target_velocity = player_direction*RUSH_SPEED
		target_velocity.y = current_velocity.y
		current_velocity = current_velocity.linear_interpolate(target_velocity, RUSH_ACCELERATION * delta)
		
		move_and_slide(current_velocity, Vector3(0, 1, 0))
		# Orient model
		orient_model(delta)
	else:
		current_mvt = Movement.CIRCLE_IN
		is_rushing = false
		rush_timer = 0.0
		var current_velocity_xz = current_velocity
		current_velocity_xz.y = .00
		look_at(translation + current_velocity_xz, Vector3.UP)
	
func process_pounce_movement(delta):
	pass


func process_shock_movement(delta):
		
	if !is_shock_started:
		#init shock
		shock_timer = 0.0
		current_velocity = shock_speed
		
		is_shock_started = true
		
		
		if current_mood == Mood.SHOOTER:
			my_gun.deactivate_gun()
			is_shooting = false
			reset_gun()
	
	shock_timer += delta
	if shock_timer > SHOCK_DURATION:
		if current_health <= 0.0:
			must_die()
		else:
			my_model.set_rotation(Vector3.ZERO)
			my_model.transform = my_model.transform.orthonormalized()
			is_shock_started = false
			current_mvt = Movement.SEEK
	
	# Manage freefall and bounce
	if current_velocity.y > -60:
		current_velocity.y += 2*delta*GRAVITY
	
	var k_col_ = move_and_collide(current_velocity*delta)
	if k_col_ != null:
		current_velocity = -current_velocity.reflect(k_col_.normal)
		current_velocity.y *= 0.5
		shock_rot_axis *= -1
	
	# Rotate model
	var angle = SHOCK_ROT_SPEED*delta
	my_model.global_rotate(shock_rot_axis,angle)

func update_dir_rot_angle(delta):
	rot_update_timer += delta
	if rot_update_timer > rot_update_delay:
		rot_sign *= -1
		var value_ = 0.0
		match current_mvt:
			Movement.SEEK:
				value_ = deg2rad(15)
			Movement.CIRCLE_IN:
				value_ = deg2rad(70)
			Movement.CIRCLE_OUT:
				value_ = deg2rad(110)
		dir_rot_angle = rot_sign * value_
		rot_update_timer = 0.0
		rot_update_delay = randi()%3 + 1

func set_player(_player):
	player = _player

func make_wallcheck_ray():
	wallcheck_ray = RayCast.new()
	add_child(wallcheck_ray)
	wallcheck_ray.add_exception(self)
	CollisionManager.setup_terrain_mask(wallcheck_ray)
	var collider_halfheight_margin = 0.5*my_model.shape.get_extents().y-0.1
	var collider_radius_margin = 5*my_model.shape.get_extents().z
	wallcheck_ray.set_cast_to(Vector3(0.0 , -collider_halfheight_margin , -collider_radius_margin))
	wallcheck_ray.set_enabled(true)


func take_yellow_damage(damage_, center_):
	if has_shield and shield_color == Sc.yellow:
		pass
	else:
		if check_headshot(center_):
			edit_health(-2*damage_)
			game_manager.add_splatter_magenta(center_)
			var toss_ = randf()
			if toss_ < 0.1:
				game_manager.add_pickup(translation,2)
			elif toss_ <0.2:
				game_manager.add_pickup(translation,0)
		else:
			edit_health(-damage_)
			game_manager.add_splatter_red(center_)
			var toss_ = randf()
			if toss_ < 0.1:
				game_manager.add_pickup(translation,3)
			elif toss_ <0.5:
				game_manager.add_pickup(translation,1)


func take_blue_damage(damage_, center_):
	if has_shield and shield_color == Sc.blue:
		pass
	else:
		edit_health(-damage_)


func take_explosion_damage(damage_, center_):
	if has_shield and shield_color == Sc.blue:
		pass
	else:
		current_health += -damage_
		
		shock_speed += (self.translation - center_).normalized()*EXPLOSION_SPEED
		# Gravity correction
		shock_speed.y += 20.0
		is_shock_started = false
		current_mvt = Movement.SHOCK

func take_red_damage(damage_, center_):
	if has_shield and shield_color == Sc.red:
		pass
	else:
		current_health += -damage_
		var toss_ = randf()
		if toss_ < 0.1:
			game_manager.add_pickup(translation,2)
		elif toss_ <0.5:
			game_manager.add_pickup(translation,0)
		
		shock_speed += (self.translation - center_).normalized()*EXPLOSION_SPEED
		# Gravity correction
		is_shock_started = false
		current_mvt = Movement.SHOCK


func edit_health(_value):
	current_health += _value
	# Add hurt FX
	if current_health <= 0:
		must_die()

func must_die():
	game_manager.add_smoke(translation)
	queue_free()


func setup_gun():
	my_gun = my_gun.instance()
	add_child(my_gun)
	my_gun.set_translation($WeaponRightPos.translation)
	my_gun.set_manager(game_manager)
	shooting_range_sqrd = SHOOTING_RANGE*SHOOTING_RANGE
	shooting_mindist_sqrd = SHOOTING_MIN_DISTANCE*SHOOTING_MIN_DISTANCE

func setup_cc():
	my_blade = my_blade.instance()
	add_child(my_blade)
	my_blade.set_manager(game_manager)
	my_blade.set_owner(self)
	cc_range_sqrd = CC_RANGE*CC_RANGE
	my_blade.set_activation_time(RUSH_DURATION)

func update_head(delta):
	head_look_at = translation + target_head_look_at
	my_head.look_at(head_look_at, Vector3.UP)

func update_gun(delta):
	gun_look_at = translation + target_gun_look_at
	my_gun.look_at(gun_look_at, Vector3.UP)
	
func reset_head():
	my_head.set_rotation(Vector3.ZERO)

func reset_gun():
	my_gun.set_rotation_degrees(gun_reset_rotation)

func check_headshot(_position):
	var center_to_impact_vector_ = _position - translation
	var projection_ = my_model.get_global_transform().basis.y.dot(center_to_impact_vector_)
	return projection_ > CENTER_TO_NECK	


func set_game_manager(manager_):
	game_manager = manager_
	choose_weapons()
