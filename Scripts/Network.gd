extends Node

const DEFAULT_PORT = 28960
const MAX_CLIENTS = 5

var server = null
var client = null

var ip_address = "127.0.0.1"



func _ready():
	get_tree().connect("connected_to_server",self,"_connected_to_server")
	get_tree().connect("server_disconnected",self,"_server_disconnected")
	get_tree().connect("connection_failed",self,"_connection_failed")
	get_tree().connect("network_peer_connected",self,"_player_connected")
	


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


func _player_connected(id):
	pass#print("Player "+str(id)+" connected")
