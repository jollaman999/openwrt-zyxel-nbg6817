#!/bin/sh
local DEV

mergeDate(){
	daily_data="$1"
	daily_data_length=$(echo "$daily_data" | sed 's/,//g' | wc -L)
	time_day=""
	output_time=""

	if [ "$daily_data_length" == "24" ];then
		for hour_data in $(echo "$daily_data" | sed 's/,/ /g')
		do
			if [ "$hour_data" == "0" ];then
				time_day="0,0,"
			elif [ "$hour_data" == "1" ];then
				time_day="1,1,"
			fi
			output_time="$output_time$time_day"
		done
		echo "${output_time%?}"	 #return value
	fi
}

init_schedule(){
	for day in sun mon tue wed thu fri sat
	do
		local daily=$(uci get wifi_schedule"$DEV"."$day".times)
		local daily_data=$(mergeDate $daily)
		uci set wifi_schedule"$DEV"."$day".times="$daily_data"
		uci commit
	done
}

init(){
	rm /tmp/newWifiSchedule"$DEV"

	local daily_data_length=$(uci get wifi_schedule"$DEV".sun.times | sed 's/,//g' | wc -L)
	if [ "$daily_data_length" == "24" ]; then
		# merge data model
		init_schedule
	fi
}

check_dev(){
	DEV="$2"
	if [ "$DEV" == "24G" ];then
		DEV=""
	elif [ "$DEV" == "5G" ];then
		DEV="5G"
	fi
}

## command: /sbin/mergeWifiSchedule.sh init 24G
case $1 in
	init)
		check_dev "$@"
		init
		;;
esac
