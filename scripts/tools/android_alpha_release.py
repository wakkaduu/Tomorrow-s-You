#!/usr/bin/env python3
"""Private-key setup and verified Android alpha packaging. Never stores passwords."""
import argparse
import getpass
import hashlib
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime
from zoneinfo import ZoneInfo

ROOT = Path(__file__).resolve().parents[2]
VERSION = '0.1.0-alpha.1'
CODE = 4
PACKAGE = 'com.tomorrowsyou.game'
OUT = ROOT / 'build/android/releases'
APK = OUT / f'TomorrowsYou-v{VERSION}-android.apk'
CONFIG = Path.home() / '.config/tomorrows-you/release-signing.json'
SDK = Path(os.environ.get('ANDROID_HOME', str(Path.home() / 'Android/Sdk')))
TOOLS = SDK / 'build-tools/34.0.0'


def run(args, **kwargs):
    return subprocess.run(args, check=True, text=True, **kwargs)


def outside_repo(path):
    path = Path(path).expanduser().resolve()
    if path == ROOT or ROOT in path.parents:
        raise SystemExit('Keep the private keystore outside the Git repository.')
    return path


def setup():
    if not sys.stdin.isatty():
        raise SystemExit('Run setup-key in your own local terminal; never send signing passwords in chat.')
    if CONFIG.exists():
        raise SystemExit('A signing configuration already exists; preserve that identity instead of replacing it.')
    default = Path.home() / '.local/share/godot/keystores/tomorrows-you-release.p12'
    key = outside_repo(input(f'New private keystore path [{default}]: ').strip() or default)
    if key.exists():
        raise SystemExit('Refusing to overwrite an existing keystore. Configure an existing key separately.')
    alias = input('Choose the permanent release key alias: ').strip()
    if not alias:
        raise SystemExit('An alias you choose is required.')
    password = getpass.getpass('Choose a strong release keystore password (not saved): ')
    if len(password) < 6 or password != getpass.getpass('Confirm password: '):
        raise SystemExit('Passwords must match and meet keytool minimum length (6 characters).')
    key.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    env = dict(os.environ, TY_PRIVATE_KEY_PASSWORD=password)
    # keytool itself prompts for the owner's identity; no identity is invented here.
    run(['keytool', '-genkeypair', '-storetype', 'PKCS12', '-keyalg', 'RSA',
         '-keysize', '3072', '-validity', '10000', '-keystore', str(key),
         '-alias', alias, '-storepass:env', 'TY_PRIVATE_KEY_PASSWORD',
         '-keypass:env', 'TY_PRIVATE_KEY_PASSWORD'], env=env)
    key.chmod(0o600)
    CONFIG.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    CONFIG.write_text(json.dumps({'path': str(key), 'alias': alias}, indent=2) + '\n')
    CONFIG.chmod(0o600)
    print(f'Private key created. Non-secret path/alias configuration: {CONFIG}')
    print('Back up the key in encrypted offline storage; retain its alias and password in a password manager.')
    print('Use this same key for every future update. Next run:')
    print('python3 scripts/tools/android_alpha_release.py build')


