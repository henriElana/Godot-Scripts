extends Spatial

# Declare member variables here.
var plate_size: float
var cell_size = 16
var cell_per_plate_length = 39 # 4*n-1
var plate = Spatial.new()

var plate_filename_base = "plate_a_size"
var plate_number = 0

var node_count = 0

var rng = RandomNumberGenerator.new()

# random terrain probabilities
var proba_cloud = 0.1
var proba_roadblock = 0.2
var proba_building = 0.5
var proba_tower_if_not_building = 0.3
var proba_zeroG = 0.2
var proba_pivot = 0.7

var m_cloud: Material = preload("res://materials/cloud.material")
var m_plate: Material = preload("res://materials/gray_v30.material")
var m_tower: Material = preload("res://materials/gray_v10.material")
var m_building1: Material = preload("res://materials/gray_v50.material")
var m_building2: Material = preload("res://materials/gray_v60.material")
var m_building3: Material = preload("res://materials/gray_v70.material")
var m_building4: Material = preload("res://materials/gray_v80.material")
var m_building5: Material = preload("res://materials/gray_v90.material")

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	
	plate_size = (cell_per_plate_length)*cell_size
		
	for i in range(9):
		plate_number = i
		node_count = 0
		build_plate()
	get_tree().quit()

func coin_toss():
	var toss = rng.randf() < 0.5
	return toss

func build_plate():
	
	AaPrism.build_below(Vector3.ZERO, Vector3(plate_size, 1.0, plate_size),
	 plate, m_plate)
	var min_included = int(floor(cell_per_plate_length/2))
	var max_excluded = int(ceil(cell_per_plate_length/2))
	for x in range(-min_included,max_excluded):
		for z in range(-min_included,max_excluded):
			add_clouds(x*cell_size,z*cell_size, plate)
			if not (x==0 and z==0):
				if ((x%4 == 0) or (z%4 == 0)):
					if ((x%8 == 0) and (z%8 == 0)):
						add_pivot(x*cell_size,z*cell_size, plate)
					elif x==z:
						add_pivot(x*cell_size,z*cell_size, plate)
					else:
						add_roadblocks(x*cell_size,z*cell_size, plate)
				elif ((x%2 == 0) and (z%2 == 0)):
					add_terrain(x*cell_size,z*cell_size, plate)
	
	own_children_recursive(plate, plate)
	
	# Configure file name
	var save_path = "res://plates/" + plate_filename_base + str(plate_size) + "_nb_" + str(plate_number) + ".scn"
	
	var scene = PackedScene.new()
	var result = scene.pack(plate)
	if result == OK:
		var error = ResourceSaver.save(save_path, scene)  # Or "user://..."
		if error != OK:
			push_error("An error occurred while saving the scene to disk.")
	
	# Clear plate before iteration !!
	terminate_children(plate)
	

func add_clouds(x, z, parent):
	var roll = rng.randf()
	var heigth = rng.randi_range(4,7)
	
	if roll < proba_cloud:
		AaPrism.random_free(Vector3(3,3,3), Vector3(x, heigth*cell_size, z),
				 Vector3(2*cell_size, 2*cell_size, 2*cell_size), parent, m_cloud)
	if roll < 0.5*proba_cloud:
		AaPrism.random_free(Vector3(3,3,3), Vector3(x, (heigth+1)*cell_size, z),
				 Vector3(2*cell_size, 2*cell_size, 2*cell_size), parent, m_cloud)


func add_roadblocks(x, z, parent):
	var roll = rng.randf()
	if roll < proba_roadblock:
		AaPrism.random_free_small(Vector3(4, 1, 4), Vector3(x, 0.25*cell_size, z),
				 Vector3(1.25*cell_size, 0.5*cell_size, 1.25*cell_size), parent, m_cloud)
	if roll < 0.7*proba_roadblock:
		AaPrism.random_free_small(Vector3(4,1,4), Vector3(x, 0.5*cell_size, z),
				 Vector3(1.25*cell_size, 0.5*cell_size, 1.25*cell_size), parent, m_cloud)
	if roll < 0.3*proba_roadblock:
		AaPrism.random_free_small(Vector3(4,1,4), Vector3(x, 0.75*cell_size, z),
				 Vector3(1.25*cell_size, 0.5*cell_size, 1.25*cell_size), parent, m_cloud)


func add_park(x, z, parent):
	var _path = "res://materials/grass_"+str(rng.randi_range(1,5))+".material"
	var m_grass: Material = load(_path)
	AaPrism.build_above( Vector3(x, 0, z),
			 Vector3(3*cell_size, 0.02*cell_size, 3*cell_size), parent, m_grass)


