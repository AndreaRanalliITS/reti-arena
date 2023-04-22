extends Node

enum PickupType {HEALTH_PACK, GUN_AMMO, BARRELGUN_AMMO, AK47_AMMO, SNIPER_AMMO}

# warning-ignore:unused_signal
signal instance_player(id)
# warning-ignore:unused_signal
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
	"game_spawn_point" : -1,
	"deaths":0,
	"kills":0
}

var players_info = {}

func _ready():
	lobby_spawn_indexes = range(Network.max_clients)
	lobby_spawn_indexes.shuffle()
	game_spawn_indexes = range(Network.max_clients)
	game_spawn_indexes.shuffle()

func _init():
	randomize()
	avatars = Utils.read_json("res://avatars.json")
	


#######################
##QUIT GAME BY PRESSING ESCAPE
func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE:
			get_tree().quit()
