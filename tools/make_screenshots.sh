#!/bin/bash
# Regenerates docs/screenshots/*.png from the real views with demo data.
# Usage: bash tools/make_screenshots.sh
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
xcrun swiftc -parse-as-library -swift-version 5 -D SNAPSHOT \
  -target "$(uname -m)-apple-macos14.0" \
  -o build/snapshots Sources/*.swift tools/Snapshots.swift
build/snapshots docs/screenshots
