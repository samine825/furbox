extends CharacterBody2D

var iaminchunk = Vector2(0,0)
var viewdistance = 3
var current_chunks = []
var mainseed = 825
var display_chunks = false
var SPEED = 500

var biomes := {
	"snowy_plains": [1.0/6.0, 1.0/6.0],
	"taiga": [0.5, 1.0/6.0],
	"snowy_taiga": [5.0/6.0, 1.0/6.0],
	"plains": [1.0/6.0, 0.5],
	"forest": [0.5, 0.5],
	"swamp": [5.0/6.0, 0.5],
	"desert": [1.0/6.0, 5.0/6.0],
	"savanna": [0.5, 5.0/6.0],
	"jungle": [5.0/6.0, 5.0/6.0],
}
var biomeblocks := {
	"snowy_plains": "snow",
	"taiga": "grass",
	"snowy_taiga": "snow",
	"plains": "grass",
	"forest": "grass",
	"swamp": "grass",
	"desert": "sand",
	"savanna": "grass",
	"jungle": "grass"
}

var flower_textures: Array[Texture2D] = [
	preload("res://textures/flowers/flower_allium.png"),
	preload("res://textures/flowers/flower_paeonia.png"),
	preload("res://textures/flowers/flower_blue_orchid.png"),
	preload("res://textures/flowers/flower_rose.png"),
	preload("res://textures/flowers/flower_cornflower.png"),
	preload("res://textures/flowers/flower_rose_blue.png"),
	preload("res://textures/flowers/flower_dandelion.png"),
	preload("res://textures/flowers/flower_tulip_orange.png"),
	preload("res://textures/flowers/flower_houstonia.png"),
	preload("res://textures/flowers/flower_tulip_pink.png"),
	preload("res://textures/flowers/flower_lily_of_the_valley.png"),
	preload("res://textures/flowers/flower_tulip_red.png"),
	preload("res://textures/flowers/flower_oxeye_daisy.png"),
	preload("res://textures/flowers/flower_tulip_white.png")
]

var flower_block_names: Array[String] = [
	"flower_allium",
	"flower_paeonia",
	"flower_blue_orchid",
	"flower_rose",
	"flower_cornflower",
	"flower_rose_blue",
	"flower_dandelion",
	"flower_tulip_orange",
	"flower_houstonia",
	"flower_tulip_pink",
	"flower_lily_of_the_valley",
	"flower_tulip_red",
	"flower_oxeye_daisy",
	"flower_tulip_white"
]

var blocks: Dictionary = {
	#"water":        {"type": "tilemap", "terrain_set": 0, "terrain": 0,  "side_atlas_coords": Vector2i(4,4)},
	"snow":          {"type": "tilemap", "terrain_set": 0, "terrain": 2,  "side_atlas_coords": Vector2i(4,4), "tilemap":6},
	"planks":        {"type": "tilemap", "terrain_set": 0, "terrain": 1,  "side_atlas_coords": Vector2i(4,4), "tilemap":4},
	"cobblestone":   {"type": "tilemap", "terrain_set": 0, "terrain": 0,  "side_atlas_coords": Vector2i(4,4), "tilemap":2},
	"grass":         {"type": "tilemap", "terrain_set": 0, "terrain": 3,  "side_atlas_coords": Vector2i(4,4), "tilemap":3},
	"sand":          {"type": "tilemap", "terrain_set": 0, "terrain": 4,  "side_atlas_coords": Vector2i(4,4), "tilemap":5},
	#"swamp":        {"type": "tilemap", "terrain_set": 0, "terrain": 0,  "side_atlas_coords": Vector2i(4,4)},
	#"desert":       {"type": "tilemap", "terrain_set": 0, "terrain": 0,  "side_atlas_coords": Vector2i(4,4)},
	#"savanna":      {"type": "tilemap", "terrain_set": 0, "terrain": 0,  "side_atlas_coords": Vector2i(4,4)},
	#"jungle":       {"type": "tilemap", "terrain_set": 0, "terrain": 0,  "side_atlas_coords": Vector2i(4,4)},
	#"dirt":         {"type": "tilemap", "terrain_set": 0, "terrain": 0, "side_atlas_coords": Vector2i(4,4)},
	
	"tree": {
		"type": "sprite",
		"texture": preload("res://textures/trees/tree.png"),
		"offset": Vector2(-24, -48),
		"centered": false
	}
}

