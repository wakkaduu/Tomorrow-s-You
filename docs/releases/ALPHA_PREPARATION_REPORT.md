# Android alpha preparation report

Status: **signed release candidate prepared locally; not published**.

## Verified artifact

- APK: `build/android/releases/TomorrowsYou-v0.1.0-alpha.1-android.apk`
- Size: **107,211,976 bytes** (102.2 MiB).
- SHA-256: `b0925c9f76695bddbe54c5fefe0bd1d6a6345c6cd05e4a4c037e4566f24a00a7`.
- Checksum file: `TomorrowsYou-v0.1.0-alpha.1-android.apk.sha256` in the same directory.
- Manifest: `TomorrowsYou-v0.1.0-alpha.1-android.apk.manifest.json` in the same directory.
- Package: `com.tomorrowsyou.game` (unchanged).
- Version: **0.1.0-alpha.1**, versionCode **4**.
- Actual build timestamp: `2026-11-10T17:05:14.659724+08:00` (Asia/Manila).
- Godot: 4.7.2; JDK 17; Android SDK build tools 34.0.0.
- Minimum Android: API 24 / Android 7.0; target API 36.
- ABIs: ARM64, ARMv7, x86, x86_64; portrait activity confirmed.
- Requested permissions: **none**, including no Internet permission.
- Release-mode export; APK is **not debuggable**.
- APK signing verifies using **v2 and v3**. Certificate matches the configured permanent release key and differs from the existing local debug certificate.
- Release certificate SHA-256: `43f8a0c0bfe13c5c60e3d8d61360ffecdbea4778f437b53c8a5bd98d1438f0db` (public certificate fingerprint, not a secret).
- No private keys or test/documentation assets bundled. Three OFL font-license texts and the asset-license document are bundled.

## Source provenance

Base commit: `0c1d5619b3247fd7999eacae37132f691a4a2605`. The starting working tree was clean. The APK includes **uncommitted release configuration changes** to version/preset data; it must not be described as a binary of the unmodified base commit.

Production source fingerprint: `1f28a22562d1b08a698629527a3852fdb40c2ba4fddf9da2195bb6acd268c8ac`. It matches the current production tree. The exact production configuration delta is saved locally as `build/android/releases/SOURCE_CHANGES.patch`. No gameplay, story, save schema or level balance was changed in this release-preparation task.

Before creating a release tag/draft, commit the reviewed release preparation changes, push the intended release commit, and rebuild using the same private key from that clean revision. The draft helper refuses a dirty or mismatched source snapshot. This task did not commit, push, tag or publish anything.

## Tests actually executed

All **18 preflight suites passed**, using isolated saves. The record is `build/android/releases/test-results.json`; logs are `/tmp/tomorrow-alpha-tests-hzdyz6ll`. Coverage includes 282 optimization checks, 3,187 door/WAIT regressions, master gameplay, all ten intended campaign solutions, mobile controls/navigation, UI, hints, completion/progression/save handling, narrative/archive and atmospheric backgrounds. The release-tool unit suite also passed **11/11** checks, covering rejected debug builds, wrong versions, network permissions, missing ABIs, wrong certificates, source-provenance preservation and dirty-source draft prevention.

Actual signed APK verification and checksum checks were run independently of the mocked unit tests. A disposable unsigned release-mode smoke export also succeeded; that file remains in a private temporary directory and is **not** a public-release asset.

Existing detached-renderer responsiveness harness path errors and ObjectDB cleanup warnings remain known test-tool limitations; assertion suites passed and no GDScript compile/runtime errors appeared in the preflight. Export reports an SDK/build-tools fallback and an unavailable ADB daemon. Aapt2 also reports a missing themed-icon resource reference; verify launcher behavior on a real device. The legacy aapt badging parser could not read the exported Vulkan feature attributes, so successful badging inspection used aapt2.

## Signing and installation safety

The developer created the dedicated release key locally through private prompts. No signing identity or password was invented. The key is outside this repository with mode 0600. Its local JSON configuration contains only path/alias; passwords are not saved. Keep an encrypted offline key backup and retain the password/alias securely. Future updates require the same key and package ID, with a higher versionCode.

No Android device/emulator was connected. **Installation, first launch, save persistence on Android, background/resume, real touch feel and airplane-mode playtesting are not verified.** Desktop automated mobile tests and signature validity cannot substitute for installation testing.

The release certificate differs from the local debug key. The installed phone APK could not be inspected without the phone, so an in-place upgrade is not promised. Do not uninstall the debug app or clear data. Prefer a separate clean device/emulator for release testing. For any migration, inspect the installed certificate and supported backup options first; Android backup is disabled in the preset, and a production app cannot normally restore private data via debug run-as.

## Distribution preparation and remaining gates

- No existing tags or releases were found in local/remote tag inspection and the public GitHub API.
- Proposed tag: `v0.1.0-alpha.1`; title: **TOMORROW'S YOU — Android Alpha 0.1.0**; channel: **prerelease**.
- Release notes: `docs/releases/0.1.0-alpha.1.md` (also copied beside the APK).
- Release guide: `docs/ANDROID_RELEASE_GUIDE.md`.
- Key/build/verify/draft helper: `scripts/tools/android_alpha_release.py`.
- Repeatable test preflight: `scripts/tools/run_alpha_tests.py`.
- Continuation check: GitHub CLI is authenticated as `wakkaduu` with ADMIN repository access. **No GitHub draft URL exists yet: committing/pushing requires developer approval, followed by a fresh signed rebuild and exact remote-tag verification.** Exact manual draft steps are in the guide. Do not send GitHub tokens in chat.
- Complete device QA and clean release-source pinning before publication. Stage only the signed APK and matching checksum, review notes/manifest, and save a prerelease **draft**. Public publication still requires explicit developer approval.

Known game limitations remain disclosed in the alpha notes: movement-padding alternatives to intended WAIT strategies and Nightmare's two-Echo sequence-latch route. They were not silently changed for release.
