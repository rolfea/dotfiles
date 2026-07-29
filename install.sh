#!/bin/sh
#
# Bootstrap these dotfiles on a new machine: create the symlinks, then report
# what still needs installing.
#
# Deliberately POSIX sh with no bash-4 constructs, because on macOS this runs
# *before* you've replaced Apple's bash 3.2.
#
# By default it installs nothing: package installs need sudo and network, so it
# just prints the command and stops. Pass --install to opt in and have it run
# the install for you via whichever package manager it detects.
#
#   ./install.sh            link everything, then report what's missing
#   ./install.sh --install  link, then install the missing tools for you
#   ./install.sh --dry-run  show what would happen, touch nothing
#
# Safe to re-run: existing correct links are left alone, and any real file in
# the way is moved into a timestamped backup directory before being replaced.

set -eu

DOTFILES=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DRY_RUN=0
DO_INSTALL=0
for arg in "$@"; do
    case $arg in
        --dry-run|-n) DRY_RUN=1 ;;
        --install|-i) DO_INSTALL=1 ;;
        *) printf 'unknown option: %s\n' "$arg" >&2; exit 2 ;;
    esac
done

BACKUP_DIR=$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)
made_backup=0
changed=0

# Terminal colours only when stdout is a tty, so piping stays clean.
if [ -t 1 ]; then
    B=$(printf '\033[1m'); DIM=$(printf '\033[2m'); R=$(printf '\033[0m')
    GRN=$(printf '\033[32m'); YEL=$(printf '\033[33m'); RED=$(printf '\033[31m')
else
    B=''; DIM=''; R=''; GRN=''; YEL=''; RED=''
fi

say()  { printf '%s\n' "$*"; }
step() { printf '  %s%s%s %s\n' "$1" "$2" "$R" "$3"; }

# ── the link map ─────────────────────────────────────────────────────────────
# "<path in repo>:<path under $HOME>", one per line. The single source of
# truth for what gets linked — setup.txt describes it, this creates it.
LINKS='
.bashrc:.bashrc
.profile:.profile
.bash_profile:.bash_profile
.vimrc:.vimrc
.tmux.conf:.tmux.conf
nvim:.config/nvim
alacritty:.config/alacritty
agents/.claude:.claude
'

# `ln -s dir/ target` stores the trailing slash, so a link that is already
# correct can compare unequal to the path we'd write. Normalise before
# comparing, or every run "fixes" a link that was never broken.
strip_trailing_slash() {
    _p=$1
    while :; do
        case $_p in
            */) _p=${_p%/} ;;
            *)  break ;;
        esac
    done
    printf '%s' "$_p"
}

link_one() {
    src=$DOTFILES/$1
    dst=$HOME/$2

    if [ ! -e "$src" ]; then
        step "$RED" "✗" "$2 ${DIM}— missing in repo: $1$R"
        return 0
    fi

    # Already correct? Say nothing louder than "ok" and move on.
    if [ -L "$dst" ] &&
       [ "$(strip_trailing_slash "$(readlink "$dst")")" = "$(strip_trailing_slash "$src")" ]; then
        step "$DIM" "·" "${DIM}$2 already linked$R"
        return 0
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        if [ -L "$dst" ]; then
            step "$YEL" "~" "$2 ${DIM}would be repointed$R"
        elif [ -e "$dst" ]; then
            step "$YEL" "~" "$2 ${DIM}would be backed up, then linked$R"
        else
            step "$GRN" "+" "$2 ${DIM}would be linked$R"
        fi
        return 0
    fi

    mkdir -p "$(dirname "$dst")"

    # A real file or directory in the way gets preserved, never deleted. A
    # stale symlink is just a pointer, so it's replaced without ceremony.
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$2")"
        mv "$dst" "$BACKUP_DIR/$2"
        made_backup=1
        step "$YEL" "~" "$2 ${DIM}(original backed up)$R"
    elif [ -L "$dst" ]; then
        rm -f "$dst"
        step "$YEL" "~" "$2 ${DIM}(repointed)$R"
    else
        step "$GRN" "+" "$2"
    fi

    ln -sfn "$src" "$dst"
    changed=$((changed + 1))
}

# ── tools ────────────────────────────────────────────────────────────────────
# Mirrors the list in .bashrc. Kept as binary:package because the two names
# diverge often enough to matter (rg/ripgrep, nvim/neovim). The package name
# here is the Homebrew/apt one; pkg_name() remaps the few that differ elsewhere
# (gh→github-cli on Arch, and npm ships inside Homebrew's node formula).
TOOLS='git:git tmux:tmux nvim:neovim node:nodejs npm:npm fzf:fzf rg:ripgrep gh:gh jq:jq curl:curl'

