extends Area

# Declare member variables here. Examples:

var timer = 0
var has_collided = false
var is_hidden = false
onready var mesh = $Icosphere2div

var force_update_by_moving = Vector3(0, 0, 0.01)

const KILL_TIMER = 0.2
const HIDE_TIMER = 0.06
const EXPLOSION_DAMAGE = 15

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set weapon collision layer
	CollisionManager.setup_weapon_layer_mask(self)
	set_monitoring(true)
	set_monitorable(false)


func _physics_process(delta):
	if !has_collided:
#		force_update_by_moving *=-1
#		translate(force_update_by_moving)
		var list_ = get_overlapping_bodies()
		if list_ != []:
			print("mortarhit")
			for ob in list_:
				print(ob.name)
				if ob.has_method("take_explosion_damage"):
					ob.take_explosion_damage(EXPLOSION_DAMAGE, translation)
					print("damage dealt")
			has_collided = true
			set_monitoring(false)
	timer += delta
	if timer >= KILL_TIMER:
		queue_free()
	
	if !is_hidden:
		if timer > HIDE_TIMER:
			mesh.hide()
			is_hidden  = true
#func _on_timer_timeout():
#	queue_free()

