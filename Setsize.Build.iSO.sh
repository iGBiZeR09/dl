#!/bin/bash
set -euo pipefail

LIVEKITNAME="minios"
PERCHIMG="perch.img"
SourceDiR="${SourceDiR:-.}"
ISOFile="../Rebuild-$(basename "$PWD").iso"

[[ -d "$SourceDiR" ]] || { echo "Error: SourceDiR '$SourceDiR' not found" >&2; exit 1; }

read -rp "Enter ISO Size in MiB (e.g., 512, 1000): " InputMiB
[[ "$InputMiB" =~ ^[0-9]+$ ]] || { echo "Error: InputMiB must be an integer MiB value" >&2; exit 1; }

CurrentSize=$(du -sm "$SourceDiR" | cut -f1)
echo "Current Source Directory Size: ${CurrentSize} MiB"

# Create persistence image
DummySize=$(( InputMiB - CurrentSize - 2 ))
if (( DummySize > 0 )); then
  echo "Padding Partition 1 with ${DummySize} MiB..."
  dd if=/dev/zero of="$PERCHIMG" bs=1M count=0 seek="$DummySize" status=progress
fi

sudo mkfs.ext4 -F -L persistence -b 4096 -m 0 -E stride=2,stripe-width=2 \
  -O "^has_journal,sparse_super,dir_index" "$PERCHIMG"

# Create persistence image
#dd if=/dev/zero of="$PERCHIMG" bs=1k count=0 seek=128
#sudo mkfs.ext2 -F -b 1024 -L resizeme "$PERCHIMG"

# Create ISO
xorriso --as mkisofs \
  -iso-level 3 -volid "1ComPK" -A "1ComPK" \
  -joliet -joliet-long -rational-rock \
  -eltorito-boot "${LIVEKITNAME}/boot/grub/i386-pc/eltorito.img" \
  -eltorito-catalog "${LIVEKITNAME}/boot/boot.cat" \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e "${LIVEKITNAME}/boot/grub/efi.img" -no-emul-boot \
  --isohybrid-mbr "${LIVEKITNAME}/boot/grub/i386-pc/boot_hybrid.img" \
  -append_partition 2 0x83 "$PERCHIMG" \
  -partition_cyl_align on -partition_offset 16 -part_like_isohybrid \
  -exclude "$PERCHIMG" \
  -output "$ISOFile" "$SourceDiR"

rm -f "$PERCHIMG" 2>/dev/null || true

echo "ISO created successfully: $ISOFile"
sync
exit