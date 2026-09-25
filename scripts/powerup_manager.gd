class_name PowerupManager
extends RefCounted

## Same shop, same costs, for both the player and the bot -- call buy_*()
## from your UI for the player, and from BotController for the bot.
## Costs and durations are starting points to balance through playtesting,
## same caveat as Difficulty: there's no formula to derive these from,
## they just need to feel right once you're actually playing games.

signal turn_continues(team: Piece.Team) # emitted instead of a normal turn pass, for Extra Move

const SHIELD_COST := 8.0
const SHIELD_DURATION := 3   # turns of protection

const BLOCK_SQUARE_COST := 6.0
const BLOCK_DURATION := 3    # turns before the claim expires

const TELEPORT_COST := 10.0

const EXTRA_MOVE_COST := 15.0

var game_manager: GameManager
var currency: MoveQualityTracker
var pending_extra_move: Dictionary = {} # Piece.Team -> bool
var enabled: bool = false # set by BotController.set_level() per Difficulty profile

## ---- Click-to-target flow, for the player's shop UI ----
## Shield/Block Square/Teleport need the player to pick a piece or square
## after buying; Extra Move doesn't (call buy_extra_move directly from its
## button). The shop calls begin_targeting() on button press; GameManager's
## _unhandled_input calls handle_targeting_click() on the next board click
## instead of treating it as a normal move.
var targeting_mode: String = "" # "", "shield", "block_square", "teleport"
var targeting_team: Piece.Team
var teleport_source_piece: Piece = null

func begin_targeting(team: Piece.Team, mode: String) -> void:
	targeting_mode = mode
	targeting_team = team
	teleport_source_piece = null

func cancel_targeting() -> void:
	targeting_mode = ""
	teleport_source_piece = null

## Returns true if the click was consumed as a powerup target (so
## GameManager should skip its normal drag/move handling for this click).
func handle_targeting_click(cell: Vector2i) -> bool:
	if targeting_mode == "":
		return false
	match targeting_mode:
		"shield":
			buy_shield(targeting_team, game_manager.get_piece_at(cell))
			cancel_targeting()
		"block_square":
			buy_block_square(targeting_team, cell)
			cancel_targeting()
		"teleport":
			if teleport_source_piece == null:
				var piece := game_manager.get_piece_at(cell)
				if piece != null and piece.team == targeting_team:
					teleport_source_piece = piece
				else:
					cancel_targeting() # clicked something invalid as the source, bail out
			else:
				buy_teleport(targeting_team, teleport_source_piece, cell)
				cancel_targeting()
	return true

func _init(_game_manager: GameManager, _currency: MoveQualityTracker) -> void:
	game_manager = _game_manager
	currency = _currency
	pending_extra_move[Piece.Team.REEF] = false
	pending_extra_move[Piece.Team.ABYSSAL] = false

## ---- Shield ----
func buy_shield(team: Piece.Team, piece: Piece) -> bool:
	if not enabled or piece == null or piece.team != team:
		return false
	if not currency.spend(team, SHIELD_COST):
		return false
	piece.shielded_turns = SHIELD_DURATION
	piece.apply_shield(SHIELD_DURATION)
	return true

## ---- Block Square ----
func buy_block_square(team: Piece.Team, cell: Vector2i) -> bool:
	if not enabled or not game_manager.is_empty_and_unblocked(cell):
		return false
	if not currency.spend(team, BLOCK_SQUARE_COST):
		return false
	game_manager.blocked_squares[cell] = BLOCK_DURATION
	game_manager.add_block_overlay(cell)
	return true

## ---- Teleport ----
## Spends currency, then performs the move itself (via GameManager.teleport_piece,
## which also ends the turn / passes to Extra Move handling like any other move).
func buy_teleport(team: Piece.Team, piece: Piece, to: Vector2i) -> bool:
	if not enabled or piece == null or piece.team != team or piece.piece_type == "a_king" or piece.piece_type == "r_king":
		return false
	if not game_manager.is_empty_and_unblocked(to):
		return false
	if not currency.spend(team, TELEPORT_COST):
		return false
	if not game_manager.teleport_piece(piece, to):
		# Refund if the move somehow failed after payment (shouldn't normally happen
		# given the checks above, but don't eat the player's currency on a bug).
		currency.currency[team] += TELEPORT_COST
		return false
	return true

## ---- Extra Move ----
## Doesn't act immediately -- flags the team's NEXT move this turn to not end
## the turn. Consumed by GameManager._on_move_made via consume_extra_move().
func buy_extra_move(team: Piece.Team) -> bool:
	if not enabled or not currency.spend(team, EXTRA_MOVE_COST):
		return false
	pending_extra_move[team] = true
	return true

func consume_extra_move(team: Piece.Team) -> bool:
	if pending_extra_move.get(team, false):
		pending_extra_move[team] = false
		return true
	return false

## Call once per real move (from GameManager._on_move_made) to count down
## Shield and Block Square durations.
func tick_turn_effects() -> void:
	for y in Board.HEIGHT:
		for x in Board.WIDTH:
			var piece = game_manager.get_piece_at(Vector2i(x, y))
			if piece != null and piece.shielded_turns > 0:
				piece.shielded_turns -= 1
				piece.update_shield_status()

	var expired: Array = []
	for cell in game_manager.blocked_squares.keys():
		game_manager.blocked_squares[cell] -= 1
		if game_manager.blocked_squares[cell] <= 0:
			expired.append(cell)
	for cell in expired:
		game_manager.remove_block_overlay(cell) # Handled below
		game_manager.blocked_squares.erase(cell)
