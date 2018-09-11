#!/bin/bash

SSID_REG=1010
LOGIN_REG=1030
PASSW_REG=1050
RST_FLAG_REG=1099
SRV_CODE_REG=1100
FRQ_REG=1120
URL_REG=1150
UPDATE_FLAG_REG=1300

SERIAL_PORT=/dev/ttyS1
WIRELESS_DEVICE=wlan0
HOME="/root/wifi"
BAUD=115200

#do not modify it
COUNTER=10
SSID=""
PASSW=""

sleep 120
#set -x

netmask2cidr()
{
  case $1 in
      0x*)
      local hex=${1#0x*} quad=
      while [ -n "${hex}" ]; do
        local lastbut2=${hex#??*}
        quad=${quad}${quad:+.}0x${hex%${lastbut2}*}
        hex=${lastbut2}
      done
      set -- ${quad}
      ;;
  esac

  local i= len=
  local IFS=.
  for i in $1; do
    while [ ${i} != "0" ]; do
      len=$((${len} + ${i} % 2))
      i=$((${i} >> 1))
    done
  done

  echo "${len}"
}



get_config()
{

	SSID_NEW=""
	LOGIN_NEW=""
	PASSW_NEW=""
	SRV_CODE_NEW=""
	URL_NEW=""
	UPDATE_NEW=""


	for index in {1..32}
	do
		CHAR="0"

		until [ ${#CHAR} -eq 3 ]; do
			CHAR=$(modbus_client -mrtu --debug $SERIAL_PORT -pnone -s2 -b$BAUD -t0x03 -a1 -r$(($SSID_REG+$index-1)) | grep Data | tail -c 4)
		done

		if [ $CHAR == "00" ] ;then
			break
		fi
		SSID_NEW+=$(echo $CHAR | xxd -p -r)
	done


	for index in {1..32}

	do
		CHAR="0"

		until [ ${#CHAR} -eq 3 ]; do
			CHAR=$(modbus_client -mrtu --debug $SERIAL_PORT -pnone -s2 -b$BAUD -t0x03 -a1 -r$(($LOGIN_REG+$index-1)) | grep Data | tail -c 4)
	#		echo $CHAR ${#CHAR} $(($BASE+$index-1))
		done

		if [ $CHAR == "00" ] ;then
			break
		fi
		LOGIN_NEW+=$(echo $CHAR | xxd -p -r)
	done


for index in {1..32}

	do
		CHAR="0"

		until [ ${#CHAR} -eq 3 ]; do
			CHAR=$(modbus_client -mrtu --debug $SERIAL_PORT -pnone -s2 -b$BAUD -t0x03 -a1 -r$(($PASSW_REG+$index-1)) | grep Data | tail -c 4)
	#		echo $CHAR ${#CHAR} $(($BASE+$index-1))
		done

		if [ $CHAR == "00" ] ;then
			break
		fi
		PASSW_NEW+=$(echo $CHAR | xxd -p -r)
	done

for index in {1..32}

	do
		CHAR="0"

		until [ ${#CHAR} -eq 3 ]; do
			CHAR=$(modbus_client -mrtu --debug $SERIAL_PORT -pnone -s2 -b$BAUD -t0x03 -a1 -r$(($SRV_CODE_REG+$index-1)) | grep Data | tail -c 4)
	#		echo $CHAR ${#CHAR} $(($BASE+$index-1))
		done

		if [ $CHAR == "00" ] ;then
			break
		fi
		SRV_CODE_NEW+=$(echo $CHAR | xxd -p -r)
	done
for index in {1..32}

	do
		CHAR="0"

		until [ ${#CHAR} -eq 3 ]; do
			CHAR=$(modbus_client -mrtu --debug $SERIAL_PORT -pnone -s2 -b$BAUD -t0x03 -a1 -r$(($URL_REG+$index-1)) | grep Data | tail -c 4)
	#		echo $CHAR ${#CHAR} $(($BASE+$index-1))
		done

		if [ $CHAR == "00" ] ;then
			break
		fi
		URL_NEW+=$(echo $CHAR | xxd -p -r)
	done
echo $URL_NEW

for index in {1..32}

	do
		CHAR="0"

		until [ ${#CHAR} -eq 3 ]; do
			CHAR=$(modbus_client -mrtu --debug $SERIAL_PORT -pnone -s2 -b$BAUD -t0x03 -a1 -r$(($UPDATE_FLAG_REG+$index-1)) | grep Data | tail -c 4)
	#		echo $CHAR ${#CHAR} $(($BASE+$index-1))
		done

		if [ $CHAR == "00" ] ;then
			break
		fi

		UPDATE_NEW+=$(echo $CHAR | xxd -p -r)
            	 modbus_client -mrtu --debug $SERIAL_PORT -pnone -s2 -t0x06 -a1 -b$BAUD -r$(($UPDATE_FLAG_REG)) 0 > /dev/null
               	 opkg update
               	 opkg install bb_wifi_to_rs485
               	 echo "Update Request on $(date)" >> $HOME/bb_wifi_update.log
#		 PID=$(ps | grep netw | head -1 | cut -d " " -f3)
#               	 reboot&kill $PID
	done



        SSID=$(cat $HOME/wifi_conf | cut -d " " -f1)
        LOGIN=$(cat $HOME/wifi_conf | cut -d " " -f2)
        PASSW=$(cat $HOME/wifi_conf | cut -d " " -f3)
        SRV_CODE=$(cat $HOME/wifi_conf | cut -d " " -f4)
        URL=$(cat $HOME/wifi_conf | cut -d " " -f5)

	if ([[ -n $SSID_NEW ]] || [[ -n $PASSW_NEW ]]); then
		echo $SSID_NEW $LOGIN_NEW $PASSW_NEW $SRV_CODE_NEW $URL_NEW $UPDATE_NEW > $HOME/wifi_conf

		SSID=$(cat $HOME/wifi_conf | cut -d " " -f1)
        	LOGIN=$(cat $HOME/wifi_conf | cut -d " " -f2)
        	PASSW=$(cat $HOME/wifi_conf | cut -d " " -f3)
        	SRV_CODE=$(cat $HOME/wifi_conf | cut -d " " -f4)
        	URL=$(cat $HOME/wifi_conf | cut -d " " -f5)
	fi

}

#uci set firewall.@zone[1].input=ACCEPT
#uci commit

while true
do

	OLD_SSID=$SSID
	get_config
	#SSID contains the latest SSID

	if [[ $SSID != $OLD_SSID ]]; then
		CONNECTED=$(iwinfo | grep ESSID | cut -d ":" -f2 | cut -d "\"" -f2)
		if [[ $CONNECTED != $SSID ]]; then
			echo "CONNECTING TO NEW NETWORK"

			uci set wireless.@wifi-iface[0].ssid="$SSID"
			uci set wireless.@wifi-iface[0].mode="sta"
			uci set wireless.@wifi-iface[0].auth="auth=MSCHAPV2"
			uci set wireless.@wifi-iface[0].eap_type="peap"
			uci set wireless.@wifi-iface[0].encryption="wpa+tkip"
			uci set wireless.@wifi-iface[0].identity="$LOGIN"
			uci set wireless.@wifi-iface[0].password="$PASSW"
			uci set wireless.@wifi-iface[0].disabled="0"
			uci commit wireless; wifi

			COUNTER=10
		fi
	fi



	if [ 0 -ne ${#SSID} ];then
#	        iwinfo phy0  scann  > $HOME/scan_output


		echo $SSID
#		cat $HOME/scan_output | grep -n \"$SSID\" | head -1 > $HOME/essid_numbers

#		SSID_LINES=$(cat $HOME/essid_numbers | cut -d ":" -f1)
#		SSID_NAMES=$(cat $HOME/essid_numbers | cut -d "\"" -f2)
#		BIT_RATE_LINES=$((${SSID_LINES}+5))
#		QUALIY_LINES=$((${SSID_LINES}+3))

		BIT_RATE=$(iwinfo | grep "Bit Rate:" | cut -d ':' -f2 | cut -d " " -f2)
		QUALIY_BASE=$(iwinfo | grep "Link Quality" | cut -d ' ' -f16 | cut -d "/" -f2)
		QUALIY_VALUE=$(iwinfo | grep "Link Quality" | cut -d ' ' -f16 | cut -d "/" -f1)
		SIGNAL_LEVEL=$(iwinfo | grep "Signal" | cut -d ' ' -f12)
		SIGNAL_LEVEL=$((${SIGNAL_LEVEL}+65536))
			if ([[ $QUALIY_VALUE -eq "unknown" ]] || [[ $BIT_RATE -eq "unknown" ]] || [[ $SIGNAL_LEVEL -eq 65536 ]])
			 then
				QUALIY_VALUE=0
				BIT_RATE=0
				SIGNAL_LEVEL=0
			fi

	fi

	if [ $COUNTER -eq 10 ]; then
		NETWORK=$(route -n | grep $WIRELESS_DEVICE | grep -v UH | grep -v UG | cut -c1-16 | tr -d " ")
		MASK=$(route -n | grep $WIRELESS_DEVICE | grep -v UH | grep -v UG | cut -c33-48)
		MASK=$(netmask2cidr $MASK)
		GATEWAY=$(route -n | grep $WIRELESS_DEVICE | grep UG | cut -c17-32)
		CLIENTS=$(nmap -sn -PU $NETWORK/24 --exclude $GATEWAY | grep "Nmap done:" | cut -d "(" -f2 | cut -d " " -f1)
		COUNTER=0
	fi
	((COUNTER++))

	if ([[ -z $BIT_RATE ]] || [[ $BIT_RATE -gt 300 ]])
	then
	    BIT_RATE=0
	fi
	if [ -z $QUALIY_BASE ]
	then
	    QUALIY_BASE=0
	fi

	if [ -z $QUALIY_VALUE ]
	then
	    QUALIY_VALUE=0
	fi

	if [ -z $SIGNAL_LEVEL ]
	then
	    SIGNAL_LEVEL=0
	fi
	if [ -z $CLIENTS ]
	then
	    CLIENTS=0
	    COUNTER=10
	fi




	#echo ${SIGNAL_LEVEL} ${BIT_RATE} ${QUALIY_VALUE} ${QUALIY_BASE} $PING $DOWNLOAD $UPLOAD $CLIENTS
	modbus_client -mrtu --debug $SERIAL_PORT -pnone -s2 -t0x10 -a1 -b$BAUD -r1000 ${SIGNAL_LEVEL} ${BIT_RATE} ${QUALIY_VALUE} ${QUALIY_BASE} $CLIENTS

	until [ "$?" -eq 0 ]; do
		modbus_client -mrtu --debug $SERIAL_PORT -pnone -s2 -t0x10 -a1 -b$BAUD -r1000 ${SIGNAL_LEVEL} ${BIT_RATE} ${QUALIY_VALUE} ${QUALIY_BASE} $CLIENTS 
	done

#echo $UPDATE
#
# 	if [ ${UPDATE} != "0" ]; then
#		modbus_client -mrtu --debug $SERIAL_PORT -pnone -s2 -t0x06 -a1 -b$BAUD -r$(($UPDATE_FLAG_REG)) 0 > /dev/null
#		opkg update
#		opkg install wpa-supplicant
#		echo "Update Request on $(date)" >> /var/log/bb_wifi_update.log
#	fi

#	rm essid_numbers
#	rm scan_output

done
