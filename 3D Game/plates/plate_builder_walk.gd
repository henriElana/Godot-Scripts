extends Spatial

# Walk : no clouds. mist light

# Declare member variables here.
var plate_size: float
var cell_size = 16
var cell_per_plate_length = 39 # 4*n-1
var plate = Spatial.new()
var plate_max_altitude_in_cells = 16

var plate_filename_base = "plate_a_size"
var plate_number = 0

var node_count = 0

var rng = RandomNumberGenerator.new()

# random terrain probabilities
var proba_roadblock = 0.05
var proba_building = 0.1
var proba_rocks = 0.3
var proba_pivot = 0.7

var m_cloud: Material = preload("res://materials/cloud.material")
var m_sky: Material = preload("res://materials/sky.material")
var m_plate: Material = preload("res://materials/gray_v30.material")
var m_building1: Material = preload("res://materials/gray_v50.material")
var m_building2: Material = preload("res://materials/gray_v60.material")
var m_building3: Material = preload("res://materials/gray_v70.material")
var m_building4: Material = preload("res://materials/gray_v80.material")
var m_building5: Material = preload("res://materials/gray_v10.material")

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	
	plate_size = (cell_per_plate_length)*cell_size
		
	for i in range(9):
		plate_number = i
		node_count = 0
		build_plate()
	get_tree().quit()

func random_nb_under(value_ = 0.5):
	var roll = rng.randf() < value_
	return roll

func build_plate():

	var min_included = int(floor(cell_per_plate_length/2))
	var max_excluded = int(ceil(cell_per_plate_length/2))
	for x in range(-min_included,max_excluded):
		for z in range(-min_included,max_excluded):
			if not (x==0 and z==0):
				if ((x%4 == 0) or (z%4 == 0)):
					if ((x%8 == 0) and (z%8 == 0)):
						# "Pivot" location
						add_pivot(x*cell_size,z*cell_size, plate)
					elif x==z or x==-z:
						# "Pivot" location
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


func add_roadblocks(x, z, parent):
	if random_nb_under(proba_roadblock):
		var terrain_ = AaPrism.random_free_small(Vector3(7, 7, 7), Vector3(x, 0.5*cell_size, z),
				 Vector3(cell_size, cell_size, cell_size), parent, m_cloud)
		var x_rot_ = (rng.randi_range(1,7)-4)*deg2rad(20)
		var y_rot_ = (rng.randi_range(1,7)-4)*deg2rad(20)
		var z_rot_ = (rng.randi_range(1,7)-4)*deg2rad(20)
		var y_rise = 0.5*rng.randi_range(1,4)
		terrain_.rotate_x(x_rot_)
		terrain_.rotate_y(y_rot_)
		terrain_.rotate_z(z_rot_)
		terrain_.translate(Vector3(0, y_rise, 0))


func add_park(x, z, parent):
	var _path = "res://materials/grass_"+str(rng.randi_range(1,5))+".material"
	var m_grass: Material = load(_path)
	# No collision with grass --> "false" parameter
	AaPrism.build_above( Vector3(x, 0, z),
			 Vector3(3*cell_size, 0.02*cell_size, 3*cell_size), parent, m_grass, false)


func add_building(x, z, parent):
	var root_ = Spatial.new()
	parent.add_child(root_)
	root_.set_translation(Vector3(x, 0.0, z))
	
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
	var height_factor_ = rng.randi_range(1,3)
	AaPrism.random_grounded(Vector3(4, 9, 4), Vector3(0.0, 1.25*cell_size*height_factor_, 0.0),
			 Vector3(2.5*cell_size, 2.5*cell_size*height_factor_, 2.5*cell_size), root_, m_building)
	if random_nb_under():
		AaPrism.random_grounded(Vector3(4, 9, 4), Vector3(0.0, 1.25*cell_size*height_factor_, 0.0),
				 Vector3(2.5*cell_size, 2.5*cell_size*height_factor_, 2.5*cell_size), root_, m_building)
	
	return root_


