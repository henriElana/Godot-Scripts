extends Spatial

const KILL_TIMER = 0.06
var timer = 0

# Called when the node enters the scene tree for the first time.
func _ready():
#	yield(get_tree().create_timer(lifespan),"timeout")
#	queue_free()
	var angle = randf()*2
	$shard.rotate_z(angle)
	$shard2.rotate_z(angle)

func _process(delta):
	timer += delta
	if timer >= KILL_TIMER:
		queue_free()
