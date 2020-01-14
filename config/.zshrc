export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="babeuloula"

setopt correct

plugins=(
    git
)

source $ZSH/oh-my-zsh.sh

if [[ -f $HOME/.zsh_profile ]]; then
    source $HOME/.zsh_profile
fi
