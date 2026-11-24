## Portraits for the pre-wave "This wave" roster (GW-AA pass 5).
##
## Slot: assets/art/ui/roster/roster_<vermin folder>.png (e.g.
## roster_ladybug.png), one paper-cutout portrait per vermin, any size,
## transparent background. Until Asset Gen's portraits land, each vermin
## shows its paper-cutout idle frame from AnimLibrary (idle_100 frame 0, the
## same cut-out it plays on the lawn; no stick or string), not the old
## cartoon sprite.
class_name RosterPortraits
extends RefCounted

const DIR := "res://assets/art/ui/roster/"


static func slot_path(kind: int) -> String:
	return DIR + "roster_%s.png" % AnimLibrary.vermin_folder(kind as UnitCatalog.Vermin).get_file()


## The roster portrait for one vermin kind, and whether it came from the
## slot: {texture, from_slot}.
static func portrait(kind: int) -> Dictionary:
	var slotted := BackdropCatalog.optional(slot_path(kind))
	if slotted != null:
		return {"texture": slotted, "from_slot": true}
	return {"texture": idle_frame(kind), "from_slot": false}


## The vermin's paper-cutout idle frame (frame 0 of its idle clip).
static func idle_frame(kind: int) -> Texture2D:
	var frames := AnimLibrary.vermin(kind as UnitCatalog.Vermin)
	if frames == null:
		return null
	var clip := AnimLibrary.animation_name(frames, "idle", "100")
	if clip.is_empty() or frames.get_frame_count(clip) == 0:
		return null
	return frames.get_frame_texture(clip, 0)
