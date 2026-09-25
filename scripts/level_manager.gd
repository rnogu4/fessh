extends Node

signal level_changed(new_level: int)

const MAX_LEVEL := 3

var current_level: int = 1
var game_manager: GameManager
var bot_controller: BotController

func _ready() -> void:
	# Wait until the current scene is fully initialized
	call_deferred("_wire_current_scene")

func _wire_current_scene() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		push_error("LevelManager: get_tree().current_scene is null")
		return
		
	game_manager = scene.get_node_or_null("GameManager")
	bot_controller = scene.get_node_or_null("BotController")

	if game_manager == null or bot_controller == null:
		push_error("LevelManager: couldn't find GameManager/BotController in scene: %s" % scene.name)
		return

	# Safely connect signal
	if game_manager.game_over.is_connected(_on_game_over):
		game_manager.game_over.disconnect(_on_game_over)
	game_manager.game_over.connect(_on_game_over)

	print("LevelManager wired to %s at level %d" % [scene.name, current_level])

	TurnTracker.reset()
	bot_controller.set_level(current_level)

func _on_game_over(winner: Piece.Team) -> void:
	if current_level < MAX_LEVEL:
		current_level += 1
		_reload_level()
	else:
		if winner == bot_controller.bot_team:
			_show_defeat_screen()
		else:
			_show_victory_screen()

func _reload_level() -> void:
	# Ensure bot search thread is safely finished before scene deletion
	if bot_controller != null and bot_controller.thread != null and bot_controller.thread.is_alive():
		bot_controller.thread.wait_to_finish()

	get_tree().reload_current_scene()
	
	# Wait for node tree change signal instead of frame-guessing
	await get_tree().node_added
	await get_tree().process_frame
	
	_wire_current_scene()
	level_changed.emit(current_level)

func _show_victory_screen() -> void:
	print("Victory! Your king made it home.")

func _show_defeat_screen() -> void:
	print("Defeat. Game over.")

func restart_from_level_1() -> void:
	current_level = 1
	_reload_level()
