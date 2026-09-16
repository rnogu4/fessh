extends Node

const PIECE_SCENE = preload("res://scenes/piece.tscn")
const VALID_SPOT_TEXTURE = preload("res://sprites/tiles/valid_spot_2.0.png")

@onready var board: TileMapLayer = $"../World/Board"
@onready var pieces_layer: Node2D = $"../World/PiecesLayer"
@onready var highlight_layer: Node2D = $"../World/HighlightLayer"

var grid: Array = []

var dragging_piece: Piece = null
var drag_start_cell: Vector2i
var highlight_sprites: Array[Sprite2D] = []

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
	
	["r_pawn", Piece.Team.REEF, 0, 10],
	["r_pawn", Piece.Team.REEF, 1, 10],
	["r_pawn", Piece.Team.REEF, 2, 10],
	["r_pawn", Piece.Team.REEF, 3, 10],
	["r_pawn", Piece.Team.REEF, 4, 10],
	["r_pawn", Piece.Team.REEF, 5, 10],
	["r_pawn", Piece.Team.REEF, 6, 10],
	["r_pawn", Piece.Team.REEF, 7, 10],
	["r_pawn", Piece.Team.REEF, 8, 10],
	["r_rook", Piece.Team.REEF, 0, 11],
	["r_rook", Piece.Team.REEF, 8, 11],
	["r_knight", Piece.Team.REEF, 1, 11],
	["r_knight", Piece.Team.REEF, 7, 11],
	["r_bishop", Piece.Team.REEF, 2, 11],
	["r_bishop", Piece.Team.REEF, 6, 11],
	["r_queen", Piece.Team.REEF, 3, 11],
	["r_queen", Piece.Team.REEF, 5, 11],
	["r_king", Piece.Team.REEF, 4, 11]
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
	
#----------------Handles Piece Capture----------------
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
	
#-----------Handles Piece Movement w/ Mouse-----------
func _unhandled_input(event: InputEvent) -> void:
	var mouse_world_pos = board.get_global_mouse_position()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			try_start_drag()
		else:
			if dragging_piece:
				try_drop()
	elif event is InputEventMouseMotion and dragging_piece:
		dragging_piece.position = mouse_world_pos

func try_start_drag() -> void:
	var mouse_world_pos = board.get_global_mouse_position()
	var cell = board.local_to_map(board.to_local(mouse_world_pos))
	var piece = get_piece_at(cell)
	if piece == null:
		return
	dragging_piece = piece
	drag_start_cell = cell
	piece.z_index = 2
	
	show_valid_move_highlights(cell)

func try_drop() -> void:
	var mouse_world_pos = board.get_global_mouse_position()
	var target_cell = board.local_to_map(board.to_local(mouse_world_pos))

	if is_valid_move(drag_start_cell, target_cell):
		move_piece(drag_start_cell, target_cell)
	else:
		dragging_piece.position = board.map_to_local(drag_start_cell)
	
	dragging_piece.z_index = 0
	clear_valid_move_highlights()
	dragging_piece = null

#-----------Valid Moves-----------
func show_valid_move_highlights(from: Vector2i) -> void:
	var valid_moves = get_all_valid_moves(from)
	for cell in valid_moves:
		var highlight = Sprite2D.new()
		highlight.texture = VALID_SPOT_TEXTURE
		highlight.position = board.map_to_local(cell)
		highlight_layer.add_child(highlight)
		highlight_sprites.append(highlight)

func clear_valid_move_highlights() -> void:
	for sprite in highlight_sprites:
		sprite.queue_free()
	highlight_sprites.clear()

func get_pawn_moves(from: Vector2i, piece: Piece) -> Array:
	var results: Array = []
	var candidates = MoveTable.pawn_table[piece.piece_type][from]
	var dir = MoveTable.pawn_offsets[piece.piece_type][0]  # true forward direction

	var blocked_forward = false
	var blocked_backward = false

	for cell in candidates:
		if cell.x == from.x:
			var is_forward = sign(cell.y - from.y) == sign(dir.y)
			if is_forward:
				if blocked_forward:
					continue
				var occupant = get_piece_at(cell)
				if occupant == null:
					results.append(cell)
				else:
					blocked_forward = true  # forward straight never captures
			else:
				if blocked_backward:
					continue
				var occupant = get_piece_at(cell)
				if occupant == null:
					results.append(cell)
				elif occupant.team != piece.team:
					results.append(cell)   # backward straight CAN capture
					blocked_backward = true  # still can't pass beyond it
				else:
					blocked_backward = true  # own piece blocks
		else:
			# diagonal — capture only, any of the 4 directions
			var target = get_piece_at(cell)
			if target != null and target.team != piece.team:
				results.append(cell)

	return results

func get_all_valid_moves(from: Vector2i) -> Array:
	var piece = get_piece_at(from)
	if piece == null:
		return []

	var results: Array = []

	if MoveTable.pawn_table.has(piece.piece_type):
		results = get_pawn_moves(from, piece)

	if MoveTable.leaper_table.has(piece.piece_type):
		for ray in MoveTable.leaper_table[piece.piece_type][from]:
			if is_valid_move(from, ray):
				results.append(ray)

	if MoveTable.slider_table.has(piece.piece_type):
		for ray in MoveTable.slider_table[piece.piece_type][from]:
			for step_cell in ray:
				if is_valid_move(from, step_cell):
					results.append(step_cell)
				if get_piece_at(step_cell) != null:
					break  # blocked — stop walking this ray

	return results

func is_valid_move(from: Vector2i, to: Vector2i) -> bool:
	var piece = get_piece_at(from)
	if piece == null:
		return false
	if to.x < 0 or to.x >= board.WIDTH or to.y < 0 or to.y >= board.HEIGHT:
		return false
		
	var target_piece = get_piece_at(to)
	if target_piece and target_piece.team == piece.team:
		return false  # can't capture your own piece
		
	if MoveTable.pawn_table.has(piece.piece_type):
		return to in get_pawn_moves(from, piece)
		
	if MoveTable.leaper_table.has(piece.piece_type):
		return to in MoveTable.leaper_table[piece.piece_type][from]
		
	if MoveTable.slider_table.has(piece.piece_type):
		for ray in MoveTable.slider_table[piece.piece_type][from]:
			for step_cell in ray:
				if step_cell == to:
					return true
				if get_piece_at(step_cell) != null:
					break  # something's in the way — this ray goes no further
		return false
	return false
