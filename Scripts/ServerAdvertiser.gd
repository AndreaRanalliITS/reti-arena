extends Node

export(NodePath) onready var broadcast_timer = get_node(broadcast_timer) as Timer
export(float) var broadcast_interval = 1.0


var server_info = {
	"name": "string",
	"player_count" : 0,
	"max_player_count": 5,
	"time_sent_UTC": 0.0
}

var socket_udp
var broadcast_port = Network.DEFAULT_PORT


func _ready():
	broadcast_timer.wait_time = broadcast_interval
	Global.connect("hosting_started",self,"_start_advertising")



func _exit_tree():
	if socket_udp != null:
		socket_udp.close()


func _start_advertising():
	if get_tree().is_network_server():
		broadcast_timer.start()
		server_info.name = Global.server_name
		socket_udp = PacketPeerUDP.new()
		socket_udp.set_broadcast_enabled(true)
		socket_udp.set_dest_address("255.255.255.255",broadcast_port)

func _stop_advertising():
	broadcast_timer.stop()
	if socket_udp != null:
		socket_udp.close()
	

func _on_BroadcastTimer_timeout():
	server_info.player_count = Global.players_info.size()
	server_info.max_player_count = Utils.get_setting("server_confs","max_clients")
	server_info.time_sent_UTC = Time.get_unix_time_from_system()
	var packet_message = to_json(server_info)
	var packet = packet_message.to_ascii()
	socket_udp.put_packet(packet)
