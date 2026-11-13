# Android alpha release QA

## Local re-validation of the signed alpha.2 APK — November 13, 2026

**Result: PASS on the tested profile (Android 15 x86_64 emulator, host-GPU OpenGL ES). Physical-device and Vulkan-on-hardware behaviour remain untested.** This section repeats the alpha.2 runtime checks on a freshly built AVD, because the earlier AVD lived on a drive that is no longer present. It supplements the Nov 11 section below; it does not replace it.

| Item | Value |
|---|---|
| APK | `TomorrowsYou-v0.1.0-alpha.2-android.apk`, SHA-256 `a39c2fd89c4c57b23c8d644f0c762cbbc5dbdb6194358aa472d7f40a8c4dafc9` (checked against the GitHub draft download and before `adb install`) |
| Source | Tag `v0.1.0-alpha.2` → `10956640`. HEAD `ab8e982` differs only in docs/CHANGELOG. Package `com.tomorrowsyou.game`, 0.1.0-alpha.2 (5), release certificate `43f8a0c0…38f0db` |
| Emulator | New AVD `TomorrowsYou_Alpha_QA_Local`, emulator 37.2.13, official `system-images;android-35;default;x86_64` (r02, installed with sdkmanager), Pixel 2 profile, 720×1280 / 240 dpi, 2,560 MiB RAM, 2 cores, KVM, `-gpu host -feature -Vulkan`, serial `emulator-5580`, isolated ADB server on port 5038 |
| Location | `/mnt/ubuntu-data/Android-QA/` (sdk, avd, home, evidence). The old AVD/QA data were not modified. No physical phone was targeted. |
| Data | Fresh install, so the real player save and the phone's debug build were never touched. Airplane mode, Wi-Fi and mobile data were off for the whole session after the first launch; all gameplay and archive checks ran offline. |

### Results (screenshots in `/mnt/ubuntu-data/Android-QA/evidence/`)

| Check | Result | Evidence |
|---|---|---|
| Launch, Compatibility/OpenGL rendering, MORROW transmissions, effects | PASS — menu, gameplay, intro/outro transmissions and background effects render; no GL errors in logcat | `03`, `04`, `05` |
| Android Back — gameplay → Pause → Resume; Hint panel; Archive reader → Archive → previous screen; Level Select → Difficulty → Main Menu → exit confirmation; Stay | PASS — process ID unchanged throughout, no turn/credit change (Hint still 3/3) | `19`–`22`, `A1`–`A7`, `B1`–`B4`, `C1` |
| Replay scoring | PASS — Level 1 first run 14 actions / 3★; after Replay Attempt the counter restarts at 0 and the identical route again gives 14 / 3★ (previously 28 / 1★). Level Select still shows record 14. | `14`, `15`, `23`, `B1` |
| Live resize with active Echo | PASS — 720×1600 and 480×800 overrides at turn 3: player, Echo, plate and open door stay grid-aligned, turn/recording unchanged; reset restores layout | `16`–`18` |
| Echo recording/expiry, door sync, WAIT budgets | PASS (Level 1) — Echo holds plate, door opens for the player, Echo expires and door closes behind; WAIT disables at 0 left | `07`–`12` |
| Save persistence, offline, background/foreground | PASS — Home then relaunch keeps the process; force-stop then relaunch shows Continue Journey, 30/30 stars, Archive 31/31 | `C2`, `C3` |
| Hint panel / Archive | PASS — hint opens/closes without charge; Archive reader opens, replays text, closes via Back | `21`, `A5`–`A7` |

### Campaign coverage (each solution is from `campaign_solutions.gd`, executed by touch on the emulator)

| Level | Loaded | Interacted | Completed |
|---|---|---|---|
| 1–10 | Yes | Yes | Yes — all ten completed with their canonical solutions, each 3★. Final report shows 30/30 stars, 283 total actions, 20 Echoes. Evidence: `L<n>_a`–`L<n>_e`. |

Only the canonical route was run per level; alternative routes, failure paths, hint use beyond Level 1, and the slower-replay "best preserved" case were not repeated here (that case passed in the Nov 11 signed-APK QA). The game ran all ten levels in one process with no crash.

### Findings and remaining issues

