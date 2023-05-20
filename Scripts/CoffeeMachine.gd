extends StaticBody


export(int,0,9999999)var health = 100
onready var stream_player = get_node("../StreamPlayer") as AudioStreamPlayer3D
onready var coffee_particles = get_node("../Particles") as Particles



remotesync func receive_damage(damage):
	health -= damage
	coffee_particles.emitting = true
	if stream_player.playing:
		stream_player.stop()
	else:
		stream_player.play()
