class_name PowerupShop
extends Control

## Attach to an empty Control node placed beside the board in your UI scene.
## Assign your 128x128 shop background and each 16x16 powerup icon in the
## Inspector -- everything else (layout, labels, buttons) is built in code.
##
## Wire-up, once per game start:
##   $UI/PowerupShop.setup(game_manager, player_team)
## and give BotController a reference so it can show/hide this per level:
##   $BotController.powerup_shop = $UI/PowerupShop

@export var shop_background: Texture2D
@export var shield_icon: Texture2D
@export var block_square_icon: Texture2D
@export var teleport_icon: Texture2D
@export var extra_move_icon: Texture2D
@export var icon_display_size: Vector2 = Vector2(32, 32) # 16x16 source, upscaled so it reads at UI distance

var game_manager: GameManager
var player_team: Piece.Team

var coins_label: Label
var button_container: VBoxContainer
var background_rect: TextureRect

func setup(_game_manager: GameManager, _player_team: Piece.Team) -> void:
	game_manager = _game_manager
	player_team = _player_team
	_build_ui()
	set_process(true)

func _process(_delta: float) -> void:
	if game_manager != null and coins_label != null:
		coins_label.text = "Coins: %d" % int(game_manager.move_quality_tracker.get_currency(player_team))

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	# Set total shop dimensions
	custom_minimum_size = Vector2(120, 160)

	# 1. Background Panel
	background_rect = TextureRect.new()
	background_rect.texture = shop_background
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_SCALE
	background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background_rect)

	# 2. Outer Margin Container (keeps buttons inside the wooden border)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	# 3. Main Vertical Layout
	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(main_vbox)

	# 4. Currency Header
	coins_label = Label.new()
	coins_label.text = "Coins: 0"
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coins_label.add_theme_font_size_override("font_size", 10)
	coins_label.add_theme_color_override("font_color", Color("f0e6d2"))
	main_vbox.add_child(coins_label)

	# 5. Buttons Container
	button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 3)
	main_vbox.add_child(button_container)

	_add_row(button_container, "Shield", shield_icon, PowerupManager.SHIELD_COST, _on_shield_pressed)
	_add_row(button_container, "Block", block_square_icon, PowerupManager.BLOCK_SQUARE_COST, _on_block_square_pressed)
	_add_row(button_container, "Teleport", teleport_icon, PowerupManager.TELEPORT_COST, _on_teleport_pressed)
	_add_row(button_container, "Extra", extra_move_icon, PowerupManager.EXTRA_MOVE_COST, _on_extra_move_pressed)

func _add_row(parent: VBoxContainer, label_text: String, icon: Texture2D, cost: float, on_pressed: Callable) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 24)
	button.pressed.connect(on_pressed)

	# Pixel-art button styling: subtle dark overlay that fits the scroll background
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.09, 0.07, 0.6) # Semi-transparent dark wood tint
	style.set_corner_radius_all(3)
	style.set_content_margin_all(2)
	button.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate()
	hover_style.bg_color = Color(0.25, 0.20, 0.15, 0.8)
	button.add_theme_stylebox_override("hover", hover_style)

	var disabled_style := style.duplicate()
	disabled_style.bg_color = Color(0.05, 0.05, 0.05, 0.4)
	button.add_theme_stylebox_override("disabled", disabled_style)

	parent.add_child(button)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 4)
	button.add_child(hbox)

	var icon_rect := TextureRect.new()
	icon_rect.texture = icon
	icon_rect.custom_minimum_size = icon_display_size
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hbox.add_child(icon_rect)

	var label := Label.new()
	label.text = "%s (%dp)" % [label_text, int(cost)]
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color("fff7e6"))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(label)

func _on_shield_pressed() -> void:
	game_manager.powerup_manager.begin_targeting(player_team, "shield")

func _on_block_square_pressed() -> void:
	game_manager.powerup_manager.begin_targeting(player_team, "block_square")

func _on_teleport_pressed() -> void:
	game_manager.powerup_manager.begin_targeting(player_team, "teleport")

func _on_extra_move_pressed() -> void:
	# No board target needed, so this buys immediately rather than entering
	# targeting mode.
	game_manager.powerup_manager.buy_extra_move(player_team)
