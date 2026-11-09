#!/usr/bin/env bash
set -e
echo '🚀 Starting Flutter Project: Flutter Snake Game...'
if ! command -v flutter >/dev/null 2>&1; then
    for cand in "$HOME/flutter/bin" "$HOME/development/flutter/bin" "$HOME/.flutter/bin" "/snap/bin" "/opt/flutter/bin"; do
        if [ -x "$cand/flutter" ]; then
            export PATH="$cand:$PATH"
            break
        fi
    done
fi
if ! command -v flutter >/dev/null 2>&1; then
    echo '❌ Flutter SDK not found in PATH.'
    echo '💡 If installed, add it to your PATH: export PATH="$HOME/flutter/bin:$PATH"'
    echo '   Or install from https://flutter.dev/docs/get-started/install'
    exit 1
fi
echo '📦 Fetching Flutter dependencies...'
if [ ! -d "web" ] && [ ! -d "linux" ] && [ ! -d "android" ] && [ ! -d "windows" ] && [ ! -d "macos" ]; then
    echo '📱 Generating native platform targets (web, desktop, mobile)...'
    flutter create . --suppress-analytics
fi
flutter pub get
echo '⚡ Launching Flutter App...'
flutter run -d chrome || flutter run
