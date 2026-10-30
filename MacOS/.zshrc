# The user-specific dirs (uv/local installs, ~/bin, Cargo/Rust, opencode) are
# only added for non-root users — root shouldn't run things out of a user's
# home, which under `sudo zsh` may still be the invoking user's (matches the
# .bashrc behavior on Linux). Resulting order: ~/.opencode/bin, Cargo,
# ~/.local/bin, ~/bin.
if [ "$EUID" -ne 0 ]; then
  export PATH=$HOME/.local/bin:$HOME/bin:$PATH
  # Add Cargo/Rust to PATH if installed (rustup writes ~/.cargo/env).
  [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
  export PATH=$HOME/.opencode/bin:$PATH
fi

# If a per-user Perl library exists (~/perl5, set up by local::lib / cpanm),
# load its env vars so `perl` and CPAN modules resolve from there.
[ -d "$HOME/perl5/lib/perl5" ] && eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"

# Point the linker at the active macOS SDK's lib dir so compiling/linking
# against system libraries works (xcrun resolves the current SDK path).
if command -v xcrun &>/dev/null; then
  export LIBRARY_PATH="$(xcrun --show-sdk-path)/usr/lib"
fi

# Claude Code mouse click handling: 0 (set here) keeps it enabled; set to 1
# to disable it so terminal-native click behavior (text selection, etc.)
# keeps working.
export CLAUDE_CODE_DISABLE_MOUSE_CLICKS=0

# Don't cycle through completion matches on repeated Tab — just list them
# (AUTO_MENU is on by default in zsh).
unsetopt AUTO_MENU

# Bash-style completion: first Tab completes the common prefix, second Tab
# lists the ambiguous matches.
setopt BASH_AUTO_LIST

# History: macOS's /etc/zshrc already sets HISTFILE (~/.zsh_history), but with
# small limits (HISTSIZE=2000, SAVEHIST=1000). Keep far more, share history
# between concurrent terminals as commands run, drop consecutive duplicates,
# and skip commands typed with a leading space.
HISTFILE=${HISTFILE:-$HOME/.zsh_history}
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

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
