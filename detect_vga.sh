#!/bin/bash
echo "=== GPU/Display Controller Info ==="
lspci -nn | grep -E -i "vga|3d|display"
echo ""
echo "=== Detailed Display Info ==="
if command -v lshw &> /dev/null; then
    lshw -C display
else
    echo "lshw command not found. You can install it for more detailed hardware information."
    echo "Attempting to install lshw..."
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y lshw
        lshw -C display
    fi
fi
