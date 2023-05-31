extends Spatial

export(NodePath) onready var ready_players_label = get_node(ready_players_label) as Label3D
export(NodePath) onready var lobby_spawn_points = get_node(lobby_spawn_points).get_children() as Array
export(NodePath) onready var game_spawn_points = get_node(game_spawn_points).get_children() as Array
export(NodePath) onready var music_player = get_node(music_player) as AudioStreamPlayer
export(AudioStream) var menu_music
export(AudioStream) var combat_music

var player_scene = preload("res://Scenes/Player.tscn")
var can_change_ready_status = false

var tree_connection_signals = {
	"network_peer_connected": "_player_connected",
	"network_peer_disconnected": "_player_disconnected",
	"connected_to_server": "_connected_ok",
	"connection_failed": "_connected_fail",
	"server_disconnected": "_server_disconnected"
}

var global_connection_signals = {
	"instance_player": "_instance_player",
	"match_ended": "_end_match"
}

func _ready():
	music_player.stream = menu_music
	music_player.play()
	var error = Utils.connect_signals(get_tree(),self,tree_connection_signals)
	if error != OK:
		printerr(error)
	error = Utils.connect_signals(Global,self,global_connection_signals)
	if error != OK:
		printerr(error)
	
	if get_tree().network_peer != null:
		Global.emit_signal("toggle_network_setup",false)




func _process(_delta):
	if Input.is_action_just_pressed("toggle_ready_state") && \
	not Global.match_on && \
	get_tree().network_peer != null && \
	Global.players_info.size() >= 2:
		rpc("_update_player_ready_state",get_tree().get_network_unique_id())



func _player_connected(id):
	print("Player "+ str(id) + " connected")
	rpc_id(id,"register_player",Global.player_info)


remote func register_player(info):
	var id = get_tree().get_rpc_sender_id()
	# log_info("added player_scene\n"+str(Global.players_info))

	#if server, tell the client to spawn his own player_scene
	if get_tree().get_network_unique_id() == 1:
		info.lobby_spawn_point = Global.lobby_spawn_indexes.pop_front()
		info.game_spawn_point = Global.game_spawn_indexes.pop_front()
		rpc_id(id,"receive_info_from_server_and_spawn",info)
	Global.players_info[id] = info
	# instance client player
	_instance_player(id)
	

func _connected_fail():
	print("Connection failed")

func _connected_ok():
	print("Connected to server")
	pass # Only called on clients, not server. Will go unused; not useful here.

func _server_disconnected():
	print("Disconnected from server")
	pass # Server kicked us; show error and abort.

func _player_disconnected(id):
	print("Player {0} disconnected".format([id]))
	if has_node(str(id)):
		get_node(str(id)).queue_free()
	Global.players_info.erase(id)
	update_ready_label()

remote func receive_info_from_server_and_spawn(updated_info):
	Global.player_info = updated_info
	Global.players_info[get_tree().get_network_unique_id()] = Global.player_info
	_instance_player(get_tree().get_network_unique_id())
	Global.can_pause = true
	


remotesync func _update_player_ready_state(player_id):
	if Global.players_info.has(player_id):
		Global.players_info[player_id].ready = !Global.players_info[player_id].ready
		update_ready_label()


remote func _instance_player(id):
	music_player.stop()
#	log_info("instancing player_scene "+str(id)+"\n"+str(Global.players_info[id]))
	var player_inst = player_scene.instance()
	player_inst.set_network_master(id)
	player_inst.name = str(id)
	
	add_child(player_inst)
	player_inst.invincible = true
	
	if player_inst.is_network_master():
		player_inst.add_to_group("Players")
		can_change_ready_status = true
#		player_inst._toggle_spec_mode(true)

	if !player_inst.is_network_master():
		player_inst.update_mesh_material(Global.players_info[id].avatar)
	
	var spawn_point = lobby_spawn_points[Global.players_info[id].lobby_spawn_point]
	player_inst.global_transform.origin = spawn_point.transform.origin
	player_inst.global_rotation = spawn_point.global_rotation

	update_ready_label()


func update_ready_label():
	var text = ""
	for key in Global.players_info:
		var check = "X" if Global.players_info[key].ready else " "
		text += "[{0}] {1}\n".format([check,Global.players_info[key].name])
	ready_players_label.text = text

	#if is server, check if all player_scene are ready
	if get_tree().get_network_unique_id() == 1 and everyone_is_ready():
#		log_info("EVERYONE IS READY")
		rpc("start_match")


func everyone_is_ready()->bool:
	for key in Global.players_info:
		if not Global.players_info[key].ready:
			return false
	return true


remotesync func start_match():
	get_tree().refuse_new_network_connections = true
	
	#reset counters
	for key in Global.players_info:
		Global.players_info[key].deaths = 0
		Global.players_info[key].kills = 0
	
	music_player.stop()
	music_player.stream = combat_music
	music_player.play(42.10)
	
	var player = get_node(str(get_tree().get_network_unique_id()))
	
	#move everyone to their match start positions
	var spawn_point = game_spawn_points[Global.player_info.game_spawn_point]
	player.global_transform.origin = spawn_point.transform.origin
	player.global_rotation = spawn_point.global_rotation
	player.reset_state()
	player.invincible = false
	
	Global.emit_signal("match_started")


func _end_match():
	get_tree().refuse_new_network_connections = false
	
	#reset counters
	for key in Global.players_info:
		Global.players_info[key].deaths = 0
		Global.players_info[key].kills = 0
		Global.players_info[key].ready = false
	
	update_ready_label()
	music_player.stop()
	
	var player = get_node(str(get_tree().get_network_unique_id()))
	
	#move everyone to their lobby start positions
	var spawn_point = lobby_spawn_points[Global.player_info.lobby_spawn_point]
	player.global_transform.origin = spawn_point.transform.origin
	player.global_rotation = spawn_point.global_rotation
	player.reset_state(range(player.hand.weapons.size()))
	player._toggle_spec_mode(false)
	player.invincible = true

func log_info(message:String):
	print("[{0}] {1}".format([get_tree().get_network_unique_id(),message]))
