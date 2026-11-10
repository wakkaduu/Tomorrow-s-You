# TOMORROW'S YOU

> *"Every failed attempt becomes your teammate."*

**TOMORROW'S YOU** is a 2D top-down mobile puzzle game developed with Godot Engine 4.7.2. You are trapped inside a mysterious temporal research facility where time behaves differently: every previous attempt can become a holographic Echo that replays your exact movements synchronously, helping you activate pressure plates, open logic doors, and navigate intricate paradoxes.

---

## Features

- **Unique Temporal Echo Mechanic**: Save your current attempt as an Echo. On each new attempt, previous Echoes replay their movements step-by-step alongside you.
- **Deterministic Historical Playback**: Echoes follow their recorded positions through the final recorded turn, then expire before the next playback turn.
- **10 Handcrafted Campaign Levels**:
  - **Sector 1 — Awakening**: Core movement and your first temporal teammate.
  - **Sector 2 — Synchronization**: AND-doors, relay doors, and strategic WAIT timing.
  - **Sector 3 — Paradox**: Complex 3-Echo puzzles, interlocking doors, and multi-stage solutions.
- **5 Difficulty Tiers**:
  - **Initiation (Easy)**: Single-Echo mechanics and temporal fundamentals.
  - **Synchronization (Normal)**: Dual-timeline coordination and AND-logic doors.
  - **Convergence (Hard)**: Staggered lifecycles and strict duration limits.
  - **Paradox (Expert)**: Multi-timeline planning and triple-Echo relays.
  - **The Last Tomorrow (Nightmare)**: 4-Quadrant facility with precision Sequence Lock.
- **Fixed-Duration Echo Lifecycle**: Echoes exist strictly for the duration of their recorded sequence and expire upon completion, preventing indefinite holding of pressure plates.
- **Atmospheric Visual Engine ("Temporal Research Facility")**:
  - Multi-layer procedural sci-fi background with facility silhouettes, reactive particles, and custom GLSL chromatic/vignette shader.
  - Distinct theme palettes per difficulty tier and floating holographic glass modals.
- **Mobile-First Android Architecture**:
  - Portrait locked with automatic notch/cutout safe-area insets via `DisplayServer.get_display_safe_area()`.
  - Comprehensive hardware back-button routing (`AndroidSystemManager`).
  - Tactile haptic feedback engine (`Input.vibrate_handheld()`) mapped to movement, Echo creation, plates, doors, and completions.
  - Dynamic responsive board renderer tested across 7 mobile resolutions (`360×640` to `1080×2400`).
  - High-touch-target 72×72px D-Pad, full-width `CREATE ECHO` button, and constrained board swipe gestures.
- **Offline & Privacy-Respecting**: Zero ads, zero trackers, zero cloud dependencies. Local progress saving via `user://save.cfg`.
- **Fair Daily Hint System**: 3 free hints per calendar day shared across all levels, resetting at midnight with clock rollback protection and zero microtransactions.

---

## Daily Hint System

TOMORROW'S YOU includes an offline-first, fair, daily-limited hint system designed to assist players while preserving puzzle challenge and satisfaction.

### 1. Global Daily Allowance Mechanics
- **Allowance**: 3 hint credits per local calendar day (`DAILY_HINT_LIMIT = 3`).
- **Game-Wide Pool**: The allowance is shared globally across every campaign level and difficulty tier (not 3 per level).
- **Free Re-reading**: Once a hint stage is unlocked for a level, it is permanently free to revisit anytime and never consumes future credits.
- **No Monetization**: No advertising, no subscriptions, no in-app purchases, and no paid replenishment.

### 2. Progressive 3-Stage Disclosure
Each campaign level features 3 handcrafted, solution-verified hint tiers:
1. **Stage 0 — Observation**: Focuses player attention on critical puzzle elements (e.g., pressure plate colors, door linkages, dead-end traps).
2. **Stage 1 — Strategy**: Outlines the strategic coordination plan, Echo roles, chamber sequence, and required WAIT timing.
3. **Stage 2 — Solution**: Provides the exact, deterministic, step-by-step verified action sequences for each Echo and the final player run.

### 3. Midnight Reset & Clock Rollback Protection
- **Midnight Reset**: The allowance automatically refreshes to 3 credits at 00:00 local device time using `Time.get_date_string_from_system(false)`.
- **Trigger Points**: Checked at boot, when resuming from background (`NOTIFICATION_APPLICATION_RESUMED` / `NOTIFICATION_WM_WINDOW_FOCUS_IN`), and immediately before any hint is consumed.
- **Rollback Protection**: If the system date is detected to be earlier than the last recorded reset date (`curr_date < last_reset_date`), the game detects clock manipulation, retains the consumed state, and blocks premature allowance replenishment.

