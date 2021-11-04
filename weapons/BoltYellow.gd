extends Area

const KILL_TIMER = 4
var timer = 0
const DAMAGE = 25
const SPEED = 20
const ROT_SPEED = 2
var hit_something = false
onready var my_model = $shard
var facing: Vector3

var game_manager

# Called when the node enters the scene tree for the first time.
func _ready():
	game_manager = get_parent()
	CollisionManager.setup_weapon_layer_mask(self)
	set_monitorable(false)
	connect("body_entered", self, "collided")
	facing = get_global_transform().basis.z


func _physics_process(delta):
	translate_object_local(Vector3(0.0, 0.0, -SPEED * delta))
	my_model.rotate_z(ROT_SPEED*delta)
	
	timer += delta
	if timer >= KILL_TIMER:
		game_manager.add_impact(translation, -facing)
		queue_free()


func collided(body):
	if hit_something == false:
		if body.has_method("take_yellow_damage"):
			body.take_yellow_damage(DAMAGE, translation)
		game_manager.add_impact(translation + 0.5*facing, facing)
	hit_something = true
	queue_free()
