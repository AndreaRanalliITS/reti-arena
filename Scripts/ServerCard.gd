extends Panel


var ip_address = ""


func _on_Join_pressed():
	get_node("%MainMenu")._join_from_card(ip_address)
