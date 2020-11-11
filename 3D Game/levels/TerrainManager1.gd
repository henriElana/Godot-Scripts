extends Spatial

# Infinite level manager, procedurally generates nine plates made up of tiles.

# Declare member variables here.
var plate_size: float
var cell_size = 16
var cell_per_plate_length = 7 # odd number ! 5 mini to see buildings (overlapping..)
var plate_roots = []

var my_player

var rng = RandomNumberGenerator.new()

var my_timer: Timer
const DELAY = 0.2

# ranom terrain probabilities
var proba_cloud_1 = 0.2
var proba_cloud_2 = 0.1
var proba_car_s = 0.2
var proba_car_b = 0.9 # ! check the code ! actual probability is 1 minus this !
var proba_house = 0.7
var proba_building = 0.3 # If not house. Else trees.

var m_grass: Material = preload("res://materials/pastel_green.material")
var m_tree: Material = preload("res://materials/shadow_green.material")
var m_cloud: Material = preload("res://materials/cloud.material")

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	
	plate_size = (cell_per_plate_length)*cell_size
	
	my_timer = Timer.new()
	add_child(my_timer)
	my_timer.set_wait_time(DELAY)
	my_timer.connect("timeout", self , "_on_Timer_timeout")
	my_timer.start()
	
	
	build_plates()


func _on_Timer_timeout():
	plates_pos_update()


func set_player(player_):
	my_player = player_


func plates_pos_update():
	if my_player != null:
		for pl in plate_roots:
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


func make_plates_roots():
	var plate_root_: Spatial
	for i in [-1, 0, 1]:
		for j in [-1, 0, 1]:
			plate_root_ = Spatial.new()
			add_child(plate_root_)
			plate_root_.set_translation(Vector3(i*plate_size, 0.0, j*plate_size))
			plate_roots.append(plate_root_)

#
#func build_plates_test_1():
#	for pl in plate_roots:
#		AaPrism.build_below(Vector3.ZERO, Vector3(plate_size, 1.0, plate_size), pl)
#
#
#
#func build_terrain_test_1():
#	for pl in plate_roots:
#		AaPrism.random_grounded(Vector3(9,3,9), Vector3(0, 2, 0),
#				 Vector3(plate_size, 4.0, plate_size), pl, AaPrism.m_gray_v70)
#
#		AaPrism.random_free_small(Vector3(9,3,9), Vector3(0, 6, 0),
#				 Vector3(plate_size, 4.0, plate_size), pl, AaPrism.m_gray_v50)


func build_plates():
	make_plates_roots()
	
	for pl in plate_roots:
		AaPrism.build_below(Vector3.ZERO, Vector3(plate_size, 1.0, plate_size),
		 pl, AaPrism.m_gray_v30)
		var min_included = int(floor(cell_per_plate_length/2))
		var max_excluded = int(ceil(cell_per_plate_length/2))
		for x in range(-min_included,max_excluded):
			for z in range(-min_included,max_excluded):
				add_clouds(x*cell_size,z*cell_size, pl)
				if ((x%4 == 0) or (z%4 == 0)):
					add_cars(x*cell_size,z*cell_size, pl)
				elif ((x%2 == 0) and (z%2 == 0)):
					add_kerb(x*cell_size,z*cell_size, pl)
					add_grass(x*cell_size,z*cell_size, pl)
					add_terrain(x*cell_size,z*cell_size, pl)


func add_clouds(x, z, parent):
	var roll = rng.randf()
	
	if roll < proba_cloud_1:
		AaPrism.random_free(Vector3(3,3,3), Vector3(x, 7*cell_size, z),
				 Vector3(2*cell_size, 2*cell_size, 2*cell_size), parent, m_cloud)
	if roll < proba_cloud_2:
		AaPrism.random_free(Vector3(3,3,3), Vector3(x, 6*cell_size, z),
				 Vector3(2*cell_size, 2*cell_size, 2*cell_size), parent, m_cloud)


func add_cars(x, z, parent):
	var roll = rng.randf()
	
	if roll < proba_car_s:
		AaPrism.random_grounded_small(Vector3(4, 1, 4), Vector3(x, 1, z),
				 Vector3(cell_size, 0.25*cell_size, cell_size), parent, AaPrism.m_gray_v10)
	if roll > proba_car_b:
		AaPrism.random_grounded_small(Vector3(4,1,4), Vector3(x, 1.5, z),
				 Vector3(cell_size, 0.38*cell_size, cell_size), parent, AaPrism.m_gray_v10)


func add_kerb(x, z, parent):
	AaPrism.build_above( Vector3(x, 0, z),
			 Vector3(3*cell_size, 0.025*cell_size, 3*cell_size), parent, AaPrism.m_gray_v70)


func add_grass(x, z, parent):
	AaPrism.build_above( Vector3(x, 0, z),
			 Vector3(2.49*cell_size, 0.038*cell_size, 2.49*cell_size), parent, m_grass)


func add_house(x, z, parent):
	AaPrism.random_grounded(Vector3(1, 2, 1), Vector3(x, 1.5*cell_size, z),
			 Vector3(2.5*cell_size, 3*cell_size, 2.5*cell_size), parent, AaPrism.m_gray_v50)
	AaPrism.random_grounded(Vector3(2, 1, 2), Vector3(x, 1.5*cell_size, z),
			 Vector3(2.5*cell_size, 3*cell_size, 2.5*cell_size), parent, AaPrism.m_gray_v50)


func add_trees(x, z, parent):
	for i in rng.randi_range(2,6):
		AaPrism.random_grounded_small(Vector3(7, 2, 7), Vector3(x, 0.5*cell_size, z),
			 Vector3(2.5*cell_size, cell_size, 2.5*cell_size), parent, m_tree)


func add_building(x, z, parent):
	AaPrism.build_above( Vector3(x, 0, z),
			 Vector3(1.8*cell_size, 6.1*cell_size, 1.8*cell_size), parent, AaPrism.m_gray_v10)
	for i in rng.randi_range(2,6):
		AaPrism.random_free_small(Vector3(1, 5, 1), Vector3(x, 3*cell_size, z),
			 Vector3(2.5*cell_size, 6*cell_size, 2.5*cell_size), parent, AaPrism.m_gray_v10)


# Pick among house, trees, building
func add_terrain(x, z, parent):
	var roll = rng.randf()
	
	if roll < proba_house:
		add_house(x, z, parent)
	else:
		roll = rng.randf()
		if roll < proba_building:
			add_building(x, z, parent)
		else:
			add_trees(x, z, parent)
