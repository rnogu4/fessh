class_name SearchBoard
extends RefCounted

## Cloneable, non-visual mirror of GameManager.grid. The AI clones this
## many times per turn, so it deliberately holds no Node2D/Sprite anything --
## just team + type per square. Same [y][x] indexing as GameManager.grid.

const WIDTH = Board.WIDTH
const HEIGHT = Board.HEIGHT

var grid: Array # grid[y][x] = PieceStub or null
var blocked_squares: Dictionary = {} # Vector2i -> turns_remaining, from the Block Square powerup

func _init() -> void:
	grid = []
	for y in HEIGHT:
		var row := []
		row.resize(WIDTH)
		for x in WIDTH:
			row[x] = null
		grid.append(row)

## Snapshots the live game state into a SearchBoard the AI can safely mutate.
static func from_game_manager(gm: GameManager) -> SearchBoard:
	var b := SearchBoard.new()
	for y in HEIGHT:
		for x in WIDTH:
			var piece = gm.get_piece_at(Vector2i(x, y))
			if piece != null:
				b.grid[y][x] = PieceStub.new(piece.piece_type, piece.team, piece.shielded_turns)
	b.blocked_squares = gm.blocked_squares.duplicate()
	return b

func clone() -> SearchBoard:
	var b := SearchBoard.new()
	for y in HEIGHT:
		for x in WIDTH:
			var p = grid[y][x]
			b.grid[y][x] = p.duplicate_stub() if p != null else null
	b.blocked_squares = blocked_squares.duplicate()
	return b

func is_square_blocked(cell: Vector2i) -> bool:
	return blocked_squares.has(cell)

func get_piece_at(cell: Vector2i) -> Variant:
	if cell.x < 0 or cell.x >= WIDTH or cell.y < 0 or cell.y >= HEIGHT:
		return null
	return grid[cell.y][cell.x]

func set_piece_at(cell: Vector2i, piece) -> void:
	grid[cell.y][cell.x] = piece

func apply_move(move: FesshMove) -> void:
	if move.is_capture():
		set_piece_at(move.captured_pos, null)
	set_piece_at(move.to, get_piece_at(move.from))
	set_piece_at(move.from, null)

func find_king_pos(team: Piece.Team) -> Vector2i:
	for y in HEIGHT:
		for x in WIDTH:
			var p = grid[y][x]
			if p != null and p.team == team and p.piece_type.ends_with("king"):
				return Vector2i(x, y)
	return Vector2i(-1, -1) # king missing -- shouldn't happen since no piece can capture a king

func opponent_of(team: Piece.Team) -> Piece.Team:
	return Piece.Team.ABYSSAL if team == Piece.Team.REEF else Piece.Team.REEF
