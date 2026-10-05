#!/usr/bin/env bash
# install.sh — turn a fresh Arch Linux install into the x220 "AMBER-76" i3 setup.
#
# Run as your normal user (with sudo rights) from a tty on a fresh Arch install:
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/chaseungjoon/arch.config/main/install.sh)
#
# or, if you already cloned the repo:
#
#   ./install.sh [options]
#
# options
#   --yes             don't ask for confirmation
#   --hostname NAME   also set the hostname (default: leave it alone)
#   --no-packages     skip pacman/AUR package installation
#   --no-system       skip everything that writes outside $HOME (no sudo needed)
#   --no-dotfiles     skip copying dotfiles into $HOME
#   --no-claude       skip installing Claude Code
#   -h, --help        show this help
#
# Idempotent: re-running only re-applies what changed. Every file it would
# overwrite is first saved under ~/.local/state/arch.config/backup-<timestamp>/
# (dotfiles) or as <file>.pre-arch-config (system files).
set -euo pipefail

REPO_URL=https://github.com/chaseungjoon/arch.config.git
DEST=${ARCH_CONFIG_DIR:-$HOME/arch.config}

ORIG_ARGS=("$@")
ASSUME_YES=0 DO_PACKAGES=1 DO_SYSTEM=1 DO_DOTFILES=1 DO_CLAUDE=1 NEW_HOSTNAME=
while (($#)); do
    case $1 in
        --yes|-y)      ASSUME_YES=1 ;;
        --hostname)    NEW_HOSTNAME=${2:?--hostname needs a value}; shift ;;
        --no-packages) DO_PACKAGES=0 ;;
        --no-system)   DO_SYSTEM=0 DO_PACKAGES=0 ;;
        --no-dotfiles) DO_DOTFILES=0 ;;
        --no-claude)   DO_CLAUDE=0 ;;
        -h|--help)     sed -n '2,/^set -euo/{/^set -euo/d;s/^# \{0,1\}//;p}' "${BASH_SOURCE[0]}"; exit 0 ;;
        *) echo "unknown option: $1 (see --help)" >&2; exit 2 ;;
    esac
    shift
done

# ── output helpers (AMBER-76, of course) ────────────────────────────────
c_amber=$'\033[38;5;214m' c_red=$'\033[38;5;167m' c_dim=$'\033[38;5;245m' c_off=$'\033[0m'
step() { printf '\n%s▌ %s%s\n' "$c_amber" "$*" "$c_off"; }
info() { printf '%s  %s%s\n' "$c_dim" "$*" "$c_off"; }
warn() { printf '%s  ! %s%s\n' "$c_red" "$*" "$c_off" >&2; WARNINGS+=("$*"); }
die()  { printf '%s✗ %s%s\n' "$c_red" "$*" "$c_off" >&2; exit 1; }
WARNINGS=()

# ── preflight ───────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] || die "run this as your normal user, not root (it uses sudo where needed)"
[[ -f /etc/arch-release ]] || die "this script is for Arch Linux"

# Running via curl? Bootstrap: install git, clone the repo, re-exec from the clone.
SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)
if [[ ! -d $SELF_DIR/home || ! -d $SELF_DIR/meta ]]; then
    step "bootstrapping: fetching $REPO_URL -> $DEST"
    command -v git >/dev/null || sudo pacman -Sy --needed --noconfirm git
    if [[ -d $DEST/.git ]]; then git -C "$DEST" pull --ff-only
    else git clone "$REPO_URL" "$DEST"; fi
    # `curl ... | bash` leaves stdin on the pipe; give the real run the terminal back
    if [[ ! -t 0 ]] && { : </dev/tty; } 2>/dev/null; then
        exec bash "$DEST/install.sh" "${ORIG_ARGS[@]}" </dev/tty
    fi
    exec bash "$DEST/install.sh" "${ORIG_ARGS[@]}"
fi
REPO=$SELF_DIR

cat <<EOF
${c_amber}
  ▌▌▌▌▌  arch.config installer
