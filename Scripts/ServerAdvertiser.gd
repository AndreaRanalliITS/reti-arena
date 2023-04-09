extends Node


export(float) var broadcast_interval = 1.0
var server_info = {
	"name": "string",
	"player_count" : 11
}

var socket_udp
var broadcast_port = Network.DEFAULT_PORT

func _enter_tree():
	if get_tree().is_network_server():
		server_info.name = Global.server_name
		socket_udp = PacketPeerUDP.new()
		socket_udp.set_broadcast_enabled(true)
		socket_udp.set_dest_address("255.255.255.255",broadcast_port)


func _exit_tree():
	if socket_udp != null:
		socket_udp.close()


func _on_BroadcastTimer_timeout():
	server_info.player_count = 1
	var packet_message = to_json(server_info)
	var packet = packet_message.to_ascii()
	socket_udp.put_packet(packet)
