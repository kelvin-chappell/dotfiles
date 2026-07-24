#!/usr/bin/env bash
set -euo pipefail

# Dev container dotfiles installer.
# Intended to run as a devcontainer.json "postCreateCommand" (or
# "updateContentCommand"). Unlike install.sh, this resolves the repo location
# from the script itself rather than assuming ~/code/dotfiles, installs stow via
# the container's package manager when missing, and uses --restow so repeated
# post-create runs stay idempotent.

# Resolve the directory containing this script, following symlinks.
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SCRIPT_SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" >/dev/null 2>&1 && pwd)"
  SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
  [[ "$SCRIPT_SOURCE" != /* ]] && SCRIPT_SOURCE="$DIR/$SCRIPT_SOURCE"
done
DOTFILES_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" >/dev/null 2>&1 && pwd)"

# Portable packages only. The brew package is macOS-only and is never stowed.
PACKAGES=(git zsh config)

# Install stow using whichever package manager the container provides.
install_stow() {
  echo "stow not found; attempting to install it..."

  # Use sudo only when not already root and sudo is available. A command array
  # avoids word-splitting/globbing on an empty or multi-word prefix (SC2086).
  local sudo_cmd=()
  if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
    sudo_cmd=(sudo)
  fi

  if command -v apt-get >/dev/null 2>&1; then
    # Avoid interactive prompts on Debian/Ubuntu bases and skip recommended
    # extras to keep the container lean.
    "${sudo_cmd[@]}" env DEBIAN_FRONTEND=noninteractive apt-get update
    "${sudo_cmd[@]}" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends stow
  elif command -v apk >/dev/null 2>&1; then
    "${sudo_cmd[@]}" apk add --no-cache stow
  elif command -v dnf >/dev/null 2>&1; then
    "${sudo_cmd[@]}" dnf install -y stow
  elif command -v yum >/dev/null 2>&1; then
    "${sudo_cmd[@]}" yum install -y stow
  else
    echo "Error: could not find a supported package manager to install stow." >&2
    echo "Install GNU Stow manually, then re-run this script." >&2
    exit 1
  fi
}

if ! command -v stow >/dev/null 2>&1; then
  install_stow
fi

# --restow refreshes symlinks without adopting container defaults into the repo,
# keeping the operation safe to run on every container (re)build.
stow --restow --target="$HOME" --dir="$DOTFILES_DIR" "${PACKAGES[@]}"

echo "Dotfiles stowed into $HOME successfully."
