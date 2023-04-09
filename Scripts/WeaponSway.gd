extends Position3D


export(float) var h_sway = 30.0
export(float) var v_sway = 25.0

onready var hand = $"../Hand"
onready var head = $".."
onready var body = $"../.."


# Called when the node enters the scene tree for the first time.
func _ready():
	hand.set_as_toplevel(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	hand.global_transform.origin = global_transform.origin
	hand.rotation.y = lerp_angle(hand.rotation.y,body.rotation.y,h_sway*delta)
	hand.rotation.x = lerp_angle(hand.rotation.x,head.rotation.x,v_sway*delta)
	hand.rotation.z = head.rotation.z
	
