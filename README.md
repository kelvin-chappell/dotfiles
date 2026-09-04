# Dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level
folder is a Stow "package" whose contents mirror the home directory:

- `git/` -> `~/.gitconfig`, `~/.gitignore_global`
- `zsh/` -> `~/.zshrc`
- `config/` -> `~/.config/...` (for example `devenv`, `mise`)

The `brew/` folder holds a `Brewfile` and is intentionally not symlinked.

## Prerequisites

Install Stow (and everything else) via Homebrew:

```sh
brew bundle --file=brew/Brewfile
```

## Install

```sh
./install.sh
```

This runs `stow --adopt`, which pulls any existing real files in `~` into the
repo so nothing is lost. Review what was adopted and revert anything unwanted:

```sh
git diff
git checkout -- <path>   # discard an unwanted overwrite
```

## Dev containers

For dev containers, use `install-devcontainer.sh` instead of `install.sh`. 

We don't bother installing `stow` and the macOS-only `brew` package is skipped.

## Usage

- Refresh symlinks after adding or moving files:

  ```sh
  stow --restow --target="$HOME" git zsh config
  ```

- Remove a package's symlinks:

  ```sh
  stow -D --target="$HOME" <package>
  ```