var noiseH #oceans
var noiseH2 #rivers
var noise1 #temp
var noise2 #vlaznost
var noise3 #trees
var noise4 #flowers color
var noise5 #flowers 

var worker_thread: Thread
var queue_mutex: Mutex
var finished_mutex: Mutex
var semaphore: Semaphore
var chunk_queue: Array = []
var finished_chunks: Array = []
var worker_running := true

var mode = 0 
var dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)+"/sandboxdata"

var tilemap_layers: Array[TileMapLayer] = []

var textures = [
	preload("res://Untitled.png"),
	preload("res://Untitled2.png"),
	preload("res://Untitled3.png"),
	preload("res://Untitled4.png"),
]

func _ready() -> void:
	print(mainseed," ",name)
	if !DirAccess.dir_exists_absolute(dir+"/"+name):
		DirAccess.make_dir_absolute(dir+"/"+name)
	
	for i in range(flower_block_names.size()):
		blocks[flower_block_names[i]] = {
			"type": "sprite",
			"texture": flower_textures[i],
			"offset": Vector2(0, 0),
			"centered": false
		}
	
	tilemap_layers = [$"../ground", $"../ground2"]
	
	noiseH = FastNoiseLite.new()
	noiseH.seed = mainseed
	noiseH.frequency = 0.005
	noiseH.fractal_gain = 0.6
	noiseH.noise_type = FastNoiseLite.TYPE_CELLULAR
	noiseH2 = FastNoiseLite.new()
	noiseH2.seed = mainseed
	noiseH2.frequency = 0.01
	noiseH2.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	noiseH2.fractal_gain = -0.15
	noiseH2.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise1 = FastNoiseLite.new()
	noise1.seed = mainseed + 1
	noise1.frequency = 0.005
	noise2 = FastNoiseLite.new()
	noise2.seed = mainseed + 2
	noise2.frequency = 0.005
	noise3 = FastNoiseLite.new()
	noise3.seed = mainseed
	noise3.frequency = 1.0
	noise4 = FastNoiseLite.new()
	noise4.seed = mainseed + 3
	noise4.frequency = 0.02
	noise4.fractal_type = FastNoiseLite.FRACTAL_NONE
	noise5 = FastNoiseLite.new()
	noise5.seed = mainseed + 4
	noise5.frequency = 0.05
	noise5.fractal_gain = 4.0
	
	queue_mutex = Mutex.new()
	finished_mutex = Mutex.new()
	semaphore = Semaphore.new()
	worker_thread = Thread.new()
	worker_thread.start(_worker)
	updater()
	get_tree().set_auto_accept_quit(false)

func _physics_process(_delta: float) -> void:
	$"../../CanvasLayer/ScrollContainer2".scroll_vertical = INF
	var vec = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = vec * SPEED
	move_and_slide()
	if vec.x > 0.5:
		$Sprite2D.texture = textures[2]
	elif vec.x < -0.5:
		$Sprite2D.texture = textures[0]
	elif vec.y > 0.5:
		$Sprite2D.texture = textures[1]
	elif vec.y < -0.5:
		$Sprite2D.texture = textures[3]
	if vec:
		$GPUParticles2D.emitting = true
	else:
		$GPUParticles2D.emitting = false
	
	var chunk_pixel_size = int(16 * $"../ground".scale.x * $"../ground".tile_set.tile_size.x)
	var current_chunk_x = floor(global_position.x / chunk_pixel_size)
	var current_chunk_y = floor(global_position.y / chunk_pixel_size)
	if current_chunk_x != iaminchunk.x or current_chunk_y != iaminchunk.y:
		iaminchunk = Vector2(current_chunk_x, current_chunk_y)
		updater()
	_process_finished_chunks()
	$"../../CanvasLayer2/ColorRect".material["shader_parameter/num_loaded"] = current_chunks.slice(0,1024).size() - chunk_queue.size()
	$"../../CanvasLayer2/ColorRect".material["shader_parameter/loaded_chunks"] = current_chunks.slice(0,1024)
	$"../../CanvasLayer2/ColorRect".material["shader_parameter/camera_zoom"] = $Camera2D.zoom
	$"../../CanvasLayer2/ColorRect".material["shader_parameter/camera_position"] = $Camera2D.global_position
	$"../../CanvasLayer2/ColorRect".material["shader_parameter/viewport_size"] =  get_viewport_rect().size

