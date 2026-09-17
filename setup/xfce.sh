# dpkg --add-architecture i386
#!/bin/bash

echo "Checking Network Connection..."
until wget -q --spider --no-check-certificate -T 2 https://1.1.1.1 > /dev/null 2>&1; do
    echo "No Internet, Retry in next 10s or Ctrl+C to Stop..."
    sleep 10
done

echo "Updating..."
apt update -y

echo "Installing Nala..."
apt install nala perl sudo -y

echo "Installing Nala Completion Bash..."
nala --install-completion bash

echo "Prompt for New User and Password"
read -p "Enter New User : " inputuser
adduser "$inputuser"
usermod -aG sudo,audio,video,dip,netdev,plugdev "$inputuser"
id -Gn "$inputuser"

echo "Updating..."
apt update -y && apt upgrade -y

echo "Cleaning..."
nala clean

echo "Installing 1ComXFce..."
xargs -a xfce apt install

echo "Updating..."
apt update -y

echo "Cleaning..."
nala clean

echo "Setting Desktop Manager..."
dpkg-reconfigure sddm

echo "Setting Timezone..."
dpkg-reconfigure tzdata

echo "Setting Completed..."
echo "Now Plz Reboot by :  reboot"