#!/bin/bash

# 1. Define target autostart directory and source file
FileTarget="Pipewire.Service.desktop"
AutoStartDir="/etc/xdg/autostart"
SourceFile="/home/$FileTarget"

# 2. Check if the system is NOT running systemd (meaning it uses SysV init, OpenRC, etc.)
# It verifies this by checking the command name of PID 1
if [ "$(ps -p 1 -o comm=)" != "systemd" ]; then
    echo "System is not running systemd (Non-systemd/Init system detected)."
    
    # Create the autostart directory if it does not exist (requires sudo)
    sudo mkdir -p "$AutoStartDir"
    
    # Check if the source desktop file exists
    if [ -f "$SourceFile" ]; then
        sudo cp -f "$SourceFile" "$AutoStartDir/"
        echo "Successfully copied $FileTarget to $AutoStartDir!"
    else
        echo "Error: $SourceFile not found."
        echo "Generating a new $FileTarget file instead..."
        
        # Fallback: Fixed with 'sudo tee' to prevent "Permission denied" error
        sudo tee "$AutoStartDir/$FileTarget" > /dev/null <<EOF
[Desktop Entry]
Version=1.0
Name=PipeWire Sound Server
Comment=Start the PipeWire Sound Server
Exec=sh -c "pipewire & sleep 1 && pipewire-pulse & sleep 1 && wireplumber"
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true
EOF
        echo "Created a custom $FileTarget in autostart folder."
    fi
else
    echo "System is running systemd. Skipping autostart file copy."
fi
