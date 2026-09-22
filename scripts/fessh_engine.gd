class_name FesshEngine
extends RefCounted

## Generic search. Everything Fessh-specific is injected via `rules`, which
## must duck-type this interface:
##
##   rules.get_legal_moves(board: SearchBoard, color: Piece.Team) -> Array[FesshMove]
##   rules.is_terminal(board: SearchBoard) -> Dictionary
##       returns {"over": bool, "winner": Variant}  # Piece.Team, or null if not over
##   rules.evaluate(board: SearchBoard, color: Piece.Team) -> float
##       positive score = good for `color`. Only called on non-terminal
##       positions at the search horizon.
##
## This file doesn't know or care that Fessh's win condition is "get your
## king home" instead of checkmate -- that logic lives entirely in your
## rules object's is_terminal() and evaluate().

var rules
var nodes_searched: int = 0

const WIN_SCORE := 100000.0

func _init(_rules) -> void:
	rules = _rules

## Depth-limited search entry point. Call this from a Thread/WorkerThreadPool
## so it doesn't block your main game loop.
##
## randomness_margin: collect every root move scoring within this many
## points of the best move, then pick among them at random. 0 = always
## play the single best move (fully deterministic). Higher = more variety,
## but at some point you're including genuinely worse moves.
##
## blunder_chance: probability [0-1] of skipping search entirely and
## playing a uniformly random legal move instead. Cheap way to emulate a
## weaker player who occasionally misses the point completely.
func find_best_move(board: SearchBoard, color: Piece.Team, depth: int, randomness_margin: float = 0.0, blunder_chance: float = 0.0) -> FesshMove:
	nodes_searched = 0

	var moves: Array = rules.get_legal_moves(board, color)
	if moves.is_empty():
		return null

	if blunder_chance > 0.0 and randf() < blunder_chance:
		return moves.pick_random()

	_order_moves(moves)

	var alpha := -INF
	var beta := INF
	var scored: Array = [] # [{move, score}, ...]

	for move in moves:
		var next_board := board.clone()
		next_board.apply_move(move)
		var score := -_negamax(next_board, depth - 1, -beta, -alpha, board.opponent_of(color))
		scored.append({"move": move, "score": score})
		alpha = max(alpha, score)

	scored.sort_custom(func(a, b): return a["score"] > b["score"])
	var best_score: float = scored[0]["score"]

	var top_moves: Array = []
	for entry in scored:
		if best_score - entry["score"] <= randomness_margin:
			top_moves.append(entry["move"])
		else:
			break # scored is sorted descending, nothing further qualifies

	return top_moves.pick_random()

## Iterative deepening wrapper: searches depth 1, 2, 3... and keeps the best
## move found so far. Call this with a time budget from your calling code
## (e.g. stop calling deeper searches once you've used your time slice) --
## useful once fixed depth gets too slow or too shallow depending on position.
func find_best_move_iterative(board: SearchBoard, color: Piece.Team, max_depth: int) -> FesshMove:
	var best_move: FesshMove = null
	for d in range(1, max_depth + 1):
		var move := find_best_move(board, color, d)
		if move != null:
			best_move = move
	return best_move

func _negamax(board: SearchBoard, depth: int, alpha: float, beta: float, color: Piece.Team) -> float:
	nodes_searched += 1

	var terminal: Dictionary = rules.is_terminal(board)
	if terminal["over"]:
		if terminal["winner"] == color:
			return WIN_SCORE + depth       # prefer winning sooner
		elif terminal["winner"] == null:
			return 0.0                     # draw -- FesshRules never actually returns this today
		else:
			return -WIN_SCORE - depth      # prefer losing later, still bad

	if depth <= 0:
		return rules.evaluate(board, color)

	var moves: Array = rules.get_legal_moves(board, color)
	if moves.is_empty():
		# No legal moves but not otherwise terminal. Standard chess would call
		# this stalemate; decide what "no moves" means in Fessh and adjust.
		return -WIN_SCORE - depth

	_order_moves(moves)

	var best := -INF
	for move in moves:
		var next_board := board.clone()
		next_board.apply_move(move)
		var score := -_negamax(next_board, depth - 1, -beta, -alpha, board.opponent_of(color))
		best = max(best, score)
		alpha = max(alpha, score)
		if alpha >= beta:
			break # beta cutoff -- opponent already has a better option elsewhere
	return best

## Cheap move ordering so alpha-beta prunes more branches. Captures are tried
## first here as a placeholder -- once you know what matters in Fessh
## (e.g. moves that advance the king toward the goal rank), score and sort
## by that instead for much better pruning.
func _order_moves(moves: Array) -> void:
	moves.sort_custom(func(a, b): return a.is_capture() and not b.is_capture())
