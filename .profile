# ~/.profile — read by login shells. Deliberately POSIX (no [[ ]], no arrays)
# so a /bin/sh login works too.
#
# Bash prefers ~/.bash_profile when it exists, which is why that file exists
# and does nothing but source this one. macOS terminals start *login* shells,
# so that redirect is what makes this config reach a Mac at all.
#
# Order matters: PATH is assembled here first, and .bashrc is sourced last, so
# an interactive login shell sees the finished PATH.

# umask is set in /etc/profile; for ssh logins see libpam-umask.
#umask 022

# Idempotent — logging in twice, or re-sourcing, must not grow PATH.
# Intentionally duplicated in .bashrc: each file has to stand alone, because a
# non-login shell reads only .bashrc and never gets here.
_path_prepend() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) [ -d "$1" ] && PATH="$1:$PATH" ;;
    esac
}

_path_prepend "$HOME/bin"
_path_prepend "$HOME/.local/bin"

# pyenv splits cleanly: PATH here, `pyenv init` in .bashrc where we know the
# shell is bash. Running `pyenv init - bash` from a /bin/sh login would emit
# bash syntax into dash.
PYENV_ROOT="$HOME/.pyenv"
export PYENV_ROOT
_path_prepend "$PYENV_ROOT/bin"
_path_prepend "$PYENV_ROOT/shims"

[ -r "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

export PATH

# Interactive bash config last, so it inherits the complete PATH above.
if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
