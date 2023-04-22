extends Node

var settings_path = "res://settings.ini"
var settings


func _init():
	settings = ConfigFile.new()
	var _err = settings.load(settings_path)

func get_setting(section,key,default):
	var value = settings.get_value(section,key,default)
	settings.set_value(section,key,value)
	settings.save(settings_path)
	return value
	
func set_setting(section,key,value):
	settings.set_value(section,key,value)
	settings.save(settings_path)

#func get_settings(path="res://settings.ini"):	
#	var config = ConfigFile.new()
#	# Load data from a file.
#	var _err = config.load(path)
#	return config

#func save_settings(settings,path="res://settings.ini"):
#	settings.save(path)

func read_json(json_path)->Dictionary:
	var file = File.new()
	file.open(json_path,File.READ)
	var content = file.get_as_text()
	content = JSON.parse(content).result
	file.close()
	return content
#
#func save_json(json_path,content):
#	var file = File.new()
#	file.open(json_path,File.WRITE)
#	var json_string = JSON.print(content)
#	file.store_string(json_string)
#	file.close()



func connect_signals(source_node,dest_node,signals):
	var error
	for signl in signals:
		error = source_node.connect(signl,dest_node,signals[signl])
		if error != OK:
			return error
	return OK