# Which package manager we suggest, and use with --install. brew wins on macOS
# even when another manager is present; then the common Linux distro managers.
detect_pkg_mgr() {
    if   command -v brew   >/dev/null 2>&1; then echo brew
    elif command -v pacman >/dev/null 2>&1; then echo pacman
    elif command -v apt    >/dev/null 2>&1; then echo apt
    else echo ''
    fi
}

# Map a TOOLS package name to the given manager's name. Most agree; only the
# exceptions live here. An empty result means "no separate package on this
# manager" — e.g. npm is bundled with Homebrew's node formula.
pkg_name() {
    case "$2:$1" in
        pacman:gh)   echo github-cli ;;
        brew:nodejs) echo node ;;
        brew:npm)    echo '' ;;
        *)           echo "$1" ;;
    esac
}

# The human-facing install command, for when we're only reporting. $2 is a
# leading-space-separated package list.
install_cmd() {
    case $1 in
        brew)   printf 'brew install%s' "$2" ;;
        pacman) printf 'sudo pacman -S --needed%s' "$2" ;;
        apt)    printf 'sudo apt install%s' "$2" ;;
        *)      printf '(via your package manager):%s' "$2" ;;
    esac
}

# Actually install the missing packages. Word-splitting $2 is intentional.
run_install() {
    case $1 in
        brew)   brew install $2 ;;
        pacman) sudo pacman -S --needed $2 ;;
        apt)    sudo apt update && sudo apt install $2 ;;
    esac
}

report_tools() {
    mgr=$(detect_pkg_mgr)
    missing=''
    for entry in $TOOLS; do
        bin=${entry%%:*}
        name=$(pkg_name "${entry#*:}" "$mgr")
        if command -v "$bin" >/dev/null 2>&1; then
            step "$GRN" "✓" "${DIM}$bin$R"
        elif [ -z "$name" ]; then
            step "$YEL" "✗" "$bin ${DIM}→ bundled$R"
        else
            step "$RED" "✗" "$bin ${DIM}→ $name$R"
            missing="$missing $name"
        fi
    done

    [ -z "$missing" ] && return 0

    if [ "$DO_INSTALL" -eq 1 ] && [ "$DRY_RUN" -eq 0 ]; then
        if [ -z "$mgr" ]; then
            say ''
            say "  ${RED}!${R} no known package manager — install manually:$missing"
            return 0
        fi
        say ''
        say "  ${B}installing${R}${DIM} via $mgr${R}:$missing"
        run_install "$mgr" "$missing"
        return 0
    fi

    say ''
    say "  ${B}Install these yourself:${R}"
    say "    $(install_cmd "$mgr" "$missing")"
    if [ "$DRY_RUN" -eq 1 ] && [ "$DO_INSTALL" -eq 1 ]; then
        say "    ${DIM}(--dry-run: not run)$R"
    elif [ "$DO_INSTALL" -eq 0 ]; then
        say "    ${DIM}or re-run with --install to do it now$R"
    fi
}

check_bash() {
    # Apple ships bash 3.2 (2007) rather than GPLv3. Several things in .bashrc
    # need 4+, so flag it before the user wonders why globstar errors.
    major=$(echo "${BASH_VERSION:-0}" | cut -d. -f1)
    [ "${major:-0}" -ge 4 ] 2>/dev/null && return 0
    [ "$(uname -s)" != Darwin ] && return 0

    prefix=/usr/local
    [ -d /opt/homebrew ] && prefix=/opt/homebrew
    say ''
    say "  ${YEL}!${R} ${B}bash ${BASH_VERSION:-unknown}${R} — parts of .bashrc need bash 4+"
    say "    brew install bash"
    say "    sudo sh -c 'echo $prefix/bin/bash >> /etc/shells'"
    say "    chsh -s $prefix/bin/bash"
}

# ── run ──────────────────────────────────────────────────────────────────────
say ''
if [ "$DRY_RUN" -eq 1 ]; then
    say "${B}dotfiles${R} ${DIM}— dry run, nothing will be written${R}"
else
    say "${B}dotfiles${R} ${DIM}— $DOTFILES${R}"
fi

say ''
say "  ${B}links${R}"
for pair in $LINKS; do
    link_one "${pair%%:*}" "${pair#*:}"
done

say ''
say "  ${B}tools${R}"
report_tools
check_bash

say ''
if [ "$DRY_RUN" -eq 1 ]; then
    say "  ${DIM}re-run without --dry-run to apply${R}"
elif [ "$made_backup" -eq 1 ]; then
    say "  ${DIM}replaced files saved in $BACKUP_DIR${R}"
elif [ "$changed" -eq 0 ]; then
    say "  ${DIM}already up to date${R}"
fi
say "  ${DIM}open a new shell, or: exec \$SHELL -l${R}"
say ''
