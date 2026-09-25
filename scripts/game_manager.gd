extends Node
class_name GameManager

const PIECE_SCENE = preload("res://scenes/piece.tscn")
const VALID_SPOT_TEXTURE = preload("res://assets/sprites/tiles/valid_spot_2.0.png")

signal game_over(winner: Piece.Team)

@onready var board: TileMapLayer = $"../World/Board"
@onready var pieces_layer: Node2D = $"../World/PiecesLayer"
@onready var highlight_layer: Node2D = $"../World/HighlightLayer"

var grid: Array = []
var rules := FesshRules.new(self)
var move_quality_tracker := MoveQualityTracker.new()
var powerup_manager := PowerupManager.new(self, move_quality_tracker)
var blocked_squares: Dictionary = {} # Vector2i -> turns_remaining, set by PowerupManager
var game_active: bool = true

var dragging_piece: Piece = null
var drag_start_cell: Vector2i
var highlight_sprites: Array[Sprite2D] = []

const GREEN_TILE_BLOCK_TEXTURE = preload("res://assets/sprites/tiles/green_tile_block.png")
const RED_TILE_BLOCK_TEXTURE = preload("res://assets/sprites/tiles/red_tile_block.png")

@onready var player_move_sound: AudioStreamPlayer2D = $"../PlayerMoveSound"
@onready var bot_move_sound: AudioStreamPlayer2D = $"../BotMoveSound"

var blocked_overlay_sprites: Dictionary = {} # Vector2i -> Sprite2D

var textures := {
	"a_pawn": preload("res://assets/sprites/pieces/abyssal_ith'ka_(pawn).png"),
	"a_rook": preload("res://assets/sprites/pieces/abyssal_vraalth_(rook).png"),
	"a_knight": preload("res://assets/sprites/pieces/abyssal_miraq'th_(knight).png"),
	"a_bishop": preload("res://assets/sprites/pieces/abyssal_sygnorae_(bishop).png"),
	"a_queen": preload("res://assets/sprites/pieces/abyssal_nyxara_(queen).png"),
	"a_king": preload("res://assets/sprites/pieces/abyssal_korrathum_(king).png"),
	"r_pawn": preload("res://assets/sprites/pieces/reef_ith'ka_(pawn).png"),
	"r_rook": preload("res://assets/sprites/pieces/reef_vraalth_(rook).png"),
	"r_knight": preload("res://assets/sprites/pieces/reef_miraq'th_(knight).png"),
	"r_bishop": preload("res://assets/sprites/pieces/reef_sygnorae_(bishop).png"),
	"r_queen": preload("res://assets/sprites/pieces/reef_nyxara_(queen).png"),
	"r_king": preload("res://assets/sprites/pieces/reef_korrathum_(king).png")
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
	["a_king", Piece.Team.ABYSSAL, 4, 11],
	
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
	["r_king", Piece.Team.REEF, 4, 0]
]

func _ready() -> void:
	init_grid()
	spawn_pieces()
	var bot_controller = $"../BotController"
	bot_controller.setup(self, rules)
	_wire_powerup_shop(bot_controller)

## Looks for a PowerupShop node and wires it up if one exists -- safe to
## call even before you've added the shop to your scene. Adjust shop_path
## below to match wherever you actually place the shop node.
func _wire_powerup_shop(bot_controller) -> void:
	var shop_path := "../HUD/PowerupShop"
	if not has_node(shop_path):
		return
	var shop: PowerupShop = get_node(shop_path)
	var player_team: Piece.Team = Piece.Team.REEF if bot_controller.bot_team == Piece.Team.ABYSSAL else Piece.Team.ABYSSAL
	shop.setup(self, player_team)
	bot_controller.powerup_shop = shop
	bot_controller.set_level(bot_controller.difficulty_level) # re-apply now that the shop reference exists

func add_block_overlay(cell: Vector2i) -> void:
	if blocked_overlay_sprites.has(cell):
		return
		
	var sprite := Sprite2D.new()
	
	# Match the board's alternating tile logic: (x + y) % 2 == 0 is Green, else Red
	if (cell.x + cell.y) % 2 == 0:
		sprite.texture = GREEN_TILE_BLOCK_TEXTURE
	else:
		sprite.texture = RED_TILE_BLOCK_TEXTURE
		
	sprite.position = board.map_to_local(cell)
	highlight_layer.add_child(sprite)
	blocked_overlay_sprites[cell] = sprite

func remove_block_overlay(cell: Vector2i) -> void:
	if blocked_overlay_sprites.has(cell):
		var sprite: Sprite2D = blocked_overlay_sprites[cell]
		sprite.queue_free()
		blocked_overlay_sprites.erase(cell)

