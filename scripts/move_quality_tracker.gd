class_name MoveQualityTracker
extends RefCounted

## Currency economy, funds the powerup shop. Every move earns points based
## on the piece that moved (MOVE_VALUE_MULTIPLIER * that piece's rank), and
## captures earn an additional, larger bonus based on the CAPTURED piece's
## rank (CAPTURE_VALUE_MULTIPLIER). Both scale off the same PieceValues
## table the AI uses for material scoring, so a queen capture is worth far
## more than a pawn shuffle for both the player and the bot.

const MOVE_VALUE_MULTIPLIER := 2.0
const CAPTURE_VALUE_MULTIPLIER := 10.0

var currency: Dictionary = {} # Piece.Team -> float

func _init() -> void:
	currency[Piece.Team.REEF] = 0.0
	currency[Piece.Team.ABYSSAL] = 0.0

## Call right after a move is applied.
## moved_piece_type / captured_piece_type are piece_type strings like
## "a_queen" -- pass "" for captured_piece_type on a non-capture.
func score_move(mover: Piece.Team, moved_piece_type: String, captured_piece_type: String = "") -> float:
	var points: float = PieceValues.rank_value(moved_piece_type) * MOVE_VALUE_MULTIPLIER
	if captured_piece_type != "":
		points += PieceValues.rank_value(captured_piece_type) * CAPTURE_VALUE_MULTIPLIER

	currency[mover] = currency.get(mover, 0.0) + points
	return points

func get_currency(team: Piece.Team) -> float:
	return currency.get(team, 0.0)

## Returns true and deducts if affordable, false (no change) otherwise.
func spend(team: Piece.Team, amount: float) -> bool:
	if get_currency(team) < amount:
		return false
	currency[team] -= amount
	return true
