#sudo dpkg --add-architecture i386
#!/bin/bash

echo "Checking Network Connection..."
until wget -q --spider --no-check-certificate -T 2 https://1.1.1.1 > /dev/null 2>&1; do
    echo "No Internet, Retry in next 10s or Ctrl+C to Stop..."
    sleep 10
done

echo "Updating..."
sudo apt update -y

echo "Installing Nala..."
sudo apt install nala -y

echo "Installing Nala Completion Bash..."
sudo nala --install-completion bash

echo "Updating..."
sudo apt update -y && sudo apt upgrade -y

echo "Cleaning..."
sudo nala clean

echo "Installing MiXDE..."
xargs -a mixde sudo apt install

echo "Updating..."
sudo apt update -y

echo "Cleaning..."
sudo nala clean

echo "Setting Desktop Manager..."
sudo dpkg-reconfigure sddm

echo "Setting Timezone..."
sudo dpkg-reconfigure tzdata

echo "Setting Completed..."
echo "Now Plz Reboot by : sudo reboot"

