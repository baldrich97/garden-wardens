extends SceneTree

## Loads the visual prototype and checks the mock roster after the scene is ready.

var _board: Node
var _phase := 0


func _process(_delta: float) -> bool:
	if _phase == 0:
		var packed := load("res://src/prototype/garden_board.tscn") as PackedScene
		if packed == null:
			push_error("SMOKE failed to load garden_board.tscn")
			quit(1)
			return true
		_board = packed.instantiate()
		root.add_child(_board)
		_phase = 1
		return false
	var failures := _check(_board)
	if failures.is_empty():
		print("SMOKE_OK")
		quit(0)
		return true
	for failure in failures:
		push_error("SMOKE %s" % failure)
	quit(1)
	return true


func _check(board: Node) -> PackedStringArray:
	var failures: PackedStringArray = []
	_check_texts(board, failures)
	_check_cards(board, failures)
	_check_textures(board, failures)
	var lawn := board.find_child("Lawn", true, false) as LawnView
	if lawn == null or lawn.tile_count() != 45:
		failures.append("expected 45 lawn tiles")
	var ability := board.find_child("AbilityButton", true, false) as Button
	if ability == null or not ability.disabled:
		failures.append("Ability button should stay disabled")
	return failures


func _check_texts(node: Node, failures: PackedStringArray) -> void:
	var texts: PackedStringArray = []
	_collect_text(node, texts)
	for required in ["Garden Wardens", "Dew Dropper", "Needle Spitter", "Bark Block", "No sprite in this pack", "150", "Wave 1", "Vermin 6", "Ability", "Remove", "Speed", "Pause"]:
		if not _has_text(texts, required):
			failures.append("missing text: %s" % required)


func _check_cards(node: Node, failures: PackedStringArray) -> void:
	var counts := _count_cards(node)
	if counts.x != 3:
		failures.append("expected 3 warden cards, found %d" % counts.x)
	if counts.y != 0:
		failures.append("expected no card selected yet, found %d" % counts.y)
	if counts.z != 0:
		failures.append("expected every card affordable at the start, found %d unaffordable" % counts.z)


func _check_textures(node: Node, failures: PackedStringArray) -> void:
	if node is TextureRect:
		var rect := node as TextureRect
		if rect.visible and rect.texture == null and rect.is_inside_tree():
			failures.append("visible TextureRect has no texture: %s" % str(rect.get_path()))
	for child in node.get_children():
		_check_textures(child, failures)


func _count_cards(node: Node) -> Vector3i:
	var counts := Vector3i.ZERO
	if node is WardenCard:
		counts.x = 1
		var card := node as WardenCard
		if card.is_selected():
			counts.y = 1
		if card.is_unaffordable():
			counts.z = 1
	for child in node.get_children():
		counts += _count_cards(child)
	return counts


func _collect_text(node: Node, texts: PackedStringArray) -> void:
	if node is Label:
		texts.append((node as Label).text)
	elif node is Button:
		texts.append((node as Button).text)
	for child in node.get_children():
		_collect_text(child, texts)


func _has_text(texts: PackedStringArray, required: String) -> bool:
	for text in texts:
		if text == required:
			return true
	return false
