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
	return true

## ---- Block Square ----
func buy_block_square(team: Piece.Team, cell: Vector2i) -> bool:
	if not enabled or not game_manager.is_empty_and_unblocked(cell):
		return false
	if not currency.spend(team, BLOCK_SQUARE_COST):
		return false
	game_manager.blocked_squares[cell] = BLOCK_DURATION
	return true

## ---- Teleport ----
## Spends currency, then performs the move itself (via GameManager.teleport_piece,
## which also ends the turn / passes to Extra Move handling like any other move).
func buy_teleport(team: Piece.Team, piece: Piece, to: Vector2i) -> bool:
	if not enabled or piece == null or piece.team != team:
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

	var expired: Array = []
	for cell in game_manager.blocked_squares.keys():
		game_manager.blocked_squares[cell] -= 1
		if game_manager.blocked_squares[cell] <= 0:
			expired.append(cell)
	for cell in expired:
		game_manager.blocked_squares.erase(cell)
