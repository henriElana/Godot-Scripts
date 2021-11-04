extends Spatial


var barrel_end = Vector3(0.0, 0.0, -2.0)
var warmup_time = 1
var cooldown_time = 2
var timer = 0

var is_shooting = false
var is_warm = false
var target_aim: Vector3
var current_aim: Vector3

var game_manager = null

var m_black: Material = preload("res://materials/gray_v00.material")
var m_yellow: Material = preload("res://materials/fx_yellow.material")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_shooting:
		timer += delta
		if is_warm:
			if timer > cooldown_time:
				shoot()
				timer = 0.0
		else:
			if timer > warmup_time:
				is_warm = true
				shoot()
				timer = 0.0
	

func shoot():
	var mf_pos = to_global(barrel_end)
	var aim_input = -get_global_transform().basis.z
	game_manager.add_muzzle_flash(mf_pos, aim_input)
	game_manager.add_bolt_yellow(mf_pos,aim_input)

func set_manager(manager_):
	game_manager = manager_

func activate_gun():
	is_shooting = true
	is_warm = false
	$Mesh.set_surface_material(1,m_yellow)

func deactivate_gun():
	is_shooting = false
	rotation = Vector3.ZERO
	$Mesh.set_surface_material(1,m_black)
