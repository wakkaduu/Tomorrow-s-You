extends SceneTree

# Preload classes
const LevelRegistryClass = preload("res://scripts/level/level_registry.gd")
const LevelValidatorClass = preload("res://scripts/level/level_validator.gd")

func _init() -> void:
	print("\n===================================================================")
	print(" TOMORROW'S YOU — AUTOMATED LEVEL VALIDATOR & ECHO-DEPENDENCY SUITE")
	print("===================================================================")

	var solutions: Dictionary = _get_verified_solutions()
	var total_levels: int = 10
	var validated_levels: int = 0
	var zero_echo_blocked: int = 0
	var sub_min_blocked: int = 0
	var known_bypasses: Array[String] = []

	for i in range(total_levels):
		var lvl: LevelDefinition = LevelRegistryClass.get_level(i)
		var sol: Array = solutions.get(lvl.level_id, [])

		var res: Dictionary = LevelValidatorClass.validate_level(lvl, sol)
		print(res["report"])

		if res["zero_echo_passed"]:
			zero_echo_blocked += 1
		if res["sub_min_echoes_passed"]:
			sub_min_blocked += 1
		if res["intended_solution_valid"]:
			validated_levels += 1
		if res["global_echo_status"] == "VIOLATED_BY_REPLAYED_WITNESS": known_bypasses.append(lvl.level_id)

	print("\n===================================================================")
	print(" SUMMARY OF ECHO-DEPENDENCY VALIDATION")
	print("===================================================================")
	print(" Zero-Echo bypass routes eliminated: %d / %d (100%% requirement)" % [zero_echo_blocked, total_levels])
	print(" Sub-minimum Echo blocks verified:   %d / %d" % [sub_min_blocked, total_levels])
	print(" Verified intended campaign solutions:    %d / %d" % [validated_levels, total_levels])
	print("===================================================================")

	if validated_levels == total_levels and zero_echo_blocked == total_levels and known_bypasses == ["lvl_10"]:
		print(" ALL 10 INTENDED SOLUTIONS VERIFIED; KNOWN NIGHTMARE TWO-ECHO BYPASS CORRECTLY REPORTED ")
		quit(0)
	else:
		push_error(" LEVEL VALIDATION DETECTED FAILURES OR BYPASSES!")
		quit(1)

static func _get_verified_solutions() -> Dictionary:
	var solutions = preload("res://scripts/level/campaign_solutions.gd")
	var result: Dictionary = {}
	for level_id in solutions.SOLUTIONS:
		result[level_id] = solutions.get_actions(level_id)
	return result
