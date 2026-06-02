#!/bin/bash

# Create the XDG config directory if it doesn't exist
mkdir -p "$HOME/.config"

# Symlink Neovim config
#ln -sfn "$HOME/code/my-dotfiles/.config/nvim" "$HOME/.config/nvim"

# Symlink dev container config
ln -sfn "$HOME/code/my-dotfiles/.config/devenv/devenv.yaml" "$HOME/.config/devenv/devenv.yaml"

# Symlink shell files
ln -sf "$HOME/code/my-dotfiles/shell/.zshrc" "$HOME/.zshrc"
ln -sf "$HOME/code/my-dotfiles/git/.gitconfig" "$HOME/.gitconfig"
ln -sf "$HOME/code/my-dotfiles/git/.gitignore_global" "$HOME/.gitignore_global"

echo "Dotfiles symlinked successfully!"
