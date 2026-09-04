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

# Switch the default shell to zsh.
# The copy step above only installs the zsh config files (e.g. ~/.zshrc); it
# does not install the zsh binary or change the login shell. Do that here so
# containers use zsh instead of continuing to default to bash.

# Use sudo when available (many containers run as a non-root user).
if command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  SUDO=""
fi

# Ensure the zsh binary is installed.
if ! command -v zsh >/dev/null 2>&1; then
  echo "zsh not found; attempting to install it..."
  if command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get update && $SUDO apt-get install -y zsh
  elif command -v apk >/dev/null 2>&1; then
    $SUDO apk add --no-cache zsh
  elif command -v dnf >/dev/null 2>&1; then
    $SUDO dnf install -y zsh
  elif command -v yum >/dev/null 2>&1; then
    $SUDO yum install -y zsh
  else
    echo "No supported package manager found; cannot install zsh." >&2
  fi
fi

# Set zsh as the login shell, if it is available.
if command -v zsh >/dev/null 2>&1; then
  ZSH_PATH="$(command -v zsh)"

  # zsh must be listed in /etc/shells for chsh to accept it.
  if ! grep -qxF "$ZSH_PATH" /etc/shells 2>/dev/null; then
    echo "$ZSH_PATH" | $SUDO tee -a /etc/shells >/dev/null || \
      echo "Could not add $ZSH_PATH to /etc/shells." >&2
  fi

  # Change the login shell for the current user.
  if command -v chsh >/dev/null 2>&1; then
    if $SUDO chsh -s "$ZSH_PATH" "$(whoami)" 2>/dev/null; then
      echo "Default shell changed to zsh ($ZSH_PATH)."
    else
      echo "Could not change login shell via chsh (may need different perms)." >&2
    fi
  else
    echo "chsh not available; leaving login shell unchanged." >&2
  fi
else
  echo "zsh is not installed; keeping current shell." >&2
fi

# Install a curated set of Matt Pocock's skills into the *personal* skills
# location (shared across all projects) rather than into this repo.
# Runs non-interactively so it works as a devcontainer command.
# Pinned to skills 1.5.23 so npx can cache it instead of re-resolving @latest
# over the network on every container create.
if command -v npx >/dev/null 2>&1; then
  echo "Installing selected skills into the personal skills location..."

  # The skills you want.
  SKILLS="code-review,codebase-design,diagnosing-bugs,domain-modeling,grill-with-docs,implement,improve-codebase-architecture,prototype,research,resolving-merge-conflicts,tdd,wayfinder,grill-me,grilling"

  # --global installs to the personal (home) location instead of the project.
  # --yes skips confirmation prompts so the command never blocks on input.
  npx skills@1.5.23 add mattpocock/skills \
    --skill "$SKILLS" \
    --global \
    --yes \
    || echo "Skill installation failed; continuing." >&2
else
  echo "npx not found; skipping skills installation." >&2
fi
