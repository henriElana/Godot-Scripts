extends Spatial


# Declare member variables here.
var damage = 100

var arm_length = 1.0
var core_position := Vector3()
var core_max_forward_offset = 4.0
var core_min_forward_offset = 1.5
var core_current_offset

var model_growth_speed = 5
var model_shrink_speed = 10

var cut_speed = 10
var cut_progress = 0.0 # From 0.0 to PI

enum {IS_IDLE, IS_GROWING, IS_CUTTING, IS_SHRINKING, IS_BOUNCING}
var current_state

onready var arm = get_node("Arm")
onready var sword = get_node("Arm/Sword")
onready var sword_model = get_node("Arm/Sword/SwordModel")
onready var sword_hitbox = get_node("Arm/Sword/SwordHitbox")


# Called when the node enters the scene tree for the first time.
func _ready():
	current_state = IS_IDLE
	sword_model.scale = Vector3.ZERO
	sword_model.set_visible(false)
	sword_hitbox.monitoring = false
	sword_hitbox.monitorable = false
	sword.set_translation(Vector3(0.0, arm_length, 0.0))
	


func _physics_process(delta):
	process_movement(delta)

func process_movement(delta):
	match current_state:
		IS_IDLE:
			pass
			
		IS_GROWING:
			# Sword must be set visible, and cut progress to 0.0 !
			if sword_model.scale.x <1:
				sword_model.scale += model_growth_speed*delta*Vector3.ONE
			else:
				sword_model.scale = Vector3.ONE
				sword_hitbox.monitoring = true
				sword_hitbox.monitorable = true
				current_state = IS_CUTTING
			
		IS_CUTTING:
			if cut_progress < PI:
				cut_progress += cut_speed*delta
				arm.set_rotation(Vector3(-cut_progress, 0.0, 0.0))
				sword.set_rotation(Vector3(-0.7*cut_progress, 0.0, 0.0))
				self.set_translation(Vector3(0.0, 0.0, 
						-core_current_offset*sin(cut_progress)))
			else:
				current_state = IS_SHRINKING
				
		IS_SHRINKING:
			if sword_model.scale.x > 0.05:
				sword_model.scale -= model_shrink_speed*delta*Vector3.ONE
			else:
				sword_model.scale = Vector3.ZERO
				sword_model.set_visible(false)
				sword_hitbox.monitoring = false
				sword_hitbox.monitorable = false
				current_state = IS_IDLE
				
		IS_BOUNCING:
			if cut_progress > 0.0:
				cut_progress -= cut_speed*delta
				arm.set_rotation(Vector3(-cut_progress, 0.0, 0.0))
				sword.set_rotation(Vector3(-cut_progress, 0.0, 0.0))
			else:
				current_state = IS_SHRINKING

func start_cut(angle = 0.0):
	if current_state == IS_IDLE:
		if abs(angle) > 0.9*PI:
			# Move back --> vertical long range cut
			angle = 0.0
			core_current_offset = core_max_forward_offset
		elif abs(angle) > 0.51*PI:
			# Move back and to the side : angle = +-135 degrees. halve to cut from above.
			angle *= 0.5
			core_current_offset = core_max_forward_offset
		else:
			# Moving forward or to the sides, keep angle, normal range cut
			core_current_offset = core_min_forward_offset
		
		self.set_rotation(Vector3(0.0, 0.0, angle))
		cut_progress = 0.0
		arm.set_rotation(Vector3.ZERO)
		sword.set_rotation(Vector3.ZERO)
		sword_model.set_visible(true)
		current_state = IS_GROWING
		

func _on_SwordHitbox_body_entered(body):
	if current_state == IS_CUTTING:
		current_state = IS_BOUNCING
		sword_hitbox.monitoring = false
		sword_hitbox.monitorable = false
	if body.has_method("take_hit"):
		var push_ = body.translation() - to_global(sword_model.translation())
		body.take_hit(damage, push_)

func set_damage(dam):
	damage = dam
