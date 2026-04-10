PATH="$PATH:/snap/bin"
export PATH=$PATH:$HOME/.local/bin
eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"
PATH="/Users/mikesa/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="/Users/mikesa/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/Users/mikesa/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/Users/mikesa/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/Users/mikesa/perl5"; export PERL_MM_OPT;

export PROMPT=$'%{\e]0;%m\a%}%{%B%F{green}%}%n@%m%{%b%f%}:%{%B%F{blue}%}%1~%{%b%f%}%# '
source ~/.aliases
