## A water droplet. Hover or tap to collect it.
class_name WaterDrop
extends Control

signal collected(amount: int)

var amount: int = UnitCatalog.DEW_AMOUNT
var column_pos: float
var row_pos: float
var land_row: float
var falling := false
var life: float = UnitCatalog.DROP_LIFE
var _taken := false
var _collect_enabled := true


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 6
	var sprite := TextureRect.new()
	sprite.texture = preload("res://assets/sprites/board/water.png")
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(sprite)
	mouse_entered.connect(_collect)
	gui_input.connect(_on_gui_input)


## A sky drop starts above the lawn and drifts down onto [param row]. A dew drop is already sitting on its tile.
func setup(p_amount: int, column: float, row: float, from_sky: bool) -> void:
	amount = p_amount
	column_pos = column
	land_row = row
	if from_sky:
		falling = true
		row_pos = UnitCatalog.SKY_SPAWN_ROW
	else:
		falling = false
		row_pos = row


## Returns true when the drop has expired uncollected. Sky drops do not expire until they land.
func tick(delta: float) -> bool:
	if falling:
		row_pos = minf(land_row, row_pos + UnitCatalog.SKY_FALL_SPEED * delta)
		if row_pos >= land_row:
			falling = false
		return false
	life -= delta
	return life <= 0.0 and not _taken


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_collect()
		accept_event()


func collect() -> void:
	_collect()


## Dragging a card across the lawn must not scoop up every drop it crosses.
func set_collect_enabled(enabled: bool) -> void:
	_collect_enabled = enabled
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func _collect() -> void:
	if _taken or not _collect_enabled:
		return
	_taken = true
	collected.emit(amount)
	queue_free()
