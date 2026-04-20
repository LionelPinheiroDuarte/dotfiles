#!bash
# shellcheck disable=SC1090

# === INTERACTIVE SHELL GUARD ===
# Bail out early if the shell is not interactive (e.g. scripts, scp sessions).

case $- in
*i*) ;;
*) return ;;
esac

# === DISTRO / ENVIRONMENT DETECTION ===
# Detect the running platform to allow conditional behaviour later.
# Currently only distinguishes WSL2 — extend with more cases as needed.

export DISTRO
[[ $(uname -r) =~ Microsoft ]] && DISTRO=WSL2 #TODO distinguish WSL1
#TODO add native Linux, macOS, etc.

# === CORE UTILITY FUNCTIONS ===
# Lightweight helpers used internally throughout this file.
# _have: true if a command exists on PATH.
# _source_if: source a file only if it exists and is readable.

_have() { type "$1" &>/dev/null; }
_source_if() { [[ -r "$1" ]] && source "$1"; }

# === ENVIRONMENT VARIABLES ===

# -- Personal paths --
# REPOS/GHREPOS follow the ~/Repos/github.com/<user>/ layout used by clone().
# GITHUB is the actual working location for day-to-day projects.

export USER="${USER:-$(whoami)}"
export GITUSER="$USER"
export REPOS="$HOME/Repos"
export GHREPOS="$REPOS/github.com/$GITUSER"
export GITHUB="$HOME/repos/github"
export JOURNAL="$HOME/documents/journal"

# -- Editor & terminal --
# vi/vim as default editor; xterm-256color for full colour support.

export TERM=xterm-256color
export EDITOR=vi
export VISUAL=vi

# -- Go toolchain --
# Keep private modules off the public proxy; output binaries to ~/.local/bin.

export GOPRIVATE="github.com/$GITUSER/*,gitlab.com/$GITUSER/*"
export GOPATH="$HOME/.local/share/go"
export GOBIN="$HOME/.local/bin"
export GOPROXY=direct
export CGO_ENABLED=0

# -- Python --
# Prevent Python from littering the filesystem with .pyc bytecode files.

export PYTHONDONTWRITEBYTECODE=2

# -- LESS / man page colours --
# TERMCAP overrides to colourize man page headings and highlights in less.

export LESS_TERMCAP_mb="[35m" # magenta  — blinking
export LESS_TERMCAP_md="[33m" # yellow   — bold
export LESS_TERMCAP_me=""      # reset bold
export LESS_TERMCAP_se=""      # reset standout
export LESS_TERMCAP_so="[34m" # blue     — standout (status bar)
export LESS_TERMCAP_ue=""      # reset underline
export LESS_TERMCAP_us="[4m"  # underline

# -- Miscellaneous tool config --

export LC_COLLATE=C
export ANSIBLE_INVENTORY="$HOME/.config/ansible/ansible_hosts"
#export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
#export GPG_TTY=$(tty)

[[ -d /.vim/spell ]] && export VIMSPELL=("$HOME/.vim/spell/*.add")

# === PAGER ===
# Enable lesspipe so less can display binary files (archives, images, etc.)
# by piping them through the appropriate converter first.

if [[ -x /usr/bin/lesspipe ]]; then
	export LESSOPEN="| /usr/bin/lesspipe %s"
	export LESSCLOSE="/usr/bin/lesspipe %s %s"
fi

# === LS COLOURS ===
# Load a terminal colour scheme for ls output. Reads ~/.dircolors if present,
# otherwise falls back to the system defaults.

if _have dircolors; then
	if [[ -r "$HOME/.dircolors" ]]; then
		eval "$(dircolors -b "$HOME/.dircolors")"
	else
		eval "$(dircolors -b)"
	fi
fi

# === PATH ===
# pathprepend / pathappend add directories to PATH without creating duplicates.
# Entries that don't exist as directories are silently skipped.

