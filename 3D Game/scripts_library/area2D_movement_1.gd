extends Area2D

# Fixed camera
# player position clamped to viewport
# No player rotation

# Source : godot engine manual

export var speed = 400  # How fast the player will move (pixels/sec).
var screen_size  # Size of the game window.


# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size

func _process(delta):
	var velocity = Vector2()  # The player's movement vector.
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1
	# Normalize velocity
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
	# Apply velocity
	position += velocity * delta
	# Prevent player from leaving th screen
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)
