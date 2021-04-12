extends Spatial


# Declare member variables here.
var player = preload("res://player/Player_1.tscn")
var terrain_manager_script = preload("res://levels/plate_juggler.gd")
var light = preload("res://lights/Fog.tscn")
var terrain_manager

var goal_position = Vector3.UP*100
var goal_timer: Timer

onready var gui = $GUI

# Called when the node enters the scene tree for the first time.
func _ready():
	setup_player()
	setup_terrain()
	setup_light()
	setup_goal_timer()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func setup_player():
	player = player.instance()
	add_child(player)
	player.translate(Vector3.UP*100.0)

func setup_terrain():
	terrain_manager = Spatial.new()
	add_child(terrain_manager)
	terrain_manager.set_script(terrain_manager_script)
	terrain_manager._ready()
	terrain_manager.set_player(player)	

func setup_light():
	light = light.instance()
	add_child(light)

func set_goal(_position):
	goal_position = _position
	
func setup_goal_timer():
	goal_timer = Timer.new() 		# Create a new Timer node
	goal_timer.set_wait_time(0.2) 		# Set the wait time
	goal_timer.connect("timeout", self, "on_goal_timer_timeout")
	add_child(goal_timer)				# Add it to the node tree as the direct child
	goal_timer.start()			# Start it


func on_goal_timer_timeout():
	var _direction = player.get_arrow(goal_position)
	gui.orient_arrow(_direction)
