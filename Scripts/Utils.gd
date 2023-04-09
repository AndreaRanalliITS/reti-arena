extends Node


func read_json(json_path)->Dictionary:
	var file = File.new()
	file.open(json_path,File.READ)
	var content = file.get_as_text()
	content = JSON.parse(content).result
	file.close()
	return content

func connect_signals(source_node,dest_node,signals):
	var error
	for signl in signals:
		error = source_node.connect(signl,dest_node,signals[signl])
		if error != OK:
			return error
	return OK
