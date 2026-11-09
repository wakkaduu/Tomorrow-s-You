# Changelog — Tomorrow's You

All notable changes to this project will be documented in this file.

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
