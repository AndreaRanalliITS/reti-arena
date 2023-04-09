extends KinematicBody

const HEAD_ROTATION_CLAMP = deg2rad(90)

export(float) var gravity = -40.0
export(float,0,999) var speed = 16.0
export(float,0,999) var jump_speed = 15.0
export(float,0,999) var mouse_sensitivity = .08
export(int,0,9999) var max_health = 100
export(int,0,9999) var health = 100
export(bool) var invincible = false
export(NodePath) onready var head = get_node(head) as Spatial
export(NodePath) onready var model = get_node(model) as Spatial
export(NodePath) onready var camera = get_node(camera) as Camera
export(NodePath) onready var hand = get_node(hand) as Position3D
export(NodePath) onready var network_tick_rate = get_node(network_tick_rate) as Timer
export(NodePath) onready var movement_tween = get_node(movement_tween) as Tween

onready var is_network_master = is_network_master()
export(NodePath) onready var life_bar = get_node(life_bar) as TextureProgress
export(NodePath) onready var life_label = get_node(life_label) as Label

var velocity = Vector3()

var pup_position = Vector3()
var pup_velocity = Vector3()
var pup_rotation = Vector2()





func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# get_tree().connect("network_peer_connected",self,"_player_connected")
	
	if is_network_master:
		network_tick_rate.connect("timeout",self,"_on_NetworkTickRate_timeout")
		network_tick_rate.start()
		life_bar.min_value = 0
		life_bar.max_value = max_health
		update_lifebar()
		camera.current = true
	else:
		camera.queue_free()
		get_node("UI").queue_free()
		network_tick_rate.queue_free()
	
#	camera.current = is_network_master
	model.visible = !is_network_master
#	get_node("UI").visible = is_network_master


# func _player_connected(_id):
# 	if is_network_master:
# 		rpc("update_mesh_material",Global.selected_character)


func get_input() -> Vector3:
	var input_dir = Vector3()
	
	if Input.is_action_pressed("forward"):
		input_dir += -global_transform.basis.z
	if Input.is_action_pressed("backward"):
		input_dir += global_transform.basis.z
	if Input.is_action_pressed("left"):
		input_dir += -global_transform.basis.x
	if Input.is_action_pressed("right"):
		input_dir += global_transform.basis.x
	
	
	input_dir = input_dir.normalized()
	
	return input_dir


func _input(event):
	if !is_network_master:
		return
	
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x,-HEAD_ROTATION_CLAMP,HEAD_ROTATION_CLAMP)


func _physics_process(delta):
	if is_network_master:
		velocity.y += gravity * delta
		
		var desired_velocity = get_input() * speed
		velocity.x = desired_velocity.x
		velocity.z = desired_velocity.z
		
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y += jump_speed
	else:
		global_transform.origin = pup_position
		velocity.x = pup_velocity.x
		velocity.z = pup_velocity.z
		rotation.y = pup_rotation.y
		head.rotation.x = pup_rotation.x
	
	if !movement_tween.is_active():
		velocity = move_and_slide(velocity, Vector3.UP, true)


func update_lifebar():
	life_bar.value = health
	life_label.text = str(health)


puppet func update_state(p_position, p_velocity, p_rotation):
	pup_position = p_position
	pup_velocity = p_velocity
	pup_rotation = p_rotation
	
	movement_tween.interpolate_property(self,"global_transform",global_transform,Transform(global_transform.basis,p_position),0.1)
	movement_tween.start()


func update_mesh_material(avatar_idx):
	print("[{0}] [{1}] {2}".format([get_tree().get_network_unique_id(),name,"Changing avatar to "+str(avatar_idx)]))
	model.mesh.material = load(Global.avatars[avatar_idx].material)


master func receive_damage(dmg : int):
	if invincible: return
#	print(name + " received " + str(dmg) + " damage")
	health -= dmg
	if health <= 0:
		global_transform.origin = Vector3(0,15,0)
		health = max_health
	update_lifebar()


func receive_health(heal:int):
	health += heal
	if health > max_health:
		health = max_health
	update_lifebar()


func receive_pickup(pickup_type,amount)->bool:
	if pickup_type == Global.PickupType.HEALTH_PACK:
		if health < max_health:
			receive_health(amount)
			return true
		return false
	else:
		return hand.receive_ammo(pickup_type,amount)

func reset_state():
	health = max_health
	update_lifebar()
	hand.reset_state()

func _on_NetworkTickRate_timeout():
#	if is_network_master():
	rpc_unreliable("update_state",global_transform.origin,velocity, Vector2(head.rotation.x,rotation.y))
