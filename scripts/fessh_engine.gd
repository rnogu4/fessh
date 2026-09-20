class_name FesshEngine
extends RefCounted

## Generic search. Everything Fessh-specific is injected via `rules`, which
## must duck-type this interface:
##
##   rules.get_legal_moves(board: FesshBoard, color: String) -> Array[FesshMove]
##   rules.is_terminal(board: FesshBoard) -> Dictionary
##       returns {"over": bool, "winner": String}  # winner is "" for a draw
##   rules.evaluate(board: FesshBoard, color: String) -> float
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
func find_best_move(board: FesshBoard, color: String, depth: int) -> FesshMove:
	nodes_searched = 0
	var best_move: FesshMove = null
	var best_score := -INF
	var alpha := -INF
	var beta := INF

	var moves: Array = rules.get_legal_moves(board, color)
	_order_moves(moves)

	for move in moves:
		var next_board := board.clone()
		next_board.apply_move(move)
		var score := -_negamax(next_board, depth - 1, -beta, -alpha, board.opponent_of(color))
		if score > best_score:
			best_score = score
			best_move = move
		alpha = max(alpha, score)

	return best_move

## Iterative deepening wrapper: searches depth 1, 2, 3... and keeps the best
## move found so far. Call this with a time budget from your calling code
## (e.g. stop calling deeper searches once you've used your time slice) --
## useful once fixed depth gets too slow or too shallow depending on position.
func find_best_move_iterative(board: FesshBoard, color: String, max_depth: int) -> FesshMove:
	var best_move: FesshMove = null
	for d in range(1, max_depth + 1):
		var move := find_best_move(board, color, d)
		if move != null:
			best_move = move
	return best_move

func _negamax(board: FesshBoard, depth: int, alpha: float, beta: float, color: String) -> float:
	nodes_searched += 1

	var terminal: Dictionary = rules.is_terminal(board)
	if terminal["over"]:
		if terminal["winner"] == color:
			return WIN_SCORE + depth       # prefer winning sooner
		elif terminal["winner"] == "":
			return 0.0
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
