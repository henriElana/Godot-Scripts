extends Spatial

var state_machine
var smash_state_machine
var attack_index = 1
var rng



# Called when the node enters the scene tree for the first time.
func _ready():
	state_machine = $AnimationTree["parameters/playback"]
	var tree_ = $AnimationTree
	tree_.set_active(true)
	rng = RandomNumberGenerator.new()
	rng.randomize()


func play_airborne():
	state_machine.travel("airborne")

func play_wallrun():
	state_machine.travel("wallrun")

func play_jump():
	state_machine.travel("jump")
	
func play_ball():
	state_machine.travel("ball")

func play_turn_still():
	state_machine.travel("idle_2")

func play_idle():
	var name = "idle_"+str(rng.randi()%2+1)
	state_machine.travel(name)

func play_run():
	var name = "run_"+str(rng.randi()%2+1)
	state_machine.travel(name)

func play_smash_start():
	attack_index = rng.randi()%4+1
	var name = "strike_0"+str(attack_index)+"_a"
	state_machine.travel(name)

func play_smash_end():
	var name = "strike_0"+str(attack_index)+"_b"
	state_machine.travel(name)
