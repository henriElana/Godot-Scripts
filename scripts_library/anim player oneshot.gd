extends Spatial

onready var player = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	player.play("flash", -1, 2, false)

func _on_AnimationPlayer_animation_finished():
	queue_free()
