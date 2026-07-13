extends Control
var dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)+"/sandboxdata"
var worldbutton = preload("res://worldbutton.tscn")
var world = preload("res://main.tscn")
func _ready() -> void:
	var worlds = global.data.worlds.duplicate()
	var ks = worlds.keys()
	ks.reverse()
	for i in ks:
		var b = worldbutton.instantiate()
		var texture
		if FileAccess.file_exists(dir+"/"+i+"/screenshot.png"):
			texture = ImageTexture.create_from_image(Image.load_from_file(dir+"/"+i+"/screenshot.png"))
		else:
			texture = load("res://textures/1774075168004.jpg")
		b.get_node("H/VBoxContainer/Label").text = i
		b.get_node("H/TextureRect").texture = texture 
		$MarginContainer/PanelContainer/VBoxContainer/MarginContainer/PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer.add_child(b)
		b.get_node("H").gui_input.connect(world_input.bind(i))
func world_input(event: InputEvent, name):
	if event is InputEventScreenTouch:
		if event.pressed:
			open_world(name)

func add_world():
	$MarginContainer/PanelContainer2.show()
	


func create() -> void:
	var nt = $MarginContainer/PanelContainer2/VBoxContainer/MarginContainer/PanelContainer/VBoxContainer/HBoxContainer/LineEdit.text
	var st = int($MarginContainer/PanelContainer2/VBoxContainer/MarginContainer/PanelContainer/VBoxContainer/HBoxContainer2/LineEdit.text)
	if !st:
		st = randi()
	global.data.worlds.set(nt,{"seed":st})
	global.save()
	open_world(nt)
func open_world(name):
	var w = world.instantiate()
	w.get_node("Node2D/CharacterBody2D").mainseed = global.data.worlds[name].seed
	w.get_node("Node2D/CharacterBody2D").name = name
	get_tree().change_scene_to_node(w)
