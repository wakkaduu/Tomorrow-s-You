class_name HintDefinition
extends Resource

## Data representation of progressive hints for a puzzle level in Tomorrow's You.
## Each level defines exactly three ordered hint stages:
## Stage 0: OBSERVATION (Small nudge, focus attention)
## Stage 1: STRATEGY (Intended approach, Echo assignments, WAIT needs)
## Stage 2: SOLUTION (Direct step-by-step verified action sequence)

@export var level_id: String = ""
@export var hint_version: int = 1
# hints: Array of Dictionary {"stage": int, "title": String, "text": String}
@export var hints: Array[Dictionary] = []

func _init(p_level_id: String = "", p_hints: Array[Dictionary] = []) -> void:
	level_id = p_level_id
	hints = p_hints
	hint_version = 1

func get_hint_count() -> int:
	return hints.size()

func get_hint(stage_idx: int) -> Dictionary:
	if stage_idx >= 0 and stage_idx < hints.size():
		return hints[stage_idx]
	return {}

func validate() -> Array[String]:
	var errors: Array[String] = []
	if level_id.is_empty():
		errors.append("HintDefinition: Missing level_id")
	if hints.size() != 3:
		errors.append("HintDefinition for %s: Must have exactly 3 hints (got %d)" % [level_id, hints.size()])
	for i in range(hints.size()):
		var h: Dictionary = hints[i]
		if not h.has("text") or str(h["text"]).strip_edges().is_empty():
			errors.append("HintDefinition for %s: Stage %d has empty text" % [level_id, i])
		if not h.has("stage") or int(h["stage"]) != i:
			errors.append("HintDefinition for %s: Stage %d index mismatch" % [level_id, i])
	return errors

