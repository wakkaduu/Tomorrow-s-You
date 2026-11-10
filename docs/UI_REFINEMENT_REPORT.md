# UI refinement audit and development report

## Repository findings

Verified on November 10, 2026: clean initial `main`, origin
`git@github.com:wakkaduu/Tomorrow-s-You.git`, Godot
`4.7.2.stable.official.ed1daf0bf`. Android export preset targets
`build/android/TomorrowsYou-debug.apk`; project uses a 720 × 1280 portrait
canvas with expanded aspect scaling and the mobile renderer.

Five autoloads already coordinate persistence, procedural audio, campaign/simulation,
scene routing, and Android safe areas/back navigation/haptics. GameplayController
binds a separate deterministic PuzzleSimulation to BoardRenderer and scene controls.
EchoRecording preserves accepted positions and WAIT actions. Echoes occupy their
final recorded turn and expire on the following turn; this boundary is covered by
the master suite. No simulation or save rules were changed.

SaveManager schema 3 already migrates progression and stores scores, hints,
narrative state and settings. NarrativeRegistry, IncidentArchive and MorrowVisualizer
already implement the story registry, reader, replay and cinematic transmissions.
The story bible confirms Mount Caelum and Directive 88-F, but uses older chamber
names in its facility diagram. Runtime level definitions remain authoritative.

The handoff understates existing UI work: semantic button styling, heading/body/mono
helpers and 37 canonical SVG icons already exist. Oxanium, Inter and IBM Plex Mono
are bundled with OFL licenses and configured for offline loading. Legacy icon
copies exist in `assets/icons/ui`; their resource paths were retained for compatibility.
Most UI is constructed by screen controllers around `.tscn` containers; archive
cards are generated dynamically. Shared refinements therefore require no scene
or game rewrite.

## Implemented changes and files

- `assets/ui/icons/*.svg`: standardized main strokes to 1.8 units on the existing
  24-unit grid. Replaced the Create Echo symbol with an original split-orbit
  operator/Echo emblem. Preserved existing navigation/story/progress concepts.
- `scripts/ui/components/ui_design_system.gd`: larger text tokens, Inter primary
  button text, subdued resting borders, reduced primary glow, capped 24-unit icons,
  consistent icon/text spacing, minimum touch dimensions and icon-button tooltips.
  Existing reusable button helpers remain the single implementation used by menus,
  gameplay and the archive; no duplicate component hierarchy was introduced.
- `assets/themes/default_theme.tres`: increased default body and button type sizes
  for controls that inherit the shared theme.
- `scripts/gameplay/gameplay_controller.gd`: clearer Create Echo/Wait labels,
  larger HUD statistics and dialogue, text-only Next/Continue labels alongside
  vector icons. Directional pad, semantic actions and atmospheric backgrounds persist.
- `scripts/ui/incident_archive.gd`: readable wrapped headings/metadata, research
  classification, numbered locked transmissions, quieter research actions, one
  View Transmission action per transmission card with replay in the reader, larger
  reader body type, and fixed invalid timeline Label API call.
- `tests/core/test_ui_and_screens.gd`: defer loading singleton-dependent scripts
  until autoload initialization; mount the audio manager before exercising playback.
  Previously this suite reported compile errors and failed its audio check.
- `tests/ui/test_design_system.gd`: real scene/container integration coverage for
  all five requested portrait resolutions, all four unlocked archive tabs and
  reader-to-replay interaction. Checks transmissions do not advance the simulation.
- `README.md`: corrected obsolete permanent Echo occupancy claim.
- `ASSET_LICENSES.md`: documented SVG provenance and bundled OFL fonts.

## Validation

All test processes used separate temporary XDG_DATA_HOME directories so reset and
migration tests could not touch the player's normal `user://save.cfg`. Logs for this
run are under `/tmp/tomorrow-ui-ifp2odo4/` (temporary, not project artifacts).

| Suite | Result |
| --- | --- |
| Master mechanics, 10 campaign solutions, minimum Echo validation, hints | 38/38 |
| Mounted full integration | 11/11 |
| Android mobile systems | 50/50 |
| Narrative registry/archive/persistence | 10/10 |
| Narrative save scenarios/triggers | 4/4 |
| Opening transmission flow | Exit 0 |
| Daily hints | 20/20 |
| UI scenes, save roundtrip and audio | 7/7 |
| Board responsiveness | 36/36 |
| Temporal backgrounds | 8/8 |
| New UI integration at 360×640, 360×800, 390×844, 412×915, 432×960 | 105/105 |

All 37 canonical SVGs also passed XML checks for the shared viewbox and main stroke;
`git diff --check` passed.

Headless geometry checks exercise the portrait canvas scaling and actual containers;
they do not prove rendered font appearance, perceived touch comfort or device behavior.
Some existing suites report ObjectDB cleanup warnings; the standalone responsiveness
suite also queries absolute scene paths from detached BoardRenderer instances.
The editor import completed but attempted unavailable sandbox ADB/socket/editor-settings
operations; asset imports and runtime suites completed. No Android build, rendered
screenshot review or physical-phone test is claimed.

## Remaining work

Review rendered screens and button states on Android, especially text size and
physical touch targets at 360-pixel width. The 48 logical-unit minimum and 74-unit
D-pad are preserved; logical canvas units are not Android density-independent pixels.
Check safe-area cutouts and long narrative content on a real phone. Resolve test
shutdown warnings separately and update the story bible's older chamber naming.
Legacy icon copies remain technical debt, intentionally not deleted in this pass.

Suggested commit: `Refine shared mobile UI, temporal icons and archive readability`
