#!/usr/bin/env bash
set -euo pipefail

# Dev container dotfiles installer.
# Copies the dotfiles from the portable packages in this repo into $HOME,
# backing up any pre-existing files before overwriting them. Intended to run as
# a devcontainer.json "postCreateCommand" (or "updateContentCommand").

# Resolve the directory containing this script.
DOTFILES_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Portable packages only. The brew package is macOS-only and is never copied.
PACKAGES=(git zsh config)

# Backup location for any files we replace.
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

for pkg in "${PACKAGES[@]}"; do
  pkg_dir="$DOTFILES_DIR/$pkg"
  [ -d "$pkg_dir" ] || continue

  while IFS= read -r -d '' file; do
    rel="${file#"$pkg_dir"/}"
    target="$HOME/$rel"

    # Back up an existing regular file (not a symlink) before overwriting it.
    if [ -f "$target" ] && [ ! -L "$target" ]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      mv "$target" "$BACKUP_DIR/$rel"
      echo "Backed up existing $target -> $BACKUP_DIR/$rel"
    fi

    mkdir -p "$(dirname "$target")"
    cp "$file" "$target"
  done < <(find "$pkg_dir" -type f -print0)
done

echo "Dotfiles copied into $HOME successfully."
if [ -d "$BACKUP_DIR" ]; then
  echo "Any replaced files were backed up under $BACKUP_DIR."
fi
