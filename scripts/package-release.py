#!/usr/bin/env python3
"""Package verified local preview builds; never include game archives or signing keys."""
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
    apk = ROOT / 'build/gtav-mobile-debug.apk'
    ipa = ROOT / 'build/GTAVMobile.ipa'
    with zipfile.ZipFile(apk) as archive:
        required = {'AndroidManifest.xml', 'lib/arm64-v8a/libgtav_mobile.so', 'classes.dex'}
        if not required.issubset(archive.namelist()):
            raise ValueError('Android APK is missing runtime files')
        if archive.testzip():
            raise ValueError('Android APK has corrupt ZIP entries')
    with zipfile.ZipFile(ipa) as archive:
        binary = archive.read('Payload/GTAVMobile.app/gtav-mobile')
        if has_embedded_game(binary):
            raise ValueError('Refusing to publish embedded game code as a runtime-only preview')
        if archive.testzip():
            raise ValueError('iOS IPA has corrupt ZIP entries')
    out = ROOT / 'build/releases' / version
    out.mkdir(parents=True, exist_ok=True)
    outputs = []
    for source, name in [(apk, 'gtav-mobile-android-preview.apk'), (ipa, 'GTAVMobile-ios-runtime-preview.ipa')]:
        destination = out / name
        shutil.copy2(source, destination)
        outputs.append(destination)
    bundle = out / 'gtav-mobile-desktop-installers.zip'
    with zipfile.ZipFile(bundle, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for artifact in outputs:
            archive.write(artifact, 'GTAV-Mobile/' + artifact.name)
        for name in ['Install-Android.command', 'Install-Android.cmd', 'START-HERE.txt']:
            archive.write(ROOT / 'distribution' / name, 'GTAV-Mobile/' + name)
        for name in ['LICENSE', 'NOTICE.md']:
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
