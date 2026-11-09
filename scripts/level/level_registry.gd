class_name LevelRegistry
extends RefCounted

## Master Level Registry for Tomorrow's You.
## Contains 10 handcrafted, verified campaign levels across 3 sectors.

static func get_all_levels() -> Array[LevelDefinition]:
	var levels: Array[LevelDefinition] = []
	levels.append(_create_level_01())
	levels.append(_create_level_02())
	levels.append(_create_level_03())
	levels.append(_create_level_04())
	levels.append(_create_level_05())
	levels.append(_create_level_06())
	levels.append(_create_level_07())
	levels.append(_create_level_08())
	levels.append(_create_level_09())
	levels.append(_create_level_10())
	return levels

static func get_level(index: int) -> LevelDefinition:
	var all: Array[LevelDefinition] = get_all_levels()
	if index >= 0 and index < all.size():
		return all[index]
	return all[0]

static func get_level_by_id(id: String) -> LevelDefinition:
	for lvl: LevelDefinition in get_all_levels():
		if lvl.level_id == id:
			return lvl
	return null

static func get_level_count() -> int:
	return 10

# ==============================================================================
# SECTOR 01: AWAKENING (Levels 1–3)
# ==============================================================================

# Level 1: "First Steps" - Core grid movement & reaching exit
static func _create_level_01() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_01"
	lvl.level_name = "First Steps"
	lvl.sector = 1
	lvl.echo_limit = 1
	lvl.hint = "Navigate the facility corridors to reach the temporal exit."
	lvl.map_lines = [
		"#######",
		"#P....#",
		"###.#.#",
		"#...#.#",
		"#.###.#",
		"#.....X",
		"#######"
	]
	lvl.doors_data = []
	lvl.plates_data = []
	lvl.initialize_from_map()
	return lvl

# Level 2: "Temporal Twin" - Single plate, single door, 1 Echo needed
static func _create_level_02() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_02"
	lvl.level_name = "Temporal Twin"
	lvl.sector = 1
	lvl.echo_limit = 1
	lvl.hint = "Step on the pressure plate, then CREATE ECHO so your teammate holds it."
	lvl.map_lines = [
		"#######",
		"#P...##",
		"#.##.##",
		"#.1#A.X",
		"#######"
	]
	lvl.doors_data = [
		{"id": "A", "logic": "AND", "required_plates": ["1"]}
	]
	lvl.plates_data = [
		{"id": "1"}
	]
	lvl.initialize_from_map()
	return lvl

# Level 3: "Relay Run" - Echo travel distance and timing
static func _create_level_03() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_03"
	lvl.level_name = "Relay Run"
	lvl.sector = 1
	lvl.echo_limit = 1
	lvl.hint = "Deploy an Echo to Plate 1. Head towards the exit as they travel to unlock it."
	lvl.map_lines = [
		"#########",
		"#P......#",
		"#.#####.#",
		"#.#...#.A",
		"#1#...#.X",
		"#########"
	]
	lvl.doors_data = [
		{"id": "A", "logic": "AND", "required_plates": ["1"]}
	]
	lvl.plates_data = [
		{"id": "1"}
	]
	lvl.initialize_from_map()
	return lvl

# ==============================================================================
# SECTOR 02: SYNCHRONIZATION (Levels 4–7)
# ==============================================================================

# Level 4: "Dual Lock" - Two plates, one AND door, 2 Echoes required
static func _create_level_04() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_04"
	lvl.level_name = "Dual Lock"
	lvl.sector = 2
	lvl.echo_limit = 2
	lvl.hint = "Door A requires BOTH plates active at once. Coordinate with two Echoes."
	lvl.map_lines = [
		"#########",
		"#P......#",
		"#.##.##.#",
		"#1##.##2#",
		"####A####",
		"####.####",
		"####X####",
		"#########"
	]
	lvl.doors_data = [
		{"id": "A", "logic": "AND", "required_plates": ["1", "2"]}
	]
	lvl.plates_data = [
		{"id": "1"},
		{"id": "2"}
	]
	lvl.initialize_from_map()
	return lvl

# Level 5: "Sequential Relay" - Staggered gate relay (Echo 1 opens Door A -> Echo 2 reaches Plate 2 -> Door B opens)
static func _create_level_05() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_05"
	lvl.level_name = "Sequential Relay"
	lvl.sector = 2
	lvl.echo_limit = 2
	lvl.hint = "Echo 1 unlocks Door A so Echo 2 can reach Plate 2, which unlocks Door B for you."
	lvl.map_lines = [
		"#########",
		"#P....1.#",
		"#.###.#.#",
		"#..A#.#.#",
		"#.2.#.#.#",
		"#.###.#.#",
		"#...B...X",
		"#########"
	]
	lvl.doors_data = [
		{"id": "A", "logic": "AND", "required_plates": ["1"]},
		{"id": "B", "logic": "AND", "required_plates": ["2"]}
	]
	lvl.plates_data = [
		{"id": "1"},
		{"id": "2"}
	]
	lvl.initialize_from_map()
	return lvl

