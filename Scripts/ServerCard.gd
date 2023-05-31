extends Panel

export(NodePath) var server_name = get_node(server_name) as Label
export(NodePath) var players = get_node(players) as Label
export(NodePath) var ping = get_node(ping) as Label

var server_info setget set_server_info

func _enter_tree():
	update_labels()

func _on_Join_pressed():
	get_node("%MainMenu")._join_from_card(server_info.ip_address)


func set_server_info(info):
	var ping_seconds = str(OS.get_unix_time_from_system() - info.time_sent_UTC)
	info.ping = ping_seconds.rsplit(".",false)[1].substr(0,3)
	server_info = info
	update_labels()



func update_labels():
	server_name.text = server_info.name
	players.text = "{0}/{1}\nplayers".format([server_info.player_count,server_info.max_player_count])
	ping.text = "{0} ms".format([server_info.ping])
