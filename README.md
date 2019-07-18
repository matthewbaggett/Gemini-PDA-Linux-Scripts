Matt's Gemini Documentation
===========================

# Configuring WPA Supplicant for automatic wifi connections

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

# Controlling the lid LEDs
```bash
apt install -y gemian-leds gemian-leds-scripts
/usr/share/gemian-leds/scripts/torch-on && sleep 1 && /usr/share/gemian-leds/scripts/torch-off
```

there are 7 LEDs that appear to be addressed through aw9120:

![Lid LEDs](resources/leds.jpg)

Not pictured: #7, inside on keyboard.

## Manually controlling Lid + Capslock LEDs:

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

## Manually controlling Power LEDs:

```bash
# Turn on green power LED
echo 1 | sudo tee --append /sys/class/leds/green/brightness
# Turn on red power LED
echo 1 | sudo tee --append /sys/class/leds/red/brightness
```

And to turn 'em off again, echo a 0.

This LED cannot be completely turned off when device is charging.

# Running with the lid closed 

If we want things to run in the background, we need it to run with the lid closed:

```bash
sed -i 's|#HandleLidSwitch=.*|HandleLidSwitch=ignore|g' /etc/systemd/logind.conf 
systemctl restart systemd-logind
```

