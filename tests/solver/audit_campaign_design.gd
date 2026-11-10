extends SceneTree
const Solver = preload("res://scripts/solver/campaign_wait_solver.gd")
const Registry = preload("res://scripts/level/level_registry.gd")
const Validator = preload("res://scripts/level/level_validator.gd")
func _init() -> void:
	var report: Dictionary = {"scope": "replayed counterexamples, not absence proofs", "movement_padding": [], "echo_count": []}
	var probes: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/wait_padding_results.json"))
	var ok: bool = true
	for probe: Dictionary in probes:
		if probe.status != "PADDING_WITNESS": continue
		var level = Registry.get_level_by_id(probe.level_id)
		var replay: Dictionary = Validator._replay_solution(level, probe.actions, level.target_3_stars)
		var analysis: Dictionary = Solver.inspect_routes(level, probe.actions)
		ok = ok and replay.completed and not analysis.intended_route
		report.movement_padding.append({"level_id": level.level_id, "level_fingerprint": level.get_rules_fingerprint(),
			"actions": probe.actions, "action_bound": level.target_3_stars, "replay": replay, "route_analysis": analysis})
	var nightmare = Registry.get_level(9)
	var bypass: Dictionary = Validator.find_prefix_counterexample(nightmare, 2)
	ok = ok and bypass.get("path_found", false)
	bypass["level_id"] = nightmare.level_id
	bypass["level_fingerprint"] = nightmare.get_rules_fingerprint()
	bypass["intended_echoes"] = nightmare.min_echoes_required
	# Separate constructive witness: explicit WAITs instead of movement timing loops.
	var explicit_wait_route: Array = []
	for segment in ["DRWWW", "ECHO", "DRRRRRURRR", "ECHO", "DRRRRRDWWDDDRRLLLLLD"]:
		if segment == "ECHO": explicit_wait_route.append(segment)
		else:
			for action in segment: explicit_wait_route.append(action)
	var explicit_replay: Dictionary = Validator._replay_solution(nightmare, explicit_wait_route, nightmare.target_3_stars)
	ok = ok and explicit_replay.completed and explicit_replay.echoes_used == 2 and explicit_replay.wait_used == 5
	bypass["constructive_explicit_wait_witness"] = {"source": "derived route, authoritative replay verified; no optimality claim", "actions": explicit_wait_route, "replay": explicit_replay}
	report.echo_count.append(bypass)
	var output = FileAccess.open("res://tests/fixtures/campaign_design_weaknesses.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t") + "\n")
	output.close()
	print("DESIGN AUDIT: %d movement-padding witnesses; Nightmare %d-Echo witness, %d actions, %d WAITs" % [report.movement_padding.size(), bypass.get("replay", {}).get("echoes_used", -1), bypass.get("replay", {}).get("turns", -1), bypass.get("replay", {}).get("wait_used", -1)])
	quit(0 if ok else 1)
