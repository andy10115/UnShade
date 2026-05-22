#!/usr/bin/env bash
set -e

INSTALL_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"
BASE_URL="https://raw.githubusercontent.com/andy10115/UnShade/main"

# Dependency check
MISSING=()
for cmd in zenity kdialog; do
  command -v "$cmd" &>/dev/null || MISSING+=("$cmd")
done
 
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "✗ UnShade requires the following dependencies that were not found:"
  for dep in "${MISSING[@]}"; do
    echo "    - $dep"
  done
  echo ""
  echo "  Please use your distro's package manager to install them and try again."
  exit 1
fi

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
