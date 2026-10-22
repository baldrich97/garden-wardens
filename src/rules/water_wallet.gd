## Water spent to place Wardens and gained from a Dew Dropper.
class_name WaterWallet
extends RefCounted

var amount: int


func _init(starting: int) -> void:
	amount = starting


func can_afford(cost: int) -> bool:
	return cost >= 0 and amount >= cost


func try_spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	amount -= cost
	return true


func add(gained: int) -> void:
	if gained > 0:
		amount += gained
