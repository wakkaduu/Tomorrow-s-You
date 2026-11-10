class_name CampaignSolutions
extends RefCounted

## Solver-generated intended-route fixtures. BOUNDED minima, never global claims.
## See tests/fixtures/wait_solver_results.json and docs/WAIT_BALANCING_REPORT.md.
const SOLUTIONS: Dictionary = {
	"lvl_01": {
		"wait": 3,
		"attempts": [
			"DDDWWW",
			"DRRRDDRR"
		]
	},
	"lvl_02": {
		"wait": 2,
		"attempts": [
			"DDDDWW",
			"DDRRRRRR"
		]
	},
	"lvl_03": {
		"wait": 1,
		"attempts": [
			"RRRRRR",
			"RRRDWDDRRR"
		]
	},
	"lvl_04": {
		"wait": 2,
		"attempts": [
			"RRWW",
			"DRRRRURR",
			"DRRRRDDLLDL"
		]
	},
	"lvl_05": {
		"wait": 4,
		"attempts": [
			"LUULL",
			"RUURR",
			"WWWWDD"
		]
	},
	"lvl_06": {
		"wait": 4,
		"attempts": [
			"DDWWW",
			"DRRRRRURRW",
			"DRRRRRDDDRRR"
		]
	},
	"lvl_07": {
		"wait": 8,
		"attempts": [
			"RRRWWWWWWW",
			"DRRRRRURRW",
			"DRRRRRDDDRRR"
		]
	},
	"lvl_08": {
		"wait": 8,
		"attempts": [
			"RRRWW",
			"RRRRDDRRR",
			"RRRRDDWWDDLLL",
			"RRRRDDWWDDWWDD"
		]
	},
	"lvl_09": {
		"wait": 20,
		"attempts": [
			"RRRWWWWWWWWWW",
			"RRRRDDRRRWWWW",
			"RRRRDDWWDDLLL",
			"RRRRDDWWDDWWDD"
		]
	},
	"lvl_10": {
		"wait": 9,
		"attempts": [
			"DRWWW",
			"DRRRRRURRR",
			"DRRRRRDWWDDDRR",
			"DRRRRRDWWDDDWWLLDL"
		]
	}
}

static func get_attempts(level_id: String) -> Array:
	return SOLUTIONS.get(level_id, {}).get("attempts", []).duplicate()

static func get_actions(level_id: String) -> Array:
	var result: Array = []
	var attempts: Array = get_attempts(level_id)
	for i in range(attempts.size()):
		if i > 0: result.append("ECHO")
		for action in str(attempts[i]): result.append(action)
	return result

static func get_wait_limit(level_id: String) -> int:
	return int(SOLUTIONS.get(level_id, {}).get("wait", -1))

static func get_solution_text(level_id: String) -> String:
	var lines: PackedStringArray = []
	var attempts: Array = get_attempts(level_id)
	var names: Dictionary = {"U": "UP", "D": "DOWN", "L": "LEFT", "R": "RIGHT", "W": "WAIT"}
	for i in range(attempts.size()):
		var actions: String = attempts[i]
		var runs: PackedStringArray = []
		var cursor: int = 0
		while cursor < actions.length():
			var end: int = cursor + 1
			while end < actions.length() and actions[end] == actions[cursor]: end += 1
			runs.append("%s ×%d" % [names[actions[cursor]], end - cursor])
			cursor = end
		var role: String = "Echo %d" % (i + 1) if i < attempts.size() - 1 else "Player"
		lines.append("%s: %s.%s" % [role, ", ".join(runs), " CREATE ECHO." if i < attempts.size() - 1 else ""])
	lines.append("Shared WAIT allowance: %d. Follow these routes without extra WAITs." % get_wait_limit(level_id))
	return "\n".join(lines)
