extends Area

# Declare member variables here. Examples:
var timer = 0
var has_collided = true
var is_hidden = false
const DEACTIVATION_TIMER = 0.2
const HIDE_TIMER = 0.06
onready var mesh = $Icosphere2div
const BLAST_DAMAGE = 20

# Called when the node enters the scene tree for the first time.
func _ready():
	CollisionManager.setup_weapon_layer_mask(self)
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
			for ob in list_:
				if ob.has_method("take_blue_damage"):
					ob.take_explosion_damage(BLAST_DAMAGE, translation)
			has_collided = true
			set_monitoring(false)

	if !is_hidden:
		if timer > HIDE_TIMER:
			mesh.hide()
			is_hidden  = true


func activate_blast(_position):
	set_translation(_position)
	timer = 0.0
	has_collided = false
	is_hidden = false
	set_monitoring(true)
	mesh.show()
	

