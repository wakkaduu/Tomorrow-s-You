# TOMORROW'S YOU

> *"Every failed attempt becomes your teammate."*

**TOMORROW'S YOU** is a 2D top-down mobile puzzle game developed with Godot Engine 4.7.2. You are trapped inside a mysterious temporal research facility where time behaves differently: every previous attempt can become a holographic Echo that replays your exact movements synchronously, helping you activate pressure plates, open logic doors, and navigate intricate paradoxes.

---

## Features

- **Unique Temporal Echo Mechanic**: Save your current attempt as an Echo. On each new attempt, previous Echoes replay their movements step-by-step alongside you.
- **Deterministic Historical Playback**: Echoes follow their recorded positions and remain at their final destination to hold pressure plates.
- **10 Handcrafted Campaign Levels**:
  - **Sector 1 — Awakening**: Core movement and your first temporal teammate.
  - **Sector 2 — Synchronization**: AND-doors, relay doors, and strategic WAIT timing.
  - **Sector 3 — Paradox**: Complex 3-Echo puzzles, interlocking doors, and multi-stage solutions.
- **Mobile-First Experience**:
  - Portrait orientation (720×1280 base viewport).
  - High-touch-target on-screen D-Pad and swipe gestures.
  - Desktop keyboard controls for testing.
- **Offline & Privacy-Respecting**: Zero ads, zero trackers, zero cloud dependencies. Local progress saving via `user://save.cfg`.
- **Procedural Audiovisuals**: Neon cyberpunk holographic art style with synthesized sound effects and ambient music.

---

## Controls

### Mobile (Touch)
- **D-Pad / Swipe**: Move Up / Down / Left / Right.
- **WAIT**: Advance one turn without moving.
- **CREATE ECHO**: Store current attempt as a teammate and restart from spawn.
- **RESTART**: Reset current attempt without creating an Echo.
- **CLEAR ECHOES**: Clear all Echoes and start fresh.

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

