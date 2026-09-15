extends Node

var grid: Array = []
const PIECE_SCENE = preload("res://scenes/piece.tscn")

@onready var board: TileMapLayer = $"../World/Board"
@onready var pieces_layer: Node2D = $"../World/PiecesLayer"

var textures := {
	"a_pawn": preload("res://sprites/pieces/abyssal_ith'ka_(pawn).png"),
	"a_rook": preload("res://sprites/pieces/abyssal_vraalth_(rook).png"),
	"a_knight": preload("res://sprites/pieces/abyssal_miraq'th_(knight).png"),
	"a_bishop": preload("res://sprites/pieces/abyssal_sygnorae_(bishop).png"),
	"a_queen": preload("res://sprites/pieces/abyssal_nyxara_(queen).png"),
	"a_king": preload("res://sprites/pieces/abyssal_korrathum_(king).png"),
	"r_pawn": preload("res://sprites/pieces/reef_ith'ka_(pawn).png"),
	"r_rook": preload("res://sprites/pieces/reef_vraalth_(rook).png"),
	"r_knight": preload("res://sprites/pieces/reef_miraq'th_(knight).png"),
	"r_bishop": preload("res://sprites/pieces/reef_sygnorae_(bishop).png"),
	"r_queen": preload("res://sprites/pieces/reef_nyxara_(queen).png"),
	"r_king": preload("res://sprites/pieces/reef_korrathum_(king).png")
}

var starting_layout = [
	["a_pawn", Piece.Team.ABYSSAL, 0, 1],
	["a_pawn", Piece.Team.ABYSSAL, 1, 1],
	["a_pawn", Piece.Team.ABYSSAL, 2, 1],
	["a_pawn", Piece.Team.ABYSSAL, 3, 1],
	["a_pawn", Piece.Team.ABYSSAL, 4, 1],
	["a_pawn", Piece.Team.ABYSSAL, 5, 1],
	["a_pawn", Piece.Team.ABYSSAL, 6, 1],
	["a_pawn", Piece.Team.ABYSSAL, 7, 1],
	["a_pawn", Piece.Team.ABYSSAL, 8, 1],
	["a_rook", Piece.Team.ABYSSAL, 0, 0],
	["a_rook", Piece.Team.ABYSSAL, 8, 0],
	["a_knight", Piece.Team.ABYSSAL, 1, 0],
	["a_knight", Piece.Team.ABYSSAL, 7, 0],
	["a_bishop", Piece.Team.ABYSSAL, 2, 0],
	["a_bishop", Piece.Team.ABYSSAL, 6, 0],
	["a_queen", Piece.Team.ABYSSAL, 3, 0],
	["a_queen", Piece.Team.ABYSSAL, 5, 0],
	["a_king", Piece.Team.ABYSSAL, 4, 0],
	
	["r_pawn", Piece.Team.REEF, 0, 6],
	["r_pawn", Piece.Team.REEF, 1, 6],
	["r_pawn", Piece.Team.REEF, 2, 6],
	["r_pawn", Piece.Team.REEF, 3, 6],
	["r_pawn", Piece.Team.REEF, 4, 6],
	["r_pawn", Piece.Team.REEF, 5, 6],
	["r_pawn", Piece.Team.REEF, 6, 6],
	["r_pawn", Piece.Team.REEF, 7, 6],
	["r_pawn", Piece.Team.REEF, 8, 6],
	["r_rook", Piece.Team.REEF, 0, 7],
	["r_rook", Piece.Team.REEF, 8, 7],
	["r_knight", Piece.Team.REEF, 1, 7],
	["r_knight", Piece.Team.REEF, 7, 7],
	["r_bishop", Piece.Team.REEF, 2, 7],
	["r_bishop", Piece.Team.REEF, 6, 7],
	["r_queen", Piece.Team.REEF, 3, 7],
	["r_queen", Piece.Team.REEF, 5, 7],
	["r_king", Piece.Team.REEF, 4, 7]
]

func _ready() -> void:
	init_grid()
	spawn_pieces()

func init_grid():
	grid.clear()
	for y in Board.HEIGHT:
		var row = []
		for x in Board.WIDTH:
			row.append(null)
		grid.append(row)

func spawn_pieces():
	for entry in starting_layout:
		var type: String = entry[0]
		var team: Piece.Team = entry[1]
		var x: int = entry[2]
		var y: int = entry[3]
		spawn_piece(type, team, Vector2i(x, y))

func spawn_piece(type: String, team: Piece.Team, cell: Vector2i):
	var piece = PIECE_SCENE.instantiate()
	pieces_layer.add_child(piece)
	piece.setup(type, team, cell, textures[type])
	piece.position = board.map_to_local(cell)
	grid[cell.y][cell.x] = piece

func get_piece_at(cell: Vector2i) -> Piece:
	if cell.y < 0 or cell.y >= grid.size():
		return null
	if cell.x < 0 or cell.x >= grid[cell.y].size():
		return null
	return grid[cell.y][cell.x]

func move_piece(from: Vector2i, to: Vector2i):
	var piece = get_piece_at(from)
	if piece == null:
		return
	# handle capture if a piece already exists at 'to'
	var target = get_piece_at(to)
	if target:
		target.queue_free()
	grid[from.y][from.x] = null
	grid[to.y][to.x] = piece
	piece.board_pos = to
	piece.position = board.map_to_local(to)
