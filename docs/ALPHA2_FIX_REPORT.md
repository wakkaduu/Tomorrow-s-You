# Alpha 2 Android defect remediation

Status: **four fixes pass automated and internal Android checks; final signed release candidate remains HOLD**.

Follow-up date: November 11, 2026 (Asia/Manila). The original findings and immutable alpha.1 artifact are recorded in [Android release QA](ALPHA_RELEASE_QA.md). No public release is authorized.

## Scope and artifact identity

The implementation is based on `221f4226bf593199c4c7d7b0b5c5bb6f576549fa`, with reviewed fixes approved for commit on November 11, 2026. The internal APK was built before that commit; the final build manifest will record the exact approved source commit. It preserves campaign definitions, intended solutions, WAIT budgets, story content, the release package ID and save schema 3. No website or physical phone was changed.

**The APK tested here is an internal debug build, not the final release APK.** It uses an isolated package suffix so the retained alpha.1 installation and saves remain available for subsequent same-key upgrade testing.

| Field | Internal build actually tested | Final alpha.2 requirement |
|---|---|---|
| Filename | `TomorrowsYou-alpha2-internal-debug.apk` | `TomorrowsYou-v0.1.0-alpha.2-android.apk` — NOT BUILT |
| Package | `com.tomorrowsyou.game.qa` | `com.tomorrowsyou.game` |
| Version / code | `0.1.0-alpha.2` / `5` | Same version/code prepared |
| SHA-256 | `ef5d2a6d4e86b05fca177f0884a949a1017d79b21b5c8fcba32d1cc8828b1a86` | NOT AVAILABLE; do not reuse the debug or alpha.1 hash |
| Size | 117,046,951 bytes | NOT AVAILABLE |
| Signing / debuggable | Existing debug identity / true; signature verified | Permanent alpha.1 release identity / false; NOT TESTED |
| Source | Base commit above plus uncommitted fixes | Exact approved source commit pending |
| Production content fingerprint | `4a3f648a0d685658dfed1ecb613981787ccb468a2f462367e6f2204b3b47ca67` | Recorded again by final build helper |

The staging project is outside Git on the approved secondary drive. Its intentional differences are the `.qa` package suffix, QA display name and debug export/signing. The production game scripts, scenes, assets and Android renderer setting are the fixed working-tree content. Packaging checks now explicitly require certificate SHA-256 `43f8a0c0bfe13c5c60e3d8d61360ffecdbea4778f437b53c8a5bd98d1438f0db` for every release verification, including verification without a prior manifest. No new release keystore was created.

## Defect 1 — Android Back unexpectedly quits

**Original reproduction:** open gameplay Hint Assistance or an archive record and press Android Back. Alpha.1 exits to the launcher instead of dismissing the active modal.

**Cause:** Godot's automatic `quit_on_go_back` behavior remained enabled. AndroidSystemManager additionally listened to both a key fallback and the window notification, while retaining a fallback that explicitly quit from Main Menu. Auxiliary navigation destroyed the original gameplay scene, preventing a faithful return to the paused session.

**Correction:**