func _enqueue_chunk(cords: Vector2i):
	queue_mutex.lock()
	chunk_queue.append(cords)
	queue_mutex.unlock()
	semaphore.post()

func _worker(_userdata = null) -> void:
	while worker_running:
		semaphore.wait()
		if not worker_running: break
		var cords = null
		queue_mutex.lock()
		if chunk_queue.size() > 0:
			cords = chunk_queue.pop_front()
		queue_mutex.unlock()
		if cords != null:
			var data = _generate_chunk_data(cords)
			finished_mutex.lock()
			finished_chunks.append({"cords": cords, "data": data})
			finished_mutex.unlock()

var chunk_data = {}

func _process_finished_chunks():
	var pending := []
	finished_mutex.lock()
	if finished_chunks.size() > 0:
		pending = finished_chunks.duplicate()
		finished_chunks.clear()
	finished_mutex.unlock()
	for item in pending:
		_apply_chunk(item.data, item.cords)

func _apply_chunk(data: Dictionary, cords: Vector2i):
	if !(cords.x >= iaminchunk.x-viewdistance and cords.x <= iaminchunk.x+viewdistance) or !(cords.y >= iaminchunk.y-viewdistance and cords.y <= iaminchunk.y+viewdistance):
		return
	
	var chunk_container = _get_or_create_chunk_container(cords)
	
	var terrain_groups: Dictionary = {}
	
	for entry in data["chunks"]:
		var block_name: String = entry["block"]
		if not blocks.has(block_name): continue
		var def = blocks[block_name]
		var pos = entry["pos"]
		var layer_idx: int = entry["layer"]
		var layer = tilemap_layers[layer_idx]
		
		if def.type == "tilemap":
			if not terrain_groups.has(layer_idx):
				terrain_groups[layer_idx] = {}
			if not terrain_groups[layer_idx].has(def.terrain):
				terrain_groups[layer_idx][def.terrain] = []
			terrain_groups[layer_idx][def.terrain].append(pos)
			
			var below = Vector2i(pos.x, pos.y + 1)
			if layer.get_cell_source_id(below) == -1:
				layer.set_cell(below, def.tilemap, def.side_atlas_coords)
		
		elif def.type == "sprite":
			if not _has_sprite_at(chunk_container, pos):
				var sprite = Sprite2D.new()
				sprite.texture = def.texture
				sprite.scale = Vector2(5, 5)
				sprite.position = Vector2(pos.x * 16 * $"../ground".scale.x, pos.y * 16 * $"../ground".scale.y)
				sprite.centered = def.get("centered", false)
				sprite.offset = def.get("offset", Vector2.ZERO)
				chunk_container.add_child(sprite)
	
	for layer_idx in terrain_groups:
		var layer = tilemap_layers[layer_idx]
		for terrain in terrain_groups[layer_idx]:
			layer.set_cells_terrain_connect(terrain_groups[layer_idx][terrain], 0, terrain, false)

func _get_or_create_chunk_container(cords: Vector2i) -> Node2D:
	var chname = "%sx%s" % [cords.x, cords.y]
	if !$"../chunks".has_node(chname):
		var container = Node2D.new()
		container.name = chname
		$"../chunks".add_child(container)
		return container
	return $"../chunks".get_node(chname) as Node2D

func _has_sprite_at(container: Node2D, pos: Vector2i) -> bool:
	for child in container.get_children():
		if child is Sprite2D and Vector2(pos) == floor(child.position / (16.0 * 5.0)):
			return true
	return false

func _delete_chunk(cords: Vector2i):
	var start_pos = Vector2i(cords.x * 16, cords.y * 16)
	for layer in tilemap_layers:
		for x in range(16):
			for y in range(16):
				layer.erase_cell(start_pos + Vector2i(x, y))
	
	var chname = "%sx%s" % [cords.x, cords.y]
	var container = $"../chunks".get_node_or_null(chname)
	if container:
		container.queue_free()

