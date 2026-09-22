class_name FesshRules
extends RefCounted

## What FesshEngine actually calls during search. Reuses GameManager's
## validity functions against a SearchBoard snapshot instead of the live
## grid, so the capture-rule matrix lives in exactly one place.

var game_manager: GameManager

## ASSUMPTION: "home" means the king's own original back rank (row 0 for
## Abyssal, row HEIGHT-1 for Reef), matching where their own pieces start.
## If home is actually meant to be a wider zone (e.g. rows 0-1 / 10-11),
## change the checks in is_terminal()/evaluate() below to a range test
## instead of an equality test.
const ABYSSAL_HOME_ROW := 0
const REEF_HOME_ROW := SearchBoard.HEIGHT - 1 # 11

func _init(_game_manager: GameManager) -> void:
	game_manager = _game_manager

func get_legal_moves(board: SearchBoard, team: Piece.Team) -> Array:
	var moves: Array = []
	for y in SearchBoard.HEIGHT:
		for x in SearchBoard.WIDTH:
			var from := Vector2i(x, y)
			var piece = board.get_piece_at(from)
			if piece == null or piece.team != team:
				continue
			for to in game_manager.get_all_valid_moves(from, board):
				var captured = board.get_piece_at(to)
				moves.append(FesshMove.new(
					from, to,
					{"type": piece.piece_type, "team": piece.team},
					{} if captured == null else {"type": captured.piece_type, "team": captured.team},
					to if captured != null else Vector2i(-1, -1)
				))
	return moves

func is_terminal(board: SearchBoard) -> Dictionary:
	var abyssal_king := board.find_king_pos(Piece.Team.ABYSSAL)
	var reef_king := board.find_king_pos(Piece.Team.REEF)

	if abyssal_king != Vector2i(-1, -1) and abyssal_king.y == ABYSSAL_HOME_ROW:
		return {"over": true, "winner": Piece.Team.ABYSSAL}
	if reef_king != Vector2i(-1, -1) and reef_king.y == REEF_HOME_ROW:
		return {"over": true, "winner": Piece.Team.REEF}

	return {"over": false, "winner": null}

func evaluate(board: SearchBoard, team: Piece.Team) -> float:
	var opponent := board.opponent_of(team)
	var score := 0.0

	# King progress toward home dominates -- that's the actual win condition.
	# Tune this weight relative to material once you're testing real games.
	var my_king := board.find_king_pos(team)
	var opp_king := board.find_king_pos(opponent)
	var my_home := ABYSSAL_HOME_ROW if team == Piece.Team.ABYSSAL else REEF_HOME_ROW
	var opp_home := ABYSSAL_HOME_ROW if opponent == Piece.Team.ABYSSAL else REEF_HOME_ROW

	if my_king != Vector2i(-1, -1):
		score += (SearchBoard.HEIGHT - abs(my_king.y - my_home)) * 10.0
	if opp_king != Vector2i(-1, -1):
		score -= (SearchBoard.HEIGHT - abs(opp_king.y - opp_home)) * 10.0

	# Material as a tiebreaker -- MATERIAL_WEIGHT controls how much captures
	# matter relative to king progress. Raise it if the bot still ignores
	# good captures in favor of tiny king-progress gains; the king-progress
	# term above tops out around 120, so material needs real weight to compete.
	const MATERIAL_WEIGHT := 15.0
	for y in SearchBoard.HEIGHT:
		for x in SearchBoard.WIDTH:
			var piece = board.get_piece_at(Vector2i(x, y))
			if piece == null:
				continue
			var value: float = PieceValues.rank_value(piece.piece_type) * MATERIAL_WEIGHT
			score += value if piece.team == team else -value

	return score
