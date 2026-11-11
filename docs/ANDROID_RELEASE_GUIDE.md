# Android alpha release guide

## Candidate and source

Next candidate version: **0.1.0-alpha.2**, Android versionCode **5**, package **com.tomorrowsyou.game**, proposed tag **v0.1.0-alpha.2**. Release title: **TOMORROW'S YOU — Android Alpha 0.1.0-alpha.2**. Always mark this release as a prerelease. Preserve the existing alpha.1 draft and assets; alpha.2 requires a separate draft and explicit developer approval. Reuse the permanent release key; do not run initial key setup again.

The starting revision is `0c1d5619b3247fd7999eacae37132f691a4a2605`. Initial working tree was clean; no local/remote tags or GitHub releases existed at inspection. The previous internal debug versionCode was 3, so 4 preserves integer progression despite changing the visible version from internal 1.3.0 to public alpha 0.1.0. Increment versionCode on every future distributed build. Change both `project.godot` and the Android preset version fields together.

Release preparation edits are initially uncommitted. A build manifest must distinguish the base commit from working-tree changes. Before staging a GitHub draft, commit only reviewed release changes, push the intended commit, rebuild, and ensure the APK manifest identifies that exact clean source. Do not tag old source while uploading an APK containing newer uncommitted changes.

## Official setup reference

Follow the installed-version [Godot 4.7 Android export guide](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html). This machine has Godot 4.7.2 release/debug templates, JDK 17 and Android SDK build tools 34.0.0. SDK/template compatibility warnings must be reviewed during export; never silently claim they were absent.

Use the **Android Alpha** preset with `--export-release`, not `--export-debug`. The existing Android debug preset remains separate. The release preset excludes tests, documentation, screenshots and build outputs. No website project needs modification.

## Create a permanent private release key

Only a debug keystore was found in the inspected Godot/Android locations. Signing environment variables were unset. The developer selected creation of a dedicated release key.

In your own local terminal:

```sh
cd "/home/wakkadu/Tomorrow's you"
python3 scripts/tools/android_alpha_release.py setup-key
```

The helper prompts privately for the password and asks keytool to prompt for **your** identity. Choose the alias yourself. It refuses an existing destination and any keystore path inside the repository. It creates a PKCS12/RSA key with the same key/store password for Godot compatibility. Passwords are never stored or placed in command-line arguments. The local configuration at `~/.config/tomorrows-you/release-signing.json` contains only the path and alias, with restrictive permissions.

Keep an encrypted offline backup of the keystore and retain the alias/password in a password manager. Verify your backup is readable. Do not overwrite, regenerate or lose this key: future sideloaded updates need the same signing identity. Never send the password in chat, add it to Git, upload the keystore with release assets, or place credentials on the website. The repository ignores keystores and nested release build outputs as a secondary safeguard.

To use a previously created key, configure the local JSON with its real external path and alias, then run `build` to enter the password privately. Do not copy an old key into the repository.

## Tests and release export

Run the existing suites using isolated `XDG_DATA_HOME` and `XDG_CONFIG_HOME` directories; some tests reset saves. Required coverage includes `tests/solver/test_wait_optimization.gd`, `tests/regression/test_turn_and_wait.gd`, `tests/run_all_tests.gd`, campaign/validator suites, mobile tests, completion, narrative, hints, UI and backgrounds. Preserve the actual logs and report failures honestly. The known Nightmare Echo-count weakness must remain disclosed; it is not a passing global minimum-Echo guarantee.

Record a fresh complete preflight with:

```sh
python3 scripts/tools/run_alpha_tests.py
```

Then, in a local terminal:

```sh
python3 scripts/tools/android_alpha_release.py build
```

This sets Godot's documented `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, and `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` only in the export subprocess. Godot receives the private password from an environment variable, not a checked-in preset. Captured build output is password-redacted before being written to the local log.

Expected final artifact:

`build/android/releases/TomorrowsYou-v0.1.0-alpha.2-android.apk`

The helper verifies the package/version, ABIs, signature, non-debuggable flag and permission list, then creates a matching `.apk.sha256` file and `.apk.manifest.json` with actual size, hash, source revision, local source state, build time in Asia/Manila, and verification status. It also copies the release notes. Never fabricate metadata before a signed APK exists. Unsigned internal smoke builds are not release artifacts and must never be uploaded as the public alpha.

Independent checks:

