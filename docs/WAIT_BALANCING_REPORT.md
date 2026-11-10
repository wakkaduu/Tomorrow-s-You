# WAIT balancing report

All ten configured allowances now equal their verified **bounded intended-route minima**, with no bonus WAITs. Sequential Relay changes from **16 to 2**. The user explicitly chose to preserve movement rules and apply bounded intended-route budgets after the zero-WAIT movement-padding finding.

These are **not unrestricted mathematical minima**. The machine-readable proof scope and the limitations below are part of the result. Movement loops remain legal in gameplay. No level geometry, door rule, Echo lifecycle, star target, story, progression or save schema was changed.

## Applied allowances

| Level | Difficulty | Previous WAIT | Verified Minimum | Applied WAIT | Solver Status |
|---|---|---:|---:|---:|---|
| 1. First Contact | Easy | 12 | 3 (bounded) | 3 | BOUNDED_EXACT |
| 2. Stay Behind | Easy | 12 | 2 (bounded) | 2 | BOUNDED_EXACT |
| 3. Double Perspective | Easy | 12 | 1 (bounded) | 1 | BOUNDED_EXACT |
| 4. Sequential Relay | Normal | 16 | 2 (bounded) | 2 | BOUNDED_EXACT |
| 5. Split Decision | Normal | 14 | 4 (bounded) | 4 | BOUNDED_EXACT |
| 6. Crossed Signals | Hard | 15 | 4 (bounded) | 4 | BOUNDED_EXACT |
| 7. No Turning Back | Hard | 15 | 8 (bounded) | 8 | BOUNDED_EXACT |
| 8. Temporal Interlock | Expert | 32 | 8 (bounded) | 8 | BOUNDED_EXACT |
| 9. Parallel Existence | Expert | 32 | 20 (bounded) | 20 | BOUNDED_EXACT |
| 10. The Last Tomorrow | Nightmare | 37 | 9 (bounded) | 9 | BOUNDED_EXACT |

Nightmare additionally has a verified **pre-existing two-Echo route** despite its intended three-Echo design. Its global Echo-count validation is flagged, not passed. Its WAIT optimization fixes the intended count at three, as required by the chosen domain.

## Search domain and completeness

For every level, the domain contains exactly the intended number of Echoes, one terminal recording on each distinct pressure plate, in **every plate order**. Each recording takes any spatially shortest route from spawn to its assigned plate, then may WAIT there before committing. The final player takes any spatially shortest route from spawn to the exit. WAIT is considered at **every position**, including before doors. Distances ignore door closure only to enumerate candidate routes; every actual action must pass the authoritative collision and temporal rules.

This excludes both repeated movement loops and longer acyclic detours used solely to delay playback. It also excludes extra Echoes and recordings ending away from their assigned plate. Those are explicit design-domain restrictions, not newly imposed gameplay rules. This is why an unrestricted minimum is not claimed.

The total accepted-action bound is the existing three-star target. It is a solver/validation bound, **not a new hard gameplay move cap**. Echo creation is not an accepted turn and is not added to star action counts. Among solutions with the least WAIT, accepted actions are minimized secondarily. Because all domain routes are shortest and every plate is used once, total movement length is fixed; this secondary cost is the route-length sum plus WAITs.

The search tests WAIT budgets 0, 1, 2, … until the first feasible budget. All lower-budget trials are complete. Proof regeneration and replay are tested, including node counts. “Complete” includes sound lower-bound pruning and duplicate-state elimination; it does not mean every equivalent action string was individually enumerated.

All transitions use `PuzzleSimulation.step_move`, `step_wait` and `create_echo`. Branches copy deterministic simulation state; no alternative gameplay simulator decides legality. This preserves future-turn door entry, final-turn Echo occupancy, expiry, AND/OR conditions, sequence latches, occupied-door safety, and exit resolution.

