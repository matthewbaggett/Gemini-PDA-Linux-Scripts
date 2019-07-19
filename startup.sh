#!/usr/bin/env bash
# You can run this on the device:
# $ curl -sSL https://raw.githubusercontent.com/matthewbaggett/Gemini-PDA-Linux-Scripts/master/setup.sh | sh
#
# Or, if you've not established wifi on the device yet, you can do it over USB bridged network:
# $ ./payload-inject.sh

set -e

if [ -f ./.gem-config ]; then
    echo "Detected .gem-config, gonna load it."
    . ./.gem-config
fi

echo "Okay, lets configure your Gemini to not suck, yeah?"
if [ -z "$GEM_HOSTNAME" ]; then
    read -p "Enter new hostname: " GEM_HOSTNAME
fi
if [ -z "$GEM_USERNAME" ]; then
    read -p "Username: " GEM_USERNAME
fi
if [ -z "$GEM_PASSWORD" ]; then
    read -p "$GEM_USERNAME's password: " GEM_PASSWORD
fi
if [ -z "$GEM_WIFI_SSID" ]; then
    echo "Enter your first wifi SSID for first-time-setup"
    echo " (don't worry, you can edit these in /etc/wpa_supplicant/wpa_supplicant.conf!)"
    read -p "Wifi SSID: " GEM_WIFI_SSID
fi
if [ -z "$GEM_WIFI_KEY" ]; then
    read -p "Wifi Secret: " GEM_WIFI_KEY
fi

# Try the default password to sudo up.
echo "gemini" | sudo -S true > /dev/null 2>&1

# Configure WPA Supplicant
echo "ctrl_interface=/run/wpa_supplicant" | sudo tee /etc/wpa_supplicant/wpa_supplicant.conf
echo "update_config=1" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf
echo "ap_scan=1" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf
wpa_passphrase $GEM_WIFI_SSID $GEM_WIFI_KEY | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf

if [ -f /etc/wpa_supplicant/wpa_supplicant.conf ]; then
    echo "Written to /etc/wpa_supplicant/wpa_supplicant.conf OK";
else
    echo "Failed to write to /etc/wpa_supplicant/wpa_supplicant.conf";
fi

# Symlink our config into -wlan0.conf
if [ ! -f /etc/wpa_supplicant/wpa_supplicant-wlan0.conf ]; then
    sudo ln -s /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
fi

# Touch /etc/fstab incase it doesn't exist - this upsets dhclient if it doesn't.
sudo touch /etc/fstab

# Reload all the things
echo "Reloading systemd"
sudo systemctl daemon-reload
echo "Stopping wpa_supplicant service"
sudo systemctl stop wpa_supplicant.service
echo "Disabling wpa_supplicant service"
sudo systemctl disable wpa_supplicant.service
echo "Enabling wpa_supplicant@wlan0"
sudo systemctl enable wpa_supplicant@wlan0
echo "Restarting wpa_supplicant@wlan0"
sudo systemctl start wpa_supplicant@wlan0

# Prevent closing the lid from sleeping the device
echo "Disabling the lid from sleeping the system.."
sudo sed -i 's|#HandleLidSwitch=.*|HandleLidSwitch=ignore|g' /etc/systemd/logind.conf
sudo systemctl restart systemd-logind

# Wait for internet to come up
echo -n "Waiting for internet to come up...";
while ! ping -c 1 -n -w 1 8.8.8.8 &> /dev/null
do
    echo -n "."
done

# Alright, lets go install shit.
echo "Okay, updating APT repos..."
sudo apt-get update -qq
echo "Installing some default tooling that should have shipped with this thing..."
sudo apt-get -yq install \
    gemian-leds gemian-leds-scripts \
    aptitude \
    openssh-server \
    avahi-daemon \
    curl \
    wget \
    htop \
    iproute2 \
    systemd-sysv \
    locales \
    iputils-ping

sudo systemctl daemon-reload

# Install PHP for some scripting goodness.
echo "Install some PHP for scripting goodness."
sudo apt-get -yq install --no-install-recommends \
    php7.3-bcmath \
    php7.3-bz2 \
    php7.3-cli \
    php7.3-curl \
    php7.3-gd \
    php7.3-imap \
    php7.3-intl \
    php7.3-json \
    php7.3-ldap \
    php7.3-mbstring \
    php7.3-memcache \
    php7.3-memcached \
    php7.3-mongodb \
    php7.3-mysql \
    php7.3-opcache \
    php7.3-pgsql \
    php7.3-pspell \
    php7.3-redis \
    php7.3-soap \
    php7.3-sqlite \
    php7.3-xml \
    php7.3-zip

# Add gemian-leds/scripts to PATH
echo "Adding gemian-leds/scripts to PATH."
echo "PATH=$PATH:/usr/share/gemian-leds/scripts" | sudo tee /etc/profile.d/gemian-leds-path.sh

# Test the lid LEDs
echo "Testing the lid LEDs"
/usr/share/gemian-leds/scripts/torch-on
sleep 1
/usr/share/gemian-leds/scripts/torch-off

sleep 3
torch-on
sleep 1
torch-off

# Add the new user
echo "Adding the user $GEM_USERNAME...";
if [ ! -d  /home/$GEM_USERNAME ]; then
    sudo useradd $GEM_USERNAME -m -p $(openssl passwd -1 $GEM_PASSWORD)
fi;

# Alter the hostname
echo "Setting hostname to $GEM_HOSTNAME";
echo -e "127.0.0.1\t$GEM_HOSTNAME" | sudo tee -a /etc/hosts
echo -e $GEM_HOSTNAME | sudo tee /etc/hostname

# Avahi
echo "Enabling avahi"
sudo systemctl unmask avahi-daemon
sudo systemctl enable avahi-daemon
