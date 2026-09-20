class_name FesshMove
extends RefCounted

## A single move. Kept as plain data so it's cheap to create/copy during search.

var from: Vector2i
var to: Vector2i
var piece: Dictionary               # the piece being moved: {type, color, has_moved, ...}
var captured_piece: Dictionary = {} # empty dict = no capture
var captured_pos: Vector2i = Vector2i(-1, -1) # kept separate from `to` in case your
											   # capture rules don't require landing on
											   # the captured piece's square
var flags: Dictionary = {}          # anything custom: promotion, special ability, etc.

func _init(_from := Vector2i.ZERO, _to := Vector2i.ZERO, _piece := {}, _captured := {}, _captured_pos := Vector2i(-1, -1), _flags := {}) -> void:
	from = _from
	to = _to
	piece = _piece
	captured_piece = _captured
	captured_pos = _captured_pos
	flags = _flags

func is_capture() -> bool:
	return not captured_piece.is_empty()

func _to_string() -> String:
	var s := "%s: %s -> %s" % [piece.get("type", "?"), from, to]
	if is_capture():
		s += " (captures %s)" % captured_piece.get("type", "?")
	return s