func play_move_sound(is_bot: bool) -> void:
	if is_bot:
		if bot_move_sound != null:
			bot_move_sound.play()
	else:
		if player_move_sound != null:
			player_move_sound.play()

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

func is_square_blocked(cell: Vector2i) -> bool:
	return blocked_squares.has(cell)
	
#----------------Handles Piece Capture----------------
func move_piece(from: Vector2i, to: Vector2i, is_bot_move: bool = false):
	var piece = get_piece_at(from)
	if piece == null:
		return
	# handle capture if a piece already exists at 'to'
	var target = get_piece_at(to)
	var captured_type: String = target.piece_type if target != null else ""
	if target:
		target.queue_free()
	grid[from.y][from.x] = null
	grid[to.y][to.x] = piece
	piece.board_pos = to
	piece.position = board.map_to_local(to)
	move_quality_tracker.score_move(piece.team, piece.piece_type, captured_type)
	_on_move_made(piece, to)
	play_move_sound(is_bot_move)

## Powerup action: relocate a piece to any empty, unblocked square, bypassing
## normal movement rules entirely. Counts as that team's move for the turn.
func teleport_piece(piece: Piece, to: Vector2i) -> bool:
	if piece == null or not is_empty_and_unblocked(to):
		return false
	grid[piece.board_pos.y][piece.board_pos.x] = null
	grid[to.y][to.x] = piece
	piece.board_pos = to
	piece.position = board.map_to_local(to)
	_on_move_made(piece, to)
	return true

func is_empty_and_unblocked(cell: Vector2i) -> bool:
	return get_piece_at(cell) == null and not is_square_blocked(cell)

func _on_move_made(piece: Piece, to: Vector2i) -> void:
	_check_game_over()
	if not game_active:
		return
	powerup_manager.tick_turn_effects()
	if powerup_manager.consume_extra_move(piece.team):
		powerup_manager.turn_continues.emit(piece.team) # same team acts again, no end_turn()
	else:
		TurnTracker.end_turn()

func _check_game_over() -> void:
	var snapshot := SearchBoard.from_game_manager(self)
	var result := rules.is_terminal(snapshot)
	if result["over"]:
		game_active = false
		game_over.emit(result["winner"])
		print("Game over! Winner: ", result["winner"]) # placeholder until you hook up a real end screen

#-----------Handles Piece Movement w/ Mouse-----------
func _unhandled_input(event: InputEvent) -> void:
	if not game_active:
		return
	var mouse_world_pos = board.get_global_mouse_position()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if powerup_manager.targeting_mode != "":
			var cell = board.local_to_map(board.to_local(mouse_world_pos))
			powerup_manager.handle_targeting_click(cell)
			return
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
	if TurnTracker.get_current_team_number(TurnTracker.get_current_team()) == piece.team:
		dragging_piece = piece
		drag_start_cell = cell
		piece.z_index = 2
		show_valid_move_highlights(cell)

func try_drop() -> void:
	var mouse_world_pos = board.get_global_mouse_position()
	var target_cell = board.local_to_map(board.to_local(mouse_world_pos))

# if the get_all_valid_moves() array contains target_cell, then move piece


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

func valid_pawn_moves(from: Vector2i, piece, provider = self) -> Array:
	var results: Array = []
	var moves_at_position = MoveTable.pawn_table[piece.piece_type][from]
	var dir = MoveTable.pawn_offsets[piece.piece_type][0]  # true forward direction

	var blocked_forward = false
	var blocked_backward = false

	for potential_move in moves_at_position:
		if potential_move.x == from.x:
			var is_forward = sign(potential_move.y - from.y) == sign(dir.y)
			if is_forward:
				if blocked_forward:
					continue
				var occupant = provider.get_piece_at(potential_move)
				if occupant == null:
					results.append(potential_move)
				else:
					blocked_forward = true  # forward straight never captures
			else:
				if blocked_backward:
					continue
				var occupant = provider.get_piece_at(potential_move)
				if occupant == null:
					results.append(potential_move)
				elif occupant.team != piece.team && occupant.shielded_turns <= 0 && (!occupant.piece_type.contains("queen") && !occupant.piece_type.contains("king")):
					results.append(potential_move)   # backward straight CAN capture
				else:
					blocked_backward = true  # own piece blocks
		else:
			# diagonal — capture only
			var occupant = provider.get_piece_at(potential_move)
			# pawn can't capture queen
			if occupant != null and occupant.team != piece.team && occupant.shielded_turns <= 0 && (!occupant.piece_type.contains("queen") && !occupant.piece_type.contains("king")):
				results.append(potential_move)
	return results
