extends Spatial

# Walk : no clouds. mist light

# Declare member variables here.
#var plate_size: float
var cell_size = 64
var level_core_lenght_in_cells = 10 #grow along -z
var plate_max_altitude_in_cells = 10
var max_cell_number = 30

export var use_random_plate_tilt = false

var my_player

var game_manager
#
var node_count = 0

var rng = RandomNumberGenerator.new()

# random terrain probabilities
var proba_roadblock = 0.5
var proba_building = 0.1
var proba_rocks = 0.3
var proba_pivot = 0.7
var proba_cloud = 0.1

var m_cloud: Material = preload("res://materials/cloud.material")
var m_sky: Material = preload("res://materials/sky.material")
var m_plate: Material = preload("res://materials/gray_v30.material")
var m_building1: Material = preload("res://materials/gray_v50.material")
var m_building2: Material = preload("res://materials/gray_v60.material")
var m_building3: Material = preload("res://materials/gray_v70.material")
var m_building4: Material = preload("res://materials/gray_v80.material")
var m_building5: Material = preload("res://materials/gray_v10.material")

# terrain peak position
var extrema = []
var spawn_pos_array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	
	game_manager = get_parent()
	
	rng.randomize()
	
	build_plate()

func random_nb_under(value_ = 0.5):
	var roll = rng.randf() < value_
	return roll

func build_plate():
	# Plate parameters randomization
	proba_building = 0.1*rng.randi_range(2,6)
	proba_rocks = 0.1*rng.randi_range(2,6)
	proba_pivot = 0.1*rng.randi_range(4,7)
	
	# Plate slope management
	var number_of_extrema = rng.randi_range(1,3)
	create_extrema(number_of_extrema)
	
	# Cells positions generation
	var pos_indexes_ = []
	for z in range(0,level_core_lenght_in_cells):
		pos_indexes_.append(Vector2(0,-z))
	var old_pos_indexes_ = pos_indexes_
	var pos_offsets = [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]
	while pos_indexes_.size() < max_cell_number:
		for pos_ in old_pos_indexes_:
			
			var new_pos_ = pos_ + pos_offsets[rng.randi_range(0,3)]
			
			if not(new_pos_ in pos_indexes_):
				pos_indexes_.append(new_pos_)
		old_pos_indexes_ = pos_indexes_
	
	for p in pos_indexes_:
		add_terrain(p.x*cell_size,p.y*cell_size, self)
		add_clouds(p.x*cell_size,p.y*cell_size, self)
		
	# Mobwalls positions generation
	var mobwall_pos_indexes_ = []
	for p in pos_indexes_:
		for o in pos_offsets:
			var mw_pos = p+o
			if not(mw_pos in pos_indexes_):
				mobwall_pos_indexes_.append(mw_pos)
	for p in mobwall_pos_indexes_:
		add_mobwall(p.x*cell_size,p.y*cell_size, self)
	
	# Spawn points positions list, size 5
	for i_ in range(5):
		var pos_index_  = pos_indexes_[pos_indexes_.size()-1-i_]
		var y_rise_ = 2*cell_size
		for i in range(extrema.size()):
			y_rise_ += calculate_height(extrema[i], Vector3(pos_index_.x*cell_size, 0.0, pos_index_.y*cell_size))
		var spawn_pos_ = Vector3(pos_index_.x*cell_size, y_rise_, pos_index_.y*cell_size)
		spawn_pos_array.append(spawn_pos_)
	game_manager.setup_spawn_pos_array(spawn_pos_array)



func create_extrema(number=1):
	# Plate slope management
	for _i in range(number):
		var sign_ = 2*(rng.randi_range(0,1)-0.5)
		var extremum_z_ = rng.randf_range(-level_core_lenght_in_cells*cell_size,0)
		var extremum_y_ = sign_*0.2*(0.5*level_core_lenght_in_cells*cell_size- abs(extremum_z_))
		var extremum = Vector3(0.0, extremum_y_, extremum_z_)
		extrema.append(extremum)


