#!/bin/sh

[ -x /usr/sbin/pppd ] || exit 0

[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. /lib/functions/network.sh
	. ../netifd-proto.sh
	init_proto "$@"
}

ppp_select_ipaddr()
{
	local subnets=$1
	local res
	local res_mask

	for subnet in $subnets; do
		local addr="${subnet%%/*}"
		local mask="${subnet#*/}"

		if [ -n "$res_mask" -a "$mask" != 32 ]; then
			[ "$mask" -gt "$res_mask" ] || [ "$res_mask" = 32 ] && {
				res="$addr"
				res_mask="$mask"
			}
		elif [ -z "$res_mask" ]; then
			res="$addr"
			res_mask="$mask"
		fi
	done

	echo "$res"
}

ppp_exitcode_tostring()
{
	local errorcode=$1
	[ -n "$errorcode" ] || errorcode=5

	case "$errorcode" in
		0) echo "OK" ;;
		1) echo "FATAL_ERROR" ;;
		2) echo "OPTION_ERROR" ;;
		3) echo "NOT_ROOT" ;;
		4) echo "NO_KERNEL_SUPPORT" ;;
		5) echo "USER_REQUEST" ;;
		6) echo "LOCK_FAILED" ;;
		7) echo "OPEN_FAILED" ;;
		8) echo "CONNECT_FAILED" ;;
		9) echo "PTYCMD_FAILED" ;;
		10) echo "NEGOTIATION_FAILED" ;;
		11) echo "PEER_AUTH_FAILED" ;;
		12) echo "IDLE_TIMEOUT" ;;
		13) echo "CONNECT_TIME" ;;
		14) echo "CALLBACK" ;;
		15) echo "PEER_DEAD" ;;
		16) echo "HANGUP" ;;
		17) echo "LOOPBACK" ;;
		18) echo "INIT_FAILED" ;;
		19) echo "AUTH_TOPEER_FAILED" ;;
		20) echo "TRAFFIC_LIMIT" ;;
		21) echo "CNID_AUTH_FAILED";;
		*) echo "UNKNOWN_ERROR" ;;
	esac
}

## WenHsien-EMG2926-2013.1122
echo 2 > /proc/sys/net/ipv6/conf/default/accept_ra

ppp_generic_init_config() {
	proto_config_add_string username
	proto_config_add_string password
	proto_config_add_string keepalive
	proto_config_add_int demand
	proto_config_add_string pppd_options
	proto_config_add_string 'connect:file'
	proto_config_add_string 'disconnect:file'
	proto_config_add_string ipv6
	proto_config_add_boolean authfail
	proto_config_add_int mtu
	proto_config_add_boolean keepalive_adaptive
	proto_config_add_string pppname
	proto_config_add_string unnumbered
}

