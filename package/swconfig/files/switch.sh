#!/bin/sh
# Copyright (C) 2009 OpenWrt.org

setup_ACL(){
	##Drop ICMP type 3 code 3
	ssdk_sh rate aclpolicer set 0 no yes no no no 128 32768 0 0 1ms
	ssdk_sh acl status set enable
	ssdk_sh acl list create 1 1
	ssdk_sh acl rule add 1 0 1 ip4 no no no no no no no no no no no no no no no no no no no no no no no no yes 3 0xf yes 3 0xf no no yes no no no no no no no no no no 0 0 no no no no no no no yes 0 no no no no no

	##LAN
	ssdk_sh acl list bind 1 0 0 1
	ssdk_sh acl list bind 1 0 0 2
	ssdk_sh acl list bind 1 0 0 3
	ssdk_sh acl list bind 1 0 0 4

	##WAN
	ssdk_sh acl list bind 1 0 0 5
}

support_802_3az() {

	##Set 802.3az default enable
	for i in 0 1 2 3 4
	do
		ssdk_sh debug phy set 0x$i 0xd 0x7
		ssdk_sh debug phy set 0x$i 0xe 0x3c
		ssdk_sh debug phy set 0x$i 0xd 0x4007
		ssdk_sh debug phy set 0x$i 0xe 0x6
		ssdk_sh debug phy set 0x$i 0x0 0x1200
	done

	ssdk_sh debug reg set 0x100 0x0001550 4

}

setup_switch_dev() {
	config_get name "$1" name
	name="${name:-$1}"
	[ -d "/sys/class/net/$name" ] && ifconfig "$name" up
	swconfig dev "$name" load network
}

setup_switch() {
	config_load network
	config_foreach setup_switch_dev switch

	countrycode=$(fw_printenv countrycode | awk -F"=" '{print $2}' | tr [a-f] [A-F])
	if [ "$countrycode" == "E1" ]; then
		##Set 802.3az default enable, and Reduce power loss for ERP requesting.
		support_802_3az
	fi

	setup_ACL
}
