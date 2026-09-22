class_name PieceStub
extends RefCounted

## Plain-data stand-in for a Piece node, used only by the search board.
## Your valid_*_moves functions read `.team` and `.piece_type` off whatever
## get_piece_at() returns -- this gives them exactly that shape without any
## Node2D/Sprite overhead, so cloning boards for search stays cheap.

var piece_type: String
var team: Piece.Team

func _init(_piece_type: String, _team: Piece.Team) -> void:
	piece_type = _piece_type
	team = _team

func duplicate_stub() -> PieceStub:
	return PieceStub.new(piece_type, team)
