# The user-specific dirs are only added for non-root users — root shouldn't
# run things out of a user's home (matches the .bashrc behavior on Linux).
if [ "$EUID" -ne 0 ]; then
  export PATH=$HOME/.local/bin:$HOME/bin:$PATH
fi

# Add Cargo/Rust to PATH if installed (rustup writes ~/.cargo/env).
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# If a per-user Perl library exists (~/perl5, set up by local::lib / cpanm),
# load its env vars so `perl` and CPAN modules resolve from there.
[ -d "$HOME/perl5/lib/perl5" ] && eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"

# Point the linker at the active macOS SDK's lib dir so compiling/linking
# against system libraries works (xcrun resolves the current SDK path).
if command -v xcrun &>/dev/null; then
  export LIBRARY_PATH="$(xcrun --show-sdk-path)/usr/lib"
fi

# Prompt: user@host:dir%  — username red for root / green for normal users,
# hostname yellow, dir blue. zsh syntax: %{...%} wraps non-printing escapes,
# %F{color} sets color, %B bold (%b/%f reset), %n=user, %m=host, %1~=cwd
# (last component), %#=prompt char (% normally, # for root). %{\e]0;%m\a%}
# sets the terminal title to the hostname.
if [ "$EUID" -eq 0 ]; then
  export PROMPT=$'%{\e]0;%m\a%}%{%B%F{red}%}%n@%{%F{yellow}%}%m%{%b%f%}:%{%B%F{blue}%}%1~%{%b%f%}%# '
else
  export PROMPT=$'%{\e]0;%m\a%}%{%B%F{green}%}%n@%{%F{yellow}%}%m%{%b%f%}:%{%B%F{blue}%}%1~%{%b%f%}%# '
fi

# Keep PATH entries unique (drop duplicates) — zsh's equivalent of dedup.
typeset -U PATH

[ -f ~/.aliases ] && source ~/.aliases
