scan_pptp() {
	scan_ppp "$@"
}

setup_interface_pptp() {
	local iface="$1"
	local config="$2"
	
	scan_pptp "$config"	
	#config_get device "$config" device
	config_get pptp_Nailedup vpn pptp_Nailedup
	config_get server vpn pptp_serverip
	config_get pptp_proto vpn proto
	#config_get mtu vpn mtu
	config_get pptp_mtu wan pptp_mtu
		
	for module in slhc ppp_generic ppp_async pppox pptp; do
		/sbin/insmod $module 2>&- >&-
	done

	# make sure only one pppd process is started
	lock "/var/lock/ppp-${cfg}"
	local pid="$(head -n1 /var/run/ppp-${cfg}.pid 2>/dev/null)"
	[ -d "/proc/$pid" ] && grep pppd "/proc/$pid/cmdline" 2>/dev/null >/dev/null && {
		lock -u "/var/lock/ppp-${cfg}"
		return 0
	}
	# Workaround: sometimes hotplug2 doesn't deliver the hotplug event for creating
	# /dev/ppp fast enough to be used here
	[ -e /dev/ppp ] || mknod /dev/ppp c 108 0

	[ "$pptp_Nailedup" != "1" ] && {
                config_get demand "$cfg" demand
#                echo "nameserver 1.1.1.1" > /tmp/resolv.conf.auto
                /sbin/update_sys_dns
		/sbin/update_lan_dns
        }

	setup_interface "$iface" "$config" "$pptp_proto"
	/sbin/set_pptp_options

	# kill active pptp daemon
	pptp_pid=$(ps | grep "options.pptp" | grep "grep" -v | awk '{print $1}')
	if [ "$pptp_pid" != "" ]; then
  		kill $pptp_pid
	fi

	mtu=${pptp_mtu:-1452}	
	#/usr/sbin/pppd file /etc/ppp/options.pptp mtu $mtu mru $mtu  &

	/usr/sbin/pppd plugin pptp.so file /tmp/options.pptp mtu $mtu mru $mtu
	lock -u "/var/lock/ppp-${cfg}"

	
	#start_pppd "$config" \
	#	pty "/usr/sbin/pptp $server --loglevel 0 --nolaunchpppd" \
	#	file /etc/ppp/options.pptp \
	#	mtu $mtu mru $mtu
}
