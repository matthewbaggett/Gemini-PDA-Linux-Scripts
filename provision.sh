#!/bin/bash
GEM_DEFAULT_IP=10.15.19.82
set -e
echo "Checking dependencies..."
echo -n "Checking for sshpass... ";
if [ ! -f /usr/bin/sshpass ]; then
    sudo apt install -yq sshpass
    echo "[DONE]"
else
    echo "[SKIP!]"
fi

echo -n "Checking that ModemManager isn't running... ";
if systemctl status ModemManager.service | grep "Active: inactive"; then
    echo "[Success - its stopped!]"
else
    systemctl stop ModemManager.service
    systemctl disable ModemManager.service
    echo "[Stopped it!]"
fi

echo -n "Downloading FlashTool... ";
if [ ! -f flashtool.tgz ]; then
    wget -q -nc -O flashtool.tgz http://support.planetcom.co.uk/download/FlashToolLinux.tgz
    echo "[DONE]"
else
    echo "[SKIP!]"
fi

echo -n "Downloading Gemini Base Images... ";
if [ ! -f firmware/gemini_x27_base.zip ]; then
    wget -q -nc -O firmware/gemini_x27_base.zip https://support.planetcom.co.uk/download/LinuxFirmware7/gemini_x27_base.zip
    echo "[DONE]"
else
    echo "[SKIP!]"
fi

echo -n "Downloading Debian... ";
if [ ! -f firmware/debian.zip ]; then
    wget -q -nc -O firmware/debian.zip https://support.planetcom.co.uk/download/LinuxFirmware7/debian.zip
    echo "[DONE]"
else
    echo "[SKIP!]"
fi;

echo -n "Unpacking Flashtool... "
if [ ! -d FlashToolLinux ]; then
    tar xzf flashtool.tgz
    echo "[DONE]";
else
    echo "[SKIP!]";
fi

echo -n "Inflating Debian.zip... "
if [ ! -f firmware/debian_boot.img ] || [ ! -f firmware/linux.img ]; then
    if [ ! -f firmware/debian_boot.img ]; then
        unzip -qq -x -d firmware/ firmware/debian.zip debian_boot.img
    fi
    if [ ! -f firmware/linux.img ]; then
        unzip -qq -x -d firmware/ firmware/debian.zip linux.img
    fi
    echo "[DONE]";
else
    echo "[SKIP!]";
fi

echo -n "Inflating Gemini Base Images... "
if [ ! -f firmware/system.img ]; then
    unzip -qq -x -d firmware firmware/gemini_x27_base.zip
    echo "[DONE]";
else
    echo "[SKIP!]";
fi

echo "Trying to find the device..."
# Check for device connected and reboot it if we can
if  ping -c 1 $GEM_DEFAULT_IP &> /dev/null; then
    echo "Device is up - rebooting...";
    ssh -t gemini@$GEM_DEFAULT_IP "/bin/bash ~/shutdown.sh && exit"
else
    echo "Can't find device - attach it now!"
fi

# Flash firmware
echo "Flashing firmware..."
./FlashToolLinux/flash_tool.sh -i ./firmware/download.xml -b

# Wait for usb network to come up
echo -n "Waiting for gemini to come up...";
while ! ping -c 1 -n -w 1 $GEM_DEFAULT_IP &> /dev/null
do
    echo -n "."
done

# Install local SSH key into gemini user
sshpass -f .gemini_default_password.txt ssh-copy-id gemini@$GEM_DEFAULT_IP

# Trigger installation of other utilities.
./payload-inject.sh

