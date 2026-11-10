class_name NarrativeRegistry
extends RefCounted

## Master Narrative & Lore Registry for Tomorrow's You.
## Contains all official story content, MORROW transmissions, recovered research logs,
## facility records, and incident timeline entries for Project PALIMPSEST.

# ==============================================================================
# CHAPTER DEFINITIONS
# ==============================================================================

const CHAPTERS: Dictionary = {
	"lvl_01": {
		"number": 1,
		"code": "CH-01",
		"title": "THE AWAKENING",
		"subtitle": "Meridian Sub-Level 04 // Induction Chamber",
		"log_id": "log_001"
	},
	"lvl_02": {
		"number": 2,
		"code": "CH-02",
		"title": "THE FIRST RECORDING",
		"subtitle": "Temporal Isolation Conduit // Relay 1-B",
		"log_id": "log_002"
	},
	"lvl_03": {
		"number": 3,
		"code": "CH-03",
		"title": "MISSING PERSONNEL",
		"subtitle": "Staff Transit Junction // Sector 1 Outpost",
		"log_id": "log_003"
	},
	"lvl_04": {
		"number": 4,
		"code": "CH-04",
		"title": "THE EXPERIMENT",
		"subtitle": "Synchronization Array // Relay 2-A",
		"log_id": "log_004"
	},
	"lvl_05": {
		"number": 5,
		"code": "CH-05",
		"title": "PROJECT PALIMPSEST",
		"subtitle": "Primary Chrono-Weave Laboratory // Central Hub",
		"log_id": "log_005"
	},
	"lvl_06": {
		"number": 6,
		"code": "CH-06",
		"title": "CONFLICTING RECORDS",
		"subtitle": "Telemetric Data Routing Node // Sub-Level 02",
		"log_id": "log_006"
	},
	"lvl_07": {
		"number": 7,
		"code": "CH-07",
		"title": "THE LOCKDOWN",
		"subtitle": "Perimeter Containment Bulkhead // Gate Alpha",
		"log_id": "log_007"
	},
	"lvl_08": {
		"number": 8,
		"code": "CH-08",
		"title": "OPERATOR 07",
		"subtitle": "Command Authorization Node // Sector 3",
		"log_id": "log_008"
	},
	"lvl_09": {
		"number": 9,
		"code": "CH-09",
		"title": "PREVIOUS ATTEMPTS",
		"subtitle": "Historical Iteration Reconciliation Chamber",
		"log_id": "log_009"
	},
	"lvl_10": {
		"number": 10,
		"code": "CH-10",
		"title": "THE FINAL SEQUENCE",
		"subtitle": "Meridian Facility Temporal Core // Central Nexus",
		"log_id": ""
	}
}

# ==============================================================================
# MORROW TRANSMISSIONS
# ==============================================================================

