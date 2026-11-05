#!/bin/zsh
# ⌘⇧S in kitty: fuzzy-pick a Host from ~/.ssh/config, then open it in its own tab,
# named after the host.
#
#   Enter    herdr --remote <host>   your agents keep running there when you leave
#   ⌥Enter   kitten ssh <host>       plain shell; kitten ssh copies kitty's terminfo over,
#                                    so no "unknown terminal type xterm-kitty"
#
# The picker tab may open one new tab (launch --allow-remote-control), then closes.
# The herdr / ssh tab it opens gets no remote-control rights, so a remote host can
# never drive your local kitty.
PATH="$HOME/.local/bin:$PATH:/opt/homebrew/bin:/usr/local/bin:/Applications/kitty.app/Contents/MacOS"

# Host names come from ~/.ssh/config plus every file it pulls in with Include
# (your hosts live in ~/.ssh/config.d/hosts). Relative Include paths are relative
# to ~/.ssh, as in ssh itself.
files=(~/.ssh/config)
for inc in ${(f)"$(awk 'tolower($1) == "include" { for (i = 2; i <= NF; i++) print $i }' ~/.ssh/config 2>/dev/null)"}; do
  [[ -z $inc ]] && continue
  inc=${inc/#\~/$HOME}
  [[ $inc != /* ]] && inc=$HOME/.ssh/$inc
  files+=(${~inc}(N.))
done
hosts=$(awk 'tolower($1) == "host" { for (i = 2; i <= NF; i++) print $i }' $files 2>/dev/null | grep -v '[*?!]' | sort -u)
# `ssh-pick.sh --list` just prints the host names (handy for checking).
[[ $1 == --list ]] && { print -r -- $hosts; exit 0 }
if [[ -z $hosts ]]; then
  print "No Host entries found in ~/.ssh/config"
  read -k1 -s "?press any key"
  exit 1
fi

if (( $+commands[fzf] )); then
  out=$(print -r -- $hosts | fzf --prompt='host ❯ ' --reverse --border=rounded \
    --header='↵ herdr --remote   ⌥↵ plain ssh' --expect=alt-enter \
    --preview='ssh -G {} 2>/dev/null | grep -i -E "^(hostname|user|port|proxyjump) "' \
    --preview-window=right,45%)
  lines=("${(@f)out}")
  key=$lines[1] host=$lines[2]
else
  PS3='host › '
  select host in ${(f)hosts}; do break; done
  key=
fi
[[ -z $host ]] && exit 0

if [[ $key == alt-enter ]] || ! (( $+commands[herdr] )); then
  cmd=(kitten ssh $host)
else
  cmd=(herdr --remote $host)
fi
kitten @ launch --type=tab --tab-title="$host" --cwd="$HOME" -- "${cmd[@]}" >/dev/null
