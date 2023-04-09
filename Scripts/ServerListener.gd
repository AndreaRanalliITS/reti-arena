extends VBoxContainer


signal new_server
signal remove_server


var socket_udp = PacketPeerUDP.new()
var listen_port = Network.DEFAULT_PORT
var known_servers = {}

export(int) var server_cleanup_threshold = 3
export(NodePath) onready var cleanup_timer = get_node(cleanup_timer) as Timer
export(NodePath) onready var server_card_list = get_node(server_card_list) as VBoxContainer


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
		
		if not known_servers.has(server_ip):
			var server_message = array_bytes.get_string_from_ascii()
			var game_info = parse_json(server_message)
			game_info.ip = server_ip
			game_info.lastSeen = OS.get_unix_time()
			known_servers[server_ip] = game_info
			emit_signal("new_server",game_info)
			print(socket_udp.get_packet_ip())
		else:
			var game_info = known_servers[server_ip]
			game_info.lastSeen = OS.get_unix_time()



func _exit_tree():
	socket_udp.close()



func _on_CleanupTimer_timeout():
	var now = OS.get_unix_time()
	for server_ip in known_servers:
		var server_info = known_servers[server_ip]
		if(now - server_info.lastSeen) > server_cleanup_threshold:
			known_servers.erase(server_ip)
			print("Removing server from list: " + server_ip)
			emit_signal("remove_server",server_ip)


func _on_ServerList_visibility_changed():
	if is_visible_in_tree():
		cleanup_timer.start()
		if socket_udp.listen(listen_port) != OK:
			printerr("GameServer LAN service: Error listening on port " + str(listen_port))
		else:
			print("GameServer LAN service: listening on port " + str(listen_port))
	else:
		cleanup_timer.stop()
		socket_udp.close()