func add_clouds(x, z, parent):
	var roll = rng.randf()
	var heigth = rng.randi_range(6,plate_max_altitude_in_cells)
	
	# No collision with clouds --> "false" parameter
	if roll < proba_cloud:
		var cloud_ = AaPrism.random_free(Vector3(3,3,3), Vector3(x, heigth*cell_size, z),
				 Vector3(1.25*cell_size, 0.75*cell_size, 1.25*cell_size), parent, m_cloud, false)
		# Keep texture overlap with buildings to a minimum :
		var y_rot_ = deg2rad(30)
		cloud_.rotate_y(y_rot_)
	if roll < 0.5*proba_cloud:
		var cloud_ = AaPrism.random_free(Vector3(3,3,3), Vector3(x, (heigth+1.5)*cell_size, z),
				 Vector3(1.25*cell_size, 0.75*cell_size, 1.25*cell_size), parent, m_cloud, false)
		# Keep texture overlap with buildings to a minimum :
		var y_rot_ = deg2rad(30)
		cloud_.rotate_y(y_rot_)


func add_roadblocks(x, z, parent):
	if random_nb_under(proba_roadblock):
		
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
		
		var terrain_ = AaPrism.random_free_small(Vector3(4, 4, 4), Vector3(x, 0.25*cell_size, z),
				 Vector3(0.5*cell_size, 0.5*cell_size, 0.5*cell_size), parent, m_building)
		var x_rot_ = (rng.randi_range(1,7)-4)*deg2rad(20)
		var y_rot_ = (rng.randi_range(1,7)-4)*deg2rad(20)
		var z_rot_ = (rng.randi_range(1,7)-4)*deg2rad(20)
		terrain_.rotate_x(x_rot_)
		terrain_.rotate_y(y_rot_)
		terrain_.rotate_z(z_rot_)


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
	AaPrism.random_grounded_small(Vector3(4, 9, 4), Vector3(0.0, 0.3*cell_size*height_factor_, 0.0),
			 Vector3(0.6*cell_size, 0.6*cell_size*height_factor_, 0.6*cell_size), root_, m_building)
	if random_nb_under():
		AaPrism.random_grounded_small(Vector3(4, 9, 4), Vector3(0.0, 0.3*cell_size*height_factor_, 0.0),
				 Vector3(0.6*cell_size, 0.6*cell_size*height_factor_, 0.6*cell_size), root_, m_building)
		if random_nb_under():
			AaPrism.random_free_small(Vector3(4, 4, 4), Vector3(0.0, 0.3*cell_size*height_factor_, 0.0),
					 Vector3(0.6*cell_size, 0.6*cell_size*height_factor_, 0.6*cell_size), root_, m_building)
			if random_nb_under():
				AaPrism.random_free_small(Vector3(4, 4, 4), Vector3(0.0, 0.3*cell_size*height_factor_, 0.0),
						 Vector3(0.6*cell_size, 0.6*cell_size*height_factor_, 0.6*cell_size), root_, m_building)
	return root_


func add_trees(x, z, parent):
	var root_ = Spatial.new()
	parent.add_child(root_)
	root_.set_translation(Vector3(x, 0.0, z))
	
	for i in rng.randi_range(1,13):
		# Keep textures from overlapping by offseting models :
		var xz_offset = 0.1*i-0.7
		var _path = "res://materials/tree_"+str(rng.randi_range(1,5))+".material"
		var m_tree: Material = load(_path)
		AaPrism.random_grounded_small(Vector3(18, 18, 18), 
			Vector3(xz_offset, 0.49*cell_size + 0.5*i, xz_offset),
			Vector3(0.98*cell_size, 0.98*cell_size + i, 0.98*cell_size), root_, m_tree)
	
	return root_


func add_rocks(x, z, parent):
	var root_ = Spatial.new()
	parent.add_child(root_)
	root_.set_translation(Vector3(x, 0.0, z))
	
	for i in rng.randi_range(1,6):
		AaPrism.random_grounded_small(Vector3(9, 12, 9), Vector3(0.0, 0.5*cell_size, 0.0),
			 Vector3(cell_size, cell_size, cell_size), root_, m_plate)
	
	return root_

func add_mobwall(x, z, parent):
	var terrain_ =  Spatial.new()
	parent.add_child(terrain_)
	terrain_.set_translation(Vector3(x, 0.0, z))
	AaPrism.build_centered_mobwall(Vector3(0.0, 0.0, 0.0),
		Vector3(cell_size, 2*cell_size, cell_size),
		terrain_)
	var y_rise = 0.0
	for i in range(extrema.size()):
		y_rise += calculate_height(extrema[i], Vector3(x, 0.0, z))
	terrain_.translate_object_local(Vector3(0, y_rise, 0))
	terrain_.set_visible(false)


