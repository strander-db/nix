# Idempotently add Privacy exclusions so Spotlight mainly indexes Applications.
# Leaves /Applications, /System/Applications, and ~/Applications searchable
# (including Home Manager Apps). Skip missing paths.
set -euo pipefail

PLIST="/System/Volumes/Data/.Spotlight-V100/VolumeConfiguration.plist"
BUDDY=/usr/libexec/PlistBuddy
HOME_DIR="${1:-$HOME}"

STATIC_PATHS=(
  /nix
  /Library
  /System/Library
  "${HOME_DIR}/Library"
  "${HOME_DIR}/Documents"
  "${HOME_DIR}/Downloads"
  "${HOME_DIR}/Desktop"
  "${HOME_DIR}/Movies"
  "${HOME_DIR}/Music"
  "${HOME_DIR}/Pictures"
  "${HOME_DIR}/Public"
  "${HOME_DIR}/.cache"
  "${HOME_DIR}/.local"
  "${HOME_DIR}/.config"
  "${HOME_DIR}/.Trash"
)

if [[ ! -f "$PLIST" ]]; then
  echo "spotlight-exclusions: $PLIST not found; skipping"
  exit 0
fi

existing="$("$BUDDY" -c "Print :Exclusions" "$PLIST" 2>/dev/null || true)"

already_excluded() {
  local path="$1"
  printf '%s\n' "$existing" | grep -Fxq "    $path" || printf '%s\n' "$existing" | grep -Fxq "$path"
}

add_exclusion() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    return 0
  fi
  if already_excluded "$path"; then
    return 0
  fi
  echo "spotlight-exclusions: adding $path"
  "$BUDDY" -c "Add :Exclusions: string $path" "$PLIST"
  existing="${existing}"$'\n'"    ${path}"
}

for path in "${STATIC_PATHS[@]}"; do
  add_exclusion "$path"
done

echo "spotlight-exclusions: done"
