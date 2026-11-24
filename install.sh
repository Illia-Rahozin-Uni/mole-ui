#!/bin/bash
# Mole UI — one-command install:  bash install.sh
# 1) installs Mole if missing  2) builds the app  3) copies it to ~/Applications and launches it
set -euo pipefail

cd "$(dirname "$0")"
APP_NAME="Mole UI"
DEST="$HOME/Applications"
BUILD="$(pwd)/build"

say()  { printf "\033[1;34m==>\033[0m %s\n" "$1"; }
ok()   { printf "\033[1;32m✓\033[0m %s\n" "$1"; }
die()  { printf "\033[1;31m✗ %s\033[0m\n" "$1"; exit 1; }

[[ "$(uname)" == "Darwin" ]] || die "macOS only."
MAJOR="$(sw_vers -productVersion | cut -d. -f1)"
(( MAJOR >= 14 )) || die "Requires macOS 14 Sonoma or later (you have $(sw_vers -productVersion))."

# --- 1. Build tools (Swift) ---
say "Checking Swift…"
if ! xcrun --find swiftc >/dev/null 2>&1; then
  echo "Apple Command Line Tools are required. An installer window will open now."
  xcode-select --install || true
  die "Wait for the install to finish, then run this script again."
fi
ok "Swift: $(xcrun swiftc --version 2>&1 | head -1)"

# --- 2. Mole ---
for d in "$HOME/.homebrew/bin" /opt/homebrew/bin /usr/local/bin "$HOME/.local/bin"; do
  [[ -d "$d" ]] && PATH="$d:$PATH"
done
export PATH

if command -v mo >/dev/null 2>&1; then
  ok "Mole is already installed: $(mo --version 2>/dev/null | grep -m1 .)"
else
  say "Installing Mole…"
  if command -v brew >/dev/null 2>&1; then
    brew install mole
  else
    mkdir -p "$HOME/.local/bin"
    curl -fsSL https://raw.githubusercontent.com/tw93/mole/main/install.sh | bash -s -- --prefix "$HOME/.local/bin"
    echo 'Add this line to ~/.zshrc:  export PATH="$HOME/.local/bin:$PATH"'
  fi
  command -v mo >/dev/null 2>&1 || die "Mole failed to install — see the errors above."
  ok "Mole installed"
fi

# --- 3. Build the app ---
say "Building $APP_NAME (about a minute)…"
APP="$BUILD/$APP_NAME.app"
rm -rf "$BUILD"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Mole UI</string>
  <key>CFBundleDisplayName</key><string>Mole UI</string>
  <key>CFBundleIdentifier</key><string>local.mole-ui</string>
  <key>CFBundleExecutable</key><string>MoleUI</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

xcrun swiftc -O -parse-as-library -swift-version 5 \
  -target "$(uname -m)-apple-macos14.0" \
  -o "$APP/Contents/MacOS/MoleUI" \
  Sources/*.swift 2>&1 | tee "$BUILD/build.log" | grep -E "error|warning: unre" || true
[[ -x "$APP/Contents/MacOS/MoleUI" ]] || die "Build failed. Full log: $BUILD/build.log"

# Icon: the "hare" SF Symbol on a gradient (skipped if it fails)
xcrun swiftc -O -parse-as-library -target "$(uname -m)-apple-macos14.0" -o "$BUILD/mkicon" make_icon.swift 2>/dev/null \
  && "$BUILD/mkicon" "$BUILD/AppIcon.iconset" \
  && iconutil -c icns "$BUILD/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns" \
  || echo "(icon skipped)"

codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true
ok "Built"

# --- 4. Install ---
mkdir -p "$DEST"
pkill -x MoleUI 2>/dev/null || true
rm -rf "$DEST/$APP_NAME.app"
cp -R "$APP" "$DEST/"
xattr -cr "$DEST/$APP_NAME.app" 2>/dev/null || true
ok "Installed to $DEST/$APP_NAME.app"

open "$DEST/$APP_NAME.app"
ok "Launched! Look for the Mole window and the hare in the menu bar."