func updater():
	for i in $"../chunkborders".get_children():
		i.queue_free()
	
	var desired_chunks = get_spiral_chunks(Vector2i(iaminchunk), viewdistance)
	
	var to_unload = []
	for chunk in current_chunks:
		if chunk not in desired_chunks:
			to_unload.append(chunk)
	
	var to_load = []
	for chunk in desired_chunks:
		if chunk not in current_chunks:
			to_load.append(chunk)
	
	for chunk in to_unload:
		_delete_chunk(chunk)
	
	for chunk in to_load:
		_enqueue_chunk(chunk)
	
	current_chunks = desired_chunks.duplicate()
	
	if display_chunks:
		for c in desired_chunks:
			var rect = ReferenceRect.new()
			rect.editor_only = false
			rect.global_position = Vector2(c.x, c.y) * 16 * 16 * $"../ground".scale 
			rect.size = Vector2(16, 16) * 16 * $"../ground".scale 
			rect.border_width = 8
			if c == Vector2i(iaminchunk):
				rect.border_color = Color.GREEN
				rect.z_index = 10
			$"../chunkborders".add_child(rect)

func get_biome(humidity: float, temperature: float) -> String:
	var closest_biome := ""
	var closest_dist := INF
	for b in biomes.keys():
		var bh = biomes[b][0]
		var bt = biomes[b][1]
		var dist = pow(humidity - bh, 2) + pow(temperature - bt, 2)
		if dist < closest_dist:
			closest_dist = dist
			closest_biome = b
	return closest_biome

func get_spiral_chunks(center: Vector2i, radius: int) -> Array:
	var result: Array = []
	var x = 0; var y = 0; var dx = 0; var dy = -1
	var max_size = (radius * 2 + 1) * (radius * 2 + 1)
	for i in range(max_size):
		if x ** 2 + y ** 2 <= radius ** 2 + 5:
			result.append(center + Vector2i(x, y))
		if x == y or (x < 0 and x == -y) or (x > 0 and x == 1 - y):
			var temp = dx; dx = -dy; dy = temp
		x += dx; y += dy
	return result

var lastpos
func tilemap_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var pos: Vector2 = floor((position + (event.position - get_viewport_rect().size/2.0) / $Camera2D.zoom) / (5.0*16.0))
		if lastpos and lastpos != pos:
			cell_press(pos)
		lastpos = pos
	if event is InputEventScreenTouch:
		if event.pressed:
			var pos: Vector2 = floor((position + (event.position - get_viewport_rect().size/2.0) / $Camera2D.zoom) / (5.0*16.0))
			cell_press(pos)
			lastpos = Vector2(event.position)
		else:
			lastpos = null

func _on_h_slider_value_changed(value: float) -> void:
	value = 1/value
	$Camera2D.zoom = Vector2(value,value)

func _on_h_slider_2_value_changed(value: float) -> void:
	viewdistance = int(value)

@onready var modes_nodes =[$"../../CanvasLayer/ScrollContainer/VBoxContainer2/Button3", $"../../CanvasLayer/ScrollContainer/VBoxContainer2/Button4", $"../../CanvasLayer/ScrollContainer/VBoxContainer2/Button5"]
func interaction_mode() -> void:
	mode = 0
	for i in modes_nodes: i.modulate = Color(1,1,1,0.5) if i != modes_nodes[mode] else Color.WHITE
func place_mode() -> void:
	mode = 1
	for i in modes_nodes: i.modulate = Color(1,1,1,0.5) if i != modes_nodes[mode] else Color.WHITE
func break_mode() -> void:
	mode = 2
	for i in modes_nodes: i.modulate = Color(1,1,1,0.5) if i != modes_nodes[mode] else Color.WHITE

func _update_chunk_cache(pos: Vector2i, layer: int, block: String = "") -> void:
	var chunk_x := floor(pos.x / 16.0) as int
	var chunk_y := floor(pos.y / 16.0) as int
	var super_x := floor(chunk_x / 16.0) as int
	var super_y := floor(chunk_y / 16.0) as int
	var dataname := "%s_%s" % [super_x, super_y]
	var chunkname := "%sx%s" % [chunk_x, chunk_y]
	
	if not chunk_data.has(dataname):
		if FileAccess.file_exists(dir+"/"+name+"/" + dataname):
			var file = FileAccess.open(dir+"/"+name+"/" + dataname, FileAccess.READ)
			chunk_data[dataname] = file.get_var()
		else:
			chunk_data[dataname] = {}
	
	if not chunk_data[dataname].has(chunkname):
		chunk_data[dataname][chunkname] = {"chunks": [], "changed": false}
	
	var data: Array = chunk_data[dataname][chunkname]["chunks"]
	for i in range(data.size() - 1, -1, -1):
		if data[i].has("pos") and data[i]["pos"] == pos and data[i]["layer"] == layer:
			data.remove_at(i)
	
	if block != "":
		data.append({"pos": pos, "layer": layer, "block": block})
		chunk_data[dataname][chunkname]["changed"] = true

