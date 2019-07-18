Matt's Gemini Documentation
===========================

## Generally useful packages

I don't know how people quite live without these:

```bash
apt-get update -qq
apt-get -y install \
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
sudo systemctl unmask avahi-daemon
sudo systemctl enable avahi-daemon
```

And then do a complete upgrade of all the things.

```bash
apt-get -y upgrade
```


## Configuring WPA Supplicant for automatic wifi connections

It would be quite nice if the device would automatically connect to wifi...
```bash
# Install WPA supplicant 
apt install -y wpasupplicant

# Disable WPA supplicant Service
systemctl stop wpa_supplicant.service
systemctl disable wpa_supplicant.service

# Configure WPA supplicant
curl -K https://raw.githubusercontent.com/matthewbaggett/Gemini-PDA-Linux-Scripts/master/wpa_supplicant.conf -o /etc/wpa_supplicant/wpa_supplicant.conf
```

Don't forget to modify `/etc/wpa_supplicant/wpa_supplicant.conf` to configure your various wifi access points!

## Controlling the lid LEDs
```bash
apt install -y gemian-leds gemian-leds-scripts
/usr/share/gemian-leds/scripts/torch-on && sleep 1 && /usr/share/gemian-leds/scripts/torch-off
```

there are 7 LEDs that appear to be addressed through aw9120:

![Lid LEDs](resources/leds.jpg)

Not pictured: #7, inside on keyboard.

### Manually controlling Lid + Capslock LEDs:

```bash
# echo LED_NUMBER RED GREEN BLUE > /proc/aw9120_operation
echo 1 0 0 0 > /proc/aw9120_operation # LED 1 OFF.
echo 2 3 0 0 > /proc/aw9120_operation # LED 2 RED.
echo 3 3 0 0 > /proc/aw9120_operation # LED 3 GREEN.
echo 4 3 0 0 > /proc/aw9120_operation # LED 4 BLUE.
echo 5 3 3 3 > /proc/aw9120_operation # LED 5 WHITE.
echo 6 3 0 3 > /proc/aw9120_operation # LED 6 PURPLE.
echo 7 0 1 > /proc/aw9120_operation # LED 7 DIM BLUE.
```

LED 7 on the keyboard only has red and blue LEDs attached to it, so the GREEN value is omitted.

### Manually controlling Power LEDs:

```bash
# Turn on green power LED
echo 1 | sudo tee --append /sys/class/leds/green/brightness
# Turn on red power LED
echo 1 | sudo tee --append /sys/class/leds/red/brightness
```

And to turn 'em off again, echo a 0.

This LED cannot be completely turned off when device is charging.

## Running with the lid closed 

If we want things to run in the background, we need it to run with the lid closed:

```bash
sed -i 's|#HandleLidSwitch=.*|HandleLidSwitch=ignore|g' /etc/systemd/logind.conf 
systemctl restart systemd-logind
```

## Installing Docker

```bash
apt-get update -qq
apt install -y apt-transport-https ca-certificates curl
curl -fsSL "https://download.docker.com/linux/debian/gpg" | apt-key add -qq - >/dev/null
echo "deb [arch=arm64] https://download.docker.com/linux/debian stretch stable" > /etc/apt/sources.list.d/docker.list
apt-get update -qq
apt install -y docker-ce docker-compose aufs-dev
```

## Decyphering Battery State

Cryptically, battery state seems to be a pain in the ass to obtain on the MTK6769 - A proc device called `/proc/battery_status` is provided which returns an unlabeled CSV of data.

Digging through kernel-3.18, [mtk_cooler_bcct.c](https://github.com/gemian/gemini-linux-kernel-3.18/blob/master/drivers/misc/mediatek/thermal/common/coolers/mtk_cooler_bcct.c#L1023):

 * proc_create("battery_status") 
 * stuct _cl_battery_status_fops
 * _cl_battery_status_open
 * _cl_battery_status_read
 
```bash
matthew@pocket:~$ cat /proc/battery_status 
100,100,4404,2,0,0,5024,500
```
This shows us that the fields returned are:

| internal name    | Explanation | Example Value |
| ---------------- |:----------- | -------------:|
| bat_info_soc     | ???         | 100           |
| bat_info_uisoc   | ???         | 100           |
| bat_info_vbat    | ???         | 4404          |
| bat_info_ibat    | ???         | 2             |
| bat_info_mintchr | ???         | 0             |
| bat_info_maxtchr | ???         | 0             |
| bat_info_vbus    | ???         | 5024          |
| bat_info_aicr    | ???         | 500           |