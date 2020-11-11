extends Node

# Source : godot engine manual

var s: Sprite

func _ready():
	s = Sprite.new() # Create a new sprite!
	add_child(s) # Add it as a child of this node.
	
	# Access a member variable on another node 
	# Relative path reference, ../ = one node up in the scene tree
	var player_max_health = $"../Characters/Player".max_health

func _destroy_me():
	s.queue_free() # Removes the node (and its children) from the scene
	# and frees it when it becomes safe to do so.
