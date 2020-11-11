extends Spatial


# Declare member variables here.
var player = preload("res://player/Drone.tscn")
var terrain_manager_script = preload("res://levels/plate_juggler.gd")
var terrain_manager


# Called when the node enters the scene tree for the first time.
func _ready():
	player = player.instance()
	add_child(player)
	terrain_manager = Spatial.new()
	add_child(terrain_manager)
	terrain_manager.set_script(terrain_manager_script)
	terrain_manager._ready()
	terrain_manager.set_player(player)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
