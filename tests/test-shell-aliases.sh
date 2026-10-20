#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for tool in bash zsh stow; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Error: $tool is required to run the shell aliases tests." >&2
    exit 1
  fi
done

TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-aliases.XXXXXX")"
trap 'rm -r -- "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

create_fixture() {
  TEST_HOME="$TEST_ROOT/$1 home"
  FIXTURE="$TEST_HOME/code/dotfiles"
  mkdir -p "$FIXTURE"/{git,zsh,shell,config,agents,scripts}
  cp "$REPO_DIR/install" "$REPO_DIR/install-in-devcontainer" "$FIXTURE/"
  cp "$REPO_DIR/scripts/ensure-bash-aliases.sh" "$FIXTURE/scripts/"
  cp "$REPO_DIR/zsh/.zshrc" "$FIXTURE/zsh/"
  cp "$REPO_DIR/shell/.aliases" "$FIXTURE/shell/"
  printf '\nalias dotfiles_test_alias="printf shared-alias"\n' >> "$FIXTURE/shell/.aliases"
  printf '# Fixture git configuration\n' > "$FIXTURE/git/.gitconfig"
  mkdir -p "$TEST_HOME/.oh-my-zsh"
  printf 'alias dotfiles_test_alias="printf plugin-alias"\n' \
    > "$TEST_HOME/.oh-my-zsh/oh-my-zsh.sh"
}

run_installer() {
  HOME="$TEST_HOME" bash "$FIXTURE/$1" > "$TEST_ROOT/install.log" 2>&1
}

install_successfully() {
  if ! run_installer "$1"; then
    cat "$TEST_ROOT/install.log" >&2
    fail "$1 failed"
  fi
}

assert_shells() {
  local expected="$1"
  local expression="$2"
  local output
  if ! output="$(HOME="$TEST_HOME" bash --noprofile --rcfile "$TEST_HOME/.bashrc" -ic "$expression" 2>"$TEST_ROOT/bash.log")"; then
    cat "$TEST_ROOT/bash.log" >&2
    fail "Bash startup failed"
  fi
  [ "$output" = "$expected" ] || fail "Bash output: $output"
  if ! output="$(HOME="$TEST_HOME" ZDOTDIR="$TEST_HOME" zsh -i -c "$expression" 2>"$TEST_ROOT/zsh.log")"; then
    cat "$TEST_ROOT/zsh.log" >&2
    fail "zsh startup failed"
  fi
  [ "$output" = "$expected" ] || fail "zsh output: $output"
}

for installer in install install-in-devcontainer; do
  create_fixture "$installer"
  printf '# Existing configuration without a trailing newline' > "$TEST_HOME/.bashrc"
  cp "$TEST_HOME/.bashrc" "$TEST_ROOT/original-bashrc"
  install_successfully "$installer"
  [ -L "$TEST_HOME/.aliases" ] || fail "$installer did not link aliases"
  [ "$TEST_HOME/.aliases" -ef "$FIXTURE/shell/.aliases" ] || fail "Wrong aliases target"
  [ "$TEST_HOME/.gitconfig" -ef "$FIXTURE/git/.gitconfig" ] || fail "Existing package not linked"
  head -c "$(wc -c < "$TEST_ROOT/original-bashrc")" "$TEST_HOME/.bashrc" \
    | cmp - "$TEST_ROOT/original-bashrc" || fail "Existing .bashrc content changed"
  [ "$(grep -Fxc '# Dotfiles shared aliases.' "$TEST_HOME/.bashrc")" = 1 ] \
    || fail "Expected one loader"
  assert_shells shared-alias dotfiles_test_alias
  cp "$TEST_HOME/.bashrc" "$TEST_ROOT/installed-bashrc"
  install_successfully "$installer"
  cmp "$TEST_ROOT/installed-bashrc" "$TEST_HOME/.bashrc" || fail "Repeat install changed .bashrc"
  [ ! -e "$TEST_HOME/.dotfiles-backup" ] || fail "Repeat install created backups"

  rm "$FIXTURE/shell/.aliases"
  assert_shells missing-ok 'printf missing-ok'
  if grep -F '.aliases' "$TEST_ROOT/bash.log" "$TEST_ROOT/zsh.log"; then
    fail "Missing aliases file produced a startup error"
  fi

  create_fixture "$installer-missing-bashrc"
  install_successfully "$installer"
  [ -f "$TEST_HOME/.bashrc" ] || fail "Missing .bashrc was not created"
  assert_shells shared-alias dotfiles_test_alias

  create_fixture "$installer-symlink-bashrc"
  printf '# Existing symlink target\n' > "$TEST_HOME/bashrc-target"
  ln -s bashrc-target "$TEST_HOME/.bashrc"
  install_successfully "$installer"
  [ "$(readlink "$TEST_HOME/.bashrc")" = bashrc-target ] || fail ".bashrc symlink changed"
  grep -Fx '# Existing symlink target' "$TEST_HOME/bashrc-target" >/dev/null \
    || fail "Symlink target content lost"
  assert_shells shared-alias dotfiles_test_alias

  for invalid in directory dangling; do
    create_fixture "$installer-$invalid-bashrc"
    if [ "$invalid" = directory ]; then
      mkdir "$TEST_HOME/.bashrc"
    else
      ln -s missing-target "$TEST_HOME/.bashrc"
    fi
    if run_installer "$installer"; then
      fail "$installer accepted $invalid .bashrc"
    fi
    grep -F 'must be a regular file or a symlink to one' "$TEST_ROOT/install.log" >/dev/null \
      || fail "Missing invalid-path error"
    if grep -F 'successfully' "$TEST_ROOT/install.log" >/dev/null; then
      fail "Installer reported success after failing"
    fi
  done
done

create_fixture host-conflict
printf '# Existing aliases\n' > "$TEST_HOME/.aliases"
printf '# Existing Bash configuration\n' > "$TEST_HOME/.bashrc"
cp "$TEST_HOME/.bashrc" "$TEST_ROOT/conflict-bashrc"
if run_installer install; then
  fail "Host installer accepted an unmanaged aliases file"
fi
cmp "$TEST_ROOT/conflict-bashrc" "$TEST_HOME/.bashrc" || fail "Stow failure changed .bashrc"
[ ! -L "$TEST_HOME/.aliases" ] || fail "Stow replaced conflicting aliases"

create_fixture container-conflict
printf '# Existing aliases\n' > "$TEST_HOME/.aliases"
cp "$TEST_HOME/.aliases" "$TEST_ROOT/original-aliases"
install_successfully install-in-devcontainer
backups=("$TEST_HOME"/.dotfiles-backup/*/.aliases)
[ "${#backups[@]}" -eq 1 ] || fail "Expected one aliases backup"
cmp "$TEST_ROOT/original-aliases" "${backups[0]}" || fail "Aliases backup changed"
install_successfully install-in-devcontainer
backup_dirs=("$TEST_HOME"/.dotfiles-backup/*)
[ "${#backup_dirs[@]}" -eq 1 ] || fail "Repeat install created another backup"
assert_shells shared-alias dotfiles_test_alias

echo "Shell aliases tests passed."
