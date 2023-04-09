extends Node

var DEFAULT_PORT = 28960
var MAX_CLIENTS = 5

var server = null
var client = null

var ip_address = "127.0.0.1"

var connection_signals = {
	"connected_to_server": "_connected_to_server",
	"server_disconnected": "_server_disconnected",
	"connection_failed": "_connection_failed",
	"network_peer_connected": "_player_connected"
}


func _init():
	var server_confs = Utils.read_json("res://server.conf")
	DEFAULT_PORT = server_confs.port
	MAX_CLIENTS = server_confs.max_clients


func _ready():
	var error = Utils.connect_signals(get_tree(),self,connection_signals)
	if error != OK:
		printerr(error)


func create_server():
	print("Creating server")
	server = NetworkedMultiplayerENet.new()
	server.create_server(DEFAULT_PORT,MAX_CLIENTS)
	get_tree().set_network_peer(server)


func join_server():
	print("Joining server")
	client = NetworkedMultiplayerENet.new()
	client.create_client(ip_address,DEFAULT_PORT)
	get_tree().set_network_peer(client)


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
