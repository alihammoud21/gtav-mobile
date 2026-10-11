import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class AndroidInstallerTests(unittest.TestCase):
    def run_installer(self, authorized=True, install_ok=True, apk=True):
        with tempfile.TemporaryDirectory(prefix='gtav installer ') as directory:
            root = Path(directory)
            shutil.copy2(ROOT / 'distribution/Install-Android.command', root / 'Install-Android.command')
            if apk:
                (root / 'gtav-mobile-android-preview.apk').write_bytes(b'test-only')
            tools = root / 'platform-tools'
            tools.mkdir()
            adb = tools / 'adb'
            adb.write_text('''#!/bin/bash
printf '%s\\n' "$*" >> "$TEST_CALLS"
if [ "$2" = get-state ]; then exit "$TEST_STATE"; fi
if [ "$2" = install ]; then exit "$TEST_INSTALL"; fi
exit 99
''')
            adb.chmod(0o755)
            calls = root / 'calls'
            env = {**os.environ, 'TEST_CALLS': str(calls), 'TEST_STATE': '0' if authorized else '1', 'TEST_INSTALL': '0' if install_ok else '1'}
            result = subprocess.run(['bash', str(root / 'Install-Android.command')], env=env, stdin=subprocess.DEVNULL, capture_output=True, text=True)
            return result, calls.read_text() if calls.exists() else ''

    def test_install_uses_usb_device_and_preserves_existing_app_data(self):
        result, calls = self.run_installer()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('-d get-state', calls)
        self.assertIn('-d install -r ', calls)
        self.assertNotIn('uninstall', calls)

    def test_unauthorized_device_never_receives_install(self):
        result, calls = self.run_installer(authorized=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('install -r', calls)

    def test_missing_apk_never_contacts_device(self):
        result, calls = self.run_installer(apk=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, '')

    def test_failed_install_is_not_reported_as_success(self):
        result, calls = self.run_installer(install_ok=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('Installed GTAV Mobile.', result.stdout)


if __name__ == '__main__':
    unittest.main()
