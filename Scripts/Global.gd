extends Node

enum PickupType {HEALTH_PACK, GUN_AMMO, BARRELGUN_AMMO, AK47_AMMO,SNIPER_AMMO}

signal instance_player(id)
signal toggle_network_setup(toggle)

var server_name = ""
var avatars = null
var lobby_spawn_indexes = null
var game_spawn_indexes = null

var player_info = {
	"name" : "John Doe",
	"avatar" : 0,
	"ready" : false,
	"lobby_spawn_point" : -1,
	"game_spawn_point" : -1
}

var players_info = {}


func _ready():
	randomize()
	avatars = Utils.read_json("res://avatars.json")
	lobby_spawn_indexes = range(Network.MAX_CLIENTS)
	lobby_spawn_indexes.shuffle()
	game_spawn_indexes = range(Network.MAX_CLIENTS)
	game_spawn_indexes.shuffle()


#######################
##QUIT GAME BY PRESSING ESCAPE
func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE:
			get_tree().quit()