### 4. Test Clock Injection API (QA & Testing)
For automated testing and QA verification without altering the host OS clock, `SaveManager` provides an injectable test date provider:
```gdscript
# Fast-forward to next calendar day for testing
SaveManager.set_test_date("2026-11-10", 1762732800)

# Query remaining hints under test date
var rem: int = SaveManager.get_remaining_daily_hints() # Returns 3

# Clear override to resume real system clock
SaveManager.clear_test_date()
```

### 5. Hint Registry Architecture & Authoring New Hints
Hint definitions are decoupled from UI logic in `scripts/hints/`:
- `HintDefinition` (`scripts/hints/hint_definition.gd`): Resource data container holding `level_id` and three validated hint dictionaries (`stage`, `title`, `text`).
- `HintRegistry` (`scripts/hints/hint_registry.gd`): Master registry providing `get_hints_for_level(id)`, `get_hint_stage(id, stage)`, and `validate_all_hints()`.

To register hints for a new level:
```gdscript
# In HintRegistry:
static func _create_lvl_custom_hints() -> HintDefinitionClass:
    var def = HintDefinitionClass.new("lvl_custom")
    def.hints = [
        {"stage": 0, "title": "Observation", "text": "Observe which door opens..."},
        {"stage": 1, "title": "Strategy", "text": "Create an Echo that waits on plate A..."},
        {"stage": 2, "title": "Solution", "text": "Echo 1: R, R, WAIT. Player: D, R, EXIT."}
    ]
    return def
```

---

## Automated Test Suites

The project includes exhaustive automated test suites that run in headless Godot (129/129 passing):

```bash
# 1. Android Mobile System Suite (50 tests: Safe Area, Haptics, Back Navigation, 7 Aspect Ratios, Swipes)
godot --headless tests/mobile/test_mobile_system.tscn

# 2. In-Engine Full Integration Suite (11 tests with mounted Autoloads, UI, audio, and gameplay)
godot --headless tests/test_runner.tscn

# 3. Master Comprehensive Test Suite (38 tests: Core Mechanics + Campaign Solutions + Topology Enforcement + Hint System)
godot --headless -s tests/run_all_tests.gd

# 4. Dedicated Daily Hint System Suite (20 tests covering allowance, reset, persistence, modals, rollback)
godot --headless -s tests/hints/test_hint_system.gd

# 5. Campaign 10-Level Validation & Physical Solvability Suite
godot --headless -s tests/levels/test_campaign_solutions.gd

# 6. Temporal Background System Suite (8 tests for shader uniforms, layers, input passthrough)
godot --headless tests/visual/test_temporal_background.tscn
```

---

## Controls

### Mobile (Touch)
- **D-Pad / Swipe**: Move Up / Down / Left / Right.
- **WAIT**: Advance one turn without moving.
- **CREATE ECHO**: Store current attempt as a teammate and restart from spawn.
- **RESTART**: Reset current attempt without creating an Echo.
- **CLEAR ECHOES**: Clear all Echoes and start fresh.

### Shared WAIT allowance
Each level has a finite `max_wait_actions` budget shared by all committed Echo
recordings and the current attempt. Echo playback never spends it again. The WAIT
button shows the remaining allowance; exhausted requests do not advance time.
Restart Attempt refunds only the discarded current recording. Clear Echoes resets
the full puzzle allowance. The stationary Interact shortcut also uses WAIT validation.

Campaign allowances are verified minima within the intended shortest-route domain;
movement timing detours remain legal. See [WAIT balancing report](docs/WAIT_BALANCING_REPORT.md)
for proofs, limits, and the known Nightmare two-Echo sequence-latch route.

Doors display their resolved state immediately. Door entry retains the simultaneous
turn rule: it uses the Echo positions on the proposed next turn. An amber cross and
`NEXT: SHUT` warn when an open door will block that next move.

### Desktop
| Action | Keybinding |
|---|---|
| Move Up | W / Up Arrow |
| Move Down | S / Down Arrow |
| Move Left | A / Left Arrow |
| Move Right | D / Right Arrow |
| Wait | Space |
| Interact | E |
| Create Echo | Enter |
| Restart Attempt | R |
| Pause Menu | Escape |

---

## Building and Running

### Prerequisites
- [Godot Engine 4.7.2 Stable](https://godotengine.org)

### Running on Desktop
```bash
# Launch the game directly
godot --path .

# Or run in headless test mode
godot --headless --path . -s tests/run_all_tests.gd
```

### Android Build & Export
1. Ensure OpenJDK 17 and Android SDK (Platform 34, Build-tools) are installed.
2. In Godot, set Android SDK path and Java path in Editor Settings.
3. Export using the configured preset:
```bash
godot --headless --export-debug "Android" build/android/TomorrowsYou-debug.apk
```

---

## License
MIT License. See [ASSET_LICENSES.md](ASSET_LICENSES.md) for asset details.

