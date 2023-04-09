extends Node


func read_json(json_path)->Dictionary:
	var file = File.new()
	file.open(json_path,File.READ)
	var content = file.get_as_text()
	content = JSON.parse(content).result
	file.close()
	return content