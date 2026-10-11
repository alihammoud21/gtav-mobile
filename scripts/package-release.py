#!/usr/bin/env python3
"""Package the Android app, iOS game build, and desktop installation helpers."""
import argparse
import hashlib
from pathlib import Path
import shutil
import struct
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def has_embedded_game(binary):
    if len(binary) < 32 or struct.unpack_from('<I', binary)[0] != 0xFEEDFACF:
        raise ValueError('Expected an ARM64 Mach-O iOS executable')
    count = struct.unpack_from('<I', binary, 16)[0]
    offset = 32
    for _ in range(count):
        command, size = struct.unpack_from('<II', binary, offset)
        if size < 8 or offset + size > len(binary):
            raise ValueError('Invalid Mach-O load command')
        if command == 0x19 and binary[offset + 8:offset + 24].rstrip(b'\0') == b'__GAME':
            return True
        offset += size
    return False


def package(version):
    if not version.startswith('v') or any(c not in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-' for c in version):
        raise ValueError('Use a version such as v0.1.0-alpha.1')
    apk = ROOT / 'build/gtav-mobile-release.apk'
    ipa = ROOT / 'build/GTAVMobile.ipa'
    with zipfile.ZipFile(apk) as archive:
        required = {'AndroidManifest.xml', 'lib/arm64-v8a/libgtav_mobile.so', 'classes.dex'}
        if not required.issubset(archive.namelist()):
            raise ValueError('Android APK is missing runtime files')
        if archive.testzip():
            raise ValueError('Android APK has corrupt ZIP entries')
    with zipfile.ZipFile(ipa) as archive:
        binary = archive.read('Payload/GTAVMobile.app/gtav-mobile')
        if not has_embedded_game(binary):
            raise ValueError('Refusing to publish an iOS app without embedded game code')
        if archive.testzip():
            raise ValueError('iOS IPA has corrupt ZIP entries')
    out = ROOT / 'build/releases' / version
    out.mkdir(parents=True, exist_ok=True)
    outputs = []
    for source, name in [(apk, 'gtav-mobile-android.apk'), (ipa, 'GTAVMobile-ios.ipa')]:
        destination = out / name
        shutil.copy2(source, destination)
        outputs.append(destination)
    ios_files = [
        'Install-iPhone.command', 'iOS-USB/Info.plist',
        'iOS-USB/PersonalTeam.entitlements', 'iOS-USB/prepare-app.sh',
        'iOS-USB/stub.c', 'iOS-USB/project.yml',
        'iOS-USB/GTAVMobile.xcodeproj/project.pbxproj',
        'iOS-USB/GTAVMobile.xcodeproj/xcshareddata/xcschemes/GTAVMobile.xcscheme',
    ]
    for bundle_name, platforms in [
        ('gtav-mobile-desktop-installers.zip', outputs.copy()),
        ('gtav-mobile-mac-usb.zip', [out / 'GTAVMobile-ios.ipa']),
    ]:
        bundle = out / bundle_name
        with zipfile.ZipFile(bundle, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
            for artifact in platforms:
                archive.write(artifact, 'GTAV-Mobile/' + artifact.name)
            helpers = ios_files + ['START-HERE.txt']
            if bundle_name == 'gtav-mobile-desktop-installers.zip':
                helpers += ['Install-Android.command', 'Install-Android.cmd']
            for name in helpers:
                archive.write(ROOT / 'distribution' / name, 'GTAV-Mobile/' + name)
            archive.writestr('GTAV-Mobile/iOS-USB/Game.sha256',
                             hashlib.sha256(ipa.read_bytes()).hexdigest() + '  GTAVMobile-ios.ipa\n')
            for name in ['LICENSE', 'NOTICE.md', 'GAME-DATA.md']:
                archive.write(ROOT / name, 'GTAV-Mobile/' + name)
        outputs.append(bundle)
    install = out / 'INSTALL.txt'
    shutil.copy2(ROOT / 'distribution/START-HERE.txt', install)
    outputs.append(install)
    sums = out / 'SHA256SUMS.txt'
    sums.write_text(''.join(f'{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}\n' for path in outputs))
    print(out)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--version', required=True)
    package(parser.parse_args().version)
