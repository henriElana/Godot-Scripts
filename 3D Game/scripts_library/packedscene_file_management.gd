extends Node

# Create the objects.
var node = Node2D.new()
var rigid = RigidBody2D.new()
var collision = CollisionShape2D.new()

# Universal owner for recursive script
var all_father = Spatial.new()

func _ready():
		
	# Create the object hierarchy.
	rigid.add_child(collision)
	node.add_child(rigid)

	# Change owner of `rigid`, but not of `collision`.
	rigid.owner = node
	
	
	var scene = PackedScene.new()
	# Only `node` and `rigid` are now packed.
	var result = scene.pack(node)
	if result == OK:
		var error = ResourceSaver.save("res://path/name.scn", scene)  # Or "user://..."
		if error != OK:
			push_error("An error occurred while saving the scene to disk.")


# Recursively change owner of all children
func own_direct_children(node):
	if node.get_child_count() > 0:
		for n in node.get_children():
			n.owner = all_father
			own_direct_children(n)

