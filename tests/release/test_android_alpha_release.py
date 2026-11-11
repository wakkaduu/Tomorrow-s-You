import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from types import SimpleNamespace

spec = importlib.util.spec_from_file_location('alpha_release', Path(__file__).resolve().parents[2] / 'scripts/tools/android_alpha_release.py')
alpha = importlib.util.module_from_spec(spec)
spec.loader.exec_module(alpha)

class ReleaseVerificationTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.apk = Path(self.tmp.name) / alpha.APK.name
        self.apk.write_bytes(b'fixture only; not an Android package')
        self.badging = f"package: name='{alpha.PACKAGE}' versionCode='{alpha.CODE}' versionName='{alpha.VERSION}'\nsdkVersion:'24'\ntargetSdkVersion:'36'\nnative-code: 'arm64-v8a' 'armeabi-v7a' 'x86' 'x86_64'"
        self.permissions = ''
        self.certificate = ('Signer #1 certificate DN: CN=Fixture Release Owner\n'
                            f'Signer #1 certificate SHA-256 digest: {alpha.RELEASE_CERTIFICATE_SHA256}')

    def fake_run(self, args, **kwargs):
        if 'permissions' in args: text = self.permissions
        elif 'badging' in args: text = self.badging
        elif 'xmltree' in args: text = ''
        elif 'verify' in args: text = self.certificate
        else: raise AssertionError('Unexpected command: ' + str(args))
        return SimpleNamespace(stdout=text, returncode=0)

    def verify(self, provenance=None):
        with patch.object(alpha, 'run', self.fake_run):
            return alpha.verify(self.apk, provenance)

    def test_debuggable_is_rejected(self):
        self.badging += '\napplication-debuggable'
        with self.assertRaises(SystemExit): self.verify()

    def test_debug_signing_identity_is_rejected(self):
        self.certificate = 'CN=Android Debug'
        with self.assertRaises(SystemExit): self.verify()

    def test_wrong_version_is_rejected(self):
        self.badging = self.badging.replace(f"versionCode='{alpha.CODE}'", f"versionCode='{alpha.CODE - 1}'")
        with self.assertRaises(SystemExit): self.verify()

    def test_network_permission_is_rejected(self):
        self.permissions = "uses-permission: name='android.permission.INTERNET'"
        with self.assertRaises(SystemExit): self.verify()

    def test_missing_abi_is_rejected(self):
        self.badging = self.badging.replace("'arm64-v8a'", '')
        with self.assertRaises(SystemExit): self.verify()

    def test_allowed_haptics_and_checksum(self):
        self.permissions = "uses-permission: name='android.permission.VIBRATE'"
        info = self.verify({'source_base_commit': 'fixture-revision', 'build_date': 'fixture-time'})
        self.assertTrue(info['signing_verified'])
        self.assertIn(info['sha256'], self.apk.with_suffix('.apk.sha256').read_text())

    def test_verify_never_invents_source_provenance(self):
        self.assertIsNone(self.verify()['source_base_commit'])

    def test_reverification_preserves_real_provenance(self):
        provenance = {'source_base_commit': 'original-build', 'build_date': 'original-time'}
        self.verify(provenance)
        self.assertEqual(self.verify()['source_base_commit'], 'original-build')
        self.assertEqual(self.verify()['build_date'], 'original-time')

    def test_wrong_permanent_certificate_is_rejected(self):
        with self.assertRaises(SystemExit):
            self.verify({'expected_certificate_sha256': '00' * 32})

    def test_new_certificate_is_rejected_without_provenance(self):
        self.certificate = 'Signer #1 certificate SHA-256 digest: ' + '11' * 32
        with self.assertRaises(SystemExit): self.verify()

    def test_private_key_cannot_be_inside_repository(self):
        with self.assertRaises(SystemExit): alpha.outside_repo(alpha.ROOT / 'key.p12')

    def test_draft_rejects_uncommitted_source_without_upload(self):
        def fake(args, **kwargs):
            self.assertEqual(args[:3], ['git', 'status', '--porcelain'])
            return SimpleNamespace(stdout=' M project.godot\n')
        with patch.object(alpha, 'run', fake), self.assertRaises(SystemExit): alpha.draft()

    def test_missing_remote_tag_is_rejected(self):
        with patch.object(alpha, 'run', return_value=SimpleNamespace(stdout='')), self.assertRaises(SystemExit):
            alpha.verify_remote_tag('expected-revision')

    def test_wrong_remote_tag_is_rejected(self):
        value = f"wrong-revision\trefs/tags/v{alpha.VERSION}\n"
        with patch.object(alpha, 'run', return_value=SimpleNamespace(stdout=value)), self.assertRaises(SystemExit):
            alpha.verify_remote_tag('expected-revision')

    def test_annotated_tag_uses_peeled_commit(self):
        value = f"tag-object\trefs/tags/v{alpha.VERSION}\nexpected-revision\trefs/tags/v{alpha.VERSION}^{{}}\n"
        with patch.object(alpha, 'run', return_value=SimpleNamespace(stdout=value)):
            self.assertEqual(alpha.verify_remote_tag('expected-revision'), f'v{alpha.VERSION}')

if __name__ == '__main__': unittest.main()
