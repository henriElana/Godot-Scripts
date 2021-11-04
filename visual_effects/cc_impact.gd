extends Spatial

export var lifespan = 0.1
const GROWTH_SPEED = 20
onready var impact = get_node("CCimpact")

# Called when the node enters the scene tree for the first time.
func _ready():
	impact.rotate_z(2*randf())
	yield(get_tree().create_timer(lifespan),"timeout")
	queue_free()


func _process(delta):
	impact.set_scale((1.0+GROWTH_SPEED*delta)*impact.get_scale())
