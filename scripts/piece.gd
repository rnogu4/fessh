extends Node2D
class_name Piece

enum Team { REEF, ABYSSAL }

@export var piece_type: String = ""
@export var team: Team = Team.REEF
var board_pos: Vector2i
var shielded_turns: int = 0 # >0 while a Shield powerup is active on this piece
const SHIELD_TEXTURE = preload("uid://dpi2e7xbiavw8")

var shield_sprite: Sprite2D = null
var sprite_2d: Sprite2D

func _ready() -> void:
	pass

func setup(type: String, p_team: Team, pos: Vector2i, texture: Texture2D):
	piece_type = type
	team = p_team
	board_pos = pos
	sprite_2d = get_node("PieceSprite")
	sprite_2d.texture = texture

func apply_shield(turns: int) -> void:
	shielded_turns = turns
	if shield_sprite == null:
		shield_sprite = Sprite2D.new()
		shield_sprite.texture = SHIELD_TEXTURE
		shield_sprite.z_index = 1 # Renders directly on top of the piece sprite
		add_child(shield_sprite)
	shield_sprite.visible = true

func update_shield_status() -> void:
	if shielded_turns <= 0 and shield_sprite != null:
		shield_sprite.visible = false
