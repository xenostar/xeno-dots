#
# Plugin Configuration
#

# Load Pure Prompt
# autoload -U promptinit; promptinit
# prompt pure

# Spaceship Prompt Configuartion - https://github.com/denysdovhan/spaceship-prompt/blob/master/docs/Options.md
SPACESHIP_PROMPT_ADD_NEWLINE=false

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# iTermocil
compctl -g '~/.itermocil/*(:t:r)' itermocil

# thefuck
eval $(thefuck --alias)

# oh-my-zsh Configuration
function precmd () {
  # Adds new line after every prompt
  precmd() {
      echo
  }
  # $funcstack[1]() {
  #   echo
  # }

  # Simplified Title - https://www.robertcooper.me/elegant-development-experience-with-zsh-and-hyper-terminal
  # window_title="\\033]0;${PWD##*/}\\007"
  # echo -ne "$window_title"
}



#
# Custom Functions
#

# Add new variables to iTerm2 session
# function iterm2_print_user_vars() {
#   # extend this to add whatever
#   # you want to have printed out in the status bar
#   iterm2_set_user_var phpVersion $(php -v | awk '/^PHP/ { print $2 }')
#   iterm2_set_user_var nodeVersion $(node -v)
#   iterm2_set_user_var rubyVersion $(ruby -v | awk '{ print $2 }')
#   iterm2_set_user_var pwd $(pwd)
# }

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

# Start up the Docket local environment
function docketdev() {
  # node scripts/migrate && node server/index.js
  node scripts/migrate && nodemon --inspect server/index.js
  # node -r dotenv/config scripts/migrate && nodemon -r dotenv/config --inspect server/index.js
}

function zoomdev() {
  source ~/Docket/docket/scripts/zoom-client.sh && z devep
}

# Git commit with current branch name
# Requires zsh for git_current_branch function to work.
function gcc() {
  # git commit -m "#$(git_current_branch) $1"
  git commit -m "$(git_current_branch) $1"
}

# Git commit with current branch name ("issue-" removed)
# Requires zsh for git_current_branch function to work.
function gccold() {
  # branch="$(git_current_branch)"
  # prefix="issue-"
  # prefix_removed_branch=${branch/#$prefix}
  git commit -m "#${$(git_current_branch)/#issue-} $1"
}

# Clean up old branches
# function gbclean() {
#   git branch --no-color --merged | command grep -vE "^(\*|\s*(master|develop|dev|project-133)\s*$)" | command xargs -n 1 git branch -d
# }

# Easy git commits
# function lazygit() {
#   git add --all
#   git commit -m "$1"
#   git push
# }

# List global npm packages
function npmglobal() {
  npm list -g --depth 0
}

# Install common global npm packages
function npminstall() {
  npm install -g gatsby-cli lighthouse ngrok nodemon now serve
}

# Uninstall common global npm packages
function npmuninstall() {
  npm uninstall -g gatsby-cli lighthouse ngrok nodemon now serve
}



#
# Other stuff
#

# Removes xenobook@Bryans-MBP from every line
DEFAULT_USER="xenobook"

# iTerm2 Shell Integration
source ~/.iterm2_shell_integration.zsh