func valid_knight_moves(from: Vector2i, piece, provider = self) -> Array:
	var results: Array = []
	var moves_at_position = MoveTable.knight_table[piece.piece_type][from]
	for potential_move in moves_at_position:
		var occupant = provider.get_piece_at(potential_move)
		if occupant == null:
			results.append(potential_move)
		# knight can't capture king or bishop, or a shielded piece
		elif occupant.team != piece.team && occupant.shielded_turns <= 0 && (!occupant.piece_type.contains("bishop") && !occupant.piece_type.contains("king")):
			results.append(potential_move)
	return results
func valid_rook_moves(from: Vector2i, piece, provider = self) -> Array:
	var results: Array = []
	var moves_at_position = MoveTable.rook_table[piece.piece_type][from]

	for potential_move in moves_at_position:
		for step in potential_move:
			var occupant = provider.get_piece_at(step)
			if occupant == null:
				results.append(step)
			# rook can't capture pawns, king, or a shielded piece
			elif occupant.team != piece.team && occupant.shielded_turns <= 0 && (!occupant.piece_type.contains("pawn") && !occupant.piece_type.contains("king")):
				results.append(step)
				break
			else:
				break
	return results
func valid_bishop_moves(from: Vector2i, piece, provider = self) -> Array:
	var results: Array = []
	var moves_at_position = MoveTable.bishop_table[piece.piece_type][from]
	for potential_move in moves_at_position:
		for step in potential_move:
			var occupant = provider.get_piece_at(step)
			if occupant == null:
				results.append(step)
			# bishop can't capture rook, pawns, king, or a shielded piece
			elif occupant.team != piece.team && occupant.shielded_turns <= 0 && (!occupant.piece_type.contains("rook") && !occupant.piece_type.contains("king")):
				results.append(step)
				break
			else:
				break
	return results
func valid_queen_moves(from: Vector2i, piece, provider = self) -> Array:
	var results: Array = []
	var moves_at_position = MoveTable.queen_table[piece.piece_type][from]
	
	for potential_moves in moves_at_position:
		for move in potential_moves:
			var occupant = provider.get_piece_at(move)
			if occupant == null:
				results.append(move)
			# queen can't capture king or a shielded piece
			elif occupant.team != piece.team && occupant.shielded_turns <= 0 && !occupant.piece_type.contains("king"):
				results.append(move)
				break
			else:
				break
	return results
func valid_king_moves(from: Vector2i, piece, provider = self) -> Array:
	var results: Array = []
	var moves_at_position = MoveTable.king_table[piece.piece_type][from]
	for potential_move in moves_at_position:
		var occupant = provider.get_piece_at(potential_move)
		if occupant == null:
			results.append(potential_move)
		# king can't capture
		elif occupant.team != piece.team || occupant.team == piece.team:
			continue
	return results

## `provider` must expose get_piece_at(cell) -> null or an object with
## `.team` and `.piece_type` (a real Piece, or a PieceStub used by search).
## Defaults to `self` so every existing call site (live game, mouse drag)
## behaves exactly as before with no changes needed there.
func get_all_valid_moves(from: Vector2i, provider = self) -> Array:
	var piece = provider.get_piece_at(from)
	if piece == null:
		return []
	
	var results: Array = []

	if MoveTable.pawn_table.has(piece.piece_type):
		results = valid_pawn_moves(from, piece, provider)
	if MoveTable.knight_table.has(piece.piece_type):
		results = valid_knight_moves(from, piece, provider)
	if MoveTable.rook_table.has(piece.piece_type):
		results = valid_rook_moves(from, piece, provider)
	if MoveTable.bishop_table.has(piece.piece_type):
		results = valid_bishop_moves(from, piece, provider)
	if MoveTable.queen_table.has(piece.piece_type):
		results = valid_queen_moves(from, piece, provider)
	if MoveTable.king_table.has(piece.piece_type):
		results = valid_king_moves(from, piece, provider)
	
	return results.filter(func(cell): return not provider.is_square_blocked(cell))

## Simplified to delegate to get_all_valid_moves instead of re-implementing
## the capture matrix a second time -- the old knight branch here checked
## geometric reachability only (no occupancy/capture-exclusion check), which
## meant it could validate illegal knight moves. This also means provider
## now flows through here too, so search can reuse it directly.
func is_valid_move(from: Vector2i, to: Vector2i, provider = self) -> bool:
	return to in get_all_valid_moves(from, provider)
