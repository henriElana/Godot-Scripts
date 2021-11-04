extends Spatial

export var lifespan = 0.06
onready var impact = get_node("bulletImpact")

# Called when the node enters the scene tree for the first time.
func _ready():
	impact.rotate_z(2*randf())
	yield(get_tree().create_timer(lifespan),"timeout")
	queue_free()
