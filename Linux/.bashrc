# If not running interactively, stop here. This prevents the aliases,
# functions, and prompt below from being set up for non-interactive shells
# (e.g. scripts, scp/rsync, cron). $- holds the current shell flags; it
# contains 'i' only for interactive shells.
case $- in *i*) ;; *) return;; esac


# /snap/bin goes on PATH for everyone. The user-specific dirs (Go toolchain,
# pip/local installs, ~/bin) are only added for non-root users — root doesn't
# need them and shouldn't run things out of a user's home.
PATH="$PATH:/snap/bin"
if [ "$EUID" -ne 0 ]; then
  PATH="$PATH:/usr/local/go/bin"
  PATH="$PATH:$HOME/.local/bin"
  PATH="$PATH:$HOME/bin"
fi
export PATH


source ~/.aliases


# Escape sequence that sets the terminal window/tab title to the hostname (\h).
# \e]0; ... \a is the OSC "set title" control string; embedded in PS1 below so
# the title refreshes on every prompt.
TITLEBAR='\[\e]0;\h\a\]'

# Prompt: user@host:dir$  — username colored red for root / green for normal
# users (visual warning that you're root), hostname yellow, dir blue.
# \[...\] wraps non-printing escapes so bash computes line length correctly;
# 01;31=bold red, 01;32=bold green, 01;33=bold yellow, 01;34=bold blue, 00=reset.
if [ "$EUID" -eq 0 ]; then
  export PS1="${TITLEBAR}\[\033[01;31m\]\u@\[\033[01;33m\]\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\$ "
else
  export PS1="${TITLEBAR}\[\033[01;32m\]\u@\[\033[01;33m\]\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\$ "
fi
