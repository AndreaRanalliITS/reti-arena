extends VBoxContainer


var socket_udp = PacketPeerUDP.new()
var listen_port = Network.DEFAULT_PORT
var known_servers = {}

export(int) var server_cleanup_threshold = 3
export(NodePath) onready var cleanup_timer = get_node(cleanup_timer) as Timer
export(NodePath) onready var server_card_list = get_node(server_card_list) as VBoxContainer
export(Resource) var card_template


func _ready():
	known_servers.clear()


func _process(_delta):
	if socket_udp.get_available_packet_count() > 0:
		var server_ip = socket_udp.get_packet_ip()
		var server_port = socket_udp.get_packet_port()
		var array_bytes = socket_udp.get_packet()
		
		if server_ip.empty() or server_port <= 0:
			printerr("invalid ip or port: " + str(server_ip) + ":" + str(server_port))
			return
		
		var server_message = array_bytes.get_string_from_ascii()
		var game_info = parse_json(server_message)
		game_info.ip_address = server_ip
		game_info.lastSeen = OS.get_unix_time()
		known_servers[server_ip] = game_info
		if not known_servers.has(server_ip):
			create_card(game_info)
			print_debug(socket_udp.get_packet_ip())
		else:
			update_card(game_info)


func create_card(info):
	var new_card = card_template.instance()
	new_card.name = info.ip_address.validate_node_name()
	server_card_list.add_child(new_card)
	new_card.server_info = info

func update_card(info):
	var card_to_update = server_card_list.get_node(info.ip_address.validate_node_name())
	card_to_update.server_info = info

func remove_card(info):
	var card_to_remove = server_card_list.get_node(info.ip_address.validate_node_name())
	card_to_remove.queue_free()


func _exit_tree():
	socket_udp.close()



func _on_CleanupTimer_timeout():
	var now = OS.get_unix_time()
	for server_ip in known_servers:
		var server_info = known_servers[server_ip]
		if(now - server_info.lastSeen) > server_cleanup_threshold:
			known_servers.erase(server_ip)
			print_debug("Removing server from list: " + server_ip)
			remove_card(server_info)
#			emit_signal("remove_server",server_ip)


func _on_ServerList_visibility_changed():
	if is_visible_in_tree():
		cleanup_timer.start()
		if socket_udp.listen(listen_port) != OK:
			printerr("GameServer LAN service: Error listening on port " + str(listen_port))
		else:
			print_debug("GameServer LAN service: listening on port " + str(listen_port))
	else:
		cleanup_timer.stop()
		socket_udp.close()
