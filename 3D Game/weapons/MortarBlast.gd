extends Area

# Declare member variables here. Examples:
const DELAY = 0.5
var has_collided = false
var is_hidden = false
onready var mesh = $MeshInstance
var mat := Material
var col = Color.yellow
const GROWTH_SPEED = 5
const FADE_SPEED = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	var _timer = Timer.new()
	add_child(_timer)
	_timer.connect("timeout",self,"_on_timer_timeout")
	_timer.set_wait_time(DELAY)
	_timer.start()
	
	set_collision_mask(5) # Collides with mobs and player.
	set_monitorable(false)
	mat = mesh.get_active_material(0)
	col = mat.get_albedo()


func _physics_process(delta):
	if !has_collided:
		var list_ = get_overlapping_bodies()
		if list_ != []:
			for ob in list_:
				if ob.has_method("take_explosion_damage"):
					ob.take_explosion_damage(10, translation)
			has_collided = true
			set_monitoring(false)
	if !is_hidden:
		if mesh.get_scale().length_squared() < 3:
			mesh.set_scale((1.0+GROWTH_SPEED*delta)*mesh.get_scale())
			col.a *=1.0-FADE_SPEED*delta
			mat.set_albedo(col)
		else:
			mesh.hide()
			is_hidden = true
			


func _on_timer_timeout():
	queue_free()
