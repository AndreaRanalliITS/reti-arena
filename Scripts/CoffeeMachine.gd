extends StaticBody


export(int,0,9999999)var health = 1000
export(NodePath) onready var audio_player = get_node(audio_player) as AudioStreamPlayer3D
export(NodePath) onready var particles = get_node(particles) as Particles



remotesync func receive_damage(damage):
	health -= damage
	
	if health <= 0:
		get_parent().queue_free()
		return
	
	particles.emitting = true
	if audio_player.playing:
		audio_player.stop()
	else:
		audio_player.play()
