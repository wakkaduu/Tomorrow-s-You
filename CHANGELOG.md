# Changelog — Tomorrow's You

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-11-09

### Added
- Core grid-based puzzle engine with discrete turn management.
- Deterministic Echo recording & playback system:
  - Turn-synchronized playback of historical attempts.
  - Final position holding (Echoes hold pressure plates indefinitely).
  - Safety rules: Non-blocking collision for echoes, exit reachable only by real player.
  - Door logic: AND and OR conditions, player crushing prevention safety rule.
- 10 handcrafted campaign levels across 3 sectors:
  - Sector 1: Awakening (Levels 1–3) — Movement, plate basics, echo twins.
  - Sector 2: Synchronization (Levels 4–7) — Dual locks, relay doors, wait timing, logic divergence.
  - Sector 3: Paradox (Levels 8–10) — Triad echo coordination, interlocks, grand finale.
- Automated headless test suite with 20+ comprehensive mechanic tests and full campaign solver validation.
- Procedural audio synthesizer generating retro-futuristic SFX and ambient synth background loop.
- Full mobile UI:
  - On-screen touch D-Pad and swipe gesture controls.
  - Action buttons: WAIT, CREATE ECHO, RESTART, CLEAR ECHOES.
  - Responsive layout for portrait orientation (720x1280 base).
  - Main menu, Level Select, Pause menu, Settings screen, Level Complete screen.
- Local persistence (`user://save.cfg`) storing unlocked levels, best turn records, and audio/accessibility preferences.
- Android export preset configuration.

