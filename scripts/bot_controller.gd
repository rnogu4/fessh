class_name BotController
extends Node

## Attach as a node in your game scene. Call setup() once with your
## GameManager, then call take_turn() whenever it becomes the bot's turn.
## Runs the search on a background Thread so the game doesn't freeze.

@export var bot_team: Piece.Team = Piece.Team.ABYSSAL
@export var difficulty_level: int = 1

var game_manager: GameManager
var rules: FesshRules
var engine: FesshEngine
var thread: Thread
var profile: Dictionary
var powerup_shop: PowerupShop # optional: assign from your scene setup script to auto show/hide it per level

func setup(_game_manager: GameManager, _rules: FesshRules = null) -> void:
	game_manager = _game_manager
	rules = _rules if _rules != null else FesshRules.new(game_manager)
	engine = FesshEngine.new(rules)
	set_level(difficulty_level)
	# TurnTracker is assumed to be an autoload (matches how game_manager.gd
	# already calls TurnTracker.end_turn() with no reference to it).
	TurnTracker.turn_started.connect(_on_turn_started)
	game_manager.powerup_manager.turn_continues.connect(_on_turn_continues)

func set_level(level: int) -> void:
	difficulty_level = level
	profile = Difficulty.profile_for_level(level)
	game_manager.powerup_manager.enabled = profile["powerups_enabled"]
	if powerup_shop != null:
		powerup_shop.visible = profile["powerups_enabled"]

## turn_started fires once from TurnTracker._ready() AND after every
## end_turn(), so this one hook covers the bot going first or going second.
func _on_turn_started(team: String, _turn_number: int) -> void:
	if not game_manager.game_active:
		return
	if TurnTracker.get_current_team_number(team) == bot_team:
		take_turn()

## Extra Move doesn't go through TurnTracker (the turn doesn't pass), so it
## needs its own hook to keep the bot acting.
func _on_turn_continues(team: Piece.Team) -> void:
	if game_manager.game_active and team == bot_team:
		take_turn()

func take_turn() -> void:
	if thread != null and thread.is_alive():
		return # already thinking, don't start a second search

	# Snapshot on the main thread, BEFORE the background thread starts,
	# so the search never reads live game state while it could be changing.
	var search_board := SearchBoard.from_game_manager(game_manager)

	thread = Thread.new()
	thread.start(_search_in_background.bind(search_board))

func _search_in_background(search_board: SearchBoard) -> void:
	var best_move: FesshMove = engine.find_best_move(
		search_board, bot_team, profile["depth"], profile["randomness_margin"], profile["blunder_chance"]
	)
	call_deferred("_apply_move", best_move)

func _apply_move(move: FesshMove) -> void:
	if move != null:
		_maybe_use_powerup(move)
		game_manager.move_piece(move.from, move.to, true)
	else:
		push_warning("BotController: no legal move found for %s" % bot_team)
	if thread != null:
		thread.wait_to_finish()
		thread = null

## Intentionally basic v1: the search itself doesn't reason about powerups
## (that would mean modeling currency and the shop inside the search tree,
## a much bigger change), so this is a bolt-on policy, not a real strategy.
## Right now: sometimes shield the piece it's about to move, if affordable.
func _maybe_use_powerup(move: FesshMove) -> void:
	if not game_manager.powerup_manager.enabled:
		return
	if randf() < 0.5:
		var piece := game_manager.get_piece_at(move.from)
		if piece != null:
			game_manager.powerup_manager.buy_shield(bot_team, piece)
			
func _exit_tree() -> void:
	if thread != null and thread.is_alive():
		thread.wait_to_finish()
		thread = null