- **Software renderer fails (new observation, not a regression):** with `-gpu swiftshader_indirect` (GL_MAX_FRAGMENT_UNIFORM_VECTORS = 261) the app shows a blank dark screen. Logcat shows Godot's built-in `SceneShaderGLES3`/`CanvasShaderGLES3` link errors ("active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS"). The project's own shader has only 11 small uniforms, so the limit is hit by engine shaders. Risk assessment: a compatibility risk on low-limit GPUs, not evidence of failure on ordinary phones (the host-GPU run was clean). Needs real-device reports. Log: `swiftshader-indirect-logcat.txt`.
- **ObjectDB leak at exit (headless tests):** 4 instances, all `AudioStreamWAV`/`AudioStreamPlaybackWAV`, fixed count at shutdown. It does not grow during play, so it is not a long-running-gameplay leak; low priority.
- A shader-cache "Failed to load cached shader, recompiling" warning appears on first launch. No `FATAL EXCEPTION`, ANR or native crash in `full-logcat.txt`.
- **Not tested:** physical devices, ARM, other Android versions, real-hardware Vulkan, audio/haptics, gesture navigation, endurance/performance, non-canonical solutions.

**Assessment: CONDITIONAL — LIMITED ALPHA POSSIBLE.** No known release-blocking defect remains and the four reported defects are verified on the signed APK. Device and coverage limits above remain, and publication still needs developer approval.

## Final signed alpha.2 QA — November 11, 2026

