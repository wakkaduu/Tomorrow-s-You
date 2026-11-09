class_name HintRegistry
extends RefCounted

## Master Hint Registry for Tomorrow's You.
## Contains handcrafted, verified 3-stage progressive hints for all 10 campaign levels.
## All hints directly correlate with the authoritative, physically verified level layouts
## and movement solutions in LevelRegistry and test_campaign_solutions.

const HintDefinitionClass = preload("res://scripts/hints/hint_definition.gd")

const DAILY_HINT_LIMIT: int = 3

static func get_hints_for_level(level_id: String) -> HintDefinitionClass:
	match level_id:
		"lvl_01": return _create_lvl_01_hints()
		"lvl_02": return _create_lvl_02_hints()
		"lvl_03": return _create_lvl_03_hints()
		"lvl_04": return _create_lvl_04_hints()
		"lvl_05": return _create_lvl_05_hints()
		"lvl_06": return _create_lvl_06_hints()
		"lvl_07": return _create_lvl_07_hints()
		"lvl_08": return _create_lvl_08_hints()
		"lvl_09": return _create_lvl_09_hints()
		"lvl_10": return _create_lvl_10_hints()
	return null

static func get_hint_stage(level_id: String, stage_idx: int) -> Dictionary:
	var def: HintDefinitionClass = get_hints_for_level(level_id)
	if def:
		return def.get_hint(stage_idx)
	return {}

static func validate_all_hints() -> Array[String]:
	var errors: Array[String] = []
	for i in range(1, 11):
		var lid: String = "lvl_%02d" % i
		var def: HintDefinitionClass = get_hints_for_level(lid)
		if not def:
			errors.append("Missing HintDefinition for " + lid)
		else:
			errors.append_array(def.validate())
	return errors

# ==============================================================================
# LEVEL HINT DEFINITIONS (10 CAMPAIGN LEVELS)
# ==============================================================================

# Level 1: First Contact (Sector 1, Min 1 Echo)
static func _create_lvl_01_hints() -> HintDefinitionClass:
	var def: HintDefinitionClass = HintDefinitionClass.new("lvl_01")
	def.hints = [
		{
			"stage": 0,
			"title": "Stage 1 — Observation",
			"text": "Notice Door A at (4,4) blocks the only path to the exit, and it is wired directly to Plate 1 located in the lower-left corner."
		},
		{
			"stage": 1,
			"title": "Stage 2 — Strategy",
			"text": "Your Echo must reach Plate 1 and stay there using WAIT commands. Because Echoes expire when their recording ends, station your Echo on the plate with several WAIT turns so Door A remains open long enough for you to run across the facility."
		},
		{
			"stage": 2,
			"title": "Stage 3 — Solution",
			"text": "Echo 1: Move DOWN 3 times to Plate 1, press WAIT 5 times, then tap CREATE ECHO.\nPlayer Run: Move RIGHT 3 times, DOWN 3 times through Door A before Echo 1 expires, and RIGHT 2 times to reach the exit."
		}
	]
	return def

# Level 2: Stay Behind (Sector 1, Min 1 Echo)
static func _create_lvl_02_hints() -> HintDefinitionClass:
	var def: HintDefinitionClass = HintDefinitionClass.new("lvl_02")
	def.hints = [
		{
			"stage": 0,
			"title": "Stage 1 — Observation",
			"text": "Door A stands in the central corridor between you and the exit. Plate 1 is at the far southern end of the hallway."
		},
		{
			"stage": 1,
			"title": "Stage 2 — Strategy",
			"text": "The journey to Door A takes 5 turns from spawn. An Echo reaching Plate 1 after 4 steps will expire on turn 5 unless you record explicit WAIT turns on the plate to hold the door open."
		},
		{
			"stage": 2,
			"title": "Stage 3 — Solution",
			"text": "Echo 1: Move DOWN 4 times to step on Plate 1, then WAIT 4 times to keep Door A held open. Tap CREATE ECHO.\nPlayer Run: Move RIGHT 3 times, DOWN 2 times through Door A, and RIGHT 3 times to the exit."
		}
	]
	return def