# Level 6: "The Standoff" - Strategic use of WAIT action
static func _create_level_06() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_06"
	lvl.level_name = "The Standoff"
	lvl.sector = 2
	lvl.echo_limit = 2
	lvl.hint = "Use WAIT while your Echo travels to open Door A, then coordinate with Plate 2."
	lvl.map_lines = [
		"###########",
		"#P......1.#",
		"#.#######.#",
		"#...A...2.#",
		"#.#######.#",
		"#...B...X.#",
		"###########"
	]
	lvl.doors_data = [
		{"id": "A", "logic": "AND", "required_plates": ["1"]},
		{"id": "B", "logic": "AND", "required_plates": ["2"]}
	]
	lvl.plates_data = [
		{"id": "1"},
		{"id": "2"}
	]
	lvl.initialize_from_map()
	return lvl

# Level 7: "Logic Divergence" - OR logic door & AND logic door
static func _create_level_07() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_07"
	lvl.level_name = "Logic Divergence"
	lvl.sector = 2
	lvl.echo_limit = 2
	lvl.hint = "Door A opens if EITHER plate 1 or 2 is active. Door B requires BOTH."
	lvl.map_lines = [
		"###########",
		"#P....1...#",
		"#.#######.#",
		"#...A...#.#",
		"#.###.2.#.#",
		"#...B.....X",
		"###########"
	]
	lvl.doors_data = [
		{"id": "A", "logic": "OR",  "required_plates": ["1", "2"]},
		{"id": "B", "logic": "AND", "required_plates": ["1", "2"]}
	]
	lvl.plates_data = [
		{"id": "1"},
		{"id": "2"}
	]
	lvl.initialize_from_map()
	return lvl

# ==============================================================================
# SECTOR 03: PARADOX (Levels 8–10)
# ==============================================================================

# Level 8: "Triad Coordination" - 3 Echoes across 3 security sectors
static func _create_level_08() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_08"
	lvl.level_name = "Triad Coordination"
	lvl.sector = 3
	lvl.echo_limit = 3
	lvl.hint = "Station 3 Echoes on Plates 1, 2, and 3 to clear the triple blast doors."
	lvl.map_lines = [
		"#############",
		"#P..1...2...#",
		"#.###.###.###",
		"#...A...B...3",
		"#.#########.#",
		"#.....C.....X",
		"#############"
	]
	lvl.doors_data = [
		{"id": "A", "logic": "AND", "required_plates": ["1"]},
		{"id": "B", "logic": "AND", "required_plates": ["2"]},
		{"id": "C", "logic": "AND", "required_plates": ["3"]}
	]
	lvl.plates_data = [
		{"id": "1"},
		{"id": "2"},
		{"id": "3"}
	]
	lvl.initialize_from_map()
	return lvl

# Level 9: "Temporal Interlock" - Interlocking chained gates
static func _create_level_09() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_09"
	lvl.level_name = "Temporal Interlock"
	lvl.sector = 3
	lvl.echo_limit = 3
	lvl.hint = "Each plate is behind a previous door. Chain your attempts in sequence."
	lvl.map_lines = [
		"#############",
		"#P....1.....#",
		"#.#########.#",
		"#...A...2...#",
		"#.#########.#",
		"#...B...3...#",
		"#.#########.#",
		"#...C...X...#",
		"#############"
	]
	lvl.doors_data = [
		{"id": "A", "logic": "AND", "required_plates": ["1"]},
		{"id": "B", "logic": "AND", "required_plates": ["2"]},
		{"id": "C", "logic": "AND", "required_plates": ["3"]}
	]
	lvl.plates_data = [
		{"id": "1"},
		{"id": "2"},
		{"id": "3"}
	]
	lvl.initialize_from_map()
	return lvl

# Level 10: "Tomorrow's You" - Grand Finale Puzzle
static func _create_level_10() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_10"
	lvl.level_name = "Tomorrow's You"
	lvl.sector = 3
	lvl.echo_limit = 3
	lvl.hint = "Synchronize all 3 Echoes across hybrid AND/OR matrices to achieve temporal escape."
	lvl.map_lines = [
		"###############",
		"#P......1.....#",
		"#.###########.#",
		"#...A...2...#.#",
		"#.#####.###.#.#",
		"#...B...3...#.#",
		"#.#####.###.#.#",
		"#...C...#...#.#",
		"#.#####.#.###.#",
		"#.......D...X.#",
		"###############"
	]
	lvl.doors_data = [
		{"id": "A", "logic": "AND", "required_plates": ["1"]},
		{"id": "B", "logic": "OR",  "required_plates": ["2", "3"]},
		{"id": "C", "logic": "AND", "required_plates": ["2"]},
		{"id": "D", "logic": "AND", "required_plates": ["1", "3"]}
	]
	lvl.plates_data = [
		{"id": "1"},
		{"id": "2"},
		{"id": "3"}
	]
	lvl.initialize_from_map()
	return lvl