- Disable `application/config/quit_on_go_back` in project settings and `SceneTree.quit_on_go_back` at manager startup. The [Godot 4.7 API documentation](https://docs.godotengine.org/en/4.7/classes/class_scenetree.html#class-scenetree-property-quit-on-go-back) describes the automatic exit behavior.
- Android dispatches only the window Back notification. Desktop Back/Escape is handled before GUI/unhandled gameplay input. Deferred coalescing prevents duplicate deliveries in one frame; transition guards avoid routing through a disappearing scene.
- Delegate to the existing scene/modal handlers. MORROW Back retains the existing Skip/close policy, including viewed-state recording only on that permitted close transition.
- Main Menu displays an exit confirmation; only its explicit Exit Game confirmation calls quit. Back cancels it. Credits closes first.
- Settings and Archive retain the originating scene hidden and disabled, then restore it on return. A paused puzzle keeps its simulation, turn, recordings, active Echoes and pause state. Archive closes a record/replay before returning. Settings also dismisses a reset confirmation before navigating.
- Correct the pause-restart guard's stale `simulation.echo_history` reference to the existing `echoes` collection.

Files: `project.godot`, `scripts/autoload/android_system_manager.gd`, `scripts/autoload/scene_router.gd`, `scripts/ui/main_menu.gd`, `scripts/ui/settings_menu.gd`, `scripts/ui/incident_archive.gd`, `scripts/gameplay/gameplay_controller.gd`.

**Internal Android result: PASS.** Gameplay Back pauses once, another Back resumes; paused move/WAIT input consumes no turn. Hint Back preserves credits. Archive reader Back closes the reader, then returns to the same paused turn-3 puzzle. Settings returns to that same puzzle. Level Select → Difficulty → Main Menu works. Credits closes. Main Menu Back shows confirmation; cancel preserves the process, and explicit Exit Game terminates it. Relaunch preserves progress.

## Defect 2 — Vulkan emulator black output

**Original reproduction:** launch alpha.1 with Vulkan available on host Intel UHD 620 or SwiftShader. Both profiles show persistent black output and Vulkan presentation error 5. Disabling Vulkan in the emulator permits the existing GLES fallback to work.

**Diagnosis:** the captured failure is consistent with [Godot issue #121035](https://github.com/godotengine/godot/issues/121035) and its [Swappy/gfxstream queue-handle fix #121701](https://github.com/godotengine/godot/pull/121701). This is not proof that every physical Vulkan device fails. Shader/background inspection found 2D canvas effects and procedural board/UI drawing that already rendered on the observed GLES fallback; disabling visual effects was unnecessary.

**Correction:** set `rendering/renderer/rendering_method.android="gl_compatibility"`. Desktop retains the existing Mobile setting. Android now selects Compatibility directly; no user renderer switch and no emulator `-feature -Vulkan` workaround is needed. Existing temporal shader, particles, rings, holographic narrative panels, UI colors/glow, Echo trails, plate/door rendering and Archive UI are retained without asset/shader rewrites.

File: `project.godot`.

**Internal Android result: PASS for the selected renderer.** The existing AVD was launched with `-gpu host` and Vulkan available. Logcat identifies OpenGL ES 3 Compatibility directly. Main Menu, MORROW, puzzle, Echo trails, plate/door states, completion effects and Archive render and respond. No Vulkan fallback initialization error or presentation failure occurs on this selected path. A shader-cache recompilation warning was captured; rendering completed afterward.

**Underlying Vulkan issue: NOT FIXED/NOT RETESTED as a Vulkan renderer.** No claim extends to untested hardware or drivers.

## Defect 3 — Replay score accumulation

**Original reproduction:** solve First Contact with a six-action Echo recording and eight-action winning attempt: 14 actions. Choose Replay Attempt and repeat. Alpha.1 reports 28 actions and lowers the displayed star award.

**Cause:** `total_actions_taken` was incremented for every accepted action but reset only by `load_level()`. Restart, Clear Echoes and completed-level Replay did not refund discarded recordings. The replay button used Clear Echoes, so it inherited the previous score. SaveManager also replaced its structured historical record with slower completions despite separately retaining `best_actions`.

**Correction:** `current_attempt_actions` derives from the active recording; `committed_echo_actions` sums committed recordings; `total_actions_taken` derives from their sum. Echo creation transfers rather than duplicates actions. Restart removes only discarded current-attempt actions, retaining committed Echoes. Clear Echoes and completed-level Replay start a zero-score run. No lifetime statistic is introduced. Star calculation receives the actual current solution total. A slower completion no longer replaces the structured best-action record; independent historical best fields and the schema stay compatible.

Files: `scripts/gameplay/puzzle_simulation.gd`, `scripts/autoload/save_manager.gd`.

**Internal Android result: PASS.** A discarded DOWN followed by Restart refunds the action. First completion and identical replay each score 14/three stars. A deliberately slower recording produces a 16-action completion; Level Select and subsequent restart still retain the 14-action best. The regression suite additionally checks 18 → 22 retains 18, then 14 updates it, followed by a save/load round trip.

## Defect 4 — Live resize actor misalignment

**Original reproduction:** in stationary Level 2, resize from 720×1280 to 720×1600. Alpha.1 moves the grid but leaves the player at its previous pixel position until the next move.

**Cause:** `calculate_layout()` changed tile size and board origin, while interpolated actor positions/targets, Echo trail points and the shockwave origin remained cached in the old pixel coordinate space. Walls, plates, doors and exit already used the current grid transform.

**Correction:** recalculate the board transform, remap cached visual points using fractional cell coordinates, and resolve actor targets from the unchanged authoritative simulation positions. Remap trail history and shockwave origin too. Clamp interpolation weight to [0,1], preventing slow frames from overshooting the new endpoint. No puzzle reload, logical move, turn advancement, recording reset or Echo playback reset occurs.

File: `scripts/gameplay/board_renderer.gd`.

**Internal Android result: PASS.** Stationary Level 2 stays aligned immediately after the settled tall resize and after restoration, with turn 00/actions 0 unchanged. Resizing while Level 1's Echo occupies a plate, including with Pause open, preserves the player, Echo, open gate, turn 3 and score 9. Both remain aligned upon resume and restoring the original dimensions. Automated tests cover reduction/enlargement, multiple aspect ratios, mid-interpolation resize, trail transformation, occupied plates, paused state and settling to fresh endpoints without stale positions.

Manual desktop OS-window dragging is NOT TESTED; the shared board transform is covered by headless desktop tests and actual Android live display changes.

## Automated verification

Command: `python3 scripts/tools/run_alpha_tests.py` (isolated XDG data/config for every suite).

- New `tests/regression/test_alpha2_fixes.gd` / `.tscn`: **86 checks**, covering centralized Back, modal/menu hierarchy, confirmation cancellation, retained navigation state, renderer configuration/effect retention, solution/replay accounting, historical records and live-layout/interpolation invariants.
- All ten canonical campaign solutions remain solvable with their existing WAIT budgets and three-star targets.
- Existing door/expiry/WAIT, core simulation, validation, integration, mobile layout, UI, narrative, hint, save/migration, completion and background suites are retained.
- Release-helper tests include rejection of any certificate differing from alpha.1, including verification without provenance.

During the November 11 rerun, two existing fixtures assumed November 10 rather than controlling the clock. Real daily rollover invalidated their expected allowance. Their tests now set the existing injected clock and use a separate hint-fixture save path; constructor/default-save loading cannot reset the fixture before the injected-clock load. Production hint logic was not changed. Intermediate failed/aborted logs are retained and are not presented as successful runs.

Final result: **19/19 suites PASS**, every suite exit code 0 and no GDScript errors. This includes **86 targeted checks**, **282 WAIT optimization checks**, **3,187 turn/WAIT checks**, **10/10 campaign solutions**, **20/20 hint tests** and **15 release-helper tests**. Record: `build/android/releases/test-results.json`; a durable copy and per-suite logs are retained in the external QA directory.

Files for tests/release preparation: `tests/regression/test_alpha2_fixes.gd`, `.tscn` and generated UID; `tests/hints/test_hint_system.gd`; `tests/narrative/test_save_scenarios_and_triggers.gd`; `tests/release/test_android_alpha_release.py`; `scripts/tools/run_alpha_tests.py`; `scripts/tools/android_alpha_release.py`; `export_presets.cfg`; `CHANGELOG.md`; `docs/ANDROID_RELEASE_GUIDE.md`; `docs/releases/0.1.0-alpha.2.md`; this report and the updated QA report.

## Actual Android runtime coverage

Reused `TomorrowsYou_Alpha_QA`: Android 15/API 35 AOSP x86_64 revision 2; emulator 37.2.13; KVM version 12 usable; Pixel 2-derived 720×1280/density-240 profile, two vCPUs and actual 2,560 MiB RAM. Graphics: host Intel UHD 620 through the Android emulator translator, Vulkan available to the guest, game explicitly using OpenGL Compatibility. ADB always targeted dedicated port 5038 / serial `emulator-5580` after checking the AVD identity.

| Check | Internal APK result | Evidence under `alpha2/evidence/` |
|---|---|---|
| Install and first visible launch | PASS | Internal install returned Success; `02_main_menu_settled.png`; signature/badging logs outside evidence subdirectory |
| Main Menu, Difficulty and Level Select | PASS | `02`, `07`–`10`, `40`, `66` |
| Android Back and explicit exit | PASS | `03`–`06`, `12`–`15`, `18`–`26`, `67`–`69`, `explicit-exit.txt` |
| Movement, restart and scoring | PASS | `20`, `27`, `36`–`40` |
| Echo creation, playback, expiry | PASS | `29`–`35`; turn 6 gate entry, turn 7 expiry/closure |
| Door visual/logical agreement | PASS | `33`–`35`; closed-door LEFT rejects without turn/action change |
| WAIT allowances | PASS for Levels 1–2 | Level 1 budget 3 and Level 2 budget 2; exhausted touch/Space rejects; committed Echo keeps spent budget; `28`, `41`, `47` |
| MORROW and Archive | PASS for exercised content | `11`–`12`, `22`–`25`, archive replay/Next/Back captures `70`–`73` |
| Daily hint and free reread | PASS for exercised reveal/reread | `18`–`19`, `42`, `64`; 3 → 2, Back does not charge; disclosed hint remains available |
| Completion and historical best | PASS for Levels 1–2 | `36`, `38`–`40`, `66`; both levels retain 14-action/three-star records |
| Save persistence/restart | PASS for exercised data | `64`–`66`, `69`; completed progress, best records and hint disclosure survive restart/explicit exit |
| Background/foreground | PASS | `62`–`63`: same turn-1 puzzle returns paused |
| Offline gameplay | PASS for exercised flows | Airplane mode on, Wi-Fi/data off, active default network none; `offline-state.txt`; both solves, hints, archive and restarts work |
| Portrait live layout | PASS for puzzle cases verified after settling | `29`–`32` for active Echo/plate and Pause; `59`–`61` for stationary Level 2 |
| Crashes/script errors | None found in captured app session | `final-app-logcat.txt`; empty `final-crash-buffer.txt` |

Evidence includes unsuccessful capture attempts and navigation transitions. In particular, `16` is a startup frame before shader compilation settled; `17` is the visible menu. Captures `43`–`46` include display-transition frames. Captures `48`–`58` navigated away from completion into menus, so their filenames do not establish stationary-puzzle resize or background-state passes; the later `59`–`66` captures provide those checks. Filename wording alone is not used as proof.

Screenshots and raw logs: `/home/wakkadu/.local/share/tomorrows-you-qa/alpha2/`. Internal staging project: `/run/media/wakkadu/4C1A86B21A86989A/TomorrowsYou-Alpha-QA/alpha2-internal-project/`. No test artifact is bundled into a release APK. The original alpha.1 draft and checksum remain unchanged.

## Remaining requirements and release decision

**PASS:** four fixes in the internal Android profile; solution/state regression coverage; ten campaign source solutions; original gameplay/story/WAIT data preserved; schema-compatible save behavior.

**NOT TESTED:** final same-key signed alpha.2 APK, real alpha.1 → alpha.2 signed upgrade, physical phones/ARM ABIs, Android versions other than 15/API 35, audible audio/haptics, notches/gesture navigation, performance endurance, complete ten-level Android playthrough and all narrative/archive content. No broad device or Android-version compatibility claim is made. Existing movement-loop WAIT alternatives and Nightmare's two-Echo shortcut remain known balance limitations.

**BLOCKED pending developer action:** obtaining the final release signature through the local private-password prompt after committing the approved fixes. No release password should enter chat. A final source commit, release certificate verification, non-debuggable check, production package check, file size and SHA-256 must be recorded for the actual signed candidate, then its Android runtime checks must pass.

**FAIL:** no reproduced failure remains in the four exercised internal remediation scenarios. The underlying emulator Vulkan-renderer failure has not been claimed fixed; the selected production Android renderer avoids it.

Version `0.1.0-alpha.2` / code 5 and release notes/helper are prepared. Do not label alpha.2 ready, tag it or create its separate draft until the signed candidate passes. The developer approved the reviewed commit and conditional push/tag/separate draft preparation on November 11, 2026. Remote actions remain conditional on successful final signed-artifact QA. No asset replacement or public publication is authorized. The permanent key, package ID, save schema, phone installation and website are preserved.

The dedicated emulator and QA ADB server were stopped after evidence collection. The AVD and both app installations are retained; the display override is reset to 720×1280 and airplane mode remains enabled.
