## A simple needle. It travels right along one row until it hits a vermin.
## Visual: the Needle Spitter's fx/needle_spine.png art; the travel and the hit
## test live in GardenBoard and are unchanged.
class_name ShotActor
extends Control

const SPINE: Texture2D = preload("res://assets/sprites/anim/wardens/needle_spitter/fx/needle_spine.png")

var row: int
var column_pos: float
var damage: int


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 5
	var spine := TextureRect.new()
	spine.texture = SPINE
	spine.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	spine.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spine.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(spine)
