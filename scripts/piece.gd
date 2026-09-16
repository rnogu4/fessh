extends Node2D
class_name Piece

enum Team { REEF, ABYSSAL }

@export var piece_type: String = ""
@export var team: Team = Team.REEF
var board_pos: Vector2i

var sprite_2d: Sprite2D

func _ready() -> void:
	pass

func setup(type: String, p_team: Team, pos: Vector2i, texture: Texture2D):
	piece_type = type
	team = p_team
	board_pos = pos
	sprite_2d = get_node("PieceSprite")
	sprite_2d.texture = texture
