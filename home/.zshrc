# ----- Environment -----
export PATH="$HOME/.local/bin:$PATH"
export EDITOR=nvim VISUAL=nvim PAGER=less
export LESS='-R --mouse --wheel-lines=3'
export BAT_THEME=gruvbox-dark
command -v bat >/dev/null && export MANPAGER="sh -c 'col -bx | bat -l man -p'" MANROFFOPT='-c'


# ----- History -----
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
unsetopt FLOW_CONTROL 

# ----- Completion -----
# tailscale has no packaged zsh completion: generate it once
ZFUNC="$HOME/.local/share/zsh/site-functions"
[[ -d $ZFUNC ]] || mkdir -p "$ZFUNC"
if command -v tailscale >/dev/null && [[ ! -s $ZFUNC/_tailscale ]]; then
    tailscale completion zsh > "$ZFUNC/_tailscale" 2>/dev/null
fi
fpath=("$ZFUNC" /usr/share/zsh/site-functions $fpath)

autoload -Uz compinit
compinit

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{214}-- %d --%f'
zstyle ':completion:*' group-name ''


# ----- Keybindings -----
bindkey -e
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[3~' delete-char
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line


# ----- Prompt (AMBER-76) -----
autoload -Uz vcs_info add-zsh-hook
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' stagedstr '+'
zstyle ':vcs_info:git:*' formats ' %F{108}%b%F{208}%u%c'
zstyle ':vcs_info:git:*' actionformats ' %F{108}%b%F{167}:%a'
add-zsh-hook precmd vcs_info
setopt PROMPT_SUBST
PROMPT='%F{214}%n%F{240}@%F{172}%m %F{223}%~${vcs_info_msg_0_} %(?.%F{214}.%F{167})>%f '
RPROMPT=''


# ----- Aliases -----
if command -v eza >/dev/null; then
    alias ls='eza --group-directories-first'
    alias ll='eza -l --group-directories-first --git --time-style=long-iso'
    alias la='eza -la --group-directories-first --git --time-style=long-iso'
    alias lt='eza --tree --level=2 --group-directories-first'
else
    alias ls='ls --color=auto'
    alias ll='ls -lh'
    alias la='ls -lah'
fi
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias v='nvim'
alias vim='nvim'
alias g='git'
alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate -20'
alias lg='lazygit'
alias ff='fastfetch'
alias ts='tailscale'
alias ..='cd ..'
alias ...='cd ../..'
alias update='sudo pacman -Syu'
alias cleanup='sudo pacman -Rns $(pacman -Qdtq)'
alias wifi='nmtui'
alias myip='curl -s ifconfig.me; echo'

# ssh: remote hosts (Ubuntu, macOS, ...) don't know kitty's TERM, which makes
# their shells redraw garbage like "exxieexixit"; send a universal TERM instead
ssh() {
    if [[ $TERM == xterm-kitty ]]; then TERM=xterm-256color command ssh "$@"
    else command ssh "$@"; fi
}

# yazi: cd into the directory you quit in
y() {
    local tmp="$(mktemp -t yazi-cwd.XXXXXX)" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(<"$tmp")" && [[ -n $cwd && $cwd != $PWD ]]; then cd -- "$cwd"; fi
    rm -f -- "$tmp"
}


# ----- Tools -----
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border=sharp --no-scrollbar \
  --color=bg+:#2a2723,bg:#1c1b19,fg:#e8dcc0,fg+:#ffb000,hl:#e8742c,hl+:#f2c14e \
  --color=border:#4a453e,info:#3e9d9a,prompt:#ffb000,pointer:#ffb000,marker:#8fb339,spinner:#3e9d9a,header:#9a8f7a \
  --prompt='> ' --pointer='▶' --marker='+'"
command -v fzf    >/dev/null && source <(fzf --zsh)
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

[[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#5a544a'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# must be sourced last
[[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# ----- Greeting -----
# system info on new terminals (not inside tmux / nvim / nested shells)
if [[ -o interactive && -z $TMUX && -z $NVIM && -z $FASTFETCH_SHOWN ]] && command -v fastfetch >/dev/null; then
    export FASTFETCH_SHOWN=1
    fastfetch
fi
