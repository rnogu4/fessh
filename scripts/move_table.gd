extends Node

const WIDTH = 9
const HEIGHT = 12

var pawn_offsets := {
	# forward 1, forward 2, backward 1, diag 1, diag 2
	"a_pawn": [Vector2i(0,1), Vector2i(0,2), Vector2i(0,-1), Vector2i(1,1), Vector2i(-1,1)], 
	# forward 1, forward 2, backward 1, diag 1, diag 2
	"r_pawn": [Vector2i(0,-1), Vector2i(0,-2), Vector2i(0,1), Vector2i(1,-1), Vector2i(-1,-1)] 
}
var knight_offsets := {
	"a_knight": [
		Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, 2),      # top right (pos,pos)
		Vector2i(1, -2), Vector2i(2, -1), Vector2i(2, -2),   # bottom right (pos, neg)
		Vector2i(-1, 2), Vector2i(-2, 1), Vector2i(-2, 2),   # top left (neg, pos)
		Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, -2) # bottom left (neg, neg)
	],
	"r_knight": [
		Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, 2),      # top right (pos,pos)
		Vector2i(1, -2), Vector2i(2, -1), Vector2i(2, -2),   # bottom right (pos, neg)
		Vector2i(-1, 2), Vector2i(-2, 1), Vector2i(-2, 2),   # top left (neg, pos)
		Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, -2) # bottom left (neg, neg)
	]
}
var rook_offsets1 := {
	"a_rook": [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)],  # right, left, down, up (to be iterated)
	"r_rook": [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)],  # right, left, down, up (to be iterated)
}
var rook_offsets2 := {
	"a_rook": [Vector2i(1,1), Vector2i(-1,1), Vector2i(1,-1), Vector2i(-1,-1)],  # corners
	"r_rook": [Vector2i(1,1), Vector2i(-1,1), Vector2i(1,-1), Vector2i(-1,-1)],  # corners
}
var bishop_offsets1 := {
	"a_bishop": [Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(1,-1)],   # immediate cardinals (static)
	"r_bishop": [Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)],  # immediate cardinals (static)
}
var bishop_offsets2 := {
	"a_bishop": [Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(1,-1)],   # diagonals
	"r_bishop": [Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)],  # diagonals
}

var pawn_table := {}    # pawn_table   [piece_type][cell] = Array[Vector2i]
var knight_table := {}  # knight_table [piece_type][cell] = Array[Vector2i]
var rook_table := {}    # rook_table   [piece_type][cell] = Array[Array[Vector2i]]
var bishop_table := {}  # rook_table   [piece_type][cell] = Array[Array[Vector2i]]

func _ready():
	build_tables()

func build_tables():
	build_pawn_table()
	build_knight_table()
	build_rook_table()

func build_pawn_table():
	for piece_type in pawn_offsets:
		# stores offsets in pawn table dictionary
		pawn_table[piece_type] = {}
		# for each tile, precalculate the valid pawn moves
		for y in HEIGHT:
			for x in WIDTH:
				var cell = Vector2i(x, y)
				pawn_table[piece_type][cell] = find_pawn_potential_moves(cell, pawn_offsets[piece_type])
func build_knight_table():
	for piece_type in knight_offsets:
		# stores offsets in knight table dictionary
		knight_table[piece_type] = {}
		# for each tile, precalculate the valid knight moves
		for y in HEIGHT:
			for x in WIDTH:
				var cell = Vector2i(x, y)
				knight_table[piece_type][cell] = find_knight_potential_moves(cell, knight_offsets[piece_type])
func build_rook_table():
	for piece_type in rook_offsets1:
		rook_table[piece_type] = {}
		for y in HEIGHT:
			for x in WIDTH:
				var cell = Vector2i(x, y)
				
				var sliding = find_rook_potential_moves1(cell, rook_offsets1[piece_type])
				var diagonal = find_rook_potential_moves2(cell, rook_offsets2[piece_type])
				
				# wrap diagonals as single square ray
				var wrapped_diagonal := []
				for dest in diagonal:
					wrapped_diagonal.append([dest])
				
				rook_table[piece_type][cell] = sliding + wrapped_diagonal
func build_bishop_table():
	for piece_type in bishop_offsets1:
		bishop_table[piece_type] = {}
		for y in HEIGHT:
			for x in WIDTH:
				var cell = Vector2i(x, y)
				bishop_table[piece_type][cell] = find_bishop_potential_moves(cell, bishop_offsets1[piece_type])

func find_pawn_potential_moves(cell: Vector2i, offsets: Array) -> Array:
	var moves := []
	for offset in offsets:
		# check if it's in the bounds of the map
		var dest = cell + offset
		if _is_in_bounds(dest):
			moves.append(dest)
	return moves

func find_knight_potential_moves(cell: Vector2i, offsets: Array) -> Array:
	var moves := []
	for offset in offsets:
		var dest = cell + offset
		# check if it's in the bounds of the map
		if _is_in_bounds(dest):
			moves.append(dest)
	return moves

func find_rook_potential_moves1(cell: Vector2i, offsets: Array) -> Array:
	var moves := []
	for offset in offsets:
		var move := []
		var current = cell + offset
		# check if it's in the bounds of the map
		while _is_in_bounds(current):
			move.append(current)
			current += offset
		moves.append(move)
	return moves
func find_rook_potential_moves2(cell: Vector2i, offsets: Array) -> Array:
	var moves := []
	for offset in offsets:
		var dest = cell + offset
		# check if it's in the bounds of the map
		if _is_in_bounds(dest):
			moves.append(dest)
	return moves

func find_bishop_potential_moves(cell: Vector2i, offsets: Array) -> Array:
		var moves := []
		for offset in offsets:
			var move := []
			var current = cell + offset
			# check if it's in the bounds of the map
			while _is_in_bounds(current):
				move.append(current)
				current += offset
			moves.append(move)
		return moves

func _is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < WIDTH and cell.y >= 0 and cell.y < HEIGHT
