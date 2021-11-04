extends Area

const KILL_TIMER = 4
var timer = 0
const DAMAGE = 20
const SPEED = 60
const ROT_SPEED = 2
var hit_something = false
onready var my_model = $shard

var game_manager

# Called when the node enters the scene tree for the first time.
func _ready():
	game_manager = get_parent()
	CollisionManager.setup_weapon_layer_mask(self)
	set_monitorable(false)
	connect("body_entered", self, "collided")


func _physics_process(delta):
	translate_object_local(Vector3(0.0, 0.0, -SPEED * delta))
	my_model.rotate_z(ROT_SPEED*delta)
	
	timer += delta
	if timer >= KILL_TIMER:
		queue_free()


func collided(body):
	if hit_something == false:
		if body.has_method("take_blue_damage"):
			body.take_blue_damage(DAMAGE, translation)
		game_manager.acivate_blue_blast_p(translation)
	hit_something = true
	queue_free()
