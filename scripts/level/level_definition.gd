class_name LevelDefinition
extends Resource

## Data representation of a single puzzle level in Tomorrow's You.

@export var level_id: String = ""
@export var level_name: String = ""
@export var sector: int = 1
@export var echo_limit: int = 3
@export var hint: String = ""
@export var map_lines: Array[String] = []

# Environmental entities
# doors: Array of {"id": "A", "pos": Vector2i, "logic": "AND"|"OR", "required_plates": ["1", "2"]}
@export var doors_data: Array[Dictionary] = []
# plates: Array of {"id": "1", "pos": Vector2i}
@export var plates_data: Array[Dictionary] = []

var grid_width: int = 0
var grid_height: int = 0
var spawn_pos: Vector2i = Vector2i(-1, -1)
var exit_pos: Vector2i = Vector2i(-1, -1)
var walls: Dictionary = {} # Vector2i -> bool

func initialize_from_map() -> bool:
	walls.clear()
	grid_height = map_lines.size()
	grid_width = 0
	for line: String in map_lines:
		if line.length() > grid_width:
			grid_width = line.length()

	var spawn_count: int = 0
	var exit_count: int = 0

	for y in range(map_lines.size()):
		var line: String = map_lines[y]
		for x in range(line.length()):
			var char_code: String = line[x]
			var pos: Vector2i = Vector2i(x, y)
			match char_code:
				"#":
					walls[pos] = true
				"P":
					spawn_pos = pos
					spawn_count += 1
				"X":
					exit_pos = pos
					exit_count += 1
				"1", "2", "3", "4":
					# Auto-register plate position or add new
					var plate_found: bool = false
					for p: Dictionary in plates_data:
						if p.get("id") == char_code:
							plate_found = true
							if not p.has("pos"):
								p["pos"] = pos
							break
					if not plate_found:
						plates_data.append({"id": char_code, "pos": pos})
				"A", "B", "C", "D":
					# Auto-register door position if defined
					for d: Dictionary in doors_data:
						if d.get("id") == char_code and not d.has("pos"):
							d["pos"] = pos

	# Verify and resolve any missing positions for plates and doors
	for p: Dictionary in plates_data:
		if not p.has("pos"):
			var plate_id: String = p.get("id", "")
			for y in range(map_lines.size()):
				var line: String = map_lines[y]
				for x in range(line.length()):
					if line[x] == plate_id:
						p["pos"] = Vector2i(x, y)

	for d: Dictionary in doors_data:
		if not d.has("pos"):
			var door_id: String = d.get("id", "")
			for y in range(map_lines.size()):
				var line: String = map_lines[y]
				for x in range(line.length()):
					if line[x] == door_id:
						d["pos"] = Vector2i(x, y)

	return validate().is_empty()

func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_width and pos.y >= 0 and pos.y < grid_height

func is_wall(pos: Vector2i) -> bool:
	if not is_in_bounds(pos):
		return true
	return walls.has(pos)

func get_door_at(pos: Vector2i) -> Dictionary:
	for d: Dictionary in doors_data:
		if d.get("pos", Vector2i(-1, -1)) == pos:
			return d
	return {}

func get_plate_at(pos: Vector2i) -> Dictionary:
	for p: Dictionary in plates_data:
		if p.get("pos", Vector2i(-1, -1)) == pos:
			return p
	return {}

func validate() -> Array[String]:
	var errors: Array[String] = []
	if level_id.is_empty():
		errors.append("Level ID is empty")
	if map_lines.is_empty():
		errors.append("Map lines are empty")
		return errors

	if spawn_pos == Vector2i(-1, -1):
		errors.append("No player spawn (P) found")
	if exit_pos == Vector2i(-1, -1):
		errors.append("No exit (X) found")
	if echo_limit <= 0 or echo_limit > 5:
		errors.append("Echo limit must be between 1 and 5 (got %d)" % echo_limit)

	# Validate plates
	var plate_ids: Dictionary = {}
	for p: Dictionary in plates_data:
		var pid: String = str(p.get("id", ""))
		if pid.is_empty():
			errors.append("Plate missing ID")
		elif plate_ids.has(pid):
			errors.append("Duplicate plate ID: " + pid)
		else:
			plate_ids[pid] = true

	# Validate doors
	var door_ids: Dictionary = {}
	for d: Dictionary in doors_data:
		var did: String = str(d.get("id", ""))
		if did.is_empty():
			errors.append("Door missing ID")
		elif door_ids.has(did):
			errors.append("Duplicate door ID: " + did)
		else:
			door_ids[did] = true

		var req_plates: Array = d.get("required_plates", [])
		if req_plates.is_empty():
			errors.append("Door %s has no required plates" % did)
		for rpid in req_plates:
			if not plate_ids.has(str(rpid)):
				errors.append("Door %s references non-existent plate %s" % [did, str(rpid)])

		var logic: String = str(d.get("logic", "AND")).to_upper()
		if logic != "AND" and logic != "OR":
			errors.append("Door %s has invalid logic mode %s" % [did, logic])

	return errors
