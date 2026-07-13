extends Node
class_name Terrain
static var map = {
38: Vector2(0,0),
55: Vector2(0,1),
19: Vector2(0,2),
23: Vector2(0,3),
39: Vector2(0,4),
6: Vector2(0,5),
7: Vector2(0,6),
3: Vector2(0,7),
110: Vector2(1,0),
0: Vector2(1,1),
155: Vector2(1,2),
141: Vector2(1,3),
77: Vector2(1,4),
14: Vector2(1,5),
15: Vector2(1,6),
11: Vector2(1,7),
76: Vector2(2,0),
205: Vector2(2,1),
137: Vector2(2,2),
78: Vector2(2,3),
139: Vector2(2,4),
12: Vector2(2,5),
13: Vector2(2,6),
9: Vector2(2,7),
47: Vector2(3,0),
63: Vector2(3,1),
31: Vector2(3,2),
46: Vector2(3,3),
27: Vector2(3,4),
223: Vector2(3,5),
239: Vector2(3,6),
2: Vector2(3,7),
111: Vector2(4,0),
255: Vector2(4,1),
159: Vector2(4,2),
95: Vector2(4,3),
#nan: Vector2(4,4), 
191: Vector2(4,5),
127: Vector2(4,6),
10: Vector2(4,7),
79: Vector2(5,0),
207: Vector2(5,1),
143: Vector2(5,2),
175: Vector2(5,3),
4: Vector2(5,4),
5: Vector2(5,5),
1: Vector2(5,6),
8: Vector2(5,7)
}

static func terrain(tiles_dict: Dictionary) -> Array:
	var result_array: Array = []
	var directions = [
		Vector2(0, -1),  # 1: Север
		Vector2(1, 0),   # 2: Восток
		Vector2(0, 1),   # 4: Юг
		Vector2(-1, 0),  # 8: Запад
		Vector2(1, -1),  # 16: Северо-Восток
		Vector2(-1, -1), # 32: Северо-Запад
		Vector2(1, 1),   # 64: Юго-Восток
		Vector2(-1, 1)   # 128: Юго-Запад
	]
	var weights = [1, 2, 4, 8, 16, 32, 64, 128]

	for pos in tiles_dict.keys():
		var current_block = tiles_dict[pos]
		var bitmask = 0
		for i in range(directions.size()):
			var neighbor_pos = pos + directions[i]
			if tiles_dict.has(neighbor_pos) and tiles_dict[neighbor_pos] == current_block:
				bitmask += weights[i]
		var atlas_pos = map.get(bitmask, Vector2.ZERO)
		var tile_data = {
			"pos": pos,
			"block": current_block,
			"type": atlas_pos
		}
		result_array.append(tile_data)
	return result_array
