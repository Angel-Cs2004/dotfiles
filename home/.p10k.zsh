# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
#ZSH_THEME="robbyrussell"
typeset -g POWERLEVEL9K_DIR_BACKGROUND='#d0a9f5'
typeset -g POWERLEVEL9K_VCS_BACKGROUND='#ff9ecb'
typeset -g POWERLEVEL9K_USER_BACKGROUND='#c792ea'

# typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=''
# typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=''

#typeset -g POWERLEVEL9K_BACKGROUND=none
# typeset -g POWERLEVEL9K_RAINBOW=true


typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=255
typeset -g POWERLEVEL9K_USER_FOREGROUND=255
typeset -g POWERLEVEL9K_DIR_FOREGROUND=255
typeset -g POWERLEVEL9K_VCS_FOREGROUND=255
ZSH_THEME="powerlevel10k/powerlevel10k"
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
# This section is for Powerlevel9k theme.

POWERLEVEL9K_MODE="nerdfont-complete"
##POWERLEVEL9K_DISABLE_RPROMPT=true
 POWERLEVEL9K_PROMPT_ON_NEWLINE=true
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX='%f╭─'
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%f╰─❯ '
# POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon user dir_writable dir vcs virtualenv)
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  os_icon
  user
  dir
  vcs
  virtualenv
)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status
  docker_context
  disk_usage
  command_execution_time
  cpu_usage
  background_jobs
  container_name
  battery
  time
)

# ===== PALETA ROJO DEGRADADO (según imagen) =====
R1='#6e2a2a'
R2='#8a3a3a'
R3='#a94a4a'
R4='#c45b5b'
R5='#dd7474'
R6='#f08f8f'

DARK_FG='#1e1e2e'


# ✔ / ✘ status
typeset -g POWERLEVEL9K_STATUS_BACKGROUND=$R1
typeset -g POWERLEVEL9K_STATUS_FOREGROUND=$DARK_FG
typeset -g POWERLEVEL9K_STATUS_BOLD=true

# Docker context
typeset -g POWERLEVEL9K_DOCKER_CONTEXT_BACKGROUND=$R2
typeset -g POWERLEVEL9K_DOCKER_CONTEXT_FOREGROUND=$DARK_FG
typeset -g POWERLEVEL9K_DOCKER_CONTEXT_BOLD=true

# Disk usage
typeset -g POWERLEVEL9K_DISK_USAGE_BACKGROUND=$R3
typeset -g POWERLEVEL9K_DISK_USAGE_FOREGROUND=$DARK_FG
typeset -g POWERLEVEL9K_DISK_USAGE_BOLD=true

# Command execution time
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=$R4
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$DARK_FG
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_BOLD=true

# CPU usage
typeset -g POWERLEVEL9K_CPU_USAGE_BACKGROUND=$R5
typeset -g POWERLEVEL9K_CPU_USAGE_FOREGROUND=$DARK_FG
typeset -g POWERLEVEL9K_CPU_USAGE_BOLD=true

# Background jobs
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND=$R6
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=$DARK_FG
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_BOLD=true

# Container name
typeset -g POWERLEVEL9K_CONTAINER_NAME_BACKGROUND=$R5
typeset -g POWERLEVEL9K_CONTAINER_NAME_FOREGROUND=$DARK_FG
typeset -g POWERLEVEL9K_CONTAINER_NAME_BOLD=true

# Battery
typeset -g POWERLEVEL9K_BATTERY_BACKGROUND=$R4
typeset -g POWERLEVEL9K_BATTERY_FOREGROUND=$DARK_FG
typeset -g POWERLEVEL9K_BATTERY_BOLD=true

# Time
typeset -g POWERLEVEL9K_TIME_BACKGROUND=$R3
typeset -g POWERLEVEL9K_TIME_FOREGROUND=$DARK_FG
typeset -g POWERLEVEL9K_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=''
typeset -g POWERLEVEL9K_RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL=''

#POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )"
#POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
#POWERLEVEL9K_USER_ICON="\uF415" # 
POWERLEVEL9K_ROOT_ICON="\uF09C"
#POWERLEVEL9K_SUDO_ICON=$'\uF09C' # 
POWERLEVEL9K_TIME_FORMAT="%D{%H:%M}"
#POWERLEVEL9K_VCS_GIT_ICON='\uF408 '
#POWERLEVEL9K_VCS_GIT_GITHUB_ICON='\uF408 '

# End Powerlevel9k configuration

ZSH_DISABLE_COMPFIX=true

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  gitfast
  man
  python
  composer
  zsh-syntax-highlighting
  zsh-autosuggestions
  z
  sudo
  extract
  command-not-found
  docker
  kubectl
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

alias suroot='sudo -E -s'

# source ~/.bash_profile

if [ -f ~/.bash_profile ]; then 
    . ~/.bash_profile;
fi

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"


