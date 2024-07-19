PATH="$PATH:/snap/bin"
export PATH=$PATH:/usr/local/go/bin
source ~/.aliases
TITLEBAR='\[\e]0;\h\a\]'
export PS1="${TITLEBAR}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\$ "
