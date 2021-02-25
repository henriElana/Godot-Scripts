extends Particles


# Declare member variables here. Examples:
var delay = 1.0


# Called when the node enters the scene tree for the first time.
func _ready():
	set_emitting(true)
	yield(get_tree().create_timer(delay), "timeout")
	queue_free()


