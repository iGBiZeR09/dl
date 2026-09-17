#!/usr/bin/env bash
set -euo pipefail

echo "=== Image Flashing & Disk Setup Utility ==="

die() { echo "ERROR: $*" >&2; exit 1; }

# List available block devices
list_disks() {
  echo -e "\nAvailable block devices:"
  lsblk -a -p -o NAME,TRAN,TYPE,SIZE,MODEL | grep -Ev "ram" || true
  echo
}

# Normalize and validate device path
normalize_device() {
  local dev="/dev/${1#/dev/}"
  [[ -b "$dev" ]] || die "Block device '$dev' not found."
  echo "$dev"
}

# Get partition device name handling nvme/mmcblk naming
get_part_name() {
  local disk="$1" part_num="$2"
  if [[ "$disk" =~ (loop|nvme|mmcblk) ]]; then
    echo "${disk}p${part_num}"
  else
    echo "${disk}${part_num}"
  fi
}

# Wait for a block device node to appear
wait_for_part() {
  local part="$1" timeout="${2:-10}" waited=0
  while [[ ! -b "$part" && $waited -lt $((timeout * 2)) ]]; do
    sleep 0.5
    waited=$((waited + 1))
  done
  [[ -b "$part" ]] || { echo "Warning: Device $part did not appear after ${timeout}s"; return 1; }
}

