extends Area

export(Global.PickupType) var pickup_type
export(int,1,9999) var amount = 10
export(float) var respawn_time = 10.0
export(NodePath) onready var mesh_instance = get_node(mesh_instance) as Spatial

onready var animation_player = $AnimationPlayer
onready var respawn_timer = $RespawnTimer


func _ready():
	animation_player.play("pickup_floating")
	respawn_timer.wait_time = respawn_time


remotesync func _toggle_can_pickup(v):
	set_deferred("monitoring",v)
	mesh_instance.visible = v


func _on_Pickcup_body_entered(body):
	if body.is_in_group('Players') && monitoring:
		var should_disappear = body.receive_pickup(pickup_type,amount)
		if should_disappear:
#			print(body.name + " picked up " + str(pickup_type))
			rpc("_toggle_can_pickup",false)
			respawn_timer.start()


func _on_RespawnTimer_timeout():
	rpc("_toggle_can_pickup",true)
