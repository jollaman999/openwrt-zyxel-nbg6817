#!/bin/sh
. /lib/functions.sh
include /lib/upgrade
v "Switching to ramdisk..."
kill_remaining TERM
sleep 3
kill_remaining KILL
fw_mtd=$(cat /tmp/fw_mtd)
if [ "$fw_mtd" == "single" ]; then
run_ramfs 'fw_upgrade exec_mtd; reboot -f'
else
if [ -d /sys/block/mmcblk0 ]; then
	fw_upgrade exec_mtd
else
	fw_upgrade exec_mtd "$fw_mtd"
fi
reboot -f
fi
