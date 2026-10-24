#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT"
if [ "$#" -gt 0 ]; then
  exec python3 scripts/patch-stossign.py "$1"
fi
exec python3 scripts/patch-stossign.py
