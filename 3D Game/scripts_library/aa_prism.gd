extends Spatial

# Utility class to create axis-aligned prisms in local coordinates.
# Set up in project/settings/autoload.
# Node name : AaPrism.

# Declare member variables here. Examples:
var m_gray_v90: Material = preload("res://materials/gray_v90.material")

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()

# Create prismatic StaticBody with MeshInstance and CollisionShape. Local coordinates !
func build_centered(center_ = Vector3.ZERO, size_ = Vector3.ONE,
			 parent_ = self, mat_ = m_gray_v90, has_collision_shape = true):
	var cube_: StaticBody = StaticBody.new()
	parent_.add_child(cube_)
	cube_.set_translation(center_) # Local coordinates !
	
	if has_collision_shape:
		var collision_shape_: CollisionShape = CollisionShape.new()
		cube_.add_child(collision_shape_)
		collision_shape_.shape = BoxShape.new()
		collision_shape_.shape.set_extents(Vector3(0.5*size_.x, 0.5*size_.y, 0.5*size_.z))
	
	var mesh_instance_: MeshInstance = MeshInstance.new()
	cube_.add_child(mesh_instance_)
	mesh_instance_.mesh = CubeMesh.new()
	mesh_instance_.mesh.set_size(Vector3(size_.x, size_.y, size_.z))
	mesh_instance_.mesh.set_material(mat_)
	
	return cube_


# Create axis aligned prism within extents with given material. Local coordinates !
func build_extents(start_ = Vector3.ZERO, end_ = Vector3.ONE,
			 parent_ = self, mat_ = m_gray_v90, has_collision_shape = true):
	var center_ = 0.5*(start_ + end_)
	var size_ = Vector3(abs(end_.x-start_.x), abs(end_.y-start_.y), abs(end_.z-start_.z))
	
	return build_centered(center_, size_, parent_, mat_, has_collision_shape)


# Create axis aligned prism above center with given material. Local coordinates !
func build_above(base_center_ = Vector3.ZERO, size_ = Vector3.ONE,
			 parent_ = self, mat_ = m_gray_v90, has_collision_shape = true):
	var center_ = base_center_ + Vector3(0, 0.5*abs(size_.y), 0)
	
	return build_centered(center_, size_, parent_, mat_, has_collision_shape)
	

# Create axis aligned prism below center with given material. Local coordinates !
func build_below(top_center_ = Vector3.ZERO, size_ = Vector3.ONE,
			 parent_ = self, mat_ = m_gray_v90, has_collision_shape = true):
	var center_ = top_center_ + Vector3(0, -0.5*abs(size_.y), 0)
	
	return build_centered(center_, size_, parent_, mat_, has_collision_shape)



func random_grounded(cuts_ = Vector3.ONE,center_ = Vector3.ZERO, size_ = Vector3.ONE,
			 parent_ = self, mat_ = m_gray_v90, has_collision_shape = true):
	# Unit cell size
	var cellsize_ = Vector3(size_.x/(cuts_.x+1), size_.y/(cuts_.y+1), size_.z/(cuts_.z+1))
	# Random multiplicators
	var x_cells_ = rng.randi_range(1, int(cuts_.x+1))
	var y_cells_ = rng.randi_range(1, int(cuts_.y+1))
	var z_cells_ = rng.randi_range(1, int(cuts_.z+1))
	# Final cell
	var final_cellsize_ = cellsize_
	final_cellsize_.x *= x_cells_
	final_cellsize_.y *= y_cells_
	final_cellsize_.z *= z_cells_
	# Move new cell to corner
	center_.x -= 0.5*(size_.x-final_cellsize_.x)
	center_.y -= 0.5*(size_.y-final_cellsize_.y)
	center_.z -= 0.5*(size_.z-final_cellsize_.z)
	# Random offset along x and z
	center_.x += rng.randi_range(0,int(cuts_.x+1)-x_cells_)*cellsize_.x
	center_.z += rng.randi_range(0,int(cuts_.z+1)-z_cells_)*cellsize_.z
	
	# Build !
	return build_centered(center_, final_cellsize_, parent_, mat_, has_collision_shape)



