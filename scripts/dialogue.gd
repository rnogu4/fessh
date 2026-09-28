class_name IntroDialogue
extends CanvasLayer

## Lives in your main scene as a CanvasLayer. Every time the scene loads
## (first launch AND each level reload), it plays the lines for whatever
## LevelManager.current_level is, then unlocks the game. LevelManager never
## needs a reference to it.
##
## While it's showing, GameManager.game_active is false, so the player can't
## touch the board and the bot won't move.
##
## ASSUMPTION: GameManager and BotController are direct children of the scene
## root -- the same assumption LevelManager already makes.

signal finished

@export var npc_name: String = "???"    # speaker name on level 1
@export var npc_name2: String = "Flub"  # speaker name on levels 2 and 3
@export var npc_portrait: Texture2D
@export var lines1: Array[String] = [
	"Welcome, poor, lost soul.",
	"It seems you've found your way into Davy Jone's locker.",
	"No matter. If you play me and win in a game of Fessh, I'll set your soul free.",
	"HAHA!",
	"What is Fessh you ask?",
	"I believe you surface dwellers have a game similar called *chess*?",
	"You'll learn well enough. I'll give you time to learn the moves and extra bits, then you're on your own.",
	"The basic premise: your king has been taken, and the only way to save it is to bring it home.",
	"Let's see if you can manage it.",
]
@export var lines2: Array[String] = [
	"Nice going. You've been a great sport so I'll tell you my name. It's Flub.",
	"Anyways, now it's time for powerups.",
	"They're... pretty self explanatory.",
	"HAHA! Good luck!"
]
@export var lines3: Array[String] = [
	"Time for the final duel!",
	"Good luck.",
	"Your soul is counting on it..."
]
@export var lines4: Array[String] = [
	"Good game."
]
@export var portrait_size: Vector2 = Vector2(192, 192)
@export var panel_height: float = 140.0
@export var chars_per_second: float = 45.0
@export var font_size: int = 20

var game_manager: GameManager
var bot_controller: BotController

var _root: Control
var _text_label: Label
var _hint: Label
var _tween: Tween
var _current_lines: Array[String] = []
var _line_index: int = -1
var _typing: bool = false
var _active: bool = false

func _ready() -> void:
	layer = 50 # draw above the HUD and shop
	call_deferred("_begin", LevelManager.current_level)

func _lines_for(level: int) -> Array[String]:
	match level:
		1: return lines1
		2: return lines2
		3: return lines3
		4: return lines4
	return []

func _name_for(level: int) -> String:
	return npc_name if level == 1 else npc_name2

func _begin(level: int) -> void:
	_current_lines = _lines_for(level)
	if _current_lines.is_empty():
		queue_free()
		return

	var scene := get_tree().current_scene
	game_manager = scene.get_node_or_null("GameManager")
	bot_controller = scene.get_node_or_null("BotController")
	if game_manager != null:
		game_manager.game_active = false # freezes player input and the bot's turns

	_line_index = -1
	_build_ui(_name_for(level))
	_active = true
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.3)
	_next_line()

func _build_ui(speaker: String) -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP # swallow clicks meant for the board
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	# Portrait row on top, dialogue panel below, pinned to the bottom of the screen.
	var box := VBoxContainer.new()
	box.anchor_left = 0.0
	box.anchor_right = 1.0
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 24.0
	box.offset_right = -24.0
	box.offset_bottom = -24.0
	box.offset_top = -(24.0 + portrait_size.y + panel_height + 8.0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(box)

	var portrait_row := HBoxContainer.new()
	portrait_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(portrait_row)

	var portrait := TextureRect.new()
	portrait.texture = npc_portrait
	portrait.custom_minimum_size = portrait_size
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST # keeps pixel art crisp
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_row.add_child(portrait)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, panel_height)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 14)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	var name_label := Label.new()
	name_label.text = speaker
	name_label.add_theme_font_size_override("font_size", font_size + 2)
	vbox.add_child(name_label)

	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.add_theme_font_size_override("font_size", font_size)
	vbox.add_child(_text_label)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", maxi(font_size - 6, 8))
	_hint.modulate.a = 0.0 # alpha instead of visible, so the layout doesn't jump
	vbox.add_child(_hint)

func _input(event: InputEvent) -> void:
	if not _active:
		return
	var advance := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true
	elif event.is_action_pressed("ui_accept"):
		advance = true
	if advance:
		get_viewport().set_input_as_handled()
		_advance()

## First press finishes the current line instantly; the next press moves on.
func _advance() -> void:
	if _typing:
		_finish_typing()
	else:
		_next_line()

func _next_line() -> void:
	_line_index += 1
	if _line_index >= _current_lines.size():
		_end()
		return

	var line := _current_lines[_line_index]
	_text_label.text = line
	_text_label.visible_characters = 0
	_hint.modulate.a = 0.0
	_hint.text = "Click to begin" if _line_index == _current_lines.size() - 1 else "Click to continue"
	_typing = true

	_tween = create_tween()
	_tween.tween_property(_text_label, "visible_characters", line.length(), line.length() / chars_per_second)
	_tween.finished.connect(_finish_typing)

func _finish_typing() -> void:
	if _tween != null:
		_tween.kill()
	_text_label.visible_characters = -1 # show everything
	_typing = false
	_hint.modulate.a = 0.6

func _end() -> void:
	_active = false
	var fade := create_tween()
	fade.tween_property(_root, "modulate:a", 0.0, 0.3)
	await fade.finished

	if game_manager != null:
		game_manager.game_active = true
		# Only matters if the bot moves first; normally the player (Reef) starts.
		if bot_controller != null:
			var current_team = TurnTracker.get_current_team_number(TurnTracker.get_current_team())
			if current_team == bot_controller.bot_team:
				bot_controller.take_turn()

	finished.emit()
	queue_free()
