#!/usr/bin/env python3
"""Apply GetMoreRam's Anisette User-Agent overrides to the resolved StosSign SPM checkout.

Run after `xcodebuild -resolvePackageDependencies` and before building. Idempotent.
"""
from pathlib import Path
import sys

CANDIDATES = [
    Path('.build/SourcePackages/checkouts/StosSign/Sources/StosSign_Auth/Authentication.swift'),
]
# Xcode's normal DerivedData package cache.
home = Path.home()
for root in (home / 'Library/Developer/Xcode/DerivedData',):
    if root.exists():
        CANDIDATES.extend(root.glob('*/SourcePackages/checkouts/StosSign/Sources/StosSign_Auth/Authentication.swift'))

if len(sys.argv) > 1:
    CANDIDATES.insert(0, Path(sys.argv[1]))

files = [p for p in CANDIDATES if p.is_file()]
if not files:
    print('ERROR: StosSign Authentication.swift not found. Run xcodebuild -resolvePackageDependencies first.', file=sys.stderr)
    sys.exit(2)

for path in files:
    text = path.read_text()
    if 'getMoreRamConfiguredUserAgent' not in text:
        anchor = '    public static func sendAuthenticationRequest(\n'
        helper = '''    /// GetMoreRam: read the same persisted Anisette User-Agent override used by Settings.\n    /// Empty/disabled overrides preserve the upstream StosSign default.\n    private static func getMoreRamConfiguredUserAgent(fallback: String) -> String {\n        let defaults = UserDefaults.standard\n        guard defaults.bool(forKey: "AnisetteUseCustomUserAgent"),\n              let value = defaults.string(forKey: "AnisetteCustomUserAgent")?.trimmingCharacters(in: .whitespacesAndNewlines),\n              !value.isEmpty else { return fallback }\n        return value\n    }\n\n'''
        if anchor not in text:
            raise SystemExit(f'ERROR: expected insertion point not found in {path}')
        text = text.replace(anchor, helper + anchor, 1)
    text = text.replace('"User-Agent": "AuthKit/1 (Macintosh; OS X 26.6) (com.apple.dt.Xcode/26.0)",', '"User-Agent": getMoreRamConfiguredUserAgent(fallback: "AuthKit/1 (Macintosh; OS X 26.6) (com.apple.dt.Xcode/26.0)"),')
    text = text.replace('"User-Agent": "Xcode",', '"User-Agent": getMoreRamConfiguredUserAgent(fallback: "Xcode"),')
    if 'getMoreRamConfiguredUserAgent(fallback: "AuthKit/1 (Macintosh; OS X 26.6) (com.apple.dt.Xcode/26.0)")' not in text:
        raise SystemExit(f'ERROR: did not patch GrandSlam User-Agent in {path}')
    if 'getMoreRamConfiguredUserAgent(fallback: "Xcode")' not in text:
        raise SystemExit(f'ERROR: did not patch 2FA User-Agent in {path}')
    path.write_text(text)
    print(f'Patched StosSign User-Agent overrides: {path}')
