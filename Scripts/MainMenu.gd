extends HBoxContainer

export(int,0,999) var max_nickname_length = 15

var tab_route = []

onready var player_preview = get_node("../../PlayerPreview")
onready var left_menu = $Left
onready var nickname_error = $Left/Main/ErrorMessage
onready var nickname = $Left/Main/HBoxContainer/Nickname
onready var char_count = $Left/Main/HBoxContainer/CharCount
onready var show_host = $Left/Main/Host
onready var show_join = $Left/Main/Join
onready var manual_join_error = $Left/ManualSetup/ErrorMessage
onready var ip_address = $Left/ManualSetup/LineEdit
onready var server_name = $Left/HostSetup/ServerName
onready var character_name = $Right/Panel/HBoxContainer/VBoxContainer/MeshName
onready var character_idx = $Right/Panel/HBoxContainer/VBoxContainer/CharacterIdx


func _ready():
	Global.connect("toggle_network_setup",self,"_toggle_network_setup")
	nickname.max_length = max_nickname_length
	char_count.text = "{0}/{1}".format([nickname.text.length(),max_nickname_length])
	
	_select_character(0)


func _on_IpAddress_text_changed(_new_text):
	clear_error(manual_join_error)


func _on_Host_pressed():
	Network.create_server()
	Global.player_info.lobby_spawn_point = Global.lobby_spawn_indexes.pop_front()
	Global.player_info.game_spawn_point = Global.game_spawn_indexes.pop_front()
	Global.players_info[get_tree().get_network_unique_id()] = Global.player_info
	hide()
	Global.emit_signal("instance_player",get_tree().get_network_unique_id())


func _on_Join_pressed():
	Network.join_server()
	hide()


func _toggle_network_setup(toggle):
	visible = toggle



func _change_tab(tabIdx):
	tab_route.append(left_menu.current_tab)
	left_menu.current_tab = tabIdx



func _previous_tab():
	left_menu.current_tab = tab_route.pop_back()


func _on_Quit_pressed():
	get_tree().quit()


func _on_Nickname_text_changed(new_text):
	nickname.text = new_text.validate_node_name().strip_edges()
	char_count.text = "{0}/{1}".format([nickname.text.length(),max_nickname_length])
	nickname.caret_position = nickname.text.length()
	var allow_play = nickname.text.length() > 0
	show_host.disabled = !allow_play
	show_join.disabled = !allow_play
	server_name.text = nickname.text + "'s server"
	Global.server_name = server_name.text
	Global.player_info.name = nickname.text
	
	if allow_play:
		clear_error(nickname_error)
	else:
		show_error(nickname_error, "Nickname required")


func show_error(label,msg):
	label.text = msg


func clear_error(label):
	label.text = ""


func _on_ManualJoin_pressed():
	if !ip_address.text.is_valid_ip_address():
#		printerr("Invalid ip address: " + ip_address.text)
		show_error(manual_join_error,"Invalid ip address")
		return
	
	Network.ip_address = ip_address.text
	_on_Join_pressed()



func _join_from_card(ip):
	Network.ip_address = ip
	_on_Join_pressed()


func _select_character(dir):
	var avatar = Global.player_info.avatar
	avatar += dir
	if avatar < 0:
		avatar = Global.avatars.size()-1
	elif avatar >= Global.avatars.size():
		avatar = 0
	
	Global.player_info.avatar = avatar
	character_name.text = Global.avatars[avatar].name
	player_preview.mesh.material = load(Global.avatars[avatar].material)
	
	character_idx.text = "{0}/{1}".format([avatar+1,Global.avatars.size()])
