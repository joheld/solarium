#!/usr/bin/env bash
# ==============================================================================
# Script de compilación para Solarium Widget (macOS Native Swift)
# Arquitectura: Apple Silicon ARM64
# Zero dependencias externas • AppKit / Cocoa Nativo
# ==============================================================================
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Solarium Widget.app"
APP_DIR="$DIR/$APP_NAME"
DESKTOP_APP="$HOME/Desktop/$APP_NAME"

echo "🔨 Compilando $APP_NAME en Swift para Apple Silicon..."

mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cat << 'EOF' > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>es</string>
    <key>CFBundleExecutable</key>
    <string>Solarium Widget</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.solarium.widget</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Solarium Widget</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

if [ -f "$DIR/solarium.icns" ]; then
    cp "$DIR/solarium.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

swiftc -O "$DIR/macos-widget/main.swift" \
       -o "$APP_DIR/Contents/MacOS/Solarium Widget" \
       -target arm64-apple-macos13.0

codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true

# Copiar a Desktop
rm -rf "$DESKTOP_APP"
cp -R "$APP_DIR" "$DESKTOP_APP"
touch "$DESKTOP_APP"

echo "✅ $APP_NAME compilado con éxito."
echo "📁 Ubicación local: $APP_DIR"
echo "🖥️ Ubicación escritorio: $DESKTOP_APP"