func _save_super(dataname: String) -> void:
	if chunk_data.has(dataname) and not chunk_data[dataname].is_empty():
		var copy = {}
		for i in chunk_data[dataname]:
			if chunk_data[dataname][i]["changed"]:
				copy[i] = chunk_data[dataname][i]
		if copy:
			var file = FileAccess.open(dir+"/"+name+"/" + dataname, FileAccess.WRITE)
			if file: file.store_var(copy)

func _save_unneeded_supers() -> void:
	var needed_supers: Dictionary = {}
	for c: Vector2i in current_chunks:
		var sx := floor(c.x / 16.0) as int
		var sy := floor(c.y / 16.0) as int
		needed_supers[Vector2i(sx, sy)] = true
	
	var to_erase: Array[String] = []
	for dataname: String in chunk_data.keys():
		var parts := dataname.split("_")
		if parts.size() != 2: continue
		var sx := parts[0].to_int()
		var sy := parts[1].to_int()
		if not needed_supers.has(Vector2i(sx, sy)):
			to_erase.append(dataname)
	
	for dataname in to_erase:
		_save_super(dataname)
		chunk_data.erase(dataname)

func _generate_chunk_data(cords: Vector2i) -> Dictionary:
	var super_x := floor(cords.x / 16.0) as int
	var super_y := floor(cords.y / 16.0) as int
	var dataname := "%s_%s" % [super_x, super_y]
	var chunkname := "%sx%s" % [cords.x, cords.y]
	call_deferred("msg","%s %s"%[super_x,super_y])
	if not chunk_data.has(dataname):
		if FileAccess.file_exists(dir+"/"+name+"/" + dataname):
			var file = FileAccess.open(dir+"/"+name+"/" + dataname, FileAccess.READ)
			chunk_data[dataname] = file.get_var()
		else:
			chunk_data[dataname] = {}
	
	if chunk_data[dataname].has(chunkname):
		return chunk_data[dataname][chunkname]
	
	var out := {"chunks":[], "changed":false}
	for x in range(16):
		for y in range(16):
			var wx = cords.x * 16 + x
			var wy = cords.y * 16 + y
			var height = (noiseH.get_noise_2d(wx, wy) + 1.0) / 2.0
			var height2 = (noiseH2.get_noise_2d(wx, wy) + 1.0) / 2.0
			var humidity = (noise1.get_noise_2d(wx, wy) + 1.0) / 2.0
			var temperature = (noise2.get_noise_2d(wx, wy) + 1.0) / 2.0
			humidity = clamp((humidity - 0.5) * 1.5 + 0.5, 0.0, 1.0)
			temperature = clamp((temperature - 0.5) * 1.5 + 0.5, 0.0, 1.0)
			
			if height < 0.17 or height2 > 0.8:
				continue
			
			var biome = get_biome(humidity, temperature)
			var pos = Vector2i(x + cords.x * 16, y + cords.y * 16)
			
			out["chunks"].append({"pos": pos, "layer": 0, "block": biomeblocks[biome]})
			
			if (noise3.get_noise_2d(wx, wy) + 1.0) / 2.0 > 0.75 and biome in ["savanna","forest","snowy_taiga","taiga","jungle","swamp"]:
				out["chunks"].append({"pos": pos, "layer": 1, "block": "tree"})
			
			if (noise5.get_noise_2d(wx, wy) + 1.0) / 2.0 > 0.7 and biome == "plains":
				var idx = floor( ((noise4.get_noise_2d(wx, wy) + 1.0) / 2.0) * float(flower_block_names.size()) )
				idx = clamp(idx, 0, flower_block_names.size() - 1)
				out["chunks"].append({"pos": pos, "layer": 1, "block": flower_block_names[idx]})
	
	chunk_data[dataname][chunkname] = out
	return out

func _exit_tree() -> void:
	worker_running = false
	semaphore.post()
	for dataname in chunk_data.keys():
		_save_super(dataname)
	chunk_data.clear()
	if worker_thread:
		worker_thread.wait_to_finish()
	print("_")

