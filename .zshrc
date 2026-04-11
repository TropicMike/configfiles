export PATH=$HOME/.local/bin:$PATH
eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"

export PROMPT=$'%{\e]0;%m\a%}%{%B%F{green}%}%n@%m%{%b%f%}:%{%B%F{blue}%}%1~%{%b%f%}%# '
source ~/.aliases
