# Changelog — Tomorrow's You

All notable changes to this project will be documented in this file.

## [1.3.0] - 2026-11-09

### Added
- **Temporal Research Facility Visual Atmosphere Overhaul**:
  - Reusable 5-layer procedural environmental background system (`scenes/background/temporal_background.tscn`):
    - Layer 1 (Base Environment): Deep vertical gradient (`#0B1020` to `#141C2E`) with radial atmospheric glow and dither.
    - Layer 2 (Architecture Silhouettes): Distant laboratory walls, structural pillars, suspended catwalks, and floor perspective grid.
    - Layer 3 (Atmospheric Lighting): Downward volumetric light cones radiating from central temporal aperture with breathing fog drift.
    - Layer 4 (Particle Simulation): Floating dust motes and energetic sparks with zero-allocation wrap-around physics.
    - Layer 5 (Temporal Effects): Concentric rotating time rings with cardinal ticks and faint wireframe Echo silhouettes.
  - Screen-specific atmospheric presets for Main Menu, Credits, Level Select, Settings, Gameplay, Pause, and Level Complete.
  - Dynamic difficulty tier environmental progression (calm cyan Initiation through volatile crimson Nightmare).
  - Floating holographic glass modals for Pause, Hint Assistance, and Level Complete with glowing borders and drop shadows.
  - Full accessibility integration with `SaveManager.reduced_animations` (pauses particle velocity and stabilizes glow).
  - Dedicated visual background test suite (`tests/visual/test_temporal_background.tscn`) and 10 in-engine 720×1280 screen captures.

## [1.2.1] - 2026-11-09

### Fixed
- **Level Completion Modal & Progression Lockup**:
  - Resolved fatal runtime script crash where missing `GameManager.get_next_level_def()` prevented `GameplayController._on_level_completed()` from displaying the Level Complete modal.
  - Implemented lookahead door evaluation via `is_door_open_at_turn(door_id, turn)` so door state changes coinciding with turns never incorrectly block legal moves.
  - Preserved actor safety: doors closing behind players never crush or retroactively invalidate legal movement.
  - Centralized level completion state transitions in `GameplayController` with `_level_completed_handled` guarding against duplicate completion recordings.
  - Added formal `GameState` enum (`PLAYING`, `PAUSED`, `COMPLETED`, `FAILED`) in `PuzzleSimulation`.
  - Added structured real-time diagnostic logging (`[TURN]`, `[PLAYER]`, `[EXIT]`, `[ECHO]`, `[LEVEL]`, `[SAVE]`, `[SCENE]`).
  - Added 12-case regression test harness (`tests/core/test_level_completion.gd` & `.tscn`) covering all exit reach and door expiration timing interactions with 100% pass rate.

## [1.2.0] - 2026-11-09

### Added
- **Daily-Limited Hint System**:
  - Global daily allowance of 3 hint credits (`DAILY_HINT_LIMIT = 3`) shared across all levels and difficulties.
  - 3-stage progressive disclosure per level:
    - Stage 0 (Observation): Focused environmental nudges and plate/door relationships.
    - Stage 1 (Strategy): Echo role assignments, chamber routing, and WAIT timing.
    - Stage 2 (Solution): Deterministic, verified step-by-step action sequences.
  - Local midnight reset via `Time.get_date_string_from_system(false)` with zero external dependencies.
  - Clock rollback protection detecting system date manipulation to block illegitimate allowance replenishment.
  - Test clock injection API (`SaveManager.set_test_date()`, `clear_test_date()`) for automated testing.
  - Mobile-first Gameplay HUD integration: `💡 HINT · X LEFT` button ($\ge 48\text{dp}$ touch target).
  - Hint Modal with scrollable previously revealed list (permanently free to re-read) and Confirmation Modal dialog.
  - Gameplay input and Echo playback freeze while hint modals are open, preventing turn advancement.
  - Dedicated automated test suite: `tests/hints/test_hint_system.gd` with 20 verified test cases.
- **Difficulty Tiers System**:
  - 5 distinct difficulty tiers: Easy (Initiation), Normal (Synchronization), Hard (Convergence), Expert (Paradox), Nightmare (The Last Tomorrow).
  - Dedicated Difficulty Selection screen (`scenes/menus/difficulty_select.tscn`) with interactive cards, tier stats, and star counters.
  - Progressive tier unlocking requiring 100% verified completion of previous tiers.
  - 3-star rating threshold system with optimal action targets.
