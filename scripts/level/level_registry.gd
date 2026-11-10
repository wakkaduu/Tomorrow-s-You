class_name LevelRegistry
extends RefCounted

## Master Level Registry for Tomorrow's You.
## Contains 10 handcrafted, verified campaign levels across 3 sectors.
## Intended Echo roles used by the bounded shortest-route solver:
## - Sector 1 (Levels 1–3): Minimum 1 Echo required
## - Sector 2 (Levels 4–7): Minimum 2 Echoes required
## - Sector 3 (Levels 8–10): Minimum 3 Echoes required
## WAIT limits are proven within that intended domain; movement remains unrestricted.
## A pre-existing two-Echo Nightmare sequence-latch route is documented in
## docs/WAIT_BALANCING_REPORT.md; intended roles are not global minimum proofs.

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
# SECTOR 01: AWAKENING (Levels 1–3) — Minimum 1 Echo Required
# ==============================================================================

# Level 1: "First Contact" - Introduces Plate 1 and Door A. Requires 1 Echo to hold plate.
static func _create_level_01() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_01"
	lvl.max_wait_actions = 3
	lvl.level_name = "First Contact"
	lvl.sector = 1
	lvl.difficulty_tier = 1
	lvl.target_3_stars = 18
	lvl.target_2_stars = 25
	lvl.echo_limit = 1
	lvl.min_echoes_required = 1
	lvl.intended_mechanic = "Echo holds Plate 1 with WAIT turns so the player can pass Door A to the exit."
	lvl.hint = "Walk to Plate 1, WAIT several turns to hold the door open, then CREATE ECHO."
	lvl.map_lines = [
		"#######",
		"#P...##",
		"#....##",
		"#.##.##",
		"#1##A.X",
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

# Level 2: "Stay Behind" - Echo holds remote plate while player travels through Door A.
static func _create_level_02() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_02"
	lvl.max_wait_actions = 2
	lvl.level_name = "Stay Behind"
	lvl.sector = 1
	lvl.difficulty_tier = 1
	lvl.target_3_stars = 18
	lvl.target_2_stars = 25
	lvl.echo_limit = 1
	lvl.min_echoes_required = 1
	lvl.intended_mechanic = "Echo stays at Plate 1 using WAITs, allowing player to traverse a distant corridor."
	lvl.hint = "Deploy an Echo to Plate 1 and add WAIT commands before creating the Echo."
	lvl.map_lines = [
		"#########",
		"#P...#..#",
		"#....#..#",
		"#....A.X#",
		"#....#..#",
		"#1...#..#",
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

# Level 3: "Double Perspective" - Navigation through obstacles to coordinate Door A.
static func _create_level_03() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_03"
	lvl.max_wait_actions = 1
	lvl.level_name = "Double Perspective"
	lvl.sector = 1
	lvl.difficulty_tier = 1
	lvl.target_3_stars = 24
	lvl.target_2_stars = 32
	lvl.echo_limit = 1
	lvl.min_echoes_required = 1
	lvl.intended_mechanic = "Echo travels to remote wing plate while player routes through the central chokepoint."
	lvl.hint = "Send Echo 1 to Plate 1 with WAIT turns, then navigate down through Door A."
	lvl.map_lines = [
		"#########",
		"#P.....1#",
		"#.##.##.#",
		"####A####",
		"#......X#",
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
# SECTOR 02: SYNCHRONIZATION (Levels 4–7) — Minimum 2 Echoes Required
# ==============================================================================

# Level 4: "Sequential Relay" - 3 interconnected chambers; Echo 1 holds Door A, Echo 2 holds Door B.
static func _create_level_04() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_04"
	lvl.max_wait_actions = 2
	lvl.level_name = "Sequential Relay"
	lvl.sector = 2
	lvl.difficulty_tier = 2
	lvl.target_3_stars = 40
	lvl.target_2_stars = 52
	lvl.echo_limit = 2
	lvl.min_echoes_required = 2
	lvl.intended_mechanic = "Echo 1 opens Door A for Echo 2. Echo 2 reaches Plate 2 to open Door B for the player."
	lvl.hint = "Echo 1 unlocks Door A so Echo 2 can reach Plate 2, which unlocks Door B for your final run."
	lvl.map_lines = [
		"#########",
		"#P.1#..2#",
		"#...A...#",
		"#####.###",
		"#...B...#",
		"#.X.#...#",
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

# Level 5: "Split Decision" - Dual-wing chamber; Door A requires BOTH Plate 1 and Plate 2.
static func _create_level_05() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_05"
	lvl.max_wait_actions = 4
	lvl.level_name = "Split Decision"
	lvl.sector = 2
	lvl.difficulty_tier = 2
	lvl.target_3_stars = 28
	lvl.target_2_stars = 38
	lvl.echo_limit = 2
	lvl.min_echoes_required = 2
	lvl.intended_mechanic = "Simultaneous dual-plate activation: Echo 1 holds Wing 1, Echo 2 holds Wing 2."
	lvl.hint = "Door A requires BOTH plates active at once. Station an Echo on each wing."
	lvl.map_lines = [
		"#########",
		"#1..#..2#",
		"#...#...#",
		"#...P...#",
		"####A####",
		"#...X...#",
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

# Level 6: "Crossed Signals" - Interlocking sequential gates with directional routing.
static func _create_level_06() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_06"
	lvl.max_wait_actions = 4
	lvl.level_name = "Crossed Signals"
	lvl.sector = 2
	lvl.difficulty_tier = 3
	lvl.target_3_stars = 42
	lvl.target_2_stars = 55
	lvl.echo_limit = 2
	lvl.min_echoes_required = 2
	lvl.intended_mechanic = "Chained door access: Door A opens Chamber 2, Door B opens Final Chamber."
	lvl.hint = "Echo 1 keeps Door A open so Echo 2 can hold Plate 2, clearing Door B to the exit."
	lvl.map_lines = [
		"###########",
		"#P...#..2.#",
		"#....A....#",
		"#1...#..###",
		"######.####",
		"#....#.B.X#",
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

# Level 7: "No Turning Back" - Two plates; Door B requires BOTH plates to remain active.
static func _create_level_07() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_07"
	lvl.max_wait_actions = 8
	lvl.level_name = "No Turning Back"
	lvl.sector = 2
	lvl.difficulty_tier = 3
	lvl.target_3_stars = 42
	lvl.target_2_stars = 55
	lvl.echo_limit = 2
	lvl.min_echoes_required = 2
	lvl.intended_mechanic = "Door A requires Plate 1; Door B requires BOTH Plate 1 and Plate 2."
	lvl.hint = "Both Echoes must stay on their respective plates to satisfy the final AND gate."
	lvl.map_lines = [
		"###########",
		"#P..1#..2.#",
		"#....A....#",
		"######.####",
		"#....#..###",
		"#....#.B.X#",
		"###########"
	]
	lvl.doors_data = [
		{"id": "A", "logic": "AND", "required_plates": ["1"]},
		{"id": "B", "logic": "AND", "required_plates": ["1", "2"]}
	]
	lvl.plates_data = [
		{"id": "1"},
		{"id": "2"}
	]
	lvl.initialize_from_map()
	return lvl

# ==============================================================================
# SECTOR 03: PARADOX (Levels 8–10) — Minimum 3 Echoes Required
# ==============================================================================

# Level 8: "Temporal Interlock" - 3 sequential chambers; 3 plates; 3 chokepoint doors. Zero bypass routes.
static func _create_level_08() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_08"
	lvl.max_wait_actions = 8
	lvl.level_name = "Temporal Interlock"
	lvl.sector = 3
	lvl.difficulty_tier = 4
	lvl.target_3_stars = 70
	lvl.target_2_stars = 88
	lvl.echo_limit = 3
	lvl.min_echoes_required = 3
	lvl.intended_mechanic = "3-stage sequential relay: Echo 1 holds Door A, Echo 2 holds Door B, Echo 3 holds Door C."
	lvl.hint = "Each chamber is sealed. Chain 3 Echoes with coordinated WAITs to hold all 3 doors."
	lvl.map_lines = [
		"###########",
		"#P..1.....#",
		"#####A#####",
		"#.......2.#",
		"#####B#####",
		"#.3.......#",
		"#####C#####",
		"#....X....#",
		"###########"
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

# Level 9: "Parallel Existence" - Cumulative security matrix requiring 3 Echoes.
static func _create_level_09() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_09"
	lvl.max_wait_actions = 20
	lvl.level_name = "Parallel Existence"
	lvl.sector = 3
	lvl.difficulty_tier = 4
	lvl.target_3_stars = 70
	lvl.target_2_stars = 88
	lvl.echo_limit = 3
	lvl.min_echoes_required = 3
	lvl.intended_mechanic = "Cumulative AND logic: Door A needs Plate 1, Door B needs 1+2, Door C needs 1+2+3."
	lvl.hint = "The final door requires all 3 security plates to remain depressed at the same moment."
	lvl.map_lines = [
		"###########",
		"#P..1.....#",
		"#####A#####",
		"#.......2.#",
		"#####B#####",
		"#.3.......#",
		"#####C#####",
		"#....X....#",
		"###########"
	]
	lvl.doors_data = [
		{"id": "A", "logic": "AND", "required_plates": ["1"]},
		{"id": "B", "logic": "AND", "required_plates": ["1", "2"]},
		{"id": "C", "logic": "AND", "required_plates": ["1", "2", "3"]}
	]
	lvl.plates_data = [
		{"id": "1"},
		{"id": "2"},
		{"id": "3"}
	]
	lvl.initialize_from_map()
	return lvl

# Level 10: "The Last Tomorrow" - Grand Finale 4-Quadrant Temporal Facility with Sequence Lock.
static func _create_level_10() -> LevelDefinition:
	var lvl: LevelDefinition = LevelDefinition.new()
	lvl.level_id = "lvl_10"
	lvl.max_wait_actions = 9
	lvl.level_name = "The Last Tomorrow"
	lvl.sector = 3
	lvl.difficulty_tier = 5
	lvl.target_3_stars = 80
	lvl.target_2_stars = 100
	lvl.echo_limit = 3
	lvl.min_echoes_required = 3
	lvl.intended_mechanic = "4-quadrant synchronization with Sequence Lock on Door C: Plate 1 -> Plate 2 -> Plate 3."
	lvl.hint = "Synchronize across all 4 quadrants. Door C is a Sequence Lock: activate Plates 1 -> 2 -> 3 in order."
	lvl.map_lines = [
		"###########",
		"#P...#...2#",
		"#.1..A....#",
		"#....#....#",
		"######B####",
		"#....#....#",
		"#....C..3.#",
		"#..X.#....#",
		"###########"
	]
	lvl.doors_data = [
		{"id": "A", "logic": "AND", "required_plates": ["1"]},
		{"id": "B", "logic": "AND", "required_plates": ["2"]},
		{"id": "C", "logic": "SEQUENCE", "required_sequence": ["1", "2", "3"]}
	]
	lvl.plates_data = [
		{"id": "1"},
		{"id": "2"},
		{"id": "3"}
	]
	lvl.initialize_from_map()
	return lvl