# Level 3: Double Perspective (Sector 1, Min 1 Echo)
static func _create_lvl_03_hints() -> HintDefinitionClass:
	var def: HintDefinitionClass = HintDefinitionClass.new("lvl_03")
	def.hints = [
		{
			"stage": 0,
			"title": "Stage 1 — Observation",
			"text": "The partition separates the upper remote wing from the central chokepoint Door A. Plate 1 is located all the way across in the top-right corner."
		},
		{
			"stage": 1,
			"title": "Stage 2 — Strategy",
			"text": "Echo 1 requires 6 steps to reach Plate 1, but your path to Door A only takes 4 steps. You must deliberately WAIT at the door until Echo 1 arrives to unlock it, and Echo 1 must record extra WAITs to avoid expiring too early."
		},
		{
			"stage": 2,
			"title": "Stage 3 — Solution",
			"text": "Echo 1: Move RIGHT 6 times to Plate 1, record 4 WAITs, and CREATE ECHO.\nPlayer Run: Move RIGHT 3, DOWN 1 to face Door A. Press WAIT 2 times until Echo 1 reaches Plate 1 to open Door A, then step DOWN 2 times and RIGHT 3 times to exit."
		}
	]
	return def

# Level 4: Sequential Relay (Sector 2, Min 2 Echoes)
static func _create_lvl_04_hints() -> HintDefinitionClass:
	var def: HintDefinitionClass = HintDefinitionClass.new("lvl_04")
	def.hints = [
		{
			"stage": 0,
			"title": "Stage 1 — Observation",
			"text": "This facility has three sealed chambers. Door A leads into the upper-right chamber with Plate 2, which controls Door B leading into the exit chamber."
		},
		{
			"stage": 1,
			"title": "Stage 2 — Strategy",
			"text": "You need a relay chain: Echo 1 must hold Door A open while Echo 2 traverses through it to reach Plate 2. Then Echo 2 holds Door B so your third attempt can slip through into the exit chamber."
		},
		{
			"stage": 2,
			"title": "Stage 3 — Solution",
			"text": "Echo 1: Move RIGHT 2 to Plate 1, WAIT 8 times, and tap CREATE ECHO.\nEcho 2: Move DOWN 1, RIGHT 4 through Door A, UP 1, RIGHT 2 onto Plate 2, WAIT 6 times, and CREATE ECHO.\nPlayer Run: Move DOWN 1, RIGHT 4 through Door A, DOWN 2, WAIT 1 turn for Door B to unlock, then LEFT 3 and DOWN 1 to exit."
		}
	]
	return def

# Level 5: Split Decision (Sector 2, Min 2 Echoes, AND Door A)
static func _create_lvl_05_hints() -> HintDefinitionClass:
	var def: HintDefinitionClass = HintDefinitionClass.new("lvl_05")
	def.hints = [
		{
			"stage": 0,
			"title": "Stage 1 — Observation",
			"text": "Door A is an AND logic gate — it will only open when BOTH Plate 1 on the west wing and Plate 2 on the east wing are depressed at the exact same moment."
		},
		{
			"stage": 1,
			"title": "Stage 2 — Strategy",
			"text": "Neither plate can be held by you during your final escape run. You must deploy Echo 1 to the west plate and Echo 2 to the east plate, both recording WAITs so their activations synchronize while you wait near Door A."
		},
		{
			"stage": 2,
			"title": "Stage 3 — Solution",
			"text": "Echo 1: Move LEFT 3, UP 2 to Plate 1, WAIT 4 times, and tap CREATE ECHO.\nEcho 2: Move RIGHT 3, UP 2 to Plate 2, WAIT 4 times, and tap CREATE ECHO.\nPlayer Run: WAIT 5 turns at spawn while both Echoes reach their plates; when Door A opens, move DOWN 2 times to exit."
		}
	]
	return def