${c_off}  repo       $REPO
  packages   $([[ $DO_PACKAGES == 1 ]] && echo "yes ($(grep -c . "$REPO/meta/pacman.txt") from pacman.txt)" || echo no)
  system     $([[ $DO_SYSTEM == 1 ]] && echo "yes (/etc config, services, firewall, shell)" || echo no)
  dotfiles   $([[ $DO_DOTFILES == 1 ]] && echo "yes (existing files are backed up first)" || echo no)
  hostname   ${NEW_HOSTNAME:-unchanged}
EOF
if [[ $ASSUME_YES != 1 ]]; then
    read -r -p "continue? [y/N] " ans </dev/tty
    [[ $ans == [yY]* ]] || die "aborted"
fi

if [[ $DO_SYSTEM == 1 ]]; then
    sudo -v || die "sudo is required (or use --no-system)"
    # keep the sudo timestamp fresh for the whole run
    while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
fi

# put_root SRC DEST — install a system file, keeping the original once
put_root() {
    local src=$1 dst=$2
    if [[ -f $dst ]] && sudo cmp -s "$src" "$dst"; then return 0; fi
    if [[ -f $dst && ! -e $dst.pre-arch-config ]]; then sudo cp -a "$dst" "$dst.pre-arch-config"; fi
    sudo install -Dm644 "$src" "$dst"
    info "wrote $dst"
}

# ── 1. pacman configuration (before installing anything) ──────────────
if [[ $DO_SYSTEM == 1 ]]; then
    step "pacman configuration"
    put_root "$REPO/system/etc/pacman.conf" /etc/pacman.conf
    put_root "$REPO/system/etc/pacman.d/mirrorlist" /etc/pacman.d/mirrorlist
fi

