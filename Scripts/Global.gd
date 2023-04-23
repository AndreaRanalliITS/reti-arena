extends Node

enum PickupType {HEALTH_PACK, GUN_AMMO, BARRELGUN_AMMO, AK47_AMMO, SNIPER_AMMO}

# warning-ignore:unused_signal
signal instance_player(id)
# warning-ignore:unused_signal
signal toggle_network_setup(toggle)
# warning-ignore:unused_signal
signal match_started()
# warning-ignore:unused_signal
signal match_ended()
signal toggle_pause(toggle)

var server_name = ""
var avatars = null
var lobby_spawn_indexes = null
var game_spawn_indexes = null
var match_started = false
var can_pause = false
var paused = false

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


func _init():
	randomize()
	avatars = Utils.read_json("res://avatars.json")



func _ready():
	lobby_spawn_indexes = range(Network.max_clients)
	lobby_spawn_indexes.shuffle()
	game_spawn_indexes = range(Network.max_clients)
	game_spawn_indexes.shuffle()


func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel") and can_pause:
		paused = not paused
		emit_signal("toggle_pause",paused)
#		if mode == MenuMode.IN_GAME:
#			visible = not visible
#			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED)
#			tab_route.clear()
#			_change_tab(0)


#######################
##QUIT GAME BY PRESSING ESCAPE
#func _input(event):
#	if event is InputEventKey:
#		if event.scancode == KEY_ESCAPE:
#			get_tree().quit()
