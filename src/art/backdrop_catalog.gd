## Backdrops the match can cycle through. Hills is the Kenney painting. The other four are drafts.
class_name BackdropCatalog
extends RefCounted

const NAMES: Array[String] = [
	"Hills",
	"Flat garden",
	"Morning dew",
	"Late afternoon",
	"Blight edge",
]

const PATHS: Array[String] = [
	"res://assets/sprites/board/background.png",
	"res://assets/sprites/board/backdrops/flat_garden.jpg",
	"res://assets/sprites/board/backdrops/morning_dew.jpg",
	"res://assets/sprites/board/backdrops/late_afternoon.jpg",
	"res://assets/sprites/board/backdrops/blight_edge.jpg",
]


static func count() -> int:
	return NAMES.size()


static func texture_at(index: int) -> Texture2D:
	return load(PATHS[posmod(index, PATHS.size())]) as Texture2D