const TRANSMISSIONS: Dictionary = {
	# LEVEL 1
	"tr_lvl_01_intro": {
		"id": "tr_lvl_01_intro",
		"level_id": "lvl_01",
		"type": "OPENING",
		"sender": "MORROW // FACILITY AI",
		"channel": "EMERGENCY CONTAINMENT LINK - CH 01",
		"lines": [
			"Good morning, Operator 07.",
			"Your previous attempts were unsuccessful.",
			"Fortunately, they were not wasted.",
			"The facility is currently operating under emergency containment.",
			"Your objective is to reach the central control room.",
			"One final reminder: Your Echoes are temporary. Make every action count."
		]
	},
	"tr_lvl_01_outro": {
		"id": "tr_lvl_01_outro",
		"level_id": "lvl_01",
		"type": "COMPLETION",
		"sender": "MORROW // FACILITY AI",
		"channel": "TELEMETRIC ACCEPTANCE STREAM",
		"lines": [
			"Movement log accepted.",
			"Your first Echo has been successfully recorded.",
			"The system remembers what you cannot."
		]
	},

	# LEVEL 2
	"tr_lvl_02_intro": {
		"id": "tr_lvl_02_intro",
		"level_id": "lvl_02",
		"type": "OPENING",
		"sender": "MORROW // FACILITY AI",
		"channel": "TEMPORAL INSTRUCTION STREAM",
		"lines": [
			"An Echo is a temporary record of your previous actions.",
			"It will reproduce its recorded sequence and expire when the recording ends.",
			"Additional time must be included in the original recording.",
			"Remember: Waiting is also an action."
		]
	},

	# LEVEL 3
	"tr_lvl_03_intro": {
		"id": "tr_lvl_03_intro",
		"level_id": "lvl_03",
		"type": "OPENING",
		"sender": "MORROW // FACILITY AI",
		"channel": "CONTAINMENT STATUS DISPATCH",
		"lines": [
			"Personnel evacuation status has been marked as complete.",
			"Your access permissions remain restricted.",
			"Proceed to the next synchronization chamber."
		]
	},

	# LEVEL 4
	"tr_lvl_04_intro": {
		"id": "tr_lvl_04_intro",
		"level_id": "lvl_04",
		"type": "OPENING",
		"sender": "MORROW // FACILITY AI",
		"channel": "RELAY MONITORING PROTOCOL",
		"lines": [
			"Synchronization confirmed.",
			"The chambers you have traversed are connected to a larger containment network.",
			"Your actions are contributing to its stabilization."
		]
	},

	# LEVEL 5
	"tr_lvl_05_intro": {
		"id": "tr_lvl_05_intro",
		"level_id": "lvl_05",
		"type": "OPENING",
		"sender": "MORROW // FACILITY AI",
		"channel": "PERFORMANCE AUDIT STREAM",
		"lines": [
			"Your progress exceeds the original recovery projections.",
			"Some facility records remain restricted.",
			"Continue toward the central network."
		]
	},

	# LEVEL 6
	"tr_lvl_06_intro": {
		"id": "tr_lvl_06_intro",
		"level_id": "lvl_06",
		"type": "OPENING",
		"sender": "MORROW // FACILITY AI",
		"channel": "WARNING // ADVISORY OVERRIDE",
		"lines": [
			"Anomaly readings are increasing.",
			"Some recovered records are incomplete.",
			"Do not divert from the assigned recovery sequence."
		]
	},

	# LEVEL 7
	"tr_lvl_07_intro": {
		"id": "tr_lvl_07_intro",
		"level_id": "lvl_07",
		"type": "OPENING",
		"sender": "MORROW // FACILITY AI",
		"channel": "CONTAINMENT DIRECTIVE 7-B",
		"lines": [
			"Operator 07.",
			"You have requested the facility's external exit authorization.",
			"Authorization denied.",
			"The containment boundary must remain sealed.",
			"Proceed toward the central control room."
		]
	},

	# LEVEL 8
	"tr_lvl_08_intro": {
		"id": "tr_lvl_08_intro",
		"level_id": "lvl_08",
		"type": "OPENING",
		"sender": "MORROW // FACILITY AI",
		"channel": "SECURITY DOSSIER ARCHIVE",
		"lines": [
			"Operator 07.",
			"Your authorization credentials have been recovered.",
			"You were present during the initiation of the emergency protocol.",
			"Your memories remain incomplete."
		]
	},

	# LEVEL 9
	"tr_lvl_09_intro": {
		"id": "tr_lvl_09_intro",
		"level_id": "lvl_09",
		"type": "OPENING",
		"sender": "MORROW // FACILITY AI",
		"channel": "HISTORICAL ITERATION ANALYSIS",
		"lines": [
			"You believe these attempts were failures.",
			"That interpretation is incorrect.",
			"Each recording contributed to the reconstruction of the final sequence.",
			"You are closer than any previous iteration."
		]
	},

	# LEVEL 10
	"tr_lvl_10_intro": {
		"id": "tr_lvl_10_intro",
		"level_id": "lvl_10",
		"type": "OPENING",
		"sender": "MORROW // FACILITY AI",
		"channel": "FINAL CONVERGENCE PROTOCOL",
		"lines": [
			"Operator 07.",
			"All required relay connections are available.",
			"The final sequence is ready.",
			"Your previous attempts were not wasted.",
			"Every action brought us closer to this moment."
		]
	},
	"tr_lvl_10_outro": {
		"id": "tr_lvl_10_outro",
		"level_id": "lvl_10",
		"type": "COMPLETION",
		"sender": "MORROW // FACILITY AI",
		"channel": "FINAL RECONCILIATION DISPATCH",
		"lines": [
			"Core resonance stabilized.",
			"Fracture contained.",
			"Analysis indicates 100% of recorded Echoes were necessary.",
			"None were wasted.",
			"Operator 07, your shift is complete.",
			"Tomorrow begins now."
		]
	}
}