Admissible pruning relaxes Echo expiry by allowing plates to remain held after their earliest possible arrival. A topology-checked terminal-holder lemma supplies lifetime lower bounds only when other shortest-route actors either cannot visit the plate or must subsequently cross a remote AND gate controlled by it. Another actor cannot be its latest holder in that second case: constructing its later gate crossing requires an even later holder in an earlier recording. Arbitrary layouts that fail this check fall back to weaker bounds. The relaxation never authorizes gameplay actions. Unpruned exhaustive searches agree for Levels 1–6.

Visited keys retain player position, clock, sequence state, previous plate state, WAIT resources and every turn of recorded plate occupancy. Historical non-plate Echo positions cannot affect collisions or mechanisms. Discarded attempts and Clear All are dominated: removing the discarded prefix leaves the same deterministic future state with fewer accepted actions. They cannot improve either objective, so optimal searches need not generate them; reset accounting remains covered by gameplay regressions.

Guards are 2,000,000 node visits and 120 seconds per level. A guard hit produces `INCONCLUSIVE`, even if a witness was found. No final intended-route search hit a guard. Node counts below include entry visits later pruned or deduplicated; they are not claims of distinct unique world states.

| Level | Intended Echoes | Action bound | Solution actions | Search node visits | Lower WAIT budgets ruled out | Validation |
|---|---:|---:|---:|---:|---|---|
| 1 | 1 | 18 | 14 | 38 | 0–2, complete in domain | Replay PASS |
| 2 | 1 | 18 | 14 | 33 | 0–1, complete in domain | Replay PASS |
| 3 | 1 | 24 | 16 | 30 | 0, complete in domain | Replay PASS |
| 4 | 2 | 40 | 23 | 56 | 0–1, complete in domain | Replay PASS |
| 5 | 2 | 28 | 16 | 116 | 0–3, complete in domain | Replay PASS |
| 6 | 2 | 42 | 27 | 226 | 0–3, complete in domain | Replay PASS |
| 7 | 2 | 42 | 32 | 415 | 0–7, complete in domain | Replay PASS |
| 8 | 3 | 70 | 41 | 853 | 0–7, complete in domain | Replay PASS |
| 9 | 3 | 70 | 53 | 24,390 | 0–19, complete in domain | Replay PASS |
| 10 | 3 | 80 | 47 | 5,695 | 0–8, complete in domain | Replay PASS |

## Per-level solutions and reasons

Notation: `U/D/L/R` are accepted moves; `W` is one recorded WAIT. Commit each Echo recording before the next line. These sequences come from solver output, not estimated recipes.

### 1. First Contact

Echo 1 arrives at Plate 1 on turn 3 and must remain through Door A entry on turn 6: three recorded WAITs.

- Echo 1: `DDDWWW` — 3 WAITs, 6 accepted actions.
- Player: `DRRRDDRR` — 0 WAITs, 8 accepted actions.

The real simulation reaches exit `[6, 4]` with 3 WAITs and 14 actions. Smaller budgets are excluded by the complete domain trials listed above. No level-design correction was applied.

### 2. Stay Behind

Echo 1 reaches Plate 1 on turn 4; Door A entry is turn 6: two recorded WAITs. The previous hint incorrectly said the door was five moves away.

- Echo 1: `DDDDWW` — 2 WAITs, 6 accepted actions.
- Player: `DDRRRRRR` — 0 WAITs, 8 accepted actions.

The real simulation reaches exit `[7, 3]` with 2 WAITs and 14 actions. Smaller budgets are excluded by the complete domain trials listed above. No level-design correction was applied.

### 3. Double Perspective

The Echo arrives at Plate 1 on turn 6 and needs no trailing WAIT. The player uses one WAIT so door entry occurs on that final recorded turn.

- Echo 1: `RRRRRR` — 0 WAITs, 6 accepted actions.
- Player: `RRRDWDDRRR` — 1 WAITs, 10 accepted actions.

The real simulation reaches exit `[7, 4]` with 1 WAITs and 16 actions. Smaller budgets are excluded by the complete domain trials listed above. No level-design correction was applied.