pathappend() {
	declare arg
	for arg in "$@"; do
		test -d "$arg" || continue
		PATH=${PATH//":$arg:"/:}
		PATH=${PATH/#"$arg:"/}
		PATH=${PATH/%":$arg"/}
		export PATH="${PATH:+"$PATH:"}$arg"
	done
} && export pathappend

pathprepend() {
	for arg in "$@"; do
		test -d "$arg" || continue
		PATH=${PATH//:"$arg:"/:}
		PATH=${PATH/#"$arg:"/}
		PATH=${PATH/%":$arg"/}
		export PATH="$arg${PATH:+":${PATH}"}"
	done
} && export pathprepend

# Prepended entries appear first (higher priority). Last listed = highest priority.
pathprepend \
	/usr/local/bin \
	"$HOME/.local/bin" \
	"$HOME/.npm-global/bin" \
	"$GHREPOS/cmd-"*

# Appended entries are lower priority fallbacks, including Windows-side paths for WSL2.
pathappend \
	/usr/local/opt/coreutils/libexec/gnubin \
	'/mnt/c/Program Files/Oracle/VirtualBox' \
	'/mnt/c/Windows' \
	'/mnt/c/Program Files (x86)/VMware/VMware Workstation' \
	/mingw64/bin \
	/usr/local/bin \
	/usr/local/sbin \
	/usr/local/games \
	/usr/games \
	/usr/sbin \
	/usr/bin \
	/snap/bin \
	/sbin \
	/bin

# === CDPATH ===
# Directories searched by cd — lets you jump to a subdirectory from anywhere
# without typing the full path (e.g. `cd job-listing` from any location).

export CDPATH=".:$GHREPOS:$REPOS:/media/$USER:$HOME"

# === SHELL OPTIONS ===
# Tune Bash behaviour:
#   checkwinsize — update LINES/COLUMNS after each command
#   expand_aliases — aliases work in non-interactive contexts
#   globstar — ** matches across directory boundaries
#   dotglob — globs include hidden files (dot files)
#   extglob — enables extended pattern matching (!(x), +(x), etc.)

shopt -s checkwinsize
shopt -s expand_aliases
shopt -s globstar
shopt -s dotglob
shopt -s extglob

#shopt -s nullglob # bug kills completion for some
#set -o noclobber

# === TERMINAL ===
# Disable Ctrl-S (XOFF flow control) to prevent accidental terminal freezes.
# Remap Caps Lock to Escape when running in a graphical session.

stty stop undef

_have setxkbmap && test -n "$DISPLAY" &&
	setxkbmap -option caps:escape &>/dev/null

# === HISTORY ===
# ignoreboth: skip duplicates and lines starting with a space.
# Large history size; append to the file rather than overwrite it.
# vi mode for command-line editing.

export HISTCONTROL=ignoreboth
export HISTSIZE=5000
export HISTFILESIZE=10000

set -o vi
shopt -s histappend

# === PROMPT ===
# Adaptive PS1 showing user, host, current directory, and git branch.
# Automatically switches to a two-line or three-line layout when the
# one-liner would exceed PROMPT_LONG or PROMPT_MAX characters.
# Branch name turns red on main/master as a subtle reminder.

PROMPT_LONG=20
PROMPT_MAX=95
PROMPT_AT=@

__ps1() {
	local P='$' dir="${PWD##*/}" B countme short long double \
		r='\[\e[38;5;167m\]' \
		g='\[\e[38;5;245m\]' \
		h='\[\e[38;5;109m\]' \
		u='\[\e[38;5;208m\]' \
		p='\[\e[38;5;208m\]' \
		w='\[\e[38;5;214m\]' \
		b='\[\e[38;5;108m\]' \
		x='\[\e[0m\]'

	[[ $EUID == 0 ]] && P='#' && u=$r && p=$u # root
	[[ $PWD = / ]] && dir=/
	[[ $PWD = "$HOME" ]] && dir='~'

	B=$(git branch --show-current 2>/dev/null)
	[[ $dir = "$B" ]] && B=.
	countme="$USER$PROMPT_AT$(hostname):$dir($B)\$ "

	[[ $B = master || $B = main ]] && b="$r"
	[[ -n "$B" ]] && B="$g($b$B$g)"

	short="$u\u$g$PROMPT_AT$h\h$g:$w$dir$B$p$P$x "
	long="$g╔ $u\u$g$PROMPT_AT$h\h$g:$w$dir$B\n$g╚ $p$P$x "
	double="$g╔ $u\u$g$PROMPT_AT$h\h$g:$w$dir\n$g║ $B\n$g╚ $p$P$x "

	if ((${#countme} > PROMPT_MAX)); then
		PS1="$double"
	elif ((${#countme} > PROMPT_LONG)); then
		PS1="$long"
	else
		PS1="$short"
	fi
}

# log_output: capture stderr of failed commands for `x wtf`.
# Writes the last command to /tmp/last_command.txt and re-runs it
# (stderr only) to /tmp/last_error.txt. Skips python/x invocations
# to avoid infinite loops or side effects.
log_output() {
	local exit_code=$?
	local last_cmd
	last_cmd=$(history 1 | awk '{$1=""; print $0}' | xargs)
	if [[ $exit_code -ne 0 ]]; then
		echo "$last_cmd" >/tmp/last_command.txt
		case "$last_cmd" in
			python3* | python* | x\ * | x) ;;
			*) eval "$last_cmd" 2>/tmp/last_error.txt 1>/dev/null ;;
		esac
	fi
}

PROMPT_COMMAND='log_output; __ps1'

# === ALIASES ===
# Wipe all existing aliases first to avoid inheriting stale definitions.

unalias -a

# -- Navigation: repos --
# Quick jumps to GitHub projects.

alias github='cd $GITHUB'
alias agents='cd $GITHUB/agents'
alias brain='cd $GITHUB/brain'
alias dotfiles='cd $GITHUB/dotfiles'
alias job='cd $GITHUB/job-listing'
alias portfolio='cd $GITHUB/portfolio'
alias toolbox='cd $GITHUB/toolbox'
alias ghmanager='cd $GITHUB/gh-manager'

# -- Navigation: documents --

alias journal='cd $JOURNAL'

# -- System utilities --
# Human-readable sizes, colour output, safer/ergonomic defaults.

alias ls='ls -h --color=auto'
alias free='free -h'
alias df='df -h'
alias diff='diff --color'
alias clear='printf "\e[H\e[2J"'
alias c='printf "\e[H\e[2J"'
alias temp='cd $(mktemp -d)'
alias chmox='chmod +x'
alias grep="pcregrep"
alias top=bashtop

# -- Development tools --

alias bat='batcat'
alias view='vi -R'           # read-only vim
alias sc='shellcheck'
alias sshh='sshpass -f $HOME/.sshpass ssh '

_have vim && alias vi=vim

# === FUNCTIONS ===

# -- envx: source a KEY=VALUE .env file into the current shell --
# Falls back to ~/.env when no argument is given.

envx() {
	local envfile="${1:-"$HOME/.env"}"
	[[ ! -e "$envfile" ]] && echo "$envfile not found" && return 1
	while IFS= read -r line; do
		name=${line%%=*}
		value=${line#*=}
		[[ -z "${name}" || $name =~ ^# ]] && continue
		export "$name"="$value"
	done <"$envfile"
} && export -f envx

[[ -e "$HOME/.env" ]] && envx "$HOME/.env"

# -- new-from: create a GitHub repo from a template and clone it locally --

new-from() {
	local template="$1"
	local name="$2"
	! _have gh && echo "gh command not found" && return 1
	[[ -z "$name" ]] && echo "usage: $0 <name>" && return 1
	[[ -z "$GHREPOS" ]] && echo "GHREPOS not set" && return 1
	[[ ! -d "$GHREPOS" ]] && echo "Not found: $GHREPOS" && return 1
	cd "$GHREPOS" || return 1
	[[ -e "$name" ]] && echo "exists: $name" && return 1
	gh repo create -p "$template" --public "$name"
	gh repo clone "$name"
	cd "$name" || return 1
} && export -f new-from

# -- clone: smart GitHub repo cloner --
# Accepts full HTTPS/SSH URLs or bare "user/repo" / "repo" strings.
# Clones under ~/Repos/github.com/<user>/ and cd into the result.

clone() {
	local repo="$1" user
	local repo="${repo#https://github.com/}"
	local repo="${repo#git@github.com:}"
	if [[ $repo =~ / ]]; then
		user="${repo%%/*}"
	else
		user="$GITUSER"
		[[ -z "$user" ]] && user="$USER"
	fi
	local name="${repo##*/}"
	local userd="$REPOS/github.com/$user"
	local path="$userd/$name"
	[[ -d "$path" ]] && cd "$path" && return
	mkdir -p "$userd"
	cd "$userd"
	echo gh repo clone "$user/$name" -- --recurse-submodule
	gh repo clone "$user/$name" -- --recurse-submodule
	cd "$name"
} && export -f clone

# === COMPLETIONS ===
# Register tab-completion for custom Bonzai-style commands and external tools.
# Each external tool's completion is loaded only if the binary is present.

owncomp=(
	pdf md zet yt gl auth pomo config live iam sshkey ws x z clip
	./build build b ./k8sapp k8sapp ./setup ./cmd run ./run
	foo ./foo cmds ./cmds z bonzai
)

for i in "${owncomp[@]}"; do complete -C "$i" "$i"; done

_have gh && . <(gh completion -s bash)
_have pandoc && . <(pandoc --bash-completion)
_have kubectl && . <(kubectl completion bash 2>/dev/null)
_have k && complete -o default -F __start_kubectl k
_have kind && . <(kind completion bash)
_have kompose && . <(kompose completion bash)
_have helm && . <(helm completion bash)
_have minikube && . <(minikube completion bash)
_have docker && _source_if "$HOME/.local/share/docker/completion"
_have docker-compose && complete -F _docker_compose dc

complete -C /usr/bin/terraform terraform
complete -C /usr/bin/terraform tf

# === EXTERNAL CONFIG ===
# Source optional local overrides that are not tracked in version control.
# Use these for machine-specific, personal, or sensitive settings.

_have x && eval "$(_X_COMPLETE=bash_source x)"

_source_if "$HOME/.bash_personal"
_source_if "$HOME/.bash_private"
_source_if "$HOME/.bash_work"
