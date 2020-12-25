extends Spatial


# Declare member variables here.
var player = preload("res://player/Drone.tscn")
var terrain_manager_script = preload("res://levels/plate_juggler.gd")
var light = preload("res://lights/Fog.tscn")
var terrain_manager


# Called when the node enters the scene tree for the first time.
func _ready():
	player = player.instance()
	add_child(player)
	player.translate(Vector3.UP*10.0)
	terrain_manager = Spatial.new()
	add_child(terrain_manager)
	terrain_manager.set_script(terrain_manager_script)
	terrain_manager._ready()
	terrain_manager.set_player(player)
	light = light.instance()
	add_child(light)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
