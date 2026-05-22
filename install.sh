#!/usr/bin/env bash
set -e

INSTALL_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"
BASE_URL="https://raw.githubusercontent.com/andy10115/unshade/main"

echo "Installing UnShade..."

mkdir -p "$INSTALL_DIR" "$DESKTOP_DIR" "$ICON_DIR"

curl -fsSL "$BASE_URL/unshade.sh" -o "$INSTALL_DIR/unshade.sh"
chmod +x "$INSTALL_DIR/unshade.sh"

curl -fsSL "$BASE_URL/UnShade.svg" -o "$ICON_DIR/unshade.svg"

cat > "$DESKTOP_DIR/unshade.desktop" << EOF
[Desktop Entry]
Name=UnShade
Comment=Clear Linux gaming shader caches
Exec=$INSTALL_DIR/unshade.sh
Icon=$ICON_DIR/unshade.svg
Terminal=false
Type=Application
Categories=Game;Utility;
EOF

echo "✓ UnShade installed. Search for 'UnShade' in your app menu."