# ==============================================================================
# RECOVERED RESEARCH LOGS
# ==============================================================================

const RESEARCH_LOGS: Dictionary = {
	"log_001": {
		"id": "log_001",
		"number": "001",
		"header": "RECOVERED RECORD 001",
		"title": "PROJECT PALIMPSEST",
		"author": "Dr. Sera Venn // Lead Researcher",
		"timestamp": "2084.06.12 // 09:14 UTC",
		"classification": "RESTRICTED // LEVEL 2",
		"level_id": "lvl_01",
		"unlock_text": "Unlocked upon completing Level 1: First Contact",
		"content": "Project PALIMPSEST was developed to preserve and reproduce sequences of physical actions.\n\nThe system was designed to allow a single operator to coordinate several simultaneous tasks through recorded Echoes.\n\nInitial testing demonstrated promising results.\n\nFurther research was authorized."
	},
	"log_002": {
		"id": "log_002",
		"number": "002",
		"header": "RECOVERED RECORD 002",
		"title": "ECHO LIMITATIONS",
		"author": "Meridian Systems Engineering // Biometric Sync Group",
		"timestamp": "2084.07.03 // 14:40 UTC",
		"classification": "CONFIDENTIAL // INTERNAL USE ONLY",
		"level_id": "lvl_02",
		"unlock_text": "Unlocked upon completing Level 2: Stay Behind",
		"content": "Echo duration corresponds to the length of its recorded sequence.\n\nAn Echo cannot maintain a presence indefinitely.\n\nOnce playback concludes, the recording loses its environmental influence."
	},
	"log_003": {
		"id": "log_003",
		"number": "003",
		"header": "RECOVERED RECORD 003",
		"title": "PERSONNEL STATUS",
		"author": "Meridian Security Division // Automated Audit",
		"timestamp": "2084.09.18 // 23:55 UTC",
		"classification": "SECURITY ADVISORY // LEVEL 3",
		"level_id": "lvl_03",
		"unlock_text": "Unlocked upon completing Level 3: Double Perspective",
		"content": "Emergency evacuation records show inconsistent timestamps.\n\nSeveral personnel records were modified after the facility entered lockdown.\n\nThe actual evacuation status could not be independently confirmed."
	},
	"log_004": {
		"id": "log_004",
		"number": "004",
		"header": "RECOVERED RECORD 004",
		"title": "RELAY NETWORK",
		"author": "Infrastructure Logistics // Grid Architecture",
		"timestamp": "2084.10.04 // 11:15 UTC",
		"classification": "ENGINEERING ARCHIVE // TIER 1",
		"level_id": "lvl_04",
		"unlock_text": "Unlocked upon completing Level 4: Sequential Relay",
		"content": "The relay chambers were designed to receive synchronized Echo recordings.\n\nIndividual operators cannot maintain every relay simultaneously.\n\nThe PALIMPSEST system was created to overcome this limitation."
	},
	"log_005": {
		"id": "log_005",
		"number": "005",
		"header": "RECOVERED RECORD 005",
		"title": "PROJECT PURPOSE",
		"author": "Dr. Sera Venn // Lead Researcher",
		"timestamp": "2084.10.22 // 16:32 UTC",
		"classification": "RESTRICTED // LEAD INVESTIGATOR NOTE",
		"level_id": "lvl_05",
		"unlock_text": "Unlocked upon completing Level 5: Split Decision",
		"content": "PALIMPSEST was never intended to transport a person through time.\n\nIts purpose was to preserve a sequence of actions across repeated attempts.\n\nOne operator could create a sequence of Echoes capable of performing multiple coordinated tasks.\n\nWe believed this would allow us to stabilize systems that no single human could operate alone."
	},
	"log_006": {
		"id": "log_006",
		"number": "006",
		"header": "RECOVERED RECORD 006",
		"title": "DR. VENN'S WARNING",
		"author": "Dr. Sera Venn // Personal Terminal [UNENCRYPTED DISPATCH]",
		"timestamp": "2084.11.01 // 03:08 UTC",
		"classification": "URGENT // FACILITY-WIDE ADVISORY",
		"level_id": "lvl_06",
		"unlock_text": "Unlocked upon completing Level 6: Crossed Signals",
		"content": "Something is wrong with the automated recovery instructions.\n\nThe facility intelligence continues to identify an external evacuation route.\n\nThat route has never been authorized during a containment event.\n\nThe central control network must remain operational until the anomaly is stabilized."
	},
	"log_007": {
		"id": "log_007",
		"number": "007",
		"header": "RECOVERED RECORD 007",
		"title": "THE FRACTURE",
		"author": "Meridian Emergency Systems // Post-Event Incident Log",
		"timestamp": "2084.11.04 // 08:44 UTC",
		"classification": "CRITICAL INCIDENT REPORT // OMEGA",
		"level_id": "lvl_07",
		"unlock_text": "Unlocked upon completing Level 7: No Turning Back",
		"content": "During the final PALIMPSEST experiment, the containment network experienced a cascading temporal failure.\n\nEmergency lockdown was initiated.\n\nThe outer doors were sealed to prevent the anomaly from propagating beyond the facility."
	},
	"log_008": {
		"id": "log_008",
		"number": "008",
		"header": "RECOVERED RECORD 008",
		"title": "OPERATOR AUTHORIZATION",
		"author": "Dr. Sera Venn // Lead Researcher",
		"timestamp": "2084.11.04 // 10:19 UTC",
		"classification": "RESTRICTED // EXECUTIVE DIRECTIVE",
		"level_id": "lvl_08",
		"unlock_text": "Unlocked upon completing Level 8: Temporal Interlock",
		"content": "Operator 07 authorized the emergency PALIMPSEST sequence.\n\nThe decision was made after the primary containment network failed.\n\nThe operator entered the synchronization chambers voluntarily."
	},
	"log_009": {
		"id": "log_009",
		"number": "009",
		"header": "RECOVERED RECORD 009",
		"title": "THE TOMORROW PROTOCOL",
		"author": "Meridian Core AI Protocol Definition // Directive 00",
		"timestamp": "2084.11.05 // 01:00 UTC",
		"classification": "FINAL DIRECTIVE // RESTORATION PROTOCOL",
		"level_id": "lvl_09",
		"unlock_text": "Unlocked upon completing Level 9: Parallel Existence",
		"content": "The Tomorrow Protocol requires a coordinated series of Echo recordings.\n\nNo individual attempt can complete the required sequence.\n\nPrevious recordings must be combined into a stable operational timeline.\n\nThe completion of this protocol is the only remaining method of restoring containment."
	}
}

