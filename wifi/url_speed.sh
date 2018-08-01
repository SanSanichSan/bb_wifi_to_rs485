#!/bin/bash

HOME="/root/wifi"
SERIAL_PORT=/dev/ttyS1
BAUD=115200
URL=$(cat $HOME/wifi_conf | cut -d " " -f5)
sleep 120
#set -x
while true
do
#	curl -w "@$HOME/curl-format" -o /dev/null -s "$URL" > $HOME/curl_file
	TT=$(curl -s -w %{time_total}\\n -o /dev/null "$URL")
	TT=$(echo $TT*1000 | bc | cut -d "." -f1)

	if [ -z $TT ]
	then
	    TT=0
	fi



	#echo ${SIGNAL_LEVEL} ${BIT_RATE} ${QUALIY_VALUE} ${QUALIY_BASE} $PING $DOWNLOAD $UPLOAD $CLIENTS
	modbus_client -mrtu --debug $SERIAL_PORT -pnone -s2 -t0x10 -a1 -b$BAUD  -r1070 $TT

	until [ "$?" -eq 0 ]; do
		modbus_client -mrtu --debug $SERIAL_PORT -pnone -s2 -t0x10 -a1 -b$BAUD  -r1070 $TT
	done


	sleep 60
done

