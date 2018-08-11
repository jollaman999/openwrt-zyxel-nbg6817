#!/bin/sh
local FILENAME="/etc/crontabs/root"

local product=$(uci get system.main.product_name)
if [ "$product" == "NBG6817" ];then
	DEV24G="ath1"
	DEV5G="ath"
else
	DEV24G="ath"
	DEV5G="ath1"
fi

check_rule(){
	local iface="$1"
	local timer_index
	local running_iface=$(ls /tmp/timer_setting_* |awk -F '_' '{print $3}')
	for face in $running_iface
	do
		if [ "$face" == "$iface" ];then
			timer_index=$(cat /tmp/timer_index_$iface)
			at -d $timer_index
		fi
	done
}

set_rule(){
	local GUEST_NUMBER="$1"		# 1, 2, 3
	local DEV="$2"				# ath, ath1
	local TIMER="$3"			# 1:30
	local iface="$DEV$GUEST_NUMBER"
	local timer_hh=$(echo $TIMER | awk -F':' '{print $1}')
	local timer_mm=$(echo $TIMER | awk -F':' '{print $2}')
	local time2minute=`expr $timer_hh \* 60 + $timer_mm`

	check_rule "$iface"

	[ "$timer_hh" == "0" ] && [ "$timer_mm" == "0" ] || {
		echo "$TIMER" > /tmp/timer_setting_$iface
		cat /proc/uptime | awk '{print $1}' | awk -F'.' '{print $1}' > /tmp/timer_up_time_$iface
		at now + $time2minute minutes -f /bin/guest_wifi_$iface 2>&1 | awk '/job/{print $2}' > /tmp/timer_index_$iface
	}
}

add_rule(){
	local GUEST_NUMBER="$2"
	local DEV="$3"
	local timer="$4"

	if [ "$DEV" == "24G" ];then
		set_rule "$GUEST_NUMBER" "$DEV24G" "$timer"
	elif [ "$DEV" == "5G" ]; then
		set_rule "$GUEST_NUMBER" "$DEV5G" "$timer"
	fi

	if [ ! -e "/tmp/reload_bonus" ];then
		check_watch=$(ps |grep -v grep |grep check_guest_wifi_bonus.sh)
		if [ -z "$check_watch" ]; then
			watch -tn 1800 /bin/check_guest_wifi_bonus.sh 1>/dev/null 2>&1 &
		else
			/bin/check_guest_wifi_bonus.sh
		fi
	fi
}


remove_rule(){
	local GUEST_NUMBER="$2"		# 1, 2, 3
	local DEV="$3"				# ath, ath1
	local iface
	local timer_index

	if [ "$DEV" == "24G" ]; then
		iface="$DEV24G$GUEST_NUMBER"
	elif [ "$DEV" == "5G" ]; then
		iface="$DEV5G$GUEST_NUMBER"
	fi

	timer_index=$(cat /tmp/timer_index_$iface)
	at -d $timer_index

	rm /tmp/timer_setting_$iface
	rm /tmp/timer_up_time_$iface
	rm /tmp/timer_index_$iface
}

disable_guest_wifi(){
	local GUEST_NUMBER="$2"		# 1, 2, 3
	local DEV="$3"				# ath, ath1
	local iface

	if [ "$DEV" == "24G" ]; then
		iface="$DEV24G$GUEST_NUMBER"
		remove_rule "$GUEST_NUMBER" 24G
		echo "$iface" > /tmp/wifi24G_Apply
		echo "$(uci get wireless.iface.wifi24G)" > /tmp/WirelessDev
	elif [ "$DEV" == "5G" ]; then
		iface="$DEV5G$GUEST_NUMBER"
		remove_rule "$GUEST_NUMBER" 5G
		echo "$iface" > /tmp/wifi5G_Apply
		echo "$(uci get wireless.iface.wifi5G)" > /tmp/WirelessDev
	fi

	uci set wireless.$iface.disabled=1
	uci commit
	sync #This command is for emmc and ext4 filesystem
	luci-reload wireless wireless_macfilter wireless5G_macfilter wifi_schedule wifi_schedule5G
}

