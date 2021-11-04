extends Spatial

const DELAY = 0.4
var ray
onready var sprite = $Sprite3D
const ROTATION_SPEED = 4

var game_manager

# Called when the node enters the scene tree for the first time.
func _ready():
	game_manager = get_parent()
	var _timer = Timer.new()
	add_child(_timer)
	_timer.connect("timeout",self,"_on_timer_timeout")
	_timer.set_wait_time(DELAY)
	_timer.start()
	
	ray = RayCast.new()
	add_child(ray)
	ray.set_translation(Vector3(0, 20, 0))
	ray.set_cast_to(Vector3(0,-60, 0))
	ray.set_collision_mask(6) # Collide with layers 2,3 : terrain+mobs
	ray.set_enabled(false)
	
	sprite.rotate_y(randf()*6)
	

func _physics_process(delta):
	sprite.rotate_y(ROTATION_SPEED*delta)

func _on_timer_timeout():
	ray.force_raycast_update()
	if ray.is_colliding():
		game_manager.add_mortarblast(ray.get_collision_point())
	queue_free()