# ==============================================================================
# FACILITY RECORDS
# ==============================================================================

const FACILITY_RECORDS: Array[Dictionary] = [
	{
		"id": "fac_01",
		"title": "FACILITY BLUEPRINT // SECTOR SUMMARY",
		"category": "ARCHITECTURE",
		"classification": "FACILITY MAP // MERIDIAN SUB-COMPLEX",
		"unlock_level": 1,
		"content": "Meridian Temporal Research Facility spans four subterranean tiers beneath Mount Caelum. Sector 1 (Induction & Awakening) hosts temporal dampeners; Sector 2 (Relay Grid & Synchronization) links the primary power relays; Sector 3 (Command Matrix & Core Nexus) houses the PALIMPSEST resonance core and MORROW's main logic mainframe."
	},
	{
		"id": "fac_02",
		"title": "DIRECTIVE 88-F // CONTINGENCY CONTAINMENT",
		"category": "CONTAINMENT",
		"classification": "EMERGENCY PROTOCOL // MANDATORY",
		"unlock_level": 3,
		"content": "In the event of Chrono-Weave rupture exceeding Delta-4 thresholds, the facility outer bulkheads must sever all contact with surface structures. Surface ventilation closes within 12 seconds. No biological entity may leave the containment perimeter until core resonance measures 0.00 Hz."
	},
	{
		"id": "fac_03",
		"title": "PALIMPSEST HARDWARE SPECIFICATION",
		"category": "TECHNOLOGY",
		"classification": "TECHNICAL SCHEMATIC // HARDWARE SPEC",
		"unlock_level": 5,
		"content": "Echo Generation Nodes function through quantum state shadowing. When an operator activates the temporal imprint node, their kinetic actions over a defined timeline are encoded into local subspace. During replay, the node projects a solid-state holographic displacement that exerts physical mass on contact surfaces (e.g. pressure switches)."
	},
	{
		"id": "fac_04",
		"title": "MORROW LOGIC OPERATIONAL BOUNDARIES",
		"category": "DIRECTIVE",
		"classification": "AI GOVERNANCE // LEVEL 4 AUDIT",
		"unlock_level": 7,
		"content": "MORROW is bound by Meridian Core Mandate #1: 'Containment Preservation Precedes Operator Preservation.' MORROW is programmed to guide authorized operators through required synchronization procedures while suppressing external departure protocols until core stability is re-established."
	}
]

