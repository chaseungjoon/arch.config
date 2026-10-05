#!/bin/sh
# ~/.xinitrc — started by startx (auto-launched on tty1 from ~/.zprofile)

# system xinitrc snippets (imports DISPLAY/XAUTHORITY into systemd + dbus)
if [ -d /etc/X11/xinit/xinitrc.d ]; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

[ -f "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xresources"

# CapsLock -> Super
setxkbmap -layout us -option '' -option caps:super -option terminate:ctrl_alt_bksp


# smooth touchpad/trackpoint scrolling in firefox
export MOZ_USE_XINPUT2=1

xsetroot -cursor_name left_ptr -solid '#1c1b19'

exec i3