func add_trees(x, z, parent):
	var root_ = Spatial.new()
	parent.add_child(root_)
	root_.set_translation(Vector3(x, 0.0, z))
	
	for i in rng.randi_range(1,7):
		# Keep textures from overlapping by offseting models :
		var xz_offset = 0.1*i-0.4
		var _path = "res://materials/tree_"+str(rng.randi_range(1,5))+".material"
		var m_tree: Material = load(_path)
		AaPrism.random_grounded_small(Vector3(15, 15, 15), 
			Vector3(xz_offset, 1.25*cell_size, xz_offset),
			Vector3(2.5*cell_size, 2.5*cell_size, 2.5*cell_size), root_, m_tree)
	
	return root_


func add_rocks(x, z, parent):
	var root_ = Spatial.new()
	parent.add_child(root_)
	root_.set_translation(Vector3(x, 0.0, z))
	
	for i in rng.randi_range(1,6):
		AaPrism.random_grounded_small(Vector3(7, 19, 7), Vector3(0.0, 1.25*cell_size, 0.0),
			 Vector3(2.5*cell_size, 2.5*cell_size, 2.5*cell_size), root_, m_plate)
	
	return root_


# Pick among building, trees, rocks
func add_terrain(x, z, parent):
	var terrain_
	if random_nb_under(proba_building):
		# add building, light grey base
		terrain_ =  Spatial.new()
		parent.add_child(terrain_)
		terrain_.set_translation(Vector3(x, 0.0, z))
		AaPrism.build_below(Vector3(0.0, 0.0, 0.0),
			Vector3(4*cell_size, 4*cell_size, 4*cell_size),
			terrain_, m_building4)
		add_building(0.0, 0.0, terrain_)
	else:
		if random_nb_under(proba_rocks):
			# Add rocks, dark grey base
			terrain_ =  Spatial.new()
			parent.add_child(terrain_)
			terrain_.set_translation(Vector3(x, 0.0, z))
			AaPrism.build_below(Vector3(0.0, 0.0, 0.0),
					Vector3(4*cell_size, 4*cell_size, 4*cell_size),
					terrain_, m_plate)
			add_rocks(0.0, 0.0, terrain_)
		else:
			# Add trees, random green base
			var _path = "res://materials/grass_"+str(rng.randi_range(1,5))+".material"
			var m_grass: Material = load(_path)
			terrain_ =  Spatial.new()
			parent.add_child(terrain_)
			terrain_.set_translation(Vector3(x, 0.0, z))
			AaPrism.build_below(Vector3(0.0, 0.0,0.0),
					Vector3(4*cell_size, 4*cell_size, 4*cell_size),
					terrain_, m_grass)
			add_trees(0.0, 0.0, terrain_)
	

	var x_rot_ = (rng.randi_range(1,7)-4)*deg2rad(1)
	var z_rot_ = (rng.randi_range(1,7)-4)*deg2rad(1)
	var y_rise = 0.5*rng.randi_range(0,4)
	if random_nb_under():
		terrain_.rotate_x(x_rot_)
		terrain_.rotate_z(z_rot_)
	else:
		terrain_.rotate_z(z_rot_)
		terrain_.rotate_x(x_rot_)
	terrain_.translate_object_local(Vector3(0, y_rise, 0))


# Pick among building, trees, rocks
func add_pivot(x, z, parent):
	
	if random_nb_under(proba_pivot):
		# add building, light grey base
		var terrain_ =  Spatial.new()
		parent.add_child(terrain_)
		terrain_.set_translation(Vector3(x, 0.0, z))
		add_building(0.0, 0.0, terrain_)
		
		var x_rot_ = (rng.randi_range(1,7)-4)*deg2rad(1)
		var z_rot_ = (rng.randi_range(1,7)-4)*deg2rad(1)
		var y_rise = 0.5*rng.randi_range(0,4)
		if random_nb_under():
			terrain_.rotate_x(x_rot_)
			terrain_.rotate_z(z_rot_)
		else:
			terrain_.rotate_z(z_rot_)
			terrain_.rotate_x(x_rot_)
		
		if random_nb_under():
			terrain_.rotate_y(deg2rad(45))
		
		terrain_.translate_object_local(Vector3(0, y_rise, 0))


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
