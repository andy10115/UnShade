#!/usr/bin/env bash
set -e

VDF="$HOME/.steam/steam/config/libraryfolders.vdf"

if [[ ! -f "$VDF" ]]; then
  kdialog --error "Could not find Steam library config at:\n$VDF\n\nIs Steam installed?" --title "Shader Cache Cleaner"
  exit 1
fi

# Parse all library paths from VDF
mapfile -t LIBRARIES < <(grep '"path"' "$VDF" | sed 's/.*"path"[[:space:]]*"\(.*\)"/\1/')

if [[ ${#LIBRARIES[@]} -eq 0 ]]; then
  kdialog --error "No Steam libraries found in libraryfolders.vdf." --title "Shader Cache Cleaner"
  exit 1
fi

# Checklist — zenity with proper checkboxes
SELECTED=$(zenity --list --checklist \
  --title="Shader Cache Cleaner" \
  --text="Select shader caches to clear:" \
  --column="" --column="tag" --column="Available Cache" \
  --hide-column=2 \
  --print-column=2 \
  --height=400 \
  TRUE  "mesa"   "Mesa driver cache" \
  TRUE  "steam"  "Steam shader pre-cache" \
  TRUE  "dxvk"   "DXVK state cache" \
  TRUE  "vkd3d"  "VKD3D-Proton pipeline cache" \
  TRUE  "gl"     "OpenGL shader cache" \
  --separator=" ") || exit 0

# Nothing checked
if [[ -z "$SELECTED" ]]; then
  kdialog --msgbox "Nothing selected. No caches were cleared." --title "Shader Cache Cleaner"
  exit 0
fi

# Build library list for confirmation
LIB_LIST=""
for lib in "${LIBRARIES[@]}"; do
  LIB_LIST+="\n  • $lib/steamapps"
done

kdialog --yesno "Confirm: clear selected caches across ${#LIBRARIES[@]} Steam library/libraries?$LIB_LIST" \
  --title "Shader Cache Cleaner" || exit 0

# Mesa driver cache
if [[ "$SELECTED" == *"mesa"* ]]; then
  rm -rf ~/.cache/mesa_shader_cache/
fi

# Per-library caches
for lib in "${LIBRARIES[@]}"; do
  SP="$lib/steamapps"
  [[ -d "$SP" ]] || continue

  if [[ "$SELECTED" == *"steam"* ]]; then
    rm -rf "$SP/shadercache/"
  fi

  if [[ "$SELECTED" == *"dxvk"* ]]; then
    find "$SP" -name "*.dxvk-cache" -delete
    [[ -d "$SP/compatdata/" ]] && find "$SP/compatdata/" -name "*.dxvk-cache" -delete
  fi

  if [[ "$SELECTED" == *"vkd3d"* ]]; then
    find "$SP" -name "*.vkd3d-cache" -delete
    [[ -d "$SP/compatdata/" ]] && find "$SP/compatdata/" -name "*.vkd3d-cache" -delete
  fi
done

if [[ "$SELECTED" == *"gl"* ]]; then
  rm -rf ~/.cache/nvidia/GLCache/
  rm -rf ~/.cache/radeon/
fi

kdialog --msgbox "✓ Selected caches cleared across ${#LIBRARIES[@]} Steam library/libraries." --title "Shader Cache Cleaner"
