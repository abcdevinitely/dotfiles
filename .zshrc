# Exports
export ZSH="$HOME/.oh-my-zsh"
export EDITOR="code --wait"

# Oh My Zsh
ZSH_THEME="simple"
plugins=(
  git
  ruby
  rails
  zsh-syntax-highlighting
  zsh-autosuggestions
)
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
source $ZSH/oh-my-zsh.sh

# Aliases
alias zshc="code $HOME/.zshrc"
alias omzc="code $ZSH"

# fzf
source <(fzf --zsh)

# asdf
. /opt/homebrew/opt/asdf/libexec/asdf.sh