func add_building(x, z, parent):
	var roll = rng.randf()
	var m_building
	var mat_roll = rng.randf()
	if mat_roll<0.2:
		m_building = m_building1
	elif mat_roll<0.4:
		m_building = m_building2
	elif mat_roll<0.6:
		m_building = m_building3
	elif mat_roll<0.8:
		m_building = m_building4
	else:
		m_building = m_building5
		
	if roll > proba_zeroG:
		AaPrism.random_grounded(Vector3(1, 2, 1), Vector3(x, 1.5*cell_size, z),
				 Vector3(2.5*cell_size, 3*cell_size, 2.5*cell_size), parent, m_building)
		if coin_toss():
			AaPrism.random_grounded(Vector3(2, 1, 2), Vector3(x, 1.5*cell_size, z),
					 Vector3(2.5*cell_size, 3*cell_size, 2.5*cell_size), parent, m_building)
	else:
		AaPrism.random_free(Vector3(2, 1, 2), Vector3(x, 1.5*cell_size, z),
				 Vector3(2.5*cell_size, 3*cell_size, 2.5*cell_size), parent, m_building)
		if coin_toss():
			AaPrism.random_free(Vector3(1, 2, 1), Vector3(x, 1.5*cell_size, z),
					 Vector3(2.5*cell_size, 3*cell_size, 2.5*cell_size), parent, m_building)

func add_pivot(x, z, parent):
	var roll = rng.randf()
	if roll < proba_pivot:
		roll = rng.randf()
		var m_building
		var mat_roll = rng.randf()
		if mat_roll<0.2:
			m_building = m_building1
		elif mat_roll<0.4:
			m_building = m_building2
		elif mat_roll<0.6:
			m_building = m_building3
		elif mat_roll<0.8:
			m_building = m_building4
		else:
			m_building = m_building5
		
		var height_factor = rng.randi_range(1,3)+.1
		
		if roll > proba_zeroG:
			AaPrism.random_grounded(Vector3(1, 2, 1), Vector3(x, height_factor*cell_size, z),
					 Vector3(1.9*cell_size, 2*height_factor*cell_size, 1.9*cell_size), parent, m_building)
			if coin_toss():
				AaPrism.random_grounded(Vector3(2, 1, 2), Vector3(x, height_factor*cell_size, z),
						 Vector3(1.9*cell_size, 2*height_factor*cell_size, 1.9*cell_size), parent, m_building)
		else:
			AaPrism.random_free(Vector3(2, 1, 2), Vector3(x, height_factor*cell_size, z),
					 Vector3(1.9*cell_size, 2*height_factor*cell_size, 1.9*cell_size), parent, m_building)
			if coin_toss():
				AaPrism.random_free(Vector3(1, 2, 1), Vector3(x, height_factor*cell_size, z),
						 Vector3(1.9*cell_size, 2*height_factor*cell_size, 1.9*cell_size), parent, m_building)

func add_trees(x, z, parent):
	var _path = "res://materials/tree_"+str(rng.randi_range(1,5))+".material"
	var m_tree: Material = load(_path)
	var roll = rng.randf()
	if roll > proba_zeroG:
		for i in rng.randi_range(1,4):
			AaPrism.random_grounded_small(Vector3(7, 2, 7), Vector3(x, 0.5*cell_size, z),
				 Vector3(2.5*cell_size, cell_size, 2.5*cell_size), parent, m_tree)
	else:
		for i in rng.randi_range(1,4):
			AaPrism.random_free_small(Vector3(7, 2, 7), Vector3(x, 0.5*cell_size, z),
				 Vector3(2.5*cell_size, cell_size, 2.5*cell_size), parent, m_tree)


func add_tower(x, z, parent):
	var roll = rng.randf()
	if roll > proba_zeroG:
		AaPrism.build_above( Vector3(x, 0, z),
				 Vector3(2.5*cell_size, rng.randi_range(2,9)*cell_size,
				 2.5*cell_size), parent, m_tower)
	else:
		AaPrism.build_above( Vector3(x, rng.randi_range(1,3)*cell_size, z),
				 Vector3(2.5*cell_size, rng.randi_range(2,9)*cell_size,
				 2.5*cell_size), parent, m_tower)


# Pick among house, trees, building
func add_terrain(x, z, parent):
	var roll = rng.randf()
	
	if roll < proba_building:
		if coin_toss():
			add_park(x, z, parent)
		add_building(x, z, parent)
	else:
		roll = rng.randf()
		if roll < proba_tower_if_not_building:
			add_tower(x, z, parent)
		else:
			add_park(x, z, parent)
			add_trees(x, z, parent)


# Recursively change owner of all children
func own_children_recursive(node, allfather):
	if node.get_child_count() > 0:
		for n in node.get_children():
#			var n_name = plate_filename_base + str(plate_size) + "_nb_" + str(plate_number) + "_node_" + str(node_count)
#			n.set_name(n_name)
			node_count += 1
			n.owner = allfather
			own_children_recursive(n, allfather)

func terminate_children(node):
	for n in node.get_children():
		n.free()
