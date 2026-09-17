# dpkg --add-architecture i386
#!/bin/bash

echo "Checking Network Connection..."
until wget -q --spider --no-check-certificate -T 2 https://1.1.1.1 > /dev/null 2>&1; do
    echo "No Internet, Retry in next 10s or Ctrl+C to Stop..."
    sleep 10
done

echo "Start from Home"
cd /home

#echo "Plz provide your User"
#read -p "For Extract Setting Files : " inputuser

echo "Your User is : "$USER" "

echo "Extracting Setting Files..."
sudo 7z x -y User.Settings.7z -o/home/"$USER"
sudo 7z x -y Firefox.Settings.7z -o/home/"$USER"
sudo 7z x -y Noble.Settings.7z -o/home/"$USER"
sudo 7z x -y Noble.FF.Settings.7z -o/home/"$USER"
sudo 7z x -y Trixie.Settings.7z -o/home/"$USER"
sudo 7z x -y Trixie.FF.Settings.7z -o/home/"$USER"

echo "Changing Owner of Setting Files..."
sudo chown -R "$USER":user /home
sudo chown -R "$USER":user /home/"$USER"
#sudo chown -R "$USER":user /home/"$USER"/.config
#sudo chown -R "$USER":user /home/"$USER"/.local
#sudo chown -R "$USER":user /home/"$USER"/.mozilla

echo "Updating and Upgrading System..."
sudo apt update && sudo apt upgrade -y
sudo mandb -c

echo "Cleaning..."
sudo nala clean

echo "Updating and Upgrading System..."
sudo apt modernize-sources -y
sudo apt update && sudo apt upgrade -y

echo "Installing FDM, ISO Master"
#sudo apt install -y ./FDM.x64.deb
#sudo apt install -y ./iSO.Master.x64.deb
#sudo apt install -y ./OVDL.x64.deb
sudo apt install -y ./*.x64*.deb

echo "Installing Lastest Apps and Neofetch..."
sudo apt install apparmor apparmor-profiles engrampa ffmpeg mate-polkit sddm-theme-maui

echo "Cleaning..."
sudo nala clean

#sudo mv /etc/apt/sources.list.d/freedownloadmanager.list /etc/apt/sources.list.d/freedownloadmanager.bak

echo "Setting Desktop Manager..."
sudo dpkg-reconfigure sddm
sudo mousepad /etc/sddm.conf

echo "Setting Timezone..."
sudo dpkg-reconfigure tzdata

systemctl --user stop mpris-proxy.service
systemctl --user disable mpris-proxy.service
systemctl --user mask mpris-proxy.service

sudo systemctl --global disable mpris-proxy.service

sudo bash polkit.setup.sh
#sudo bash pipewire.setup.sh

sudo rm -rf /etc/xdg/autostart/settings.desktop
sudo cp -f /home/update.desktop /etc/xdg/autostart/update.desktop
sudo cp -f /home/minios-store.desktop /usr/share/applications

pipx ensurepath
pipx install yt-dlp

echo "Setting Completed..."
echo "Now Plz Logout or Reboot by : sudo reboot"
