extends Spatial


# Declare member variables here.
onready var player = preload("res://player/Player_1.tscn")
onready var terrain_manager_script = preload("res://levels/TerrainManager1.gd")
onready var spawn_manager_script = preload("res://levels/SpawnManager1.gd")
onready var light = preload("res://lights/Fog.tscn")
var terrain_manager
var spawn_manager

var goal_position = Vector3.UP*100
var goal_timer: Timer

onready var gui = $GUI

# Effecs management
onready var muzzle_flash = preload("res://visual_effects/Muzzle Flash.tscn")
onready var impact = preload("res://visual_effects/Impact.tscn")
onready var mortar_shell = preload("res://weapons/MortarShell.tscn")
onready var mortar_blast = preload("res://weapons/MortarBlast.tscn")
onready var smash_blast = preload("res://weapons/SmashBlast.tscn")
onready var blue_blast_p = preload("res://weapons/BlueBlastP.tscn")
onready var bolt = preload("res://weapons/Bolt.tscn")
onready var bolt_yellow = preload("res://weapons/BoltYellow.tscn")
onready var explosion = preload("res://visual_effects/Explosion.tscn")
onready var trailsmoke = preload("res://visual_effects/TrailSmoke.tscn")
onready var trailsmoke_yellow = preload("res://visual_effects/TrailSmokeYellow.tscn")
onready var splatter_red = preload("res://visual_effects/SplatterRed.tscn")
onready var splatter_magenta = preload("res://visual_effects/SplatterMagenta.tscn")
onready var smoke = preload("res://visual_effects/Smoke.tscn")
onready var smashFX = preload("res://visual_effects/SmashFX.tscn")
onready var mob =  preload("res://mobs/BaseMob.tscn")
onready var pickup =  preload("res://pickups/Pickup.tscn")

var blue_blast_p_instance

var spawn_pos_array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	setup_player()
	setup_terrain_manager()
	setup_light()
	setup_goal_timer()
	init_spawns()
	setup_spawn_manager()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func setup_player():
	player = player.instance()
	add_child(player)
	player.set_translation(Vector3.UP*100.0)

func setup_terrain_manager():
	terrain_manager = Spatial.new()
	add_child(terrain_manager)
	terrain_manager.set_script(terrain_manager_script)
	terrain_manager._ready()
	terrain_manager.set_player(player)	

func setup_spawn_manager():
	spawn_manager = Spatial.new()
	add_child(spawn_manager)
	spawn_manager.set_script(spawn_manager_script)
	spawn_manager._ready()
	spawn_manager.set_player(player)	

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
#	player.set_translation(Vector3.UP*100.0)
	player.edit_health(100)
	player.edit_energy(100)

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

func add_mortarblast(_position):
	var mb_ = mortar_blast.instance()
	add_child(mb_)
	mb_.set_translation(_position)

func add_smashblast(_position, _direction):
	var sb_ = smash_blast.instance()
	add_child(sb_)
	sb_.look_at_from_position(_position, _position + _direction, Vector3.UP)
	
func add_mortarshell(_position):
	var ms_ = mortar_shell.instance()
	add_child(ms_)
	ms_.set_translation(_position)

func add_bolt(_position, _direction):
	var bt_ = bolt.instance()
	add_child(bt_)
	bt_.look_at_from_position(_position, _position + _direction, Vector3.UP)
	var ts_ = trailsmoke.instance()
	add_child(ts_)
	ts_.look_at_from_position(_position, _position + _direction, Vector3.UP)


func add_bolt_yellow(_position, _direction):
	var bt_ = bolt_yellow.instance()
	add_child(bt_)
	bt_.look_at_from_position(_position, _position + _direction, Vector3.UP)

func add_explosion(_position):
	var ob_ = explosion.instance()
	add_child(ob_)
	ob_.set_translation(_position)

func add_smoke(_position):
	var ob_ = smoke.instance()
	add_child(ob_)
	ob_.set_translation(_position)

func add_smashFX(_position):
	var ob_ = smashFX.instance()
	add_child(ob_)
	ob_.set_translation(_position)

func add_splatter_red(_position):
	var ob_ = splatter_red.instance()
	add_child(ob_)
	ob_.set_translation(_position)

func add_splatter_magenta(_position):
	var ob_ = splatter_magenta.instance()
	add_child(ob_)
	ob_.set_translation(_position)

func add_pickup(_position,_type):
	var ob_ = pickup.instance()
	add_child(ob_)
	ob_.set_translation(_position)
	match _type:
		0:
			ob_.setup_health_pickup_small()
		1:
			ob_.setup_energy_pickup_small()
		2:
			ob_.setup_health_pickup_big()
		3:
			ob_.setup_energy_pickup_big()

func acivate_blue_blast_p(_position):
	blue_blast_p_instance.activate_blast(_position)

func init_spawns():
	var default_pos = Vector3(0.0, 100.0, -10)
	var default_dir = Vector3(0, 0, -1)
	add_impact(default_pos, default_dir)
	add_muzzle_flash(default_pos, default_dir)
	add_mortarblast(default_pos)
	add_smashblast(default_pos, default_dir)
	add_mortarshell(default_pos)
	add_bolt(default_pos, default_dir)
	add_bolt_yellow(default_pos, default_dir)
	add_smoke(default_pos)
	add_splatter_red(default_pos)
	add_splatter_magenta(default_pos)
	
	blue_blast_p_instance = blue_blast_p.instance()
	add_child(blue_blast_p_instance)
	

#func spawn_mobs():
#	while true:
#		var _mob = mob.instance()
#		add_child(_mob)
#		_mob.set_player(player)
#		_mob.set_translation(Vector3.UP*102.0)
#		yield(get_tree().create_timer(5),"timeout")

func setup_spawn_pos_array(array_):
	spawn_pos_array = array_

func get_spawn_pos_array():
	return spawn_pos_array
