extends Node

# Source : godot engine manual

# Objects management (1/2)
var scene: PackedScene = load("res://myscene.tscn") # Will load when the script is instanced.
#var scene2: PackedScene  = preload("res://myscene.tscn") # Will load when parsing the script.

# Game level management (1/2)
var next_scene = preload("res://levels/level2.tscn")

func _my_level_was_completed():
	get_tree().change_scene_to(next_scene)

func _ready():
	
	# Objects management (2/2)
	# Create the actual node from the Packedscene 
	var node = scene.instance()
	add_child(node)
	
	# Access a member variable on another node 
	# Relative path reference, ../ = one node up in the scene tree
	var player_max_health = $"../Characters/Player".max_health

# Variant without member variable decalaraton
#func _on_shoot():
#	var bullet = preload("res://bullet.tscn").instance() # Will load when parsing the script.
#	add_child(bullet)


# Game level management (2/2)
func _my_level_was_completed():
	get_tree().change_scene_to(next_scene)


# Game level management variant without member variable decalaraton
func _my_level_was_completed():
	get_tree().change_scene("res://levels/level2.tscn")
