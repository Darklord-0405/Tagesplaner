#!/bin/bash
# Baut "Tagesplaner.app" für den Mac – ohne App Store und ohne Xcode-Projekt.
# Beendet vorher die alte Version, entfernt veraltete Kopien und startet die neue App.
cd "$(dirname "$0")" || exit 1

APP_NAME="Tagesplaner"
EXE="Tagesplaner"
BUNDLE_ID="com.example.tagesplaner"
SRC_DIR="Tagesplaner.swiftpm"

pause() { read -n 1 -s -r -p "Taste drücken zum Beenden ..."; echo; }

if ! command -v swiftc >/dev/null 2>&1; then
  echo "Swift wurde nicht gefunden. Installiere zuerst die kostenlosen Entwicklerwerkzeuge von Apple:"
  echo "    xcode-select --install"
  echo "Danach dieses Skript noch einmal starten."
  pause
  exit 1
fi

# 1. Laufende alte Version beenden, sonst würde sie einfach wieder nach vorne geholt
osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1
pkill -x "$EXE" >/dev/null 2>&1
sleep 1

# 2. Alte gebaute Version in diesem Ordner entfernen – so kann nichts Veraltetes liegen bleiben
rm -rf "./$APP_NAME.app"

ARCH="$(uname -m)"
OUT="build"
APP="$OUT/$APP_NAME.app"
rm -rf "$OUT"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

SOURCES=()
while IFS= read -r f; do SOURCES+=("$f"); done < <(find "$SRC_DIR" -name '*.swift' ! -name 'Package.swift')

echo "Kompiliere für $ARCH ..."
if ! swiftc -O -parse-as-library -target "${ARCH}-apple-macos13.0" "${SOURCES[@]}" -o "$APP/Contents/MacOS/$EXE"; then
  echo
  echo "=============================================================="
  echo " FEHLER: Es wurde KEINE neue App erstellt."
  echo " Bitte die Meldung oben kopieren und weitergeben."
  echo "=============================================================="
  pause
  exit 1
fi

# Icon (optional)
if [ -f Icon.png ] && command -v iconutil >/dev/null 2>&1 && command -v sips >/dev/null 2>&1; then
  ICONSET="$OUT/AppIcon.iconset"
  mkdir -p "$ICONSET"
  for s in 16 32 128 256 512; do
    sips -z $s $s Icon.png --out "$ICONSET/icon_${s}x${s}.png" >/dev/null 2>&1
    sips -z $((s*2)) $((s*2)) Icon.png --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null 2>&1
  done
  iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns" >/dev/null 2>&1 || true
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>$APP_NAME</string>
  <key>CFBundleExecutable</key><string>$EXE</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>3.0</string>
  <key>CFBundleVersion</key><string>3</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

# Lokal signieren, damit macOS die App starten lässt
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

mv "$APP" "./$APP_NAME.app"
rm -rf "$OUT"

# 3. Bereits installierte alte Kopien in "Programme" durch die neue Version ersetzen
for dir in "/Applications" "$HOME/Applications"; do
  if [ -d "$dir/$APP_NAME.app" ]; then
    if rm -rf "$dir/$APP_NAME.app" 2>/dev/null && cp -R "./$APP_NAME.app" "$dir/" 2>/dev/null; then
      echo "Aktualisiert: $dir/$APP_NAME.app"
    else
      echo "Hinweis: $dir/$APP_NAME.app konnte nicht ersetzt werden. Bitte löschen und die neue App hineinziehen."
    fi
  fi
done

echo
echo "=============================================================="
echo " Fertig! Neue Version erstellt:"
echo " $(pwd)/$APP_NAME.app"
echo " Im Fenstertitel steht „$APP_NAME – Version 3“."
echo "=============================================================="
echo "Falls im Dock noch das alte Symbol liegt: mit der rechten Maustaste"
echo "„Optionen → Aus dem Dock entfernen“ und die neue App neu ins Dock ziehen."
open "./$APP_NAME.app" 2>/dev/null || true
pause
