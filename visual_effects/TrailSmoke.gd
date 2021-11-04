extends Area


# Declare member variables here. Examples:
export var SPEED = 40
export var KILL_TIMER = 4
var timer = 0
var is_moving = true

# Called when the node enters the scene tree for the first time.
func _ready():
	$TrailSmoke.restart()
	var col_ = CollisionShape.new()
	add_child(col_)
	col_.set_translation(Vector3(0,0,0))
	col_.set_rotation_degrees(Vector3(0,-180, 0))
	var ray_ = RayShape.new()
	col_.set_shape(ray_)
	ray_.set_length(0.5)
	CollisionManager.setup_weapon_layer_mask(self)
	set_monitorable(false)
	connect("body_entered", self, "collided")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timer += delta
	if timer > KILL_TIMER:
		queue_free()
	if is_moving:
		translate_object_local(Vector3(0.0, 0.0, -SPEED * delta))

func collided(_body):
	if is_moving == true:
		is_moving = false
		$TrailSmoke.set_emitting(false)