def verify(apk, provenance=None):
    apk = Path(apk).resolve()
    badging = run([str(TOOLS / 'aapt2'), 'dump', 'badging', str(apk)], capture_output=True).stdout
    perms = run([str(TOOLS / 'aapt'), 'dump', 'permissions', str(apk)], capture_output=True).stdout
    manifest = run([str(TOOLS / 'aapt'), 'dump', 'xmltree', str(apk), 'AndroidManifest.xml'], capture_output=True).stdout
    signature = run([str(TOOLS / 'apksigner'), 'verify', '--verbose', '--print-certs', str(apk)], capture_output=True).stdout
    for expected in [f"name='{PACKAGE}'", f"versionCode='{CODE}'", f"versionName='{VERSION}'"]:
        if expected not in badging:
            raise SystemExit('APK identity/version mismatch: ' + expected)
    if 'application-debuggable' in badging or any('android:debuggable' in line and '0xffffffff' in line for line in manifest.splitlines()):
        raise SystemExit('Refusing debuggable APK.')
    if 'CN=Android Debug' in signature or 'Android Debug' in signature:
        raise SystemExit('Refusing APK signed with an Android debug identity.')
    permissions = [line for line in perms.splitlines() if 'uses-permission:' in line]
    unexpected = [line for line in permissions if "name='android.permission.VIBRATE'" not in line]
    if unexpected:
        raise SystemExit('Unexpected permissions require explicit review: ' + ', '.join(unexpected))
    for abi in ['arm64-v8a', 'armeabi-v7a', 'x86', 'x86_64']:
        if abi not in badging:
            raise SystemExit('Required ABI missing: ' + abi)
    minimum_sdk = re.search(r"sdkVersion:'(\d+)'", badging)
    target_sdk = re.search(r"targetSdkVersion:'(\d+)'", badging)
    if not minimum_sdk or int(minimum_sdk.group(1)) != 24:
        raise SystemExit('Unexpected Android minimum SDK; review compatibility requirements.')
    digest = hashlib.sha256(apk.read_bytes()).hexdigest()
    existing_path = apk.with_suffix('.apk.manifest.json')
    if provenance is None and existing_path.exists():
        old = json.loads(existing_path.read_text())
        if old.get('sha256') == digest:
            provenance = {k: old.get(k) for k in ['source_base_commit', 'working_tree_modified', 'source_content_sha256', 'build_date', 'expected_certificate_sha256']}
    provenance = provenance or {'source_base_commit': None, 'working_tree_modified': None, 'source_content_sha256': None, 'build_date': None}
    expected_certificate = provenance.get('expected_certificate_sha256')
    actual_certificate = re.search(r'certificate SHA-256 digest: ([0-9a-fA-F]+)', signature)
    if expected_certificate and (not actual_certificate or actual_certificate.group(1).lower() != expected_certificate.lower()):
        raise SystemExit('APK certificate differs from the configured permanent release key.')
    info = {'apk': apk.name, 'size_bytes': apk.stat().st_size, 'sha256': digest,
            'version_name': VERSION, 'version_code': CODE, 'package_id': PACKAGE,
            **provenance,
            'minimum_sdk': int(minimum_sdk.group(1)),
            'target_sdk': int(target_sdk.group(1)) if target_sdk else None,
            'verified_at': datetime.now(ZoneInfo('Asia/Manila')).isoformat(),
            'signing_verified': True, 'debuggable': False, 'permissions': permissions,
            'badging': badging, 'signing_certificate': signature,
            'device_installation_verified': False}
    apk.with_suffix('.apk.sha256').write_text(f'{digest}  {apk.name}\n')
    apk.with_suffix('.apk.manifest.json').write_text(json.dumps(info, indent=2) + '\n')
    print(json.dumps({k: v for k, v in info.items() if k not in ['badging', 'signing_certificate']}, indent=2))
    return info


def source_fingerprint():
    digest = hashlib.sha256()
    paths = [ROOT / 'project.godot', ROOT / 'export_presets.cfg', ROOT / 'icon.svg']
    for directory in ['scripts', 'scenes', 'assets']:
        paths.extend(p for p in (ROOT / directory).rglob('*') if p.is_file()
                     and p.suffix not in ['.import', '.uid', '.pyc']
                     and 'tools' not in p.relative_to(ROOT).parts)
    for path in sorted(paths):
        digest.update(str(path.relative_to(ROOT)).encode() + b'\0' + path.read_bytes() + b'\0')
    return digest.hexdigest()


