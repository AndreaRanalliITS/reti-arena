extends Node

var DEFAULT_PORT = 28960
var DEFAULT_MAX_CLIENTS = 5

var server = null
var client = null
var port = null
var max_clients = null

var ip_address = "127.0.0.1"

var connection_signals = {
	"connected_to_server": "_connected_to_server",
	"server_disconnected": "_server_disconnected",
	"connection_failed": "_connection_failed",
	"network_peer_connected": "_player_connected"
}


func _init():
	port = Utils.get_setting("server_confs", "port",DEFAULT_PORT)
	max_clients = Utils.get_setting("server_confs", "max_clients",DEFAULT_MAX_CLIENTS)



func _ready():
	var error = Utils.connect_signals(get_tree(),self,connection_signals)
	if error != OK:
		printerr(error)


func create_server():
	print("Creating server")
	server = NetworkedMultiplayerENet.new()
	var error = server.create_server(port,max_clients)
	if error == OK:
		get_tree().set_network_peer(server)
		return true
	print_debug(error)
	return false


func join_server():
	print("Joining server")
	client = NetworkedMultiplayerENet.new()
	var error = client.create_client(ip_address,port)
	if error == OK:
		get_tree().set_network_peer(client)
		return true
	print_debug(error)
	return false


func _connected_to_server():
	pass#print("Connected to server")


func _server_disconnected():
	print("Server disconnected")
	
	reset_network_connection()


func _connection_failed():
	printerr("Connection to server failed")
	
	reset_network_connection()


func reset_network_connection():
	if get_tree().has_network_peer():
		get_tree().network_peer = null


func _player_connected(_id):
	pass#print("Player "+str(id)+" connected")
