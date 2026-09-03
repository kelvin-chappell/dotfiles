#!/bin/bash
set -euo pipefail

# Manage dotfiles with GNU Stow.
# Each top-level folder here is a Stow "package" whose contents mirror $HOME.
# The brew package is intentionally excluded (repo-only, not symlinked).

DOTFILES_DIR="$HOME/code/dotfiles"
PACKAGES=(git zsh config)

if ! command -v stow >/dev/null 2>&1; then
  echo "Error: stow is not installed. Install it first, e.g. 'brew bundle --file=brew/Brewfile'." >&2
  exit 1
fi

# Refresh symlinks. --restow cleanly removes and re-creates links, which is safe
# to run repeatedly. For a first-time setup on a new machine with pre-existing
# real files in $HOME, temporarily switch --restow to --adopt to pull those
# files into the repo, review with 'git diff', then switch back.
stow --restow --target="$HOME" --dir="$DOTFILES_DIR" "${PACKAGES[@]}"

echo "Dotfiles stowed successfully!"