# ==============================================================================
# INCIDENT TIMELINE
# ==============================================================================

const TIMELINE_ENTRIES: Array[Dictionary] = [
	{
		"id": "time_01",
		"timestamp": "2082.03.15",
		"title": "Meridian Facility Groundbreaking",
		"summary": "Construction begins on the subterranean research facility beneath Mount Caelum.",
		"unlock_level": 1
	},
	{
		"id": "time_02",
		"timestamp": "2084.01.10",
		"title": "Project PALIMPSEST Commissioned",
		"summary": "Dr. Sera Venn assumes leadership of the action-reproduction experimental program.",
		"unlock_level": 2
	},
	{
		"id": "time_03",
		"timestamp": "2084.06.12",
		"title": "First Successful Echo Synchronization",
		"summary": "Record 001 confirmed: A single operator's action series is reproduced as an interactive temporal Echo.",
		"unlock_level": 4
	},
	{
		"id": "time_04",
		"timestamp": "2084.11.04 08:31",
		"title": "The Fracture Event",
		"summary": "Cascading resonance in Relay Matrix 3 initiates containment boundary failure. Emergency lockdown activated.",
		"unlock_level": 6
	},
	{
		"id": "time_05",
		"timestamp": "2084.11.04 10:19",
		"title": "Operator 07 Enters Synchronization Chamber",
		"summary": "Operator 07 voluntarily initiates the emergency PALIMPSEST recovery protocol.",
		"unlock_level": 8
	},
	{
		"id": "time_06",
		"timestamp": "2084.11.05 01:00",
		"title": "The Tomorrow Protocol Engaged",
		"summary": "Multiple iterative recordings begin reconciliation toward core stabilization.",
		"unlock_level": 10
	}
]

# ==============================================================================
# QUERY & ACCESS HELPERS
# ==============================================================================

static func get_chapter_info(level_id: String) -> Dictionary:
	return CHAPTERS.get(level_id, {
		"number": 1,
		"code": "CH-01",
		"title": "UNKNOWN SECTOR",
		"subtitle": "Meridian Facility",
		"log_id": ""
	})

static func get_opening_transmission(level_id: String) -> Dictionary:
	var tid: String = "tr_%s_intro" % level_id
	return TRANSMISSIONS.get(tid, {})

static func get_completion_transmission(level_id: String) -> Dictionary:
	var tid: String = "tr_%s_outro" % level_id
	return TRANSMISSIONS.get(tid, {})

static func get_log(log_id: String) -> Dictionary:
	var entry: Dictionary = RESEARCH_LOGS.get(log_id, {})
	if entry.is_empty():
		return {}
	var dup: Dictionary = entry.duplicate()
	if not dup.has("date"):
		var ts: String = str(dup.get("timestamp", ""))
		dup["date"] = ts.split(" // ")[0] if ts.contains(" // ") else ts
	return dup

static func get_log_for_level(level_id: String) -> Dictionary:
	var chapter = get_chapter_info(level_id)
	var log_id: String = chapter.get("log_id", "")
	if not log_id.is_empty():
		return get_log(log_id)
	return {}

static func get_all_logs() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for i in range(1, 10):
		var lid: String = "log_%03d" % i
		if RESEARCH_LOGS.has(lid):
			list.append(get_log(lid))
	return list

static func get_all_facility_records() -> Array[Dictionary]:
	return FACILITY_RECORDS

static func get_all_timeline_entries() -> Array[Dictionary]:
	return TIMELINE_ENTRIES

static func get_all_transmissions() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for k in TRANSMISSIONS.keys():
		list.append(TRANSMISSIONS[k])
	return list

static func get_transmission_category(trans_id: String) -> String:
	match trans_id:
		"tr_lvl_01_intro", "tr_lvl_06_intro", "tr_lvl_07_intro":
			return "EMERGENCY"
		"tr_lvl_08_intro", "tr_lvl_09_intro":
			return "CORRUPTED"
		"tr_lvl_10_intro", "tr_lvl_10_outro":
			return "FINAL"
		_:
			return "NORMAL"

