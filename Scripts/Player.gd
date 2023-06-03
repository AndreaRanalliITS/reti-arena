extends KinematicBody

const HEAD_ROTATION_CLAMP = deg2rad(90)

export(float) var gravity = -40.0
export(float,0,999) var speed = 16.0
export(float,0,999) var jump_speed = 15.0
export(float,0,999) var mouse_sensitivity = .08
export(int,0,9999) var max_health = 100
export(int,0,9999) var health = 100
export(bool) var invincible = false
export(bool) var spec_mode = false
export(NodePath) onready var collision_shape = get_node(collision_shape) as CollisionShape
export(NodePath) onready var head = get_node(head) as Spatial
export(NodePath) onready var model = get_node(model) as Spatial
export(NodePath) onready var camera = get_node(camera) as Camera
export(NodePath) onready var hand = get_node(hand) as Position3D
export(NodePath) onready var player_name_label = get_node(player_name_label) as Label3D
export(NodePath) onready var network_tick_rate = get_node(network_tick_rate) as Timer
export(NodePath) onready var movement_tween = get_node(movement_tween) as Tween

onready var is_network_master = is_network_master()
export(NodePath) onready var life_bar = get_node(life_bar) as TextureProgress
export(NodePath) onready var life_label = get_node(life_label) as Label

var can_move = true
var velocity = Vector3()
var gravity_vec = Vector3()
var pup_position = Vector3()
var pup_velocity = Vector3()
var pup_rotation:float = 0.0





func _ready():
	if is_network_master:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse_sensitivity = Utils.get_setting("player_confs","mouse_sensitivity",0.08)
		network_tick_rate.connect("timeout",self,"_on_NetworkTickRate_timeout")
		network_tick_rate.start()
		life_bar.min_value = 0
		life_bar.max_value = max_health
		update_lifebar()
		camera.current = true
		var error = Global.connect("toggle_pause",self,"_toggle_pause")
		if error != OK:
			printerr(error)
		rpc("_update_mesh_material",Global.players_info[get_tree().get_network_unique_id()].avatar)
	else:
		camera.queue_free()
		get_node("UI").queue_free()
		network_tick_rate.queue_free()
	
	model.visible = not is_network_master
	player_name_label.visible = not is_network_master



func get_input() -> Vector3:
	var input_dir = Vector3()
	
	var subject = head if spec_mode else self
	
	if Input.is_action_pressed("forward"):
		input_dir += -subject.global_transform.basis.z
	if Input.is_action_pressed("backward"):
		input_dir += subject.global_transform.basis.z
	if Input.is_action_pressed("left"):
		input_dir += -global_transform.basis.x
	if Input.is_action_pressed("right"):
		input_dir += global_transform.basis.x
	
	
	input_dir = input_dir.normalized()
	
	return input_dir


func _input(event):
	if !is_network_master:
		return
	
	if event is InputEventMouseMotion && can_move:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x,-HEAD_ROTATION_CLAMP,HEAD_ROTATION_CLAMP)


func _physics_process(delta):
	if is_network_master:
		if can_move:
			var desired_velocity = get_input() * speed
			velocity.x = desired_velocity.x
			velocity.z = desired_velocity.z
			if spec_mode:
				velocity.y = desired_velocity.y
		
		if is_on_floor():
			velocity.y=0
			if Input.is_action_just_pressed("jump") && can_move && not spec_mode:
				velocity.y += jump_speed
		
		if not spec_mode:
			velocity.y += gravity * delta
		
	else:
		global_transform.origin = pup_position
		velocity.x = pup_velocity.x
		velocity.z = pup_velocity.z
		rotation.y = pup_rotation
	
	if !movement_tween.is_active():
		velocity = move_and_slide(velocity, Vector3.UP, true)

func _toggle_pause(toggle):
	can_move = not toggle


func update_lifebar():
	life_bar.value = health
	life_label.text = str(health)


puppet func update_state(p_position, p_velocity, p_rotation):
	pup_position = p_position
	pup_velocity = p_velocity
	pup_rotation = p_rotation
	
	movement_tween.interpolate_property(self,"global_transform",global_transform,Transform(global_transform.basis,p_position),0.1)
	movement_tween.start()


puppet func _update_mesh_material(avatar_idx):
	print("[{0}] [{1}] Changing avatar to {2}\n".format([get_tree().get_network_unique_id(),name,avatar_idx]))
	model.mesh.surface_set_material(0, load(Global.avatars[avatar_idx].material))


master func receive_damage(dmg : int):
	if invincible: return
	health -= dmg
	if health <= 0:
		rpc("_update_deaths_count")
		rpc("_toggle_spec_mode",true)
		rpc("_toggle_label",false)
	update_lifebar()


remotesync func _update_deaths_count():
	Global.players_info[get_tree().get_network_unique_id()].deaths += 1
	
	# if server and one player remaining, end match
	if get_tree().get_network_unique_id() == 1:
		var dead_players = 0
		for key in Global.players_info:
			if Global.players_info[key].deaths > 0:
				dead_players += 1
		
		if (Global.players_info.size() - dead_players) <= 1:
			rpc("_end_match")


remotesync func _end_match():
	Global.emit_signal("match_ended")

func receive_health(heal:int)->bool:
	if health <= 0: return false
	
	if health < max_health:
		health += heal
		if health > max_health:
			health = max_health
		update_lifebar()
		return true
	return false


func receive_pickup(pickup_type,amount)->bool:
	if spec_mode: 
		return false
	
	if pickup_type == Global.PickupType.HEALTH_PACK:
		return receive_health(amount)
	else:
		return hand.receive_ammo(pickup_type,amount)



func reset_state(wpns_to_reset=[0],wpn_to_equip=0):
	health = max_health
	update_lifebar()
	rpc("_toggle_spec_mode",false)
	rpc("_toggle_label",true)
	hand.reset_state(wpns_to_reset,wpn_to_equip)


func _set_label_text(text):
	player_name_label.text = text

puppet func _toggle_label(toggle):
	player_name_label.visible = toggle


puppetsync func _toggle_spec_mode(toggle):
	input_ray_pickable = not toggle
	model.visible = not toggle && not is_network_master()
	hand.set_enabled(not toggle)
	set_collision_layer_bit(0, not toggle)
	set_collision_layer_bit(19, toggle)
	set_collision_mask_bit(0,not toggle)
	spec_mode = toggle



func _on_NetworkTickRate_timeout():
	rpc_unreliable("update_state",global_transform.origin,velocity, rotation.y)