# Level 6: Crossed Signals (Sector 2, Min 2 Echoes)
static func _create_lvl_06_hints() -> HintDefinitionClass:
	var def: HintDefinitionClass = HintDefinitionClass.new("lvl_06")
	def.hints = [
		{
			"stage": 0,
			"title": "Stage 1 — Observation",
			"text": "Plate 1 is located south of spawn and unlocks Door A. Through Door A lies Chamber 2 containing Plate 2, which unlocks Door B guarding the exit."
		},
		{
			"stage": 1,
			"title": "Stage 2 — Strategy",
			"text": "Echo 1 must hold Door A long enough for Echo 2 to enter Chamber 2 and reach Plate 2, as well as for you to pass through Door A. Then Echo 2 must hold Plate 2 so Door B is open when you arrive."
		},
		{
			"stage": 2,
			"title": "Stage 3 — Solution",
			"text": "Echo 1: Move DOWN 2 to Plate 1, WAIT 8 times, and tap CREATE ECHO.\nEcho 2: Move DOWN 1, RIGHT 5 through Door A, UP 1, RIGHT 2 to Plate 2, WAIT 6 times, and CREATE ECHO.\nPlayer Run: Move DOWN 1, RIGHT 5 through Door A, DOWN 3, and RIGHT 3 through Door B directly to the exit."
		}
	]
	return def

# Level 7: No Turning Back (Sector 2, Min 2 Echoes, AND Door B)
static func _create_lvl_07_hints() -> HintDefinitionClass:
	var def: HintDefinitionClass = HintDefinitionClass.new("lvl_07")
	def.hints = [
		{
			"stage": 0,
			"title": "Stage 1 — Observation",
			"text": "Inspect the wiring on Door B: unlike the previous level, Door B is an AND gate that requires BOTH Plate 1 AND Plate 2 active simultaneously to unlock."
		},
		{
			"stage": 1,
			"title": "Stage 2 — Strategy",
			"text": "Because Door B requires Plate 1 in addition to Plate 2, Echo 1 cannot leave or expire early! Echo 1 must record enough WAIT turns to keep Plate 1 active through the moment you step through Door B."
		},
		{
			"stage": 2,
			"title": "Stage 3 — Solution",
			"text": "Echo 1: Move RIGHT 3 to Plate 1, WAIT 8 times, and tap CREATE ECHO.\nEcho 2: Move DOWN 1, RIGHT 5 through Door A, UP 1, RIGHT 2 to Plate 2, WAIT 6 times, and CREATE ECHO.\nPlayer Run: Move DOWN 1, RIGHT 5 through Door A, DOWN 3, and RIGHT 3 through Door B to the exit before Echo 1 expires."
		}
	]
	return def

# Level 8: Temporal Interlock (Sector 3, Min 3 Echoes)
static func _create_lvl_08_hints() -> HintDefinitionClass:
	var def: HintDefinitionClass = HintDefinitionClass.new("lvl_08")
	def.hints = [
		{
			"stage": 0,
			"title": "Stage 1 — Observation",
			"text": "Three vertically stacked, completely sealed chambers require three successive doors (A, B, C) to be unlocked in order to reach the southern exit."
		},
		{
			"stage": 1,
			"title": "Stage 2 — Strategy",
			"text": "Coordinate a 3-stage temporal relay. Echo 1 holds Door A for Echoes 2, 3, and yourself. Echo 2 rushes to Chamber 2's Plate 2 to open Door B. Echo 3 waits for Door B, rushes to Plate 3, and opens Door C. Echo 1 and Echo 2 must record generous WAIT counts."
		},
		{
			"stage": 2,
			"title": "Stage 3 — Solution",
			"text": "Echo 1: Move RIGHT 3 to Plate 1, WAIT 12 times, tap CREATE ECHO.\nEcho 2: Move RIGHT 4, DOWN 2, RIGHT 3 to Plate 2, WAIT 6 times, tap CREATE ECHO.\nEcho 3: Move RIGHT 4, DOWN 2, WAIT 3 times at Door B, move DOWN 2, LEFT 3 to Plate 3, WAIT 4 times, tap CREATE ECHO.\nPlayer Run: Move RIGHT 4, DOWN 2, WAIT 3 times at Door B, DOWN 2, WAIT 3 times at Door C, and DOWN 2 to exit."
		}
	]
	return def

