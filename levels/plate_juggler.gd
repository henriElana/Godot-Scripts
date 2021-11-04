extends Spatial

# Infinite level manager, uses prebuilt plates

# Declare member variables here.
var plate_size = 640 # !!!  See plate name for size !!!!!!!!!!!!!!!!!!!!! update path !!!
export var plates = [] # Uses nine plates ! array of PackedScenes
var plates_path = "res://plates/plate_a_size624_nb_"	# Plates path without number !! update size in plate_size !!!

var my_player

var rng = RandomNumberGenerator.new()

var my_timer: Timer
const DELAY = 0.2

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	randomize()
	my_timer = Timer.new()
	add_child(my_timer)
	my_timer.set_wait_time(DELAY)
	my_timer.connect("timeout", self , "_on_Timer_timeout")
	my_timer.start()
	build_plates_array()
	setup_plates()


func _on_Timer_timeout():
	plates_pos_update()


func set_player(player_):
	my_player = player_


func plates_pos_update():
	if my_player != null:
		for pl in plates:
			var plate_to_player_ = my_player.translation - pl.translation
			if plate_to_player_.x > 1.5*plate_size :
				pl.translation.x += 3*plate_size
				pl.rotate_y(deg2rad(90))
			if plate_to_player_.x < -1.5*plate_size :
				pl.translation.x -= 3*plate_size
				pl.rotate_y(deg2rad(90))
			if plate_to_player_.z > 1.5*plate_size :
				pl.translation.z += 3*plate_size
				pl.rotate_y(deg2rad(90))
			if plate_to_player_.z < -1.5*plate_size :
				pl.translation.z -= 3*plate_size
				pl.rotate_y(deg2rad(90))
	else:
		print('error : no player to follow !')

func build_plates_array():
	# Try to fecth nine prebuilt plates
	for i in range(9):
		var path = plates_path + str(i) + ".scn"
		var pl = load(path)
		if pl != null:
			pl = pl.instance()
			add_child(pl)
			plates.append(pl)
	
	if plates.size() == 0:
		print("empty array !")
	
	# Not enough plates ? not a problem, fill array with random duplicates.
	while plates.size() < 9:
		plates.shuffle()
		plates.append(plates[0])
	
	plates.shuffle()

func setup_plates():
	
	# Position plates
	var plate_index = 0
	for i in [-1, 0, 1]:
		for j in [-1, 0, 1]:
			var pl = plates[plate_index]
			pl.set_translation(Vector3(i*plate_size, 0.0, j*plate_size))
			pl.rotate_y(deg2rad(90*rng.randi_range(0,3)))
			plate_index += 1
