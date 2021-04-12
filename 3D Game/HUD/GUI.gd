extends MarginContainer

# Red and green counters
onready var red_label = $VBoxContainer/HBoxContainer/RedCounter/Value
onready var green_label = $VBoxContainer/HBoxContainer/GreenCounter/Value

# Text display
onready var main_text = $VBoxContainer/Message

# Arrow
onready var arrow = $VBoxContainer/ViewportContainer/Viewport/Arrow
var rot_speed = 5
var target_position = Vector3.ZERO

# Life management
onready var l_bar_front = $VBoxContainer/HBoxContainer/Bars/LifeBar/ProgressLerp/Progress
onready var l_bar_background = $VBoxContainer/HBoxContainer/Bars/LifeBar/ProgressLerp
var current_life = 100
var previous_life = 100
var animated_life = 100
onready var l_tween = $l_Tween

# Energy management
onready var e_bar_front = $VBoxContainer/HBoxContainer/Bars/EnergyBar/ProgressLerp/Progress
onready var e_bar_background = $VBoxContainer/HBoxContainer/Bars/EnergyBar/ProgressLerp
var current_energy = 100
var previous_energy = 100
var animated_energy = 100
onready var e_tween = $i_Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	l_bar_front.value = 100
	l_bar_background.value = 100
	e_bar_front.value = 100
	e_bar_background.value = 100
	red_label.text = "00"
	green_label.text = "00"

func _process(delta):
	if current_life >= animated_life:
		l_bar_front.value = animated_life
	else:
		l_bar_background.value = animated_life
	
	if current_energy >= animated_energy:
		e_bar_front.value = animated_energy
	else:
		e_bar_background.value = animated_energy
	
	# Smooth arrow rotation
	var new_transform = arrow.transform.looking_at(target_position, Vector3.UP)
	arrow.transform  = arrow.transform.interpolate_with(new_transform, rot_speed * delta)
	arrow.transform = arrow.transform.orthonormalized()

func update_red_label(new_value):
	red_label.text = str(round(new_value))

func update_green_label(new_value):
	green_label.text = str(round(new_value))

func update_energy(new_value):
	if current_energy < new_value:
		# Energy increasing, animate front progress.
		e_bar_background.value = new_value
		e_bar_front.value = current_energy
		previous_energy = current_energy
		current_energy = new_value
		e_tween.interpolate_property(self, "animated_energy", previous_energy, current_energy, 0.6, Tween.TRANS_LINEAR, Tween.EASE_IN)
	else:
		# Energy decreasing, animate back progress.
		e_bar_front.value = new_value
		e_bar_background.value = current_energy
		previous_energy = current_energy
		current_energy = new_value
		e_tween.interpolate_property(self, "animated_energy", previous_energy, current_energy, 0.6, Tween.TRANS_LINEAR, Tween.EASE_IN)
	
	if not e_tween.is_active():
		e_tween.start()

func update_life(new_value):
	if current_life < new_value:
		# Energy increasing, animate front progress.
		l_bar_background.value = new_value
		l_bar_front.value = current_life
		previous_life = current_life
		current_life = new_value
		l_tween.interpolate_property(self, "animated_energy", previous_life, current_life, 0.6, Tween.TRANS_LINEAR, Tween.EASE_IN)
	else:
		# Energy decreasing, animate back progress.
		l_bar_front.value = new_value
		l_bar_background.value = current_life
		previous_life = current_life
		current_life = new_value
		l_tween.interpolate_property(self, "animated_energy", previous_life, current_life, 0.6, Tween.TRANS_LINEAR, Tween.EASE_IN)
	
	if not l_tween.is_active():
		l_tween.start()

func update_green_goal(_text):
	green_label.text = _text


func update_red_timer(_text):
	red_label.text = _text

func display_message(_text):
	main_text.text = _text
	main_text.set_visible(true)

func hide_message():
	main_text.set_visible(false)
	
func orient_arrow(_target_position):
	target_position = _target_position
