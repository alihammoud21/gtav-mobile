import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class IPhoneInstallerTests(unittest.TestCase):
    def run_helper(self, *, ipa_present=True, valid_hash=True, sdk_available=True):
        with tempfile.TemporaryDirectory(prefix='gtav iphone usb ') as directory:
            root = Path(directory)
            shutil.copy2(ROOT / 'distribution/Install-iPhone.command', root / 'Install-iPhone.command')
            project = root / 'iOS-USB/GTAVMobile.xcodeproj'
            project.mkdir(parents=True)
            payload = b'test-only IPA'
            if ipa_present:
                (root / 'GTAVMobile-ios.ipa').write_bytes(payload)
            digest = hashlib.sha256(payload if valid_hash else b'different').hexdigest()
            (project.parent / 'Game.sha256').write_text(digest + '  GTAVMobile-ios.ipa\n')
            mocks = root / 'mock-bin'
            mocks.mkdir()
            scripts = {
                'uname': '#!/bin/sh\necho Darwin\n',
                'xcrun': '#!/bin/sh\nexit "$TEST_SDK_STATUS"\n',
                'open': '#!/bin/sh\nprintf "%s\\n" "$@" > "$TEST_OPEN_LOG"\n',
            }
            for name, body in scripts.items():
                path = mocks / name
                path.write_text(body)
                path.chmod(0o755)
            log = root / 'opened'
            env = {**os.environ, 'PATH': str(mocks) + os.pathsep + os.environ['PATH'],
                   'TEST_SDK_STATUS': '0' if sdk_available else '1', 'TEST_OPEN_LOG': str(log)}
            result = subprocess.run(['bash', str(root / 'Install-iPhone.command')], env=env,
                                    stdin=subprocess.DEVNULL, capture_output=True, text=True)
            return result, log.read_text() if log.exists() else ''

    def test_opens_exact_project_with_spaces_after_verification(self):
        result, opened = self.run_helper()
        self.assertEqual(result.returncode, 0, result.stderr)
        arguments = opened.splitlines()
        self.assertEqual(arguments[:2], ['-a', 'Xcode'])
        self.assertEqual(len(arguments), 3)
        self.assertTrue(arguments[2].endswith('/iOS-USB/GTAVMobile.xcodeproj'))
        self.assertIn('seven days', result.stdout)

    def test_corrupt_ipa_never_opens_xcode(self):
        result, opened = self.run_helper(valid_hash=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(opened)

    def test_missing_ipa_never_opens_xcode(self):
        result, opened = self.run_helper(ipa_present=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(opened)

    def test_missing_ios_sdk_explains_setup(self):
        result, opened = self.run_helper(sdk_available=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(opened)
        self.assertIn('Install and open Xcode', result.stdout)
