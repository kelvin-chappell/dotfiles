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

- Adding a new global skill from a dev container:

  ```sh
  sudo apt install stow
  mv "$HOME/.agents/*" "$HOME/dotfiles/agents/.agents"
  stow --restow \
   --target="$HOME" \
   --dir="$HOME/code/dotfiles" \
   agents
  ```

- Adding a third-party skill:

  ```sh
  cd "$HOME/code/dotfiles/agents"
  NODE_DIR="$(dirname "$(node -p 'process.execPath')")"
  HOME="$PWD" XDG_STATE_HOME= npm_config_cache="${TMPDIR:-/tmp}/dotfiles-skills-npm-cache" \
    PATH="$NODE_DIR:$PATH" "$NODE_DIR/npx" --yes skills@1.7.0 add \
    <owner/repository> \
    --skill <skill-name> \
    --agent github-copilot \
    --global \
    --copy \
    --yes
  ../validate-agent-skills
  ```

  Third-party skills must be installed with the Skills CLI so their source and
  content hash are recorded in `agents/.agents/.skill-lock.json`. Skills absent
  from the lockfile are locally maintained. Treat the lockfile as generated
  provenance and do not edit it manually.

- Updating third-party skills:

  ```sh
  ./update-agent-skills
  git diff -- agents/.agents
  ```

  The updater changes only skills recorded in the lockfile and validates all
  installed skills afterward. Review updates as executable agent instructions,
  paying particular attention to tool permissions, scripts, external links,
  source changes, and licensing before committing them.

  The `Update agent skills` GitHub Actions workflow runs weekly and can also be
  started manually. When updates exist, it opens or refreshes a pull request;
  updates are never merged automatically.

- Adding a new global agent from a dev container:

  ```sh
  sudo apt install stow
  mv "$HOME/.copilot/agents/*" "$HOME/code/dotfiles/agents/.copilot/agents"
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