# Level 9: Parallel Existence (Sector 3, Min 3 Echoes)
static func _create_lvl_09_hints() -> HintDefinitionClass:
	var def: HintDefinitionClass = HintDefinitionClass.new("lvl_09")
	def.hints = [
		{
			"stage": 0,
			"title": "Stage 1 — Observation",
			"text": "Check the door logic: Door A requires Plate 1, Door B requires 1 AND 2, and Door C requires 1, 2, AND 3! All three plates must be held down simultaneously for the final door to unlock."
		},
		{
			"stage": 1,
			"title": "Stage 2 — Strategy",
			"text": "Because Door C requires all three plates depressed together, Echo 1 cannot expire when Echo 2 reaches Plate 2, nor can Echo 2 expire when Echo 3 reaches Plate 3. Every Echo's duration must overlap at the final breakthrough turn."
		},
		{
			"stage": 2,
			"title": "Stage 3 — Solution",
			"text": "Echo 1: Move RIGHT 3 to Plate 1, WAIT 12 times, and CREATE ECHO.\nEcho 2: Move RIGHT 4, DOWN 2, RIGHT 3 to Plate 2, WAIT 6 times, and CREATE ECHO.\nEcho 3: Move RIGHT 4, DOWN 2, WAIT 3 times, DOWN 2, LEFT 3 to Plate 3, WAIT 4 times, and CREATE ECHO.\nPlayer Run: Follow behind: RIGHT 4, DOWN 2, WAIT 3 times at Door B, DOWN 2, WAIT 3 times at Door C, and DOWN 2 to exit."
		}
	]
	return def

# Level 10: The Last Tomorrow (Sector 3, Min 3 Echoes)
static func _create_lvl_10_hints() -> HintDefinitionClass:
	var def: HintDefinitionClass = HintDefinitionClass.new("lvl_10")
	def.hints = [
		{
			"stage": 0,
			"title": "Stage 1 — Observation",
			"text": "This 4-quadrant facility is locked by a Sequence Lock on Door C. Notice the indicator on Door C: it requires Plates 1, 2, and 3 to be stepped on in exact chronological sequence (1 -> 2 -> 3)."
		},
		{
			"stage": 1,
			"title": "Stage 2 — Strategy",
			"text": "Synchronize all 4 quadrants without violating the sequence order: Echo 1 must trigger Plate 1 first on turn 2 to open Door A. Then Echo 2 must trigger Plate 2 second (advancing the sequence to 2/3 and opening Door B). Then Echo 3 triggers Plate 3 third (unlocking Door C). Stepping on any plate out of sequence resets the lock!"
		},
		{
			"stage": 2,
			"title": "Stage 3 — Solution",
			"text": "Echo 1: Move DOWN 1, RIGHT 1 onto Plate 1, WAIT 14 times, and CREATE ECHO.\nEcho 2: Move DOWN 1, RIGHT 5, UP 1, RIGHT 3 onto Plate 2, WAIT 8 times, and CREATE ECHO.\nEcho 3: Move DOWN 1, RIGHT 5, DOWN 1, WAIT 4 times at Door B, move DOWN 3, RIGHT 2 onto Plate 3, WAIT 4 times, and CREATE ECHO.\nPlayer Run: Move DOWN 1, RIGHT 5, DOWN 1, WAIT 4 times, DOWN 3, WAIT 2 times for Door C to unlock, then move LEFT 2, DOWN 1, and LEFT 1 to the exit."
		}
	]
	return def
