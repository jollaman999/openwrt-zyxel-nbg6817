#!/bin/sh

. /etc/functions.sh
include /lib/config

##wifi0--5G   wifi1--24G
DEV24G="wifi1"
DEV5G="wifi0"
DEV24G_FIRSTNAME="ath1"		#ath10 ath11 ath12 ath13
DEV5G_FIRSTNAME="ath"		#ath0 ath1 ath2 ath3

wifi_scheduling_up()
{
	wifi_status=$(uci_get wireless "$DEV5G_FIRSTNAME"0 disabled)

	if [ "$wifi_status" == "1" ]; then
		exit 0
	fi
	
	chk_wifi=$(iwconfig "$DEV5G_FIRSTNAME"0)
#	bootflag=$(cat /tmp/bootflag | sed 's/"//g' )
#	[ "$bootflag" == "1" ] || {			
		[ -n "$chk_wifi" ] || {			
			while :
			do
				if [ -f "/tmp/WirelessDev" ];then
					dev=$(cat /tmp/WirelessDev | sed 's/"//g' )
					if [ "$dev" == "$DEV5G" ]; then
						break
					fi
					sleep 1
				else
					echo $DEV5G > /tmp/WirelessDev
					/etc/init.d/wireless restart
					/etc/init.d/wireless5G_macfilter restart
					break
				fi
			done
		}	
#	}
}

wifi_scheduling_down()
{
	/sbin/wifi down $DEV5G
}

show_help()
{
	echo 'Wireless_scheduling : invalid argument'
}


if [ $# = 0 ]; then
show_help
exit 0
fi

case $1 in

up)
wifi_scheduling_up
;;
down)
wifi_scheduling_down
;;
*)
show_help
;;
esac
