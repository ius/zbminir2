#!/usr/bin/env bash
DEV=/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0

if [ -e $DEV ]
then
	rlwrap ./build/zigbee_z3_gateway.elf -n 0 -d build -p $(readlink -f $DEV)
else
	echo Zigbee USB adapter not present, expecting $DEV
fi