```sh
/home/wakkadu/Android/Sdk/build-tools/34.0.0/apksigner verify --verbose --print-certs build/android/releases/TomorrowsYou-v0.1.0-alpha.2-android.apk
/home/wakkadu/Android/Sdk/build-tools/34.0.0/aapt2 dump badging build/android/releases/TomorrowsYou-v0.1.0-alpha.2-android.apk
/home/wakkadu/Android/Sdk/build-tools/34.0.0/aapt dump permissions build/android/releases/TomorrowsYou-v0.1.0-alpha.2-android.apk
cd build/android/releases
sha256sum -c TomorrowsYou-v0.1.0-alpha.2-android.apk.sha256
```

Confirm API requirements from the **final** APK, all four configured ABIs, expected portrait activity, no debuggable attribute, no unintended permissions, and the expected release certificate. The final release certificate must differ from the debug certificate. No Internet permission is expected for offline gameplay; verify this rather than assuming it.

## Protect the existing phone installation

No device/emulator was attached during initial preparation. Do not uninstall or clear app data automatically.

When a device is attached, read-only inspection comes first:

```sh
adb devices -l
adb shell pm path com.tomorrowsyou.game
adb shell dumpsys package com.tomorrowsyou.game
```

Pull the installed base APK to a private temporary directory and inspect its certificate with `apksigner verify --print-certs`. Compare the certificate SHA-256 against the new release APK. Different certificates mean Android cannot perform an ordinary in-place update, even with a higher versionCode.

For a debuggable installation only, check whether `adb shell run-as com.tomorrowsyou.game` is supported. If available, an app-private-data export can be attempted to a private local backup and verified before any destructive action. The save is Godot's `user://save.cfg`; discover its actual device location rather than assuming a desktop path. A production non-debuggable app normally cannot use run-as for restoration. The current preset disables Android user-data backup, so do not promise standard Android backup will preserve progress.

Options after a signing conflict: keep the debug installation intact and test the release on another clean device/emulator; or perform a separately approved, verified migration. Uninstalling the debug package typically removes its private saves. The signing identity/package cannot be changed merely to bypass update checks without affecting installation behavior. Preserve the existing application ID.

## Device test gate

On a clean device/emulator, verify first launch, menu, campaign movement, Echo creation/playback/expiry, WAIT counters, door visuals, transmissions, archive, hints, save persistence after relaunch, portrait layout, back navigation, background/resume and airplane-mode operation. Record device model, OS/API and actual results. Label emulator testing as emulator testing. Packaging/signature verification is not installation verification.

Future updates must use the same package ID/key, a greater versionCode, compatible save migrations, and an actual update test with retained saves. Until checked, mark preservation as unverified.

## GitHub distribution

Initial preparation had no GitHub CLI. Continuation verified the installed CLI is authenticated as `wakkaduu` with ADMIN access to this repository. No releases or tags exist. Do not request GitHub tokens in chat. The developer explicitly requires approval before committing or pushing the release changes or tag.

After developer approval, commit and push only the reviewed release files, rebuild the signed APK from that clean commit, and verify its manifest and checksum. Device QA remains a publication gate; a private draft may record it as pending. Then create and push the reviewed tag at the exact APK source commit (never move an existing tag):

```sh
git tag -a v0.1.0-alpha.2 <exact-APK-source-commit> -m "TOMORROW'S YOU — Android Alpha 0.1.0-alpha.2"
git push origin refs/tags/v0.1.0-alpha.2
git ls-remote --tags origin 'refs/tags/v0.1.0-alpha.2*'
```

Only after confirming that tag's peeled commit matches the build manifest:

```sh
python3 scripts/tools/android_alpha_release.py draft
```

The helper verifies the existing remote tag targets the exact APK source commit and uses `--verify-tag`. It never implicitly creates a tag. It only creates **draft + prerelease** releases; it has no public publish command. Attach only the signed verified APK and its checksum. Review the release notes in `docs/releases/0.1.0-alpha.2.md`, replace pending validation wording with actual outcomes, and include the final manifest metadata.

Manual equivalent:

1. Open https://github.com/wakkaduu/Tomorrow-s-You/releases/new.
2. Choose the reviewed release source commit and proposed tag `v0.1.0-alpha.2`.
3. Title it `TOMORROW'S YOU — Android Alpha 0.1.0`.
4. Paste the reviewed release notes and mark it as a prerelease.
5. Attach the signed APK and matching checksum; check their size/hash against the manifest.
6. **Save as draft.** Do not click Publish release until the developer explicitly approves publication after reviewing these concrete artifacts.

No public release is claimed until publication actually occurs. If signing, GitHub authentication or device validation remains unavailable, report the missing gate and provide the local preparation artifacts without substituting a debug or unsigned APK.

The installed legacy aapt cannot read the exported Vulkan feature attributes in badging mode; the helper uses aapt2 for badging and aapt for the supported manifest/permission dumps. The internal smoke export also reported a missing themed-icon reference warning; check the final APK on a device before publication.
