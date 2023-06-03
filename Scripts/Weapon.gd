extends Spatial

export(int) var clip_size = 5
export(int)onready var clip_amount = clip_size
export(int) var pouch_size = 15
export(int) onready var pouch_amount = pouch_size
export(bool) var single_shot = true
export(int,1,9999) var min_rays = 1
export(int,1,9999) var max_rays = 1
export(float,0,1) var dispersion = .0
export(int) var min_damage = 1
export(int) var max_damage = 10
export(float) var damage_range = 100.0
export(float,0.05,9999) var cooldown = .5
export(float,0.05,9999) var reload_time = .5
export(AudioStream) var shoot_sound
export(AudioStream) var reload_sound

onready var is_network_master = is_network_master()
onready var min_angle = -90 * dispersion
onready var max_angle = 90 * dispersion
onready var cooldown_timer = $ShootCooldown
onready var reload_timer = $ReloadTimer
onready var bullet_trail_origin = $BulletTrailOrigin

export(NodePath) onready var ammo_label = get_node(ammo_label) as Label
export(NodePath) onready var raycast = get_node(raycast) as RayCast
export(NodePath) onready var sound_player = get_node(sound_player) as AudioStreamPlayer3D

export(NodePath) onready var crosshair_collection = get_node(crosshair_collection) as TextureRect
export(NodePath) onready var crosshair = get_node(crosshair) as TextureRect

var equipped = false setget set_equipped
var equippable : bool setget ,can_be_equipped
var cooling_down = false
var reloading = false
var bullet_trail = preload("res://Particles/BulletTrail.tscn")



func _ready():
	cooldown_timer.wait_time = cooldown
	reload_timer.wait_time = reload_time
	update_ammo_label()
	
	var tmp
	if min_rays > max_rays:
		tmp = min_rays
		min_rays = max_rays
		max_rays = tmp
	
	if min_damage > max_damage:
		tmp = min_damage
		min_damage = max_damage
		max_damage = tmp
	
	set_process(is_network_master)
	set_equipped(false)


func _process(_delta):
	if not equipped: return
	var has_to_fire = (Input.is_action_just_pressed("fire") and single_shot) or (Input.is_action_pressed("fire") and not single_shot)
	if has_to_fire && !cooling_down && !reloading && clip_amount > 0:
		cooling_down = true
		clip_amount -= 1
		shoot()
		cooldown_timer.start()
		update_ammo_label()
	elif Input.is_action_just_pressed("reload") && !reloading && clip_amount < clip_size:
		start_reloading()

func start_reloading():
	reloading = true
	cooldown_timer.stop()
	cooling_down = false
	reload_timer.start()
	rpc("play_sound",reload_sound)

func shoot():
	if Global.paused: return
	
	var rays_to_cast = (randi()%(max_rays-min_rays+1))+min_rays
	var hits = {}
	var collision_points = []
	for _i in range(rays_to_cast):
		var angle = Vector3(rand_range(min_angle,max_angle),rand_range(min_angle,max_angle),0)
		raycast.set_rotation_degrees(angle)
		raycast.force_raycast_update()
		var obj = raycast.get_collider()
#		var collision_point
		if obj != null:
			collision_points.append(raycast.get_collision_point())
			if obj.has_method("receive_damage"):
				var dmg = calculate_damage(obj.global_transform.origin)
				if hits.has(obj):
					hits[obj] += dmg
				else:
					hits[obj] = dmg
		else:
			collision_points.append(to_global(raycast.get_cast_to()))
	rpc_unreliable("draw_bullet_trail",bullet_trail_origin.global_transform.origin,collision_points)
	for key in hits.keys():
		key.rpc("receive_damage",hits[key])
	
	if clip_amount == 0:
		start_reloading()



func reload():
	if Global.paused: return
	
	var missing_amount = clip_size - clip_amount
	
	if (pouch_amount-missing_amount) < 0:
		clip_amount += pouch_amount
		pouch_amount = 0
	else:
		pouch_amount -= missing_amount
		clip_amount += missing_amount

puppetsync func play_sound(stream: AudioStream):
	sound_player.stream = stream
	sound_player.play()

puppetsync func draw_bullet_trail(a: Vector3,b):
	sound_player.stream = shoot_sound
	sound_player.play()
	for x in b:
		var trail = bullet_trail.instance()
		get_tree().get_root().get_node("Map").add_child(trail)
		trail.set_trail(a,x)


func calculate_damage(target : Vector3) -> int:
	var dist_to_target = global_translation.distance_to(target)
	if dist_to_target >= damage_range:
		return min_damage
	return int(max_damage / dist_to_target)


func update_ammo_label():
	ammo_label.text = "%d / %d" % [clip_amount,pouch_amount]


func _on_ShootCooldown_timeout():
	cooling_down = false


func _on_ReloadTimer_timeout():
	reload()
	update_ammo_label()
	reloading = false

func can_be_equipped():
	return pouch_amount > 0 or clip_amount > 0

func set_equipped(value : bool):
	if is_network_master:
		if value:
			update_ammo_label()
		else:
			cooldown_timer.stop()
			cooling_down = false
			reloading = false
			reload_timer.stop()
		equipped = value
		if equipped:
			for child in crosshair.get_parent().get_children():
				child.visible = false
			if crosshair:
				crosshair.visible = true
		
	visible = value


func add_ammo(amount):
	pouch_amount += amount
	if pouch_amount > pouch_size:
		pouch_amount = pouch_size
	if equipped:
		update_ammo_label()
	elif(clip_amount == 0):
		reload()


func force_state(clip,pouch):
	cooldown_timer.stop()
	reload_timer.stop()
	cooling_down = false
	reloading = false
	clip_amount = clip
	pouch_amount = pouch