func cell_press(pos: Vector2):
	match mode:
		0:
			pass
			
		1: # ПОСТРОЙКА
			var current_chunk = Vector2i(floor(pos / 16.0))
			if current_chunk not in current_chunks: 
				return
			
			var chunk_node = $"../chunks".get_node_or_null("%sx%s" % [current_chunk.x, current_chunk.y])
			if chunk_node:
				for child in chunk_node.get_children():
					if child is Sprite2D and Vector2(pos) == floor(child.position / (16.0 * 5.0)):
						
						return
			for layer_idx in [0,1]:
				var layer = tilemap_layers[layer_idx]
				var below = Vector2i(pos.x, pos.y + 1)
				if layer.get_cell_source_id(pos) == -1 or layer.get_cell_atlas_coords(pos) == Vector2i(4, 4):  # место свободно
					var block_name = "cobblestone"
					var def = blocks[block_name]
					if def.type == "tilemap":
						layer.set_cells_terrain_connect([pos], def.terrain_set, def.terrain, false)
						if layer.get_cell_source_id(below) == -1:
							layer.set_cell(below, def.tilemap, def.side_atlas_coords)
					_update_chunk_cache(pos, layer_idx, block_name)
					return
		
		2: # ЛОМАНИЕ — ИСПРАВЛЕННАЯ ЛОГИКА ПО ТВОЕМУ ОПИСАНИЮ
			var current_chunk = Vector2i(floor(pos / 16.0))
			if current_chunk not in current_chunks: 
				return
			
			# 1. Проверяем спрайты (деревья, цветы)
			var chunk_node = $"../chunks".get_node_or_null("%sx%s" % [current_chunk.x, current_chunk.y])
			if chunk_node:
				for child in chunk_node.get_children():
					if child is Sprite2D and Vector2(pos) == floor(child.position / (16.0 * 5.0)):
						child.queue_free()
						_update_chunk_cache(Vector2i(pos), 1, "")
						return
			
			# 2. Ломаем тайлы
			for layer_idx in [1, 0]:
				var layer = tilemap_layers[layer_idx]
				if layer.get_cell_source_id(pos) == -1:
					continue
				
				var atlas_coords = layer.get_cell_atlas_coords(pos)
				
				# Если кликнули на боковую грань или пустоту — ничего не делаем
				if atlas_coords == Vector2i(4, 4):
					return
				
				# Это основной блок
				var above_pos = Vector2i(pos.x, pos.y - 1)
				var below_pos = Vector2i(pos.x, pos.y + 1)
				var srs = layer.get_cell_source_id(pos)
				# Если выше стоит блок → ставим боковую грань НА ЭТО МЕСТО (clicked pos)
				if layer.get_cell_source_id(above_pos) != -1 and layer.get_cell_atlas_coords(above_pos) != Vector2i(4, 4):
					layer.set_cell(pos, srs, Vector2i(4, 4))
					_update_chunk_cache(pos, layer_idx, "")
				else:
					# Выше пусто → просто удаляем блок
					layer.erase_cell(pos)
					_update_chunk_cache(pos, layer_idx, "")
				
				for i in layer.get_surrounding_cells(pos):
					if layer.get_cell_source_id(i) == -1 or layer.get_cell_atlas_coords(i) == Vector2i(4, 4):
						continue
					var ts = layer.get_cell_tile_data(i).terrain_set
					var t = layer.get_cell_tile_data(i).terrain
					layer.erase_cell(i)
					layer.set_cells_terrain_connect([i],ts,t,false)
				# Дополнительно: удаляем боковую грань снизу, если она есть
				if layer.get_cell_source_id(below_pos) != -1 and layer.get_cell_atlas_coords(below_pos) == Vector2i(4, 4):
					layer.erase_cell(below_pos)
					
					#_update_chunk_cache(below_pos, layer_idx, "")
				
				return  # обработали один блок

func msg(text):
	var label = RichTextLabel.new()
	label.text = text
	label.fit_content = true
	label.bbcode_enabled = true
	label["theme_override_font_sizes/normal_font_size"] = 36
	print(text)
	$"../../CanvasLayer/ScrollContainer2/VBoxContainer2".add_child(label)

func _on_saveandexit_pressed() -> void:
	$"../../CanvasLayer".hide()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir+"/"+name+"/screenshot.png")
	get_tree().change_scene_to_file("res://worldsmenu.tscn")

func _on_menu_pressed() -> void:
	var t = create_tween()
	t.tween_property($"../../CanvasLayer/VBoxContainer2", "position:x",0,0.2)

func _on_back_pressed() -> void:
	var t = create_tween()
	t.tween_property($"../../CanvasLayer/VBoxContainer2", "position:x",-512,0.2)
