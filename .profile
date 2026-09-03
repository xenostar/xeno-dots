#
# Plugin Configuration
#

# ZSH
GIT_COMPLETION_CHECKOUT_NO_GUESS=1 # Apparently only shows local branhces?
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=cyan"
ZSH_THEME_TERM_TITLE_IDLE="%~" # Makes new tab titles change from username@computername~:~/currentDir to just ~/currentDir

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# oh-my-zsh Configuration
function precmd () {
  # Adds new line after every prompt. Set add_newline to false in starhip.toml
  precmd() {
      echo
  }
}

# Alias to clear the terminal and remove the extra line
alias clear="precmd() {precmd() {echo }} && clear"



#
# Custom Functions
#

alias gcob='git branch | fzf | xargs git checkout'

function flushdns() {
  sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder && echo \"DNS cache flushed successfully\"
}

# Clean up old branches
# function gbclean() {
#   git branch --no-color --merged | command grep -vE "^(\*|\s*(master|develop|dev|project-133)\s*$)" | command xargs -n 1 git branch -d
# }

# List global npm packages
function npmglobal() {
  npm list -g --depth 0
}

# Install common global npm packages
function npminstall() {
  npm install -g lighthouse ngrok nodemon now serve
}

# Uninstall common global npm packages
function npmuninstall() {
  npm uninstall -g lighthouse ngrok nodemon now serve
}
