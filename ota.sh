#!/usr/bin/env bash
rlwrap ./build/zigbee_z3_gateway.elf -n 0 -d build -p $(readlink -f /dev/serial/by-id/usb-1a86_USB_Serial-if00-port0)
