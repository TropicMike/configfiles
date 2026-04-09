PATH="$PATH:/snap/bin"
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/.local/bin
eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"
source ~/.aliases
export PROMPT=$'%{\e]0;%m\a%}%{%B%F{green}%}%n@%m%{%b%f%}:%{%B%F{blue}%}%1~%{%b%f%}%# '