ppp_generic_setup() {
	local config="$1"; shift
	local localip

	# udhcpc_pid=$(ps | grep "udhcpc" | grep "grep" -v | awk '{print $1}')
	# if [ "$udhcpc_pid" != "" ]; then
	#	kill $udhcpc_pid
	# fi

	# pppd_pid=$(ps | grep "pppd" | grep "grep" -v | awk '{print $1}')
	# if [ "$pppd_pid" != "" ]; then
	# 	kill $pppd_pid
	# fi

	## Michael
    uci set dhcp6c.basic.interface="$config"

	## Michael
    local ipv4
	config_get_bool ipv4 "$config" ipv4 0
	[ "$ipv4" -eq 1 ] && ipv4="" || ipv4="noip"
	
	json_get_vars ipv6 demand keepalive keepalive_adaptive username password pppd_options pppname unnumbered
	if [ "$ipv6" = 0 ]; then
		ipv6=""
	elif [ -z "$ipv6" -o "$ipv6" = auto ]; then
		ipv6=1
		proto_export "AUTOIPV6=1"
	fi

	if [ "${demand:-0}" -gt 0 ]; then
		demand="precompiled-active-filter /etc/ppp/filter demand idle $demand"
	else
		demand=""
	fi

	local pppoeWanIpAddr
	config_get pppoeWanIpAddr "$config" pppoeWanIpAddr	

	[ -n "$mtu" ] || json_get_var mtu mtu
	[ -n "$pppname" ] || pppname="${proto:-ppp}-$config"
	[ -n "$unnumbered" ] && {
		local subnets
		( proto_add_host_dependency "$config" "" "$unnumbered" )
		network_get_subnets subnets "$unnumbered"
		localip=$(ppp_select_ipaddr "$subnets")
		[ -n "$localip" ] || {
			proto_block_restart "$config"
			return
		}
	}

	local lcp_failure="${keepalive%%[, ]*}"
	local lcp_interval="${keepalive##*[, ]}"
	local lcp_adaptive="lcp-echo-adaptive"
	[ "${lcp_failure:-0}" -lt 1 ] && lcp_failure=""
	[ "$lcp_interval" != "$keepalive" ] || lcp_interval=5
	[ "${keepalive_adaptive:-1}" -lt 1 ] && lcp_adaptive=""
	[ -n "$connect" ] || json_get_var connect connect
	[ -n "$disconnect" ] || json_get_var disconnect disconnect

	proto_run_command "$config" /usr/sbin/pppd \
		nodetach ipparam "$config" \
		ifname "$pppname" \
		${localip:+$localip:} \
		${lcp_failure:+lcp-echo-interval $lcp_interval lcp-echo-failure $lcp_failure $lcp_adaptive} \
		${ipv6:++ipv6} \
		nodefaultroute \
		usepeerdns \
		$demand maxfail 1 \
		${username:+user "$username" password "$password"} \
		${connect:+connect "$connect"} \
		${disconnect:+disconnect "$disconnect"} \
		ip-up-script /lib/netifd/ppp-up \
		ipv6-up-script /lib/netifd/ppp-up \
		ip-down-script /lib/netifd/ppp-down \
		ipv6-down-script /lib/netifd/ppp-down \
		${mtu:+mtu $mtu mru $mtu} \
		${pppoeWanIpAddr:+ "$pppoeWanIpAddr":} \
		"$@" $pppd_options

		##Set switch framemaxSize(MTU size) to default
		ssdk_sh misc framemaxSize set 0x5EE

		client_ifname=$(uci get network.$config.ifname)
		ip6addr=$(uci get network.$config.ip6addr)
		prefixlen=$(uci get network.$config.prefixlen)

		ifconfig $client_ifname del $ip6addr/$prefixlen
		ifconfig pppoe-$config del $ip6addr/$prefixlen
		kill -9 $(cat /var/run/dhcp6c-pppoe-$config.pid)
		kill -9 $(cat /var/run/dhcp6c-$client_ifname.pid)
 

		## Michael
		##dhcpv6 follows ppp
		# WenHsien: ipv6 changed from "+ipv6" to "1" in 2926 with kernel 3.3.8, 2013.1114.
		#	[ "$ipv6" == "+ipv6" ] && {
		[ "$ipv6" == "1" ] && {
			##/etc/init.d/RA_status restart
			##sleep 2
			#uci set dhcp6c.basic.ifname=${link}
			#uci set dhcp6c.basic.interface=$1
			uci set dhcp6c.basic.enabled=1
			uci set dhcp6c.lan.enabled=1
			uci set dhcp6c.lan.sla_id=0
			uci set dhcp6c.lan.sla_len=0
			uci set dhcp6c.basic.RA_accepted=1
			uci set dhcp6c.basic.domain_name_servers=1
			uci set dhcp6c.basic.pd=1
			uci commit dhcp6c
			#sleep 4
			/etc/init.d/dhcp6c restart
		}

		## Michael
		## workaround- IPv6 only
		[ "$ipv4" == "noip" ] && {
			sleep 8
			interface=$(uci get dhcp6c.basic.ifname)
			local ipv4_address="$(ifconfig $interface | awk '/inet addr:/{print $2}' | sed 's/addr://g')"
			ip addr del $ipv4_address dev $interface
		}

		
}

ppp_generic_teardown() {
	local interface="$1"
	local errorstring=$(ppp_exitcode_tostring $ERROR)

	case "$ERROR" in
		0)
		;;
		2)
			proto_notify_error "$interface" "$errorstring"
			proto_block_restart "$interface"
		;;
		11|19)
			json_get_var authfail authfail
			proto_notify_error "$interface" "$errorstring"
			if [ "${authfail:-0}" -gt 0 ]; then
				proto_block_restart "$interface"
			fi
		;;
		*)
			proto_notify_error "$interface" "$errorstring"
		;;
	esac

	proto_kill_command "$interface"
}

# PPP on serial device

proto_ppp_init_config() {
	proto_config_add_string "device"
	ppp_generic_init_config
	no_device=1
	available=1
	lasterror=1
}

proto_ppp_setup() {
	local config="$1"

	json_get_var device device
	ppp_generic_setup "$config" "$device"
}

proto_ppp_teardown() {
	ppp_generic_teardown "$@"
}

proto_pppoe_init_config() {
	ppp_generic_init_config
	proto_config_add_string "ac"
	proto_config_add_string "service"
	proto_config_add_string "host_uniq"
	lasterror=1
}

