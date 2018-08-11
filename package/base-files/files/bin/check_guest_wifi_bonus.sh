#!/bin/sh

bonus_rule=$(atq)
if [ -z "$bonus_rule" ]; then
	watch_pid=$(ps |grep -v grep| grep /bin/check_guest_wifi_bonus.sh| awk -F' ' '{print $1}')
	kill -9 "$watch_pid"
else
	/bin/guestWifiTimer.sh check_bonus_time
fi