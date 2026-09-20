class_name FesshBoard
extends RefCounted

## Plain-data board state. No Node2D/Sprite anything in here on purpose —
## the AI clones this many times per turn, so it needs to be cheap.
## Your visual board should READ from an instance of this, not the other
## way around.

var width: int
var height: int
var grid: Array          # grid[x][y] = {} (empty square) or a piece dict
var side_to_move: String # e.g. "white" / "black" -- swap for your own color enum if you have one
var history: Array = []  # Array[FesshMove], kept for debugging / move-ordering heuristics

func _init(_width: int, _height: int, _side_to_move: String = "white") -> void:
	width = _width
	height = _height
	side_to_move = _side_to_move
	grid = []
	for x in range(width):
		var col := []
		col.resize(height)
		for y in range(height):
			col[y] = {}
		grid.append(col)

func clone() -> FesshBoard:
	var b := FesshBoard.new(width, height, side_to_move)
	for x in range(width):
		for y in range(height):
			b.grid[x][y] = grid[x][y].duplicate(true)
	# history isn't deep-copied here since search doesn't need it;
	# add it back if your eval/move-ordering wants move history context.
	return b

func in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

func get_piece(pos: Vector2i) -> Dictionary:
	if not in_bounds(pos):
		return {}
	return grid[pos.x][pos.y]

func set_piece(pos: Vector2i, piece: Dictionary) -> void:
	grid[pos.x][pos.y] = piece

func is_empty(pos: Vector2i) -> bool:
	return get_piece(pos).is_empty()

func opponent_of(color: String) -> String:
	return "black" if color == "white" else "white"

## Applies a move in place. Search works by cloning the board first and
## applying onto the clone, so no undo is implemented here -- add one later
## (mutate + rollback) only if profiling shows cloning is your bottleneck.
func apply_move(move: FesshMove) -> void:
	if move.is_capture():
		set_piece(move.captured_pos, {})
	set_piece(move.to, move.piece)
	set_piece(move.from, {})
	history.append(move)
	side_to_move = opponent_of(side_to_move)

func find_king_pos(color: String) -> Vector2i:
	for x in range(width):
		for y in range(height):
			var p: Dictionary = grid[x][y]
			if not p.is_empty() and p.get("color") == color and p.get("type") == "king":
				return Vector2i(x, y)
	return Vector2i(-1, -1) # king captured / off-board
