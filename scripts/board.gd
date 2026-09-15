extends TileMapLayer

const WIDTH = 9
const HEIGHT = 8
const GREEN_TILE = Vector2i(0, 0)  # atlas coords for green tile
const RED_TILE = Vector2i(0, 1)    # atlas coords for red tile
const SOURCE_ID = 0                # your tileset source id

func _ready():
	generate_board()

func generate_board():
	for y in HEIGHT:
		for x in WIDTH:
			var coords = GREEN_TILE if (x + y) % 2 == 0 else RED_TILE
			set_cell(Vector2i(x, y), SOURCE_ID, coords)