# ── 2. packages ─────────────────────────────────────────────────────────
if [[ $DO_PACKAGES == 1 ]]; then
    step "packages (official repos)"
    sudo pacman -Syu --noconfirm

    mapfile -t wanted < <(grep -Ev '^\s*(#|$)' "$REPO/meta/pacman.txt")
    # CPU microcode: use the one that matches this machine's CPU
    ucode=intel-ucode; grep -q AuthenticAMD /proc/cpuinfo && ucode=amd-ucode
    for i in "${!wanted[@]}"; do
        if [[ ${wanted[i]} == intel-ucode || ${wanted[i]} == amd-ucode ]]; then wanted[i]=$ucode; fi
    done
    # drop anything that no longer exists in the repos instead of failing the whole transaction
    export LC_ALL=C
    mapfile -t install < <(comm -12 <(printf '%s\n' "${wanted[@]}" | sort -u) <(pacman -Slq | sort -u))
    mapfile -t missing < <(comm -23 <(printf '%s\n' "${wanted[@]}" | sort -u) <(pacman -Slq | sort -u))
    unset LC_ALL
    if ((${#missing[@]})); then warn "not in the repos anymore, skipped: ${missing[*]}"; fi
    sudo pacman -S --needed --noconfirm "${install[@]}"

    mapfile -t aur < <(grep -Ev '^\s*(#|$)' "$REPO/meta/aur.txt" 2>/dev/null || true)
    if ((${#aur[@]})); then
        step "packages (AUR, via yay)"
        if ! command -v yay >/dev/null; then
            tmp=$(mktemp -d)
            git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
            (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
            rm -rf "$tmp"
        fi
        yay -S --needed --noconfirm "${aur[@]}" || warn "some AUR packages failed: ${aur[*]}"
    fi
fi

# ── 3. system configuration ─────────────────────────────────────────────
if [[ $DO_SYSTEM == 1 ]]; then
    step "system configuration (/etc)"
    while IFS= read -r -d '' f; do
        rel=${f#"$REPO/system"}
        case $rel in /etc/pacman.conf|/etc/pacman.d/mirrorlist) continue ;; esac
        put_root "$f" "$rel"
    done < <(find "$REPO/system" -type f -print0)

    step "locale, timezone, hostname"
    sudo locale-gen >/dev/null && info "locales generated: $(grep -Ev '^\s*(#|$)' /etc/locale.gen | awk '{print $1}' | xargs)"
    tz=$(<"$REPO/meta/timezone")
    if [[ -f /usr/share/zoneinfo/$tz ]]; then
        sudo ln -sf "/usr/share/zoneinfo/$tz" /etc/localtime && info "timezone: $tz"
    else
        warn "unknown timezone '$tz'"
    fi
    sudo timedatectl set-ntp true 2>/dev/null || true
    if [[ -n $NEW_HOSTNAME ]]; then
        sudo hostnamectl set-hostname "$NEW_HOSTNAME" && info "hostname: $NEW_HOSTNAME"
    fi

    step "kernel command line (zswap off — zram swap is used instead)"
    if [[ -f /etc/kernel/cmdline ]]; then          # UKI setup (archinstall + systemd-boot)
        if ! grep -q 'zswap.enabled=0' /etc/kernel/cmdline; then
            sudo cp -n /etc/kernel/cmdline /etc/kernel/cmdline.pre-arch-config
            sudo sed -i '1s/$/ zswap.enabled=0/' /etc/kernel/cmdline
            sudo mkinitcpio -P && info "added zswap.enabled=0 and rebuilt the UKI"
        else info "already set"; fi
    elif sudo test -d /boot/loader/entries; then    # systemd-boot with plain entries
        changed=0
        for e in $(sudo find /boot/loader/entries -name '*.conf'); do
            if sudo grep -q '^options' "$e" && ! sudo grep -q 'zswap.enabled=0' "$e"; then
                sudo cp -n "$e" "$e.pre-arch-config" 2>/dev/null || true
                sudo sed -i '/^options/s/$/ zswap.enabled=0/' "$e"; changed=1
            fi
        done
        info "$([[ $changed == 1 ]] && echo "added zswap.enabled=0 to systemd-boot entries" || echo "already set")"
    else
        warn "unknown bootloader: add 'zswap.enabled=0' to your kernel command line by hand"
    fi

    step "services"
    while IFS= read -r unit; do
        [[ -z $unit ]] && continue
        if systemctl list-unit-files "$unit" --no-legend 2>/dev/null | grep -q .; then
            sudo systemctl enable "$unit" >/dev/null 2>&1 && info "enabled $unit" || warn "could not enable $unit"
        else
            warn "unit $unit not installed, skipped"
        fi
    done < "$REPO/meta/services-system.txt"
    while IFS= read -r unit; do
        [[ -z $unit ]] && continue
        systemctl --user enable "$unit" >/dev/null 2>&1 && info "enabled (user) $unit" \
            || warn "could not enable user unit $unit (log in once and re-run, or ignore)"
    done < "$REPO/meta/services-user.txt"

    step "firewall (ufw: deny incoming, allow everything on tailscale0)"
    if command -v ufw >/dev/null; then
        sudo ufw default deny incoming >/dev/null
        sudo ufw default allow outgoing >/dev/null
        sudo ufw default deny routed >/dev/null
        sudo ufw allow in on tailscale0 comment tailscale >/dev/null
        sudo ufw logging low >/dev/null
        sudo ufw --force enable >/dev/null && info "ufw enabled" \
            || warn "ufw could not start now (normal right after a kernel update) — it starts on next boot"
    else
        warn "ufw not installed"
    fi

    step "login shell"
    if [[ $(getent passwd "$USER" | cut -d: -f7) != */zsh ]]; then
        sudo chsh -s /usr/bin/zsh "$USER" && info "login shell is now zsh"
    else info "already zsh"; fi
fi

# ── 4. dotfiles ─────────────────────────────────────────────────────────
if [[ $DO_DOTFILES == 1 ]]; then
    step "dotfiles -> $HOME"
    backup=$HOME/.local/state/arch.config/backup-$(date +%Y%m%d-%H%M%S)
    n_new=0 n_same=0 n_backed=0
    while IFS= read -r -d '' f; do
        rel=${f#"$REPO/home/"}
        dst=$HOME/$rel
        if [[ -e $dst || -L $dst ]]; then
            if cmp -s "$f" "$dst"; then n_same=$((n_same + 1)); continue; fi
            mkdir -p "$(dirname "$backup/$rel")"
            mv "$dst" "$backup/$rel"; n_backed=$((n_backed + 1))
        fi
        mkdir -p "$(dirname "$dst")"
        cp -a --no-preserve=ownership "$f" "$dst"
        n_new=$((n_new + 1))
    done < <(find "$REPO/home" \( -type f -o -type l \) -print0)
    info "$n_new written, $n_same already up to date, $n_backed old files saved to ${backup/#$HOME/\~}"
    if [[ $n_backed == 0 ]]; then rmdir -p "$backup" 2>/dev/null || true; fi

    # create every XDG dir (Desktop, Downloads, ...) — xdg-user-dirs-update, which also
    # runs at each login, resets any entry whose folder is missing back to $HOME
    sed -n 's/^XDG_[A-Z]*_DIR="\$HOME\/\(.*\)"$/\1/p' "$HOME/.config/user-dirs.dirs" 2>/dev/null |
        while IFS= read -r d; do [[ -n $d ]] && mkdir -p "$HOME/$d"; done
    mkdir -p "$HOME/Pictures/Screenshots" "$HOME/code"

    step "desktop settings (dconf), fonts"
    if [[ -s $REPO/meta/dconf.ini ]] && command -v dconf >/dev/null; then
        dconf load / < "$REPO/meta/dconf.ini" 2>/dev/null \
            || dbus-run-session -- dconf load / < "$REPO/meta/dconf.ini" 2>/dev/null \
            || warn "dconf load failed (harmless: only GTK file-chooser/blueman window prefs)"
    fi
    fc-cache -f >/dev/null 2>&1 && info "font cache rebuilt"

    step "neovim plugins + coc extensions"
    if command -v nvim >/dev/null; then
        timeout 600 nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 \
            && info "lazy.nvim plugins installed" || warn "nvim plugin sync failed — open nvim and run :Lazy sync"
    fi
    if command -v npm >/dev/null && [[ -f $HOME/.config/coc/extensions/package.json ]]; then
        (cd "$HOME/.config/coc/extensions" &&
            npm install --global-style --ignore-scripts --no-bin-links --no-package-lock --omit=dev >/dev/null 2>&1) \
            && info "coc extensions installed" || warn "coc extensions failed — run :CocInstall coc-python coc-clangd coc-json"
    fi
    if command -v tldr >/dev/null; then tldr --update >/dev/null 2>&1 && info "tldr pages cached" || true; fi
fi

# ── 5. Claude Code ──────────────────────────────────────────────────────
if [[ $DO_CLAUDE == 1 ]] && [[ ! -x $HOME/.local/bin/claude ]]; then
    step "Claude Code"
    curl -fsSL https://claude.ai/install.sh | bash >/dev/null 2>&1 \
        && info "installed to ~/.local/bin/claude" || warn "Claude Code install failed (re-run with: curl -fsSL https://claude.ai/install.sh | bash)"
fi

# ── done ────────────────────────────────────────────────────────────────
step "done"
cat <<EOF
  still to do by hand (secrets are deliberately not in this repo):
    • ssh key        ssh-keygen -t ed25519   (or restore ~/.ssh from your backup)
                     then add the .pub key at https://github.com/settings/keys
    • tailscale      sudo tailscale up --operator=\$USER
    • firefox        sign in to sync bookmarks/extensions
    • copilot        open nvim and run :Copilot setup
    • reboot         then log in on tty1 — X + i3 start automatically
EOF
if ((${#WARNINGS[@]})); then
    printf '\n%s  warnings:%s\n' "$c_red" "$c_off"
    printf '    - %s\n' "${WARNINGS[@]}"
fi
