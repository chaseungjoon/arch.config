# ~/.zprofile — login shell
export PATH="$HOME/.local/bin:$PATH"

# auto-start X + i3 when logging in on tty1 (other ttys stay plain consoles)
if [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]]; then
    exec startx
fi