# Pick among building, trees, rocks
func add_terrain(x, z, parent):
	var terrain_
	if random_nb_under(proba_building):
		# add building, medium grey base
		terrain_ =  Spatial.new()
		parent.add_child(terrain_)
		terrain_.set_translation(Vector3(x, 0.0, z))
		AaPrism.build_below(Vector3(0.0, 0.0, 0.0),
			Vector3(cell_size, 2*cell_size, cell_size),
			terrain_, m_building1)
		add_building(0.0, 0.0, terrain_)
	else:
		if random_nb_under(proba_rocks):
			# Add rocks, dark grey base
			terrain_ =  Spatial.new()
			parent.add_child(terrain_)
			terrain_.set_translation(Vector3(x, 0.0, z))
			AaPrism.build_below(Vector3(0.0, 0.0, 0.0),
					Vector3(cell_size, 2*cell_size, cell_size),
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
					Vector3(cell_size, 2*cell_size, cell_size),
					terrain_, m_grass)
			add_trees(0.0, 0.0, terrain_)
	
	var offset_ = get_random_offset_to_cell_edge()
	if random_nb_under():
		add_pivot(offset_.x, offset_.z, terrain_)
	else:
		add_roadblocks(offset_.x, offset_.z, terrain_)

	var y_rise = 0.5*rng.randi_range(0,4)
	for i in range(extrema.size()):
		y_rise += calculate_height(extrema[i], Vector3(x, 0.0, z))
	terrain_.translate_object_local(Vector3(0, y_rise, 0))
	
	if use_random_plate_tilt:
		var x_rot_ = (rng.randi_range(1,7)-4)*deg2rad(1)
		var z_rot_ = (rng.randi_range(1,7)-4)*deg2rad(1)
		if random_nb_under():
			terrain_.rotate_x(x_rot_)
			terrain_.rotate_z(z_rot_)
		else:
			terrain_.rotate_z(z_rot_)
			terrain_.rotate_x(x_rot_)


# Pick among building, trees, rocks
func add_pivot(x, z, parent):
	
	if random_nb_under(proba_pivot):
		# add building, light grey base
		var terrain_ =  Spatial.new()
		parent.add_child(terrain_)
		terrain_.set_translation(Vector3(x, 0.0, z))
		add_building(0.0, 0.0, terrain_)
		
		var y_rise = - 2.0
		terrain_.translate_object_local(Vector3(0, y_rise, 0))
		
		if use_random_plate_tilt:
			var x_rot_ = (rng.randi_range(1,7)-4)*deg2rad(1)
			var z_rot_ = (rng.randi_range(1,7)-4)*deg2rad(1)
			if random_nb_under():
				terrain_.rotate_x(x_rot_)
				terrain_.rotate_z(z_rot_)
			else:
				terrain_.rotate_z(z_rot_)
				terrain_.rotate_x(x_rot_)
		
		if random_nb_under():
			terrain_.rotate_y(deg2rad(45))
		


func calculate_height(extremum_, position_):
	var extremum_xz_ = Vector3(extremum_.x, 0.0, extremum_.z)
	var position_xz_ = Vector3(position_.x, 0.0, position_.z)
	var distance_ = (extremum_xz_ - position_xz_).length()
	var amplitude_ = 0.5*extremum_.y
	var cosine_half_period = 0.5*level_core_lenght_in_cells*cell_size - abs(extremum_.z)
	var height_
	if distance_ < cosine_half_period:
		height_ = amplitude_*(1+cos(PI*distance_/cosine_half_period))
	else:
		height_ = 0.0
	
	return height_


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

func set_player(player_):
	my_player = player_

func get_random_offset_to_cell_edge():
	var x_offset_
	var z_offset_
	var offset_
	if random_nb_under():
		# Random position along +x or -x edge
		x_offset_ = 0.5*cell_size
		if random_nb_under():
			x_offset_ *= -1
		z_offset_ = (randf()-0.5)*cell_size
	else:
		# Random position along +z or -z edge
		z_offset_ = 0.5*cell_size
		if random_nb_under():
			z_offset_ *= -1
		x_offset_ = (randf()-0.5)*cell_size
	offset_ = Vector3(x_offset_, 0, z_offset_)
	return offset_
