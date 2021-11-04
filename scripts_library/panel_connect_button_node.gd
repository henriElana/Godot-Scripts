extends Panel

# Source : godot engine manual

func _ready():
	# If Button node is child of the Label node.
	get_node("Label/Button")
	# If Button node is child of the Panel node
	get_node("Button").connect("pressed", self, "_on_Button_pressed")

func _on_Button_pressed():
	# If Label node is child of the Panel node
	get_node("Label").text = "HELLO!"
