extends Panel

const ROTATION_CLAMP = deg2rad(90)

export(NodePath) onready var camera = get_node(camera) as Camera
export(NodePath) onready var camera_pivot = get_node(camera_pivot) as Position3D
export(float,0,999) var mouse_sensitivity = .5
var mouse_entered = false
var mouse_down = false


func _input(event):
	if event is InputEventMouseMotion && mouse_entered && Input.is_action_pressed("fire"):
		rotate_around(camera_pivot.transform.origin,Vector3.UP,deg2rad(-event.relative.x * mouse_sensitivity))
		rotate_around(camera_pivot.transform.origin,camera.transform.basis.x,deg2rad(-event.relative.y * mouse_sensitivity))


func _on_PlayerPreview_mouse_entered():
	mouse_entered = true


func _on_PlayerPreview_mouse_exited():
	mouse_entered = false


func rotate_around(point, axis, angle):
	
	# Get transform
	var trans = camera.global_transform

	# Rotate its basis
	var rotated_basis = trans.basis.rotated(axis, angle)

	# Rotate its origin
	var rotated_origin = point + (trans.origin - point).rotated(axis, angle)

	# Set the result back
	camera.global_transform = Transform(rotated_basis, rotated_origin)
