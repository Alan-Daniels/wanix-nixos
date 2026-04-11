#!/bin/sh

mount -t proc proc /proc
mount -t sysfs sysfs /sys

ifconfig eth0 up
udhcpc -i eth0

echo "1 4 1 7" > /proc/sys/kernel/printk

echo "Welcome to NixOS in Wanix!"