### 4. Sequential Relay

Echo 1 reaches Plate 1 on turn 2 and supports Door A entry on turn 4: two WAITs. Echo 2 reaches Plate 2 on turn 8, exactly when the player enters Door B; neither needs another WAIT.

- Echo 1: `RRWW` — 2 WAITs, 4 accepted actions.
- Echo 2: `DRRRRURR` — 0 WAITs, 8 accepted actions.
- Player: `DRRRRDDLLDL` — 0 WAITs, 11 accepted actions.

The real simulation reaches exit `[2, 5]` with 2 WAITs and 23 actions. Smaller budgets are excluded by the complete domain trials listed above. No level-design correction was applied.

### 5. Split Decision

Both five-move Echo recordings end on their plates. Four player WAITs align Door A entry with turn 5. No Echo WAIT padding is necessary.

- Echo 1: `LUULL` — 0 WAITs, 5 accepted actions.
- Echo 2: `RUURR` — 0 WAITs, 5 accepted actions.
- Player: `WWWWDD` — 4 WAITs, 6 accepted actions.

The real simulation reaches exit `[4, 5]` with 4 WAITs and 16 actions. Smaller budgets are excluded by the complete domain trials listed above. No level-design correction was applied.

### 6. Crossed Signals

Echo 1 needs three WAITs to support Door A entry on turn 5. Echo 2 needs one to support Door B entry on turn 10.

- Echo 1: `DDWWW` — 3 WAITs, 5 accepted actions.
- Echo 2: `DRRRRRURRW` — 1 WAITs, 10 accepted actions.
- Player: `DRRRRRDDDRRR` — 0 WAITs, 12 accepted actions.

The real simulation reaches exit `[9, 5]` with 4 WAITs and 27 actions. Smaller budgets are excluded by the complete domain trials listed above. No level-design correction was applied.

### 7. No Turning Back

Cumulative Door B needs both plates on turn 10: Echo 1 records seven WAITs after its three-move route, and Echo 2 records one after its nine-move route.

- Echo 1: `RRRWWWWWWW` — 7 WAITs, 10 accepted actions.
- Echo 2: `DRRRRRURRW` — 1 WAITs, 10 accepted actions.
- Player: `DRRRRRDDDRRR` — 0 WAITs, 12 accepted actions.

The real simulation reaches exit `[9, 5]` with 8 WAITs and 32 actions. Smaller budgets are excluded by the complete domain trials listed above. No level-design correction was applied.

### 8. Temporal Interlock

Echo 1 records two WAITs for Door A. Echo 2 ends immediately at Plate 2 on turn 9. Echo 3 uses two WAITs before Door B; the player uses four WAITs across the two downstream doors. Door C entry is turn 13.

- Echo 1: `RRRWW` — 2 WAITs, 5 accepted actions.
- Echo 2: `RRRRDDRRR` — 0 WAITs, 9 accepted actions.
- Echo 3: `RRRRDDWWDDLLL` — 2 WAITs, 13 accepted actions.
- Player: `RRRRDDWWDDWWDD` — 4 WAITs, 14 accepted actions.

The real simulation reaches exit `[5, 7]` with 8 WAITs and 41 actions. Smaller budgets are excluded by the complete domain trials listed above. No level-design correction was applied.

### 9. Parallel Existence

Door C requires all three plates on turn 13. Echo 1 needs ten WAITs, Echo 2 four, Echo 3 two before Door B, and the player four. This cumulative condition explains the larger intended-route budget.

- Echo 1: `RRRWWWWWWWWWW` — 10 WAITs, 13 accepted actions.
- Echo 2: `RRRRDDRRRWWWW` — 4 WAITs, 13 accepted actions.
- Echo 3: `RRRRDDWWDDLLL` — 2 WAITs, 13 accepted actions.
- Player: `RRRRDDWWDDWWDD` — 4 WAITs, 14 accepted actions.

