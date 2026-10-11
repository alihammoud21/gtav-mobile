#!/usr/bin/env python3
"""Fetch and verify the pinned WebAssembly source used by the iOS release."""
import hashlib
import json
from pathlib import Path
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    manifest = json.loads((ROOT / 'distribution/game-manifest.json').read_text())
    game = next(f for f in manifest['files'] if f['relative'].endswith('/game.wasm'))
    part = next(p for p in manifest['parts'] if p['name'] == game['part'])
    output = ROOT / 'build/game-source'
    output.mkdir(parents=True, exist_ok=True)
    wasm = output / 'game.wasm'
    if wasm.exists() and hashlib.sha256(wasm.read_bytes()).hexdigest() == game['sha256']:
        print(f'Already verified: {wasm}')
        return
    archive = output / 'source-part.zip'
    try:
        print(f'Downloading {part["name"]} ({part["bytes"]:,} bytes)…', flush=True)
        digest = hashlib.sha256()
        size = 0
        with urllib.request.urlopen(part['url'], timeout=60) as response, archive.open('wb') as target:
            while chunk := response.read(1024 * 1024):
                size += len(chunk)
                if size > part['bytes']:
                    raise ValueError('Unexpected archive size')
                digest.update(chunk)
                target.write(chunk)
        if size != part['bytes'] or digest.hexdigest() != part['sha256']:
            raise ValueError('Archive verification failed')
        with zipfile.ZipFile(archive) as source:
            data = source.read(game['path'])
        if len(data) != game['bytes'] or hashlib.sha256(data).hexdigest() != game['sha256']:
            raise ValueError('Game executable verification failed')
        temporary = output / 'game.wasm.tmp'
        temporary.write_bytes(data)
        temporary.replace(wasm)
        print(f'Verified: {wasm}')
    finally:
        archive.unlink(missing_ok=True)


if __name__ == '__main__':
    main()
