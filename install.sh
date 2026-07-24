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

# First run: --adopt pulls any existing real files in $HOME into the repo so
# they can be reviewed with 'git diff' before committing.
# On subsequent runs, replace --adopt with --restow to refresh symlinks.
stow --adopt --target="$HOME" --dir="$DOTFILES_DIR" "${PACKAGES[@]}"

echo "Dotfiles stowed successfully!"
echo "Review adopted changes with 'git -C \"$DOTFILES_DIR\" diff' and revert unwanted overwrites with 'git checkout'."
