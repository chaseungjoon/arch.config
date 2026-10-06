#!/usr/bin/env bash
# collect.sh — snapshot this machine's configuration into this repo.
#
# Safe to re-run any time: it rebuilds home/, system/ and meta/ from the live
# system, so `./collect.sh && git diff` shows exactly what changed since the
# last snapshot. Only the paths listed below are copied; secrets (ssh keys,
# tokens, shell history, browser profiles, wifi passwords, ...) are never
# listed and are additionally blocked by .gitignore.
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
H=$REPO/home        # mirrored into $HOME by install.sh
S=$REPO/system      # mirrored into / by install.sh (needs root)
R=$REPO/reference   # machine-specific files: kept for reference, never applied
M=$REPO/meta        # package lists, services, timezone, dconf

# ── dotfiles (relative to $HOME) ─────────────────────────────────────────
HOME_PATHS=(
    # shell + X session
    .zshrc .zprofile .bashrc .bash_profile
    .xinitrc .Xresources .tmux.conf .gitconfig
    # window manager, bar, launcher, notifications
    .config/i3 .config/i3blocks .config/rofi .config/dunst
    # apps
    .config/kitty .config/nvim .config/zathura .config/fastfetch
    .config/btop/btop.conf .config/lazygit/config.yml
    .config/coc/extensions/package.json
    .config/azote/azoterc
    # input method (Korean / hangul)
    .config/fcitx5/profile .config/fcitx5/config
    # look & feel
    .config/gtk-3.0/settings.ini .config/gtk-4.0/settings.ini
    .themes
    .local/share/backgrounds
    Pictures/retro-x220.png Pictures/retro-x220-sunset.png Pictures/peakpx.jpg
    # desktop integration
    .config/autostart .config/mimeapps.list
    .config/user-dirs.dirs .config/user-dirs.locale
    .local/share/applications/azote.desktop
)

# ── /etc files that are safe to apply on any machine ─────────────────────
SYSTEM_PATHS=(
    /etc/pacman.conf
    /etc/pacman.d/mirrorlist
    /etc/locale.gen
    /etc/locale.conf
    /etc/vconsole.conf
    /etc/systemd/zram-generator.conf
    /etc/X11/xorg.conf.d/00-keyboard.conf
    /etc/X11/xorg.conf.d/30-touchpad.conf
)

# ── /etc files tied to this disk/bootloader: reference only ─────────────
REFERENCE_PATHS=(
    /etc/fstab
    /etc/hostname
    /etc/kernel/cmdline
    /etc/mkinitcpio.conf
    /etc/mkinitcpio.d/linux.preset
    /etc/shells
    /etc/ufw/ufw.conf
    /etc/ufw/user.rules
    /etc/ufw/user6.rules
)

say() { printf '\033[38;5;214m::\033[0m %s\n' "$*"; }

say "dotfiles -> home/"
rm -rf "$H"; mkdir -p "$H"
present=()
for p in "${HOME_PATHS[@]}"; do
    if [[ -e $HOME/$p ]]; then present+=("$p"); else say "  skip (missing): ~/$p"; fi
done
# --exclude=.git: ~/.config/nvim is its own git checkout (chaseungjoon/nvim.config)
tar -C "$HOME" --exclude=.git -cf - "${present[@]}" | tar -C "$H" -xf -

# ~/.fehbg is written by azote/feh with an absolute path; make it user-agnostic
if [[ -f $HOME/.fehbg ]]; then
    sed -E "s|'$HOME/([^']*)'|\"\$HOME/\1\"|g" "$HOME/.fehbg" > "$H/.fehbg"
    chmod 755 "$H/.fehbg"
fi
# .desktop launchers can't expand $HOME in Exec=, so go through sh -c
find "$H/.local/share/applications" -name '*.desktop' -exec \
    sed -i -E "s|^Exec=$HOME/(.*)$|Exec=sh -c \"\\\\\$HOME/\1\"|" {} + 2>/dev/null || true

copy_root() {   # copy_root DEST_DIR FILE...
    local dest=$1; shift
    rm -rf "$dest"
    for f in "$@"; do
        if [[ -r $f ]]; then install -Dm644 "$f" "$dest$f"
        else say "  skip (unreadable/missing): $f"; fi
    done
}
say "system config -> system/"
copy_root "$S" "${SYSTEM_PATHS[@]}"
say "machine-specific config -> reference/"
copy_root "$R" "${REFERENCE_PATHS[@]}"

say "packages, services, desktop settings -> meta/"
rm -rf "$M"; mkdir -p "$M"
pacman -Qqen > "$M/pacman.txt"                       # explicitly installed, official repos
pacman -Qqem > "$M/aur.txt" || true                  # explicitly installed, AUR/foreign
systemctl list-unit-files --state=enabled --no-legend --no-pager \
    | awk '{print $1}' > "$M/services-system.txt"
systemctl --user list-unit-files --state=enabled --no-legend --no-pager \
    | awk '{print $1}' > "$M/services-user.txt"
readlink /etc/localtime | sed 's|.*/zoneinfo/||' > "$M/timezone"
command -v dconf >/dev/null && dconf dump / > "$M/dconf.ini" || true

say "done — review with: git -C '$REPO' status && git -C '$REPO' diff"