- **Echo Lifecycle & Expiration Rules**:
  - Fixed-duration Echoes: Echoes expire immediately when their recording ends and stop activating plates/doors.
  - Explicit `WAIT` turn recording: allows players to intentionally extend Echo lifespan on pressure plates.
  - Sequence Lock security logic (`logic: "SEQUENCE"`) requiring exact plate activation sequences.
- **Save System v2 & Legacy Invalidation**:
  - Save schema migration to v2; automatically invalidates sub-minimum / legacy completions.
  - Master test suite expanded to 38 automated tests (100% passing) and in-engine integration suite to 9 tests.

## [1.1.0] - 2026-11-09

### Changed
- **Critical Gameplay Correction**:
  - Eliminated 100% of zero-echo bypass routes across all 10 campaign levels.
  - Redesigned puzzle layouts into sealed chamber topologies where doors function as true chokepoints.
  - Enforced minimum Echo cooperation:
    - Sector 1 (Levels 1–3): Minimum 1 Echo required.
    - Sector 2 (Levels 4–7): Minimum 2 Echoes required.
    - Sector 3 (Levels 8–10): Minimum 3 Echoes required.
  - Re-anchored pressure plates at least 2 tiles from doors to prevent single-turn crossing bypasses.
- **UI/UX Overhaul**:
  - Redesigned portrait gameplay HUD with prominent level & sector headers and styled stat pills (`⏱ TURN: 00`, `✦ ECHOES: 0 / 1`).
  - Added visual distinctions: 3D beveled metallic wall blocks, glowing animated amber pressure plates, heavy door jambs with red laser barrier beams and condition badges, spinning exit vortex, and holographic scanlines & fading trails for Echoes.
  - Increased touch control ergonomics: 72×72px D-pad buttons (>48dp), centered tactile `WAIT TURN` button, prominent violet `+ CREATE ECHO` button.
  - Optimized responsive board layout calculations across 360×640, 720×1280, and 1080×2400 viewports without clipping.

### Added
- **Automated Level Validator Engine (`LevelValidator`)**:
  - State-space BFS search simulating zero-echo player traversal to verify no level can be solved without Echoes.
  - Sub-minimum Echo combinatorial testing ensuring $< K$ Echoes cannot bypass security doors.
  - Replay verification confirming 100% solvability with exact configured minimum Echoes.
- **Developer Inspection Mode**:
  - Desktop debug mode toggled via `F12` or `~` in debug builds.
  - Renders live door-to-plate connection lines (`1➔A`, `2➔B`) and spawn/exit markers on the game board.
  - On-screen inspection overlay panel displaying level properties, door conditions, and an instant "RUN LEVEL VALIDATOR" action.
- **Vector Application Icon**:
  - Created `icon.svg` featuring cyan and violet temporal twin rings with glowing amber chrono core.
- **Automated Validation Test Suites**:
  - `tests/core/test_level_validation.gd`: Automated BFS zero-echo bypass elimination & minimum Echo verification.
  - `tests/core/test_responsiveness.gd`: Automated multi-resolution layout verification (360×640, 720×1280, 1080×2400).
  - Extended master test suite to 32 tests (100% passing). Total project assertions: 107 / 107 passing.

## [1.0.0] - 2026-11-09

### Added
- Core grid-based puzzle engine with discrete turn management.
- Deterministic Echo recording & playback system:
  - Turn-synchronized playback of historical attempts.
  - Final position holding (Echoes hold pressure plates indefinitely).
  - Safety rules: Non-blocking collision for echoes, exit reachable only by real player.
  - Door logic: AND and OR conditions, player crushing prevention safety rule.
- 10 handcrafted campaign levels across 3 sectors.
- Automated headless test suite with comprehensive mechanic tests and full campaign solver validation.
- Procedural audio synthesizer generating retro-futuristic SFX and ambient synth background loop.
- Full mobile UI:
  - On-screen touch D-Pad and swipe gesture controls.
  - Action buttons: WAIT, CREATE ECHO, RESTART, CLEAR ECHOES.
  - Responsive layout for portrait orientation (720x1280 base).
  - Main menu, Level Select, Pause menu, Settings screen, Level Complete screen.
- Local persistence (`user://save.cfg`) storing unlocked levels, best turn records, and audio/accessibility preferences.
- Android export preset configuration.
