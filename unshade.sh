#!/usr/bin/env bash
set -e

VDF="$HOME/.steam/steam/config/libraryfolders.vdf"

if [[ ! -f "$VDF" ]]; then
  kdialog --error "Could not find Steam library config at:\n$VDF\n\nIs Steam installed?" --title "UnShade"
  exit 1
fi

# Parse all library paths from VDF
mapfile -t LIBRARIES < <(grep '"path"' "$VDF" | sed 's/.*"path"[[:space:]]*"\(.*\)"/\1/')

if [[ ${#LIBRARIES[@]} -eq 0 ]]; then
  kdialog --error "No Steam libraries found in libraryfolders.vdf." --title "UnShade"
  exit 1
fi

# Checklist — zenity with proper checkboxes
SELECTED=$(zenity --list --checklist \
  --title="UnShade" \
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
  kdialog --msgbox "Nothing selected. No caches were cleared." --title "UnShade"
  exit 0
fi

# Build library list for confirmation
LIB_LIST=""
for lib in "${LIBRARIES[@]}"; do
  LIB_LIST+="\n  • $lib/steamapps"
done

kdialog --yesno "Confirm: clear selected caches across ${#LIBRARIES[@]} Steam library/libraries?$LIB_LIST" \
  --title "UnShade" || exit 0

# Track what was actually cleared
CLEARED=()

# Mesa driver cache — respect MESA_SHADER_CACHE_DIR if set
if [[ "$SELECTED" == *"mesa"* ]]; then
  MESA_DIR="${MESA_SHADER_CACHE_DIR:-$HOME/.cache/mesa_shader_cache}"
  if [[ -d "$MESA_DIR" ]]; then
    \rm -r "$MESA_DIR" 2>/dev/null && CLEARED+=("Mesa driver cache")
  fi
fi

# Per-library caches
for lib in "${LIBRARIES[@]}"; do
  SP="$lib/steamapps"
  [[ -d "$SP" ]] || continue

  if [[ "$SELECTED" == *"steam"* ]]; then
    if [[ -d "$SP/shadercache/" ]]; then
      \rm -r "$SP/shadercache/" 2>/dev/null && CLEARED+=("Steam shader pre-cache ($SP)")
    fi
  fi

  if [[ "$SELECTED" == *"dxvk"* ]]; then
    find "$SP" -name "*.dxvk-cache" -delete 2>/dev/null && CLEARED+=("DXVK cache ($SP)")
    [[ -d "$SP/compatdata/" ]] && find "$SP/compatdata/" -name "*.dxvk-cache" -delete 2>/dev/null
  fi

  if [[ "$SELECTED" == *"vkd3d"* ]]; then
    find "$SP" -name "*.vkd3d-cache" -delete 2>/dev/null && CLEARED+=("VKD3D-Proton cache ($SP)")
    [[ -d "$SP/compatdata/" ]] && find "$SP/compatdata/" -name "*.vkd3d-cache" -delete 2>/dev/null
  fi
done

# OpenGL shader cache
if [[ "$SELECTED" == *"gl"* ]]; then
  if [[ -d "$HOME/.cache/nvidia/GLCache/" ]]; then
    \rm -r "$HOME/.cache/nvidia/GLCache/" 2>/dev/null && CLEARED+=("OpenGL cache (NVIDIA)")
  fi
  if [[ -d "$HOME/.cache/radeon/" ]]; then
    \rm -r "$HOME/.cache/radeon/" 2>/dev/null && CLEARED+=("OpenGL cache (Radeon)")
  fi
fi

# Build result message from what actually got cleared
if [[ ${#CLEARED[@]} -eq 0 ]]; then
  kdialog --msgbox "Nothing was cleared — selected caches may not have existed." --title "UnShade"
else
  RESULT="✓ Cleared:\n"
  for item in "${CLEARED[@]}"; do
    RESULT+="\n  • $item"
  done
  kdialog --msgbox "$RESULT" --title "UnShade"
fi
