extends SceneTree
const Solver = preload("res://scripts/solver/campaign_wait_solver.gd")
const Registry = preload("res://scripts/level/level_registry.gd")
const Solutions = preload("res://scripts/level/campaign_solutions.gd")
const Validator = preload("res://scripts/level/level_validator.gd")
const Sim = preload("res://scripts/gameplay/puzzle_simulation.gd")
const Hints = preload("res://scripts/hints/hint_registry.gd")
var checks: int = 0
var failures: int = 0
func _init() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _run() -> void:
	var fixtures: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/wait_solver_results.json"))
	check(fixtures.size() == 10, "All ten proof fixtures exist")
	for fixture: Dictionary in fixtures:
		var level: LevelDefinition = Registry.get_level_by_id(fixture.level_id)
		check(level.max_wait_actions == int(fixture.minimum_wait), "Applied budget equals intended-route minimum")
		check(Solutions.get_actions(level.level_id) == fixture.actions, "Runtime and proof actions agree")
		check(Solutions.get_wait_limit(level.level_id) == level.max_wait_actions, "Runtime solution and level limit agree")
		var solver = Solver.new()
		var computed: Dictionary = solver.solve(level)
		check(computed.status == "BOUNDED_EXACT", "Solver did not exhaust resources")
		check(computed.minimum_wait == fixture.minimum_wait and computed.actions == fixture.actions and computed.total_actions == fixture.total_actions, "Deterministic proof regeneration matches fixture")
		check(JSON.parse_string(JSON.stringify(computed.trials)) == fixture.trials, "Exhaustive lower-budget trials and state counts reproduce")
		var report: Dictionary = Validator.validate_level(level, fixture.actions, fixture.action_bound, fixture)
		check(report.intended_solution_valid and report.optimization_valid and report.optimization_status == "BOUNDED_EXACT", "Budget-aware witness and proof validation")
		check(report.replay.wait_used == level.max_wait_actions and report.replay.turns == int(fixture.total_actions), "Authoritative replay matches objective")
		check(report.sub_min_echoes_passed if level.level_id != "lvl_10" else report.global_echo_status == "VIOLATED_BY_REPLAYED_WITNESS", "Known sequence-latch bypass is not falsely certified")
		check(report.route_analysis.intended_route, "Intended fixture contains no padding or repeated movement tiles")
		check(JSON.parse_string(JSON.stringify(report.replay.exit_state)) == fixture.verification.exit_state, "Actual final exit state matches proof fixture")
		var text: String = Hints.get_hint_stage(level.level_id, 2).text
		check(text == Solutions.get_solution_text(level.level_id), "Hints use current legal exact-budget solution")
		var lower: LevelDefinition = level.duplicate(true)
		lower.initialize_from_map()
		lower.max_wait_actions -= 1
		var lower_replay: Dictionary = Validator._replay_solution(lower, fixture.actions, fixture.action_bound)
		check(not lower_replay.completed, "Chosen witness fails under smaller allowance; full minimality uses regenerated exhaustive trials")
		check(not Validator._replay_solution(level, fixture.actions, int(fixture.total_actions) - 1).completed, "Action bound enforced")
		check(not Validator._replay_solution(level, fixture.actions + ["W"], fixture.action_bound).completed, "Trailing actions cannot be silently accepted")
		var tampered: Dictionary = fixture.duplicate(true)
		tampered.level_fingerprint = "stale"
		check(not Validator.validate_level(level, fixture.actions, fixture.action_bound, tampered).optimization_valid, "Stale proof rejected")
		# Exhaustion must not alter any environmental, Echo or scoring state.
		var sim = Sim.new()
		sim.load_level(level)
		for i in range(level.max_wait_actions): check(sim.step_wait(), "Configured allowance is spendable")
		var snapshot: Dictionary = sim.get_turn_snapshot()
		var score: int = sim.total_actions_taken
		var recording: Array = sim.current_recording.steps.duplicate(true)
		check(not sim.step_wait() and sim.get_turn_snapshot() == snapshot and sim.total_actions_taken == score and sim.current_recording.steps == recording, "Exhausted WAIT rejects atomically")
		var forked = Solver.fork(sim)
		forked.restart_attempt()
		check(sim.get_turn_snapshot() == snapshot, "Solver forks do not alias mutable current recording")
	# The search delegates OR and sequence timing to the same authoritative engine.
	var or_level: LevelDefinition = Registry.get_level(0).duplicate(true)
	or_level.initialize_from_map()
	or_level.doors_data[0]["logic"] = "OR"
	check(Solver.new().solve(or_level).minimum_wait == 3, "Solver understands OR doors")
	var sequence_level = load("res://scripts/level/level_definition.gd").new()
	sequence_level.level_id = "solver_sequence"
	sequence_level.map_lines.assign(["########", "#P1.2AX#", "########"])
	sequence_level.doors_data.assign([{"id": "A", "logic": "SEQUENCE", "required_sequence": ["1", "2"]}])
	sequence_level.echo_limit = 2
	sequence_level.min_echoes_required = 2
	sequence_level.target_3_stars = 20
	sequence_level.initialize_from_map()
	var sequence_result: Dictionary = Solver.new().solve(sequence_level)
	check(sequence_result.status == "BOUNDED_EXACT" and sequence_result.minimum_wait == 0, "Solver understands sequence latches and zero-WAIT budgets")
	check(Validator._replay_solution(sequence_level, sequence_result.actions, 20).completed, "Sequence solver witness replays")
	# Cut-off searches must never be called exact, even if a witness was discovered.
	var limited = Solver.new()
	limited.max_states = 0
	check(limited.solve(Registry.get_level(3)).status == "INCONCLUSIVE", "State guard reports INCONCLUSIVE")
	var missing: Dictionary = Validator.validate_level(Registry.get_level(3))
	check(not missing.is_valid and missing.optimization_status == "INCONCLUSIVE", "No witness is not validation success")
	# Verify lower bounds against unpruned exhaustive enumeration on small campaigns.
	for i in [0, 1, 2, 3, 4, 5]:
		var plain = Solver.new()
		plain.use_lower_bounds = false
		var result: Dictionary = plain.solve(Registry.get_level(i))
		check(result.status == "BOUNDED_EXACT" and result.minimum_wait == Registry.get_level(i).max_wait_actions, "Unpruned search agrees with admissible lower bounds")
	var padding: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/wait_padding_results.json"))
	var witnesses: int = 0
	for entry: Dictionary in padding:
		if entry.status != "PADDING_WITNESS": continue
		witnesses += 1
		var level = Registry.get_level_by_id(entry.level_id)
		var replay: Dictionary = Validator._replay_solution(level, entry.actions, entry.action_bound)
		check(replay.completed and replay.wait_used == 0, "Movement-padding witness is genuinely legal under star target")
		check(not Solver.inspect_routes(level, entry.actions).intended_route, "Padding cannot masquerade as an intended minimum")
	check(witnesses >= 1, "Known movement-padding weakness is retained as evidence")
	await _hud_limits()
	print("WAIT OPTIMIZATION: %d / %d checks passed" % [checks - failures, checks])
	quit(0 if failures == 0 else 1)

func _hud_limits() -> void:
	var gm = root.get_node("GameManager")
	var sm = root.get_node("SaveManager")
	var narrative = load("res://scripts/narrative/narrative_registry.gd")
	for transmission: Dictionary in narrative.get_all_transmissions():
		sm.viewed_transmissions.append(transmission.id)
	for i in range(10):
		gm.select_level(i)
		var game = load("res://scenes/gameplay/gameplay.tscn").instantiate()
		root.add_child(game)
		await process_frame
		var budget: int = game.current_level_def.max_wait_actions
		check(game.btn_wait.text == "WAIT · %d LEFT" % budget, "Fresh HUD uses this level's solver budget")
		while game.simulation.get_remaining_wait_actions() > 0:
			game.btn_wait.pressed.emit()
		check(game.btn_wait.disabled and game.btn_wait.text == "WAIT · 0 LEFT" and game.wait_meter.value == 0, "Every level shows exact zero and disables WAIT")
		game.queue_free()
		await process_frame