get_time(){
	local GUEST_NUMBER="$2" 	#1 2 3
	local DEV="$3"				#24G 5G
	local iface
	local sys_uptime=$(cat /proc/uptime | awk '{print $1}' | awk -F'.' '{print $1}')
	local timer_uptime
	local sum
	local hour
	local minute
	local total
	local re_value=""

	if [ "$DEV" == "24G" ];then
		iface=$DEV24G$GUEST_NUMBER
	elif [ "$DEV" == "5G" ];then
		iface=$DEV5G$GUEST_NUMBER
	fi

	if [ -e "/tmp/timer_setting_$iface" ];then
		hour=$(cat /tmp/timer_setting_$iface | awk -F':' '{print $1}')
		minute=$(cat /tmp/timer_setting_$iface | awk -F':' '{print $2}')
		total=`expr $hour \* 60 \* 60 + $minute \* 60`
		timer_uptime=$(cat /tmp/timer_up_time_$iface)
		sum=`expr "$sys_uptime" - "$timer_uptime"`
		total=`expr $total - $sum`
		re_value="$total"
	else
		re_value="0"
	fi

	echo -n $re_value
}

get_time_GUI_ctrl(){
	local iface="$1"		#ath1
	local sys_uptime=$(cat /proc/uptime | awk '{print $1}' | awk -F'.' '{print $1}')
	local timer_uptime
	local sum
	local hour
	local minute
	local total
	local re_value=""

	if [ -e "/tmp/timer_setting_$iface" ];then
		hour=$(cat /tmp/timer_setting_$iface | awk -F':' '{print $1}')
		minute=$(cat /tmp/timer_setting_$iface | awk -F':' '{print $2}')
		total=`expr $hour \* 60 \* 60 + $minute \* 60`
		timer_uptime=$(cat /tmp/timer_up_time_$iface)
		sum=`expr "$sys_uptime" - "$timer_uptime"`
		total=`expr $total - $sum`
		re_value="$total"
	else
		re_value="0"
	fi

	echo -n $re_value
}

rm_at_rule(){
	if [ "$2" != "all" ]; then
		wifi24G=$(uci get wireless.iface.wifi24G)
		if [ "$wifi24G" == "$2" ]; then
			iface="24G"
		else
			iface="5G"
		fi
	fi

	for number in $(atq | awk -F' ' '{print $1}' | tr '\r\n' ' ')
	do
		if [ "$2" == "all" ]; then
			atq_cmd=$(at -c "$number" | grep guestWifiTimer)
			guest_num=$(echo $atq_cmd | awk -F' ' '{print $3}')
			iface=$(echo $atq_cmd | awk -F' ' '{print $4}')
			if [ -n "$atq_cmd" ]; then
				remove_rule "remove_rule" "$guest_num" "$iface"
			fi
		else
			atq_cmd=$(at -c "$number" | grep guestWifiTimer | grep "$iface")
			guest_num=$(echo $atq_cmd | awk -F' ' '{print $3}')
			if [ -n "$atq_cmd" ]; then
				remove_rule "remove_rule" "$guest_num" "$iface"
			fi
		fi
	done
}

check_bonus_time(){
	for ath in ath1 ath2 ath3 ath11 ath12 ath13
	do
		bonus_time=`expr $(get_time_GUI_ctrl $ath) / 60`
		if [ "$bonus_time" != "0" ]; then
			if [ "$bonus_time" -ge "60" ]; then
				bonus_time_hh=`expr $bonus_time / 60`
				bonus_time_mm=`expr $bonus_time % 60`
				bonus_time="$bonus_time_hh:$bonus_time_mm"
			else
				bonus_time_mm=`expr $bonus_time % 60`
				bonus_time="0:$bonus_time_mm"
			fi
			uci set wireless.$ath.bonus_time=$bonus_time
		else
			uci delete wireless.$ath.bonus_time
		fi
	done
	uci commit wireless
}

case $1 in
	add_rule )
		add_rule "$@"
		# /bin/guestWifiTimer.sh add_rule 3 24G 1:30
		;;
	remove_rule )
		remove_rule "$@"
		# /bin/guestWifiTimer.sh remove_rule 3 24G
		;;
	disable_guest_wifi )
		disable_guest_wifi "$@"
		# /bin/guestWifiTimer.sh disable_guest_wifi 3 24G
		;;
	get_time )
		get_time "$@"
		# /bin/guestWifiTimer.sh get_time 1 24G
		;;
	get_time_GUI_ctrl )
		get_time_GUI_ctrl "$2"
		# /bin/guestWifiTimer.sh get_time_GUI_ctrl ath1
		;;
	rm_at_rule )
		rm_at_rule "$@"
		# /bin/guestWifiTimer.sh rm_at_rule all/wifi0/wifi1
		;;
	check_bonus_time )
		check_bonus_time "$@"
		# /bin/guestWifiTimer.sh check_bonus_time
		;;
esac
exit 0
