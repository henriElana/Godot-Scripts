extends MeshInstance

const KILL_TIMER = 0.06
var timer = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timer += delta
	if timer >= KILL_TIMER:
		queue_free()
