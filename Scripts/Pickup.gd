extends Area

export(Global.PickupType) var pickup_type
export(int,1,9999) var amount = 10
export(float) var respawn_time = 10.0
export(AudioStream) var ammo_pickup_sound
export(AudioStream) var health_pickup_sound

onready var mesh_instance = $Mesh
onready var animation_player = $AnimationPlayer
onready var respawn_timer = $RespawnTimer
onready var sound_player = $SoundPlayer as AudioStreamPlayer3D


func _ready():
#	mesh_instance = get_node(mesh_instance) as Spatial
	set_pickup_mesh()
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
			if pickup_type == Global.PickupType.HEALTH_PACK:
				play_sound(health_pickup_sound)
			else:
				play_sound(ammo_pickup_sound)
			rpc("_toggle_can_pickup",false)
			respawn_timer.start()


func set_pickup_mesh():
	for i in range(mesh_instance.get_child_count()):
		mesh_instance.get_child(i).visible = i == pickup_type

func play_sound(sound:AudioStream):
	sound_player.stop()
	sound_player.stream = sound
	sound_player.play()

func _on_RespawnTimer_timeout():
	rpc("_toggle_can_pickup",true)
