#!/bin/bash

# 1. Dynamically find the polkit agent path using dpkg
echo "Searching for mate-polkit path..."
POLKIT_PATH=$(dpkg -L mate-polkit 2>/dev/null | grep 'polkit-mate-authentication-agent-1' | head -n 1)

# Check if the path was found
if [ -z "$POLKIT_PATH" ]; then
    echo "❌ ERROR: mate-polkit is not installed or not found."
    echo "Please run: sudo apt install mate-polkit"
    exit 1
fi

echo "Success: Found agent at $POLKIT_PATH"

# 2. Setup for IceWM
echo "Configuring IceWM..."
mkdir -p ~/.icewm
# Check if already configured
if ! grep -q "$POLKIT_PATH" ~/.icewm/startup 2>/dev/null; then
    echo "$POLKIT_PATH &" >> ~/.icewm/startup
    chmod +x ~/.icewm/startup
    echo "   - Added to ~/.icewm/startup"
else
    echo "   - Already configured for IceWM"
fi

# 3. Setup for LXDE (lxde-core)
echo "Configuring LXDE..."
mkdir -p ~/.config/lxsession/LXDE
# Check if already configured
if ! grep -q "$POLKIT_PATH" ~/.config/lxsession/LXDE/autostart 2>/dev/null; then
    echo "@$POLKIT_PATH" >> ~/.config/lxsession/LXDE/autostart
    echo "   - Added to LXDE autostart"
else
    echo "   - Already configured for LXDE"
fi

echo "Done! Please Log out and Log in again to apply changes."
