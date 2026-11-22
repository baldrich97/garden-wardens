## One hand-authored level: the water you start with, the cards on the bar, and the wave.
class_name LevelDef
extends RefCounted

var title: String
var water: int
var cards: Array[int]
var wave: Array[Vector3]
## Wardens the board plants for free before Start, as Vector3i(column, row, warden kind).
var pre_placed: Array[Vector3i] = []


func _init(p_title: String, p_water: int, p_cards: Array[int], p_wave: Array[Vector3], p_pre_placed: Array[Vector3i] = []) -> void:
	title = p_title
	water = p_water
	cards = p_cards
	wave = p_wave
	pre_placed = p_pre_placed
