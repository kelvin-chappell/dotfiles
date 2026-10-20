ensure_bash_aliases() {
  local bashrc="$HOME/.bashrc"
  local marker="# Dotfiles shared aliases."
  local status

  if [ -e "$bashrc" ] || [ -L "$bashrc" ]; then
    if [ ! -f "$bashrc" ]; then
      echo "Error: $bashrc must be a regular file or a symlink to one." >&2
      return 1
    fi

    if grep -Fx "$marker" "$bashrc" >/dev/null; then
      return 0
    else
      status=$?
      if [ "$status" -ne 1 ]; then
        echo "Error: could not read $bashrc." >&2
        return "$status"
      fi
    fi
  fi

  if ! printf '\n%s\n' \
    "$marker" \
    'if [ -f "$HOME/.aliases" ]; then' \
    '  . "$HOME/.aliases"' \
    'fi' >> "$bashrc"; then
    echo "Error: could not add the aliases loader to $bashrc." >&2
    return 1
  fi
}
