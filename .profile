#
# Plugin Configuration
#

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# iTermocil
compctl -g '~/.itermocil/*(:t:r)' itermocil

# thefuck
eval $(thefuck --alias)



#
# Custom Functions
#

# Add new variables to iTerm2 session
function iterm2_print_user_vars() {
  # extend this to add whatever
  # you want to have printed out in the status bar
  iterm2_set_user_var phpVersion $(php -v | awk '/^PHP/ { print $2 }')
  iterm2_set_user_var nodeVersion $(node -v)
  iterm2_set_user_var rubyVersion $(ruby -v | awk '{ print $2 }')
  iterm2_set_user_var pwd $(pwd)
}

# iTermocil "go" shortcut
function go() {
  if [ $1 ]
  then
    itermocil $1 --here
    # itermocil $1
  else
    itermocil --list
  fi
}

# Git commit with current branch tag
# Requires zsh for git_current_branch function to work.
function gcc() {
  git commit -m "[$(git_current_branch)] $1"
}

# Easy git commits
function lazygit() {
  git add --all
  git commit -m "$1"
  git push
}

# List global npm packages
function npmglobal() {
  npm list -g --depth 0
}

# Install common global npm packages
function npminstall() {
  npm install -g bower eslint gatsby-cli grunt-cli ngrok now serve typescript
}



#
# Other stuff
#

# Removes xenobook@Bryans-MBP from every line
DEFAULT_USER="xenobook"

# iTerm2 Shell Integration
source ~/.iterm2_shell_integration.zsh
