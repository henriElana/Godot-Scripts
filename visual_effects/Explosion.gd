extends Particles


# Declare member variables here. Examples:
const DELAY = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	set_emitting(true)
	
	var _timer = Timer.new()
	add_child(_timer)
	_timer.connect("timeout",self,"_on_timer_timeout")
	_timer.set_wait_time(DELAY)
	_timer.start()
	


func _on_timer_timeout():
	queue_free()

