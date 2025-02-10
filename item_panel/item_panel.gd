extends Node

# This is the *only* thing I have decompiled from Sonic R, because it was
# simple enough.
# The Powerup choosing logic is in the function at 0x429CA0.
# Sonic R has five tables, at (0x45E1C8 + Place * 0x14), where Place is [1, 5].
#   Each table is 20 bytes long, with each byte being a powerup.
# This table is sampled at random. There is bias against the final:
#   RNG seems to be a table at 0x502170, with a length of 256.
#   It is iterated through, and then looped.
#   It has a uniform distribution of values [0x0, 0xFF] in a random order.
#   (I don't know that this is correct, but it looks correct with my eyes)
#   The index into the powerup table is the RNG value / 0xD, truncated down.
#   Since 0xFF / 0xD = 19.61..., index 19 is 39% less likely to be chosen.
# There is some unknown condition that will replace Water Shield or Lightning
# Shield with 20 Rings instead. I'm going to ignore it for now.
# Here is the value each powerup has:
#   Fleet Feet: 1
#   5 Rings: 2
#   10 Rings: 3
#   20 Rings: 4
#   Water Shield: 5
#   Lightning Shield: 6
# Here are the tables for each place:
#   1st Place: 2 2 2 2 2 2 2 2 2 2 3 3 3 3 3 3 4 5 5 6
#   2nd Place: 1 1 2 2 2 2 2 2 2 2 3 3 3 3 4 4 5 5 6 6
#   3rd Place: 1 1 1 1 2 2 2 2 2 2 3 3 3 3 4 4 5 5 6 6
#   4th Place: 1 1 1 1 1 1 1 1 2 3 3 4 4 4 4 4 6 6 6 6
#   5th Place: 1 1 1 1 1 1 1 1 1 1 4 4 4 4 4 4 6 6 6 6
# It will probably be easiest to ignore the bias against the final powerup.
# No-one will notice, except for you because you are reading my source code.
# I'm sorry for making you read such garbage :(

# Lightning Shield appear to last 30 seconds. Water is seemingly infinite.
# Fleet feet last around 8 seconds.
# I have no idea what fleet feet actually does to speed, so I'm just going
# to increase the acceleration of the player by like 33% or something. Maybe
# its more effective on characters other than Sonic. I've only been testing
# with Sonic so far.

# Water shield has been implemented by hardcoding into the areas where the
# player would normally Swim. There is some jank between going to and from
# land to water, but its fine for now. Maybe if the water actually had a
# hitbox all this would be easier?

# todo: implement lightning shield. maybe just give bigger hitbox?

@export var model: Node3D
@export var hitbox: CollisionShape3D
@export var respawn: Timer
@export var item: PackedScene

const TARGET_SPIN_SPEED := 2.0
const FASTER_SPIN_SPEED := 12.0
var spin_speed := TARGET_SPIN_SPEED
const SPIN_ACCEL := 3.0

const Item := preload("res://item_panel/item/item.gd")

const item_tables := [
	[Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.TEN_RINGS, Item.ItemType.TEN_RINGS, Item.ItemType.TEN_RINGS, Item.ItemType.TEN_RINGS, Item.ItemType.TEN_RINGS, Item.ItemType.TEN_RINGS, Item.ItemType.TWENTY_RINGS, Item.ItemType.WATER_SHIELD, Item.ItemType.WATER_SHIELD, Item.ItemType.LIGHTNING_SHIELD],
	[Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.TEN_RINGS, Item.ItemType.TEN_RINGS, Item.ItemType.TEN_RINGS, Item.ItemType.TEN_RINGS, Item.ItemType.TWENTY_RINGS, Item.ItemType.TWENTY_RINGS, Item.ItemType.WATER_SHIELD, Item.ItemType.WATER_SHIELD, Item.ItemType.LIGHTNING_SHIELD, Item.ItemType.LIGHTNING_SHIELD],
	[Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.FIVE_RINGS, Item.ItemType.TEN_RINGS, Item.ItemType.TEN_RINGS, Item.ItemType.TEN_RINGS, Item.ItemType.TEN_RINGS, Item.ItemType.TWENTY_RINGS, Item.ItemType.TWENTY_RINGS, Item.ItemType.WATER_SHIELD, Item.ItemType.WATER_SHIELD, Item.ItemType.LIGHTNING_SHIELD, Item.ItemType.LIGHTNING_SHIELD],
	[Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FIVE_RINGS, Item.ItemType.TEN_RINGS, Item.ItemType.TEN_RINGS, Item.ItemType.TWENTY_RINGS, Item.ItemType.TWENTY_RINGS, Item.ItemType.TWENTY_RINGS, Item.ItemType.TWENTY_RINGS, Item.ItemType.TWENTY_RINGS, Item.ItemType.LIGHTNING_SHIELD, Item.ItemType.LIGHTNING_SHIELD, Item.ItemType.LIGHTNING_SHIELD, Item.ItemType.LIGHTNING_SHIELD],
	[Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.FLEET_FEET, Item.ItemType.TWENTY_RINGS, Item.ItemType.TWENTY_RINGS, Item.ItemType.TWENTY_RINGS, Item.ItemType.TWENTY_RINGS, Item.ItemType.TWENTY_RINGS, Item.ItemType.TWENTY_RINGS, Item.ItemType.LIGHTNING_SHIELD, Item.ItemType.LIGHTNING_SHIELD, Item.ItemType.LIGHTNING_SHIELD, Item.ItemType.LIGHTNING_SHIELD]
]

func _on_body_entered(player: Node3D) -> void:
	# speen!
	spin_speed = FASTER_SPIN_SPEED
	hitbox.disabled = true
	respawn.start()
	# give player random item depending on their position
	var instance := item.instantiate() as Item
	var place := 2 # (there are no other players yet... todo: implement)
	instance.apply_to(player, item_tables[place].pick_random())

func _on_timer_timeout() -> void:
	hitbox.disabled = false

func _physics_process(delta):
	spin_speed = move_toward(spin_speed, TARGET_SPIN_SPEED, SPIN_ACCEL * delta)
	model.rotate_y(spin_speed * delta)
