extends Spatial


# Declare member variables here.
onready var player = preload("res://player/Player_1.tscn")
onready var terrain_manager_script = preload("res://levels/plate_juggler.gd")
onready var light = preload("res://lights/Fog.tscn")
var terrain_manager

var goal_position = Vector3.UP*100
var goal_timer: Timer

onready var gui = $GUI

# Effecs management
onready var muzzle_flash = preload("res://visual_effects/Muzzle Flash.tscn")
onready var impact = preload("res://visual_effects/Impact.tscn")
onready var mortar_shell = preload("res://weapons/MortarShell.tscn")
onready var mortar_blast = preload("res://weapons/MortarBlast.tscn")
onready var smash_blast = preload("res://weapons/SmashBlast.tscn")

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
	player.set_translation(Vector3.UP*100.0)

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

func player_dead():
	pass

func update_energy(_value):
	gui.update_energy(_value)

func update_life(_value):
	gui.update_life(_value)

func add_muzzle_flash(_position, _direction):
	var ob_ = muzzle_flash.instance()
	add_child(ob_)
	ob_.look_at_from_position(_position, _position + _direction, Vector3.UP)
	

func add_impact(_position, _direction):
	var ob_ = impact.instance()
	add_child(ob_)
	ob_.look_at_from_position(_position, _position + _direction, Vector3.ONE)

func add_mortatblast(_position):
	var mb_ = mortar_blast.instance()
	add_child(mb_)
	mb_.set_translation(_position)

func add_smashblast(_position):
	var sb_ = smash_blast.instance()
	add_child(sb_)
	sb_.set_translation(_position)
	
func add_mortarshell(_position):
	var ms_ = mortar_shell.instance()
	add_child(ms_)
	ms_.set_translation(_position)

func add_bolt(_position, _direction):
	pass
