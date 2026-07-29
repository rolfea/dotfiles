# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth:erasedups

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=200000
HISTTIMEFORMAT='%F %T '

# Flush each command to the history file as it's entered rather than at exit,
# so a killed pane doesn't take its history with it and Ctrl-R in a sibling
# pane can see it.
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
# bash 4+ only — guarded because macOS ships bash 3.2, where this errors.
shopt -s globstar 2>/dev/null

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

# The $(__git_ps1) call is inside single quotes on purpose: it must run at
# prompt-render time, not once at assignment. __git_ps1 is defined further down.
if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[01;33m\]$(__git_ps1 " (%s)")\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(__git_ps1 " (%s)")\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# ── PATH and dev tooling ─────────────────────────────────────────────────────
# Every entry goes through _path_prepend so `source ~/.bashrc` to reload is
# safe. The installers that wrote this section originally each appended
# blindly, which is why $HOME/.local/bin used to land in PATH three times.
# Duplicated from .profile on purpose — a non-login shell never reads that file.
_path_prepend() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) [ -d "$1" ] && PATH="$1:$PATH" ;;
    esac
}

# Collapse repeats inherited from /etc/profile.d and friends, keeping the first
# occurrence so precedence is unchanged.
_path_dedupe() {
    local out= entry IFS=:
    for entry in $PATH; do
        case ":$out:" in
            *":$entry:"*) ;;
            *) out="${out:+$out:}$entry" ;;
        esac
    done
    PATH=$out
}

_path_prepend "$HOME/.local/bin"
_path_prepend "$HOME/.opencode/bin"

export PYENV_ROOT="$HOME/.pyenv"
_path_prepend "$PYENV_ROOT/bin"
# `pyenv init` prepends the shim dir every time it runs, so gate on the shims
# already being present rather than on the binary existing.
case ":$PATH:" in
    *":$PYENV_ROOT/shims:"*) ;;
    *) command -v pyenv >/dev/null && eval "$(pyenv init - bash)" ;;
esac

export BUN_INSTALL="$HOME/.bun"
_path_prepend "$BUN_INSTALL/bin"

# pnpm's home is platform-specific.
if [ "$(uname -s)" = Darwin ]; then
    export PNPM_HOME="$HOME/Library/pnpm"
else
    export PNPM_HOME="$HOME/.local/share/pnpm"
fi
_path_prepend "$PNPM_HOME"

# ~/.nvm is nvm's own default and what the Mac uses; this box keeps it under
# ~/.config/nvm. Prefer whichever is actually there.
if [ -d "$HOME/.config/nvm" ]; then
    export NVM_DIR="$HOME/.config/nvm"
else
    export NVM_DIR="$HOME/.nvm"
fi
# Loading nvm.sh twice re-adds the active version's bin dir, so skip if the
# function is already defined.
if ! declare -F nvm >/dev/null && [ -s "$NVM_DIR/nvm.sh" ]; then
    \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi

_path_dedupe
export PATH

# ── git-aware prompt ─────────────────────────────────────────────────────────
# __git_ps1 ships with git itself (git-sh-prompt). Debian's bash-completion
# normally pulls it in, but load it explicitly so this file also works on a
# fresh box or a Mac, then stub it so PS1 can never error where git is absent.
if ! declare -F __git_ps1 >/dev/null; then
    for _f in /usr/lib/git-core/git-sh-prompt \
              /usr/share/git/completion/git-prompt.sh \
              /opt/homebrew/etc/bash_completion.d/git-prompt.sh \
              /usr/local/etc/bash_completion.d/git-prompt.sh \
              /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh \
              /Applications/Xcode.app/Contents/Developer/usr/share/git-core/git-prompt.sh; do
        [ -r "$_f" ] && . "$_f" && break
    done
    unset _f
fi
declare -F __git_ps1 >/dev/null || __git_ps1() { :; }

GIT_PS1_SHOWDIRTYSTATE=1       # * unstaged, + staged
GIT_PS1_SHOWSTASHSTATE=1       # $ something stashed
GIT_PS1_SHOWUNTRACKEDFILES=1   # % untracked files present
GIT_PS1_SHOWUPSTREAM=auto      # < behind, > ahead, <> diverged
# Per-repo escape hatch if the prompt ever drags in a huge worktree:
#   git config bash.showUntrackedFiles false

# ── git aliases ──────────────────────────────────────────────────────────────
# Names deliberately match the oh-my-zsh git plugin so muscle memory carries
# over from the Mac.
git_main_branch() {
    local ref
    # origin/HEAD is authoritative and handles repos whose trunk isn't "main"
    # (this monorepo's is "dev").
    ref=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null) \
        && { echo "${ref#origin/}"; return; }
    for ref in main trunk master dev; do
        git show-ref -q --verify "refs/heads/$ref" && { echo "$ref"; return; }
    done
    echo main
}

alias g='git'
alias gst='git status'
alias gss='git status -s'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -v'
alias gc!='git commit -v --amend'
alias gcm='git checkout "$(git_main_branch)"'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gsw='git switch'
alias gswc='git switch -c'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gd='git diff'
alias gdca='git diff --cached'
alias gf='git fetch'
alias gl='git pull'
alias gp='git push'
alias gm='git merge'
alias gcp='git cherry-pick'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias grb='git rebase'
alias grbi='git rebase -i'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'
alias grh='git reset'
alias grhh='git reset --hard'
alias gsta='git stash push'
alias gstp='git stash pop'
alias gstl='git stash list'

# Make tab-completion follow the aliases, not just the `git` binary.
if ! declare -F __git_complete >/dev/null \
   && [ -r /usr/share/bash-completion/completions/git ]; then
    . /usr/share/bash-completion/completions/git
