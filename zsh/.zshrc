# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt APPEND_HISTORY        	# Append to history file instead of overwriting
setopt SHARE_HISTORY         	# Share history across multiple zsh sessions
setopt HIST_IGNORE_DUPS   	# don't store duplicates
setopt HIST_FIND_NO_DUPS	# Don't display duplicates when searching
setopt HIST_VERIFY            	# lets you edit history commands before running
setopt HIST_IGNORE_SPACE     # Don't save commands that start with space
setopt EXTENDED_HISTORY      # Save timestamps with history
setopt HIST_EXPIRE_DUPS_FIRST # Remove duplicates first when trimming history

# Mise
eval "$(mise activate zsh)"
eval "$(mise hook-env)"
export MISE_ACTIVATE_AGGRESSIVE=1

# Auto-completion
autoload -Uz compinit && compinit

# Quality of life improvements
setopt AUTO_CD               # cd into directories by just typing the name

# Test GitHub App
export TEST_GITHUB_APP_CLIENT_ID=Iv23liZyoBIk01zetksj
export TEST_GITHUB_APP_PRIVATE_KEY_FILE=~/.github-creds/gu-kc-experimental.2025-09-02.private-key.pem
export TEST_OWNER=kelvin-chappell
export TEST_REPO=github-analysis

# Node
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# Dev containers
alias devdevenv="~/code/devenv/cli/target/universal/stage/bin/devenv"
