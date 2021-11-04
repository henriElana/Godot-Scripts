extends Spatial


# Declare member variables here. Examples:

var my_player

var game_manager

var spawn_pos_array = null

var rng = RandomNumberGenerator.new()

onready var mob =  preload("res://mobs/BaseMob.tscn")

onready var spawner =  preload("res://pickups/Gorenest.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	
	game_manager = get_parent()
	
	rng.randomize()
	
	initialize_spawners()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func set_player(player_):
	my_player = player_


func initialize_spawners():
	while spawn_pos_array == null:
		spawn_pos_array = game_manager.get_spawn_pos_array()
	
	for p_ in spawn_pos_array:
		var sp_ = spawner.instance()
		add_child(sp_)
		sp_.set_game_manager(game_manager)
		sp_.set_spawn_manager(self)
		sp_.set_translation(p_)

func random_nb_under(value_ = 0.5):
	var roll = rng.randf() < value_
	return roll

func add_mob(translation_):
	var _mob = mob.instance()
	add_child(_mob)
	_mob.set_player(my_player)
	_mob.set_game_manager(game_manager)
	_mob.set_translation(translation_)
