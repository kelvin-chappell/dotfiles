#!/bin/bash

# Create the XDG config directory if it doesn't exist
mkdir -p "$HOME/.config"

# Symlink Neovim config
#ln -sn "$HOME/code/my-dotfiles/.config/nvim" "$HOME/.config/nvim"

# Symlink dev container config
mkdir -p "$HOME/.config/devenv"
ln -sn "$HOME/code/my-dotfiles/.config/devenv" "$HOME/.config/devenv"

# Symlink shell files
ln -s "$HOME/code/my-dotfiles/shell/.zshrc" "$HOME/.zshrc"
ln -s "$HOME/code/my-dotfiles/git/.gitconfig" "$HOME/.gitconfig"
ln -s "$HOME/code/my-dotfiles/git/.gitignore_global" "$HOME/.gitignore_global"

echo "Dotfiles symlinked successfully!"
