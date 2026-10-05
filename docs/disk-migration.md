# Back up /home and move this install to a new SSD

Context: the X220's SSD (sold as a "KINGSTON SKC600/256G") returned uncorrectable read errors on
2026-10-05. Those errors corrupted one block of the `/home` inode table and dropped the machine
into emergency mode. SMART still shows one pending (unreadable) sector, and the drive under-reports
its own errors. Treat it as failing.

Current layout of the old disk:

```
sda   238.5G  KINGSTON SKC600/256G   (256,060,514,304 bytes)
├─sda1   1G   vfat  /boot   (systemd-boot + UKI)
└─sda2 237.5G  LVM2 PV  "ArchinstallVg"
   ├─root  32G   ext4  /
   └─home 205G   ext4  /home   (about 2 GB used)
```

There are two jobs, in this order:

1. **Today:** copy your files (`/home`) somewhere safe. This takes minutes and is what matters most.
2. **When the new SSD arrives:** clone the whole disk onto it, so it boots exactly as before.

---

## 1. File backup of /home (do this first)

You need an external USB drive with at least 5 GB free. Formatting it as ext4 keeps Linux
permissions and symlinks intact.

```sh
sudo pacman -S rsync                     # not installed yet
lsblk -o NAME,SIZE,MODEL,FSTYPE          # find the USB drive, e.g. sdb with partition sdb1

# only if the USB drive is new or empty — THIS ERASES IT:
sudo mkfs.ext4 -L x220-backup /dev/sdb1

sudo mount /dev/sdb1 /mnt
# close Firefox and other apps first so their files aren't changing mid-copy
sudo rsync -aAXH --info=progress2 /home/ /mnt/home/
# optional: the root filesystem too (configs, package database)
# (patterns are quoted one by one: zsh aborts on unquoted globs like /dev/*)
sudo rsync -aAXH --info=progress2 \
    --exclude='/dev/*' --exclude='/proc/*' --exclude='/sys/*' --exclude='/tmp/*' \
    --exclude='/run/*' --exclude='/mnt/*' --exclude='/media/*' --exclude='/home/*' \
    --exclude='/lost+found' --exclude='/var/cache/pacman/pkg/*' \
    / /mnt/rootfs/
sync && sudo umount /mnt
```

- rsync reads every file, so this also works as a health check. An `Input/output error` names a file
  sitting on another bad sector. Write those names down.
- This backup **does** include `~/.ssh` (your private key), `~/.gnupg` and browser profiles. Keep the
  drive private. Never push it anywhere.

Restoring onto any fresh Arch install (after running `install.sh`):

```sh
sudo mount /dev/sdb1 /mnt
sudo rsync -aAXH /mnt/home/ /home/
```

---

## 2. Clone the whole disk so the new SSD boots like nothing happened

A block-level clone copies everything: partition table, partition and filesystem UUIDs, LVM IDs,
the bootloader, and the UEFI boot entry's target. `fstab`, systemd-boot and the initramfs all keep
working unchanged. Use **ddrescue**, not `dd`. It copies the readable data first, retries bad areas
afterwards, and keeps a map of anything it couldn't read.

### Requirements

- **The new SSD must be at least 256,060,514,304 bytes.** Many "256 GB" SSDs are exactly that
  size. Many "250 GB" models (Samsung 870 EVO 250 GB, for example, is 250,059,350,016 bytes) are
  **too small** for a block clone. If yours is smaller, use section 3. To check, run
  `sudo blockdev --getsize64 /dev/sdX`.
- A 2.5" SATA SSD (the X220 bay takes 7 mm drives) and a USB-to-SATA adapter or enclosure.
- An Arch Linux ISO on a USB stick. It already includes `ddrescue`, `rsync` and `lsblk`.

### Steps

1. Shut down. Connect the **new** SSD through the USB adapter and plug in the Arch ISO stick.
2. Power on and press **F12**, then boot the USB stick. The old SSD stays inside but is not mounted,
   so it is read in a consistent state.
3. Identify the disks. **Triple-check this**, because the target gets overwritten:

   ```sh
   lsblk -o NAME,SIZE,MODEL,SERIAL
   # old: KINGSTON SKC600/256G  (normally sda)
   # new: your new SSD          (e.g. sdc)
   ```

4. Clone (replace `sdX` with the new SSD):

   ```sh
   ddrescue -f -n  /dev/sda /dev/sdX rescue.map    # pass 1: everything readable, skip bad spots quickly
   ddrescue -f -r3 /dev/sda /dev/sdX rescue.map    # pass 2: retry the bad spots 3 times
   ddrescuelog -t rescue.map                        # summary: look for "rescued: 100%"
   ```

   `rescue.map` lives in the live system's RAM. To keep it, copy it to the USB stick.
   If the summary shows anything still bad, keep the map: its positions can be mapped back to
   filesystem blocks and files, the same way the original fault was traced.

5. `poweroff`. Physically swap the drives: put the new SSD in the internal bay (one screw on the
   X220's side) and take the old one out.
   **Never boot with both drives connected.** They now have identical UUIDs and LVM IDs, so the
   wrong one could get mounted, and LVM will complain about duplicate PVs.

6. Boot normally. systemd-boot and the UKI load from the clone, `/` and `/home` mount from the clone,
   and your session looks exactly as it did before. Then run once:

   ```sh
   sudo fstrim -av                      # ddrescue wrote every block, so tell the new SSD what's free
   sudo smartctl -x /dev/sda            # healthy baseline for the new drive
   ```

   If the firmware can't find a boot entry, choose the disk in the F12 menu. systemd-boot also
   installs the fallback loader `\EFI\BOOT\BOOTX64.EFI`.

7. **Optional, if the new SSD is bigger.** Give the extra space to `/home`:

   ```sh
   sudo pacman -S parted
   sudo parted /dev/sda resizepart 2 100%
   sudo pvresize /dev/sda2
   sudo lvextend -r -l +100%FREE ArchinstallVg/home     # -r grows the ext4 filesystem too
   ```

8. If ddrescue reported unreadable areas, run a filesystem check from the live USB with the
   filesystems unmounted:

   ```sh
   vgchange -ay ArchinstallVg
   e2fsck -f /dev/ArchinstallVg/root
   e2fsck -f /dev/ArchinstallVg/home
   ```

Keep the old SSD untouched until the new one has booted and you've used it for a while.
After that, wipe it with `blkdiscard` before returning or discarding it.

---

## 3. Alternative: fresh install + restore (new SSD smaller, or you want a clean start)

1. Install Arch on the new SSD with `archinstall` (settings are in the README).
2. Run `install.sh` from this repo. That restores packages, `/etc`, services and every dotfile.
3. Restore your files from the section 1 backup: `sudo rsync -aAXH /mnt/home/ /home/`.

The result matches the old machine except for new disk UUIDs and whatever hostname and partition
sizes you picked in archinstall.
