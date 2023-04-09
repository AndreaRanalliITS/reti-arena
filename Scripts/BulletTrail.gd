extends ImmediateGeometry


onready var trail_fadeout = $TrailFadeout


func set_trail(start:Vector3,end:Vector3):
	begin(Mesh.PRIMITIVE_LINE_STRIP)
	add_vertex(start)
	add_vertex(end)
	end()
	trail_fadeout.play("BulletTrailFadeout")


func _on_TrailFadeout_animation_finished(_anim_name):
	queue_free()
