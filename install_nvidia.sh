#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root (use sudo)."
  exit 1
fi

echo "=== Fixing Package Manager (if needed) ==="
dpkg --configure -a

echo ""
echo "=== Blacklisting Nouveau Driver ==="
# Write blacklist rules
echo "blacklist nouveau" > /etc/modprobe.d/blacklist-nouveau.conf
echo "options nouveau modeset=0" >> /etc/modprobe.d/blacklist-nouveau.conf
echo "Nouveau driver successfully added to blacklist in /etc/modprobe.d/blacklist-nouveau.conf"

echo ""
echo "=== Updating Initramfs ==="
if command -v update-initramfs &> /dev/null; then
    echo "Running update-initramfs..."
    update-initramfs -u
elif command -v dracut &> /dev/null; then
    echo "Running dracut..."
    dracut --force
else
    echo "Warning: Neither update-initramfs nor dracut found. Please update your initramfs manually."
fi

echo ""
echo "=== Installing NVIDIA Driver for GeForce 920MX ==="
# Checking for Kali Linux / Debian
if [ -f /etc/os-release ] && grep -q "kali" /etc/os-release; then
    echo "Kali Linux detected. Installing recommended driver for 920MX..."
    apt-get update
    apt-get install -y nvidia-detect
    # Determine driver
    DRV_INFO=$(nvidia-detect)
    echo "$DRV_INFO"
    
    RECOMMENDED_DRIVER=$(echo "$DRV_INFO" | grep -o 'nvidia-driver')
    if [ -z "$RECOMMENDED_DRIVER" ]; then
         # Fallback search
         RECOMMENDED_DRIVER=$(echo "$DRV_INFO" | grep -o 'nvidia-legacy-[0-9]\+xx-driver' | head -n 1)
    fi

    if [ -n "$RECOMMENDED_DRIVER" ]; then
        echo "Installing $RECOMMENDED_DRIVER..."
        apt-get install -y "$RECOMMENDED_DRIVER" nvidia-xconfig
    else
        echo "Could not detect driver automatically. Installing standard 'nvidia-driver'..."
        apt-get install -y nvidia-driver nvidia-xconfig
    fi
    echo "Generating Xorg configuration..."
    nvidia-xconfig
elif command -v ubuntu-drivers &> /dev/null; then
    echo "Ubuntu-based system detected."
    ubuntu-drivers autoinstall
elif command -v apt-get &> /dev/null; then
    echo "Debian-based system detected."
    apt-get update
    apt-get install -y nvidia-driver nvidia-xconfig
elif command -v pacman &> /dev/null; then
    echo "Arch-based system detected."
    pacman -S --noconfirm nvidia-dkms nvidia-utils
elif command -v dnf &> /dev/null; then
    echo "Fedora-based system detected."
    dnf install -y akmod-nvidia
else
    echo "Unsupported package manager. Please install nvidia-driver manually."
fi

echo ""
echo "=== Setup Complete ==="
echo "Please reboot your system now to activate the NVIDIA driver and disable Nouveau."
echo "Command to reboot: sudo reboot"