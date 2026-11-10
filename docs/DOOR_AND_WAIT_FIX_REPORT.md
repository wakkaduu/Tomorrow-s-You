# Door synchronization and shared WAIT budget

## Diagnosis and reproduction

The new `tests/regression/test_turn_and_wait.gd` reproduced both reported visual
failures before the fix: **2/4 checks passed, exit 1**. On opening, the simulation
was open while the renderer's gate weight remained 0. After settling the opening
animation and advancing the Echo off the plate, the simulation closed while the
renderer's weight remained 1. Original state-change handlers only initialized a
missing cache entry; later changes depended on frame-time interpolation. That
interpolation controlled barrier width, opacity and the open/closed drawing branch.
Rapid turns could therefore show an obsolete gate.

A separate source of apparent disagreement was already intentional simulation
behavior: door entry projects the Echoes to the **upcoming turn**, while the current
board represents the last committed turn. An Echo on its final recorded action
still occupies its plate now, but expires before entry on the next turn. Changing
collision to use the previous turn would change campaign timing. This rule was
preserved and made visible with an amber cross and `NEXT: SHUT` forecast. An
upcoming opening is similarly marked `NEXT: OPEN`.

## Authoritative turn resolution

`PuzzleSimulation` remains the only authority. An accepted action now resolves:

1. Validate walls and projected next-turn door entry using the player's pre-move
   position, active next-turn Echo positions, and existing sequence latch.
2. Record the player action and increment the turn once.
3. Resolve active Echo occupancy at that turn; recordings are active through their
   last recorded action and inactive from the following turn.
4. Recalculate plates, sequence state, and doors, including player-in-door safety.
5. Publish environment notifications only after all environment tables are updated;
   then publish actor presentation events, check the exit, and publish turn completion.

`get_turn_snapshot()` returns copied environment tables, actor states, upcoming
door-entry forecasts and derived WAIT usage. HUD and presentation observers no
longer receive actor movement before environment resolution. Restart clears old
plate/door tables and sequence state before resolving turn zero.

The renderer reads authoritative booleans directly for gate geometry and plate
appearance. Signal caches update immediately, with no environment interpolation
or queued Tween. Decorative actor/background animation remains. Expired Echoes
already use the authoritative active flag and disappear on the resolved boundary.
The player cannot be crushed in an occupied door; historical Echoes continue
replaying their recorded paths regardless of current collision.

F12 inspection enables debug-build-only resolved snapshot and logical/rendered
state logging. Per-turn production console spam was removed. Debug diagnostics
report a mismatched presentation cache if one occurs.

## WAIT accounting and balance

Each LevelDefinition exports `max_wait_actions` and rejects negative budgets.
Usage is derived from **all committed recordings plus the current recording**;
expired recordings still consume their allocation. There is no separate mutable
currency counter. Creating an Echo transfers its counted usage without charging
again. Playback never incurs another charge. Restart discards/refunds only the
current attempt; Clear Echoes discards/refunds everything.

An exhausted request emits feedback and returns before changing the turn, score,
recording, Echo playback, plate state or door state. Keyboard, touch and the
previously inert time-advancing Interact action all use this validation. Invalid
movement directions and malformed stationary MOVE recordings cannot disguise
idle turns. Committing an over-budget or structurally invalid recording fails.
No save schema migration or progress reset is introduced.

The suggested difficulty defaults cannot accommodate the existing verified
solutions and published hints. The campaign keeps its topology, timing, solutions
and Echo requirements, with these per-level allowances:

| Level | Verified WAITs used | Budget | Spare |
| --- | ---: | ---: | ---: |
| 1 — First Contact | 5 | 12 | 7 |
| 2 — Stay Behind | 4 | 12 | 8 |
| 3 — Double Perspective | 6 | 12 | 6 |
| 4 — Sequential Relay | 15 | 16 | 1 |
| 5 — Split Decision | 13 | 14 | 1 |
| 6 — Crossed Signals | 14 | 15 | 1 |
| 7 — No Turning Back | 14 | 15 | 1 |
| 8 — Temporal Interlock | 31 | 32 | 1 |
| 9 — Parallel Existence | 31 | 32 | 1 |
| 10 — The Last Tomorrow | 36 | 37 | 1 |

These are bounded initial budgets grounded in the current solutions, not a proof
of minimum necessary WAIT counts. Further balancing can optimize solutions and
revise hints together. Legitimate movement remains available at zero WAITs.

The existing WAIT icon/button now displays `WAIT · n LEFT`, a compact remaining
allowance bar, disabled exhaustion state and `TEMPORAL WAIT LIMIT REACHED`.
A blocked request gives normal blocked-action audio/haptics. The bottom controls
also respect horizontal safe margins; this was checked in rendered desktop QA.