**PASS for the tested Android 15 x86_64 emulator profile. Ready for developer review; [the alpha.2 prerelease](https://github.com/wakkaduu/Tomorrow-s-You/releases/tag/v0.1.0-alpha.2) (tag URL; live only after publication) remains unpublished.** Physical-device and wider Android compatibility are not established. The earlier alpha.2 internal checkpoint and alpha.1 failures below are retained as historical evidence.

| Artifact check | Verified final value |
|---|---|
| APK | `TomorrowsYou-v0.1.0-alpha.2-android.apk` |
| APK source commit / annotated tag target | `10956640e8f0bbbe6077c2e613b3aab62574d301` / `v0.1.0-alpha.2` |
| Version / code / package | `0.1.0-alpha.2` / `5` / `com.tomorrowsyou.game` |
| Size | 107,211,976 bytes |
| SHA-256 | `a39c2fd89c4c57b23c8d644f0c762cbbc5dbdb6194358aa472d7f40a8c4dafc9` |
| Certificate SHA-256 | `43f8a0c0bfe13c5c60e3d8d61360ffecdbea4778f437b53c8a5bd98d1438f0db` — unchanged from alpha.1 |
| Signature / debuggable / permissions | v2 and v3 verified / false / none |
| Declared minimum / target API | 24 / 36; not a tested OS range |
| Graphics requirements | OpenGL ES 3 required; Vulkan features declared optional |
| Native ABIs | ARM64, ARMv7, x86, x86_64; only x86_64 executed here |
| Authenticated uploaded asset verification | PASS — downloaded APK hash, checksum file and signature match the runtime-tested APK and GitHub digest |

### Environment and installation

Reused `TomorrowsYou_Alpha_QA`, emulator 37.2.13, AOSP Android 15/API 35 x86_64 revision 2, Pixel 2-derived profile, two vCPUs, actual 2,560 MiB RAM, KVM version 12 usable, 720×1280/density 240. Host graphics used Intel UHD 620 through the emulator translator **with Vulkan available**; the signed game selected OpenGL ES 3 Compatibility directly. No renderer toggle was needed. Live 720×1600 and 480×800 display overrides were exercised and reset.

`adb install -r` of the exact signed APK returned Success on emulator Owner user 0, upgrading alpha.1 without uninstalling or clearing data. The two completed 14-action/three-star records, next-level unlock and prior hint disclosures were preserved (`02`, `61`). The daily allowance was 3 after the legitimate new-day reset; disclosed stages remained available.

For clean first-run data, created only Android user **10**, `TomorrowsYou Alpha2 Signed Fresh QA`, inside the same AVD and enabled the already-installed signed package with `install-existing --user 10`. This is a fresh per-user installation/data context, not a second global APK install or another AVD. It began with Start Journey and 3/31 Archive records. Both users and their saves are retained. All commands selected dedicated ADB port 5038 / serial `emulator-5580`, with AVD and active-user guards. No physical phone was used.

### Signed-APK runtime results

Evidence below is under `/home/wakkadu/.local/share/tomorrows-you-qa/alpha2-signed/evidence/`; numbers refer to the corresponding named PNG captures.

| Check | Result and actual observation | Evidence |
|---|---|---|
| First launch, Main Menu | PASS — visible and responsive on upgrade and fresh profile | `01`, `05` |
| Difficulty / Level Select | PASS — fresh locks, selection, hierarchical Back and retained records | `06`–`07`, `31`, `47`, `58`–`60` |
| Back / Pause / resume | PASS — one press opens/closes Pause; input consumes no turn while paused; Hint closes without credit charge | `10`–`16`, `41`, `62`–`63` |
| Auxiliary return | PASS — Settings and Archive restore the same paused turn-3 puzzle | `14`–`17` |
| Exit confirmation | PASS — Main Menu Back requires confirmation; explicit Exit Game terminates; relaunch works | `04`, `52`–`54`, `explicit-exit.txt` |
| Movement / discarded attempt | PASS — accepted movements and closed-door rejection; Restart refunds discarded action | `13`, `25`, `42`, `45` |
| Echo recording/playback/expiry | PASS — committed recording contributes once; Echo occupies plate through turn 6 and expires on turn 7 | `19`–`25` |
| Door visual/logical sync | PASS — entry on final active Echo turn; closure on expiry; rejected LEFT into closed door leaves turn/action count unchanged | `24`–`25`, `44`–`45` |
| Level-specific WAIT limits | PASS for Levels 1–2 — budgets 3 and 2; exhausted touch/Space rejects; Echo commit retains spent allowance | `18`–`19`, `33`, `43` |
| Level completion | PASS for Levels 1–2 — each 8-turn winning attempt / 14 actions / three stars | `27`, `46` |
| Replay scoring / historical best | PASS — 14 → replay 14; slower replay 16 preserves best 14, including restart | `27`–`31`, `47` |
| Shared daily hints / free reread | PASS — one credit in Level 1 plus two in Level 2; zero prevents another reveal; disclosed stages remain free and persist | `12`, `34`–`35`, `48` |
| MORROW / Archive | PASS for exercised content — Next, allowed Back/Skip closure, reader, research log, replay and return | `08`–`10`, `15`, `26`, `49`–`51` |
| Stationary live resize | PASS — player stays aligned at turn 00/actions 0 through enlargement/reduction/restoration | `37`–`39` |
| Active Echo / paused resize | PASS — player, Echo/plate, open gate, turn 3 and score 9 retained | `20`–`23` |
| Background/foreground | PASS — turn-1 puzzle returns paused | `40`–`41` |
| Save persistence / restart / upgrade | PASS for exercised records, progress, disclosures and credits | `02`, `47`–`48`, `54`, `61` |
| Offline gameplay | PASS for exercised flows — airplane mode 1, Wi-Fi/data off, active default network none | `offline-state.txt`, solves/readers/hints/restarts above |
| App crashes / script errors | No app crash, fatal exception or GDScript error found; final crash buffer empty | `final-app-logcat.txt`, `final-crash-buffer.txt` |

A shader-cache recompilation warning occurred at some cold starts; visible rendering followed. Supplemental Owner-profile captures `55`–`56` show an unsuccessful automated navigation after a user switch and are not used as hint/Back evidence. The settled-screen checks `57`–`63` confirm the preserved disclosures and correct Back behavior. No claim is derived from a filename alone.

### Source regression and remaining coverage

**PASS — 19/19 source suites**, including 86 targeted checks, ten campaign solutions, 282 WAIT optimization checks, 3,187 turn/WAIT checks, 20 hint tests and 15 release-helper tests. The tested production-content fingerprint matches the signed build. The date-dependent test-fixture corrections described below affect tests only.

**NOT TESTED:** physical phones, ARM/ARM64 execution, Android versions other than 15/API 35, audio/haptics, notches/gesture navigation, endurance/performance, complete ten-level Android progression and all narrative/archive content. All ten canonical solutions pass source simulation; only Levels 1–2 were completed on Android in this Nov 11 pass (superseded: all ten were completed in the Nov 13 section above). The underlying Vulkan-driver/Swappy issue is not claimed fixed; Android selects Compatibility instead. Known movement-loop WAIT alternatives and Nightmare's two-Echo shortcut remain unchanged.

**FAIL:** no reproduced failure remains in the four exercised signed-APK remediation scenarios. **BLOCKED:** none for preparing this tested candidate. Public publication is not authorized and still requires developer approval.

### Release decision and provenance

The exact signed APK is suitable for developer review and controlled alpha testing within the demonstrated profile. The approved source push, annotated tag and separate draft were created after signed-APK QA passed. Alpha.1's draft and asset digest remain unchanged. The uploaded alpha.2 APK was freshly downloaded and verified, rather than relying only on the local file or GitHub metadata.

The tag and packaging manifest point to **10956640e8f0bbbe6077c2e613b3aab62574d301**, the exact clean source used for the signed build. Final QA documentation is recorded in a later documentation-only commit on `main`; compiled production content is unchanged, so no extra signed rebuild is needed.

Durable evidence: `/home/wakkadu/.local/share/tomorrows-you-qa/alpha2-signed/`, including `runtime-qa.json`, static manifest/signing verification, uploaded-release download, device metadata, actions, screenshots and logs. The emulator and dedicated QA ADB server were stopped after testing; data and both QA users are retained, with Owner user 0 restored, 720×1280 display and airplane mode on. The website, permanent key and personal phone were not modified. Nothing was publicly published.


## Earlier alpha.2 internal checkpoint — superseded by signed QA above

**Decision at the internal-only checkpoint: HOLD for the final signed candidate.** All four fixes pass the internal Android build and automated regressions. This does not change alpha.1's historical failures below or certify an unbuilt release APK. See [Alpha 2 fix report](ALPHA2_FIX_REPORT.md) for root causes, corrections, file list and evidence.

| Gate | Current result |
|---|---|
| Full source regression gate | **PASS — 19/19 suites**, including 86 targeted checks, all ten campaign solutions, 3,187 turn/WAIT checks, 20 hint tests and 15 release-helper tests; no GDScript errors in the final run |
| Android Back | **PASS on internal APK** — pause/resume, modal dismissal, menu hierarchy, preserved auxiliary return, exit confirmation and explicit exit |
| Default Android rendering | **PASS on internal APK** — direct OpenGL Compatibility with emulator Vulkan available; visual effects retained |
| Replay scoring/history | **PASS on internal APK** — 14-action first run, 14-action replay, 16-action slower replay; best remains 14 |
| Live resizing | **PASS on internal APK** — stationary player and active Echo/plate, including Pause; no unintended turn or score changes |
| Android gameplay/offline/save/lifecycle | **PASS for exercised internal Levels 1–2 and navigation/narrative/hint flows**, Android 15/API 35 x86_64 only |
| Actual same-key signed alpha.2 APK | **NOT TESTED — not built**; production package/certificate, non-debuggable status, final commit, size and checksum still require verification |
| Release preparation | **BLOCKED on local private-password signing**; developer approved the reviewed commit and conditional push/tag/separate draft preparation on November 11, 2026. Remote actions require successful signed-artifact QA |
| Physical devices, other Android versions/ABIs | **NOT TESTED** |

Internal artifact: `TomorrowsYou-alpha2-internal-debug.apk`, package `com.tomorrowsyou.game.qa`, version `0.1.0-alpha.2` / code 5, **debuggable and debug-signed**, 117,046,951 bytes. SHA-256: `ef5d2a6d4e86b05fca177f0884a949a1017d79b21b5c8fcba32d1cc8828b1a86`. This hash identifies only the internal build, not a release candidate. The alternate package preserves the retained alpha.1 app/save for later signed-upgrade QA.

Evidence: `/home/wakkadu/.local/share/tomorrows-you-qa/alpha2/`, including `test-results.json`, `test-logs/`, internal artifact manifest, emulator launch logs and numbered runtime screenshots/application logs in `evidence/`. Original alpha.1 evidence remains in the parent `evidence/` directory.

The final rerun corrected two date-dependent test fixtures that assumed November 10; production hint logic did not change. Intermediate failures remain documented in the fix report. No website, phone data, release key or alpha.1 release asset was changed; alpha.1 remains an unpublished draft. No alpha.2 draft or public release was created.

## Alpha.1 historical artifact QA — retained evidence

Assessment: **HOLD — the exact release APK installs and supports gameplay on the tested OpenGL fallback profile, but Android Back navigation fails. Vulkan emulator launch, replay scoring and live display resizing also fail. Keep the GitHub prerelease draft unpublished.**

QA date: November 10, 2026 (Asia/Manila). This report supersedes the earlier environment-blocked assessment. Findings below concern the uploaded signed APK, exercised through Android touch/key input and inspected with screenshots and logcat. Source tests are not counted as Android runtime passes.

## Release artifact — PASS

Authenticated GitHub CLI downloaded the existing draft's actual APK and checksum. No rebuild, repackaging, replacement upload or release recreation was performed.

| Field | Verified value |
|---|---|
| Repository | `wakkaduu/Tomorrow-s-You` |
| Draft | [Existing prerelease draft](https://github.com/wakkaduu/Tomorrow-s-You/releases/tag/untagged-f21ab25e8808518354de) |
| Release ID / tag | `440156555` / `v0.1.0-alpha.1` |
| Source commit / tag target | `221f4226bf593199c4c7d7b0b5c5bb6f576549fa` |
| APK | `TomorrowsYou-v0.1.0-alpha.1-android.apk` |
| Size | 107,211,976 bytes |
| SHA-256 | `27b3425dac01b1d0b5e574b7ad517a5ca94cd9862fa2ad2d7beb60094e945150` |
| Package | `com.tomorrowsyou.game` |
| Version name / code | `0.1.0-alpha.1` / `4` |
| Minimum / target API | 24 / 36; these are declarations, not a tested OS range |
| Native ABIs | `arm64-v8a`, `armeabi-v7a`, `x86`, `x86_64` |
| Certificate SHA-256 | `43f8a0c0bfe13c5c60e3d8d61360ffecdbea4778f437b53c8a5bd98d1438f0db` |
| Signature | `apksigner verify --verbose --print-certs` succeeds; v2 and v3 verified |
| Debuggable | No |
| Requested permissions | None, including no Internet permission |
| Orientation | Portrait |
| Clean installation | **PASS — `adb install` returned `Success`** |

The downloaded checksum matches the expected checksum, the downloaded checksum file, and GitHub's asset digest. After installation, `sha256sum` of Android's installed `base.apk` matches the same expected digest. Package/version/signing inspection found no discrepancy. The annotated tag's peeled commit and draft target match the source commit. No signing password or private release key was required for QA.

## Isolated Android environment

| Component | Actual configuration / observation |
|---|---|
| Host | Ubuntu, Intel Core i3-8145U, x86_64, 4 logical CPUs, 11 GiB RAM |
| Virtualization | Intel VT-x; `/dev/kvm` readable/writable by current user |
| Acceleration | **PASS** — emulator reports KVM version 12 installed and usable |
| Official CLI tools | Latest revision 23.0, archive `commandlinetools-linux-16111833_latest.zip` |
| Official emulator | 37.2.13.0, build 16740729 |
| AVD | New `TomorrowsYou_Alpha_QA`, Pixel 2-derived phone profile; isolated userdata |
| Android image | AOSP Android 15 / API 35, `system-images;android-35;default;x86_64`, revision 2 |
| Android fingerprint | `Android/sdk_phone64_x86_64/emu64x:15/AE3A.240806.019/12368160:userdebug/test-keys` |
| Actual emulated hardware | 2 CPU cores, 2,560 MiB RAM, 6 GiB userdata partition |
| Display | 720 × 1280, density 240, portrait; additional 720 × 1600 override tested and reset |
| ADB isolation | Dedicated server port 5038, explicit serial `emulator-5580`, emulator console port 5580 |
| Working graphics profile | `-gpu host -feature -Vulkan`; APK automatically falls back to OpenGL ES 3 Compatibility |
| Failing graphics profiles | Host Vulkan on Intel UHD 620 and SwiftShader Vulkan; both show black app surface |
| Audio | Emulator launched with `-no-audio`; audible output and physical haptics NOT TESTED |

The system image is a userdebug/test-keys **Android OS image**; the installed game remains the verified non-debuggable release APK.

Developer approval covered the roughly 1.31 GB of official downloads and isolated setup. Existing platform-tools and license files were copied into a separate SDK; Godot's SDK configuration was not changed. Official archive checksums were verified. No sudo, package-manager system installation, group or device-permission changes were made.

Locations:

- Tools: `/home/wakkadu/.local/share/tomorrows-you-qa/sdk/`.
- Evidence and downloaded release: `/home/wakkadu/.local/share/tomorrows-you-qa/evidence/`.
- Image, archives, SDK cache and AVD: `/run/media/wakkadu/4C1A86B21A86989A/TomorrowsYou-Alpha-QA/`.

Setup encountered a recoverable host disk-space failure: the new SDK CLI used `.sdk` staging on the root filesystem, despite redirected legacy `.temp`. QA staging/cache and archives were moved to the approved secondary drive. After installer rollback left metadata without binaries, the checksum-verified official emulator/image archives were extracted there and validated by successful emulator boot and KVM checks. This was a setup failure, not an APK installation failure. The emulator raised requested 1,536 MiB RAM / 2 GiB userdata to the actual values above. No existing AVD or phone installation was removed or modified.

## Launch results by renderer

| Profile | Result | Evidence |
|---|---|---|
| Host GPU, Vulkan available | **FAIL** — after dismissing Android's initial fullscreen prompt, app remains black; process stays alive | `03_after_system_prompt.png`, `host-gpu-app-logcat.txt`, `emulator-host.log` |
| SwiftShader, Vulkan available | **FAIL** — same black surface and presentation error | `04_software_first_launch.png`, `swiftshader-app-logcat.txt`, `emulator-swiftshader.log` |
| Host GPU, Vulkan disabled in emulator | **PASS** — unchanged APK falls back to GLES, renders menu, accepts touch and runs puzzles | `06_main_menu.png`, `gles-fallback-app-logcat.txt`, `emulator-gles-fallback.log` |

Both failed profiles logged `Couldn't present to Vulkan queue (VkResult error 5)` from `rendering_device_driver_vulkan.cpp:3359`. This is consistent with [Godot issue #121035](https://github.com/godotengine/godot/issues/121035). The [upstream fix #121701](https://github.com/godotengine/godot/pull/121701) describes emulator gfxstream queue-handle behavior affecting Swappy frame pacing and was merged into master for the 4.8 milestone. This is a supported diagnosis, not proof that every phone's Vulkan driver fails or that this release contains that fix. No replacement engine or APK was built.

The working profile deliberately makes Vulkan unavailable. Logcat consequently reports no Vulkan physical device and switching to OpenGL 3. Those startup diagnostics are expected for this profile; its successful gameplay does not turn the Vulkan launch failures into passes. A cached-shader recompilation warning was also captured after restart. No fatal Java/native crash, ANR, or GDScript error was found in the collected working-profile logs; the final crash buffer is empty. An empty crash buffer does not establish bug-free behavior.

## Runtime checks

**All PASS results below are limited to Android 15/API 35 x86_64 on the OpenGL fallback profile.** Each filename is under the evidence directory above. Menu/modal transitions were allowed to settle before assessing results. Early captures `07`, `14`–`17` and `54` include transition or unintended home-screen states and are not used as gameplay passes.

| Check | Status | Actual observation / evidence |
|---|---|---|
| First usable launch | PASS on GLES; FAIL on Vulkan | Menu renders after startup; see renderer matrix |
| Main menu | PASS | Start/Continue, Select Level and Incident Archive navigate; `06`, `37` |
| Difficulty selection | PASS | Easy selectable; other tiers visibly locked, locked Normal tap does not navigate; `38`, `39` |
| Level selection | PASS | Completed record, next unlocked level and locked next card displayed; locked card rejects tap; `40`, `41`, `71` |
| Puzzle gameplay | PASS — Levels 1 and 2 | Both completed legally, 8-turn winning attempts, one Echo, 14 total actions on fresh level entry; `34`, `70` |
| Touch movement | PASS | Wall-facing left at spawn keeps turn 00; down advances to turn 01; valid up/right/down movement and blocked left input exercised; `20`, `21`, `62`, `68` |
| Echo recording/creation | PASS | Recorded moves/WAITs; Create Echo resets attempt to turn 00, retains recording and committed WAIT consumption; `27` |
| Echo playback | PASS | Echo moves with player turns, reaches plate and remains for recorded WAITs; `28`–`31`, `66` |
| Echo expiration | PASS | Six-action Echo remains through turn 6, shows EXPIRED and leaves plate on turn 7; `31`, `32`, `67` |
| Plate/door appearance and traversal | PASS | Door opens on occupied plate, admits player on turn 6, visibly closes on expiry; attempt to move back into closed door on turn 7 is blocked without advancing turn; `30`–`32`, `66`–`68` |
| Level-specific WAIT limits | PASS — Levels 1 and 2 only | Level 1 starts at 3; Level 2 starts at 2. Exhaustion disables button; further touch/Space does not advance turn. Committing Echo does not refill shared allowance; `25`–`27`, `43`, `44` |
| Hint disclosure | PASS | Confirmation required; one credit consumed per reveal; turn unchanged; shared allowance transfers between levels; `11`–`13`, `19`, `45` |
| Hint limit/free rereading | PASS | Three credits consumed across two levels; unrevealed next stage disabled at zero; disclosed stages reread free; zero persists after restart; `46`, `47`, `57` |
| MORROW transmissions | PASS for exercised chapters | Opening/closing transmissions render; Next advances text; Skip returns to game/completion; movement input during opening does not advance turn; `08`–`10`, `33`, `42`, `69` |
| Incident Archive | PASS for exercised records | Unlock count increases, transmission reader/replay/Next/Skip and research-log reader work offline with on-screen controls; `48`–`55` |
| Level completion | PASS for fresh entry; replay score FAIL | Fresh Levels 1 and 2 each award three stars and restore archive records; replay counter issue below; `34`, `36`, `70` |
| Save persistence / app restart | PASS for exercised progress | Process stopped and relaunched without clearing data; Continue, unlocked levels, best stars, archive records, revealed hints and zero credits persist; `37`, `40`, `57`, `71`, `restart-pids.txt` |
| Background/foreground | PASS | Home then explicit app foreground retains PID 2133 and turn 01; game returns paused, Resume works; `21`–`24` |
| Offline operation | PASS for exercised flows | Airplane mode 1, Wi-Fi/data disabled, active default network none; Level 1 replay and full Level 2 solve, hints, archive, saving and restarts work; `offline-state.txt`, `36`, `45`–`57`, `70`, `71` |
| Android Back navigation | **FAIL** | Back from hint panel and archive research reader exits process to Android home rather than dismissing modal; `14`, `56`, `back-repro.txt` |
| Portrait at fixed sizes | PASS for exercised screens | 720×1280 controls visible/usable; cold launch at 720×1600 positions player correctly and renders controls; `10`, `40`, `48`, `63`, `64` |
| Live portrait resizing | **FAIL** | Changing height during puzzle shifts board without updating stationary player sprite until next move; `58`–`62` |

### Executed puzzle routes

`D/R/W` mean accepted DOWN/RIGHT/WAIT actions; each Echo was committed with the on-screen Create Echo button.

- **First Contact:** Echo `DDDWWW`; player `DRRRDDRR`. At turn 6 player enters Door A while Echo is on Plate 1; turn 7 expires Echo and closes Door A behind player; turn 8 completes. Fresh completion gives 14 actions / three stars. Repeated offline via Replay Attempt: same accepted route completes, but reports 28 cumulative actions / one star.
- **Stay Behind:** Echo `DDDDWW`; player `DDRRRRRR`. After player turn 7, additionally tapped LEFT into the closed door: position, turn 7 and action count 13 stay unchanged. Final RIGHT completes at turn 8 / 14 actions / three stars, offline.

These are runtime regression checks, not proof that the full campaign is solvable on Android or that WAIT budgets are globally minimal.

## Reproduced defects

1. **Android Back quits unexpectedly — release blocker.** Open Hint Assistance or an archive research log, send Android `KEYCODE_BACK` once. The process exits and Android home appears. In the second reproduction PID 2666 disappears (`back-repro.txt`). Expected: close the current modal and retain the session. Completed progress is retained, but current gameplay cannot remain open through this Back action. Source inspection finds custom Back handlers but no override of `SceneTree.quit_on_go_back`, whose [documented default is true](https://docs.godotengine.org/en/stable/classes/class_scenetree.html#class-scenetree-property-quit-on-go-back). That is a likely cause, not a runtime-confirmed fix; code and APK were not changed.
2. **Vulkan emulator black screen — compatibility failure on both tested Vulkan profiles.** Reproduction, logs and upstream context are in the renderer section. Full gameplay is BLOCKED on those profiles. Real-device Vulkan remains unverified; GLES fallback alone is insufficient evidence for general Android compatibility.
3. **Replay Attempt carries previous total actions — scoring defect.** Complete Level 1 in 14 actions / three stars, press Replay Attempt, repeat identical route. Result is 28 actions / one star (`34` versus `36`). Persisted best level-select record remains 14 actions / three stars (`40`). Source supports the observation: replay calls `clear_echoes()`, which restarts without resetting `total_actions_taken`; only fresh initialization resets it. Whether cumulative attempts are intended elsewhere, a completed-level replay currently does not start a fresh scoring run.
4. **Live height change leaves player visually outside the board — visual defect.** In Level 2 turn 00 at 720×1280, override display to 720×1600. The board moves down while player stays at its old Y coordinate even after settling (`59`). The next valid move aligns it (`60`). A cold launch at the tall size works (`64`). No claim is made that a physical rotation reproduces this; the app declares portrait.

Other known issues:

- Existing balance limitations: movement loops can replace intended WAITs; budgets describe bounded intended routes. Nightmare has a known two-Echo sequence-latch shortcut. See [WAIT balancing report](WAIT_BALANCING_REPORT.md). These were not re-proved by Android testing.
- aapt2 warns about missing `res/mipmap-anydpi-v26/themed_icon.xml`. Installation and launching via the game activity succeed; themed launcher-icon presentation remains NOT TESTED.

## NOT TESTED and BLOCKED coverage

**NOT TESTED:** physical phones; ARM/ARM64 execution; any Android version except 15/API 35; actual API 24 minimum and API 36 target devices; full Levels 3–10 progression/endgame and their WAIT budgets; multiple simultaneous Echoes and other gate types on Android; all archive content; midnight/day-rollover hints; settings persistence; audible music/SFX and physical haptics; notches, gesture navigation, accessibility/font scaling, tablets, thermal/performance endurance; release-to-release upgrade and existing debug-app migration. No compatibility claim extends to these configurations.

**BLOCKED:** gameplay on both tested Vulkan emulator profiles due black output; completing expected modal/menu routing via Android Back due process exit. The GLES route permitted the other listed checks, but does not resolve either failure.

Earlier source preflight passed 18 suites. Those historical results remain supporting evidence only; no source test pass is substituted for the untested Android coverage above.

## Evidence and reproduction

Evidence is outside Git and the release artifact, retained under `/home/wakkadu/.local/share/tomorrows-you-qa/evidence/`:

- `release/`: actual downloaded APK/checksum, `artifact-audit.json`, signing/badging/manifest/permissions output and draft metadata.
- Numbered screenshots `00`–`71`; see named evidence and test table above. Some intermediate captures intentionally show failure or navigation-transition states.
- `install.txt`, `launch.txt`, `acceleration.txt`, `tested-device.json`, `installed-package.txt`, `offline-state.txt`, `restart-pids.txt`, `back-repro.txt`.
- Per-renderer emulator/application logs; `final-runtime-logcat.txt` and `final-crash-buffer.txt` preserve the final working-profile session. Earlier Vulkan logs are retained separately.
- SDK installation/recovery logs. No signing secrets were collected.

The QA interaction helper is `/home/wakkadu/.local/share/tomorrows-you-qa/qa_adb.py`; it checks `ro.kernel.qemu=1` and the AVD name before interaction, then explicitly selects server port 5038 and serial `emulator-5580`. Installation used no replacement flag and verified the package was absent first. No uninstall, app-data clear or physical-phone command was executed.

For reproducing the successful profile, set `ANDROID_HOME` to the isolated `sdk/`, `ANDROID_AVD_HOME` to the secondary-drive `avd/`, `ANDROID_USER_HOME` to the QA `android-user/`, `ANDROID_EMULATOR_HOME` to the QA `emulator-home/`, `ANDROID_ADB_SERVER_PORT=5038`, `ADB_SERVER_SOCKET=tcp:localhost:5038`, and `ADB_VENDOR_KEYS` to the QA `emulator-home/adbkey`. Launch:

```sh
/home/wakkadu/.local/share/tomorrows-you-qa/sdk/emulator/emulator \
  -avd TomorrowsYou_Alpha_QA -port 5580 -grpc 8580 -grpc-use-token \
  -no-window -no-audio -no-boot-anim -no-snapshot -no-metrics \
  -memory 1536 -cores 2 -gpu host -feature -Vulkan
```

This resumes the dedicated QA AVD's saved userdata; do not wipe it. Official reference: [emulator command-line options](https://developer.android.com/studio/run/emulator-commandline) and [Android environment variables](https://developer.android.com/tools/variables). The display override was reset to 720×1280; airplane mode remains enabled inside this AVD. After collecting evidence, the dedicated emulator and QA ADB server were stopped to release host resources. The AVD and evidence are retained.

## Release readiness

**Artifact identity/signing: PASS. Clean installation: PASS. Limited Android 15 OpenGL gameplay: PASS. Overall public-alpha QA: HOLD.**

The APK is suitable for continued controlled testing on the demonstrated fallback profile. It is **not recommended for public alpha publication yet**, primarily because required Android Back navigation fails, with Vulkan compatibility unresolved and additional scoring/resizing defects recorded. Investigate the verified defects, decide the corrective release scope, then repeat affected Android checks and obtain developer publication approval. This QA did not rebuild automatically.

The GitHub release remains **draft + prerelease**, with no publication or asset replacement. The website, source code, tag, physical phone and existing developer debug installation were not changed. Only this QA report was added to the working tree; no commit or push was performed for this task.
