<img width="1280" height="720" alt="MiniOS.SkyLine.2026" src="https://github.com/1compk/dl/raw/dl/MiniOS.SkyLine.2026.Trixie.LXFice.SS.RV413.png"/>

MiniOS Download : https://github.com/1compk/minios/releases

Rufus Download : https://rufus.ie/downloads/

MiniOS Original : https://github.com/minios-linux/minios-live

==================================================================

Armbian AMD64 Downloads : https://dl.armbian.com/uefi-x86/

Mirror : https://mirror.twds.com.tw/armbian-dl/uefi-x86/archive/?C=S&O=D

Free Download Manager : https://debrepo.freedownloadmanager.org/pool/main/f/freedownloadmanager/

Firefox : https://ftp.mozilla.org/pub/firefox/releases/

wget -O Firefox-esr.tar.xz "https://download.mozilla.org/?product=firefox-esr-latest&os=linux64&lang=en-US"

==================================================================

Flash img :

    Find Target Drive : lsblk
    Use DD Command for X = target drive :

sudo xzcat file.img.xz | sudo dd of=/dev/sdX status=progress bs=3M conv=fsync

sudo 7z x -so file.img.xz | sudo dd of=/dev/sdX status=progress bs=3M conv=fsync

sudo dd if=xxx.img of=/dev/sdX status=progress bs=3M conv=fsync

Decompress XZ : xz -dk xxx.img.xz

Decompress 7Zip : 7z x xxx.img.xz

==================================================================

SSD Speed Test : sudo hdparm -t --direct /dev/sdx

Fast User Settings : sh /usersetup.sh

sudo update-alternatives --config x-terminal-emulator

sudo mkfs.ext4 -F -O "^has_journal,sparse_super" -m 0 "/dev/loop6p3"

sudo mkfs.xfs -f -i sparse=0 -s size=4096 -b size=4096 "/dev/loop6p3"

sudo mkfs.btrfs -fv -n 8K "/dev/loop6p3"

sudo mkfs.f2fs -f -o 10 "/dev/loop6p3"

==================================================================

Install bootmgr mbr bootloader :
lsblk
sudo dd if=NT6.512.mbr of=/dev/sdX bs=512 count=1

==================================================================

Install Grub bootloader :

lsblk = /dev/sdX > mount = /mnt/sdX

#Grub-Install gonna Create "/EFI/boot/bootx64.efi" File > /EFI/boot/grub.cfg :

sudo grub-install --target=x86_64-efi --boot-directory=/media/user/sdxx/EFI --efi-directory=/media/user/sdxx --removable

#Grub-Install gonna Create "/EFI/grub" Files > /EFI/grub/grub.cfg :

sudo grub-install --target=i386-pc --boot-directory=/media/user/sdxx/EFI /dev/sdx --recheck --force

==================================================================

#Slax64 Setting :

passwd guest

usermod -l user guest

usermod -d /home/user -m user

apt update && apt install sudo nala -y

usermod -aG sudo user

for amd gpu : firmware-amd-graphics mesa-vulkan-drivers 

==================================================================

#Gnome-Disks Mount Options :

defaults,x-gvfs-show,noauto

user,users,noatime,nodiratime,suid,dev,exec,async,comment=x-gvfs-show,x-gvfs-show,x-udisks-auth

==================================================================

Gnome Extensions :

gir1.2-gmenu-3.0

gnome-shell-extension-manager

Vulkan:
libvulkan-dev
vulkan-tools
vulkaninfo


#Ubuntu remove :

grub-customizer

libfontembed1

libpulsedsp

==================================================================

menuentry "Usb - SSTR Grub4Dos Boot Menu" {
    echo Searching... /SSTR/grldr
search --file --no-floppy --set=root /SSTR/grldr

    echo Loading... kernel
ntldr (${root})/SSTR/grldr

    echo Booting... /SSTR/grldr
boot
}

menuentry "Wimboot" {
    linux16 /wimboot/wimboot gui pause
    initrd16 newc:bcd:(loop)/boot/bcd \
           newc:boot.sdi:(loop)/boot/boot.sdi \
           newc:boot.wim:(loop)/sources/boot.wim
}

==================================================================

TerMux Install Debian Command:

pkg update && pkg upgrade -y

pkg install proot-distro -y

proot-distro install debian

proot-distro login debian --shared-tmp

==================================================================

Wipe Nvme :

sudo blkdiscard -f /dev/nvmeXnX

sudo systemctl enable --now fstrim.timer

sudo fstrim -av