## Files changed in this task

- `scripts/gameplay/puzzle_simulation.gd`: authoritative commit ordering, snapshots,
  derived budget validation, idle shortcut validation and opt-in diagnostics.
- `scripts/gameplay/board_renderer.gd`: immediate authoritative plate/door drawing,
  synchronized caches, next-entry warnings and renderer diagnostics.
- `scripts/gameplay/gameplay_controller.gd`: remaining allowance UI and feedback,
  budget diagnostics, safe horizontal control margins.
- `scripts/echoes/echo_recording.gd`: WAIT counting and recording action validation.
- `scripts/level/level_definition.gd`, `level_registry.gd`: configurable validated
  allowance and ten campaign budgets.
- `scripts/level/level_validator.gd`: report budgets and reject failed WAIT actions
  during verified replay instead of silently continuing.
- `tests/regression/test_turn_and_wait.gd`: reproduction, door/plate/expiration/
  rapid-update tests, AND/OR and sequence checks, collision safety, budget/input/
  reset/UI tests, and deterministic campaign replay with per-action assertions.
- `tests/visual/capture_turn_and_wait.gd`: repeatable rendered QA captures.
- `tests/core/test_level_validation.gd`: expose existing pure solution fixtures
  statically for reuse by regression coverage.
- `tests/run_all_tests.gd`, `tests/core/test_puzzle_simulation.gd`: explicit finite
  budgets on synthetic fixtures that intentionally use 17, 19 or 14 WAITs.
- `tests/core/test_level_completion.gd`: dismiss the existing completion outro
  before asserting completion-modal navigation. Previous tests incorrectly
  expected the completion modal while the outro was still displayed.
- `README.md` and this report: document new allowance and existing collision phase.

Earlier uncommitted UI work was retained. No commit, push, save reset, website edit
or export-preset change was performed.

## Tests and verification

All Godot test runs used isolated temporary `XDG_DATA_HOME` directories; fixtures
that reset progress cannot touch the player's normal save. Full logs are in
`/tmp/tomorrow-turn-wait-lqii8gx0/` for this session.

| Executed suite | Final result |
| --- | --- |
| New turn/WAIT regression, including per-action campaign assertions | **4297/4297 checks** |
| Master mechanics/campaign/hints | 38/38 |
| Dedicated core simulation | 14/14 |
| Full campaign solution replay | 10/10 levels |
| Budget-aware validator and minimum-Echo checks | 10/10 levels |
| Mounted integration | 11/11 |
| Android mobile systems | 50/50 |
| UI/resolution integration | 105/105 |
| Board responsiveness | 36/36 |
| Completion/save/navigation | 12/12 |
| Narrative registry/archive | 10/10 |
| Narrative save scenarios/triggers | 4/4 |
| Opening transmission flow | Exit 0 |
| Daily hints | 20/20 |
| UI scenes/save/audio | 7/7 |
| Atmospheric backgrounds | 8/8 |

Door regressions run without waiting for animation frames, then vary frame deltas
and verify that no older animation restores obsolete states. Campaign replay checks
every action is accepted, checks independent occupancy expectations and immediate
gate presentation, compares two simulations for determinism, checks WAIT totals,
and verifies completion with the intended minimum Echo count. The separate
validator replays the same paths and checks the existing topology constraints.

Exhausted control layouts were checked at 360×640, 360×800, 390×844, 412×915 and
432×960. Keyboard, forced button activation, disabled touch, pause, hints,
communication log, app-resume notification, restart and full reset are exercised.

Desktop Godot launched successfully with the OpenGL compatibility override for
rendered QA; the project renderer setting remains Mobile. Four real 360×640
screenshots were captured and inspected: open gate, final-action next-entry
warning, expired-Echo closed gate, and exhausted WAIT. They are in
`/tmp/tomorrow-turn-wait-lqii8gx0/visual/godot/app_userdata/Tomorrow's You/qa/`.

The existing Android debug preset exported and verified successfully using local
Godot 4.7.2 templates, JDK 17 and Android build tools 34.0.0. The signed debug APK is
`/tmp/tomorrow-turn-wait-lqii8gx0/TomorrowsYou-debug.apk`. No installation or phone
test is claimed. Export reported an SDK/build-tool version fallback and denied
sandbox ADB/editor sockets; these did not prevent packaging/signing verification.

Remaining limitations: existing ObjectDB shutdown warnings persist in some test
harnesses; detached-renderer responsiveness tests emit existing absolute-path
lookup errors. Device Vulkan rendering, touch feel, notches, app lifecycle and
longer player balance sessions still require physical Android QA. Debug artifacts
in `/tmp` are temporary. `git diff --check` passed.

Suggested commit: `Fix turn-synchronous doors and enforce shared per-level WAIT budgets`