The real simulation reaches exit `[5, 7]` with 20 WAITs and 53 actions. Smaller budgets are excluded by the complete domain trials listed above. No level-design correction was applied.

### 10. The Last Tomorrow

Echo 1 uses three WAITs for Door A. Echo 2 needs none after reaching Plate 2. Echo 3 uses two before Door B. The player uses four, including the sequence latch phase: Plate 3 activates on turn 14, and Door C entry occurs on turn 15.

- Echo 1: `DRWWW` — 3 WAITs, 5 accepted actions.
- Echo 2: `DRRRRRURRR` — 0 WAITs, 10 accepted actions.
- Echo 3: `DRRRRRDWWDDDRR` — 2 WAITs, 14 accepted actions.
- Player: `DRRRRRDWWDDDWWLLDL` — 4 WAITs, 18 accepted actions.

The real simulation reaches exit `[3, 7]` with 9 WAITs and 47 actions. Smaller budgets are excluded by the complete domain trials listed above. No level-design correction was applied.

## Movement padding and global limitations

The movement diagnostic preserves legal zero-WAIT witnesses for Levels **2, 4, 5 and 8**, all inside their three-star action targets. They replay successfully in the real simulation, and route inspection marks their movement padding. Diagnostics for other levels found no zero-WAIT witness in their limited detour probe; those broader results are **INCONCLUSIVE**, not proofs of global WAIT necessity.

For Sequential Relay, the diagnostic found a zero-WAIT **23-action** route—the same action count as the intended two-WAIT solution:

```text
Echo 1: DU RR
Echo 2: D RRRR U RR
Player: D RRRR DD LL D L
```

`DU` is a movement loop replacing temporal delay. A three-star constraint alone therefore cannot distinguish it from the intended WAIT solution. Declaring zero WAIT to be good WAIT teaching, or claiming two WAITs are globally necessary, would both be incorrect. Per the user’s decision, movement stays unrestricted and the applied two-WAIT allowance is explicitly an intended-route result. No new anti-loop rule or arbitrary map restriction was added.

### Nightmare Echo-count weakness

The new authoritative prefix counterexample search found a legal two-Echo completion in **35 actions and 3 WAITs**, exploring **2,600** player-prefix search nodes. The first two canonical recordings suffice: the real player activates Plate 3, latching the sequence door, then returns through it. The witness also includes movement timing padding. A separately replayed two-Echo route with five explicit WAITs and 35 actions confirmed that the sequence-latch shortcut does not depend on replacing all timing with movement.

The old static plate validator never modeled the sequence latch opening and incorrectly certified the intended count. The updated validator stores the replayed counterexample, returns `global_echo_status = VIOLATED_BY_REPLAYED_WITNESS`, and does **not** set overall `is_valid` for this level. `optimization_valid` describes only the explicitly fixed three-Echo, shortest-route domain. Other sub-minimum Echo checks remain topology/prefix screens, not exhaustive global temporal proofs; the zero-Echo search now uses the actual simulation and handles sequence state.

A sequence-door or exit requirement change could enforce the intended third Echo, but would change current gameplay. It was not folded into this WAIT-only balance pass. Global minima and global Echo-count guarantees outside the documented domain remain unproven except where a concrete counterexample disproves them.

## Fixtures, runtime integration and validator

- `tests/fixtures/wait_solver_results.json`: ten complete domain searches, individual lower-budget trials, per-recording actions/WAIT counts, action totals, layout/rules fingerprints, and actual final exit states.
- `tests/fixtures/wait_padding_results.json`: bounded movement diagnostics and zero-WAIT witnesses; failed probes are not labeled global impossibility.
- `tests/fixtures/campaign_design_weaknesses.json`: replayed padding and two-Echo counterexamples, with actual exit states.
- `scripts/level/campaign_solutions.gd`: compact runtime copy of solver-generated recordings. Tests compare it against proof fixtures. Hint solutions are generated from this source, so previously revealed hints remain accurate without spending new hint credits.
- `scripts/level/level_registry.gd`: explicit per-level allowances; no shared difficulty multiplier or spare credits.
- `scripts/level/level_validator.gd`: verifies every accepted replay action, WAIT and action bounds, plate occupancy, door conditions, expiry, intended Echo count and completion; rejects trailing actions and missing witnesses. Proof metadata cannot certify a changed layout or mismatching fixture. Global Echo weaknesses and bounded optimization status are separate.

