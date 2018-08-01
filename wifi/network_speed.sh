#!/usr/bin/env sh

HOME="/root/wifi"
SERIAL_PORT=/dev/ttyS1
BAUD=115200
SRV_CODE=$(cat $HOME/wifi_conf | cut -d " " -f4)
#set -x
sleep 120
while true
do
	$HOME/speedtest.py --simple --no-pre-allocate --server $SRV_CODE > $HOME/speedtest_file

	PING=$(cat $HOME/speedtest_file | grep Ping | cut -d " " -f2)
	PING=$(echo $PING*100 | bc | cut -d "." -f1)

	DOWNLOAD=$(cat $HOME/speedtest_file | grep Download | cut -d " " -f2)
	DOWNLOAD=$(echo $DOWNLOAD*10 | bc | cut -d "." -f1)

	UPLOAD=$(cat $HOME/speedtest_file | grep Upload | cut -d " " -f2)
	UPLOAD=$(echo $UPLOAD*10 | bc | cut -d "." -f1)

	if [ -z $PING ]
	then
	    PING=0
	fi

	if [ -z $DOWNLOAD ]
	then
	    DOWNLOAD=0
	fi
	

	if [ -z $UPLOAD ]
	then
	    UPLOAD=0
	fi



	#echo ${SIGNAL_LEVEL} ${BIT_RATE} ${QUALIY_VALUE} ${QUALIY_BASE} $PING $DOWNLOAD $UPLOAD $CLIENTS
	modbus_client -mrtu --debug $SERIAL_PORT -pnone -s2 -t0x10 -a1 -b$BAUD  -r1005 $PING $DOWNLOAD $UPLOAD

	until [ "$?" -eq 0 ]; do
		modbus_client -mrtu --debug $SERIAL_PORT -pnone -s2 -t0x10 -a1 -b$BAUD  -r1005 $PING $DOWNLOAD $UPLOAD
	done


	sleep 1000
done