# Confirm destructive action
confirm_action() {
  local target="$1"
  read -rn1 -p "Confirm action on $target? [y/N]: " c; echo
  if [[ ! "$c" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    return 1
  fi
}

# GUI partitioner runner
run_partitioner() {
  local cmd="$1"
  echo "Launching: $cmd"
  sudo --preserve-env=DISPLAY,XAUTHORITY $cmd &
  read -rp "Press ENTER when finished with the partitioner..."
}

# Unmount all active partitions on target
unmount_target() {
  local disk="$1"
  sudo sync
  sudo umount "${disk}"* 2>/dev/null || true
}

# Ensure kernel sees partition changes and udev settled
rescan_and_settle() {
  local disk="$1"
  sudo sync
  sudo partprobe "$disk" 2>/dev/null || true
  sudo udevadm settle 2>/dev/null || true
  sudo systemctl daemon-reload 2>/dev/null || true
  sleep 1
}

# Flashing helper
flash_image() {
  local image="$1" target="$2"
  [[ -f "$image" && -r "$image" ]] || die "Image '$image' not found or unreadable."
  [[ -b "$target" ]] || die "Target '$target' is not a valid block device."
  if mount | grep -q "^$target"; then die "Target $target is mounted. Unmount first."; fi

  if [[ "$image" == *.xz ]]; then
    if command -v xzcat >/dev/null 2>&1; then
      sudo xzcat "$image" | sudo dd of="$target" bs=4k status=progress conv=fdatasync
    elif command -v 7z >/dev/null 2>&1; then
      sudo 7z x -so "$image" | sudo dd of="$target" bs=4k status=progress conv=fdatasync
    else
      die "Neither xzcat nor 7z is installed."
    fi
  elif [[ "$image" =~ \.(img|iso|raw)$ ]]; then
    sudo dd if="$image" of="$target" bs=4k status=progress conv=fdatasync
  else
    die "Unsupported image extension."
  fi

  sudo sync
  echo "Flashing complete."
}

wipe_disk_completely() {
  list_disks
  read -rp "Enter disk to WIPE (e.g., sdb): " disk_in
  local disk; disk=$(normalize_device "$disk_in")
  
  confirm_action "$disk" || return 1
  unmount_target "$disk"

  if [[ "$disk" =~ (nvme|mmcblk) ]] || [[ $(cat "/sys/block/${disk##*/}/queue/rotational" 2>/dev/null) -eq 0 ]]; then
    echo "SSD detected. Using blkdiscard..."
    sudo blkdiscard -f "$disk" || sudo wipefs -a "$disk"
  else
    echo "HDD detected. Using wipefs..."
    sudo wipefs -a "$disk"
  fi

  read -rn1 -p "Overwrite disk with zeroes using DD? [y/N]: " use_dd; echo
  if [[ "$use_dd" =~ ^[Yy]$ ]]; then
    sudo dd if=/dev/zero of="$disk" bs=4k status=progress conv=fdatasync || true
  fi
  echo "Disk $disk wiped successfully."
}

create_gpt_partitions() {
  local disk="$1"
  unmount_target "$disk"

  sudo wipefs -a "$disk"
  sudo parted -s "$disk" \
    mklabel gpt \
    mkpart bios 4MiB 8MiB \
    set 1 bios_grub on \
    mkpart efi fat32 8MiB 136MB \
    mkpart f2fs f2fs 136MB 100GB \
    mkpart f2fs f2fs 100GB 100%

  rescan_and_settle "$disk"

  local p1 p2 p3 p4
  p1=$(get_part_name "$disk" 1)
  p2=$(get_part_name "$disk" 2)
  p3=$(get_part_name "$disk" 3)
  p4=$(get_part_name "$disk" 4)

  wait_for_part "$p2" 10
  wait_for_part "$p3" 10
  wait_for_part "$p4" 10

  sudo mkfs.vfat -F 32 "$p2"
  sudo mkfs.f2fs -f -a 1 -o 0 -O extra_attr,flexible_inline_xattr,inode_checksum,sb_checksum,compression "$p3" || die "mkfs.f2fs failed on $p3"
  sudo mkfs.f2fs -f -a 1 -o 0 -O extra_attr,flexible_inline_xattr,inode_checksum,sb_checksum,compression "$p4" || die "mkfs.f2fs failed on $p4"
  #sudo mkfs.ext4 -F -b 4096 -m 0 -O "has_journal,sparse_super,dir_index" "$p3" || die "mkfs.ext4 failed on $p3"
  #sudo mkfs.ext4 -F -b 4096 -m 0 -O "has_journal,sparse_super,dir_index" "$p4" || die "mkfs.ext4 failed on $p4"
  #sudo mkfs.btrfs -fv -s 4K -n 32K -O no-holes "$p3" || die "mkfs.btrfs failed on $p3"
  #sudo mkfs.btrfs -fv -s 4K -n 32K -O no-holes "$p4" || die "mkfs.btrfs failed on $p4"
  #sudo mkfs.xfs -f -s size=4096 -b size=4096 -n size=64k -l size=64m,lazy-count=1 "$p3" || die "mkfs.xfs failed on $p3"
  #sudo mkfs.xfs -f -s size=4096 -b size=4096 -n size=64k -l size=64m,lazy-count=1 "$p4" || die "mkfs.xfs failed on $p4"

  rescan_and_settle "$disk"
  sudo parted -s "$disk" print
}

create_mbr_partitions() {
  local disk="$1"
  unmount_target "$disk"

  sudo wipefs -a "$disk"
  sudo parted -s "$disk" \
    mklabel msdos \
    mkpart primary fat32 8MiB 136MB \
    set 1 boot on \
    mkpart primary ext4 136MB 100%

  rescan_and_settle "$disk"

  local p1 p2
  p1=$(get_part_name "$disk" 1)
  p2=$(get_part_name "$disk" 2)

  wait_for_part "$p1" 10
  wait_for_part "$p2" 10

  sudo mkfs.vfat -F 32 -I -a "$p1"
  #sudo mkfs.btrfs -fv -s 4K -n 16K -O no-holes "$p2" || die "mkfs.btrfs failed on $p2"
  sudo mkfs.f2fs -f -a 1 -o 0 -O extra_attr,flexible_inline_xattr,inode_checksum,sb_checksum,compression "$p2" || die "mkfs.f2fs failed on $p2"
  #sudo mkfs.ext4 -F -b 4096 -m 0 -E stride=2,stripe-width=2 -O "^has_journal,sparse_super,dir_index" "$p2" || die "mkfs.ext4 failed on $p2"
  #sudo mkfs.xfs -f -s size=4096 -b size=4096 -d agcount=2 -m reflink=0 -n size=64k -l size=64m,lazy-count=1 "$p2" || die "mkfs.xfs failed on $p2"

  rescan_and_settle "$disk"
  sudo parted -s "$disk" print
}

mount_efi() {
  local disk="$1" efnum="$2" mountp="$3"
  local part; part=$(get_part_name "$disk" "$efnum")

  [[ -b "$part" ]] || die "Partition $part does not exist."
  sudo mkdir -p "$mountp"
  sudo umount "$part" 2>/dev/null || true
  sudo mount "$part" "$mountp"
}

install_grub() {
  local disk="$1" efi_mount="$2"
  rescan_and_settle "$disk"

  [[ -d "$efi_mount" ]] || die "Mountpoint $efi_mount missing."

  echo "Installing UEFI GRUB..."
  sudo grub-install --target=x86_64-efi --boot-directory="$efi_mount/minios/boot" --efi-directory="$efi_mount/minios/boot" --removable || true

  echo "Installing BIOS GRUB..."
  sudo grub-install --target=i386-pc --boot-directory="$efi_mount/minios/boot" "$disk" --recheck --force || true

  unmount_target "$disk"
}

create_gpt_disk() {
  list_disks
  read -rp "Enter target disk (e.g., sdb): " disk_in
  local disk; disk=$(normalize_device "$disk_in")
  confirm_action "$disk" || return 1

  create_gpt_partitions "$disk"

  local efnum=2
  local default_mnt="/mnt/${disk##*/}p${efnum}"
  local mountp="${mountp:-$default_mnt}"

  mount_efi "$disk" "$efnum" "$mountp"
  install_grub "$disk" "$mountp"
}

create_mbr_disk() {
  list_disks
  read -rp "Enter target disk (e.g., sdb): " disk_in
  local disk; disk=$(normalize_device "$disk_in")
  confirm_action "$disk" || return 1

  create_mbr_partitions "$disk"

  local efnum=1
  local default_mnt="/mnt/${disk##*/}${efnum}"
  local mountp="${mountp:-$default_mnt}"

  mount_efi "$disk" "$efnum" "$mountp"
  install_grub "$disk" "$mountp"
}

install_grub_only() {
  list_disks
  read -rp "Enter target disk (e.g., sdb): " disk_in
  local disk; disk=$(normalize_device "$disk_in")

  sudo parted -s "$disk" print
  read -rp "Enter EFI partition number: " efnum

  local mountp="/mnt/${disk##*/}${efnum}"
  mount_efi "$disk" "$efnum" "$mountp"
  install_grub "$disk" "$mountp"
}

show_disk_details() {
  list_disks
  read -rp "Enter disk to inspect (or ENTER to skip): " disk_in
  if [[ -n "$disk_in" ]]; then
    local disk; disk=$(normalize_device "$disk_in")
    echo -e "\n--- Parted ---"
    sudo parted -s "$disk" print
    echo -e "\n--- BLKID ---"
    sudo blkid "${disk}"* || true
    echo -e "\n--- LSBLK ---"
    lsblk -a -p -o NAME,TYPE,FSTYPE,SIZE,MOUNTPOINT,LABEL,UUID "$disk" || true
  fi
}

main() {
  while true; do
    echo -e "\nMain Menu:"
    echo "1) Show Disk Details"
    echo "2) Create MBR Disk (partitions, format, GRUB)"
    echo "3) Create GPT Disk (partitions, format, GRUB)"
    echo "4) Install GRUB to Existing EFI Partition"
    echo "5) Flash Linux iMage (entire device)"
    echo "6) Flash Windows iMage (partition)"
    echo "7) Wipe Disk Completely"
    echo "q) Quit"
    read -rp "Choose an option: " choice

    case "$choice" in
      1) show_disk_details ;;
      2) create_mbr_disk ;;
      3) create_gpt_disk ;;
      4) install_grub_only ;;
      5)
        list_disks
        read -rp "Enter target device (e.g., sdb): " t
        target=$(normalize_device "$t")
        confirm_action "$target" || continue
        unmount_target "$target"
        ls -1
        read -rp "Enter Linux image path (.img/.xz): " img
        flash_image "$img" "$target"
        rescan_and_settle "$target"
        run_partitioner "gparted $target"
        ;;
      6)
        list_disks
        read -rp "Enter partition to flash (e.g., sdb1): " p
        part=$(normalize_device "$p")
        confirm_action "$part" || continue
        unmount_target "$part"
        ls -1
        read -rp "Enter image path (.img/.xz): " img
        flash_image "$img" "$part"
        rescan_and_settle "${part%[0-9]*}"
        run_partitioner "gparted ${part%[0-9]*}"
        ;;
      7) wipe_disk_completely ;;
      q|Q) echo "Exiting."; exit 0 ;;
      *) echo "Invalid choice." ;;
    esac
  done
}

main
