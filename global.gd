extends Node
var data : Dictionary 
var dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)+"/sandboxdata"
func _ready() -> void:
	if !DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_absolute(dir)
	var file = FileAccess.open(dir+"/825", FileAccess.READ_WRITE)
	if file.get_length():
		data = file.get_var()
		print(data)
	else:
		data = {
			"worlds":{},
			"settings":{},
			"furries":{}
		}
		file.store_var(data)
		print("new")
func save():
	var file = FileAccess.open(dir+"/825", FileAccess.WRITE)
	file.store_var(data)
	
