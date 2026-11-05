#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for tool in bash stow; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Error: $tool is required to run the Oh My Zsh custom tests." >&2
    exit 1
  fi
done

TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-omz.XXXXXX")"
trap 'rm -r -- "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

create_fixture() {
  TEST_HOME="$TEST_ROOT/$1 home"
  FIXTURE="$TEST_HOME/code/dotfiles"
  CUSTOM="$TEST_HOME/.oh-my-zsh/custom"
  mkdir -p "$FIXTURE"/{git,zsh,shell,config,agents,scripts}
  cp "$REPO_DIR/install" "$REPO_DIR/install-in-devcontainer" "$FIXTURE/"
  cp "$REPO_DIR/scripts/ensure-bash-aliases.sh" "$FIXTURE/scripts/"
  cp -R "$REPO_DIR/omz" "$FIXTURE/"
  printf 'alias dotfiles_omz_test=true\n' > "$FIXTURE/omz/.oh-my-zsh/custom/dotfiles-test.zsh"
  mkdir -p "$FIXTURE/omz/.oh-my-zsh/custom/plugins/dotfiles-test"
  printf '# plugin\n' > "$FIXTURE/omz/.oh-my-zsh/custom/plugins/dotfiles-test/dotfiles-test.plugin.zsh"
  printf 'export REPO_SECRET=1\n' > "$FIXTURE/omz/.oh-my-zsh/custom/secrets.zsh"
  # Simulate an existing Oh My Zsh install with a manually created secrets file.
  mkdir -p "$CUSTOM/plugins"
  printf 'export LOCAL_SECRET=1\n' > "$CUSTOM/secrets.zsh"
}

run_installer() {
  if ! HOME="$TEST_HOME" bash "$FIXTURE/$1" > "$TEST_ROOT/install.log" 2>&1; then
    cat "$TEST_ROOT/install.log" >&2
    fail "$1 failed"
  fi
}

for installer in install install-in-devcontainer; do
  create_fixture "$installer"
  run_installer "$installer"
  run_installer "$installer"
  [ "$CUSTOM/dotfiles-test.zsh" -ef "$FIXTURE/omz/.oh-my-zsh/custom/dotfiles-test.zsh" ] \
    || fail "$installer did not link custom file"
  [ "$CUSTOM/plugins/dotfiles-test/dotfiles-test.plugin.zsh" -ef \
    "$FIXTURE/omz/.oh-my-zsh/custom/plugins/dotfiles-test/dotfiles-test.plugin.zsh" ] \
    || fail "$installer did not link custom plugin"
  [ -f "$CUSTOM/secrets.zsh" ] && [ ! -L "$CUSTOM/secrets.zsh" ] \
    || fail "$installer replaced secrets.zsh"
  grep -Fx 'export LOCAL_SECRET=1' "$CUSTOM/secrets.zsh" >/dev/null \
    || fail "$installer changed secrets.zsh"
  [ ! -e "$CUSTOM/.gitignore" ] && [ ! -L "$CUSTOM/.gitignore" ] \
    || fail "$installer linked package .gitignore"
  [ ! -e "$TEST_HOME/.dotfiles-backup" ] || fail "$installer created backups"
done

# Without Oh My Zsh, the container installer must not create ~/.oh-my-zsh,
# which would stop the Oh My Zsh installer from running later.
create_fixture container-without-omz
rm -r "$TEST_HOME/.oh-my-zsh"
run_installer install-in-devcontainer
[ ! -e "$TEST_HOME/.oh-my-zsh" ] || fail "Container installer created ~/.oh-my-zsh"

echo "Oh My Zsh custom tests passed."
