extends Node

const WIDTH = 9
const HEIGHT = 12

var leaper_offsets := {
	"a_knight": [
		Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, 2), # top right (pos,pos)
		Vector2i(1, -2), Vector2i(2, -1), Vector2i(2, -2), # bottom right (pos, neg)
		Vector2i(-1, 2), Vector2i(-2, 1), Vector2i(-2, 2), # top left (neg, pos)
		Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, -2) # bottom left (neg, neg)
	],
	"r_knight": [
		Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, 2), # top right (pos,pos)
		Vector2i(1, -2), Vector2i(2, -1), Vector2i(2, -2), # bottom right (pos, neg)
		Vector2i(-1, 2), Vector2i(-2, 1), Vector2i(-2, 2), # top left (neg, pos)
		Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, -2) # bottom left (neg, neg)
	]
}

var slider_offsets := {
	"a_rook": [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)],  # rook-like
	"r_rook": [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)],  # rook-like
	"a_bishop": [Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(1,-1)],  # bishop-like
	"r_bishop": [Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)],  # bishop-like
}

var pawn_offsets := {
	"a_pawn": [Vector2i(0,1), Vector2i(0,2), Vector2i(0,-1)],
	"r_pawn": [Vector2i(0,-1), Vector2i(0,-2), Vector2i(0,1)]
}

var leaper_table := {}  # leaper_table[piece_type][cell] = Array[Vector2i]
var slider_table := {}  # slider_table[piece_type][cell] = Array[Array[Vector2i]]
var pawn_table := {}  # pawn_table[piece_type][cell] = Array[Vector2i]

func _ready():
	build_tables()

func build_tables():
	for piece_type in leaper_offsets:
		leaper_table[piece_type] = {}
		for y in HEIGHT:
			for x in WIDTH:
				var cell = Vector2i(x, y)
				leaper_table[piece_type][cell] = _compute_leaper_rays(cell, leaper_offsets[piece_type])
	for piece_type in slider_offsets:
		slider_table[piece_type] = {}
		for y in HEIGHT:
			for x in WIDTH:
				var cell = Vector2i(x, y)
				slider_table[piece_type][cell] = _compute_slider_rays(cell, slider_offsets[piece_type])
	for piece_type in pawn_offsets:
		pawn_table[piece_type] = {}
		for y in HEIGHT:
			for x in WIDTH:
				var cell = Vector2i(x, y)
				pawn_table[piece_type][cell] = _compute_pawn_rays(cell, pawn_offsets[piece_type])

func _compute_leaper_rays(cell: Vector2i, offsets: Array) -> Array:
	var rays := []
	for offset in offsets:
		var dest = cell + offset
		if _is_in_bounds(dest):
			rays.append(dest)
	return rays

func _compute_pawn_rays(cell: Vector2i, offsets: Array) -> Array:
	var rays := []
	var dir = offsets[0]  # single-step offset, e.g. Vector2i(0,-1)
	
	for o in offsets:
		if abs(o.x) + abs(o.y) < abs(dir.x) + abs(dir.y):
			dir = o

	# forward squares (straight ahead, 1 and 2)
	for offset in offsets:
		var dest = cell + offset
		if _is_in_bounds(dest):
			rays.append(dest)

	# diagonal captures (forward-diagonal and backward-diagonal)
	var diag_offsets = [
		Vector2i(-1, dir.y), Vector2i(1, dir.y),
		Vector2i(-1, -dir.y), Vector2i(1, -dir.y)
	]
	for offset in diag_offsets:
		var diag = cell + offset
		if _is_in_bounds(diag):
			rays.append(diag)

	return rays

func _compute_slider_rays(cell: Vector2i, offsets: Array) -> Array:
	var rays := []
	for offset in offsets:
		var ray := []
		var current = cell + offset
		while _is_in_bounds(current):
			ray.append(current)
			current += offset
		rays.append(ray)
	return rays

func _is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < WIDTH and cell.y >= 0 and cell.y < HEIGHT
