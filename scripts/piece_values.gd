class_name PieceValues
extends RefCounted

## One table, three consumers: FesshRules.evaluate() (material scoring),
## FesshEngine._order_moves() (try valuable captures first), and
## MoveQualityTracker (move/capture currency). Change a number here and
## all three follow. No objectively correct values -- tune by playtesting.

static var RANK := {
	"pawn": 1.0,
	"knight": 3.0,
	"bishop": 3.0,
	"rook": 5.0,
	"queen": 9.0,
	"king": 0.0, # can't be captured, and its movement is already incentivized
				 # by the win condition itself -- bump this above 0 if you
				 # want king moves to also earn currency.
}

static func base_type(piece_type: String) -> String:
	return piece_type.substr(2) # strips "a_"/"r_" prefix

static func rank_value(piece_type: String) -> float:
	return RANK.get(base_type(piece_type), 0.0)
