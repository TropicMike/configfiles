export PATH=$HOME/bin:$PATH
export PATH=$HOME/.local/bin:$PATH
[ -d "$HOME/perl5/lib/perl5" ] && eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"
if command -v xcrun &>/dev/null; then
  export LIBRARY_PATH="$(xcrun --show-sdk-path)/usr/lib"
fi
if [ "$EUID" -eq 0 ]; then
  export PROMPT=$'%{\e]0;%m\a%}%{%B%F{red}%}%n@%m%{%b%f%}:%{%B%F{blue}%}%1~%{%b%f%}%# '
else
  export PROMPT=$'%{\e]0;%m\a%}%{%B%F{green}%}%n@%m%{%b%f%}:%{%B%F{blue}%}%1~%{%b%f%}%# '
fi
typeset -U PATH

source ~/.aliases
