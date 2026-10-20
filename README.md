# Dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level
folder is a Stow "package" whose contents mirror the home directory:

- `git/` -> `~/.gitconfig`, `~/.gitignore_global`
- `zsh/` -> `~/.zshrc`
- `shell/` -> `~/.aliases` (shared by Bash and zsh)
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
./install
```

This runs `stow --restow`, which refreshes the `git`, `zsh`, `shell`, `config`, and
`agents` symlinks without adopting existing files into the repo. Stow stops if
a real file conflicts with a managed path, so move that file aside before
running the installer again.

The custom Playwright agents are installed globally under
`~/.copilot/agents`, making them available across repositories.

## Dev containers

For dev containers, use `install-in-devcontainer` instead of `install`.
It symlinks files from the portable packages (`git`, `zsh`, `shell`, `config`, `agents`)
into the container without requiring Stow. Existing files and conflicting
symlinks at managed paths are moved under `~/.dotfiles-backup/<timestamp>/`
before linking, even if their contents match. Correct symlinks are left
untouched on subsequent runs, and the macOS-only `brew/` package is skipped.
Keep the repository available at the same path so the symlinks remain valid.

If you use the VS Code dotfiles feature, point it at this repo and set the
install command:

```jsonc
{
  "dotfiles.repository": "kelvin-chappell/dotfiles",
  "dotfiles.installCommand": "bash ./install-in-devcontainer"
}
```

## Usage

### Shared aliases

Add your aliases to `shell/.aliases`, which is linked to `~/.aliases` on the
local host and in dev containers. Use syntax supported by both Bash and zsh,
and guard aliases that depend on platform-specific commands or options.

Both installers preserve the existing `~/.bashrc` and append a marked,
guarded source block once, creating `.bashrc` if it is missing. The managed
`.zshrc` loads the same aliases after Oh My Zsh, so your definitions take
precedence. Neither installer changes your default shell.

Run the appropriate installer to set up Bash loading. Direct Stow commands
only manage symlinks and do not add the source block to `.bashrc`. An existing
unmanaged `~/.aliases` causes a conflict with the host installer; move it aside
and merge any wanted aliases into `shell/.aliases` before retrying. The
container installer backs up conflicting files using its usual mechanism.

Open a new interactive shell to load aliases, or load them into the current
Bash or zsh session:

```sh
. "$HOME/.aliases"
```

Removing an alias from the file does not remove an already-loaded definition
from an existing shell. Use `unalias` or open a new shell.

Interactive login Bash reads a profile rather than `.bashrc`. If your host
uses login Bash, ensure its existing profile sources `~/.bashrc`; the
installers do not modify profiles. Custom early returns or exits in startup
files can also prevent the aliases loader from running. A missing aliases
file is skipped by both loaders.

### Other dotfiles

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
  stow --restow --target="$HOME" git zsh shell config agents
  ```

- Remove a package's symlinks:

  ```sh
  stow -D --target="$HOME" <package>
  ```

## Testing

Run `bash tests/test-shell-aliases.sh` with Bash, zsh, and GNU Stow installed.
The checks use temporary home directories and do not install dotfiles into
your real home directory.
