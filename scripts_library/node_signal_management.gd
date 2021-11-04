extends Node

# Source : godot engine manual

# Declare member variables here. Examples:
signal my_signal # Custom signal
signal my_signal_with_optional_arguments(value, other_value) # Custom signal with arguments

func _ready():
	# Connect the buit-in "timeout" signal from a child Timer node
	# to the "_on_Timer_timeout" function
	$Timer.connect("timeout", self, "_on_Timer_timeout")
	
	emit_signal("my_signal")
	emit_signal("my_signal_with_optional_arguments",true,42)

func _on_Timer_timeout():
	pass
