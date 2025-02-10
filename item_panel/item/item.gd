extends Sprite3D

enum ItemType {
	FLEET_FEET = 1,
	FIVE_RINGS = 2,
	TEN_RINGS = 3,
	TWENTY_RINGS = 4,
	WATER_SHIELD = 5,
	LIGHTNING_SHIELD = 6,
}

@export var fleet_feet_texture: Texture
@export var five_rings_texture: Texture
@export var ten_rings_texture: Texture
@export var twenty_rings_texture: Texture
@export var water_shield_texture: Texture
@export var lightning_shield_texture: Texture

const BEGIN_Y = 1.0
const END_Y = 1.5
const SPEED = 1.0

const Player := preload("res://PlayerMovement.gd")

func apply_to(player: Player, item_type: ItemType) -> void:
	position.y = BEGIN_Y
	player.add_child(self)
	match item_type:
		ItemType.FLEET_FEET:
			texture = fleet_feet_texture
			player.fleet_feet_timer = player.MAX_FLEET_FEET_TIME
		ItemType.FIVE_RINGS:
			texture = five_rings_texture
			player.rings += 5
		ItemType.TEN_RINGS:
			texture = ten_rings_texture
			player.rings += 10
		ItemType.TWENTY_RINGS:
			texture = twenty_rings_texture
			player.rings += 20
		ItemType.WATER_SHIELD:
			texture = water_shield_texture
			player.shield = Player.Shield.WATER
		ItemType.LIGHTNING_SHIELD:
			texture = lightning_shield_texture
			player.shield = Player.Shield.LIGHTNING

func _physics_process(delta):
	position.y = move_toward(position.y, END_Y, SPEED * delta)
