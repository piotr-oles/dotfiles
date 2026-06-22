# Load homebrew shell variables (.zprofile already runs this for login shells)
[[ -z "$HOMEBREW_PREFIX" ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Force certain more-secure behaviours from homebrew
export HOMEBREW_NO_INSECURE_REDIRECT=1
export HOMEBREW_CASK_OPTS=--require-sha
export HOMEBREW_DIR=/opt/homebrew
export HOMEBREW_BIN=/opt/homebrew/bin

# Prefer GNU binaries to Macintosh binaries.
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"

# Start configuration added by Zim Framework install {{{
# Remove older command from the history if a duplicate is to be added.
setopt HIST_IGNORE_ALL_DUPS
bindkey -v
WORDCHARS=${WORDCHARS//[\/]}
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)
ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim

# Initialize modules.
source ${ZIM_HOME}/init.zsh
