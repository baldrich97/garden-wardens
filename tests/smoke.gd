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
	var roster := board.find_child("WaveRoster", true, false) as WaveRoster
	if roster == null or not roster.visible or roster.card_count() != _wave_types():
		failures.append("wave roster did not show one card per vermin type")
	var grid := board.find_child("RosterGrid", true, false) as GridContainer
	if grid == null or grid.columns != 2:
		failures.append("wave roster was not two columns")
	var start := board.find_child("StartButton", true, false) as Button
	if start == null or start.text != "Start":
		failures.append("Start button missing before the wave")
	var lawn := board.find_child("Lawn", true, false) as LawnView
	if lawn == null or lawn.column_count() != LawnView.COLUMNS or lawn.tile_count() != LawnView.COLUMNS * LawnView.ROWS:
		failures.append("lawn was not 5 by 12")
	if lawn != null and not lawn.uses_board_art():
		failures.append("lawn did not draw the locked felt board (board v1)")
	var frame := board.find_child("BoardFrame", true, false) as TextureRect
	if frame == null or frame.texture == null or frame.size.x <= 0.0:
		failures.append("felt board frame missing from the lawn")
	var icon := board.find_child("WaterIcon", true, false) as TextureRect
	if icon == null or icon.texture != FxArt.WATER_DROP_SMALL:
		failures.append("top-bar water icon is not the origami small drop")
	var ring := board.find_child("LeafRing", true, false) as TextureRect
	if ring == null or ring.texture != FxArt.LEAF_RING:
		failures.append("placement leaf ring missing from the lawn")
	var backdrop := board.find_child("BackdropButton", true, false) as Button
	if backdrop == null or backdrop.text.is_empty():
		failures.append("backdrop button missing")
	var board_script := board as GardenBoard
	if board_script == null:
		failures.append("board was not a GardenBoard")
	var porch := board.find_child("PlayerEnd", true, false) as TextureRect
	if porch == null or porch.texture == null:
		failures.append("porch missing from the player end")
	var eyes := board.find_child("VerminEnd", true, false) as TextureRect
	if eyes == null or eyes.texture == null:
		failures.append("compost eyes missing from the vermin end")
	var seed_text := ""
	var seed_panel := board.find_child("SeedLabel", true, false)
	if seed_panel != null:
		for child in seed_panel.get_children():
			if child is Label:
				seed_text = (child as Label).text
	if board_script != null and not seed_text.contains("Seed %d" % board_script.visual_seed()):
		failures.append("debug label did not show the visual seed")
	var ability := board.find_child("AbilityButton", true, false) as Button
	if ability == null or not ability.disabled:
		failures.append("Ability button should stay disabled")
	return failures


func _wave_types() -> int:
	var kinds: Array[int] = []
	for entry in LevelCatalog.current().wave:
		var kind := int(entry.y)
		if not kinds.has(kind):
			kinds.append(kind)
	return kinds.size()


func _wave_count() -> int:
	return LevelCatalog.current().wave.size()


func _check_texts(node: Node, failures: PackedStringArray) -> void:
	var texts: PackedStringArray = []
	_collect_text(node, texts)
	for required in ["Garden Wardens", "Dew Dropper", "Needle Spitter", "Stubborn Cone", "200", "Level 1", "Vermin %d" % _wave_count(), "Ability", "Remove", "Speed", "Pause", "Anims"]:
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
