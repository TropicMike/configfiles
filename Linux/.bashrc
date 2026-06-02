PATH="$PATH:/snap/bin"
if [ "$EUID" -ne 0 ]; then
  PATH="$PATH:/usr/local/go/bin"
  PATH="$PATH:$HOME/.local/bin"
  PATH="$PATH:$HOME/bin"
fi
export PATH

source ~/.aliases

TITLEBAR='\[\e]0;\h\a\]'
if [ "$EUID" -eq 0 ]; then
  export PS1="${TITLEBAR}\[\033[01;31m\]\u@\[\033[01;33m\]\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\$ "
else
  export PS1="${TITLEBAR}\[\033[01;32m\]\u@\[\033[01;33m\]\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\$ "
fi