Implementation files added or refined in this pass include `scripts/solver/campaign_wait_solver.gd`, `scripts/level/campaign_solutions.gd`, `level_definition.gd`, `level_registry.gd`, `level_validator.gd`, and `scripts/hints/hint_registry.gd`. Solver/audit runners and regression coverage are in `tests/solver/`; campaign test runners now share the canonical fixtures instead of retaining obsolete padded solutions. The existing completion test recipe and rendered QA capture were adjusted to the tighter budget. `README.md` points to this scope and its known weaknesses.

Existing derived WAIT accounting, restart refunds, Clear All, shared keyboard/touch validation and the `WAIT · n LEFT` HUD remain unchanged. All allowances now come from the actual bounded solutions. Saves and progression are not reset.

## Executed validation

All tests used isolated temporary saves under `/tmp/tomorrow-wait-opt-8bxdfmsz/`. No player save was reset. Final results:

| Suite | Result |
|---|---|
| WAIT optimization, regenerated proofs, lower bounds, fixtures, hints, every-level HUD | 282/282 checks |
| Door/WAIT/campaign regression | 3,187/3,187 checks |
| Master mechanics/campaign/hints | 38/38 |
| Dedicated simulation | 14/14 |
| Campaign replay | 10/10 intended solutions |
| Validator audit | 10/10 intended solutions; known Nightmare bypass correctly flagged |
| Mounted integration | 11/11 |
| Android mobile systems | 50/50 |
| UI/resolution integration | 105/105 |
| Completion/save/navigation | 12/12 |
| Narrative and save scenarios | 10/10 and 4/4 |
| Opening transmission flow | Exit 0 |
| Daily hints | 20/20 |
| UI scenes/save/audio | 7/7 |
| Board responsiveness | 36/36 |
| Atmospheric backgrounds | 8/8 |

Rendered desktop QA at 360×640 confirms Sequential Relay displays `WAIT · 2 LEFT`, then `WAIT · 0 LEFT`, disables the action, and shows the generated exact-budget hint. Screenshots were captured and inspected from `tests/visual/capture_wait_balance.gd` using an isolated save. Android debug export completed and its APK (`/tmp/tomorrow-wait-opt-8bxdfmsz/TomorrowsYou-debug.apk`) passed v2/v3 signature verification. No phone installation or physical-device playtest is claimed.

Known tooling limitations: existing ObjectDB shutdown warnings persist; detached-renderer responsiveness checks emit existing absolute-path lookup errors despite their assertions passing. Android export used its existing SDK/build-tool fallback and reported an unavailable ADB daemon; packaging and signature verification succeeded.

## Reproduction

Run these with isolated `XDG_DATA_HOME` and `XDG_CONFIG_HOME` directories, because existing suites write/reset test progress:

```sh
godot --headless --path . -s tests/solver/optimize_campaign_waits.gd
godot --headless --path . -s tests/solver/probe_movement_padding.gd
godot --headless --path . -s tests/solver/audit_campaign_design.gd
godot --headless --path . -s tests/solver/test_wait_optimization.gd
godot --headless --path . -s tests/regression/test_turn_and_wait.gd
```

The optimizer regenerates proof artifacts; it does not silently rewrite runtime level values or manufacture a budget when search is inconclusive. Any future level/rules changes require proof regeneration, replay and runtime fixture synchronization.

No commit or push was made. Suggested commit: `Apply solver-verified intended-route WAIT budgets and audit campaign shortcuts`.