fi
if declare -F __git_complete >/dev/null; then
    __git_complete g    __git_main
    __git_complete gco  _git_checkout
    __git_complete gcb  _git_checkout
    __git_complete gsw  _git_switch
    __git_complete gb   _git_branch
    __git_complete gd   _git_diff
    __git_complete gp   _git_push
    __git_complete gl   _git_pull
    __git_complete grb  _git_rebase
fi

alias chad='claude'

# ── fzf ──────────────────────────────────────────────────────────────────────
# Ctrl-R fuzzy history, Ctrl-T insert file path, Alt-C fuzzy cd.
if command -v fzf >/dev/null; then
    # rg honours .gitignore, which is what makes this usable in a monorepo.
    if command -v rg >/dev/null; then
        export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git/*"'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
    if fzf --bash >/dev/null 2>&1; then
        eval "$(fzf --bash)"   # fzf >= 0.48
    else
        # Debian/Ubuntu split these: key-bindings under doc/examples, but the
        # completion script (the `**<TAB>` trigger) under bash-completion/,
        # where the lazy loader would only pull it in for `fzf` itself — too
        # late to trigger on other commands. Source both, upstream paths last.
        for _f in /usr/share/doc/fzf/examples/key-bindings.bash \
                  /usr/share/bash-completion/completions/fzf \
                  /usr/share/doc/fzf/examples/completion.bash; do
            [ -r "$_f" ] && . "$_f"
        done
        unset _f
    fi
fi

# ── missing-tool notice ──────────────────────────────────────────────────────
# Cloning these dotfiles onto a new box gets you the config but none of the
# binaries it assumes. Flag what's absent, once a day, with an install command
# that actually works. Only tools installable in one command belong here —
# anything needing a third-party apt repo (doppler) or a version manager
# (node, pnpm) would print advice that fails, so it's deliberately left out.
#
# Format is binary:package because they diverge often enough to matter
# (rg/ripgrep, nvim/neovim). Both vars are overridable so a one-off machine can
# trim the list without editing this file, and so the behaviour is testable.
: "${DOTFILES_TOOLS:=git:git tmux:tmux nvim:neovim fzf:fzf rg:ripgrep gh:gh jq:jq curl:curl}"
: "${DOTFILES_CHECK_STAMP:=${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/env-check}"

# Apple freezes /bin/bash at 3.2 (2007) rather than ship GPLv3, so this fires
# on any stock macOS shell — where globstar and printf '%()T' don't exist and
# parts of this file quietly do nothing. Takes the major version as an argument
# so the behaviour is testable without a bash 3 to hand.
_dotfiles_check_bash() {
    local major=${1:-${BASH_VERSINFO[0]:-0}}
    local shown=${1:-${BASH_VERSION:-$major}}
    [ "$major" -ge 4 ] 2>/dev/null && return
    local prefix=/usr/local
    [ -d /opt/homebrew ] && prefix=/opt/homebrew
    printf '\033[33m!\033[0m bash \033[1m%s\033[0m — this config expects bash 5\n' "$shown"
    printf '  \033[2m3.2 is what Apple ships; install a current one:\033[0m\n'
    printf '    brew install bash && chsh -s %s/bin/bash\n' "$prefix"
    printf '    \033[2m(add it to /etc/shells first)\033[0m\n'
}

_dotfiles_missing_pkgs() {
    local entry
    for entry in $DOTFILES_TOOLS; do
        command -v "${entry%%:*}" >/dev/null 2>&1 || printf '%s ' "${entry#*:}"
    done
}

_dotfiles_install_cmd() {
    [ -z "$1" ] && return
    if command -v brew >/dev/null 2>&1; then
        printf 'brew install %s' "${1% }"
    else
        printf 'sudo apt install %s' "${1% }"
    fi
}

# `tools` — full status on demand, ignoring the once-a-day rate limit.
tools() {
    local entry bin pkg pkgs
    if [ "${BASH_VERSINFO[0]:-0}" -ge 4 ]; then
        printf '  \033[32m✓\033[0m %-6s %s\n' bash "$BASH_VERSION"
    else
        printf '  \033[31m✗\033[0m %-6s \033[2m%s — want 5.x\033[0m\n' bash "$BASH_VERSION"
    fi
    for entry in $DOTFILES_TOOLS; do
        bin=${entry%%:*}; pkg=${entry#*:}
        if command -v "$bin" >/dev/null 2>&1; then
            printf '  \033[32m✓\033[0m %-6s %s\n' "$bin" "$(command -v "$bin")"
        else
            printf '  \033[31m✗\033[0m %-6s \033[2mmissing → %s\033[0m\n' "$bin" "$pkg"
        fi
    done
    pkgs=$(_dotfiles_missing_pkgs)
    [ -n "$pkgs" ] && printf '\n  %s\n' "$(_dotfiles_install_cmd "$pkgs")"
    return 0
}

# One once-a-day gate for every environment warning, so a new tmux pane is
# silent even when something is wrong.
_dotfiles_env_notice() {
    local today pkgs stamp=$DOTFILES_CHECK_STAMP
    # Builtin date formatting avoids forking `date` on every shell start.
    printf -v today '%(%F)T' -1 2>/dev/null || today=$(date +%F)
    [ "$(cat "$stamp" 2>/dev/null)" = "$today" ] && return
    mkdir -p "${stamp%/*}" 2>/dev/null && printf '%s' "$today" >"$stamp" 2>/dev/null
    _dotfiles_check_bash
    pkgs=$(_dotfiles_missing_pkgs)
    [ -z "$pkgs" ] && return
    printf '\033[33m!\033[0m missing: \033[1m%s\033[0m\n  %s   \033[2m(or run `tools`)\033[0m\n' \
        "${pkgs% }" "$(_dotfiles_install_cmd "$pkgs")"
}
_dotfiles_env_notice