func random_grounded_small(cuts_ = Vector3.ONE,center_ = Vector3.ZERO, size_ = Vector3.ONE,
			 parent_ = self, mat_ = m_gray_v90, has_collision_shape = true):
	# Unit cell size
	var cellsize_ = Vector3(size_.x/(cuts_.x+1), size_.y/(cuts_.y+1), size_.z/(cuts_.z+1))
	# Random multiplicators
	var x_cells_ = rng.randi_range(1, min(3, int(cuts_.x+1)))
	var y_cells_ = rng.randi_range(1, min(3, int(cuts_.y+1)))
	var z_cells_ = rng.randi_range(1, min(3, int(cuts_.z+1)))
	# Final cell
	var final_cellsize_ = cellsize_
	final_cellsize_.x *= x_cells_
	final_cellsize_.y *= y_cells_
	final_cellsize_.z *= z_cells_
	# Move new cell to corner
	center_.x -= 0.5*(size_.x-final_cellsize_.x)
	center_.y -= 0.5*(size_.y-final_cellsize_.y)
	center_.z -= 0.5*(size_.z-final_cellsize_.z)
	# Random offset along x and z
	center_.x += rng.randi_range(0,int(cuts_.x+1)-x_cells_)*cellsize_.x
	center_.z += rng.randi_range(0,int(cuts_.z+1)-z_cells_)*cellsize_.z
	
	# Build !
	return build_centered(center_, final_cellsize_, parent_, mat_, has_collision_shape)


func random_free(cuts_ = Vector3.ONE,center_ = Vector3.ZERO, size_ = Vector3.ONE,
			 parent_ = self, mat_ = m_gray_v90, has_collision_shape = true):
	# Unit cell size
	var cellsize_ = Vector3(size_.x/(cuts_.x+1), size_.y/(cuts_.y+1), size_.z/(cuts_.z+1))
	# Random multiplicators
	var x_cells_ = rng.randi_range(1, min(3, int(cuts_.x+1)))
	var y_cells_ = rng.randi_range(1, min(3, int(cuts_.y+1)))
	var z_cells_ = rng.randi_range(1, min(3, int(cuts_.z+1)))
	# Final cell
	var final_cellsize_ = cellsize_
	final_cellsize_.x *= x_cells_
	final_cellsize_.y *= y_cells_
	final_cellsize_.z *= z_cells_
	# Move new cell to corner
	center_.x -= 0.5*(size_.x-final_cellsize_.x)
	center_.y -= 0.5*(size_.y-final_cellsize_.y)
	center_.z -= 0.5*(size_.z-final_cellsize_.z)
	# Random offset along x, y and z
	center_.x += rng.randi_range(0,int(cuts_.x+1)-x_cells_)*cellsize_.x
	center_.y += rng.randi_range(0,int(cuts_.y+1)-y_cells_)*cellsize_.y
	center_.z += rng.randi_range(0,int(cuts_.z+1)-z_cells_)*cellsize_.z
	
	# Build !
	return build_centered(center_, final_cellsize_, parent_, mat_, has_collision_shape)



func random_free_small(cuts_ = Vector3.ONE, center_ = Vector3.ZERO, size_ = Vector3.ONE,
			 parent_ = self, mat_ = m_gray_v90, has_collision_shape = true):
	# Unit cell size
	var cellsize_ = Vector3(size_.x/(cuts_.x+1), size_.y/(cuts_.y+1), size_.z/(cuts_.z+1))
	# Random multiplicators
	var x_cells_ = rng.randi_range(1, min(3, int(cuts_.x+1)))
	var y_cells_ = rng.randi_range(1, min(3, int(cuts_.y+1)))
	var z_cells_ = rng.randi_range(1, min(3, int(cuts_.z+1)))
	# Final cell
	var final_cellsize_ = cellsize_
	final_cellsize_.x *= x_cells_
	final_cellsize_.y *= y_cells_
	final_cellsize_.z *= z_cells_
	# Move new cell to corner
	center_.x -= 0.5*(size_.x-final_cellsize_.x)
	center_.y -= 0.5*(size_.y-final_cellsize_.y)
	center_.z -= 0.5*(size_.z-final_cellsize_.z)
	# Random offset along x, y and z
	center_.x += rng.randi_range(0,int(cuts_.x+1)-x_cells_)*cellsize_.x
	center_.y += rng.randi_range(0,int(cuts_.y+1)-y_cells_)*cellsize_.y
	center_.z += rng.randi_range(0,int(cuts_.z+1)-z_cells_)*cellsize_.z
	
	# Build !
	return build_centered(center_, final_cellsize_, parent_, mat_, has_collision_shape)