def build():
    if not CONFIG.exists():
        raise SystemExit('No release key configured. First run this helper with setup-key in your local terminal.')
    cfg = json.loads(CONFIG.read_text())
    key = outside_repo(cfg['path'])
    if not key.is_file():
        raise SystemExit('Configured release keystore is missing.')
    if not sys.stdin.isatty():
        raise SystemExit('Run build in your local terminal to enter the signing password privately.')
    test_file = OUT / 'test-results.json'
    if not test_file.exists():
        raise SystemExit('Release tests are not recorded yet; finish the release preflight first.')
    tests = json.loads(test_file.read_text())
    if tests.get('source_content_sha256') != source_fingerprint() or not tests.get('suites') or any(s.get('exit_code') != 0 or s.get('script_errors') for s in tests['suites']):
        raise SystemExit('Release tests are stale or failed; rerun the preflight before signing.')
    password = getpass.getpass('Release keystore password (not saved): ')
    env = dict(os.environ, GODOT_ANDROID_KEYSTORE_RELEASE_PATH=str(key),
               GODOT_ANDROID_KEYSTORE_RELEASE_USER=cfg['alias'],
               GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=password)
    OUT.mkdir(parents=True, exist_ok=True)
    cert_env = dict(os.environ, TY_PRIVATE_KEY_PASSWORD=password)
    certificate = subprocess.run(['keytool', '-exportcert', '-keystore', str(key), '-alias', cfg['alias'], '-storepass:env', 'TY_PRIVATE_KEY_PASSWORD'], env=cert_env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True).stdout
    provenance = {'source_base_commit': run(['git', 'rev-parse', 'HEAD'], cwd=ROOT, capture_output=True).stdout.strip(),
                  'expected_certificate_sha256': hashlib.sha256(certificate).hexdigest(),
                  'working_tree_modified': bool(run(['git', 'status', '--porcelain'], cwd=ROOT, capture_output=True).stdout.strip()),
                  'source_content_sha256': source_fingerprint(),
                  'build_date': datetime.now(ZoneInfo('Asia/Manila')).isoformat()}
    with tempfile.TemporaryDirectory(prefix='.candidate-', dir=OUT) as candidate_dir:
        candidate = Path(candidate_dir) / APK.name
        result = subprocess.run(['godot', '--headless', '--path', str(ROOT), '--export-release',
                                 'Android Alpha', str(candidate)], env=env, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        log = result.stdout.replace(password, '<redacted>') if password else result.stdout
        (OUT / 'build.log').write_text(log)
        if result.returncode != 0 or not candidate.exists():
            raise SystemExit('Release export failed; inspect build/android/releases/build.log (password redacted).')
        if source_fingerprint() != provenance['source_content_sha256']:
            raise SystemExit('Source changed during export; do not distribute this candidate. Rerun tests and build.')
        verify(candidate, provenance)
        for suffix in ['', '.sha256', '.manifest.json']:
            os.replace(Path(str(candidate) + suffix), Path(str(APK) + suffix))
    shutil.copy2(ROOT / 'docs/releases/0.1.0-alpha.1.md', OUT / 'RELEASE_NOTES.md')
    print('Release artifacts are local only. Do not publish until device testing and developer review are complete.')


def verify_remote_tag(revision):
    tag = f'v{VERSION}'
    output = run(['git', 'ls-remote', '--tags', 'origin', f'refs/tags/{tag}', f'refs/tags/{tag}^{{}}'], cwd=ROOT, capture_output=True).stdout
    refs = dict(line.split()[::-1] for line in output.splitlines() if line.strip())
    target = refs.get(f'refs/tags/{tag}^{{}}', refs.get(f'refs/tags/{tag}'))
    if not target:
        raise SystemExit('Create and push the reviewed release tag after the clean signed rebuild; no tag is created implicitly.')
    if target != revision:
        raise SystemExit('Release tag does not point to the exact APK source commit; refusing to draft. Do not move or force-push it.')
    return tag


def draft():
    if run(['git', 'status', '--porcelain'], cwd=ROOT, capture_output=True).stdout.strip():
        raise SystemExit('Commit reviewed release changes and rebuild from a clean source before creating a draft.')
    manifest_path = APK.with_suffix('.apk.manifest.json')
    if not manifest_path.exists():
        raise SystemExit('No verified build manifest exists.')
    built = json.loads(manifest_path.read_text())
    revision = run(['git', 'rev-parse', 'HEAD'], cwd=ROOT, capture_output=True).stdout.strip()
    if built.get('source_base_commit') != revision or built.get('working_tree_modified') or built.get('source_content_sha256') != source_fingerprint():
        raise SystemExit('Rebuild the signed APK from this exact clean release commit before drafting.')
    run(['git', 'fetch', 'origin'], cwd=ROOT, capture_output=True)
    run(['git', 'merge-base', '--is-ancestor', revision, 'origin/main'], cwd=ROOT, capture_output=True)
    tag = verify_remote_tag(revision)
    verify(APK)
    if not shutil.which('gh'):
        raise SystemExit('GitHub CLI is not installed. Use the manual draft-release steps in docs/ANDROID_RELEASE_GUIDE.md.')
    # No public publish operation exists in this helper.
    run(['gh', 'release', 'create', tag, '--repo', 'wakkaduu/Tomorrow-s-You',
         '--draft', '--prerelease', '--verify-tag', '--target', run(['git', 'rev-parse', 'HEAD'], cwd=ROOT, capture_output=True).stdout.strip(),
         '--title', "TOMORROW'S YOU — Android Alpha 0.1.0", '--notes-file', str(ROOT / 'docs/releases/0.1.0-alpha.1.md'),
         str(APK), str(APK.with_suffix('.apk.sha256'))], cwd=ROOT)


def main():
    os.umask(0o077)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['setup-key', 'build', 'verify', 'draft'])
    args = parser.parse_args()
    {'setup-key': setup, 'build': build, 'verify': lambda: verify(APK), 'draft': draft}[args.command]()

if __name__ == '__main__':
    main()
