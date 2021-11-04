extends Area

# Declare member variables here. Examples:
var timer = 0
var has_collided = true
var has_displayed_blast = true
const DEACTIVATION_TIMER = 2
#onready var mesh = get_node("MeshInstance")
var blast_owner = null
var game_manager = null
const SMASH_DAMAGE = 30

# Called when the node enters the scene tree for the first time.
func _ready():
	CollisionManager.setup_mob_mask(self)
	set_monitorable(false)
	set_monitoring(false)

func _physics_process(delta):
	timer += delta
		
	if !has_collided:
		if timer > DEACTIVATION_TIMER:
			has_collided = true
			set_monitoring(false)
		var list_ = get_overlapping_bodies()
		if list_ != []:
			
			if !has_displayed_blast:
				game_manager.add_smashFX(to_global(translation))
				has_displayed_blast = true
			for ob in list_:
				ob.take_red_damage(SMASH_DAMAGE, translation)
			has_collided = true
			set_monitoring(false)

func activate_smash():
	set_monitoring(true)
	timer = 0.0
	has_collided = false
	has_displayed_blast = false

func set_owner(owner_):
	blast_owner = owner_

func set_manager(manager_):
	game_manager = manager_
