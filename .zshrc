export PATH=$HOME/bin:$PATH
export PATH=$HOME/.local/bin:$PATH
[ -d "$HOME/perl5/lib/perl5" ] && eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"
export LIBRARY_PATH="$(xcrun --show-sdk-path)/usr/lib"
typeset -U PATH # Remove dupe path entries

export PROMPT=$'%{\e]0;%m\a%}%{%B%F{green}%}%n@%m%{%b%f%}:%{%B%F{blue}%}%1~%{%b%f%}%# '
source ~/.aliases
