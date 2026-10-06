# arch.config

Complete configuration of my ThinkPad X220 running Arch Linux + i3. The look is
**AMBER-76**: a flat retro amber-on-charcoal palette with Terminess Nerd Font and
no compositor or effects.

`install.sh` turns a fresh Arch install into this machine.
`collect.sh` takes a new snapshot of this machine and saves it into the repo.

```
 palette  bg #1c1b19  bar/term #282828 (matches wallpaper)  bg1 #2a2723  fg #e8dcc0  amber #ffb000  orange #e8742c
          red #d0453b  mustard #f2c14e  green #8fb339  teal #3e9d9a  blue #4f7cac
```

## Fresh machine setup

1. Install Arch with `archinstall`. These settings match this machine:
   - **Profile:** minimal (no desktop; i3 comes from this repo)
   - **Bootloader:** systemd-boot (UEFI), **unified kernel image:** yes
   - **Disk:** ext4. LVM is optional (this machine uses it: 32 GiB root plus the rest for home)
   - **Network:** NetworkManager
   - **User:** your user, added to the sudo/wheel group
   - **Timezone / locale:** whatever you like (the installer sets Asia/Seoul and en_US.UTF-8)
2. Reboot, log in on the tty, and run:

   ```sh
   bash <(curl -fsSL https://raw.githubusercontent.com/chaseungjoon/arch.config/main/install.sh)
   ```

   This bootstraps git, clones the repo to `~/arch.config`, and runs the installer from there.
3. Do the manual steps it prints at the end (ssh key, `tailscale up`, Firefox sync, `:Copilot setup`).
   Then reboot. Logging in on **tty1** starts X and i3 automatically.

### What `install.sh` does

| Step | Details |
|---|---|
| pacman | Applies `pacman.conf` (Color, ParallelDownloads=5) and the Korean mirrorlist |
| packages | `pacman -S --needed` everything in `meta/pacman.txt`. Swaps `intel-ucode` for `amd-ucode` on AMD CPUs, skips packages that no longer exist, and installs AUR packages via yay if `meta/aur.txt` lists any |
| /etc | Copies `system/etc/**`: X11 keyboard (CapsLock → Super) and X220 touchpad/TrackPoint, zram (zstd), locale, console keymap |
| locale & time | `locale-gen`, timezone from `meta/timezone`, NTP on. Hostname changes only with `--hostname NAME` |
| kernel cmdline | Adds `zswap.enabled=0` (zram is used instead) to the UKI cmdline or systemd-boot entries |
| services | Enables everything in `meta/services-*.txt`: NetworkManager, bluetooth, tailscaled, ufw, power-profiles-daemon, fstrim.timer, paccache.timer, pipewire, … |
| firewall | ufw: deny incoming, allow outgoing, allow everything on `tailscale0` |
| shell | Sets the login shell to zsh |
| dotfiles | Copies `home/**` into `$HOME`. Any file it replaces goes to `~/.local/state/arch.config/backup-<time>/` first |
| extras | Creates XDG folders, loads dconf settings, rebuilds the font cache, installs nvim plugins (lazy.nvim) and coc extensions, caches tldr pages, installs Claude Code |

Options: `--yes`, `--hostname NAME`, `--no-packages`, `--no-system` (touches only `$HOME`, no sudo),
`--no-dotfiles`, `--no-claude`. Re-running is safe and only applies what changed.

## Keeping the repo up to date

```sh
cd ~/arch.config
./collect.sh          # re-snapshot dotfiles, /etc, package list, services
git diff              # review
git commit -am "update config" && git push
```

To track a new dotfile or `/etc` file, add its path to `HOME_PATHS`, `SYSTEM_PATHS` or
`REFERENCE_PATHS` at the top of `collect.sh`.

## Layout

```
install.sh            fresh machine → this machine
collect.sh            this machine → repo
home/                 mirrored into $HOME
  .zshrc .zprofile      zsh (amber prompt, fzf/zoxide, autosuggestions); tty1 → startx
  .xinitrc .Xresources  X session, 96 dpi, AMBER-76 X colours
  .tmux.conf            prefix Ctrl+S, AMBER-76 status line
  .config/i3/           i3 config + scripts (lock, OSD, power menu, screenshots, keysheet,
                        monitors, night light, wallpaper picker, persistent workspaces)
  .config/i3blocks/     status bar panels: SYS (cpu, mem, ssd, temp) · PWR (vol, lcd, bat)
  .config/kitty/        terminal
  .config/rofi/         launcher + amber76.rasi theme
  .config/dunst/        notifications + OSD bars
  .config/nvim/         neovim (lazy.nvim, coc, treesitter, telescope, neo-tree, AMBER-76 lualine)
  .config/zathura/ fastfetch/ btop/ lazygit/ fcitx5/ gtk-3.0/ gtk-4.0/ azote/ autostart/
  .themes/Amber76/      GTK theme used by azote
  .local/share/backgrounds/, Pictures/   wallpapers (peakpx.jpg is the default) and the lock screen image
system/etc/           applied to /etc by install.sh
reference/etc/        this machine's fstab, mkinitcpio, kernel cmdline, ufw rules, …
                      (disk/bootloader-specific, kept for reference, never applied)
meta/                 pacman.txt, aur.txt, services-system.txt, services-user.txt, timezone, dconf.ini
docs/disk-migration.md   new SSD: archinstall + install.sh + restore from the backup stick
```

## Keys

<kbd>Super</kbd>+<kbd>Shift</kbd>+<kbd>H</kbd> shows the full key sheet, and <kbd>Super</kbd>+<kbd>F1</kbd> searches every binding.
CapsLock is an extra Super.

| | |
|---|---|
| `Super+Enter` / `Super+Shift+Enter` / ``Super+` `` | terminal / floating / dropdown |
| `Super+R` `Super+D` `Super+Tab` | apps / commands / windows (rofi) |
| `Super+B` `Super+E` `Super+N` `Super+G` | firefox / yazi / neovim / lazygit |
| `Super+C` `Super+P` | calculator / clipboard history |
| `Super+HJKL` · `+Shift` · `+Ctrl` | focus · move · resize |
| `Super+Esc` `Super+Shift+E` | lock / power menu |
| `Print` `Super+Shift+S` `Super+Print` | screenshot screen / area / window |
| `Super+Shift+N` `Super+Shift+D` | night light / do not disturb |

## Intentionally not in this repo

The repo is public, so these never go in. They live only in the USB backup; `docs/disk-migration.md` restores them:

- `~/.ssh/` (keys and the ssh config with tailnet host IPs), `~/.gnupg/`
- tokens: `~/.config/github-copilot/`, `~/.copilot/`, `~/.claude/`, `~/.claude.json`, any `.env`
- `~/.zsh_history`, `~/.bash_history`, `~/.Xauthority`, `~/.config/pulse/cookie`
- the Firefox profile (use Firefox Sync), Wi-Fi passwords (`/etc/NetworkManager/system-connections`),
  tailscale state, `/etc/sudoers.d` (archinstall creates it)

## Machine-specific bits

Made for the X220 (Sandy Bridge, 1366×768 LVDS-1, Synaptics touchpad + TrackPoint, `BAT0`). On other
hardware everything still works, but you may want to edit `system/etc/X11/xorg.conf.d/30-touchpad.conf`,
the touchpad name in `home/.config/i3/config`, and `int=LVDS-1` in `home/.config/i3/scripts/monitors`.