proto_pppoe_setup() {
	local config="$1"
	local iface="$2"

	for module in slhc ppp_generic pppox pppoe; do
		/sbin/insmod $module 2>&- >&-
	done

	json_get_var mtu mtu
	mtu="${mtu:-1492}"

	json_get_var ac ac
	json_get_var service service
	json_get_var host_uniq host_uniq

	ppp_generic_setup "$config" \
		plugin rp-pppoe.so \
		${ac:+rp_pppoe_ac "$ac"} \
		${service:+rp_pppoe_service "$service"} \
		${host_uniq:+host-uniq "$host_uniq"} \
		"nic-$iface"
}

proto_pppoe_teardown() {
	ppp_generic_teardown "$@"
}

proto_pppoa_init_config() {
	ppp_generic_init_config
	proto_config_add_int "atmdev"
	proto_config_add_int "vci"
	proto_config_add_int "vpi"
	proto_config_add_string "encaps"
	no_device=1
	available=1
	lasterror=1
}

proto_pppoa_setup() {
	local config="$1"
	local iface="$2"

	for module in slhc ppp_generic pppox pppoatm; do
		/sbin/insmod $module 2>&- >&-
	done

	json_get_vars atmdev vci vpi encaps

	case "$encaps" in
		1|vc) encaps="vc-encaps" ;;
		*) encaps="llc-encaps" ;;
	esac

	ppp_generic_setup "$config" \
		plugin pppoatm.so \
		${atmdev:+$atmdev.}${vpi:-8}.${vci:-35} \
		${encaps}
}

proto_pppoa_teardown() {
	ppp_generic_teardown "$@"
}

proto_pptp_init_config() {
	ppp_generic_init_config
	proto_config_add_string "server"
	proto_config_add_string "interface"
	available=1
	no_device=1
	lasterror=1
}

scan_pptp() {
	scan_ppp "$@"
}

proto_pptp_setup() {
	local config="$1"
	local iface="$2"

	scan_pptp "$config"	
	config_get pptp_Nailedup vpn pptp_Nailedup
	config_get server vpn pptp_serverip
	config_get pptp_proto vpn proto
	config_get pptp_mtu wan pptp_mtu
	#config_get mtu vpn mtu
	#config_get device "$config" device
	
	config_get pptp_Nailedup vpn pptp_Nailedup

	# udhcpc_pid=$(ps | grep "udhcpc" | grep "grep" -v | awk '{print $1}')
	# if [ "$udhcpc_pid" != "" ]; then
	#	kill $udhcpc_pid
	# fi

	hostname=$(uci get system.main.hostname)
	wan_dev=$(uci get network.wan.ifname)

	if [ "$pptp_proto" == "dhcp" ]; then
		udhcpc -p "/var/run/udhcpc-$wan_dev.pid" -t 0 -i $wan_dev -H "$hostname" -R -s /usr/share/udhcpc/udhcpc_pptp.sh
		#udhcpc -p "/var/run/udhcpc-$wan_dev.pid" -t 0 -i $wan_dev -H "$hostname" -R
  	else
  		wan_IP=$(uci get network.wan.ipaddr)
  		wan_dev=$(uci get network.wan.ifname)
  		wan_netmask=$(uci get network.wan.netmask)
		#config_get wan_IP wan ipaddr
		#config_get wan_dev wan ifname
		#config_get wan_netmask wan netmask

  		ifconfig $wan_dev $wan_IP netmask $wan_netmask up
	fi
	
	for module in slhc ppp_generic ppp_async pppox pptp ppp_mppe_mppc; do
		/sbin/insmod $module 2>&- >&-
	done

	# make sure only one pppd process is started
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
                #echo "nameserver 1.1.1.1" > /tmp/resolv.conf.auto
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

'	local ip serv_addr server interface
	json_get_vars interface server
	[ -n "$server" ] && {
		for ip in $(resolveip -t 5 "$server"); do
			( proto_add_host_dependency "$config" "$ip" $interface )
			serv_addr=1
		done
	}
	[ -n "$serv_addr" ] || {
		echo "Could not resolve server address"
		sleep 5
		proto_setup_failed "$config"
		exit 1
	}

	local load
	for module in slhc ppp_generic ppp_async ppp_mppe ip_gre gre pptp; do
		grep -q "^$module " /proc/modules && continue
		/sbin/insmod $module 2>&- >&-
		load=1
	done
	[ "$load" = "1" ] && sleep 1

	ppp_generic_setup "$config" \
		plugin pptp.so \
		pptp_server $server \
		file /etc/ppp/options.pptp
'
}

proto_pptp_teardown() {
	ppp_generic_teardown "$@"
}

[ -n "$INCLUDE_ONLY" ] || {
	add_protocol ppp
	[ -f /usr/lib/pppd/*/rp-pppoe.so ] && add_protocol pppoe
	[ -f /usr/lib/pppd/*/pppoatm.so ] && add_protocol pppoa
	[ -f /usr/lib/pppd/*/pptp.so ] && add_protocol pptp
}

