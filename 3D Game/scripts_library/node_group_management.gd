extends Node

# Source : godot engine manual

func _ready():
	# Add current node to "enemies" group as soon as it enters the tree
	add_to_group("enemies")

# Call the function "player_was_discovered" on every member of the group "enemies"
func _on_discovered(): 
	get_tree().call_group("enemies", "player_was_discovered")

# Built-in functions can also be called
func _group_suicide():
	get_tree().call_group("enemies", "queue_free")

# get the full list of "enemies" nodes
func _enemies_list():
	var enemies = get_tree().get_nodes_in_group("enemies")
	return enemies
