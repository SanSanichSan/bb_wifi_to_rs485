#!/bin/bash
#set -x
#sleep 120
HOME="/root/wifi"

ESSID=$(iwinfo wlan0 info | grep "Access Point" | cut -d " " -f13)
echo $ESSID
SSID=$(cat $HOME/wifi_conf | cut -d " " -f1)


rm -rf $HOME/*.csv
while true
do
	/usr/sbin/airmon-ng stop mon0 > /dev/null 2>&1
	/usr/sbin/airmon-ng start wlan0 > /dev/null 2>&1
	/usr/sbin/airmon-ng | grep mon0 && /usr/sbin/airodump-ng -w $HOME/airdump --manufacturer --uptime  --output-format csv --essid $SSID -a mon0 > /dev/null 2>&1

done

