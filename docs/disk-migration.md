# New SSD: reinstall + restore

You need the backup USB stick (ext4, holds `home/` and `rootfs/`) and an Arch ISO USB stick.

## 1. archinstall

Boot the Arch ISO (F12 to pick the USB stick). For Wi-Fi: `iwctl station wlan0 connect <SSID>`. Then run `archinstall`:

| Setting | Value |
|---|---|
| Mirrors | South Korea |
| Disk | best-effort, ext4 (LVM with a separate /home is optional) |
| Bootloader | systemd-boot, unified kernel image: yes |
| Hostname | x220 |
| User | **chaseungjoon** (same name), sudo: yes |
| Profile | Minimal |
| Network | NetworkManager |
| Timezone | Asia/Seoul |

Reboot and log in on the tty. Connect to Wi-Fi with `nmtui`.

## 2. install.sh

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/chaseungjoon/arch.config/main/install.sh)
```

## 3. Restore files

```sh
sudo mount /dev/sdb1 /mnt                  # backup stick; check the name with lsblk
sudo rsync -aAXH /mnt/home/ /home/
```

Optional, both from `rootfs/`:

```sh
# saved Wi-Fi networks
sudo cp -a /mnt/rootfs/etc/NetworkManager/system-connections/. /etc/NetworkManager/system-connections/
# same Tailscale device + IP (otherwise run: sudo tailscale up --operator=$USER)
sudo systemctl stop tailscaled
sudo rsync -a /mnt/rootfs/var/lib/tailscale/ /var/lib/tailscale/
sudo systemctl start tailscaled
```

```sh
sudo umount /mnt && reboot
```

Log in on tty1 and i3 starts.
