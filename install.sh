#!/bin/bash

set -Eeuo pipefail

cat <<EOS
Dotfiles installation script
============================
EOS

COLOR_RED="\033[0;31m"
FONT_BOLD="\033[1m"
RESET="\033[0m"

abort() {
  printf "$COLOR_RED%s\n$RESET" "$@" >&2
  exit 1
}

SYSTEM=$(uname -s)
REQUIRED_SYSTEM="Darwin"

if [[ "$SYSTEM" != "$REQUIRED_SYSTEM" ]]; then
  abort "Script requires $REQUIRED_SYSTEM. You are running $SYSTEM."
fi

SHELL=$(basename "$SHELL")
REQUIRED_SHELL="zsh"

if [[ "$SHELL" != "$REQUIRED_SHELL" ]]; then
  abort "Script requires shell to be $REQUIRED_SHELL. You are running $SHELL."
fi

COLOR_GREEN="\033[0;32m"
COLOR_BLUE="\033[0;34m"

success() {
  printf "$COLOR_GREEN%s\n$RESET" "$@" >&2
}

info() {
  printf "$COLOR_BLUE""==> $FONT_BOLD%s\n$RESET" "$@" >&2
}

command_exists() {
  command -v "$1" &>/dev/null
}

if ! command_exists git; then
  abort "Git is required. Please install Git."
fi

TARGET="$HOME/dotfiles"
SOURCE="https://github.com/abcdevinitely/dotfiles.git"

clone_repository() {
  if [[ -d "$TARGET" ]]; then
    info "Removing existing repository..."

    if command_exists "stow"; then
      stow -t "$HOME" -d "$TARGET" -D .
    fi

    rm -rf "$TARGET"
    success "Repository removed."
  fi

  info "Cloning repository..."
  git clone --recurse-submodules "$SOURCE" "$TARGET"
  success "Repository cloned."
}

install_homebrew() {
  if command_exists brew; then
    info "Homebrew is already installed."
    return
  fi

  info "Installing Homebrew..."
  sudo -v
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
}

install_homebrew_packages() {
  info "Installing Homebrew packages..."
  brew bundle install --file="$TARGET/Brewfile"
}

uninstall_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    info "Uninstalling old Oh My Zsh installation..."
    rm -rf "$HOME/.oh-my-zsh"
  fi
}

install_oh_my_zsh() {
  info "Installing Oh My Zsh..."
  printf "y" | sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  rm "$HOME/.zshrc"
}

install_asdf_plugins() {
  info "Installing asdf plugins..."

  asdf_plugins=("$@")
  missing_asdf_plugins=()

  for plugin in "${asdf_plugins[@]}"
  do
    if ! asdf plugin list | grep -q "$plugin"; then
      missing_asdf_plugins+=("$plugin")
    fi
  done

  if [[ ${#missing_asdf_plugins[@]} -eq 0 ]]; then
    info "Plugins already installed. Skipping."
  else
    for plugin in "${missing_asdf_plugins[@]}"
    do
      info "Adding $plugin plugin..."
      asdf plugin add "$plugin"
    done

    success "asdf plugins installed."
  fi
}

stow_dotfiles() {
  info "Stowing dotfiles..."
  stow -t "$HOME" -d "$TARGET" --adopt .
  git -C "$TARGET" restore --staged .
  success "Dotfiles stowed."
}

main() {
  clone_repository
  install_homebrew
  install_homebrew_packages
  uninstall_oh_my_zsh
  install_oh_my_zsh
  stow_dotfiles
  zsh -c "source $HOME/.zshrc"
  install_asdf_plugins "ruby" "nodejs"
  success "Installation complete! Restarting shell..."
}

main

exec zsh -l
