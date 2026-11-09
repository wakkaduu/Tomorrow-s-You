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

	for i in range(total_levels):
		var lvl: LevelDefinition = LevelRegistryClass.get_level(i)
		var sol: Array = solutions.get(lvl.level_id, [])

		var res: Dictionary = LevelValidatorClass.validate_level(lvl, sol)
		print(res["report"])

		if res["zero_echo_passed"]:
			zero_echo_blocked += 1
		if res["sub_min_echoes_passed"]:
			sub_min_blocked += 1
		if res["is_valid"]:
			validated_levels += 1

	print("\n===================================================================")
	print(" SUMMARY OF ECHO-DEPENDENCY VALIDATION")
	print("===================================================================")
	print(" Zero-Echo bypass routes eliminated: %d / %d (100%% requirement)" % [zero_echo_blocked, total_levels])
	print(" Sub-minimum Echo blocks verified:   %d / %d" % [sub_min_blocked, total_levels])
	print(" Fully validated campaign levels:    %d / %d" % [validated_levels, total_levels])
	print("===================================================================")

	if validated_levels == total_levels and zero_echo_blocked == total_levels:
		print(" ALL 10 CAMPAIGN PUZZLES PASS ZERO-ECHO BYPASS & SOLVABILITY TESTS! ")
		quit(0)
	else:
		push_error(" LEVEL VALIDATION DETECTED FAILURES OR BYPASSES!")
		quit(1)

func _get_verified_solutions() -> Dictionary:
	return {
		"lvl_01": _str_to_actions("DDDWWWWW ECHO RRRDDDRR"),
		"lvl_02": _str_to_actions("DDDDWWWW ECHO RRRDDRRR"),
		"lvl_03": _str_to_actions("RRRRRRWWWW ECHO RRR D W W D D RRR"),
		"lvl_04": _str_to_actions("RRWWWWWWWW ECHO DRRRRURRWWWWWW ECHO DRRRRDD W LLLD"),
		"lvl_05": _str_to_actions("LLLUUWWWW ECHO RRRUUWWWW ECHO W W W W W DD"),
		"lvl_06": _str_to_actions("DDWWWWWWWW ECHO DRRRRRURRWWWWWW ECHO DRRRRRDDDRRR"),
		"lvl_07": _str_to_actions("RRRWWWWWWWW ECHO DRRRRRURRWWWWWW ECHO DRRRRRDDDRRR"),
		"lvl_08": _str_to_actions("RRRWWWWWWWWWWWW ECHO RRRRDDRRRWWWWWW ECHO RRRRDD W W W D D LLL WWWW ECHO RRRRDD W W W DD W W W DD"),
		"lvl_09": _str_to_actions("RRRWWWWWWWWWWWW ECHO RRRRDDRRRWWWWWW ECHO RRRRDD W W W D D LLL WWWW ECHO RRRRDD W W W DD W W W DD"),
		"lvl_10": _str_to_actions("DRWWWWWWWWWWWWWW ECHO DRRRRRURRRWWWWWWWW ECHO DRRRRRDWWWWDDDRRWWWW ECHO DRRRRRDWWWWDDD WW LLDL")
	}

func _str_to_actions(s: String) -> Array:
	var result: Array = []
	var tokens: PackedStringArray = s.split(" ", false)
	for tok in tokens:
		if tok == "ECHO":
			result.append("ECHO")
		elif tok == "RESTART":
			result.append("RESTART")
		else:
			for i in range(tok.length()):
				var ch = tok[i]
				match ch:
					"U", "D", "L", "R", "W": result.append(ch)
	return result

