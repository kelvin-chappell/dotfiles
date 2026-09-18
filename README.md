# Dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level
folder is a Stow "package" whose contents mirror the home directory:

- `git/` -> `~/.gitconfig`, `~/.gitignore_global`
- `zsh/` -> `~/.zshrc`
- `config/` -> `~/.config/...` (for example `devenv`, `mise`)
- `agents/` -> `~/.copilot/agents/...` (global custom agents)

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

This runs `stow --restow`, which refreshes the `git`, `zsh`, `config`, and
`agents` symlinks without adopting existing files into the repo. Stow stops if
a real file conflicts with a managed path, so move that file aside before
running the installer again.

The custom Playwright agents are installed globally under
`~/.copilot/agents`, making them available across repositories.

## Dev containers

For dev containers, use `install-devcontainer.sh` instead of `install.sh`.
It copies the portable packages (`git`, `zsh`, `config`, `agents`) into the
container without requiring Stow. Existing regular files at managed paths are
moved under `~/.dotfiles-backup/<timestamp>/` before copying, and the macOS-only
`brew/` package is skipped.

If you use the VS Code dotfiles feature, point it at this repo and set the
install command:

```jsonc
{
  "dotfiles.repository": "kelvin-chappell/dotfiles",
  "dotfiles.installCommand": "bash ./install-devcontainer.sh"
}
```

## Usage

- Adding a new skill in a dev container:
  ```sh
  mv "$HOME/.agents" "$HOME/dotfiles/agents/.agents"
  stow --restow \
   --target="$HOME" \
   --dir="$HOME/code/dotfiles" \
   agents
  ```

- TODO: Adding a new agent:
  ```sh
  stow --restow \
   --target="$HOME" \
   --dir="$HOME/code/dotfiles" \
   agents
  ```
  
- Refresh symlinks after adding or moving files:

  ```sh
  stow --restow --target="$HOME" git zsh config agents
  ```

- Remove a package's symlinks:

  ```sh
  stow -D --target="$HOME" <package>
  ```
