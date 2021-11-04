extends Spatial

# Declare member variables here. Examples:
var timer = 0.0
var has_collided = true
var DEACTIVATION_TIMER = 2
#onready var mesh = get_node("MeshInstance")
var blast_owner = null
var game_manager = null
const CUT_DAMAGE = 20
onready var my_area = $Area
onready var my_blade =$Blade

var m_metal: Material = preload("res://materials/metal_black.material")
var m_red: Material = preload("res://materials/fx_red.material")

# Called when the node enters the scene tree for the first time.
func _ready():
	CollisionManager.setup_player_mask(my_area)
	my_area.set_monitorable(false)
	my_area.set_monitoring(false)

func _physics_process(delta):
	timer += delta
		
	if !has_collided:
		if timer > DEACTIVATION_TIMER:
			has_collided = true
			my_area.set_monitoring(false)
			my_blade.set_surface_material(1,m_metal)
			
		var list_ = my_area.get_overlapping_bodies()
		if list_ != []:
#			for ob in list_:
#				print(ob.name)
#				if ob == blast_owner:
#					pass
#				else:
#					ob.take_red_damage(CUT_DAMAGE, translation)
					
			for ob in list_:
				ob.take_red_damage(CUT_DAMAGE, translation)
			has_collided = true
			my_area.set_monitoring(false)
			my_blade.set_surface_material(1,m_metal)

func activate_ccw():
	timer = 0.0
	has_collided = false
	my_area.set_monitoring(true)
	my_blade.set_surface_material(1,m_red)

func set_owner(owner_):
	blast_owner = owner_

func set_manager(manager_):
	game_manager = manager_

func set_activation_time(time_):
	DEACTIVATION_TIMER = time_
