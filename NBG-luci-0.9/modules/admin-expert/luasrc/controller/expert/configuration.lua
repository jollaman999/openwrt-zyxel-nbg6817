--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: index.lua 4040 2009-01-16 12:35:25Z Cyrus $
]]--
module("luci.controller.expert.configuration", package.seeall)
local uci = require("luci.model.uci").cursor()
local sys = require("luci.sys")

country_code_table = {
	FF={"reg0", "reg16","reg16","reg16"},-- USA         #20M,40M,80M  //DEBUG   old:{"reg0", "reg7"}
	FF_QCA={"reg0", "reg21","reg16","reg16"},-- USA         #20M,40M,80M  //DEBUG   old:{"reg0", "reg7"}
	FE={"reg1", "reg7"},				 -- S.Africa
	FD={"reg1", "reg1"},				 -- Netherland
	FC={"reg1", "reg1"},				 -- Denmark
	FA={"reg1", "reg1"},				 -- Sweden
	F9={"reg1", "reg1"},				 -- UK
	F8={"reg1", "reg1"},				 -- Belgium
	F7={"reg1", "reg1"},				 -- Greece
	F6={"reg1", "reg2"},				 -- Czech
	F5={"reg1", "reg1"},				 -- Norway
	F4={"reg1", "reg9"},				 -- Australia
	F3={"reg1", "reg9"},				 -- New Zealand   //without 165
	F2={"reg1", "reg7"},				 -- Hong Kong
	F1={"reg1", "reg0"},				 -- Singapore
	F0={"reg1", "reg1"},				 -- Finland
	EF={"reg1", "reg6"},				 -- Morocco
	EE={"reg0", "reg23","reg22","reg18"},-- Taiwan       #20M,40M,80M// old: {"reg0", "reg13"}
	EE_QCA={"reg0", "reg24","reg3","reg3"},-- Taiwan       #20M,40M,80M// old: {"reg0", "reg13"}
	ED={"reg1", "reg1"},				 -- German
	EC={"reg1", "reg1"},				 -- Italy
	EB={"reg1", "reg1"},				 -- Ireland
	EA={"reg1", "reg1"},				 -- Japan         //without 184 188 192 196
	E9={"reg1", "reg1"},				 -- Austria
	E8={"reg1", "reg0"},				 -- Malaysia
	E7={"reg1", "reg1"},				 -- Poland
	E6={"reg1", "reg0"},				 -- Russia
	E5={"reg1", "reg1"},				 -- Hungary
	E4={"reg1", "reg1"},				 -- Slovak
	E3={"reg1", "reg7"},				 -- Thailand
	E2={"reg1", "reg2"},				 -- Israel
	E1={"reg1", "reg20","reg19","reg17"},-- Switzerland  #20M,40M,80M
	E1_QCA={"reg1", "reg20","reg19","reg17"},-- Switzerland  #20M,40M,80M
	E0={"reg1", "reg1"},				 -- UAE
	DE={"reg1", "reg4"},				 -- China
	DD={"reg1", "reg0"},				 -- Ukraine
	DC={"reg1", "reg1"},				 -- Portugal
	DB={"reg1", "reg1"},				 -- France
	DA={"reg1", "reg11"},				 -- Korea
	D9={"reg1", "reg7"},				 -- Korea
	D8={"reg1", "reg7"},				 -- Philippine
	D7={"reg1", "reg1"},				 -- Slovenia
	D6={"reg1", "reg7"},				 -- India
	D5={"reg1", "reg1"},				 -- Spain
	D3={"reg1", "reg1"},				 -- Turkey
	D1={"reg1", "reg7"},				 -- Peru
	D0={"reg0", "reg7"},				 -- Brazil
	CB={"reg1", "reg1"},				 -- Bulgaria
	CC={"reg1", "reg1"},				 -- Luxembourg
	CE={"reg0", "reg16","reg16","reg16"},-- Canada
	CE_QCA={"reg0", "reg21","reg16","reg16"},-- Canada
	CD={"reg1", "reg1"},				 -- Iceland
	CF={"reg1", "reg1"}				 -- Romania
}

channelRange = {
	reg0="1-11",    --region 0
	reg1="1-13",    --region 1
	reg2="10-11",   --region 2
	reg3="10-13",   --region 3
	reg4="14",      --region 4
	reg5="1-14",    --region 5
	reg6="3-9",     --region 6
	reg7="5-13"    --region 7
}

channelRange5G = {
	reg0="36,40,44,48,52,56,60,64,149,153,157,161,165",                                               --region 0
	reg1="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140",                       --region 1
	reg2="36,40,44,48,52,56,60,64",                                                                   --region 2
	reg3="56,60,64,149,153,157,161",                                                                  --region 3
	reg4="149,153,157,161,165",                                                                       --region 4
	reg5="149,153,157,161",                                                                           --region 5
	reg6="36,40,44,48",                                                                               --region 6
	reg7="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,149,153,157,161,165",   --region 7
	reg8="52,56,60,64",                                                                               --region 8
	reg9="36,40,44,48,52,56,60,64,100,104,108,112,116,132,136,140,149,153,157,161,165",               --region 9
	reg10="36,40,44,48,149,153,157,161,165",                                                          --region 10
	reg11="36,40,44,48,52,56,60,64,100,104,108,112,116,120,149,153,157,161",                          --region 11
	reg12="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140",                      --region 12
	reg13="52,56,60,64,100,104,108,112,116,120,124,128,132,136,140,149,153,157,161",                  --region 13
	reg14="36,40,44,48,52,56,60,64,100,104,108,112,116,136,140,149,153,157,161,165",                  --region 14
	reg15="149,153,157,161,165,169,173",                                                              --region 15
	reg16="36,40,44,48,149,153,157,161",                                                              --region 16(QTN US 80M 40M)
	reg17="36,40,44,48,52,56,60,64,100,104,108,112,120,124,128",		    	                  --region 17(QTN eu 80M)
	reg18="52,56,60,64,100,104,108,112,149,153,157,161",                                              --region 18(QTN tw 80M)
	reg19="36,40,44,48,52,56,60,64,100,104,108,112,120,124,128,132,136",				  --region 19(QTN eu 40M)
	reg20="36,40,44,48,52,56,60,64,100,104,108,112,116,120,124,128,132,136,140",			  --region 20(QTN eu 20M)
	reg21="36,40,44,48,149,153,157,161,165",							  --region 21(QTN us 20M)
	reg22="52,56,60,64,100,104,108,112,132,136,149,153,157,161",					  --region 22(QTN tw 40M)
	reg23="52,56,60,64,100,104,108,112,116,132,136,140,149,153,157,161",			  --region 23(QTN tw 20M)
	reg24="56,60,64,149,153,157,161,165",
}

function index()

	local i18n = require("luci.i18n")
	local libuci = require("luci.model.uci").cursor()
	local lang = libuci:get("system","main","language")
	i18n.load("admin-core",lang)
	i18n.load("streamboost",lang)
	i18n.setlanguage(lang)

	local streamboost_status = libuci:get("qos","general","streamboost")
	local ZyXEL_Mode = libuci:get("system","main","system_mode")
	local Product_Model = libuci:get("system","main","product_model")
	local op_mode

	if not ZyXEL_Mode then
		ZyXEL_Mode = "1"
	end

	if ZyXEL_Mode == "1" then
		op_mode = "wan"
	else
		op_mode = "wlan"
	end
    local page  = node("expert", "configuration_fw")
	page.target = template("expert_configuration/expert_mode_fw")
	page.title  = i18n.translate("Configuration_fw")
	page.order  = 39

	local page  = node("expert", "configuration")
	page.target = template("expert_configuration/expert_mode")
	page.title  = i18n.translate("Configuration")
	page.order  = 40

	local page  = node("expert", "configuration", "network")
    page.target = alias("expert", "configuration", "network", op_mode)
	page.title  = i18n.translate("Network")
	page.index = true
	page.order  = 41

	local page  = node("expert", "configuration", "network", "mode_ex")
	page.target = call("action_mode_ex")
	page.title  = "Easy"
	page.order  = 401

	local page  = node("expert", "configuration","menubar")
	page.target = call("action_menubar")
	page.title  = "Menubar"
	page.order  = 402

if ZyXEL_Mode ~= "2" and ZyXEL_Mode ~= "3" then

	local page  = node("expert", "configuration", "network", "wan")
	page.target = call("action_wan")
	page.title  = i18n.translate("WAN")
	page.order  = 420

	local page  = node("expert", "configuration", "network", "menu_wan")
	page.target = call("action_menu_wan")
	page.title  = "Advanced"
	page.order  = 4201

	local page  = node("expert", "configuration", "network", "internet_connection")
	page.target = call("action_wan_internet_connection")
	page.title  = i18n.translate("WAN")
	page.order  = 42

	local page  = node("expert", "configuration", "network", "wan","ipv6")
	page.target = call("action_wan_ipv6")
	--page.target = template("expert_configuration/ipv6")
	--page.title  = i18n.translate("IPv6")
	page.title  = "IPv6"
	page.order  = 420

    local page  = node("expert", "configuration", "network", "wan","advanced")
    page.target = call("action_wan_advanced")
    page.title  = "Advanced"
    page.order  = 421

end

--[[wireless2.4G]]--
	local page  = node("expert", "configuration", "network", "wireless")
	page.target = call("action_wireless")
	page.title  = "Wireless"
	page.order  = 431

	local page  = node("expert", "configuration", "network", "menu_wireless")
	page.target = call("action_menu_wireless")
	page.title  = "Wireless"
	page.order  = 432

	local page  = node("expert", "configuration", "network", "wlan")
	--[[ page.target = template("expert_configuration/wlan")	]]--
if ZyXEL_Mode ~= "4" then
	page.target = call("wlan_general")
else
	page.target = call("wlan_apcli_wisp")
end
	page.title  = i18n.translate("Wireless_LAN_2_dot_4_G")
	page.order  = 43

if ZyXEL_Mode ~= "2" and ZyXEL_Mode ~= "4" then
	local page  = node("expert", "configuration", "network", "wlan", "wlan_multissid")
	--page.target = template("expert_configuration/wlan_multissid")
	page.target = call("wlan_multissid")
	page.title  = "More AP"
	page.order  = 183

	local page  = node("expert", "configuration", "network", "wlan", "multissid_edit")
	--page.target = template("expert_configuration/multissid_edit")
	page.target = call("multiple_ssid")
	page.title  = "SSID Edit"
	page.order  = 185

end

if ZyXEL_Mode ~= "4" then
--[[
	local page  = node("expert", "configuration", "network", "wlan", "wlan_multissid")
	--page.target = template("expert_configuration/wlan_multissid")
	page.target = call("wlan_multissid")
	page.title  = "More AP"
	page.order  = 183

        local page  = node("expert", "configuration", "network", "wlan", "multissid_edit")
        --page.target = template("expert_configuration/multissid_edit")
        page.target = call("multiple_ssid")
        page.title  = "SSID Edit"
        page.order  = 185
]]--
	local page  = node("expert", "configuration", "network", "wlan", "wlanmacfilter")
	--[[page.target = template("expert_configuration/wlanmacfilter")]]--
	page.target = call("wlanmacfilter")
	page.title  = "MAC Filter"
	page.order  = 44

	local page  = node("expert", "configuration", "network", "wlan", "wlanadvanced")
	--[[page.target = template("expert_configuration/wlanadvanced")]]--
	page.target = call("wlan_advanced")
	page.title  = "Advanced"
	page.order  = 45

	local page  = node("expert", "configuration", "network", "wlan", "wlanqos")
	--[[page.target = template("expert_configuration/wlanqos")]]--
	page.target = call("wlan_qos")
	page.title  = "QoS"
	page.order  = 46

	local page  = node("expert", "configuration", "network", "wlan", "wlanwps")
	--[[page.target = template("expert_configuration/wlanwps")]]--
	page.target = call("wlan_wps")
	page.title  = "WPS"
	page.order  = 47

	local page  = node("expert", "configuration", "network", "wlan", "wlanwpsstation")
	--[[page.target = template("expert_configuration/wlanwpsstation")]]--
	page.target = call("wlanwpsstation")
	page.title  = "WPS Station"
	page.order  = 48

	local page  = node("expert", "configuration", "network", "wlan", "wlanscheduling")
	--[[page.target = template("expert_configuration/wlanscheduling")]]--
	page.target = call("wlanscheduling")
	page.title  = "Scheduling"
	page.order  = 48

	local page  = node("expert", "configuration", "network", "wlan", "wlanatf")
	page.target = call("wlanatf")
	page.title  = "Airtime Management"
	page.order  = 49

end

if ZyXEL_Mode ~= "1" and ZyXEL_Mode ~= "2" then
        --wireless client 2.4G 2012/06/25
	local page  = node("expert", "configuration", "network", "wlan", "wlan_apcli_wisp")
	page.target = call("wlan_apcli_wisp")
	page.title  = i18n.translate("universal_repeater")
	page.order  = 187

	local page  = node("expert", "configuration", "network", "wlan", "wlan_apcli_wisp_ur_site_survey")
	page.target = call("wlan_apcli_wisp_ur_site_survey")
	page.title  = i18n.translate("site_survey")
	page.order  = 188
        --wireless client 2.4G end
end
--[[end2.4G]]--

--check product_model
if Product_Model == "DUAL_BAND" then

--[[wireless 5G]]--
	local page  = node("expert", "configuration", "network", "wlan5G")
	--[[page.target = template("expert_configuration/wlan5G")	]]--
if ZyXEL_Mode ~= "4" then
	page.target = call("wlan_general_5G")
else
	page.target = call("wlan_apcli_wisp5G")
end
	page.title  = i18n.translate("Wireless_LAN_5_G")
	page.order  = 49

if ZyXEL_Mode ~= "4" then

        local page  = node("expert", "configuration", "network", "wlan", "wlan_multissid5G")
        --page.target = template("expert_configuration/wlan_multissid5G")
        page.target = call("wlan_multissid5G")
	page.title  = "More AP"
        page.order  = 84

        local page  = node("expert", "configuration", "network", "wlan", "multissid_edit5G")
        --page.target = template("expert_configuration/multissid_edit")
	page.target = call("multiple_ssid5G")
	page.title  = "SSID Edit"
	page.order  = 186

	local page  = node("expert", "configuration", "network", "wlan", "wlanmacfilter5G")
	--[[page.target = template("expert_configuration/wlanmacfilter5G")]]--
	page.target = call("wlanmacfilter_5G")
	page.title  = "MAC Filter"
	page.order  = 50

	local page  = node("expert", "configuration", "network", "wlan", "wlanadvanced5G")
	--[[page.target = template("expert_configuration/wlanadvanced5G")]]--
	page.target = call("wlan_advanced_5G")
	page.title  = "Advanced"
	page.order  = 51

	local page  = node("expert", "configuration", "network", "wlan", "wlanqos5G")
	--[[page.target = template("expert_configuration/wlanqos5G")]]--
	page.target = call("wlan_qos_5G")
	page.title  = "QoS"
	page.order  = 52

	-- local page  = node("expert", "configuration", "network", "wlan", "wlanwps5G")
	-- --[[page.target = template("expert_configuration/wlanwps5G")		]]--
	-- page.target = call("wlan_wps_5G")
	-- page.title  = "WPS"
	-- page.order  = 53

	local page  = node("expert", "configuration", "network", "wlan", "wlanwpsstation5G")
	--[[page.target = template("expert_configuration/wlanwpsstation5G")		]]--
	page.target = call("wlanwpsstation_5G")
	page.title  = "WPS Station"
	page.order  = 54

	local page  = node("expert", "configuration", "network", "wlan", "wlanscheduling5G")
	--[[page.target = template("expert_configuration/wlanscheduling5G")		]]--
	page.target = call("wlanscheduling_5G")
	page.title  = "Scheduling"
	page.order  = 55
end

if ZyXEL_Mode ~= "1" and ZyXEL_Mode ~= "2" then
        --wireless client 2.4G 2012/06/25
	local page  = node("expert", "configuration", "network", "wlan", "wlan_apcli_wisp5G")
	page.target = call("wlan_apcli_wisp5G")
	page.title  = i18n.translate("universal_repeater")
	page.order  = 189

	local page  = node("expert", "configuration", "network", "wlan", "wlan_apcli_wisp_ur_site_survey5G")
	page.target = call("wlan_apcli_wisp_ur_site_survey5G")
	page.title  = i18n.translate("site_survey")
	page.order  = 190
        --wireless client 2.4G end
end
--[[end5G]]--

end

	local page  = node("expert", "configuration", "network", "lan")
	page.target = call("action_lan")
	page.title  = i18n.translate("LAN")
	page.order  = 56

	local page  = node("expert", "configuration", "network", "menu_lan")
	page.target = call("action_menu_lan")
	page.title  = i18n.translate("LAN")
	page.order  = 561

	local page  = node("expert", "configuration", "network", "lan_ip")
	page.target = call("action_lan_ip")
	page.title  = i18n.translate("LAN")
	page.order  = 562

	local page  = node("expert", "configuration", "network", "lan", "ipalias")
	page.target = call("action_ipalias")
	page.title  = "IP Alias"
	page.order  = 57

	local page  = node("expert", "configuration", "network", "lan", "ipv6LAN")
	page.target = call("action_ipv6lan")
	page.title  = "IPv6 LAN"
	page.order  = 58
	--[[
	local page  = node("expert", "configuration", "network", "lan", "ipadv")
	page.target = template("expert_configuration/ip_advance")
	page.title  = "IP Advance"
	page.order  = 44
	]]--

if ZyXEL_Mode ~= "2" and ZyXEL_Mode ~= "3" then

	local page  = node("expert", "configuration", "network", "dhcpserver")
        page.target = call("action_dhcpSetup")
        page.title  = i18n.translate("DHCP_Server")
        page.order  = 58

        local page  = node("expert", "configuration", "network", "dhcpserver", "ipstatic")
        page.target = call("action_dhcpStatic")
        page.title  = "LAN_IPStatic"
        page.order  = 59

        local page  = node("expert", "configuration", "network", "dhcpserver", "dhcptbl")
        page.target = call("action_clientList")
        page.title  = "LAN_DHCPTbl_1"
        page.order  = 60

        local page  = node("expert", "configuration", "network", "dhcpserver", "dhcptable")
        page.target = call("action_clientList1")
        page.title  = "LAN_DHCPTable_1"
        page.order  = 601


	local page  = node("expert", "configuration", "network", "nat")
	page.target = call("nat")
	page.title  = i18n.translate("NAT")
	page.order  = 61

	local page  = node("expert", "configuration", "network", "nat", "portfw")
	page.target = call("action_portfw")
	page.title  = "Port Forwarding"
	page.order  = 62

	local page  = node("expert", "configuration", "network", "nat", "portfw","portfw_edit")
	page.target = call("action_portfw_edit")
	page.title  = "Port Forwarding Edit"
	page.order  = 63

	local page  = node("expert", "configuration", "network", "nat","nat_advance")
	page.target = call("port_trigger")
	page.title  = "NAT Advance"
	page.order  = 64

	local page  = node("expert", "configuration", "network", "nat", "passthrough")
	page.target = call("action_passthrough")
	page.title  = "Passthrough"
	page.order  = 611

	local page  = node("expert", "configuration", "network", "ddns")
	page.target = call("action_ddns")
	page.title  = i18n.translate("Dynamic_DNS")
	page.order  = 65

	local page  = node("expert", "configuration", "network", "static_route")
	page.target = call("action_static_route")
	page.title  = i18n.translate("Static_Route")
	page.order  = 66

	local page  = node("expert", "configuration", "security")
--	page.target = alias("expert", "configuration", "security", "firewall")
	page.target = call("action_security")
	page.title  = i18n.translate("Security")
	page.index = true
	page.order  = 67

	local page  = node("expert", "configuration", "security", "menu_security")
	page.target = call("action_menu_security")
	page.title  = i18n.translate("Security")
	page.ignoreindex = true
	page.order  = 671

	local page  = node("expert", "configuration", "security", "firewall")
	page.target = call("firewall")
	page.title  = i18n.translate("Firewall")
	page.ignoreindex = true
	page.order  = 68

	local page  = node("expert", "configuration", "security", "firewall", "fwsrv")
	page.target = call("fw_services")
	page.title  = "Firewall Service"
	page.order  = 69

--[[
	local page  = node("expert", "configuration", "security", "vpn")
	--page.target = template("expert_configuration/vpn")
	page.target = call("action_vpn")
	page.title  = i18n.translate("IPSec_VPN")
	page.order  = 70

	local page  = node("expert", "configuration", "security", "vpn", "vpn_edit")
	page.target = call("action_vpnEdit")
	page.title  = "IPSec VPN Edit"
	page.order  = 71

	local page  = node("expert", "configuration", "security", "vpn", "samonitor")
	--page.target = template("expert_configuration/samonitor")
	page.target = call("action_samonitor")
	page.title  = "SA Monitor"
	page.order  = 72
--]]

	local page  = node("expert", "configuration", "security", "ContentFilter")
	page.target = call("action_CF")
	page.title  = i18n.translate("Content_filter")
	page.order  = 73

	local page  = node("expert", "configuration", "security", "firewall6")
	page.target = call("firewall6")
	page.title  = i18n.translate("IPv6_firewall")
	page.order  = 74

	local page  = node("expert", "configuration", "security", "applications")
	page.target = call("action_applications")
	page.title  = "Applications"
	page.order  = 741

	local page  = node("expert", "configuration", "security", "menu_app")
	page.target = call("action_menu_app")
	page.title  = "Applications"
	page.order  = 742

	local page  = node("expert", "configuration", "security", "ParentalControl")
	page.target = call("parental_control")
	page.title  = i18n.translate("parental_control")
	page.order  = 74

	local page  = node("expert", "configuration", "security", "ParentalControl", "ParentalControl_Edit")
	page.target = call("parental_control_edit")
	page.title  = "Parental Control"
	page.order  = 75

	local page  = node("expert", "configuration", "security", "ParentalControl", "ParentalMonitor")
	page.target = call("parental_monitor")
	page.title  = i18n.translate("parental_monitor")
	page.order  = 79

	local page  = node("expert", "configuration", "security", "ParentalControl", "ParentalMonitor_Edit")
	page.target = call("parental_monitor_edit")
	page.title  = i18n.translate("parental_monitor_edit")
	page.order  = 80

--[[
	local page  = node("expert", "configuration", "usb")
	page.target = template("expert_configuration/3g_connection")
	page.title  = "USB Service"
	page.order  = 73

	local page  = node("expert", "configuration", "powersave")
	page.target = template("expert_configuration/powersaving")
	page.title  = "Power Saving"
	page.order  = 74
]]--

if streamboost_status == "NotSupport" then

	local page  = node("expert", "configuration", "management")
	page.target = alias("expert", "configuration", "management", "qos")
	page.title  = i18n.translate("Management")
	page.index = true
	page.order  = 75

	local page  = node("expert", "configuration", "management", "qos")
	page.target = alias("expert", "configuration", "management", "qos", "general")
	page.title  = i18n.translate("Bandwidth_MGMT")
	page.order  = 76

	local page  = node("expert", "configuration", "management", "qos", "general")
	page.target = call("action_qos")
	page.title  = "QoS General"
	page.order  = 77

	local page  = node("expert", "configuration", "management", "qos", "advance")
	page.target = call("action_qos_adv")
	page.title  = "QoS Advance"
	page.order  = 78

	local page  = node("expert", "configuration", "management", "qos", "AppEdit")
	page.target = call("action_qos_AppEdit")
	page.title  = "QoS Advance"
	page.order  = 79
	
	local page  = node("expert", "configuration", "management", "qos", "CfgEdit")
	page.target = call("action_qos_CfgEdit")
	page.title  = "QoS Advance"
	page.order  = 80

--[[
	local page  = node("expert", "configuration", "management", "qos", "monitor")
	page.target = template("expert_configuration/qos_monitor")
	page.title  = "QoS Monitor"
	page.order  = 79
--]]

else

	local page  = node("expert", "configuration", "management")
	page.target = alias("expert", "configuration", "management", "streamboost")
	page.title  = i18n.translate("Management")
	page.index = true
	page.order  = 81

	local page  = node("expert", "configuration", "management", "streamboost")
	page.target = alias("expert", "configuration", "management", "streamboost", "streamboost_fxbandwidth")
	page.title  = i18n.translate("StreamBoost_MGMT")
	page.order  = 82

	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_fxbandwidth")
	page.target = call("streamboost_fxbandwidth")
	page.title  = "Streamboost Bandwidth"
	page.order  = 82

	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_fxnetwork")
	page.target = template("expert_configuration/streamboost_fxnetwork")
	page.title  = "Streamboost Network"
	page.order  = 83

	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_fxpriority")
	page.target = template("expert_configuration/streamboost_fxpriority")
	page.title  = "Streamboost Priorities"
	page.order  = 84

	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_UsageMonitor")
	page.target = template("expert_configuration/streamboost_UsageMonitor")
	page.title  = i18n.translate("Usage_Monitor")
	page.order  = 84

	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_fxtopbytime")
	page.target = template("expert_configuration/streamboost_fxtopbytime")
	page.title  = "Streamboost Up Time"
	page.order  = 85

	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_fxtopbydl")
	page.target = template("expert_configuration/streamboost_fxtopbydl")
	page.title  = "Streamboost Download"
	page.order  = 86

	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_fxallevents")
	page.target = template("expert_configuration/streamboost_fxallevents")
	page.title  = "Streamboost All Events"
	page.order  = 87

	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_fxnode")
	page.target = template("expert_configuration/streamboost_fxnode")
	page.title  = "Streamboost node"
	page.order  = 87

	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_fxabout")
	page.target = template("expert_configuration/streamboost_fxabout")
	page.title  = "About Streamboost"
	page.order  = 87

	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_fxperdevice")
	page.target = template("expert_configuration/streamboost_fxperdevice")
	page.title  = "Streamboost Per Device"
	page.order  = 88

	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_fxdevicedetail")
	page.target = template("expert_configuration/streamboost_fxdevicedetail")
	page.title  = "Streamboost Device Detail"
	page.order  = 88

	local page  = node("expert", "configuration", "management", "streamboost", "streamboost_fxperflow")
	page.target = template("expert_configuration/streamboost_fxperflow")
	page.title  = "Streamboost Per Flow"
	page.order  = 89

end

	local page  = node("expert", "configuration", "management", "remote")
	page.target = call("action_remote_www")
	page.title  = i18n.translate("Remote_MGMT")
	page.ignoreindex = true
	page.order  = 90

	local page  = node("expert", "configuration", "management", "remote", "telnet")
	page.target = call("action_remote_telnet")
	page.title  = "Remote MGMT Telnet"
	page.order  = 91

	local page  = node("expert", "configuration", "management", "remote", "wol")
	page.target = call("action_wol")
	page.title  = "Wake On LAN"
	page.order  = 93

	local page  = node("expert", "configuration", "management", "upnp")
	page.target = call("action_upnp")
	page.title  = i18n.translate("UPnP")
	page.order  = 94

	local page  = node("expert", "configuration", "management", "media_sharing")
	page.target = alias("expert", "configuration", "management", "media_sharing", "dlna")
	page.title  = i18n.translate("Media")
	page.index = true
	page.order  = 96

	local page  = node("expert", "configuration", "management", "media_sharing", "dlna")
	page.target = call("action_dlna")
	page.title  = i18n.translate("DLNA")
	page.order  = 97

	local page  = node("expert", "configuration", "management", "media_sharing", "samba")
	page.target = call("action_samba")
	page.title  = i18n.translate("SAMBA")
	page.order  = 98

	local page  = node("expert", "configuration", "management", "media_sharing", "ftp")
	page.target = call("action_ftp")
	page.title  = i18n.translate("FTP")
	page.order  = 99

	local page  = node("expert", "configuration", "management", "oneconnect")
	page.target = call("action_oneconnect")
	page.title  = i18n.translate("oneconnect")
	page.order  = 99

	local page  = node("expert", "configuration", "management", "send_mail")
	page.target = alias("expert", "configuration", "management", "send_mail", "mail")
	page.title  = i18n.translate("Mail")
	page.index = true
	page.order  = 100

	local page  = node("expert", "configuration", "management", "send_mail", "mail")
	page.target = call("action_mail")
	page.title  = i18n.translate("myMail")
	page.order  = 101

	local page  = node("expert", "configuration", "management", "send_mail", "mail_edit")
	page.target = call("action_mail_edit")
	page.title  = i18n.translate("Mail Edit")
	page.order  = 102



else


	local page  = node("expert", "configuration", "management")
	page.target = alias("expert", "configuration", "management", "media_sharing")
	page.title  = i18n.translate("Management")
	page.index = true
	page.order  = 92

	local page  = node("expert", "configuration", "management", "media_sharing")
	page.target = alias("expert", "configuration", "management", "media_sharing", "dlna")
	page.title  = i18n.translate("Media")
	page.index = true
	page.order  = 92

	local page  = node("expert", "configuration", "management", "media_sharing", "dlna")
	page.target = call("action_dlna")
	page.title  = i18n.translate("DLNA")
	page.order  = 93

	local page  = node("expert", "configuration", "management", "upnp")
	page.target = call("action_upnp")
	page.title  = i18n.translate("UPnP")
	page.order  = 931

	local page  = node("expert", "configuration", "management", "media_sharing", "samba")
	page.target = call("action_samba")
	page.title  = i18n.translate("SAMBA")
	page.order  = 94

	local page  = node("expert", "configuration", "management", "media_sharing", "ftp")
	page.target = call("action_ftp")
	page.title  = i18n.translate("FTP")
	page.order  = 95

	local page  = node("expert", "configuration", "management", "oneconnect")
	page.target = call("action_oneconnect")
	page.title  = i18n.translate("oneconnect")
	page.order  = 96

	local page  = node("expert", "configuration", "security")
--	page.target = alias("expert", "configuration", "security", "firewall")
	page.target = call("action_security")
	page.title  = i18n.translate("Security")
	page.index = true
	page.order  = 67

	local page  = node("expert", "configuration", "security", "applications")
	page.target = call("action_applications")
	page.title  = "Applications"
	page.order  = 70

	local page  = node("expert", "configuration", "security", "menu_app")
	page.target = call("action_menu_app")
	page.title  = "Applications"
	page.order  = 75

end

end

function action_mode_ex()

        luci.template.render("expert_configuration/mode_ex")
end

function action_menubar()

        luci.template.render("expert_configuration/menubar")
end

function action_wan()

    luci.template.render("expert_configuration/wan")
end

function action_menu_wan()

        luci.template.render("expert_configuration/menu_wan")
end

function action_wan_internet_connection()
    local apply = luci.http.formvalue("apply")

    if apply then

		-- lock dns check, and it will be unlock after updating dns in update_sys_dns
		sys.exec("echo 1 > /var/update_dns_lock")
		local wan_proto = uci:get("network","wan","proto")
		sys.exec("echo "..wan_proto.." > /tmp/old_wan_proto")

		local connection_type = luci.http.formvalue("connectionType")
		local connection_IPmode = luci.http.formvalue("IP_Mode")

		--Add For IPv6Tunning
		local ipv6Tunneling = luci.http.formvalue("IPv6_Tunneling")
		--Add FOR 6RD
		local auto_6rd = luci.http.formvalue("auto_6rd")
		local zy6rd6prefix = luci.http.formvalue("zy6rd6prefix")
		local zy6rd4ip= luci.http.formvalue("zy6rd4ip")
		local zy6rdCkWan = luci.http.formvalue("WAN_IP_Auto")
		local zy6rdWanStaticIp = luci.http.formvalue("staticIp")

		local zy6rd6prefixleng = luci.http.formvalue("zy6rd6prefixleng")
		local zy6rd4prefixleng = luci.http.formvalue("zy6rd4prefixleng")
		local Server_dnsv6_1Type       = luci.http.formvalue("dnsv6_1Type")
		local Server_staticPriDnsv6   = luci.http.formvalue("staticPriDnsv6")
		local Server_dnsv6_2Type       = luci.http.formvalue("dnsv6_2Type")
		local Server_staticSecDnsv6   = luci.http.formvalue("staticSecDnsv6")
		local Server_dnsv6_3Type       = luci.http.formvalue("dnsv6_3Type")
		local Server_staticThiDnsv6   = luci.http.formvalue("staticThiDnsv6")
		--[[Support ipv6 DNS
		local zy6rd_PriDnsv6 = luci.http.formvalue("zy6rd_PriDnsv6")
		local zy6rd_SecDnsv6 = luci.http.formvalue("zy6rd_SecDnsv6")
		local zy6rd_ThiDnsv6 = luci.http.formvalue("zy6rd_ThiDnsv6")

		if not zy6rd_PriDnsv6 then
			zy6rd_PriDnsv6 = ""
		end
		if not zy6rd_SecDnsv6 then
			zy6rd_SecDnsv6 = ""
		end
		if not zy6rd_ThiDnsv6 then
			zy6rd_ThiDnsv6 = ""
		end
		]]--
		if not zy6rd6prefixleng then
			zy6rd6prefixleng = 32
		end
		if not zy6rd4prefixleng then
			zy6rd4prefixleng = 0
		end

		-- write USER defined DNS addr. into  network.uci  .
		if Server_dnsv6_1Type~="USER" or Server_staticPriDnsv6 == "::/0" or not Server_staticPriDnsv6 then
			Server_staticPriDnsv6=""
		end

		if Server_dnsv6_2Type~="USER" or Server_staticSecDnsv6 == "::/0" or not Server_staticSecDnsv6 then
			Server_staticSecDnsv6=""
		end

		if Server_dnsv6_3Type~="USER" or Server_staticThiDnsv6 == "::/0" or not Server_staticThiDnsv6 then
			Server_staticThiDnsv6=""
		end

		if connection_IPmode == "IPv4_Only" then

			if ipv6Tunneling == "IPv6_6RD" then
				uci:delete("network","wan6rd")
				uci:delete("network","wan6rdS")
				if 	uci:get("network","wan","wan6rd_enable")~="1" then
					uci:set("network","general", "dhcpv6pd", "1")
					uci:set("network","general","v6lanstatic","0")
					uci:set("network","general","linkLocalOnly","0")
					uci:set("network","general","ULA","0")
				end
				uci:set("network", "wan6rd", "interface")
				uci:set("network", "wan6rd", "proto", "6rd")
				uci:set("network", "general", "wan6rd_enable", 1)
				uci:set("network", "general", "dhcpv6pd", "1")
				uci:set("network", "wan", "iface6rd", "")
				uci:set("network", "wan", "reqopts", "")
				--Support ipv6 DNS
				uci:set("network", "wan6rd", "PriDns", Server_staticPriDnsv6)
				uci:set("network", "wan6rd", "SecDns", Server_staticSecDnsv6)
				uci:set("network", "wan6rd", "ThiDns", Server_staticThiDnsv6)

				if connection_type == "PPPOE" then
					zy6rdCkWan = "0" --For pppoe check
				end

				--WAN DHCP
				if zy6rdCkWan == "1" then
					--6RD DHCP
					if auto_6rd == "auto" then
						uci:set("network", "wan", "iface6rd", "wan6rd")
						uci:set("network", "wan", "reqopts", "212")
					--6RD Static
					else
						uci:set("network", "wan6rd", "peeraddr", zy6rd4ip)
						uci:set("network", "wan6rd", "ip6prefix", zy6rd6prefix)
						uci:set("network", "wan6rd", "ip6prefixlen", zy6rd6prefixleng)
						uci:set("network", "wan6rd", "ip4prefixlen", zy6rd4prefixleng)
					end

				elseif zy6rdCkWan == "0" then

					if auto_6rd == "auto" then
						uci:set("network", "wan", "iface6rd", "wan6rd")
						uci:set("network", "wan", "reqopts", "212")
					else
						uci:set("network", "wan6rd", "peeraddr", zy6rd4ip)
						uci:set("network", "wan6rd", "ip6prefix", zy6rd6prefix)
						uci:set("network", "wan6rd", "ip6prefixlen", zy6rd6prefixleng)
						uci:set("network", "wan6rd", "ip4prefixlen", zy6rd4prefixleng)
					end
				--WANStatic
				else
					--6RD DHCP
					if auto_6rd == "auto" then
						uci:set("network", "wan", "iface6rd", "wan6rd")
						uci:set("network", "wan6rdS", "interface")
						uci:set("network", "wan6rdS", "ifname", "eth0")
						uci:set("network", "wan6rdS", "proto", "dhcp")
						uci:set("network", "wan6rdS", "iface6rd", "wan6rd")
						uci:set("network", "wan6rdS", "reqopts", "212")
					--6RD Static
					else
						uci:set("network", "wan", "iface6rd", "")
						uci:set("network", "wan6rd", "peeraddr", zy6rd4ip)
						uci:set("network", "wan6rd", "ip6prefix", zy6rd6prefix)
						uci:set("network", "wan6rd", "ip6prefixlen", zy6rd6prefixleng)
						uci:set("network", "wan6rd", "ip4prefixlen", zy6rd4prefixleng)
						uci:set("network", "wan6rd", "ipaddr", zy6rdWanStaticIp)
					end
				end
			else
				uci:set("network", "general", "wan6rd_enable", 0)
			end
		--Add FOR 6RD

		--Add FOR 6to4
			local zy6to4ip= luci.http.formvalue("zy6to4ip")
			--[[Support ipv6 DNS
			local zy6to4_PriDnsv6 = luci.http.formvalue("zy6to4_PriDnsv6")
			local zy6to4_SecDnsv6 = luci.http.formvalue("zy6to4_SecDnsv6")
			local zy6to4_ThiDnsv6 = luci.http.formvalue("zy6to4_ThiDnsv6")
			if not zy6to4_PriDnsv6 then
				zy6to4_PriDnsv6 = ""
			end
			if not zy6to4_SecDnsv6 then
				zy6to4_SecDnsv6 = ""
			end
			if not zy6to4_ThiDnsv6 then
				zy6to4_ThiDnsv6 = ""
			end]]--

			if ipv6Tunneling == "IPv6_6to4" then
				if 	uci:get("network","wan","wan6to4_enable")~="1" then
					uci:set("network","general", "dhcpv6pd", "1")
					uci:set("network","general","v6lanstatic","0")
					uci:set("network","general","linkLocalOnly","0")
					uci:set("network","general","ULA","0")
				end
				uci:set("network", "general", "wan6to4_enable", "1")
				uci:set("network", "general", "dhcpv6pd", "1")
				--Support ipv6 DNS
				uci:set("network", "wan6to4", "PriDns", Server_staticPriDnsv6)
				uci:set("network", "wan6to4", "SecDns", Server_staticSecDnsv6)
				uci:set("network", "wan6to4", "ThiDns", Server_staticThiDnsv6)
			else
				uci:set("network", "general", "wan6to4_enable", "0")
			end

			uci:set("network", "wan6to4", "interface")
			uci:set("network", "wan6to4", "proto", "6to4")

			if not zy6to4ip or zy6to4ip == "" then
				zy6to4ip = "192.88.99.1"
			end
			uci:set("network", "wan6to4", "relayaddr", zy6to4ip)
		--Add FOR 6to4

		--Add FOR 6in4
			local zy6in4_rtv4= luci.http.formvalue("zy6in4_rtv4")
			local zy6in4_rtv6= luci.http.formvalue("zy6in4_rtv6")
			local zy6in4_lov6= luci.http.formvalue("zy6in4_lov6")
			local zy6in4_v6pfx= luci.http.formvalue("zy6in4_v6pfx")

			--Support ipv6 DNS
			--[[local zy6in4_PriDnsv6 = luci.http.formvalue("zy6in4_PriDnsv6")
			local zy6in4_SecDnsv6 = luci.http.formvalue("zy6in4_SecDnsv6")
			local zy6in4_ThiDnsv6 = luci.http.formvalue("zy6in4_ThiDnsv6")
			if not zy6in4_PriDnsv6 then
				zy6in4_PriDnsv6 = ""
			end
			if not zy6in4_SecDnsv6 then
				zy6in4_SecDnsv6 = ""
			end
			if not zy6in4_ThiDnsv6 then
				zy6in4_ThiDnsv6 = ""
			end]]--

			if ipv6Tunneling == "IPv6_6in4" then
				if 	uci:get("network","wan","wan6in4_enable")~="1" then
					uci:set("network","general", "dhcpv6pd", "1")
					uci:set("network","general","v6lanstatic","0")
					uci:set("network","general","linkLocalOnly","0")
					uci:set("network","general","ULA","0")
				end
				uci:set("network", "general", "wan6in4_enable", "1")
				uci:set("network", "general", "dhcpv6pd", "1")
				--Support ipv6 DNS
				uci:set("network", "wan6in4", "PriDns", Server_staticPriDnsv6)
				uci:set("network", "wan6in4", "SecDns", Server_staticSecDnsv6)
				uci:set("network", "wan6in4", "ThiDns", Server_staticThiDnsv6)
			else
				uci:set("network", "general", "wan6in4_enable", "0")
			end

			uci:set("network", "wan6in4", "interface")
			uci:set("network", "wan6in4", "proto", "6in4")

			if not zy6in4_rtv4 then
				zy6in4_rtv4 = ""
			end
			if not zy6in4_rtv6 then
				zy6in4_rtv6 = ""
			end
			if not zy6in4_lov6 then
				zy6in4_lov6= ""
			end
			if not zy6in4_v6pfx then
				zy6in4_v6pfx= ""
			end

			uci:set("network", "wan6in4", "peeraddr", zy6in4_rtv4)
			uci:set("network", "wan6in4", "ipv6peeraddr", zy6in4_rtv6)
			uci:set("network", "wan6in4", "ip6addr", zy6in4_lov6)
			uci:set("network", "wan6in4", "ip6prefix", zy6in4_v6pfx)
		--Add FOR 6in4

		else
			uci:set("network", "general", "wan6rd_enable", 0)
			uci:set("network", "general", "wan6to4_enable", 0)
			uci:set("network", "general", "wan6in4_enable", 0)
		end

		-- DNSv4
		local Server_dns1Type       = luci.http.formvalue("dns1Type")
		local Server_staticPriDns   = luci.http.formvalue("staticPriDns")
		local Server_dns2Type       = luci.http.formvalue("dns2Type")
		local Server_staticSecDns   = luci.http.formvalue("staticSecDns")
		local Server_dns3Type       = luci.http.formvalue("dns3Type")
		local Server_staticThiDns   = luci.http.formvalue("staticThiDns")

		if Server_dns1Type~="USER" or Server_staticPriDns == "0.0.0.0" or not Server_staticPriDns then
			Server_staticPriDns=""
		end

		if Server_dns2Type~="USER" or Server_staticSecDns == "0.0.0.0" or not Server_staticSecDns then
			Server_staticSecDns=""
		end

		if Server_dns3Type~="USER" or Server_staticThiDns == "0.0.0.0" or not Server_staticThiDns then
			Server_staticThiDns=""
		end

		uci:set("network","wan","dns1",Server_dns1Type ..",".. Server_staticPriDns)
		uci:set("network","wan","dns2",Server_dns2Type ..",".. Server_staticSecDns)
		uci:set("network","wan","dns3",Server_dns3Type ..",".. Server_staticThiDns)

		--[[ DNSv6
		local Server_dnsv6_1Type       = luci.http.formvalue("dnsv6_1Type")
		local Server_staticPriDnsv6   = luci.http.formvalue("staticPriDnsv6")
		local Server_dnsv6_2Type       = luci.http.formvalue("dnsv6_2Type")
		local Server_staticSecDnsv6   = luci.http.formvalue("staticSecDnsv6")
		local Server_dnsv6_3Type       = luci.http.formvalue("dnsv6_3Type")
		local Server_staticThiDnsv6   = luci.http.formvalue("staticThiDnsv6")
		]]--
		-- write DNSv6 server address into  dhcp6s.uci  , no matter it is ISP/USER defined.
		uci:set("dhcp6s","basic","domain_name_server1","")
		uci:set("dhcp6s","basic","domain_name_server2","")
		uci:set("dhcp6s","basic","domain_name_server3","")

		if Server_staticPriDnsv6 == nil then
			Server_staticPriDnsv6 = ""
		end

		if Server_staticSecDnsv6 == nil then
			Server_staticSecDnsv6 = ""
		end

		if Server_staticThiDnsv6 == nil then
			Server_staticThiDnsv6 = ""
		end

		if Server_staticPriDnsv6 ~= "" then
			uci:set("dhcp6s","basic","domain_name_server1", Server_staticPriDnsv6)

			if Server_staticSecDnsv6 ~= "" and Server_staticSecDnsv6 ~= Server_staticPriDnsv6 then
				uci:set("dhcp6s","basic","domain_name_server2", Server_staticSecDnsv6)
			end

			if Server_staticThiDnsv6 ~= "" and Server_staticThiDnsv6 ~= Server_staticPriDnsv6 and Server_staticThiDnsv6 ~= Server_staticSecDnsv6 then
				uci:set("dhcp6s","basic","domain_name_server3", Server_staticThiDnsv6)
			end
		end

		if connection_IPmode == "IPv4_Only" then
			if ipv6Tunneling == "None" then
				uci:set("dhcp6s","basic","enabled", "0")
			else
				uci:set("dhcp6s","basic","enabled", "1")
			end
		else
			uci:set("dhcp6s","basic","enabled", "1")
		end
		uci:commit("radvd")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:commit("dhcp6s")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem

		if connection_IPmode ~= "IPv4_Only" then
			uci:set("network","wan","dnsv6_1",Server_dnsv6_1Type ..",".. Server_staticPriDnsv6)
			uci:set("network","wan","dnsv6_2",Server_dnsv6_2Type ..",".. Server_staticSecDnsv6)
			uci:set("network","wan","dnsv6_3",Server_dnsv6_3Type ..",".. Server_staticThiDnsv6)
		end

	    --WenHsien -- set IPmode into UCI
		if connection_IPmode == "IPv4_Only" then
			uci:set("network","wan","ipv4","1")
			uci:set("network","wan","ipv6","0")
			uci:set("network","wan","ipv6Enable","0")
			uci:set("network","general","linkLocalOnly","0")
			uci:set("network","wan","IP_version","IPv4_Only")
		elseif connection_IPmode == "Dual_Stack" then
			if 	uci:get("network","wan","ipv6Enable")=="0" then
				uci:set("network","general", "dhcpv6pd", "1")
				uci:set("network","general","v6lanstatic","0")
				uci:set("network","general","linkLocalOnly","0")
				uci:set("network","general","ULA","0")
			end
			uci:set("network","wan","ipv4","1")
			uci:set("network","wan","ipv6","1")
			uci:set("network","wan","ipv6Enable","1")
			uci:set("network","wan","IP_version","Dual_Stack")
		else
			if 	uci:get("network","wan","ipv6Enable")=="0" then
				uci:set("network","general", "dhcpv6pd", "1")
				uci:set("network","general","v6lanstatic","0")
				uci:set("network","general","linkLocalOnly","0")
				uci:set("network","general","ULA","0")
			end
			uci:set("network","wan","ipv4","0")
			uci:set("network","wan","ipv6","1")
			uci:set("network","wan","ipv6Enable","1")
			uci:set("network","wan","IP_version","IPv6_Only")
		end

		-- PPPoE
        if connection_type == "PPPOE" then
			uci:set("network","wan","v6_proto","pppoe")

			local ipv6=uci:get("network","wan","ipv6")
			if ipv6=="1" then
				local IPv6_WAN_IP_Auto = luci.http.formvalue("auto_address")
				local duidmode = luci.http.formvalue("dhcpv6_autoaddr_duidmode")
				if 	uci:get("network","wan","ipv6Enable")=="0" then
					uci:set("network","general", "dhcpv6pd", "1")
					uci:set("network","general","v6lanstatic","0")
					uci:set("network","general","linkLocalOnly","0")
					uci:set("network","general","ULA","0")
				end
				uci:set("dhcp6c","basic","duid_mode", duidmode)
				uci:set("network","wan","send_rs","0")
				uci:set("network","wan","accept_ra","1")
				uci:set("dhcp6c","basic","ifname","pppoe-wan")
				uci:set("dhcp6c","basic","interface","wan")
				if IPv6_WAN_IP_Auto == "linkLocal_only" then
					uci:set("network","wan","ipv6","0")
					uci:set("network","general","linkLocalOnly","1")
                end
				uci:commit("dhcp6c")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			end


			local pppoeUser = luci.http.formvalue("pppoeUser")
			local pppoePass = luci.http.formvalue("pppoePass")
			local pppoeMTU = luci.http.formvalue("pppoeMTU")
			local pppoeNailedup = luci.http.formvalue("pppoeNailedup")
			local pppoeIdleTime = luci.http.formvalue("pppoeIdleTime")
			local pppoeServiceName = luci.http.formvalue("pppoeServiceName")
			--local pppoePassthrough = luci.http.formvalue("pppoePassthrough")
			local pppoeWanIpAddr = luci.http.formvalue("pppoeWanIpAddr")

			if pppoeNailedup~="1" then
				pppoeNailedup=0
			end

			if not pppoeIdleTime then
				pppoeIdleTime=""
			end
			--[[
			if pppoePassthrough~="1" then
				pppoePassthrough=0
			end
			]]--

			if not pppoeWanIpAddr then
				pppoeWanIpAddr=""
			end

			uci:set("network","wan","proto","pppoe")
			uci:set("network","wan","username",pppoeUser)
			uci:set("network","wan","password",pppoePass)
			uci:set("network","wan","pppoe_mtu",pppoeMTU)
			uci:set("network","wan","mtu",pppoeMTU)
			uci:set("network","wan","pppoeNailedup",pppoeNailedup)
			uci:set("network","wan","demand",pppoeIdleTime)
			uci:set("network","wan","service",pppoeServiceName)
			--uci:set("network","wan","pppoePassthrough",pppoePassthrough)
			uci:set("network","wan","pppoeWanIpAddr",pppoeWanIpAddr)
			uci:set("network","wan","ip6addr","")
			uci:set("network","wan","prefixlen","")
			uci:set("network","wan","ip6gw","")
			uci:set("network","wan","IPv6_dns","")
			--uci:set("network","wan","pppoev6_dns",pppoeipv6dns)
			--if not pppoeipv6dns then
			--sys.exec("echo nameserver "..pppoeipv6dns.." >> /tmp/resolv.conf.auto")
			--end
			--[[
			uci:delete("network","wan","ipaddr")
			uci:delete("network","wan","netmask")
			uci:delete("network","wan","gateway")
			]]--

		elseif connection_type == "PPTP" then

			local pptpUser = luci.http.formvalue("pptpUser")
			local pptpPass = luci.http.formvalue("pptpPass")
			local pptpMTU = luci.http.formvalue("pptpMTU")
			local pptpNailedup = luci.http.formvalue("pptpNailedup")
			local pptpIdleTime = luci.http.formvalue("pptpIdleTime")
			local pptp_serverIp = luci.http.formvalue("pptp_serverIp")
			local pptpWanIpAddr = luci.http.formvalue("pptpWanIpAddr")
			local pptp_config_ip = luci.http.formvalue("pptp_config_ip")
			local pptp_staticIp = luci.http.formvalue("pptp_staticIp")
			local pptp_staticNetmask = luci.http.formvalue("pptp_staticNetmask")
			local pptp_staticGateway = luci.http.formvalue("pptp_staticGateway")
			local pptpWanIPMode = luci.http.formvalue("pptpWanIPMode")
			local PPTPEncryptionType = luci.http.formvalue("PPTPEncryptionType")

			if pptpNailedup~="1" then
				pptpNailedup=0
			end

			if not pptpIdleTime then
				pptpIdleTime=""
			end

			if not pptpWanIpAddr then
				pptpWanIpAddr=""
			end
            uci:set("network","wan","proto","pptp")
						uci:set("network","wan","v6_proto","pptp")
			uci:set("network","vpn","interface")
						uci:set("network","wan","IP_version","IPv4_Only")

			if pptp_config_ip == "1" then
				uci:set("network","vpn","proto","dhcp")
            else
				uci:set("network","vpn","proto","static")
				uci:set("network","wan","ipaddr",pptp_staticIp)
				uci:set("network","wan","netmask",pptp_staticNetmask)
				uci:set("network","wan","gateway",pptp_staticGateway)
            end

            uci:set("network","vpn","pptp_username",pptpUser)
            uci:set("network","vpn","pptp_password",pptpPass)
			uci:set("network","wan","pptp_mtu",pptpMTU)
			uci:set("network","wan","mtu",pptpMTU)
			uci:set("network","vpn","pptp_Nailedup",pptpNailedup)
			uci:set("network","vpn","pptp_demand",pptpIdleTime)
			uci:set("network","vpn","pptp_serverip",pptp_serverIp)
			uci:set("network","vpn","pptpWanIPMode",pptpWanIPMode)
			uci:set("network","vpn","pptpWanIpAddr",pptpWanIpAddr)
			uci:set("network","vpn","pptp_Encryption",PPTPEncryptionType)

		-- IPoE
		else
			-- IPoE/ v4
			uci:set("network","wan","v6_proto","dhcp")
            if (connection_IPmode == "IPv4_Only") or (connection_IPmode == "Dual_Stack") then
				local WAN_IP_Auto = luci.http.formvalue("WAN_IP_Auto")
				local Fixed_staticIp = luci.http.formvalue("staticIp")
				local Fixed_staticNetmask = luci.http.formvalue("staticNetmask")
				local Fixed_staticGateway = luci.http.formvalue("staticGateway")
				local ethMTU = luci.http.formvalue("ethMTU")

				-- IPoE/ v4/ DHCP
				if WAN_IP_Auto == "1" then
					local vendor_id = luci.http.formvalue("vendor_id")
					local dhcp121Enable  = luci.http.formvalue("dhcp121Enable")
					local dhcp125Enable  = luci.http.formvalue("dhcp125Enable")
					local dhcp60Enable = luci.http.formvalue("dhcp60Enable")
					uci:set("network","wan","proto","dhcp")
					uci:set("dhcp","lan","enabled","1")

					if not ( nil == vendor_id ) then
					  uci:set("network", "wan", "vendorid", vendor_id)
					else
					  uci:set("network", "wan", "vendorid", "")
					end

					if not ("0" == dhcp121Enable ) then
					  uci:set("network", "wan", "dhcp121", 0)
					else
					  uci:set("network", "wan", "dhcp121", 1)
					end

					if not ("0" == dhcp125Enable ) then
					  uci:set("network", "wan", "dhcp125", 0)
					else
					  uci:set("network", "wan", "dhcp125", 1)
					end

					if not ("0" == dhcp60Enable ) then
					  uci:set("network", "wan", "dhcp60", 0)
					else
					  uci:set("network", "wan", "dhcp60", 1)
					end

				-- IPoE/ v4/ STATIC
				else
					uci:set("network","wan","proto","static")
					uci:set("network","wan","ipaddr",Fixed_staticIp)
					uci:set("network","wan","netmask",Fixed_staticNetmask)
					uci:set("network","wan","gateway",Fixed_staticGateway)
				end
				uci:set("network","wan","eth_mtu",ethMTU)
				uci:set("network","wan","mtu",ethMTU)
				--[[
				uci:delete("network","wan","username")
				uci:delete("network","wan","password")
				uci:delete("network","wan","pppoeNailedup")
				uci:delete("network","wan","pppoeIdleTime")
				uci:delete("network","wan","pppoeServiceName")
				uci:delete("network","wan","pppoePassthrough")
				]]--
			end

			-- IPoE/ v6
			if (connection_IPmode == "IPv6_Only") or (connection_IPmode == "Dual_Stack") then
				local IPv6_WAN_IP_Auto = luci.http.formvalue("auto_address")
				local duidmode = luci.http.formvalue("dhcpv6_autoaddr_duidmode")
				local IPv6_Fixed_StaticIp = luci.http.formvalue("ipv6_address")
				local IPv6_Prefix_Length = luci.http.formvalue("prefix_length")
				local IPv6_Fixed_StaticGateway = luci.http.formvalue("ipv6_gateway")
				--local IPv6_DNS = luci.http.formvalue("ipv6_dns")
				--local IA_NA = luci.http.formvalue("ia_na")
				--local IA_PD = luci.http.formvalue("ia_pd")
				local request_v6_dns = luci.http.formvalue("auto_dns")
				local ethMTU = luci.http.formvalue("ethMTU")

				--uci:apply("RA_status")
				--uci:set("network6","wan","type", "ipoev6")
				uci:set("network","wan","send_rs","0")
				uci:set("network","wan","accept_ra","1")
				--uci:commit("network")
				--uci:apply("network")

				uci:set("dhcp6c","basic","ifname","eth0")
				uci:set("dhcp6c","basic","interface","wan")
				uci:commit("dhcp6c")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				--uci:apply("dhcp6c")

				-- IPoE/ v6/ DHCP
				if IPv6_WAN_IP_Auto == "auto" then
					uci:set("network","wan","v6_proto","dhcp")
					uci:set("network","wan","ip6addr","")
					uci:set("network","wan","prefixlen","")
					uci:set("network","wan","ip6gw","")
                    uci:set("network","wan","IPv6_dns","")

					--uci:set("network6","wan","type","dhcp")
					uci:set("dhcp6c","basic","enabled", 1)

					local Server_dns1Type       = luci.http.formvalue("dns1Type")
					local Server_staticPriDns   = luci.http.formvalue("staticPriDns")
					local Server_dns2Type       = luci.http.formvalue("dns2Type")
					local Server_staticSecDns   = luci.http.formvalue("staticSecDns")
					local Server_dns3Type       = luci.http.formvalue("dns3Type")
					local Server_staticThiDns   = luci.http.formvalue("staticThiDns")
					--[[ if IA_NA then
						IA_NA=1
					else
						IA_NA=0
					end
					if IA_PD then
						IA_PD=1
					else
						IA_PD=0
					end ]]--
					--uci:set("dhcp6c","basic","na", IA_NA)
					--uci:set("dhcp6c","basic","pd", IA_PD)
					uci:set("dhcp6c","lan","enabled", 1)
					uci:set("dhcp6c","lan","sla_id", 0)
					uci:set("dhcp6c","lan","sla_len", 0)
					uci:set("dhcp6c","basic","gui_run","1")
					uci:set("dhcp6c","basic","duid_mode", duidmode)
					uci:set("network","wan","ipv6","1")
					uci:set("network","general","linkLocalOnly","0")
				-- IPoE/ v6/ STATIC
                elseif IPv6_WAN_IP_Auto == "static" then
					uci:set("network","wan","v6_proto","static")
					uci:set("network","wan","v6_static","1")
					uci:set("network","wan","ip6addr",IPv6_Fixed_StaticIp)
					uci:set("network","wan","prefixlen",IPv6_Prefix_Length)
					uci:set("network","wan","ip6gw",IPv6_Fixed_StaticGateway)
					--uci:set("network","wan","IPv6_dns", IPv6_DNS)
					uci:set("network","wan","send_rs","1")
					uci:set("network","wan","accept_ra","0")
					uci:set("network","wan","ipv6","1")
					uci:set("network","general","linkLocalOnly","0")
				elseif IPv6_WAN_IP_Auto == "linkLocal_only" then
					uci:set("network","wan","ipv6","0")
					uci:set("network","general","linkLocalOnly","1")
                end

				--uci:commit("network")
				uci:commit("dhcp6c")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				--WenHsien denoted for EMG2926
				--uci:apply("RA_dhcp6c")

				--uci:apply("network")
				-- if not IPv6_DNS then
				--sys.exec("echo nameserver "..IPv6_DNS.." >> /tmp/resolv.conf.auto")
				-- end
				--local ipv6_fixed_addr=uci:get("network","wan","ip6addr")
				--local ipv6_prefixlength=uci:get("network","wan","prefixlen")
				--if not ipv6_fixed_addr then ipv6_fixed_addr="" end
				--if not ipv6_prefixlength then ipv6_prefixlength="" end
				--sys.exec("ifconfig vlan10 add "..ipv6_fixed_addr.."/"..IPv6_Prefix_Length)

				--local ipv6_fixedgateway=uci:get("network","wan","ip6gw")
				--   if not ipv6_fixedgateway then ipv6_fixedgateway="" end
				--sys.exec("ip -6 route del default dev vlan10")
				--sys.exec("ip -6 route add default via "..ipv6_fixedgateway)
            end
		end -- IP mode

		local WAN_MAC_Clone = luci.http.formvalue("WAN_MAC_Clone")
		local spoofIPAddr = luci.http.formvalue("spoofIPAddr")
		local macCloneMac = luci.http.formvalue("macCloneMac")
		--[[
		local old_WAN_MAC_Clone = uci:get("network", "wan", "wan_mac_status")
		if not old_WAN_MAC_Clone then
			old_WAN_MAC_Clone = "0"
			uci:set("network","wan","wan_mac_status",old_WAN_MAC_Clone)
		end
		]]--
		--if WAN_MAC_Clone ~= old_WAN_MAC_Clone then
			if WAN_MAC_Clone == "0" then
				uci:set("network","wan","wan_mac_status",WAN_MAC_Clone)
			elseif WAN_MAC_Clone == "1" then
				local sw = 0
				local t={}
				t=luci.sys.net.arptable()
				for i,v in ipairs(t) do
					if t[i]["IP address"]==spoofIPAddr then
						uci:set("network","wan","wan_clone_ip",t[i]["IP address"])
						uci:set("network","wan","wan_clone_ip_mac",t[i]["HW address"])
						sw = 1
					end
				end

				if sw==1 then
					uci:set("network","wan","wan_mac_status","1")
				else
					arpError = 1
				end

			elseif WAN_MAC_Clone == "2" then
				uci:set("network","wan","wan_mac_status",WAN_MAC_Clone)
				uci:set("network","wan","wan_set_mac",macCloneMac)
			end

		--end

		uci:set("network","general","config_section","wan")

		--WenHsien
		local v6_static = uci:get("network","wan","v6_static")
		if v6_static ~= "1" then
			uci:commit("dhcp")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			--WenHsien denoted for EMG2926
			--uci:apply("dhcp")
			--uci:commit("network")
			--uci:apply("network")
		end
		uci:set("network","wan","v6_static","0")

		local ori_ipChangeEnabled = uci:get("network", "general", "auto_ip_change")
		local ipChangeEnabled = luci.http.formvalue("autoIpChangeEnabled")

		if ori_ipChangeEnabled ~= ipChangeEnabled then
			if ipChangeEnabled then
				uci:set("network", "general", "auto_ip_change", ipChangeEnabled)
			else
				uci:set("network", "general", "auto_ip_change", "0")
			end
			uci:set("network", "general", "config_section", "advance")
		end

		uci:commit("network")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		sys.exec("echo 1 > /tmp/Apply_dhcp_GUI")
		uci:apply("network")

		ori_igmpEnabled = uci:get("igmpproxy","general","igmpEnabled")
		local igmpEnabled  = luci.http.formvalue("igmpEnabled")

		if	ori_igmpEnabled ~= igmpEnabled then
			uci:set("igmpproxy","general","igmpEnabled",igmpEnabled)
			uci:commit("igmpproxy")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			uci:apply("igmpproxy")
		end

		if arpError == 1 then
			local url = luci.dispatcher.build_url("expert","configuration","network","internet_connection")		
			luci.http.redirect(url .. "?" .. "arp_error=1" .. "&error_addr=" .. spoofIPAddr)
		else
			--WenHsien
			local url = luci.dispatcher.build_url("expert","configuration","network","internet_connection")
			luci.http.redirect(url)
		end
	end

    local pptp_status=sys.exec("/sbin/system_status.sh get_status pptp")
    if pptp_status == "NotSupport" then
    	luci.template.render("expert_configuration/broadband_add_without_pptp",{pptp_status=pptp_status})
    else
    	luci.template.render("expert_configuration/broadband_add",{pptp_status=pptp_status})
    end
	
end

function action_wan_ipv6()
	local apply = luci.http.formvalue("apply")

	if apply then
		local connect_type = luci.http.formvalue("connectionType")

		if ( connect_type == "None" ) then
			--IPoE
			--PPPoE
			--Tunnel
			sys.exec("/etc/init.d/gw6c stop 2>/dev/null")
			uci:set("gw6c", "basic", "disabled", "1")
			uci:commit("gw6c")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			uci:set("network6","wan","type", "none")
			uci:commit("network6")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		elseif ( connect_type == "Tunnelv6" ) then
			--local broker = luci.http.formvalue("tunnel_broker")
			--freenet6
			--if (broker == "freenet6") then
				local user_name = luci.http.formvalue("gogo6_user_name")
				local password = luci.http.formvalue("gogo6_pwd")
				local tunnel_type = luci.http.formvalue("tunnel_mode")
				--local server = luci.http.formvalue("gogo6_server")
                                local server = luci.http.formvalue("tunnel_broker")

				uci:set("network6","wan","type", "tunnel")
				uci:commit("network6")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem

				uci:set("gw6c", "basic", "disabled", 0)
				uci:set("gw6c", "basic", "userid", user_name)
				uci:set("gw6c", "basic", "passwd", password)
				uci:set("gw6c", "advanced", "if_tunnel_mode", tunnel_type)

				if (server == "best_server") then
					uci:set("gw6c", "basic", "server", "anon.freenet6.net")
				else
					uci:set("gw6c", "basic", "server", server)
				end

				uci:commit("gw6c")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				uci:apply("gw6c")
			--end
		end
	end

	luci.template.render("expert_configuration/ipv6")
end

function action_wan_advanced()
	local apply = luci.http.formvalue("apply")

	if apply then
		local apply_igmp = luci.http.formvalue("apply_igmp")
		local apply_ip_change = luci.http.formvalue("apply_ip_change")

		if apply_igmp then
			local igmpEnabled = luci.http.formvalue("igmpEnabled")
			uci:set("igmpproxy","general","igmpEnabled",igmpEnabled)
			uci:commit("igmpproxy")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			uci:apply("igmpproxy")
		end

		if apply_ip_change then
			local ipChangeEnabled  = luci.http.formvalue("ipChangeEnabled")
			uci:set("network", "general", "auto_ip_change", ipChangeEnabled)
			uci:set("network", "general", "config_section", "advance")
			uci:commit("network")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem				
			uci:apply("network")
		end
	end
        luci.template.render("expert_configuration/broadband_advance")
end

function subnet(ip, mask)
	local ip_byte1, ip_byte2, ip_byte3, ip_byte4 = ip:match("(%d+).(%d+).(%d+).(%d+)")
	local mask_byte1, mask_byte2, mask_byte3, mask_byte4 = mask:match("(%d+).(%d+).(%d+).(%d+)")

	return bit.band(tonumber(ip_byte1), tonumber(mask_byte1)) .. "." .. bit.band(tonumber(ip_byte2), tonumber(mask_byte2)) .. "." .. bit.band(tonumber(ip_byte3), tonumber(mask_byte3)) .. "." .. bit.band(tonumber(ip_byte4), tonumber(mask_byte4))
end

function action_lan()
	luci.template.render("expert_configuration/lan")
end

function action_menu_lan()
	luci.template.render("expert_configuration/menu_lan")
end

function action_lan_ip()
	local apply = luci.http.formvalue("apply")

	if apply then
		local ipaddr  = luci.http.formvalue("ipaddr")
		local netmask = luci.http.formvalue("netmask")
		local lan_ip = uci:get("network", "lan", "ipaddr")
		local lan_mask = uci:get("network", "lan", "netmask")
		local changed = false
		local subnet_changed = false
		local hostname = uci:get("system", "main", "hostname")
		local system_mode = uci:get("system", "main", "system_mode")
		local old_ipaddr = uci:get("network", "lan", "ipaddr")

		if system_mode ~= "2" and system_mode ~= "3" then

			if not (ipaddr == lan_ip) then
				uci:set("network", "lan", "ipaddr", ipaddr)

				local file = io.open( "/etc/hosts", "w" )
				file:write(ipaddr .. " " .. hostname .. "\n")
				file:write(ipaddr .. " " .. "myrouter" .. "\n")
				file:write("127.0.0.1" .. " " .. "localhost" .. "\n")
				file:close()

				changed = true
			end

			if not (netmask == lan_mask) then
				uci:set("network", "lan", "netmask", netmask)
				changed = true
				subnet_changed = true
			end

			if not ("static" == uci:get("network", "lan", "proto")) then
				uci:set("network", "lan", "proto", "static")
				changed = true
			end

			local enabled = luci.http.formvalue("ssid_state")
			local startAddress = luci.http.formvalue("startAdd")
			local poolSize = luci.http.formvalue("poolSize")
			local old_enabled = uci:get("dhcp", "lan", "enabled")
			local old_start = uci:get("dhcp", "lan", "start")
			local old_poolSize = uci:get("dhcp", "lan", "limit")
			local start=string.match(startAddress,"%d+.%d+.%d+.(%d+)")

			if enabled ~= old_enabled or start ~= old_start or poolSize ~= old_poolSize or ipaddr ~= old_ipaddr then

				changed = true

				uci:set("dhcp","lan","dhcp")
				uci:set("dhcp","lan",'enabled',enabled)
				uci:set("dhcp","lan",'start',start)
				uci:set("dhcp","lan",'limit',poolSize)

				uci:commit("dhcp")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem

			end

			if changed then

				local lan_subnet = subnet(lan_ip, lan_mask)
				local cfg_subnet = subnet(ipaddr, netmask)

				uci:set("network","general","config_section","lan")

				if enabled ~= old_enabled or lan_subnet ~= cfg_subnet or subnet_changed or start ~= old_start or poolSize ~= old_poolSize or ipaddr ~= old_ipaddr then
					sys.exec("echo 1 > /tmp/lan_dhcp_range")
				end

				uci:commit("network")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				sys.exec("touch /tmp/changeLanIP")
				sys.exec("echo 1 > /tmp/Apply_dhcp_GUI")

			end

			-- DNS Relay
			local sysFirstDNSAddr = luci.http.formvalue("sysFirDNSAddr")
			local sysSecondDNSAddr = luci.http.formvalue("sysSecDNSAddr")
			local sysThirdDNSAddr = luci.http.formvalue("sysThirdDNSAddr")

			local lan_dns=""
			local d1= luci.http.formvalue("LAN_FirstDNS")
			if d1 == "fromISP" then
			        lan_dns=lan_dns .. "FromISP,"
			elseif d1 == "userDefine"  then
			        lan_dns=lan_dns .. sysFirstDNSAddr .. ","
			elseif d1 == "none"  then
			        lan_dns=lan_dns .. "None,"
			else
			        lan_dns=lan_dns .. "dnsRelay,"
			end

			local d2= luci.http.formvalue("LAN_SecondDNS")
			if d2 == "fromISP" then
			    	lan_dns=lan_dns .. "FromISP,"
			elseif d2 == "userDefine"  then
			    	lan_dns=lan_dns .. sysSecondDNSAddr .. ","
			elseif d2 == "none"  then
			    	lan_dns=lan_dns .. "None,"
			else
			    	lan_dns=lan_dns .. "dnsRelay,"
			end

			local d3= luci.http.formvalue("LAN_ThirdDNS")
			if d3 == "fromISP" then
			    	lan_dns=lan_dns .. "FromISP"
			elseif d3 == "userDefine"  then
			    	lan_dns=lan_dns .. sysThirdDNSAddr
			elseif d3 == "none"  then
			    	lan_dns=lan_dns .. "None"
			else
			    	lan_dns=lan_dns .. "dnsRelay"
			end

			uci:set("dhcp","lan","dhcp")
			uci:set("dhcp","lan",'lan_dns',lan_dns)
			uci:commit("dhcp")
			uci:apply("network")

		else
			local LAN_IP_Auto = luci.http.formvalue("LAN_IP_Auto2")
			local gateway = luci.http.formvalue("gateway")
			local lan_gw = uci:get("network", "lan", "gateway")

			if not LAN_IP_Auto then
				LAN_IP_Auto="0"
			end

			if LAN_IP_Auto == "1" then
				uci:set("network","lan","proto","dhcp")
          	else
				uci:set("network","lan","proto","static")
				uci:set("network", "lan", "ipaddr", ipaddr)
				uci:set("network", "lan", "netmask", netmask)
          	end

			if not gateway then
				gateway = ""
			end

			uci:set("network", "lan", "gateway", gateway)

			--lock dns check, and it will be unlock after updating dns in update_sys_dns
			sys.exec("echo 1 > /var/update_dns_lock")

			local lan_proto = uci:get("network","lan","proto")
			sys.exec("echo "..lan_proto.." > /tmp/old_lan_proto")

			local Server_dns1Type       = luci.http.formvalue("dns1Type")
			local Server_staticPriDns   = luci.http.formvalue("staticPriDns")
			local Server_dns2Type       = luci.http.formvalue("dns2Type")
			local Server_staticSecDns   = luci.http.formvalue("staticSecDns")
			local Server_dns3Type       = luci.http.formvalue("dns3Type")
			local Server_staticThiDns   = luci.http.formvalue("staticThiDns")

			if Server_dns1Type~="USER" or Server_staticPriDns == "0.0.0.0" or not Server_staticPriDns then
				Server_staticPriDns=""
			end

			if Server_dns2Type~="USER" or Server_staticSecDns == "0.0.0.0" or not Server_staticSecDns then
				Server_staticSecDns=""
			end

			if Server_dns3Type~="USER" or Server_staticThiDns == "0.0.0.0" or not Server_staticThiDns then
				Server_staticThiDns=""
			end

			uci:set("network","lan","dns1",Server_dns1Type ..",".. Server_staticPriDns)
			uci:set("network","lan","dns2",Server_dns2Type ..",".. Server_staticSecDns)
			uci:set("network","lan","dns3",Server_dns3Type ..",".. Server_staticThiDns)

			uci:set("network","general","config_section","lan")
			uci:commit("network")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			sys.exec("echo 1 > /tmp/Apply_dhcp_GUI")
			uci:apply("network")
			
			if system_mode == "3" then
				uci:apply("wireless_client")
			end
		end
	end

	luci.template.render("expert_configuration/lan_ip")
end

function action_ipalias()
	local apply = luci.http.formvalue("apply")

	if apply then
		local i = 1

		uci:delete_all("network", "alias")
		while not (nil == luci.http.formvalue("alias" .. i .. "_ip")) do
			local aliasEntry = "alias"..i
			uci:set("network",aliasEntry,"alias")

			local aliasIP = luci.http.formvalue("alias" .. i .. "_ip")
			local aliasNetmask = luci.http.formvalue("alias" .. i .. "_netmask")
			local lan_ifname
			if uci:get("network","lan","type") == "bridge" then
				lan_ifname = "lan"
			else
				lan_ifname = uci:get("network","lan","ifname")
			end

			--local lan_ifname = "br0"--#change eth0 to br0#
			local enabled = luci.http.formvalue("alias" .. i .. "_enabled")

			if not (enabled == "enabled") then
				enabled = "disabled"
			end

			uci:set("network", aliasEntry, "interface_alias", lan_ifname)
			uci:set("network", aliasEntry, "enabled", enabled)
			uci:set("network", aliasEntry, "proto_alias", "static")
			uci:set("network", aliasEntry, "ipaddr_alias", aliasIP)
			uci:set("network", aliasEntry, "netmask_alias", aliasNetmask)

			i = i + 1
		end
		uci:set("network","general","config_section","ipalias")
		uci:commit("network")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("network")
	end

	luci.template.render("expert_configuration/ip_alias")
end

function action_ipv6lan()
	local apply = luci.http.formvalue("apply")

	if apply then
		local PD = luci.http.formvalue("PDEnable")
		local MinRtrAdvInterval = luci.http.formvalue("MinRtrAdvInterval")
		local MaxRtrAdvInterval

		local ipv6_Enable = uci:get("network", "wan", "ipv6")

		uci:set("radvd", "interface", "MinRtrAdvInterval", MinRtrAdvInterval)
		MaxRtrAdvInterval = MinRtrAdvInterval*2
		if (MaxRtrAdvInterval > 1800) then
			MaxRtrAdvInterval = 1800
		end
		uci:set("radvd", "interface", "MaxRtrAdvInterval", MaxRtrAdvInterval)

		-- 1. Clean all LAN Global IPs.
		sys.exec("ifconfig br-lan |grep Global |awk '{print $3}' |xargs -n 1 ifconfig br-lan del");

		--dhcpv6pd
		if PD == "1" then
			uci:set("network","general","v6lanstatic","0")
			if ipv6_Enable == "1" then
				local auto_config_select = luci.http.formvalue("auto_config_select")
				local range_start = luci.http.formvalue("range_start")
				local range_end = luci.http.formvalue("range_end")
				local lifetime = luci.http.formvalue("lifetime")

				if auto_config_select == "1" then
					uci:set("radvd", "interface", "AdvManagedFlag", "0")
					uci:set("radvd", "interface", "AdvOtherConfigFlag", "0")
				elseif auto_config_select == "2" then
					uci:set("radvd", "interface", "AdvManagedFlag", "0")
					uci:set("radvd", "interface", "AdvOtherConfigFlag", "1")
				else
					uci:set("radvd", "interface", "AdvManagedFlag", "1")
					uci:set("radvd", "interface", "AdvOtherConfigFlag", "1")
					uci:set("dhcp6s", "basic", "addrstart", range_start)
					uci:set("dhcp6s", "basic", "addrend", range_end)
					uci:set("dhcp6s", "basic", "lifetime", lifetime)
				end
				uci:commit("radvd")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				uci:commit("dhcp6s")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem

				-- 2. Set UCI default_lan_radvd
				uci:set("default_lan_radvd", "basic", "address", "")
				uci:set("default_lan_radvd", "basic", "prefixlen", "")
				uci:set("default_lan_radvd", "basic", "prefix", "")
				uci:set("default_lan_radvd", "basic", "masked_address", "")
				uci:commit("default_lan_radvd")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem

				uci:set("network", "general", "dhcpv6pd", "1")
				uci:set("network","wan","ipv6","1")
				uci:set("network","general","linkLocalOnly","0")
				uci:set("network","general","ULA","0")
				uci:commit("network")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				uci:apply("radvd")
				sys.exec("/etc/init.d/dhcp6c restart")
			else
				local auto_config_select = luci.http.formvalue("auto_config_select")
				local range_start = luci.http.formvalue("range_start")
				local range_end = luci.http.formvalue("range_end")
				local lifetime = luci.http.formvalue("lifetime")

				if auto_config_select == "1" then
					uci:set("radvd", "interface", "AdvManagedFlag", "0")
					uci:set("radvd", "interface", "AdvOtherConfigFlag", "0")
				elseif auto_config_select == "2" then
					uci:set("radvd", "interface", "AdvManagedFlag", "0")
					uci:set("radvd", "interface", "AdvOtherConfigFlag", "1")
				else
					uci:set("radvd", "interface", "AdvManagedFlag", "1")
					uci:set("radvd", "interface", "AdvOtherConfigFlag", "1")
					uci:set("dhcp6s", "basic", "addrstart", range_start)
					uci:set("dhcp6s", "basic", "addrend", range_end)
					uci:set("dhcp6s", "basic", "lifetime", lifetime)
				end
				uci:commit("radvd")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				uci:commit("dhcp6s")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem

				uci:set("network","general","dhcpv6pd", "1")
				uci:set("network","general","linkLocalOnly","0")
				uci:set("network","general","ULA","0")
				uci:commit("network")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem

				uci:apply("network")
			end

		--v6lanstatic
		elseif PD == "2" then
			local ipaddrv6 = luci.http.formvalue("ipv6address")
			local prefixlenipv6 = luci.http.formvalue("ipv6prefixlen")
			local pref_lt = luci.http.formvalue("ipv6_pref_lt")
			local vali_lt = luci.http.formvalue("ipv6_vali_lt")
			local ra_m_flag = luci.http.formvalue("ipv6_ra_m_flag")

			-- 1. Set LAN Static IP.  Set this later by  radvd.sh  .
			--sys.exec("ifconfig br-lan add "..ipaddrv6.."/64")

			-- 2. Set UCI default_lan_radvd
			uci:set("default_lan_radvd", "basic", "address", ipaddrv6)
			uci:set("default_lan_radvd", "basic", "prefixlen", prefixlenipv6)
			uci:set("radvd", "prefix", "AdvPreferredLifetime", pref_lt)
			uci:set("radvd", "prefix", "AdvValidLifetime", vali_lt)
			uci:set("radvd", "interface", "AdvManagedFlag", ra_m_flag)
			-- WenHsien: Prefix and Masked_Address option is calculated in  radvd.sh  .2014.0505.
			uci:commit("default_lan_radvd")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			uci:commit("radvd")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem

			uci:set("network","wan","ipv6","1")
			uci:set("network", "general", "dhcpv6pd", "0")
			uci:set("network","general","v6lanstatic","1")
			uci:set("network","general","linkLocalOnly","0")
			uci:set("network","general","ULA","0")
			uci:commit("network")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem

			uci:apply("default_lan_radvd")

		--linkLocalOnly
		elseif PD == "3" then
			uci:set("network","wan","ipv6","0")
			uci:set("network", "general", "dhcpv6pd", "0")
			uci:set("network","general","v6lanstatic","0")
			uci:set("network","general","linkLocalOnly","1")
			uci:set("network","general","ULA","0")
			uci:commit("network")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem

			uci:apply("network")

		--ULA
		elseif PD == "4" then
			uci:set("network","wan","ipv6","1")
			uci:set("network", "general", "dhcpv6pd", "0")
			uci:set("network","general","v6lanstatic","0")
			uci:set("network","general","linkLocalOnly","0")
			uci:set("network","general","ULA","1")
			uci:set("radvd", "interface", "AdvManagedFlag", "0")
			uci:set("radvd", "interface", "AdvOtherConfigFlag", "1")
			uci:commit("network")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			uci:commit("radvd")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem

			uci:apply("radvd")

		end
	end

	luci.template.render("expert_configuration/ipv6lan")
end

--dipper firewall
function action_security()

	luci.template.render("expert_configuration/security")
end

function action_menu_security()

	luci.template.render("expert_configuration/menu_security")
end

function firewall()

	local apply = luci.http.formvalue("apply")

	if apply then
		local enabled = luci.http.formvalue("DoSEnabled")
		local fw_level
		local flag = 1

		if enabled == nil then
			enabled = "0"
		end
		uci:set("firewall","general","dos_enable",enabled)
		uci:commit("firewall")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("firewall")

	end

	luci.template.render("expert_configuration/firewall")
end

function fw_services()
	local firewall_apply = luci.http.formvalue("firwall_apply")
	local icmp_apply = luci.http.formvalue("icmp_apply")
	local enable_apply = luci.http.formvalue("enable_apply")
	local add_rule = luci.http.formvalue("add_rule")
	local remove = luci.http.formvalue("remove")

	if firewall_apply then
		local firewallenabled = luci.http.formvalue("DoSEnabled")
		local ori_firewall_apply = uci:get("firewall","general","dos_enable")
		local fw_level
		local flag = 1

		if firewallenabled then
			firewallenabled = "1"
		else
			firewallenabled = "0"
		end

		uci:set("firewall","general","dos_enable",firewallenabled)

		local action = luci.http.formvalue("action")
		uci:set("firewall","general","target",action)
--[[
		if not( ori_firewall_apply==firewallenabled ) then
			uci:set("firewall","general","dos_enable",firewallenabled)
			uci:commit("firewall")
			uci:apply("firewall")
		end
	end

	if icmp_apply then
]]--
		local pingEnabled = luci.http.formvalue("pingFrmWANFilterEnabled")
		local ori_pingEnabled = uci:get("firewall","general","pingEnabled")

		pingEnabled = checkInjection(pingEnabled)
		if pingEnabled ~= false then
			uci:set("firewall","general","pingEnabled",pingEnabled)
		end
--[[
	  if not (ori_pingEnabled==pingEnabled) then
	    pingEnabled = checkInjection(pingEnabled)
	    if pingEnabled ~= false then
		 uci:set("firewall","general","pingEnabled",pingEnabled)
		 uci:commit("firewall")
		 uci:apply("firewall")
	    end
	 end

    end

	if enable_apply then
]]--
		local filterEnabled = luci.http.formvalue("portFilterEnabled")
		local ori_filterEnabled = uci:get("firewall","general","filterEnabled")

		if filterEnabled then
			filterEnabled = "1"
		else
			filterEnabled = "0"
		end

--		if not (ori_filterEnabled==filterEnabled) then
		uci:set("firewall","general","filterEnabled",filterEnabled)
		uci:commit("firewall")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("firewall")

--		end

	end

	if add_rule then

		local srvName = luci.http.formvalue("srvName")
		local mac_address = luci.http.formvalue("mac_address")
		local dip_address = luci.http.formvalue("dip_address")
		local sip_address = luci.http.formvalue("sip_address")
		local protocol = luci.http.formvalue("protocol")
		local dFromPort = luci.http.formvalue("dFromPort")
		local dToPort = luci.http.formvalue("dToPort")
		local sFromPort = luci.http.formvalue("sFromPort")
		local sToPort = luci.http.formvalue("sToPort")

		-----firewall-----
		local enabled = 1
		if mac_address=="" then
			mac_address="00:00:00:00:00:00"
		end
		if dip_address=="" then
			dip_address="0.0.0.0"
		end
		if sip_address=="" then
			sip_address="0.0.0.0"
		end

		if protocol == "ICMP" then
			dFromPort = ""
			dToPort = ""
			sFromPort = ""
			sToPort = ""
		end

		if dFromPort=="" then
			if not dToPort=="" then
				dFromPort=dToPort
			end
		end

		if sFromPort=="" then
			if not sToPort=="" then
				sFromPort=sToPort
			end
		end

		local fw_type = "in"
		local wan = 0
		local lan = 0
		local fw_time = "always"
		--local target = "DROP"
		--local target =	uci:get("firewall","general","filterEnabled")

		local rules_count = uci:get("firewall","general","rules_count")
		local NextRulePos = uci:get("firewall","general","NextRulePos")
		--local service_count = uci:get("firewall","general","service_count")
		rules_count = rules_count+1
		NextRulePos = NextRulePos+1
		--service_count = service_count+1
		local rules = "rule"..rules_count
		local services = "service"..rules_count
		--[[
		uci:set("firewall",services,"service")
		uci:set("firewall",services,"name",srvName)
		uci:set("firewall",services,"protocol",protocol)
		uci:set("firewall",services,"dFromPort",dFromPort)
		uci:set("firewall",services,"dToPort",dToPort)
		uci:set("firewall",services,"sFromPort",sFromPort)
		uci:set("firewall",services,"sToPort",sToPort)
		]]--

		uci:set("firewall",rules,"firewall")
		uci:set("firewall",rules,"StatusEnable",enabled)
		uci:set("firewall",rules,"CurPos",rules_count)
		uci:set("firewall",rules,"type",fw_type)
		uci:set("firewall",rules,"service",services)
		uci:set("firewall",rules,"wan",wan)
		uci:set("firewall",rules,"local",lan)

		srvName = checkInjection(srvName)
		if srvName ~= false then
			uci:set("firewall",rules,"name",srvName)
		end

		if string.match(protocol, "(%w+)") then
			protocol = string.match(protocol, "(%w+)")
			uci:set("firewall",rules,"protocol",protocol)
		end
		if string.match(dFromPort, "(%d+)") then
			dFromPort = string.match(dFromPort, "(%d+)")
			uci:set("firewall",rules,"dFromPort",dFromPort)
		end
		if string.match(dToPort, "(%d+)") then
			dToPort = string.match(dToPort, "(%d+)")
			uci:set("firewall",rules,"dToPort",dToPort)
		end
		if string.match(sFromPort, "(%d+)") then
			sFromPort = string.match(sFromPort, "(%d+)")
			uci:set("firewall",rules,"sFromPort",sFromPort)
		end
		if string.match(sToPort, "(%d+)") then
			sToPort = string.match(sToPort, "(%d+)")
			uci:set("firewall",rules,"sToPort",sToPort)
		end
		if string.match(mac_address, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)") then
			mac_address = string.match(mac_address, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)")
			uci:set("firewall",rules,"mac_address",mac_address)
		end
		if string.match(sip_address, "(%d+.%d+.%d+.%d+)") then
			sip_address = string.match(sip_address, "(%d+.%d+.%d+.%d+)")
			uci:set("firewall",rules,"src_ip",sip_address)
		end
		if string.match(dip_address, "(%d+.%d+.%d+.%d+)") then
			dip_address = string.match(dip_address, "(%d+.%d+.%d+.%d+)")
			uci:set("firewall",rules,"dst_ip",dip_address)
		end

		uci:set("firewall",rules,"time",fw_time)

		local action = luci.http.formvalue("action")
		uci:set("firewall","general","target",action)
		--uci:set("firewall",rules,"target",target)

		uci:set("firewall","general","rules_count",rules_count)
		uci:set("firewall","general","NextRulePos",NextRulePos)
		--uci:set("firewall","general","service_count",service_count)
		uci:commit("firewall")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("firewall")

	end


	if remove then

		local cur_num = remove
		local del_rule ="rule"..cur_num
		uci:delete("firewall",del_rule)

		-----firewall-----
		local rules_count = uci:get("firewall","general","rules_count")
		local NextRulePos = uci:get("firewall","general","NextRulePos")
		local num = rules_count-cur_num

		for i=num,1,-1 do
			local rules = "rule"..cur_num+1
			local new_rule = "rule"..cur_num
			local old_data = {}
			old_data=uci:get_all("firewall",rules)

			if old_data then
				uci:set("firewall",new_rule,"firewall")
				uci:tset("firewall",new_rule,old_data)
				uci:set("firewall",new_rule,"CurPos",cur_num)
				uci:commit("firewall")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				uci:delete("firewall",rules)
				uci:commit("firewall")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				cur_num =cur_num+1
			end
		end

		uci:set("firewall","general","rules_count",rules_count-1)
		uci:set("firewall","general","NextRulePos",NextRulePos-1)
		uci:commit("firewall")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("firewall")
	end

	luci.template.render("expert_configuration/fw_services")
end
--dipper firewall

function firewall6()

	local icmp_apply = luci.http.formvalue("icmp_apply")
	local enable_apply = luci.http.formvalue("enable_apply")
	local add_rule = luci.http.formvalue("add_rule")
	local remove = luci.http.formvalue("remove")
--[[
	if icmp_apply then

		local pingEnabled = luci.http.formvalue("pingFrmWANFilterEnabled")
		local ori_pingEnabled = uci:get("firewall6","general","pingEnabled")

		if not (ori_pingEnabled==pingEnabled) then
			pingEnabled = checkInjection(pingEnabled)
			if pingEnabled ~= false then
				uci:set("firewall6","general","pingEnabled",pingEnabled)
			end
			uci:commit("firewall6")
			uci:apply("firewall6")
		end
	end
]]--
	if enable_apply then

		local action = luci.http.formvalue("action")
		uci:set("firewall6","general","target",action)

		local SimpleEnabled = luci.http.formvalue("SimpleEnabled")
		local filterEnabled = luci.http.formvalue("portFilterEnabled")
		local ori_filterEnabled = uci:get("firewall6","general","filterEnabled")

		if filterEnabled then
			filterEnabled = "1"
		else
			filterEnabled = "0"
		end

		if SimpleEnabled then 
			SimpleEnabled = "1"
		else
			SimpleEnabled = "0"
		end

--		if not (ori_filterEnabled==filterEnabled) then
			uci:set("firewall6","general","simpleSecurityEnabled",SimpleEnabled)
			uci:set("firewall6","general","filterEnabled",filterEnabled)
			uci:commit("firewall6")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			uci:apply("firewall6")
--		end

	end

	if add_rule then

		local srvName = luci.http.formvalue("srvName")
		local mac_address = luci.http.formvalue("mac_address")
		local dip_address = luci.http.formvalue("dip_address")
		local sip_address = luci.http.formvalue("sip_address")
		local protocol = luci.http.formvalue("protocol")
		local dFromPort = luci.http.formvalue("dFromPort")
		local dToPort = luci.http.formvalue("dToPort")
		local sFromPort = luci.http.formvalue("sFromPort")
		local sToPort = luci.http.formvalue("sToPort")

		-----firewall-----
		local enabled = 1
		if mac_address=="" then
			mac_address="00:00:00:00:00:00"
		end
		if dip_address=="" then
			dip_address="::"
		end
		if sip_address=="" then
			sip_address="::"
		end

		if protocol == "ICMPv6" then
			dFromPort = ""
			dToPort = ""
			sFromPort = ""
			sToPort = ""
		end

		if dFromPort=="" then
			if not dToPort=="" then
				dFromPort=dToPort
			end
		end

		if sFromPort=="" then
			if not sToPort=="" then
				sFromPort=sToPort
			end
		end

		local fw_type = "in"
		local wan = 0
		local lan = 0
		local fw_time = "always"
		--local target = "DROP"
		--local target =	uci:get("firewall6","general","filterEnabled")

		local rules_count = uci:get("firewall6","general","rules_count")
		local NextRulePos = uci:get("firewall6","general","NextRulePos")
		--local service_count = uci:get("firewall6","general","service_count")
		rules_count = rules_count+1
		NextRulePos = NextRulePos+1
		--service_count = service_count+1
		local rules = "rule"..rules_count
		local services = "service"..rules_count
		--[[
		uci:set("firewall6",services,"service")
		uci:set("firewall6",services,"name",srvName)
		uci:set("firewall6",services,"protocol",protocol)
		uci:set("firewall6",services,"dFromPort",dFromPort)
		uci:set("firewall6",services,"dToPort",dToPort)
		uci:set("firewall6",services,"sFromPort",sFromPort)
		uci:set("firewall6",services,"sToPort",sToPort)
		]]--

		uci:set("firewall6",rules,"firewall6")
		uci:set("firewall6",rules,"StatusEnable",enabled)
		uci:set("firewall6",rules,"CurPos",rules_count)
		uci:set("firewall6",rules,"type",fw_type)
		uci:set("firewall6",rules,"service",services)
		uci:set("firewall6",rules,"wan",wan)
		uci:set("firewall6",rules,"local",lan)
		uci:set("firewall6",rules,"time",fw_time)

		local action = luci.http.formvalue("action")
		uci:set("firewall6","general","target",action)
		--uci:set("firewall6",rules,"target",target)

		srvName = checkInjection(srvName)
		if srvName ~= false then
			uci:set("firewall6",rules,"name",srvName)
		end

		if string.match(protocol, "(%w+)") then
			protocol = string.match(protocol, "(%w+)")
			uci:set("firewall6",rules,"protocol",protocol)
		end
		if string.match(dFromPort, "(%d+)") then
			dFromPort = string.match(dFromPort, "(%d+)")
			uci:set("firewall6",rules,"dFromPort",dFromPort)
		end
		if string.match(dToPort, "(%d+)") then
			dToPort = string.match(dToPort, "(%d+)")
			uci:set("firewall6",rules,"dToPort",dToPort)
		end
		if string.match(sFromPort, "(%d+)") then
			sFromPort = string.match(sFromPort, "(%d+)")
			uci:set("firewall6",rules,"sFromPort",sFromPort)
		end
		if string.match(sToPort, "(%d+)") then
			sToPort = string.match(sToPort, "(%d+)")
			uci:set("firewall6",rules,"sToPort",sToPort)
		end
		if string.match(mac_address, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)") then
			mac_address = string.match(mac_address, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)")
			uci:set("firewall6",rules,"mac_address",mac_address)
		end
		sip_address = checkInjection(sip_address)
		if sip_address ~= false then
			uci:set("firewall6",rules,"src_ip",sip_address)
		end

		dip_address = checkInjection(dip_address)
		if dip_address ~= false then
			uci:set("firewall6",rules,"dst_ip",dip_address)
		end

		uci:set("firewall6","general","rules_count",rules_count)
		uci:set("firewall6","general","NextRulePos",NextRulePos)
		--uci:set("firewall6","general","service_count",service_count)

		uci:commit("firewall6")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("firewall6")

	end


	if remove then

		local cur_num = remove
		local del_rule ="rule"..cur_num
		uci:delete("firewall6",del_rule)

		-----firewall-----
		local rules_count = uci:get("firewall6","general","rules_count")
		local NextRulePos = uci:get("firewall6","general","NextRulePos")
		local num = rules_count-cur_num

		for i=num,1,-1 do
			local rules = "rule"..cur_num+1
			local new_rule = "rule"..cur_num
			local old_data = {}
			old_data=uci:get_all("firewall6",rules)

			if old_data then
				uci:set("firewall6",new_rule,"firewall6")
				uci:tset("firewall6",new_rule,old_data)
				uci:set("firewall6",new_rule,"CurPos",cur_num)
				uci:commit("firewall6")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				uci:delete("firewall6",rules)
				uci:commit("firewall6")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				cur_num =cur_num+1
			end
		end

		uci:set("firewall6","general","rules_count",rules_count-1)
		uci:set("firewall6","general","NextRulePos",NextRulePos-1)

		uci:commit("firewall6")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("firewall6")

	end

	luci.template.render("expert_configuration/IPv6firewall")
end

--dipper nat
function nat()

	local apply = luci.http.formvalue("apply")

	if apply then

		local enabled = luci.http.formvalue("enabled")
		--local sessions_user = luci.http.formvalue("sessions_user")

		if not max_user then
			max_user=""
		end

		uci:set("nat","general","nat")
		uci:set("nat","general","nat",enabled)
		--uci:set("nat","general","sessions_user",sessions_user)
		uci:commit("nat")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("nat")

		--uci:set("nat_new","general_new","nat")
		--uci:set("nat_new","general_new","nat",enabled)
		--uci:set("nat_new","general_new","max_user",max_user)
		--uci:commit("nat_new")
		--uci:apply("nat_new")

	end

	luci.template.render("expert_configuration/nat")
end


function action_passthrough()

	local apply = luci.http.formvalue("apply")

	if apply then

		local enabled1 = luci.http.formvalue("enabled_ftp")
		local enabled2 = luci.http.formvalue("enabled_h323")
		local enabled3 = luci.http.formvalue("enabled_sip")
		local enabled4 = luci.http.formvalue("enabled_snmp")
		local enabled5 = luci.http.formvalue("enabled_rtsp")
		local enabled6 = luci.http.formvalue("enabled_irc")

		local enabled7 = luci.http.formvalue("enabled_pptp")
		local enabled8 = luci.http.formvalue("enabled_l2tp")
		local enabled9 = luci.http.formvalue("enabled_ipsec")
		--local sessions_user = luci.http.formvalue("sessions_user")

		if not max_user then
			max_user=""
		end


		uci:set("nat","general","ftp")
		if not ( enabled1 == "enable") then
			uci:set("nat","general","ftp","disable")
		else
			uci:set("nat","general","ftp","enable")
		end

		uci:set("nat","general","h323")
		if not ( "enable" == enabled2) then
			uci:set("nat","general","h323","disable")
		else
			uci:set("nat","general","h323","enable")
		end

		uci:set("nat","general","sip")
		if not ( "enable" == enabled3 ) then
			uci:set("nat","general","sip","disable")
        else
			uci:set("nat","general","sip","enable")
		end

		uci:set("nat","general","snmp")
		if not ( enabled4 == "enable") then
			uci:set("nat","general","snmp","disable")
		else
			uci:set("nat","general","snmp","enable")
		end

		uci:set("nat","general","rtsp")
		if not ( "enable" == enabled5) then
			uci:set("nat","general","rtsp","disable")
		else
			uci:set("nat","general","rtsp","enable")
		end

		uci:set("nat","general","irc")
		if not ( "enable" == enabled6 ) then
			uci:set("nat","general","irc","disable")
        else
			uci:set("nat","general","irc","enable")
		end

		uci:set("nat","general","pptp")
        if not ( "enable" == enabled7) then
			uci:set("nat","general","pptp","disable")
		else
			uci:set("nat","general","pptp","enable")
		end

		uci:set("nat","general","l2tp")
		if not ( "enable" == enabled8) then
			uci:set("nat","general","l2tp","disable")
		else
			uci:set("nat","general","l2tp","enable")
		end

		uci:set("nat","general","ipsec")
        if not ( "enable" == enabled9) then
			uci:set("nat","general","ipsec","disable")
        else
			uci:set("nat","general","ipsec","enable")
        end

		uci:commit("nat")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("nat")
	end

	luci.template.render("expert_configuration/nat_passthrough")
end

--dipper content filter
function action_CF()

	local apply = luci.http.formvalue("apply")

	if apply then

		local IPAddress = luci.http.formvalue("websTrustedIPAddress")
		if string.match(IPAddress, "(%d+.%d+.%d+.%d+)") then
			IPAddress = string.match(IPAddress, "(%d+.%d+.%d+.%d+)")
			uci:set("parental","trust_ip","ipaddr",IPAddress)
		end

		local Activex = luci.http.formvalue("websFilterActivex")
		local Java = luci.http.formvalue("websFilterJava")
		local Cookies = luci.http.formvalue("websFilterCookies")
		local Proxy = luci.http.formvalue("websFilterProxy")

		if not Activex then Activex=0 end
		if not Java then Java=0 end
		if not Cookies then Cookies=0 end
		if not Proxy then Proxy=0 end

		if not ( 0 == Activex ) then
			uci:set("parental","restrict_web","activeX",1)
		else
			uci:set("parental","restrict_web","activeX",0)
		end

		if not ( 0 == Java ) then
			uci:set("parental","restrict_web","java",1)
		else
			uci:set("parental","restrict_web","java",0)
		end

		if not ( 0 == Cookies ) then
			uci:set("parental","restrict_web","cookies",1)
		else
			uci:set("parental","restrict_web","cookies",0)
		end

		if not ( 0 == Proxy ) then
			uci:set("parental","restrict_web","web_proxy",1)
		else
			uci:set("parental","restrict_web","web_proxy",0)
		end

		local KeyWord_Enable = luci.http.formvalue("cfKeyWord_Enable")
		local url_str = luci.http.formvalue("url_str")

		if not KeyWord_Enable then KeyWord_Enable=0 end
		if not url_str  then url_str="" end

		uci:set("parental","keyword","enable",KeyWord_Enable)

		url_str = checkInjection(url_str)
		if url_str ~= false then
			uci:set("parental","keyword","keywords",url_str)
		end

		uci:commit("parental")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("parental")

	end

	luci.template.render("expert_configuration/ContentFilter")
end

function action_applications()
	luci.template.render("expert_configuration/applications")
end

function action_menu_app()
	local streamboost_status = sys.exec("/sbin/system_status.sh get_status streamboost")
	luci.template.render("expert_configuration/menu_app",{streamboost_status=streamboost_status})
end

function parental_control()
	local sysSubmit = luci.http.formvalue("sysSubmit")
	local apply = luci.http.formvalue("apply")
	local delete = luci.http.formvalue("delete")
	local submitType = luci.http.formvalue("SRSubmitType")
	local buffer = luci.http.formvalue("buffer")
	local reward_min = luci.http.formvalue("reward_min")

	local count = uci:get("parental_ex", "general" , "count")
	local enable = uci:get("parental_ex", "general" , "enable")

	local weekdays
	local start_hour
	local stop_hour
	local start_min
	local stop_min
	local start_time
	local end_time
	local schedule

	local hour = sys.exec("date +%H")
	local minn = sys.exec("date +%M")
	local sec  = sys.exec("date +%S")
	sys.exec("rm /tmp/bonus")
	local today
	local now_hour = sys.exec("date +%H")
	local dayofflist

	today = sys.exec("date  +%u | tr -d '\n' ")
	-- set schedule value (access internet or not)
	for i = 1,count do
		schedule = 0

		now_hour = now_hour + 0
		dayofflist = uci:get("parental_ex", "rule" .. i, "time" .. now_hour)

		if (today=="7") then
			today = 0
		end

		if dayofflist then
			schedule = string.sub(dayofflist,today + 1,today + 1)
			uci:set("parental_ex", "rule" .. i, "schedule", schedule)
		end
	end

	sys.exec("rm /tmp/weekdays")
	uci:commit("parental_ex")
	sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem

	if buffer then
		local times = sys.exec("date +%s")+0
		local timestamp = reward_min*60 + times

		uci:set("parental_ex", "rule" .. buffer, "reward_min", reward_min)
		uci:set("parental_ex", "rule" .. buffer, "timestamp", timestamp)
		uci:commit("parental_ex")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("parental_ex")
	end

	if delete then
		uci:set("parental_ex", "rule" .. delete, "delete", "1")
		uci:commit("parental_ex")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("parental_ex")
	end

	if sysSubmit then
		local parentalEnable = luci.http.formvalue("parental_state")
		parentalEnable = checkEnable(parentalEnable)
		if parentalEnable ~= false then
			uci:set("parental_ex", "general" , "enable", parentalEnable)
			uci:commit("parental_ex")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			uci:apply("parental_ex")
		end
	end

	sys.exec("cat /etc/crontabs/root |grep reward |awk '{print $1\"\t\"$2\"\t\"$7}' > /tmp/parental_bonus")
	sys.exec("sed -i 's/*/-1/g' /tmp/parental_bonus")

	local easymode = luci.http.formvalue("easymode")
	if easymode then
		luci.template.render("easy_ctfilter/parental_control")
	else
		luci.template.render("expert_configuration/ParentalControl")
	end
end

function parental_control_edit()
	local edit = luci.http.formvalue("edit")
	local Back = luci.http.formvalue("Back")
	local Back2 = luci.http.formvalue("Back2")
	local apply = luci.http.formvalue("apply")
	local apply2 = luci.http.formvalue("apply2")
	local delete = luci.http.formvalue("delete")
	local idx = 0
	local mac_list=""
	local macaddr_list=""
	local editID = luci.http.formvalue("SREditID")
	local sqlite3 = require("lsqlite3")
	local db = sqlite3.open( "/tmp/netprobe.db" )
	sys.exec("rm /tmp/maclist")
	sys.exec("rm /tmp/namelist")
	db:busy_timeout(5000)

	for row in db:nrows("SELECT * FROM Device where [Alive]=1 OR ([Alive]=0 AND [nNotAlive] <= 2); ") do
		if row.DevMac then
			DevMac = row.DevMac
		else
			DevMac = "00:00:00:00:00:00"
		end

		if row.DevName == nil then
			if row.Manufacture == nil then
				DevName = "Unknown"
			else
				DevName = row.Manufacture
			end
		else
			DevName = row.DevName
		end

		sys.exec("echo "..DevMac.." >> /tmp/maclist")
		sys.exec("echo "..DevName.." >> /tmp/namelist")

		macaddr_list=macaddr_list..DevMac..";"
		mac_list=mac_list..DevName..";"
	end

	if edit then
		rule_ind="rule"..edit+1
		local tmp_count=edit+1
		local rule_count=uci:get("parental_ex", "general" , "count")
		if (tonumber(rule_count) < tonumber(tmp_count)) then
			uci:set("parental_ex","general","count",edit+1)
			uci:set("parental_ex",rule_ind,"parental_rule")
			uci:set("parental_ex",rule_ind,"src_mac","00:00:00:00:00:00")
			uci:set("parental_ex",rule_ind,"stop_hour","24")
			uci:set("parental_ex",rule_ind,"weekdays","Mon,Tue,Wed,Thu,Fri,Sat,Sun")
			uci:set("parental_ex",rule_ind,"service_count","0")

		end

		local time0 = uci:get("parental_ex", rule_ind, "time0")
		local time1 = uci:get("parental_ex", rule_ind, "time1" )
		local time2 = uci:get("parental_ex", rule_ind, "time2" )
		local time3 = uci:get("parental_ex", rule_ind, "time3" )
		local time4 = uci:get("parental_ex", rule_ind, "time4" )
		local time5 = uci:get("parental_ex", rule_ind, "time5" )
		local time6 = uci:get("parental_ex", rule_ind, "time6" )
		local time7 = uci:get("parental_ex", rule_ind, "time7" )
		local time8 = uci:get("parental_ex", rule_ind, "time8" )
		local time9 = uci:get("parental_ex", rule_ind, "time9" )
		local time10 = uci:get("parental_ex", rule_ind, "time10" )
		local time11 = uci:get("parental_ex", rule_ind, "time11" )
		local time12 = uci:get("parental_ex", rule_ind, "time12" )
		local time13 = uci:get("parental_ex", rule_ind, "time13" )
		local time14 = uci:get("parental_ex", rule_ind, "time14" )
		local time15 = uci:get("parental_ex", rule_ind, "time15" )
		local time16 = uci:get("parental_ex", rule_ind, "time16" )
		local time17 = uci:get("parental_ex", rule_ind, "time17" )
		local time18 = uci:get("parental_ex", rule_ind, "time18" )
		local time19 = uci:get("parental_ex", rule_ind, "time19" )
		local time20 = uci:get("parental_ex", rule_ind, "time20" )
		local time21 = uci:get("parental_ex", rule_ind, "time21" )
		local time22 = uci:get("parental_ex", rule_ind, "time22" )
		local time23 = uci:get("parental_ex", rule_ind, "time23" )

		uci:set("parental_ex", "general", "ruleIdx", rule_ind)
		uci:commit("parental_ex")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		keywords = uci:get("parental_ex", rule_ind , "keyword")
		mac_list2 = uci:get("parental_ex", rule_ind , "mac_list")
		macaddr_list2 = uci:get("parental_ex", rule_ind , "src_mac")

		luci.template.render("expert_configuration/ParentalControl_Edit",{keywords = keywords,macaddr_list2=macaddr_list2, mac_list2 = mac_list2, selectindx = selectindx, rule=rule_ind, macaddr_list=macaddr_list,mac_list=mac_list,time0=time0,time1=time1,time2=time2,time3=time3,time4=time4,time5=time5,time6=time6,time7=time7,time8=time8,time9=time9,time10=time10,time11=time11,time12=time12,time13=time13,time14=time14,time15=time15,time16=time16,time17=time17,time18=time18,time19=time19,time20=time20,time21=time21,time22=time22,time23=time23 })
	else
		rule_ind = uci:get("parental_ex", "general" , "ruleIdx")
	end

	if delete then

		local time0 = uci:get("parental_ex", rule_ind, "time0")
		local time1 = uci:get("parental_ex", rule_ind, "time1" )
		local time2 = uci:get("parental_ex", rule_ind, "time2" )
		local time3 = uci:get("parental_ex", rule_ind, "time3" )
		local time4 = uci:get("parental_ex", rule_ind, "time4" )
		local time5 = uci:get("parental_ex", rule_ind, "time5" )
		local time6 = uci:get("parental_ex", rule_ind, "time6" )
		local time7 = uci:get("parental_ex", rule_ind, "time7" )
		local time8 = uci:get("parental_ex", rule_ind, "time8" )
		local time9 = uci:get("parental_ex", rule_ind, "time9" )
		local time10 = uci:get("parental_ex", rule_ind, "time10" )
		local time11 = uci:get("parental_ex", rule_ind, "time11" )
		local time12 = uci:get("parental_ex", rule_ind, "time12" )
		local time13 = uci:get("parental_ex", rule_ind, "time13" )
		local time14 = uci:get("parental_ex", rule_ind, "time14" )
		local time15 = uci:get("parental_ex", rule_ind, "time15" )
		local time16 = uci:get("parental_ex", rule_ind, "time16" )
		local time17 = uci:get("parental_ex", rule_ind, "time17" )
		local time18 = uci:get("parental_ex", rule_ind, "time18" )
		local time19 = uci:get("parental_ex", rule_ind, "time19" )
		local time20 = uci:get("parental_ex", rule_ind, "time20" )
		local time21 = uci:get("parental_ex", rule_ind, "time21" )
		local time22 = uci:get("parental_ex", rule_ind, "time22" )
		local time23 = uci:get("parental_ex", rule_ind, "time23" )

		editmac = uci:get("parental_ex", rule_ind , "src_mac")
		local idx_3 = 0
		for mac in io.lines("/tmp/maclist") do
			if ( mac == editmac) then
				selectindx = idx_3
				uci:set("parental_ex",rule_ind,"src_type","single")
				break
			else
				selectindx = "none"
			end
			idx_3 = idx_3 + 1
		end

		uci:set("parental_ex", rule_ind.."_service"..delete, "delete", "1")
		uci:commit("parental_ex")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("parental_ex")
		rule_ind = uci:get("parental_ex", "general" , "ruleIdx")
		keywords = uci:get("parental_ex", rule_ind , "keyword")
		mac_list2 = uci:get("parental_ex", rule_ind , "mac_list")
		macaddr_list2 = uci:get("parental_ex", rule_ind , "src_mac")
		luci.template.render("expert_configuration/ParentalControl_Edit",{keywords = keywords, selectindx = selectindx, rule=rule_ind,macaddr_list=macaddr_list, macaddr_list2 = macaddr_list2, mac_list=mac_list,mac_list2 = mac_list2,time0=time0,time1=time1,time2=time2,time3=time3,time4=time4,time5=time5,time6=time6,time7=time7,time8=time8,time9=time9,time10=time10,time11=time11,time12=time12,time13=time13,time14=time14,time15=time15,time16=time16,time17=time17,time18=time18,time19=time19,time20=time20,time21=time21,time22=time22,time23=time23})
	end

	if apply then

		local rule_enable = luci.http.formvalue("rule_enable")
		local domain_list = luci.http.formvalue("DomainList_str")
		local domain_mac_list = luci.http.formvalue("DomainList_str_mac")
		uci:set("parental_ex", rule_ind, "mac_list", domain_list)
		uci:set("parental_ex", rule_ind, "src_mac", domain_mac_list)

		if not(rule_enable) then
			uci:set("parental_ex", rule_ind, "enable", "0")
			uci:set("parental_ex", rule_ind, "timestamp", "0")
		else
			uci:set("parental_ex", rule_ind, "enable", "1")
		end

		local rule_name = luci.http.formvalue("rule_name")

		rule_name = checkInjection(rule_name)
		if rule_name ~= false then

			time0 = luci.http.formvalue("t0")
			time1 = luci.http.formvalue("t1")
			time2 = luci.http.formvalue("t2")
			time3 = luci.http.formvalue("t3")
			time4 = luci.http.formvalue("t4")
			time5 = luci.http.formvalue("t5")
			time6 = luci.http.formvalue("t6")
			time7 = luci.http.formvalue("t7")
			time8 = luci.http.formvalue("t8")
			time9 = luci.http.formvalue("t9")
			time10 = luci.http.formvalue("t10")
			time11 = luci.http.formvalue("t11")
			time12 = luci.http.formvalue("t12")
			time13 = luci.http.formvalue("t13")
			time14 = luci.http.formvalue("t14")
			time15 = luci.http.formvalue("t15")
			time16 = luci.http.formvalue("t16")
			time17 = luci.http.formvalue("t17")
			time18 = luci.http.formvalue("t18")
			time19 = luci.http.formvalue("t19")
			time20 = luci.http.formvalue("t20")
			time21 = luci.http.formvalue("t21")
			time22 = luci.http.formvalue("t22")
			time23 = luci.http.formvalue("t23")

			uci:set("parental_ex", rule_ind, "name", rule_name)

			uci:set("parental_ex", rule_ind, "time0", time0)
			uci:set("parental_ex", rule_ind, "time1", time1)
			uci:set("parental_ex", rule_ind, "time2", time2)
			uci:set("parental_ex", rule_ind, "time3", time3)
			uci:set("parental_ex", rule_ind, "time4", time4)
			uci:set("parental_ex", rule_ind, "time5", time5)
			uci:set("parental_ex", rule_ind, "time6", time6)
			uci:set("parental_ex", rule_ind, "time7", time7)
			uci:set("parental_ex", rule_ind, "time8", time8)
			uci:set("parental_ex", rule_ind, "time9", time9)
			uci:set("parental_ex", rule_ind, "time10", time10)
			uci:set("parental_ex", rule_ind, "time11", time11)
			uci:set("parental_ex", rule_ind, "time12", time12)
			uci:set("parental_ex", rule_ind, "time13", time13)
			uci:set("parental_ex", rule_ind, "time14", time14)
			uci:set("parental_ex", rule_ind, "time15", time15)
			uci:set("parental_ex", rule_ind, "time16", time16)
			uci:set("parental_ex", rule_ind, "time17", time17)
			uci:set("parental_ex", rule_ind, "time18", time18)
			uci:set("parental_ex", rule_ind, "time19", time19)
			uci:set("parental_ex", rule_ind, "time20", time20)
			uci:set("parental_ex", rule_ind, "time21", time21)
			uci:set("parental_ex", rule_ind, "time22", time22)
			uci:set("parental_ex", rule_ind, "time23", time23)

			local url_str = luci.http.formvalue("url_str")

			if not url_str  then url_str="" end

			url_str = checkInjection(url_str)
			if url_str ~= false then
				uci:set("parental_ex",rule_ind,"keyword",url_str)
			end

			local service_act = luci.http.formvalue("service_act")
			if  (service_act == "block")  then
				uci:set("parental_ex",rule_ind,"service_act","block")
			else
				uci:set("parental_ex",rule_ind,"service_act","allow")
			end

			uci:commit("parental_ex")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			uci:apply("parental_ex")

		end --if rule_name ~= false then
		parental_control()
	end

	if apply2 then

		rule_ind = uci:get("parental_ex", "general" , "ruleIdx")

		local rule_enable = luci.http.formvalue("rule_enable")
		local domain_list = luci.http.formvalue("DomainList_str")
		local domain_mac_list = luci.http.formvalue("DomainList_str_mac")

		uci:set("parental_ex", rule_ind, "src_mac", domain_mac_list)
		uci:set("parental_ex", rule_ind, "mac_list", domain_list)

		if not(rule_enable) then
			uci:set("parental_ex", rule_ind, "enable", "0")
		else
			uci:set("parental_ex", rule_ind, "enable", "1")
		end

		local rule_name = luci.http.formvalue("rule_name")

		rule_name = checkInjection(rule_name)
		if rule_name ~= false then

			time0 = luci.http.formvalue("t0")
			time1 = luci.http.formvalue("t1")
			time2 = luci.http.formvalue("t2")
			time3 = luci.http.formvalue("t3")
			time4 = luci.http.formvalue("t4")
			time5 = luci.http.formvalue("t5")
			time6 = luci.http.formvalue("t6")
			time7 = luci.http.formvalue("t7")
			time8 = luci.http.formvalue("t8")
			time9 = luci.http.formvalue("t9")
			time10 = luci.http.formvalue("t10")
			time11 = luci.http.formvalue("t11")
			time12 = luci.http.formvalue("t12")
			time13 = luci.http.formvalue("t13")
			time14 = luci.http.formvalue("t14")
			time15 = luci.http.formvalue("t15")
			time16 = luci.http.formvalue("t16")
			time17 = luci.http.formvalue("t17")
			time18 = luci.http.formvalue("t18")
			time19 = luci.http.formvalue("t19")
			time20 = luci.http.formvalue("t20")
			time21 = luci.http.formvalue("t21")
			time22 = luci.http.formvalue("t22")
			time23 = luci.http.formvalue("t23")

			uci:set("parental_ex", rule_ind, "name", rule_name)

			uci:set("parental_ex", rule_ind, "time0", time0)
			uci:set("parental_ex", rule_ind, "time1", time1)
			uci:set("parental_ex", rule_ind, "time2", time2)
			uci:set("parental_ex", rule_ind, "time3", time3)
			uci:set("parental_ex", rule_ind, "time4", time4)
			uci:set("parental_ex", rule_ind, "time5", time5)
			uci:set("parental_ex", rule_ind, "time6", time6)
			uci:set("parental_ex", rule_ind, "time7", time7)
			uci:set("parental_ex", rule_ind, "time8", time8)
			uci:set("parental_ex", rule_ind, "time9", time9)
			uci:set("parental_ex", rule_ind, "time10", time10)
			uci:set("parental_ex", rule_ind, "time11", time11)
			uci:set("parental_ex", rule_ind, "time12", time12)
			uci:set("parental_ex", rule_ind, "time13", time13)
			uci:set("parental_ex", rule_ind, "time14", time14)
			uci:set("parental_ex", rule_ind, "time15", time15)
			uci:set("parental_ex", rule_ind, "time16", time16)
			uci:set("parental_ex", rule_ind, "time17", time17)
			uci:set("parental_ex", rule_ind, "time18", time18)
			uci:set("parental_ex", rule_ind, "time19", time19)
			uci:set("parental_ex", rule_ind, "time20", time20)
			uci:set("parental_ex", rule_ind, "time21", time21)
			uci:set("parental_ex", rule_ind, "time22", time22)
			uci:set("parental_ex", rule_ind, "time23", time23)

			local url_str = luci.http.formvalue("url_str")

			if not url_str  then url_str="" end

			url_str = checkInjection(url_str)
			if url_str ~= false then
				uci:set("parental_ex",rule_ind,"keyword",url_str)
			end

			local service_act = luci.http.formvalue("service_act")
			if  (service_act == "block")  then
				uci:set("parental_ex",rule_ind,"service_act","block")
			else
				uci:set("parental_ex",rule_ind,"service_act","allow")
			end

			uci:commit("parental_ex")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			uci:apply("parental_ex")
		end

		if "New" == editID then
			local count = 1 + uci:get("parental_ex", rule_ind , "service_count")
			uci:set("parental_ex",rule_ind.."_service"..count,"parental_netservice"..rule_ind)
			uci:set("parental_ex",rule_ind,"service_count",count)
			editID = rule_ind.."_service"..count
		end

		local service_name = luci.http.formvalue("service_name")
		service_name = checkInjection(service_name)
		local service_proto = luci.http.formvalue("service_proto")
		service_proto = checkInjection(service_proto)

		if service_name ~= false and service_proto ~= false then
			if service_name ~= "UserDefined" then
				uci:set("parental_ex",editID ,"name",service_name)
				uci:set("parental_ex",editID ,"proto",service_proto)
			end

			local service_port
			if service_name == "UserDefined" then
				service_port = luci.http.formvalue("service_port")
				local user_define_name = luci.http.formvalue("user_define_name")
				user_define_name = checkInjection(user_define_name)
				if user_define_name ~= false  and string.match(service_port, "(%d+)") then
					service_port = string.match(service_port, "(%d+)")
					uci:set("parental_ex",editID ,"name",service_name)
					uci:set("parental_ex",editID ,"proto",service_proto)
					uci:set("parental_ex",editID ,"user_define_name",user_define_name)
				end
			elseif service_name == "XboxLive" then
				service_port = "3074"
			elseif service_name == "HTTP" then
				service_port = "80"
			elseif service_name == "HTTPS" then
				service_port = "443"
			elseif service_name == "ISPEC_IKE" then
				service_port = "500,4500"
			elseif service_name == "MicrosoftRemoteDesktop" then
				service_port = "3389"
			elseif service_name == "NetMeeting" then
				service_port = "1720"
			elseif service_name == "POP3" then
				service_port = "110"
			elseif service_name == "PPTP" then
				service_port = "1723"
			elseif service_name == "SMTP" then
				service_port = "25"
			elseif service_name == "SSH" then
				service_port = "22"
			else
				service_port = "5500,5800,5900-5910"
			end
			
			sys.exec("cat /tmp/dhcp.leases |awk -F ' ' '{ print $2}' >/tmp/maclist")
			editmac = uci:get("parental_ex", rule_ind , "src_mac")

			local idx_3 = 0
			for mac in io.lines("/tmp/maclist") do
				if ( mac == editmac) then
					selectindx = idx_3
					uci:set("parental_ex",rule_ind,"src_type","single")
					break
				else
					selectindx = "none"
				end
				idx_3 = idx_3 + 1
			end

			if ( selectindx == "none") and ( editmac ~= "00:00:00:00:00:00" ) then
				uci:set("parental_ex",rule_ind,"src_type","custom")
			end

			uci:set("parental_ex",editID ,"port",service_port)
			uci:commit("parental_ex")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			uci:apply("parental_ex")
		end --if service_name ~= false and service_proto ~= false then

		rule_ind = uci:get("parental_ex", "general" , "ruleIdx")
		keywords = uci:get("parental_ex", rule_ind , "keyword")

		mac_list2 = uci:get("parental_ex", rule_ind , "mac_list")
		macaddr_list2 = uci:get("parental_ex", rule_ind , "src_mac")


		sys.exec("rm /tmp/namelist")

		luci.template.render("expert_configuration/ParentalControl_Edit",{keywords = keywords, selectindx = selectindx, rule=rule_ind,macaddr_list=macaddr_list, mac_list=mac_list, macaddr_list2=macaddr_list2, mac_list2 = mac_list2,time0=time0,time1=time1,time2=time2,time3=time3,time4=time4,time5=time5,time6=time6,time7=time7,time8=time8,time9=time9,time10=time10,time11=time11,time12=time12,time13=time13,time14=time14,time15=time15,time16=time16,time17=time17,time18=time18,time19=time19,time20=time20,time21=time21,time22=time22,time23=time23})
	end

	if Back then
		luci.template.render("expert_configuration/ParentalControl")
	end

end

function parental_monitor()

	local sysSubmit = luci.http.formvalue("sysSubmit")
	local delete = luci.http.formvalue("delete")
	sys.exec("touch /etc/config/parental_monitor")
	local add = luci.http.formvalue("add")
	sys.exec("touch /etc/config/sendmail")

	if delete then
		local del_rule = "rule" .. delete
		local rul_num = tonumber(string.match(del_rule,"%d+"))
		local cur_num = rul_num
		uci:delete("parental_monitor", del_rule)

		local count = uci:get("parental_monitor","general", "count")
		local num = count-cur_num

		for i=num,1,-1 do
			local rules = "rule"..cur_num+1
			local new_rule = "rule"..cur_num
			local old_data = {}
			old_data=uci:get_all("parental_monitor", rules)

			if old_data then
				uci:set("parental_monitor", new_rule, "parental_rule")
				uci:tset("parental_monitor", new_rule, old_data)

				uci:delete("parental_monitor", rules)
				uci:commit("parental_monitor")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				cur_num =cur_num+1
			end
		end
		uci:set("parental_monitor", "general", "count", count-1)
		uci:commit("parental_monitor")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("parental_monitor")
	end

	if sysSubmit then
		local email = luci.http.formvalue("Email")
		local server = luci.http.formvalue("MailServerAddress")
		local port = luci.http.formvalue("MailServerPort")
		local username = luci.http.formvalue("AuthenticationUsername")
		local password = luci.http.formvalue("AuthenticationPassword")
		local account = luci.http.formvalue("AccountEmailAddress2")
		sys.exec("echo "..account.." > /tmp/mail_account")
		sys.exec("cat /tmp/mail_account | awk '{FS=\"@\"} {print $2}' > /tmp/mail_at")
		mail_at = io.open("/tmp/mail_at", "r")
		local mails = mail_at:read("*line")
		local mail_at_val = "@" .. mails
		mail_at:close()
		sys.exec("rm /tmp/mail_account /tmp/mail_at")

		uci:set("sendmail", "mail_server_setup", "sendmail")
		uci:set("sendmail", "mail_server_setup", "server", server)
		uci:set("sendmail", "mail_server_setup", "port", port)
		uci:set("sendmail", "mail_server_setup", "username", username)
		uci:set("sendmail", "mail_server_setup", "password", password)
		uci:set("sendmail", "mail_server_setup", "account", account)
		uci:set("sendmail", "mail_server_setup", "mail_at", mail_at_val)
		uci:set("sendmail", "mail_server_setup", "sendmail")
		uci:set("sendmail", "send_to_1", "email")
		uci:set("sendmail", "send_to_1", "email", email)
		uci:commit("sendmail")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("sendmail")

		local parentalEnable = luci.http.formvalue("parental_state")

		local rule_index = uci:get("parental_monitor", "general" , "ruleIdx")
		local num_count = uci:get("parental_monitor", "general" , "count")

		uci:set("parental_monitor", "general", "parental_general")
		uci:set("parental_monitor", "general" , "enable", parentalEnable)
		
		for i=1,num_count do
			uci:set("parental_monitor", "rule"..i , "email", email)
			uci:set("parental_monitor", "rule"..i , "sent", "0")
		end

		uci:commit("parental_monitor")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("parental_monitor")
	end
		-- if add then
			-- local email = luci.http.formvalue("Email")

			-- local emails_count = uci:get("sendmail", "mail_server_setup", "emails_count")
			-- if not emails_count then
				-- emails_count = 0
			-- end
			-- emails_count = emails_count+1
			-- local send_to = "send_to_"..emails_count
			-- uci:set("sendmail", send_to, "sendmail")
			-- uci:set("sendmail", send_to, "email", email)
			-- uci:set("sendmail", "mail_server_setup", "sendmail")
			-- uci:set("sendmail", "mail_server_setup", "emails_count", emails_count)

			-- uci:save("sendmail")
			-- uci:commit("sendmail")
			-- uci:apply("sendmail")
		-- end
	luci.template.render("expert_configuration/ParentalMonitor")

end

function parental_monitor_edit()

	local edit = luci.http.formvalue("edit")
	local Back = luci.http.formvalue("Back")
	local apply = luci.http.formvalue("apply")
	local delete = luci.http.formvalue("delete")
	sys.exec("touch /etc/config/parental_monitor")
	sys.exec("touch /etc/config/sendmail")

	if edit then
		if not (edit) then
			edit = 0
		end

		rule_ind="rule"..edit+1
		local tmp_count=edit+1
		local rule_count=uci:get("parental_monitor", "general" , "count")
		
		if not rule_count then
			rule_count = 0
		end
		
		if (tonumber(rule_count) < tonumber(tmp_count)) then
			uci:set("parental_monitor", "general", "parental_general")
			uci:set("parental_monitor","general","count",edit+1)
			uci:set("parental_monitor",rule_ind,"parental_rule")
			uci:set("parental_monitor",rule_ind,"mac_list","")
			uci:set("parental_monitor",rule_ind,"stop_hour","24")
			uci:set("parental_monitor",rule_ind,"weekdays","Mon,Tue,Wed,Thu,Fri,Sat,Sun")
		end

		local idx = 0
		local mac_list=""
		sys.exec("cat /tmp/dhcp.leases |awk -F ' ' '{ print $2}' >/tmp/maclist")
		sys.exec("cat /tmp/dhcp.leases |awk -F ' ' '{ print $4}' >/tmp/namelist")

		uci:set("parental_monitor", "general", "ruleIdx", rule_ind)
		uci:commit("parental_monitor")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		keywords = uci:get("parental_monitor", rule_ind , "mac_list")

		for line2 in io.lines("/tmp/namelist") do
			if keywords then
				local list = string.split(keywords, ';')
				local least = 0

				for i, s in ipairs(list) do
					if line2 == s then
						least = least + 1
					end
				end

				if least == 0 then
					mac_list=mac_list..line2..";"
				end
			else
				mac_list=mac_list..line2..";"
			end
		end

		sys.exec("rm /tmp/maclist")
		sys.exec("rm /tmp/namelist")

		local name_count = uci:get("parental_ex","general","count")
		local children_name = ""

		for i=1,name_count do
			name = uci:get("parental_ex", "rule" ..i , "name")
			if name then
				children_name=children_name..name..";"
			end
		end

		luci.template.render("expert_configuration/ParentalMonitor_Edit",{keywords = keywords,  rule=rule_ind , mac_list=children_name})
	else
		rule_ind = uci:get("parental_monitor", "general" , "ruleIdx")
	end

	if apply then
		local rule_enable = luci.http.formvalue("rule_enable")

		if not (rule_enable) then
			rule_enable = 0
		else
			rule_enable = 1
		end

		-- local children_name = luci.http.formvalue("children_name")
		local domain_list = luci.http.formvalue("src_select")
		local email = uci:get("sendmail","send_to_1","email")

		uci:set("parental_monitor", rule_ind, "parental_rule")
		uci:set("parental_monitor", rule_ind, "enable", rule_enable)
		-- uci:set("parental_monitor", rule_ind, "name", children_name)
		uci:set("parental_monitor", rule_ind, "mac_list", domain_list)
		uci:set("parental_monitor", rule_ind, "email", email)
		uci:set("parental_monitor", rule_ind,"sent", "0")
		uci:set("parental_monitor", "general", "parental_general")

		local rule_ind2 = luci.http.formvalue("SelectIndex")
		rule_ind2 = rule_ind2 +1
		rule_ind2 = "rule"..rule_ind2
		device = uci:get("parental_ex",rule_ind2,"mac_list")
		uci:set("parental_monitor",rule_ind,"device",device)
		mac = uci:get("parental_ex",rule_ind2,"src_mac")
		uci:set("parental_monitor",rule_ind,"mac",mac)

		local weekdays = ""
		local Date_Mon = luci.http.formvalue("Date_Mon")
		local Date_Tue = luci.http.formvalue("Date_Tue")
		local Date_Wed = luci.http.formvalue("Date_Wed")
		local Date_Thu = luci.http.formvalue("Date_Thu")
		local Date_Fri = luci.http.formvalue("Date_Fri")
		local Date_Sat = luci.http.formvalue("Date_Sat")
		local Date_Sun = luci.http.formvalue("Date_Sun")

		if Date_Mon then
			weekdays = weekdays.."Mon,"
		end

		if Date_Tue then
			weekdays = weekdays.."Tue,"
		end

		if Date_Wed then
			weekdays = weekdays.."Wed,"
		end

		if Date_Thu then
			weekdays = weekdays.."Thu,"
		end

		if Date_Fri then
			weekdays = weekdays.."Fri,"
		end

		if Date_Sat then
			weekdays = weekdays.."Sat,"
		end

		if Date_Sun then
			weekdays = weekdays.."Sun"
		else
			weekdays = string.sub(weekdays,1,-2)
		end

		uci:set("parental_monitor", rule_ind, "weekdays", weekdays)

		local StartHour = luci.http.formvalue("StartHour")
		local StartMin = luci.http.formvalue("StartMin")
		local EndHour = luci.http.formvalue("EndHour")
		local EndMin = luci.http.formvalue("EndMin")
		uci:set("parental_monitor", rule_ind, "start_hour", StartHour)
		uci:set("parental_monitor", rule_ind, "start_min", StartMin)
		uci:set("parental_monitor", rule_ind, "stop_hour", EndHour)
		uci:set("parental_monitor", rule_ind, "stop_min", EndMin)

		uci:save("parental_monitor")
		uci:commit("parental_monitor")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("parental_monitor")

		luci.template.render("expert_configuration/ParentalMonitor")
	end

	if Back then
		luci.template.render("expert_configuration/ParentalMonitor")
	end

end

--Eten dynamic DNS
function action_ddns()
	local apply = luci.http.formvalue("apply")

	if apply then
		local provider = luci.http.formvalue("DDNSProvider")
		local update   = luci.http.formvalue("DDNSUpdate")
		local host     = luci.http.formvalue("DDNSHost")
		local user     = luci.http.formvalue("DDNSUser")
		local passwd   = luci.http.formvalue("DDNSPasswd")
		local entry = nil

		uci:foreach("updatedd", "updatedd", function( section )
			entry = section[".name"]
			-- provider = checkInjection(provider) --mark the line, because of customer request to support "-"
			if provider ~= false then
				uci:set("updatedd", entry, "service", provider)
			end
		end)

		if "enable" == update then
			uci:set("updatedd", entry, "update", "1")
		else
			uci:set("updatedd", entry, "update", "0")
		end

		-- host = checkInjection(host) --mark the line, because of customer request to support "-"
		if host ~= false then
			uci:set("updatedd", entry, "host", host)
		end

		-- user = checkInjection(user) --mark the line, because of customer request to support "-"
		if user ~= false then
			uci:set("updatedd", entry, "username", user)
		end

		-- passwd = checkInjection(passwd) --mark the line, because of customer request to support "-"
		if passwd ~= false then
			uci:set("updatedd", entry, "password", passwd)
		end

		uci:save("updatedd")
		uci:commit("updatedd")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("updatedd")
	end

	luci.template.render("expert_configuration/ddns")
end
--Eten END
--
--Eten Static Route
function action_static_route()
	local apply = luci.http.formvalue("apply")
	local delete = luci.http.formvalue("delete")
	local submitType = luci.http.formvalue("SRSubmitType")

	if apply then
		if "edit" == submitType then
			local editID = luci.http.formvalue("SREditID")
			local enable = luci.http.formvalue("SREditRadio")
			local name   = luci.http.formvalue("SREditName")
			local dest   = luci.http.formvalue("SREditDest")
			local mask   = luci.http.formvalue("SREditMask")
			local gw     = luci.http.formvalue("SREditGW")
			local entryName = nil

			if "New" == editID then
				editID = uci:get("route", "general", "routes_count") + 1
				uci:set("route", "general", "routes_count", editID)
				entryName = "route" .. editID
				uci:set("route", entryName, "route")
				uci:set("route", entryName, "new", "1")
			else
				entryName = editID
				uci:set("route", entryName, "edit", "1")
				uci:set("route", entryName, "dest_ip_old", uci:get("route", entryName, "dest_ip"))
				uci:set("route", entryName, "netmask_old", uci:get("route", entryName, "netmask"))
				uci:set("route", entryName, "gateway_old", uci:get("route", entryName, "gateway"))
				uci:set("route", entryName, "enable_old", uci:get("route", entryName, "enable"))
			end

			name = checkInjection(name)
			if name ~= false then
				uci:set("route", entryName, "name", name)

				if string.match(dest, "(%d+.%d+.%d+.%d+)") then
					dest = string.match(dest, "(%d+.%d+.%d+.%d+)")
					uci:set("route", entryName, "dest_ip", dest)
				end

				if string.match(mask, "(%d+.%d+.%d+.%d+)") then
					mask = string.match(mask, "(%d+.%d+.%d+.%d+)")
					uci:set("route", entryName, "netmask", mask)
				end

				if string.match(gw, "(%d+.%d+.%d+.%d+)") then
					gw = string.match(gw, "(%d+.%d+.%d+.%d+)")
					uci:set("route", entryName, "gateway", gw)
				end

				if not ("enable" == enable) then
					uci:set("route", entryName, "enable", 0)
				else
					uci:set("route", entryName, "enable", 1)
				end

				uci:save("route")
				uci:commit("route")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				uci:apply("route")
			end --if name ~= false then

		elseif "table" == submitType then

			local list = luci.http.formvalue("SRDeleteIDs")

			if not ( "" == list ) then
				local i, j = 0, 0

				while true do
				        j = string.find(list, ",", i + 1)
		        		if j == nil then break end
					uci:set("route", string.sub(list, i + 1, j - 1 ), "delete", "1")
				        i = j
				end

				uci:save("route")
				uci:commit("route")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				uci:apply("route")
			end

		end
	end

	if delete then
		uci:set("route", "route" .. delete, "delete", "1")
		uci:commit("route")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("route")
	end

	luci.template.render("expert_configuration/static_route")
end
--Eten Static Route END

function action_portfw()
	local new = luci.http.formvalue("new")
	local apply = luci.http.formvalue("apply")
	local add = luci.http.formvalue("add")
	local remove = luci.http.formvalue("remove")

	if new then
		uci:revert("nat")
		--uci:revert("nat_new")
	end

	if apply then
		local enabled = luci.http.formvalue("enabled")

		uci:set("nat","general","nat",enabled)

		local serChange = luci.http.formvalue("serChange")
		local changeToSerIP = luci.http.formvalue("changeToSerIP")
		local last_changeToSerIP
		local changeToSer = 0
		if (serChange=="change") then
			if not (changeToSerIP=="") then
				local changeToSer = 1
				uci:set("nat","general","changeToSer",changeToSer)
				uci:set("nat","general","changeToSerIP",changeToSerIP)
				--uci:set("nat_new","general_new","changeToSer",changeToSer)
				--uci:set("nat_new","general_new","changeToSerIP",changeToSerIP)
			end
		else
			last_changeToSerIP = uci:get("nat","general","changeToSerIP")
			if last_changeToSerIP then
				uci:delete("nat","general","changeToSerIP")
				uci:set("nat","general","last_changeToSerIP",last_changeToSerIP)
				--uci:set("nat_new","general_new","last_changeToSerIP",last_changeToSerIP)
			end
			uci:set("nat","general","changeToSer",changeToSer)
			--uci:set("nat_new","general_new","changeToSer",changeToSer)
		end

		uci:commit("nat")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("nat")
		--uci:commit("nat_new")
		--uci:apply("nat_new")
	end

	if add then
		local enabled = 1
		local srvIndex = luci.http.formvalue("srvIndex")
		local srvName,intPort,protocol = fetchProtocolInfo(srvIndex)
		local extPort = luci.http.formvalue("srvPort_L")

		if (protocol=="") then
			protocol = luci.http.formvalue("protocol")
		end

		local srvIp = luci.http.formvalue("srvIp")
		local wake_up = 1
		local wan = 1
		local wan_ip = "0.0.0.0"
		local rules_count = uci:get("nat","general","rules_count")
		local NextRulePos = uci:get("nat","general","NextRulePos")
		rules_count = rules_count+1
		local rules = "rule"..rules_count

		if srvIndex == "12" then
			if intPort == "" then
				intPort = extPort
			end
		else
			extPort = intPort
		end

		uci:set("nat",rules,"nat")
		uci:set("nat",rules,"StatusEnable",enabled)
		uci:set("nat",rules,"CurPos",NextRulePos)
		uci:set("nat",rules,"service",srvName)
		uci:set("nat",rules,"service_idx",srvIndex)
		uci:set("nat",rules,"protocol",protocol)
		uci:set("nat",rules,"port",intPort)
		uci:set("nat",rules,"local_port",extPort)
		uci:set("nat",rules,"wan",wan)
		uci:set("nat",rules,"wan_ip",wan_ip)
		uci:set("nat",rules,"local_ip",srvIp)
		uci:set("nat",rules,"wake_up",wake_up)
		uci:set("nat","general","rules_count",rules_count)

		uci:save("nat")
		uci:commit("nat")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		sys.exec("/sbin/parsePort.sh")
		uci:apply("nat")

		-- must reset remote management of WWW from port 80 to 8080
--		if srvIndex=="0" then
		if extPort=="80" or extPort==80 then
			local infIdx = uci:get("firewall", "remote_www", "interface")
			local cfgCheck = uci:get("firewall", "remote_www", "client_check")
			local remote_www_port = uci:get("firewall", "remote_www", "port")

			if remote_www_port=="80" then
				local infCmd  = ""
				local infDCmd = ""
				local addrCmd = ""

				if "2" == infIdx then
					-- LAN
					infCmd=" -i br-lan "
					if cfgCheck ~= "1" then
						infDCmd=" ! -i br-lan "
					end
				elseif "3" == infIdx then
					-- WAN LAN
					infCmd=" ! -i br-lan "
					if cfgCheck ~= "1" then
						infDCmd=" -i br-lan "
					end
				end

				if not ("0" == uci:get("firewall", "remote_www", "client_check")) then
					addrCmd=" -s " .. uci:get("firewall", "remote_www", "client_addr") .. " "
				end

				--sys.exec("/usr/sbin/iptables -t filter -D INPUT " .. infCmd .. addrCmd .. " -p tcp --dport " .. uci:get("firewall", "remote_www", "port") .. " -j ACCEPT 2> /dev/null")
				--sys.exec("/usr/sbin/iptables -t filter -D INPUT " .. infDCmd .. " -p tcp --dport " .. uci:get("firewall", "remote_www", "port") .. " -j DROP 2> /dev/null")

				uci:set("firewall", "remote_www", "port", 8080)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				--sys.exec("/etc/init.d/uhttpd restart 2>/dev/null")
				uci:apply("uhttpd")
			end
		end
		-- must reset remote management of Telnet from port 23 to 2323
		if srvIndex=="5" then
			local remote_telnet_port = uci:get("firewall", "remote_telnet", "port")
			if remote_telnet_port=="23" then
				sys.exec("/etc/init.d/telnet stop 2>/dev/null")
				uci:set("firewall", "remote_telnet", "port", 2323)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				sys.exec("/etc/init.d/telnet start 2>/dev/null")
			end
		end

		if srvIndex=="1" then
			local remote_https_port = uci:get("firewall", "remote_https", "port")
			if remote_https_port=="443" then
				uci:set("firewall", "remote_https", "port", 44343)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("rm /tmp/luci-sessions/ -rf")
				uci:apply("uhttpd")
			end
		end
		--[[
		-----nat_new-----
		local new_rule = 1
		local new_rules_count = uci:get("nat_new","general_new","rules_count")
		new_rules_count = new_rules_count+1
		local new_rules = "rule_new"..new_rules_count

		uci:set("nat_new",new_rules,"nat")
		uci:set("nat_new",new_rules,"new_rule",new_rule)
		uci:set("nat_new",new_rules,"CurPos",NextRulePos)
		uci:set("nat_new",new_rules,"service",srvName)
		uci:set("nat_new",new_rules,"port",extPort)
		uci:set("nat_new",new_rules,"wan",wan)
		uci:set("nat_new",new_rules,"wan_ip",wan_ip)
		uci:set("nat_new",new_rules,"local_ip",srvIp)
		uci:set("nat_new",new_rules,"StatusEnable",enabled)
		uci:set("nat_new","general_new","rules_count",new_rules_count)
		uci:save("nat_new")
		uci:commit("nat_new")
		uci:apply("nat_new")

		NextRulePos = NextRulePos+1
		uci:set("nat","general","NextRulePos",NextRulePos)
		uci:commit("nat")
		uci:apply("nat")
		]]--
	end

	if remove then
		local del_rule = remove
		local rul_num = tonumber(string.match(del_rule,"%d+"))
		local cur_num = rul_num
		local rm_curpos = uci:get("nat",del_rule,"CurPos")
		local extPort = uci:get("nat",del_rule,"local_port")
		uci:delete("nat",del_rule)

		local rules_count = uci:get("nat","general","rules_count")
		local NextRulePos = uci:get("nat","general","NextRulePos")
		local num = rules_count-cur_num

		for i=num,1,-1 do
			local rules = "rule"..cur_num+1
			local new_rule = "rule"..cur_num
			local old_data = {}
			old_data=uci:get_all("nat",rules)

			if old_data then
				uci:set("nat",new_rule,"nat")
				uci:tset("nat",new_rule,old_data)

				local edit_CurPos=uci:get("nat",new_rule,"CurPos")
				uci:set("nat",new_rule,"CurPos",edit_CurPos-1)

				uci:delete("nat",rules)
				uci:commit("nat")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				cur_num =cur_num+1
			end
		end
		uci:set("nat","general","rules_count",rules_count-1)
		uci:set("nat","general","NextRulePos",NextRulePos-1)
		uci:commit("nat")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		sys.exec("/sbin/parsePort.sh")
		uci:apply("nat")

		-- must reset remote management of WWW from port 8080 to 80
		if extPort=="80" then
			local infIdx = uci:get("firewall", "remote_www", "interface")
			local cfgCheck = uci:get("firewall", "remote_www", "client_check")
			local remote_www_port = uci:get("firewall", "remote_www", "port")

			if remote_www_port=="8080" then
				local infCmd  = ""
				local infDCmd = ""
				local addrCmd = ""

				if "2" == infIdx then
					-- LAN
					infCmd=" -i br-lan "
					if cfgCheck ~= "1" then
						infDCmd=" ! -i br-lan "
					end
				elseif "3" == infIdx then
					-- WAN LAN
					infCmd=" ! -i br-lan "
					if cfgCheck ~= "1" then
						infDCmd=" -i br-lan "
					end
				end

				if not ("0" == uci:get("firewall", "remote_www", "client_check")) then
					addrCmd=" -s " .. uci:get("firewall", "remote_www", "client_addr") .. " "
				end

				--sys.exec("/usr/sbin/iptables -t filter -D INPUT " .. infCmd .. addrCmd .. " -p tcp --dport " .. uci:get("firewall", "remote_www", "port") .. " -j ACCEPT 2> /dev/null")
				--sys.exec("/usr/sbin/iptables -t filter -D INPUT " .. infDCmd .. " -p tcp --dport " .. uci:get("firewall", "remote_www", "port") .. " -j DROP 2> /dev/null")

				uci:set("firewall", "remote_www", "port", 80)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				--sys.exec("/etc/init.d/uhttpd restart 2>/dev/null")
				uci:apply("uhttpd")
			end
		end
		-- must reset remote management of Telnet from port 2323 to 23
		if extPort=="23" then
			local remote_telnet_port = uci:get("firewall", "remote_telnet", "port")
			if remote_telnet_port=="2323" then
				sys.exec("/etc/init.d/telnet stop 2>/dev/null")
				uci:set("firewall", "remote_telnet", "port", 23)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				sys.exec("/etc/init.d/telnet start 2>/dev/null")
			end
		end
		
		if extPort=="443" then
			local remote_https_port = uci:get("firewall", "remote_https", "port")
			if remote_https_port=="44343" then
				uci:set("firewall", "remote_https", "port", 443)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("rm /tmp/luci-sessions/ -rf")
				uci:apply("uhttpd")
			end
		end
		--[[
		-----nat_new-----
		local delete_rule=1
		local new_rules_count = uci:get("nat_new","general_new","rules_count")
		new_rules_count = new_rules_count+1
		local new_rules = "rule_new"..new_rules_count

		uci:set("nat_new",new_rules,"nat")
		uci:set("nat_new",new_rules,"delete_rule",delete_rule)
		uci:set("nat_new",new_rules,"CurPos",rm_curpos)
		uci:set("nat_new","general_new","rules_count",new_rules_count)

		uci:commit("nat_new")
		uci:apply("nat_new")
		]]--
	end

	local sqlite3 = require("lsqlite3")
	local db = sqlite3.open( "/tmp/netprobe.db" )
	local data = ""
	local DevIP = ""
	local DevName = ""

	db:busy_timeout(5000)

	for row in db:nrows("SELECT * FROM Device where [Alive]=1 OR ([Alive]=0 AND [nNotAlive] <= 2); ") do
		if row.IP then
			DevIP = row.IP
		else
			DevIP = "0.0.0.0"
		end

		if row.DevName == nil then
			if row.Manufacture == nil then
				DevName = "Unknown"
			else
				DevName = row.Manufacture
			end
		else
			DevName = row.DevName
		end

		data = string.format("%s=%s;%s", DevName, DevIP, data)
	end

	luci.template.render("expert_configuration/nat_application",{data=data})
end

function action_portfw_edit()

	local apply = luci.http.formvalue("apply")
	local edit = luci.http.formvalue("edit")

	if apply then
		local rules = luci.http.formvalue("rules")
		local enabled = luci.http.formvalue("enabled")
		local srvIndex = luci.http.formvalue("srvIndex")
		local srvName,extPort,protocol = fetchServerInfo(srvIndex)
		local cfgPort = uci:get("nat",rules,"port")

		local srvIp = luci.http.formvalue("srvIp")
		local wake_up = luci.http.formvalue("wake_up")
		local url = luci.dispatcher.build_url("expert","configuration","network","nat","portfw")
		local wan = 1
		local wan_ip = "0.0.0.0"
		local CurPos =uci:get("nat",rules,"CurPos")
		local NextRulePos = uci:get("nat","general","NextRulePos")
		local ori_StatusEnable=uci:get("nat",rules,"StatusEnable")

		if not wake_up then
			wake_up = 0
		end

		local Local_Port = extPort
		if srvIndex=="12" then
			Local_Port = luci.http.formvalue("LocalPort")
		end

		uci:set("nat",rules,"service",srvName)
		uci:set("nat",rules,"service_idx",srvIndex)
		uci:set("nat",rules,"port",extPort)
		uci:set("nat",rules,"local_port",Local_Port)
		uci:set("nat",rules,"protocol",protocol)
		uci:set("nat",rules,"wan",wan)
		uci:set("nat",rules,"wan_ip",wan_ip)
		uci:set("nat",rules,"local_ip",srvIp)
		uci:set("nat",rules,"wake_up",wake_up)

		local rules_count = uci:get("nat","general","rules_count")
		local rul_num = tonumber(string.match(rules,"%d+"))
		local cur_num = rul_num
		local edit_rules
		local edit_rules_curpos
		if enabled=="0" then
			uci:set("nat",rules,"StatusEnable",enabled)
			if not (ori_StatusEnable==enabled) then
				for i=rules_count,1,-1 do
					cur_num = cur_num+1
					edit_rules="rule"..cur_num
					edit_rules_curpos = uci:get("nat",edit_rules,"CurPos")
					if edit_rules_curpos then
						uci:set("nat",edit_rules,"CurPos",edit_rules_curpos-1)
					end
				end
				uci:set("nat","general","NextRulePos",NextRulePos-1)
			end
		elseif enabled=="1" then
			uci:set("nat",rules,"StatusEnable",enabled)
			if not (ori_StatusEnable==enabled) then
				for i=rules_count,1,-1 do
					cur_num = cur_num+1
					edit_rules="rule"..cur_num
					edit_rules_curpos = uci:get("nat",edit_rules,"CurPos")
					if edit_rules_curpos then
						uci:set("nat",edit_rules,"CurPos",edit_rules_curpos+1)
					end
				end
				uci:set("nat","general","NextRulePos",NextRulePos+1)
			end
		end

		uci:commit("nat")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("nat")

		-- must reset remote management of WWW from port 80 to 8080
		if extPort==80 and cfgPort~="80" then
			local infIdx = uci:get("firewall", "remote_www", "interface")
			local cfgCheck = uci:get("firewall", "remote_www", "client_check")
			local remote_www_port = uci:get("firewall", "remote_www", "port")

			if remote_www_port=="80" then
				local infCmd  = ""
				local infDCmd = ""
				local addrCmd = ""

				if "2" == infIdx then
					-- LAN
					infCmd=" -i br-lan "
					if cfgCheck ~= "1" then
						infDCmd=" ! -i br-lan "
					end
				elseif "3" == infIdx then
					-- WAN LAN
					infCmd=" ! -i br-lan "
					if cfgCheck ~= "1" then
						infDCmd=" -i br-lan "
					end
				end

				if not ("0" == uci:get("firewall", "remote_www", "client_check")) then
					addrCmd=" -s " .. uci:get("firewall", "remote_www", "client_addr") .. " "
				end

				--sys.exec("/usr/sbin/iptables -t filter -D INPUT " .. infCmd .. addrCmd .. " -p tcp --dport " .. uci:get("firewall", "remote_www", "port") .. " -j ACCEPT 2> /dev/null")
				--sys.exec("/usr/sbin/iptables -t filter -D INPUT " .. infDCmd .. " -p tcp --dport " .. uci:get("firewall", "remote_www", "port") .. " -j DROP 2> /dev/null")

				uci:set("firewall", "remote_www", "port", 8080)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				--sys.exec("/etc/init.d/uhttpd restart 2>/dev/null")
				uci:apply("uhttpd")
			end
		end
		-- must reset remote management of Telnet from port 23 to 2323
		if extPort==23 and cfgPort~="23" then
			local remote_telnet_port = uci:get("firewall", "remote_telnet", "port")
			if remote_telnet_port=="23" then
				sys.exec("/etc/init.d/telnet stop 2>/dev/null")
				uci:set("firewall", "remote_telnet", "port", 2323)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				sys.exec("/etc/init.d/telnet start 2>/dev/null")
			end
		end

		-- must reset remote management of WWW from port 8080 to 80
		if cfgPort=="80" and extPort~=80 then
			local infIdx = uci:get("firewall", "remote_www", "interface")
			local cfgCheck = uci:get("firewall", "remote_www", "client_check")
			local remote_www_port = uci:get("firewall", "remote_www", "port")

			if remote_www_port=="8080" then
				local infCmd  = ""
				local infDCmd = ""
				local addrCmd = ""

				if "2" == infIdx then
					-- LAN
					infCmd=" -i br-lan "
					if cfgCheck ~= "1" then
						infDCmd=" ! -i br-lan "
					end
				elseif "3" == infIdx then
					-- WAN LAN
					infCmd=" ! -i br-lan "
					if cfgCheck ~= "1" then
						infDCmd=" -i br-lan "
					end
				end

				if not ("0" == uci:get("firewall", "remote_www", "client_check")) then
					addrCmd=" -s " .. uci:get("firewall", "remote_www", "client_addr") .. " "
				end

				--sys.exec("/usr/sbin/iptables -t filter -D INPUT " .. infCmd .. addrCmd .. " -p tcp --dport " .. uci:get("firewall", "remote_www", "port") .. " -j ACCEPT 2> /dev/null")
				--sys.exec("/usr/sbin/iptables -t filter -D INPUT " .. infDCmd .. " -p tcp --dport " .. uci:get("firewall", "remote_www", "port") .. " -j DROP 2> /dev/null")

				uci:set("firewall", "remote_www", "port", 80)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				--sys.exec("/etc/init.d/uhttpd restart 2>/dev/null")
				uci:apply("uhttpd")
			end
		end
		-- must reset remote management of Telnet from port 2323 to 23
		if cfgPort=="23" and extPort~=23 then
			local remote_telnet_port = uci:get("firewall", "remote_telnet", "port")
			if remote_telnet_port=="2323" then
				sys.exec("/etc/init.d/telnet stop 2>/dev/null")
				uci:set("firewall", "remote_telnet", "port", 23)
				uci:save("firewall")
				uci:commit("firewall")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				sys.exec("/etc/init.d/telnet start 2>/dev/null")
			end
		end

		--[[
		-----nat_new-----
		local new_rules_count = uci:get("nat_new","general_new","rules_count")
		new_rules_count = new_rules_count+1
		local new_rules = "rule_new"..new_rules_count
		if enabled=="0" then
			if not (ori_StatusEnable==enabled) then
				local delete_rule = 1
				uci:set("nat_new",new_rules,"nat")
				uci:set("nat_new",new_rules,"delete_rule",delete_rule)
				uci:set("nat_new",new_rules,"CurPos",CurPos)
				uci:set("nat_new","general_new","rules_count",new_rules_count)
			end
		else
			if not (ori_StatusEnable==enabled) then
				local insert_rule = 1
				uci:set("nat_new",new_rules,"nat")
				uci:set("nat_new",new_rules,"insert_rule",insert_rule)
				uci:set("nat_new",new_rules,"service",srvName)
				uci:set("nat_new",new_rules,"port",extPort)
				uci:set("nat_new",new_rules,"wan",wan)
				uci:set("nat_new",new_rules,"wan_ip",wan_ip)
				uci:set("nat_new",new_rules,"local_ip",srvIp)
				uci:set("nat_new",new_rules,"CurPos",CurPos)
				uci:set("nat_new","general_new","rules_count",new_rules_count)
			else
				local edit_rule = 1
				uci:set("nat_new",new_rules,"nat")
				uci:set("nat_new",new_rules,"edit_rule",edit_rule)
				uci:set("nat_new",new_rules,"service",srvName)
				uci:set("nat_new",new_rules,"port",extPort)
				uci:set("nat_new",new_rules,"wan",wan)
				uci:set("nat_new",new_rules,"wan_ip",wan_ip)
				uci:set("nat_new",new_rules,"local_ip",srvIp)
				uci:set("nat_new",new_rules,"CurPos",CurPos)
				uci:set("nat_new","general_new","rules_count",new_rules_count)
			end
		end

		uci:commit("nat_new")
		uci:apply("nat_new")
		]]--
		luci.http.redirect(url)
	end

	if edit then
		local rules = edit
		local enabled = uci:get("nat",rules,"StatusEnable")
		local protocol = uci:get("nat",rules,"protocol")
		local extPort = uci:get("nat",rules,"port")
		local LocalPort = uci:get("nat",rules,"local_port")
		local srvName = uci:get("nat",rules,"service")
		local srvIdx = uci:get("nat",rules,"service_idx")
		local srvIp = uci:get("nat",rules,"local_ip")
		local wake_up = uci:get("nat",rules,"wake_up")
		local url = luci.dispatcher.build_url("expert","configuration","network","nat","portfw","portfw_edit")

		luci.http.redirect(url .. "?" .. "service_name=" .. srvName .. "&rules=" .. rules .. "&enabled=" .. enabled .. "&protocol=" .. protocol .. "&srvIdx=" .. srvIdx .. "&external_port=" .. extPort .. "&local_port=" .. LocalPort .. "&server_ip=" .. srvIp .. "&wake_up=" .. wake_up .. "&rt=" .. 1 .. "&errmsg=test!!")
		return
	end

	luci.template.render("expert_configuration/nat_application_edit")
end


function port_trigger()

	local apply = luci.http.formvalue("apply")

	if apply then

		sys.exec("echo -n > /etc/config/portTrigger")

		local trigger_named
		local inComing_port_start
		local inComing_port_end
		local trigger_port_start
		local trigger_port_end
		local preInfo
		local rules_name
		local rule_list=''
		
		local count = luci.http.formvalue("count")

		uci:set("portTrigger","general","trigger")
		uci:set("portTrigger","general","rule_list",rule_list)

		if count ~= 0 then
			for i = 1,count do
				rule_name = string.format("%s%s", "rule", i)
				items = luci.http.formvalue(rule_name)
				item = port_trigger_split(items,"^")

				if rule_list =='' then
					rule_list=item[1]
				else rule_list=rule_list.." "..item[1]
				end
				uci:set("portTrigger",rule_name,"trigger")
				uci:set("portTrigger",rule_name,"rules_name",item[1])
				uci:set("portTrigger",rule_name,"inComing_port_start",item[2])
				uci:set("portTrigger",rule_name,"inComing_port_end",item[3])
				uci:set("portTrigger",rule_name,"trigger_port_start",item[4])
				uci:set("portTrigger",rule_name,"trigger_port_end",item[5])

			end
		
			
			uci:set("portTrigger","general","rule_list",rule_list)
			uci:set("portTrigger","general","rules_count",count)
			uci:commit("portTrigger")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			uci:apply("portTrigger")
		end
	end

	luci.template.render("expert_configuration/nat_advance")
end

function port_trigger_split(str,sep)
	local array = {}
	reg = string.format("([^%s]*)%s",sep,sep)
	for val in (str .. sep):gmatch(reg) do
		table.insert(array, val)
	end
    return array
end
--[[
function port_trigger_add(trigger_named,inComing_port_start,inComing_port_end,trigger_port_start,trigger_port_end,preName)

		if not (preName=="") then
			if not (trigger_named==preName) then
				uci:delete("portTrigger",preName)
				uci:commit("portTrigger")
			end
		end

		local section = uci:get("portTrigger",trigger_named)

		if not section then
			uci:set("portTrigger",trigger_named,"trigger")
		end

		uci:set("portTrigger",trigger_named,"inComing_port_start",inComing_port_start)
		uci:set("portTrigger",trigger_named,"inComing_port_end",inComing_port_end)
		uci:set("portTrigger",trigger_named,"trigger_port_start",trigger_port_start)
		uci:set("portTrigger",trigger_named,"trigger_port_end",trigger_port_end)
		uci:commit("portTrigger")
		uci:apply("portTrigger")
end
]]--

function fetchProtocolInfo(num)

local protNam
local portNumb
local protocol

	if num=="0" then
		protNam="WWW"
		portNumb=80
		protocol="tcpandudp"
	elseif num=="1" then
		protNam="HTTPS"
		portNumb=443
		protocol="tcp"
	elseif num=="2" then
		protNam="FTP"
		portNumb=21
		protocol="tcp"
	elseif num=="3" then
		protNam="SMTP"
		portNumb=25
		protocol="tcp"
	elseif num=="4" then
		protNam="POP3"
		portNumb=110
		protocol="tcp"
	elseif num=="5" then
		protNam="Telnet"
		portNumb=23
		protocol="tcp"
	elseif num=="6" then
		protNam="NetMeeting"
		portNumb=1720
		protocol="tcp"
	elseif num=="7" then
		protNam="PPTP"
		portNumb=1723
		protocol="tcpandudp"
	elseif num=="8" then
		protNam="IPSec"
		portNumb=500
		protocol="udp"
	elseif num=="9" then
		protNam="SIP"
		portNumb=5060
		protocol="tcpandudp"
	elseif num=="10" then
		protNam="TFTP"
		portNumb=69
		protocol="udp"
	elseif num=="11" then
		protNam="Real-Audio"
		portNumb=554
		protocol="tcpandudp"
	elseif num=="12" then
		protNam=luci.http.formvalue("srvName")
		portNumb=luci.http.formvalue("srvPort")
		protocol=luci.http.formvalue("protocol")
	else
		protNam=""
		portNumb=0
		protocol=""
	end

	return protNam,portNumb,protocol
end

function fetchServerInfo(srvidx)

local protNam
local portNumb
local protocol

	if srvidx=="0" then
		protNam="WWW"
		portNumb=80
		protocol="tcpandudp"
	elseif srvidx=="1" then
		protNam="HTTPS"
		portNumb=443
		protocol="tcp"
	elseif srvidx=="2" then
		protNam="FTP"
		portNumb=21
		protocol="tcp"
	elseif srvidx=="3" then
		protNam="SMTP"
		portNumb=25
		protocol="tcp"
	elseif srvidx=="4" then
		protNam="POP3"
		portNumb=110
		protocol="tcp"
	elseif srvidx=="5" then
		protNam="Telnet"
		portNumb=23
		protocol="tcp"
	elseif srvidx=="6" then
		protNam="NetMeeting"
		portNumb=1720
		protocol="tcp"
	elseif srvidx=="7" then
		protNam="PPTP"
		portNumb=1723
		protocol="tcpandudp"
	elseif srvidx=="8" then
		protNam="IPSec"
		portNumb=500
		protocol="udp"
	elseif srvidx=="9" then
		protNam="SIP"
		portNumb=5060
		protocol="tcpandudp"
	elseif srvidx=="10" then
		protNam="TFTP"
		portNumb=69
		protocol="udp"
	elseif srvidx=="11" then
		protNam="Real-Audio"
		portNumb=554
		protocol="tcpandudp"
	elseif srvidx=="12" then
		protNam=luci.http.formvalue("srvName")
		portNumb=luci.http.formvalue("extPort")
		protocol=luci.http.formvalue("protocol")
	else
		portNumb=0
		protocol=""
	end

	return protNam,portNumb,protocol
end
--dipper nat

--benson dhcp
function action_dhcpSetup()
        local apply = luci.http.formvalue("sysSubmit")
        if apply then
			local enabled = luci.http.formvalue("ssid_state")
			local startAddress = luci.http.formvalue("startAdd")
			local poolSize = luci.http.formvalue("poolSize")
			local old_startAddress = uci:get("dhcp", "lan", "start")
			local old_poolSize = uci:get("dhcp", "lan", "limit")
			local start=string.match(startAddress,"%d+.%d+.%d+.(%d+)")

			if startAddress ~= old_startAddress or poolSize ~= old_poolSize then
				sys.exec("echo 1 > /tmp/lan_dhcp_range")
			end

			uci:set("dhcp","lan","dhcp")
			uci:set("dhcp","lan",'enabled',enabled)
			uci:set("dhcp","lan",'start',start)
			uci:set("dhcp","lan",'limit',poolSize)

			uci:commit("dhcp")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			sys.exec("echo 1 > /tmp/Apply_dhcp_GUI")
			uci:apply("dhcp")
        end

        luci.template.render("expert_configuration/lan_dhcp_setup")
end

function action_dhcpStatic()
	local apply = luci.http.formvalue("sysSubmit")
	local sqlite3 = require("lsqlite3")
	local db = sqlite3.open( "/tmp/netprobe.db" )
	local data = ""
	local allIP = ""
	local DevMac = ""
	local DevIP = ""
	local DevName = ""

	db:busy_timeout(5000)

	for row in db:nrows("SELECT * FROM Device where [Alive]=1 OR ([Alive]=0 AND [nNotAlive] <= 2); ") do
		if row.DevMac ~= "" and row.DevMac then
			DevMac = row.DevMac
		else
			DevMac = row.ALMac
		end

		if row.IP then
			DevIP = row.IP
		else
			DevIP = "0.0.0.0"
		end

		if row.DevName == nil then
			if row.Manufacture == nil then
				DevName = "Unknown"
			else
				DevName = row.Manufacture
			end
		else
			DevName = row.DevName
		end

		data = DevName.."("..DevMac..")"..";"..data
		allIP = DevIP..","..allIP
	end

	if apply then
		local MacIP = luci.http.formvalue("MacIP")
		local UserMacIP = luci.http.formvalue("UserMacIP")
		local sysFirstDNSAddr = luci.http.formvalue("sysFirDNSAddr")
		local sysSecondDNSAddr = luci.http.formvalue("sysSecDNSAddr")
		local sysThirdDNSAddr = luci.http.formvalue("sysThirdDNSAddr")
		
		if MacIP == nil or MacIP == "" then
			MacIP=""
			uci:delete("dhcp","lan","staticIP")
			uci:delete("dhcp","lan","staticIP2")
			uci:delete("dhcp","lan","staticIP3")
		else
			uci:set("dhcp","lan","staticIP",MacIP)
			if UserMacIP ~= nil then
				local UserSetIP=uci:get("dhcp","lan","staticIP2")
				if UserSetIP == nil or UserSetIP == "" then
					uci:set("dhcp","lan","staticIP2",UserMacIP)
				else
					uci:set("dhcp","lan","staticIP3",UserMacIP)
				end
			end
		end

		uci:commit("dhcp")
		sys.exec("/bin/sync") -- This command is for emmc and ext4 filesystem
		sys.exec("echo 1 > /tmp/Apply_dhcp_GUI")
		uci:apply("dhcp")

		sys.exec("/etc/init.d/dnsmasq stop 2>/dev/null")
		sys.exec("/etc/init.d/dnsmasq start 2>/dev/null")
	end

	luci.template.render("expert_configuration/LAN_IPStatic",{data=data,allIP=allIP})
end

function action_clientList1()

	local sqlite3 = require("lsqlite3")
	local db = sqlite3.open( "/tmp/netprobe.db" )
	local anum
	local online = ""
	local name = ""
	local ip = ""
	local devmac = ""
	local rssi = ""
	local ip_reserve = ""
	local lease_time = ""

	local SignalStrength = ""
	local ConnType = ""
	local HostType = ""
	local DevName = ""

	if rssi ==nil then
		rssi=0
	end

    db:busy_timeout(5000)

    for rownum in db:urows("SELECT count(*) FROM Device where [Alive]=1 OR ([Alive]=0 AND [nNotAlive] <= 2); ") do
		anum = rownum
	end

	--local rules_count = uci:get("firewall","general","rules_count")
	for row in db:nrows("SELECT * FROM Device where [Alive]=1 OR ([Alive]=0 AND [nNotAlive] <= 2);") do
		if row.Alive then
			online=online..row.Alive..","
		else
			online=online..row.Alive.."Unknown,"
		end

		if row.DevName then
			name=name..row.DevName..","
		else
			name=name.."Unknown,"
		end

		if row.IP then
			ip=ip..row.IP..","
		else
			ip=ip.."Unknown,"
		end

		if row.DevMac ~= "" and row.DevMac then
			devmac=devmac..row.DevMac..","
		else
			devmac=devmac..row.ALMac..","
		end

		if row.Rssi then
			rssi=rssi..row.Rssi..","
		else
			rssi=rssi.."NULL,"
		end

		if row.ConnType then
			ConnType=ConnType..row.ConnType..","
		else
			ConnType=ConnType..row.ConnType.."Unknown,"
		end

		local LeaseTime=""
		local lease_timeMac=row.DevMac
		LeaseTime = sys.exec("cat /tmp/dhcp.leases | grep  "..lease_timeMac.." | cut -d ' ' -f 1 | tr '\n' ' '")
		lease_time=lease_time..LeaseTime..","
				
	end

	local apply = luci.http.formvalue("sysSubmit")
 	if apply then
		local onlyOne =luci.http.formvalue("onlyOne")
		local staticIp = luci.http.formvalue("macIp")
		local staticIpAll = luci.http.formvalue("totalmacIp")

		local count = 0
		local values = ""
		local data_file = io.open("/etc/ethers", "r")
		while true do
			local line = data_file:read("*line")
			if line == nil then
				break
			end

			local check_data=string.split(staticIpAll,";")
			for index,info in pairs(check_data) do
				if line == info then
					line = ""
					break
				end
			end

			if line ~= "" then
				if count ~=  0 then
					values = values .. ";" .. line
				else
					values = line
					count = count + 1
				end
			end
		end

		if values then
			if not staticIp then
				staticIp = values
			else
				staticIp = values .. ";" .. staticIp
			end
		end

		uci:set("dhcp","lan",'staticIP',staticIp)
		uci:commit("dhcp")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		sys.exec("echo 1 > /tmp/Apply_dhcp_GUI")
		uci:apply("dhcp")

		local staticInfo=uci:get("dhcp","lan","staticIP")

		if not staticInfo then
			local file = io.open( "/etc/ethers", "w" )
			file:write("")
			file:close()
		else
			local have=string.split(staticInfo,";")
			if onlyOne=="1" then
				local file = io.open( "/etc/ethers", "w" )
				file:write(staticInfo .. "\n")
				file:close()
			else
				local file = io.open( "/etc/ethers", "w" )
				for index,info in pairs(have) do
					file:write(info .. "\n")
				end
				file:close()
			end
		end

		sys.exec("/etc/init.d/dnsmasq stop 2>/dev/null")
		sys.exec("/etc/init.d/dnsmasq start 2>/dev/null")
		sys.exec("cp /tmp/netprobe.db /tmp/GUInetprobe.db")
	end

	if(anum>252) then
		anum=252
	end

	luci.template.render("expert_configuration/LAN_DHCPTable_1",{Anum=anum,Online=online,Name=name,Ip=ip,Devmac=devmac,Rssi=rssi,Ip_reserve=ip_reserve,Lease_time=lease_time,Connecttype=ConnType})
end
--benson dhcp

function action_clientList()
	local apply = luci.http.formvalue("sysSubmit")
 	if apply then
		local staticIp= luci.http.formvalue("macIp")
		local onlyOne=luci.http.formvalue("onlyOne")
		uci:set("dhcp","lan",'staticIP',staticIp)
		uci:commit("dhcp")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		sys.exec("echo 1 > /tmp/Apply_dhcp_GUI")
		uci:apply("dhcp")

		local staticInfo=uci.get("dhcp","lan","staticIP")

		if not staticInfo then
			local file = io.open( "/etc/ethers", "w" )
			file:write("")
			file:close()
		else
			local have=string.split(staticInfo,";")
			if onlyOne=="1" then
				local file = io.open( "/etc/ethers", "w" )
				file:write(staticInfo .. "\n")
				file:close()
			else
				local file = io.open( "/etc/ethers", "w" )
				for index,info in pairs(have) do
					file:write(info .. "\n")
				end
				file:close()
			end
		end

		sys.exec("/etc/init.d/dnsmasq stop 2>/dev/null")
		sys.exec("/etc/init.d/dnsmasq start 2>/dev/null")
	end

	luci.template.render("expert_configuration/LAN_DHCPTbl_1")
end
--benson dhcp

--Eten remote
function action_remote_www()
	local apply = luci.http.formvalue("apply")

	if apply then
		local infIdx = uci:get("firewall", "remote_www", "interface")
		local cfgCheck = uci:get("firewall", "remote_www", "client_check")

		local old_WWWport = uci:get("firewall", "remote_www", "port")
		local old_httpsport = uci:get("firewall", "remote_https", "port")

		local infCmd  = ""
		local infDCmd = ""
		local addrCmd = ""

		if "2" == infIdx then
			-- LAN
			infCmd=" -i br-lan "
			if cfgCheck ~= "1" then
				infDCmd=" ! -i br-lan "
			end
		elseif "3" == infIdx then
			-- WAN LAN
			infCmd=" ! -i br-lan "
			if cfgCheck ~= "1" then
				infDCmd=" -i br-lan "
			end
		end

		if not ("0" == uci:get("firewall", "remote_www", "client_check")) then
			addrCmd=" -s " .. uci:get("firewall", "remote_www", "client_addr") .. " "
		end

		--sys.exec("/usr/sbin/iptables -t filter -D INPUT " .. infCmd .. addrCmd .. " -p tcp --dport " .. uci:get("firewall", "remote_www", "port") .. " -j ACCEPT 2> /dev/null")
		--sys.exec("/usr/sbin/iptables -t filter -D INPUT " .. infDCmd .. " -p tcp --dport " .. uci:get("firewall", "remote_www", "port") .. " -j DROP 2> /dev/null")

		--icmp
		-- local pingEnabled = luci.http.formvalue("RemoteICMPInterface")
		-- local ori_pingEnabled = uci:get("firewall","general","pingEnabled")

		-- if not (ori_pingEnabled==pingEnabled) then
			-- pingEnabled = checkInjection(pingEnabled)
			-- if pingEnabled ~= false then
				-- uci:set("firewall","general","pingEnabled",pingEnabled)
			-- end
			-- uci:commit("firewall")
			-- uci:apply("firewall")
		-- end

		--telnet
		local Telnetport = luci.http.formvalue("RemoteTelnetPort")
		local Telnetinterface = luci.http.formvalue("RemoteTelnetInterface")
		local Telnetcheck = luci.http.formvalue("RemoteTelnetClientCheck")
		local TelnetclientAddr = luci.http.formvalue("RemoteTelnetClientAddr")
		local TelentEnable = tonumber(Telnetinterface)
		sys.exec("/etc/init.d/telnet stop 2>/dev/null")

		uci:set("firewall", "remote_telnet", "port", Telnetport)
		uci:set("firewall", "remote_telnet", "interface", tonumber(Telnetinterface))
		uci:set("firewall", "remote_telnet", "client_check", Telnetcheck)

		if "1" == Telnetcheck then
			local TelnetclientAddr = luci.http.formvalue("RemoteTelnetClientAddr")

			uci:set("firewall", "remote_telnet", "client_addr", TelnetclientAddr);
		end
		uci:save("firewall")
		uci:commit("firewall")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem

		if TelnetEnable ~= 0 then
			sys.exec("/etc/init.d/telnet start 2>/dev/null")
		end

		--ssh
		local Sshport = luci.http.formvalue("RemoteSshPort")
		local Sshinterface = luci.http.formvalue("RemoteSshInterface")
		local Sshcheck = luci.http.formvalue("RemoteSshClientCheck")
		local SshclientAddr = luci.http.formvalue("RemoteSshClientAddr")
		local SshEnable = tonumber(Sshinterface)
		sys.exec("/etc/init.d/dropbear stop 2>/dev/null")

		uci:set("firewall", "remote_ssh", "port", Sshport)
		uci:set("firewall", "remote_ssh", "interface", tonumber(Sshinterface))
		uci:set("firewall", "remote_ssh", "client_check", Sshcheck)

		if SshEnable == 0 then
			uci:set("dropbear", "setting", "enable", "0")
		else
			uci:set("dropbear", "setting", "enable", "1")
		end
		uci:set("dropbear", "setting", "Port", Sshport)
		uci:save("dropbear")
		uci:commit("dropbear")

		if "1" == Sshcheck then
			local SshclientAddr = luci.http.formvalue("RemoteSshClientAddr")

			uci:set("firewall", "remote_ssh", "client_addr", SshclientAddr);
		end
		uci:save("firewall")
		uci:commit("firewall")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		sys.exec("/etc/init.d/dropbear start 2>/dev/null")

		--https
		local httpsport = luci.http.formvalue("RemotehttpsPort")
		local httpsinterface = luci.http.formvalue("RemotehttpsInterface")
		local httpscheck = luci.http.formvalue("RemotehttpsClientCheck")
		local httpsclientAddr = luci.http.formvalue("RemotehttpsClientAddr")

		uci:set("firewall", "remote_https", "port", httpsport)
		uci:set("firewall", "remote_https", "interface", tonumber(httpsinterface))
		uci:set("firewall", "remote_https", "client_check", httpscheck)

		if "1" == httpscheck then
			uci:set("firewall", "remote_https", "client_addr", httpsclientAddr);
		end

		--www
		local WWWport = luci.http.formvalue("RemoteWWWPort")
		local WWWinterface = luci.http.formvalue("RemoteWWWInterface")
		local WWWcheck = luci.http.formvalue("RemoteWWWClientCheck")
		local WWWclientAddr = luci.http.formvalue("RemoteWWWClientAddr")

		uci:set("firewall", "remote_www", "port", WWWport)
		uci:set("firewall", "remote_www", "interface", tonumber(WWWinterface))
		uci:set("firewall", "remote_www", "client_check", WWWcheck)

		if "1" == WWWcheck then
			uci:set("firewall", "remote_www", "client_addr", WWWclientAddr);
		end

		uci:commit("firewall")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem

		uci:set("uhttpd", "main", "listen_http", WWWport)
		uci:commit("uhttpd")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem

		sys.exec("echo 0 > /tmp/restart_lighttpd")
		if "3" == tonumber(WWWinterface) or old_WWWport ~= WWWport or "3" == tonumber(httpsinterface) or old_httpsport ~= httpsport then
			sys.exec("rm /tmp/restart_lighttpd")
		end

		sys.exec("sleep 1")
		sys.exec("/sbin/parsePort.sh")
		uci:apply("uhttpd")
	end

	sys.exec("/sbin/parsePort.sh")
	local www_port=uci:get("firewall", "remote_www", "port")
	local telnet_port=uci:get("firewall", "remote_telnet", "port")
	local https_port=uci:get("firewall", "remote_https", "port")
	local ssh_port=uci:get("firewall", "remote_ssh", "port")
	luci.template.render("expert_configuration/remote",{www_port=www_port,
														telnet_port=telnet_port,
														https_port=https_port,ssh_port=ssh_port})
end

function action_remote_telnet()
	local apply = luci.http.formvalue("apply")

	if apply then
		local port = luci.http.formvalue("RemoteTelnetPort")
		local interface = luci.http.formvalue("RemoteTelnetInterface")
		local check = luci.http.formvalue("RemoteTelnetClientCheck")

		sys.exec("/etc/init.d/telnet stop 2>/dev/null")

		uci:set("firewall", "remote_telnet", "port", port)
		uci:set("firewall", "remote_telnet", "interface", tonumber(interface))
		uci:set("firewall", "remote_telnet", "client_check", check)

		if "1" == check then
			local clientAddr = luci.http.formvalue("RemoteTelnetClientAddr")

			uci:set("firewall", "remote_telnet", "client_addr", clientAddr);
		end

		uci:save("firewall")
		uci:commit("firewall")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		sys.exec("/etc/init.d/telnet start 2>/dev/null")
	end

	luci.template.render("expert_configuration/remote_telnet")
end

function action_remote_icmp()
	local apply = luci.http.formvalue("apply")

	if apply then
		local interface = luci.http.formvalue("RemoteICMPInterface")

		uci:set("firewall", "remote_telnet", "interface", tonumber(interface))
		uci:save("firewall")
		uci:commit("firewall")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("firewall")
	end

	luci.template.render("expert_configuration/remote_icmp")
end
--Eten Remote END

--Eten Upnp
function action_upnp()
	local apply = luci.http.formvalue("apply")

	if apply then
		local enabled = luci.http.formvalue("UPnPState")

		if "enable" == enabled then
			uci:set("upnpd", "config", "enabled", "1")
		else
			uci:set("upnpd", "config", "enabled", "0")
		end

		uci:save("upnpd")
		uci:commit("upnpd")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("upnpd")
	end

	sys.exec("/usr/sbin/iptables -t nat -vnL MINIUPNPD | tail -n +3 | awk -F ' ' '{ print $4 \" \" $11 \" \" $12}'|sed 's/to://g' |sed 's/dpt://g' |sed 's/:/ /g' > /tmp/upnp")

	local data = sys.exec("wc -l /tmp/upnp|awk -F \' \' \'{print $1}\' " )
	local col = data:match("%d+")

	luci.template.render("expert_configuration/upnp",{datacol=col})
end
--Eten Upnp END

--sendoh
--2.4G Wireless
function action_wireless()
	luci.template.render("expert_configuration/wireless")
end

function action_menu_wireless()
	luci.template.render("expert_configuration/menu_wireless")
end

function wlan_general()
	require("luci.model.uci")
	local apply = luci.http.formvalue("sysSubmit")
	local wps_enable = uci:get("wps","wps","enabled")
	local tmppsk

	-- NBG6817 GUI --
--	local product_name = uci:get("system","main","product_name")

--	if (product_name == "NBG6817" or product_name == "NBG6617") then
		if apply then
			--SSID
			local SSID = luci.http.formvalue("SSID_value")
			--radioON
			local Wireless_enable = luci.http.formvalue("ssid_state")
			--HideSSID
			local chk_hidden = luci.http.formvalue("Hide_SSID")
			wireless_hidden = "1"

			if not (chk_hidden)then
				wireless_hidden = "0"
			end

			--ChannelID
			local Channel_ID = luci.http.formvalue("Channel_ID_index")
			--AutoChSelect
			local Auto_Channel = luci.http.formvalue("Auto_Channel")
			--ChannelWidth
			local Channel_Width = luci.http.formvalue("ChWidth_select")
			--WirelessMode
			local Wireless_Mode = luci.http.formvalue("Mode_select")

			--SecurityMode
			local security_mode = luci.http.formvalue("security_value")
			local security_mode_val = "NULL"
			if( security_mode == "NONE") then
				security_mode_val = security_mode
			elseif( security_mode == "WEP")then
				local EncrypAuto_shared = luci.http.formvalue("auth_method")
				local wep_passphrase = luci.http.formvalue("wep_passphrase")
				local WEP64_128 = luci.http.formvalue("WEP64_128")
				local WEPKey_Code = luci.http.formvalue("WEPKey_Code")
				local DefWEPKey = luci.http.formvalue("DefWEPKey")
				local wepkey1 = luci.http.formvalue("wep_key_1")
				local wepkey2 = luci.http.formvalue("wep_key_2")
				local wepkey3 = luci.http.formvalue("wep_key_3")
				local wepkey4 = luci.http.formvalue("wep_key_4")

				local EncrypAuto_shared_val = "EncrypAuto_shared"
				if EncrypAuto_shared then
					EncrypAuto_shared_val = EncrypAuto_shared
				end

				local wep_passphrase_val = "wep_passphrase"
				if wep_passphrase then
					wep_passphrase_val = wep_passphrase
				end

				local WEP64_128_val = "WEP64_128"
				if WEP64_128 == "0" or WEP64_128 == "1" then
					WEP64_128_val = WEP64_128
				end

				local WEPKey_Code_val = "WEPKey_Code"
				if WEPKey_Code == "0" or WEPKey_Code == "1" then
					WEPKey_Code_val = WEPKey_Code
				end

				local DefWEPKey_val = "DefWEPKey"
				if DefWEPKey then
					DefWEPKey_val = DefWEPKey
				end

				local wepkey1_val = "wepkey1"
				if wepkey1 then
					wepkey1_val = wepkey1
				end

				local wepkey2_val = "wepkey2"
				if wepkey2 then
					wepkey2_val = wepkey2
				end

				local wepkey3_val = "wepkey3"
				if wepkey3 then
					wepkey3_val = wepkey3
				end

				local wepkey4_val = "wepkey4"
				if wepkey4 then
					wepkey4_val = wepkey4
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s", security_mode, EncrypAuto_shared_val, wep_passphrase_val, WEP64_128_val, WEPKey_Code_val, DefWEPKey_val, wepkey1_val, wepkey2_val, wepkey3_val, wepkey4_val)
			elseif(security_mode == "WPA")then
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
				local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
				local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
				local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")

				local RekeyInterval_val = "3600"
				if RekeyInterval then
					RekeyInterval_val = RekeyInterval
				end

				local RadiusServerIP_val = "192.168.2.3"
				if RadiusServerIP then
					RadiusServerIP_val = RadiusServerIP
				end

				local RadiusServerPort_val = "1812"
				if RadiusServerPort then
					RadiusServerPort_val = RadiusServerPort
				end

				local RadiusServerSecret_val = "ralink"
				if RadiusServerSecret then
					RadiusServerSecret_val = RadiusServerSecret
				end

				local RadiusServerSessionTimeout_val = "0"
				if (RadiusServerSessionTimeout == "") then
					RadiusServerSessionTimeout_val = RadiusServerSessionTimeout
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s", security_mode, RekeyInterval_val, RadiusServerIP_val, RadiusServerPort_val, RadiusServerSecret_val, RadiusServerSessionTimeout_val)
			elseif(security_mode == "WPAPSK")then
				local WPAPSKkey = luci.http.formvalue("PSKey")
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")

				local WPAPSKkey_val = "WPAPSKkey"
				if WPAPSKkey then
					WPAPSKkey_val = WPAPSKkey
				end

				local RekeyInterval_val = "3600"
				if RekeyInterval then
					RekeyInterval_val = RekeyInterval
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s", security_mode, WPAPSKkey_val, RekeyInterval_val)
			elseif(security_mode == "WPA2")then
				local WPACompatible = luci.http.formvalue("wpa_compatible")
				local wpa2_pmf = luci.http.formvalue("wpa2_pmf")
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				local PMKCachePeriod = luci.http.formvalue("PMKCachePeriod")
				local PreAuthentication = luci.http.formvalue("PreAuthentication")
				local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
				local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
				local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
				local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")

				local WPACompatible_val = "0"
				if WPACompatible then
					WPACompatible_val = WPACompatible
				end

				local wpa2_pmf_val = "0"
				if wpa2_pmf then
					wpa2_pmf_val = wpa2_pmf
				end

				local RekeyInterval_val = "3600"
				if RekeyInterval then
					RekeyInterval_val = RekeyInterval
				end

				local PMKCachePeriod_val = "10"
				if (PMKCachePeriod == "") then
					PMKCachePeriod_val = PMKCachePeriod
				end

				local PreAuthentication_val = "0"
				if PreAuthentication then
					PreAuthentication_val = PreAuthentication
				end

				local RadiusServerIP_val = "192.168.2.3"
				if RadiusServerIP then
					RadiusServerIP_val = RadiusServerIP
				end

				local RadiusServerPort_val = "1812"
				if (RadiusServerPort == "") then
					RadiusServerPort_val = RadiusServerPort
				end

				local RadiusServerSecret_val = "ralink"
				if RadiusServerSecret then
					RadiusServerSecret_val = RadiusServerSecret
				end

				local RadiusServerSessionTimeout_val = "0"
				if RadiusServerSessionTimeout then
					RadiusServerSessionTimeout_val = RadiusServerSessionTimeout
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s", security_mode, WPACompatible_val, wpa2_pmf_val, RekeyInterval_val, PMKCachePeriod_val, PreAuthentication_val, RadiusServerIP_val, RadiusServerPort_val, RadiusServerSecret_val, RadiusServerSessionTimeout_val)
			elseif(security_mode=="WPA2PSK")then
				local WPAPSKkey = luci.http.formvalue("PSKey")
				local WPAPSKCompatible = luci.http.formvalue("wpapsk_compatible")
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				local wpa2psk_pmf = luci.http.formvalue("wpa2psk_pmf")

				local WPAPSKkey_val = "WPAPSKkey"
				if WPAPSKkey then
					WPAPSKkey_val = WPAPSKkey
				end

				local wpa2psk_pmf_val = "0"
				if wpa2psk_pmf then
					wpa2psk_pmf_val = wpa2psk_pmf
				end

				local RekeyInterval_val = "3600"
				if RekeyInterval then
					RekeyInterval_val = RekeyInterval
				end

				local WPAPSKCompatible_val = "0"
				if WPAPSKCompatible then
					WPAPSKCompatible_val = WPAPSKCompatible
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s<;;>%s<;;>%s", security_mode, WPAPSKkey_val, WPAPSKCompatible_val, RekeyInterval_val, wpa2psk_pmf_val)
			end

			sys.exec("/bin/WiFi_GUI_ctrl main_24G '"..SSID.."' "..Wireless_enable.." "..wireless_hidden.." "..Channel_ID.." "..Auto_Channel.." "..Channel_Width.." "..Wireless_Mode.." '"..security_mode_val.."'")
		end

		local show_val=sys.exec("/bin/WiFi_GUI_ctrl main_24G_get_val")

--		sys.exec("echo '"..show_val.."' > /dev/console")
		local val_list=NEW_split(show_val,"<;;>")

		local region = country_code_table[val_list[19]:gsub("[a-fA-F]", string.upper)]

		luci.template.render("expert_configuration/wlan", {wireless_enable = val_list[1],
							ssid = val_list[2],
							hide_ssid = val_list[3],
							Auto_Channel = val_list[4],
							wireless_channel = val_list[5],
							select_channel = val_list[20],
							bandwidth =val_list[6],
							mode = val_list[7],
							security = val_list[8],
							auth = val_list[9],
							wps_enabled = val_list[10],
							WPAPSKCompatible = val_list[11],
							chk_PMF = val_list[12],
							psk = val_list[13],
							keyRenewalInterval = val_list[14],
							RadiusServerIP = val_list[15],
							RadiusServerPort = val_list[16],
							RadiusServerSecret = val_list[17],
							RadiusServerSessionTimeout = val_list[18],
							channels = channelRange[region[1]],
							WPACompatible = val_list[21],
							})

	-- else
	-- 	if apply then
	-- 		sys.exec("echo ath0 > /tmp/wifi24G_Apply")
	-- 		sys.exec("kill $(ps | grep 'watch -tn 1 wps_conf_24G' | grep 'grep' -v | awk '{print $1}')")
	-- 	--SSID
	-- 		local SSID = luci.http.formvalue("SSID_value")
	-- 		local SSID_old = uci:get("wireless", "ath0","ssid")
	-- 		if not (SSID == SSID_old)then
	-- --			SSID = checkInjection(SSID)
	-- 			if SSID ~= false then
	-- 				uci:set("wireless", "ath0","ssid",SSID)
	-- 			end
	-- 		end--SSID
	-- 	--radioON
	-- 		local Wireless_enable = luci.http.formvalue("ssid_state")
	-- 		local Wireless_enable_old = uci:get("wireless", "wifi0","disabled")
	-- 		if not(Wireless_enable == Wireless_enable_old)then
	-- 			uci:set("wireless", "wifi0","disabled",Wireless_enable)
	-- 			uci:set("wireless", "ath0","disabled",Wireless_enable)
	-- 		end--radioON
	-- 	--HideSSID
	-- 		local wireless_hidden = luci.http.formvalue("Hide_SSID")
	-- 		local wireless_hidden_old = uci:get("wireless", "ath0","hidden")
	-- 		if not (wireless_hidden)then
	-- 			wireless_hidden = "0"
	-- 		else
	-- 			wireless_hidden = "1"
	-- 		end

	-- 		if not(wireless_hidden == wireless_hidden_old)then
	-- 			uci:set("wireless", "ath0","hidden",wireless_hidden)
	-- 		end
	-- 	--ChannelID
	-- 		local Channel_ID = luci.http.formvalue("Channel_ID_index")

	-- 		local Channel_ID_old = uci:get("wireless", "wifi0","channel")
	-- 		if not(Channel_ID)then
	-- 			Channel_ID = Channel_ID_old
	-- 		end
	-- 		if not(Channel_ID == Channel_ID_old) then
	-- 			uci:set("wireless", "wifi0","channel",Channel_ID)
	-- 		end
	-- 	--AutoChSelect
	-- 		local Auto_Channel = luci.http.formvalue("Auto_Channel")
	-- 		local Auto_Channel_old = uci:get("wireless", "wifi0","AutoChannelSelect")
	-- 		if not(Auto_Channel == Auto_Channel_old) then
	-- 			uci:set("wireless", "wifi0","AutoChannelSelect",Auto_Channel)
	-- 			if (Auto_Channel==1) then
	-- 				uci:set("wireless", "wifi0", "channel", "auto")
	-- 			end
	-- 			if (Wireless_enable=="1") then
	-- 				uci:set("wireless", "wifi0", "channel", "1")
	-- 			end
	-- 		end
	-- 	--ChannelWidth
	-- 		local Channel_Width = luci.http.formvalue("ChWidth_select")
	-- 		uci:set("wireless", "wifi0","channel_width", Channel_Width)
	-- 	--WirelessMode
	-- 		local Wireless_Mode = luci.http.formvalue("Mode_select")
	-- 		uci:set("wireless", "wifi0","hwmode", Wireless_Mode)
	-- 		--if set 802.11n default enable wmm
	-- 		if ( Wireless_Mode == "11gn" or  Wireless_Mode == "11n" or Wireless_Mode == "11bgn" ) then
	-- 			uci:set("wireless", "ath0", "wmm",1)
	-- 		end
	-- 	--SecurityMode
	-- 		local security_mode = luci.http.formvalue("security_value")
	-- 		if (security_mode) then
	-- 			--No security
	-- 			if( security_mode == "NONE") then
	-- 				uci:set("wireless", "wifi0","auth","OPEN")
	-- 				uci:set("wireless", "ath0","auth","NONE")
	-- 				uci:set("wireless", "ath0","encryption","NONE")
	-- 			end

	-- 			--WEP_wlan
	-- 			if( security_mode == "WEP")then
	-- 				local EncrypAuto_shared = luci.http.formvalue("auth_method")
	-- --				uci:set("wireless", "wifi0","encryption","WEP")
	-- 				if (EncrypAuto_shared)	then
	-- 					if(EncrypAuto_shared == "WEPAUTO")then
	-- 						uci:set("wireless", "ath0","encryption","wep-mixed")
	-- 						uci:set("wireless", "ath0","auth",EncrypAuto_shared)
	-- 					elseif(EncrypAuto_shared == "SHARED") then
	-- 						uci:set("wireless", "ath0","encryption","wep-shared")
	-- 						uci:set("wireless", "ath0","auth",EncrypAuto_shared)
	-- 					end
	-- 				end
	-- 				local wep_passphrase = luci.http.formvalue("wep_passphrase")
	-- 				if not (wep_passphrase) then
	-- 					uci:set("wireless", "ath0","PassPhrase","")
	-- 				else
	-- 					uci:set("wireless", "ath0","PassPhrase",wep_passphrase)
	-- 				end
	-- 				--64-128bit
	-- 				local WEP64_128 = luci.http.formvalue("WEP64_128")
	-- 				if (WEP64_128)then
	-- 					if(WEP64_128 == "0")then--[[64-bit]]--
	-- 						uci:set("wireless", "ath0","wepencryp128", WEP64_128)
	-- 					elseif(WEP64_128 == "1") then--[[128-bit]]--
	-- 						uci:set("wireless", "ath0","wepencryp128", WEP64_128)
	-- 					end
	-- 				end
	-- 				--ASCIIHEX
	-- 				local WEPKey_Code = luci.http.formvalue("WEPKey_Code")
	-- 				if (WEPKey_Code == "1")then--[[HEx]]--
	-- 					uci:set("wireless", "ath0","keytype", "1")
	-- 				elseif (WEPKey_Code == "0") then--[[ASCII]]--
	-- 					uci:set("wireless", "ath0","keytype", "0")
	-- 				end
	-- 				--keyindex
	-- 				local DefWEPKey = luci.http.formvalue("DefWEPKey")
	-- 				if (DefWEPKey)then
	-- 					uci:set("wireless", "ath0","key", DefWEPKey)
	-- 				end

	-- 				--WEP key value
	-- 				local wepkey
	-- 				local key_name
	-- 				for i=1,4 do
	-- 					wepkey = luci.http.formvalue("wep_key_"..i)
	-- 					key_name="key"..i
	-- 					if ( wepkey ) then
	-- 						uci:set("wireless", "ath0", key_name, wepkey)
	-- 					else
	-- 						uci:set("wireless", "ath0", key_name, "")
	-- 					end
	-- 				end
	-- 			end

	-- 			--WPA_wlan
	-- 			if (security_mode == "WPA")then
	-- 				uci:set("wireless", "ath0","auth","WPA")
	-- 				uci:set("wireless", "ath0","encryption","WPA")

	-- 				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
	-- 				if (RekeyInterval == "") then
	-- 					uci:set("wireless", "ath0","RekeyInterval", "3600")
	-- 				else
	-- 					uci:set("wireless", "ath0","RekeyInterval", RekeyInterval)
	-- 				end
	-- 				--[[
	-- 				local PMKCachePeriod = luci.http.formvalue("PMKCachePeriod")
	-- 				if (PMKCachePeriod == "") then
	-- 					uci:set("wireless", "ra0","PMKCachePeriod", "10")
	-- 				else
	-- 					uci:set("wireless", "ra0","PMKCachePeriod", PMKCachePeriod)
	-- 				end
	-- 				]]--
	-- 				local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
	-- 				if (RadiusServerIP == "") then
	-- 					uci:set("wireless", "ath0","RADIUS_Server", "192.168.2.3")
	-- 				else
	-- 					uci:set("wireless", "ath0","RADIUS_Server", RadiusServerIP)
	-- 				end

	-- 				local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
	-- 				if (RadiusServerPort == "") then
	-- 					uci:set("wireless", "ath0","RADIUS_Port", "1812")
	-- 				else
	-- 					uci:set("wireless", "ath0","RADIUS_Port", RadiusServerPort)
	-- 				end

	-- 				local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
	-- 				if (RadiusServerSecret == "") then
	-- 					uci:set("wireless", "ath0","RADIUS_Key", "ralink")
	-- 				else
	-- 					uci:set("wireless", "ath0","RADIUS_Key", RadiusServerSecret)
	-- 				end

	-- 				local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")
	-- 				if (RadiusServerSessionTimeout == "") then
	-- 					uci:set("wireless", "ath0","session_timeout_interval", "0")
	-- 				else
	-- 					uci:set("wireless", "ath0","session_timeout_interval", RadiusServerSessionTimeout)
	-- 				end
	-- 				--[[
	-- 				local PreAuthentication = luci.http.formvalue("PreAuthentication")
	-- 				if (PreAuthentication == "") then
	-- 					uci:set("wireless", "ra0","PreAuth", "0")
	-- 				else
	-- 					uci:set("wireless", "ra0","PreAuth", PreAuthentication)
	-- 				end
	-- 				]]--
	-- 			end

	-- 			--WPAPSK_wlan
	-- 			if(security_mode == "WPAPSK")then
	-- 				uci:set("wireless", "ath0","auth","WPAPSK")
	-- 				uci:set("wireless", "ath0","encryption","WPAPSK")
	-- 				local WPAPSKkey = luci.http.formvalue("PSKey")
	-- 				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
	-- 				if (WPAPSKkey == "") then
	-- 					uci:set("wireless", "ath0","WPAPSKkey", "")
	-- 				else
	-- 					uci:set("wireless", "ath0","WPAPSKkey", WPAPSKkey)
	-- 				end
	-- 				if not(RekeyInterval) then
	-- 					uci:set("wireless", "ath0","RekeyInterval", "3600")
	-- 				else
	-- 					uci:set("wireless", "ath0","RekeyInterval", RekeyInterval)
	-- 				end
	-- 			end

	-- 			--WPA2
	-- 			if (security_mode == "WPA2")then
	-- 				uci:set("wireless", "ath0","auth","WPA2")
	-- 				uci:set("wireless", "ath0","encryption","WPA2")
	-- 				local WPACompatible = luci.http.formvalue("wpa_compatible")
	-- 				if not (WPACompatible) then
	-- 					uci:set("wireless", "ath0","WPACompatible", "0")
	-- 				else
	-- 					uci:set("wireless", "ath0","WPACompatible", WPACompatible)
	-- 				end

	-- 				local wpa2_pmf = luci.http.formvalue("wpa2_pmf")
	-- 				if not (wpa2_pmf) then
	-- 					uci:set("wireless", "ath0","PMF", "0")
	-- 				else
	-- 					uci:set("wireless", "ath0","PMF", wpa2_pmf)
	-- 				end

	-- 				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
	-- 				if (RekeyInterval == "") then
	-- 					uci:set("wireless", "ath0","RekeyInterval", "3600")
	-- 				else
	-- 					uci:set("wireless", "ath0","RekeyInterval", RekeyInterval)
	-- 				end

	-- 				local PMKCachePeriod = luci.http.formvalue("PMKCachePeriod")
	-- 				if (PMKCachePeriod == "") then
	-- 					uci:set("wireless", "ath0","PMKCachePeriod", "10")
	-- 				else
	-- 					uci:set("wireless", "ath0","PMKCachePeriod", PMKCachePeriod)
	-- 				end
	-- 				local PreAuthentication = luci.http.formvalue("PreAuthentication")
	-- 				if (PreAuthentication == "") then
	-- 					uci:set("wireless", "ath0","PreAuth", "0")
	-- 				else
	-- 					uci:set("wireless", "ath0","PreAuth", PreAuthentication)
	-- 				end
	-- 				local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
	-- 				if (RadiusServerIP == "") then
	-- 					uci:set("wireless", "ath0","RADIUS_Server", "192.168.2.3")
	-- 				else
	-- 					uci:set("wireless", "ath0","RADIUS_Server", RadiusServerIP)
	-- 				end

	-- 				local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
	-- 				if (RadiusServerPort == "") then
	-- 					uci:set("wireless", "ath0","RADIUS_Port", "1812")
	-- 				else
	-- 					uci:set("wireless", "ath0","RADIUS_Port", RadiusServerPort)
	-- 				end

	-- 				local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
	-- 				if (RadiusServerSecret == "") then
	-- 					uci:set("wireless", "ath0","RADIUS_Key", "ralink")
	-- 				else
	-- 					uci:set("wireless", "ath0","RADIUS_Key", RadiusServerSecret)
	-- 				end

	-- 				local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")
	-- 				if (RadiusServerSessionTimeout == "") then
	-- 					uci:set("wireless", "ath0","session_timeout_interval", "0")
	-- 				else
	-- 					uci:set("wireless", "ath0","session_timeout_interval", RadiusServerSessionTimeout)
	-- 				end
	-- 			end

	-- 			--WPA2PSK_wlan
	-- 			if(security_mode=="WPA2PSK")then
	-- 				uci:set("wireless", "ath0","auth","WPA2PSK")
	-- 				uci:set("wireless", "ath0","encryption","WPA2PSK")
	-- 				local WPAPSKkey = luci.http.formvalue("PSKey")
	-- 				local WPAPSKCompatible = luci.http.formvalue("wpapsk_compatible")
	-- 				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
	-- 				if (WPAPSKkey == "") then
	-- 					uci:set("wireless", "ath0","WPAPSKkey", "")
	-- 				else
	-- 					uci:set("wireless", "ath0","WPAPSKkey", WPAPSKkey)
	-- 				end

	-- 				local wpa2psk_pmf = luci.http.formvalue("wpa2psk_pmf")
	-- 				if not (wpa2psk_pmf) then
	-- 					uci:set("wireless", "ath0","PMF", "0")
	-- 				else
	-- 					uci:set("wireless", "ath0","PMF", wpa2psk_pmf)
	-- 				end

	-- 				if (RekeyInterval == "") then
	-- 					uci:set("wireless", "ath0","RekeyInterval", "3600")
	-- 				else
	-- 					uci:set("wireless", "ath0","RekeyInterval", RekeyInterval)
	-- 				end
	-- 				if not (WPAPSKCompatible) then
	-- 					uci:set("wireless", "ath0","WPAPSKCompatible", "0")
	-- 				else
	-- 					uci:set("wireless", "ath0","WPAPSKCompatible", WPAPSKCompatible)
	-- 				end
	-- 			end
	-- 		end

	-- 		uci:set("wps","wps","conf","1")
	-- 		uci:commit("wps")

	-- 		uci:commit("wireless")
	-- 		sys.exec("echo wifi0 >/tmp/WirelessDev")
	-- 		uci:apply("wireless")

	-- 	end --end apply

	-- 	if (wps_enable == "1") then
	-- 		wps=1
	-- 	else
	--         	wps=0
	-- 	end

	-- 	tmppsk=sys.exec("cat /tmp/tmppsk")

	-- 	local file = io.open("/var/countrycode", "r")
	-- 	local temp = file:read("*all")
	-- 	file:close()

	-- 	local code = temp:match("([0-9a-fA-F]+)")
	-- 	local region = country_code_table[code:gsub("[a-fA-F]", string.upper)]
	-- 	local Auto_Channel_chk = uci:get("wireless", "wifi0","AutoChannelSelect")

	-- 	if (Auto_Channel_chk=="1") then
	-- 		sys.exec("uci set wireless.wifi0.channel=$(iwlist ath0 channel | grep 'Current Frequency'| awk -F 'Channel ' '{print $2}'| awk -F ')' '{print $1}'|sed 's/\"//g')")
	-- 	end
	-- --	sys.exec("uci set wireless.wifi0.channel=$(iwlist ath0 channel | grep 'Current Frequency'| awk -F 'Channel ' '{print $2}'| awk -F ')' '{print $1}'|sed 's/\"//g')")
	-- 	luci.template.render("expert_configuration/wlan", {wps_enabled = wps, psk = tmppsk, channels = channelRange[region[1]]})
	-- end
end

function wlan_multissid()
	-- NBG6817 GUI --
--	local product_name = uci:get("system","main","product_name")

--	if (product_name == "NBG6817" or product_name == "NBG6617") then
		local Apply=luci.http.formvalue("time_apply")

		if Apply then
			local iface=luci.http.formvalue("iface")
			local time=luci.http.formvalue("time")
			-- sys.exec("echo --------------------"..iface.." 24G "..time..' > /dev/console')
			sys.exec("/bin/guestWifiTimer.sh add_rule "..iface.." 24G "..time)
		end

		local show_val=sys.exec("/bin/WiFi_GUI_ctrl GuestWlan24G_get_val")
		local val_list=NEW_split(show_val,"<;;>")

		luci.template.render("expert_configuration/wlan_multissid", {wireless_disable = val_list[1],
							guest1 = val_list[2],
							guest2 = val_list[3],
							guest3 = val_list[4]})
	-- else
	-- 	security = {"","",""}
	-- 	local iface
	-- 	local Wireless_enable
	-- 	local cfgfile="wireless"
	-- 	local apply = luci.http.formvalue("sysSubmit")

	-- 	for i=1,3 do
	-- 		iface="ath"..i
	-- 		security[i]=uci.get(cfgfile,iface,"auth")

	--         	if security[i] == "WPAPSK" then
	--                 	security[i]="WPA-PSK"
	--         	elseif security[i] == "WPA2PSK" then
	--                 	security[i]="WPA2-PSK"
	--         	elseif security[i] == "WEPAUTO" or security[i] == "SHARED" then
	--                 	security[i]="WEP"
	--         	elseif security[i] == "OPEN" then
	--                 	security[i]="No Security"
	--         	end
	-- 	end

	-- 	luci.template.render("expert_configuration/wlan_multissid", {security1 = security[1], security2 = security[2], security3 = security[3]})
	-- end
end

function multiple_ssid()
	require("luci.model.uci")
	local apply = luci.http.formvalue("sysSubmit")
	local interface = luci.http.formvalue("interface")

--	local product_name = uci:get("system","main","product_name")

--	if (product_name == "NBG6817" or product_name == "NBG6617") then
		if apply then
			local Wireless_disable = luci.http.formvalue("ssid_state")
			local Wireless_disable_val = "1"

			if Wireless_disable then
				Wireless_disable_val = "0"		--enable
			end

			--SSID
			local SSID = luci.http.formvalue("SSID_value")

			--HideSSID
			local chk_hidden = luci.http.formvalue("Hide_SSID")
			wireless_hidden = "1"

			if not (chk_hidden)then
				wireless_hidden = "0"
			end

			--Intra BSS
			local chk_intra_bss = luci.http.formvalue("Intra_BSS")
			intra_bss = "1"

	        if not (chk_intra_bss) then
				intra_bss = "0"
			end

			--WMM QoS
			local chk_wmm_qos = luci.http.formvalue("WMM_QoS")
			wmm_qos = "1"

			if not (chk_wmm_qos) then
				wmm_qos = "0"
			end

			--Guest WLAN
			local chk_band_manage = luci.http.formvalue("guest_wlan_bandwidth")
			local max_band = luci.http.formvalue("max_bandwidth")
			band_manage = "1"
			if not (chk_band_manage) then
				band_manage = "0"
			end

			--SecurityMode
			local security_mode = luci.http.formvalue("security_value")
			local security_mode_val = "NULL"

			if( security_mode == "NONE") then
				security_mode_val = security_mode
			elseif( security_mode == "WEP")then
				local EncrypAuto_shared = luci.http.formvalue("auth_method")
				local wep_passphrase = luci.http.formvalue("wep_passphrase")
				local WEP64_128 = luci.http.formvalue("WEP64_128")
				local WEPKey_Code = luci.http.formvalue("WEPKey_Code")
				local DefWEPKey = luci.http.formvalue("DefWEPKey")
				local wepkey1 = luci.http.formvalue("wep_key_1")
				local wepkey2 = luci.http.formvalue("wep_key_2")
				local wepkey3 = luci.http.formvalue("wep_key_3")
				local wepkey4 = luci.http.formvalue("wep_key_4")

				local EncrypAuto_shared_val = "EncrypAuto_shared"
				if EncrypAuto_shared then
					EncrypAuto_shared_val = EncrypAuto_shared
				end

				local wep_passphrase_val = "wep_passphrase"
				if wep_passphrase then
					wep_passphrase_val = wep_passphrase
				end

				local WEP64_128_val = "WEP64_128"
				if WEP64_128 == "0" or WEP64_128 == "1" then
					WEP64_128_val = WEP64_128
				end

				if WEPKey_Code == "0" or WEPKey_Code == "1" then
					WEPKey_Code_val = WEPKey_Code
				end

				local DefWEPKey_val = "DefWEPKey"
				if DefWEPKey then
					DefWEPKey_val = DefWEPKey
				end

				local wepkey1_val = "wepkey1"
				if wepkey1 then
					wepkey1_val = wepkey1
				end

				local wepkey2_val = "wepkey2"
				if wepkey2 then
					wepkey2_val = wepkey2
				end

				local wepkey3_val = "wepkey3"
				if wepkey3 then
					wepkey3_val = wepkey3
				end

				local wepkey4_val = "wepkey4"
				if wepkey4 then
					wepkey4_val = wepkey4
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s", security_mode, EncrypAuto_shared_val, wep_passphrase_val, WEP64_128_val, WEPKey_Code_val, DefWEPKey_val, wepkey1_val, wepkey2_val, wepkey3_val, wepkey4_val)
			elseif(security_mode == "WPA")then
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
				local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
				local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
				local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")

				local RekeyInterval_val = "3600"
				if RekeyInterval then
					RekeyInterval_val = RekeyInterval
				end

				local RadiusServerIP_val = "192.168.2.3"
				if RadiusServerIP then
					RadiusServerIP_val = RadiusServerIP
				end

				local RadiusServerPort_val = "1812"
				if RadiusServerPort then
					RadiusServerPort_val = RadiusServerPort
				end

				local RadiusServerSecret_val = "ralink"
				if RadiusServerSecret then
					RadiusServerSecret_val = RadiusServerSecret
				end

				local RadiusServerSessionTimeout_val = "0"
				if (RadiusServerSessionTimeout == "") then
					RadiusServerSessionTimeout_val = RadiusServerSessionTimeout
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s", security_mode, RekeyInterval_val, RadiusServerIP_val, RadiusServerPort_val, RadiusServerSecret_val, RadiusServerSessionTimeout_val)
			elseif(security_mode == "WPAPSK")then
				local WPAPSKkey = luci.http.formvalue("PSKey")
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")

				local WPAPSKkey_val = "WPAPSKkey"
				if WPAPSKkey then
					WPAPSKkey_val = WPAPSKkey
				end

				local RekeyInterval_val = "3600"
				if RekeyInterval then
					RekeyInterval_val = RekeyInterval
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s", security_mode, WPAPSKkey_val, RekeyInterval_val)
			elseif(security_mode == "WPA2")then
				local WPACompatible = luci.http.formvalue("wpa_compatible")
				local wpa2_pmf = luci.http.formvalue("wpa2_pmf")
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				local PMKCachePeriod = luci.http.formvalue("PMKCachePeriod")
				local PreAuthentication = luci.http.formvalue("PreAuthentication")
				local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
				local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
				local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
				local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")

				local WPACompatible_val = "0"
				if WPACompatible then
					WPACompatible_val = WPACompatible
				end

				local wpa2_pmf_val = "0"
				if wpa2_pmf then
					wpa2_pmf_val = wpa2_pmf
				end

				local RekeyInterval_val = "3600"
				if RekeyInterval then
					RekeyInterval_val = RekeyInterval
				end

				local PMKCachePeriod_val = "10"
				if (PMKCachePeriod == "") then
					PMKCachePeriod_val = PMKCachePeriod
				end

				local PreAuthentication_val = "0"
				if PreAuthentication then
					PreAuthentication_val = PreAuthentication
				end

				local RadiusServerIP_val = "192.168.2.3"
				if RadiusServerIP then
					RadiusServerIP_val = RadiusServerIP
				end

				local RadiusServerPort_val = "1812"
				if (RadiusServerPort == "") then
					RadiusServerPort_val = RadiusServerPort
				end

				local RadiusServerSecret_val = "ralink"
				if RadiusServerSecret then
					RadiusServerSecret_val = RadiusServerSecret
				end

				local RadiusServerSessionTimeout_val = "0"
				if RadiusServerSessionTimeout then
					RadiusServerSessionTimeout_val = RadiusServerSessionTimeout
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s", security_mode, WPACompatible_val, wpa2_pmf_val, RekeyInterval_val, PMKCachePeriod_val, PreAuthentication_val, RadiusServerIP_val, RadiusServerPort_val, RadiusServerSecret_val, RadiusServerSessionTimeout_val)
			elseif(security_mode=="WPA2PSK")then
				local WPAPSKkey = luci.http.formvalue("PSKey")
				local WPAPSKCompatible = luci.http.formvalue("wpapsk_compatible")
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				local wpa2psk_pmf = luci.http.formvalue("wpa2psk_pmf")

				local WPAPSKkey_val = "WPAPSKkey"
				if WPAPSKkey then
					WPAPSKkey_val = WPAPSKkey
				end

				local wpa2psk_pmf_val = "0"
				if wpa2psk_pmf then
					wpa2psk_pmf_val = wpa2psk_pmf
				end

				local RekeyInterval_val = "3600"
				if RekeyInterval then
					RekeyInterval_val = RekeyInterval
				end

				local WPAPSKCompatible_val = "0"
				if WPAPSKCompatible then
					WPAPSKCompatible_val = WPAPSKCompatible
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s<;;>%s<;;>%s", security_mode, WPAPSKkey_val, WPAPSKCompatible_val, RekeyInterval_val, wpa2psk_pmf_val)
			end

			sys.exec("/bin/WiFi_GUI_ctrl GuestWlan24G_edit '"..interface.."' "..Wireless_disable_val.." '"..SSID.."' "..wireless_hidden.." "..intra_bss.." "..wmm_qos.." "..band_manage.." '"..max_band.."' '"..security_mode_val.."'")

			local show_val=sys.exec("/bin/WiFi_GUI_ctrl GuestWlan24G_get_val")
			local val_list=NEW_split(show_val,"<;;>")

			luci.template.render("expert_configuration/wlan_multissid", {wireless_disable = val_list[1],
							guest1 = val_list[2],
							guest2 = val_list[3],
							guest3 = val_list[4]})
			return
		end

		local show_val=sys.exec("/bin/WiFi_GUI_ctrl GuestWlan24G_edit_get_val '"..interface.."'")
		local val_list=NEW_split(show_val,"<;;>")

		luci.template.render("expert_configuration/multissid_edit",{ifacename=val_list[1],
							wireless_enable = val_list[2],
							ssid = val_list[3],
							hide_ssid = val_list[4],
							IntraBSS = val_list[5],
							wmm = val_list[6],
							wmm_choice = val_list[7],
							enabel_bandwidth = val_list[8],
							guest_max_bandwidth = val_list[9],
							auth = val_list[10],
							security = val_list[11],
							wps_enabled = val_list[12],
							WPAPSKCompatible = val_list[13],
							chk_PMF = val_list[14],
							psk = val_list[15],
							keyRenewalInterval = val_list[16],
							RadiusServerIP = val_list[17],
							RadiusServerPort = val_list[18],
							RadiusServerSecret = val_list[19],
							RadiusServerSessionTimeout = val_list[20],
							WPACompatible = val_list[21],
							})

	-- else
	-- 	security = {"","",""}
	-- 	local iface
	-- 	local cfgfile="wireless"
	-- 	local wireless_mode = uci:get("wireless", "wifi0", "hwmode")
	-- 	local WMM_Choose

	-- 	if ( wireless_mode == "11gn" or  wireless_mode == "11n" or wireless_mode == "11bgn" ) then
	--        	uci:set("wireless", "ath1", "wmm",1)
	-- 		uci:set("wireless", "ath2", "wmm",1)
	-- 		uci:set("wireless", "ath3", "wmm",1)
	-- 		uci:commit("wireless")
	-- 		WMM_Choose="disabled"
	-- 	end

	-- 	if interface == "1" then
	-- 		iface="ath1"
	-- 	elseif interface == "2" then
	-- 		iface="ath2"
	-- 	elseif interface == "3" then
	-- 		iface="ath3"
	-- 	else
	-- 		iface=interface
	-- 	end

	-- 	if apply then
	-- 		sys.exec("echo "..iface.." > /tmp/wifi24G_Apply")
	-- 		--SSID
	-- 		local SSID = luci.http.formvalue("SSID_value")

	-- --		SSID = checkInjection(SSID)
	-- 		if SSID ~= false then
	-- 			uci:set(cfgfile, iface, "ssid", SSID)
	-- 		end

	-- 		--Active
	-- 		local Wireless_enable = luci.http.formvalue("ssid_state")
	-- 		if Wireless_enable then
	-- 			uci:set(cfgfile, iface, "disabled", 0)
	-- 		else
	-- 			uci:set(cfgfile, iface, "disabled", 1)
	-- 		end
	-- 		--HideSSID
	-- 		local wireless_hidden = luci.http.formvalue("Hide_SSID")
	-- 		if not (wireless_hidden)then
	-- 			uci:set(cfgfile, iface, "hidden", 0)
	-- 		else
	-- 			uci:set(cfgfile, iface, "hidden", 1)
	-- 		end
	-- 		--Intra BSS
	-- 		local intra_bss = luci.http.formvalue("Intra_BSS")
	--                 if not (intra_bss) then
	-- 			uci:set(cfgfile, iface, "IntraBSS", 0)
	--                 else
	-- 			uci:set(cfgfile, iface, "IntraBSS", 1)
	-- 		end
	-- 		--WMM QoS
	-- 		local wmm_qos = luci.http.formvalue("WMM_QoS")

	-- 		if ( wireless_mode == "11gn" or  wireless_mode == "11n" or wireless_mode == "11bgn" ) then
	-- 			uci:set(cfgfile, iface, "wmm", 1)
	-- 		else
	-- 			if not (wmm_qos) then
	-- 				uci:set(cfgfile, iface, "wmm", 0)
	--         		else
	-- 				uci:set(cfgfile, iface, "wmm", 1)
	-- 			end
	-- 		end

	-- 		--Guest WLAN
	-- 		local band_manage = luci.http.formvalue("guest_wlan_bandwidth")
	-- 		local max_band = luci.http.formvalue("max_bandwidth")
	-- 		if band_manage then
	-- 			uci:set(cfgfile, iface, "guest_bandwidth_enable", 1)
	-- 		else
	-- 			uci:set(cfgfile, iface, "guest_bandwidth_enable", 0)
	-- 		end
	-- 		uci:set(cfgfile, iface, "guest_max_bandwidth", max_band)

	-- 		--SecurityMode
	-- 		local security_mode = luci.http.formvalue("security_value")
	-- 		if (security_mode) then
	-- 			--No security
	-- 			if( security_mode == "NONE") then
	-- 				uci:set(cfgfile, iface, "auth", "OPEN")
	-- 				uci:set(cfgfile, iface, "encryption", "NONE")
	-- 			end

	-- 			--WEP_wlan
	-- 			if( security_mode == "WEP")then
	-- 				local EncrypAuto_shared = luci.http.formvalue("auth_method")
	-- --				uci:set(cfgfile, iface,"encryption","WEP")

	-- --				if(EncrypAuto_shared == "WEPAUTO")then
	-- --					uci:set(cfgfile, iface, "auth", EncrypAuto_shared)
	-- --              elseif(EncrypAuto_shared == "SHARED") then
	-- --					uci:set(cfgfile, iface, "auth", EncrypAuto_shared)
	-- --				end
	-- 				if (EncrypAuto_shared)	then
	-- 					if(EncrypAuto_shared == "WEPAUTO")then
	-- 						uci:set(cfgfile, iface,"encryption","wep-mixed")
	-- 						uci:set(cfgfile, iface,"auth",EncrypAuto_shared)
	-- 					elseif(EncrypAuto_shared == "SHARED") then
	-- 						uci:set(cfgfile, iface,"encryption","wep-shared")
	-- 						uci:set(cfgfile, iface,"auth",EncrypAuto_shared)
	-- 					end
	-- 				end

	-- 				local wep_passphrase = luci.http.formvalue("wep_passphrase")
	-- 				if not (wep_passphrase) then
	-- 					uci:set(cfgfile, iface, "PassPhrase","")
	-- 				else
	-- 					uci:set(cfgfile, iface, "PassPhrase",wep_passphrase)
	-- 				end

	-- 				--64-128bit
	-- 				local WEP64_128 = luci.http.formvalue("WEP64_128")
	-- 				if (WEP64_128)then
	-- 					if(WEP64_128 == "0")then--[[64-bit]]--
	-- 						uci:set(cfgfile, iface, "wepencryp128", WEP64_128)
	-- 					else
	-- 						uci:set(cfgfile, iface, "wepencryp128", WEP64_128)
	-- 					end
	-- 				end

	--                                 --ASCIIHEX
	--                                 local WEPKey_Code = luci.http.formvalue("WEPKey_Code")
	--                                 if (WEPKey_Code == "1")then--[[HEx]]--
	--                                 	uci:set(cfgfile, iface, "keytype", "1")
	--                                 elseif (WEPKey_Code == "0") then--[[ASCII]]--
	--                                         uci:set(cfgfile, iface, "keytype", "0")
	--                                 end
	--                                 --keyindex
	--                                 local DefWEPKey = luci.http.formvalue("DefWEPKey")
	--                                 if (DefWEPKey)then
	--                                 	uci:set(cfgfile, iface, "key", DefWEPKey)
	--                                 end

	-- 				--WEP key value
	-- 				local wepkey
	-- 				local key_name
	-- 				for i=1,4 do
	-- 					wepkey = luci.http.formvalue("wep_key_"..i)
	-- 					key_name="key"..i
	-- 					if ( wepkey ) then
	-- 						uci:set(cfgfile, iface, key_name, wepkey)
	-- 					else
	-- 						uci:set(cfgfile, iface, key_name, "")
	-- 					end
	-- 				end
	-- 			end --End WEP

	-- 			--WPA_wlan
	--                         if (security_mode == "WPA")then
	--                         	uci:set(cfgfile, iface, "auth","WPA")
	--                                 uci:set(cfgfile, iface, "encryption","WPA")

	--                                 local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
	--                                 if (RekeyInterval == "") then
	--                                         uci:set(cfgfile, iface, "RekeyInterval", "3600")
	--                                 else
	--                                         uci:set(cfgfile, iface, "RekeyInterval", RekeyInterval)
	--                                 end

	--                                 local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
	--                                 if (RadiusServerIP == "") then
	--                                 	uci:set(cfgfile, iface, "RADIUS_Server", "192.168.2.3")
	--                                 else
	--                                         uci:set(cfgfile, iface, "RADIUS_Server", RadiusServerIP)
	--                                 end

	--                                 local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
	--                                 if (RadiusServerPort == "") then
	--                                 	uci:set(cfgfile, iface, "RADIUS_Port", "1812")
	--                                 else
	--                                         uci:set(cfgfile, iface, "RADIUS_Port", RadiusServerPort)
	--                                 end

	--                                 local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
	--                                 if (RadiusServerSecret == "") then
	--                                 	uci:set(cfgfile, iface, "RADIUS_Key", "ralink")
	--                                 else
	--                                         uci:set(cfgfile, iface, "RADIUS_Key", RadiusServerSecret)
	--                                 end

	--                                 local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")
	--                                 if (RadiusServerSessionTimeout == "" or RadiusServerSessionTimeout == nil) then
	--                                         uci:set(cfgfile, iface, "session_timeout_interval", "0")
	--                                 else
	--                                         uci:set(cfgfile, iface, "session_timeout_interval", RadiusServerSessionTimeout)
	--                                 end
	--                 	end --End WPA

	--                         --WPAPSK_wlan
	--                         if(security_mode == "WPAPSK")then
	--                         	uci:set(cfgfile, iface, "auth", "WPAPSK")
	--                                 uci:set(cfgfile, iface, "encryption", "WPAPSK")
	--                                 local WPAPSKkey = luci.http.formvalue("PSKey")
	--                                 local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
	--                                 if (WPAPSKkey == "") then
	--                                 	uci:set(cfgfile, iface, "WPAPSKkey", "")
	--                                 else
	--                                 	uci:set(cfgfile, iface, "WPAPSKkey", WPAPSKkey)
	--                                 end
	--                                 if not(RekeyInterval) then
	--                                 	uci:set(cfgfile, iface, "RekeyInterval", "3600")
	--                                 else
	--                                         uci:set(cfgfile, iface, "RekeyInterval", RekeyInterval)
	--                                 end
	--                 	end --End WPAPSK

	--                         --WPA2
	--                         if (security_mode == "WPA2")then
	--                                 uci:set(cfgfile, iface, "auth", "WPA2")
	--                                 uci:set(cfgfile, iface, "encryption", "WPA2")
	--                                 local WPACompatible = luci.http.formvalue("wpa_compatible")
	--                                 if not (WPACompatible) then
	--                                 	uci:set(cfgfile, iface, "WPACompatible", "0")
	--                                 else
	--                                         uci:set(cfgfile, iface, "WPACompatible", WPACompatible)
	--                                 end

	--                                 local wpa2_pmf = luci.http.formvalue("wpa2_pmf")
	-- 		                        if not (wpa2_pmf) then
	-- 		                        	uci:set(cfgfile, iface, "PMF", "0")
	-- 		                        else
	-- 		                            uci:set(cfgfile, iface, "PMF", wpa2_pmf)
	-- 		                        end


	-- 				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
	--                                 if (RekeyInterval == "") then
	--                                         uci:set(cfgfile, iface, "RekeyInterval", "3600")
	--                                 else
	--                                         uci:set(cfgfile, iface, "RekeyInterval", RekeyInterval)
	--                                 end

	--                                 local PMKCachePeriod = luci.http.formvalue("PMKCachePeriod")
	--                                 if (PMKCachePeriod == "") then
	--                                         uci:set(cfgfile, iface, "PMKCachePeriod", "10")
	--                                 else
	--                                         uci:set(cfgfile, iface, "PMKCachePeriod", PMKCachePeriod)
	--                                 end
	--                                 local PreAuthentication = luci.http.formvalue("PreAuthentication")
	--                                 if (PreAuthentication == "") then
	--                                         uci:set(cfgfile, iface, "PreAuth", "0")
	--                                 else
	--                                         uci:set(cfgfile, iface, "PreAuth", PreAuthentication)
	--                                 end
	--                                 local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
	--                                 if (RadiusServerIP == "") then
	--                                         uci:set(cfgfile, iface, "RADIUS_Server", "192.168.2.3")
	--                                 else
	--                                         uci:set(cfgfile, iface, "RADIUS_Server", RadiusServerIP)
	--                                 end

	--                                 local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
	--                                 if (RadiusServerPort == "") then
	--                                         uci:set(cfgfile, iface, "RADIUS_Port", "1812")
	--                                 else
	--                                         uci:set(cfgfile, iface, "RADIUS_Port", RadiusServerPort)
	--                                 end
	--                                 local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
	--                                 if (RadiusServerSecret == "") then
	--                                         uci:set(cfgfile, iface, "RADIUS_Key", "ralink")
	--                                 else
	--                                         uci:set(cfgfile, iface, "RADIUS_Key", RadiusServerSecret)
	--                                 end

	--                                 local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")
	--                                 if (RadiusServerSessionTimeout == "" or RadiusServerSessionTimeout == nil) then
	--                                         uci:set(cfgfile, iface, "session_timeout_interval", "0")
	--                                 else
	--                                         uci:set(cfgfile, iface, "session_timeout_interval", RadiusServerSessionTimeout)
	--                                 end
	--                 	end --End WPA2

	--                         --WPA2PSK_wlan
	--                         if(security_mode=="WPA2PSK")then
	--                         	uci:set(cfgfile, iface, "auth", "WPA2PSK")
	--                         	uci:set(cfgfile, iface, "encryption", "WPA2PSK")
	--                                 local WPAPSKkey = luci.http.formvalue("PSKey")
	--                                 local WPAPSKCompatible = luci.http.formvalue("wpapsk_compatible")
	--                                 local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
	--                                 if (WPAPSKkey == "") then
	--                                 	uci:set(cfgfile, iface, "WPAPSKkey", "")
	--                                 else
	--                                         uci:set(cfgfile, iface, "WPAPSKkey", WPAPSKkey)
	--                                 end

	--                                 local wpa2psk_pmf = luci.http.formvalue("wpa2psk_pmf")
	-- 		                        if not (wpa2psk_pmf) then
	-- 		                        	uci:set(cfgfile, iface, "PMF", "0")
	-- 		                        else
	-- 		                            uci:set(cfgfile, iface, "PMF", wpa2psk_pmf)
	-- 		                        end

	--                                 if (RekeyInterval == "") then
	--                                         uci:set(cfgfile, iface, "RekeyInterval", "3600")
	--                                 else
	--                                         uci:set(cfgfile, iface, "RekeyInterval", RekeyInterval)
	--                                 end
	--                                 if not (WPAPSKCompatible) then
	--                                         uci:set(cfgfile, iface, "WPAPSKCompatible", "0")
	--                                 else
	--                                         uci:set(cfgfile, iface, "WPAPSKCompatible", WPAPSKCompatible)
	--                                 end
	--                 	end --End WPA2PSK
	-- 		end

	-- 		sys.exec("echo "..iface.." >> /tmp/moreAP")
	-- 		sys.exec("echo wifi0 >/tmp/WirelessDev")
	-- 		uci:commit(cfgfile)
	-- 		uci:apply(cfgfile)


	-- 	        for i=1,3 do
	-- 	                iface="ath"..i
	-- 	                security[i]=uci.get(cfgfile,iface,"auth")

	-- 	                if security[i] == "WPAPSK" then
	-- 	                        security[i]="WPA-PSK"
	-- 	                elseif security[i] == "WPA2PSK" then
	-- 	                        security[i]="WPA2-PSK"
	-- 	                elseif security[i] == "WEPAUTO" or security[i] == "SHARED" then
	-- 	                        security[i]="WEP"
	-- 	                elseif security[i] == "OPEN" then
	-- 	                        security[i]="No Security"
	-- 	                end
	-- 		end

	-- 		luci.template.render("expert_configuration/wlan_multissid", { security1 = security[1], security2 = security[2], security3 = security[3]})
	-- 		return
	-- 	end --End Apply

	-- 	tmppsk=sys.exec("cat /tmp/tmppsk")

	-- 	luci.template.render("expert_configuration/multissid_edit",{ifacename=iface, psk = tmppsk, wmm_choice=WMM_Choose})
	-- end
end

function wlanmacfilter()
	local sqlite3 = require("lsqlite3")
	local db = sqlite3.open( "/tmp/netprobe.db" )
	local apply = luci.http.formvalue("sysSubmit")
	local changed = 0
	local data = ""
	local DevMac = ""
	local DevName = ""

    -- NBG6817 GUI --
--	local product_name = uci:get("system","main","product_name")

--	if (product_name == "NBG6817" or product_name == "NBG6617") then
		local clients_MAC = ""
		db:busy_timeout(5000)

		for row in db:nrows("SELECT * FROM Device where [Alive]=1 OR ([Alive]=0 AND [nNotAlive] <= 2); ") do
			if row.DevMac ~= "" and row.DevMac then
				DevMac = row.DevMac
			else
				DevMac = row.ALMac
			end

			if row.IP then
				if row.DevName == nil then
					if row.Manufacture == nil then
						DevName = "Unknown"
					else
						DevName = row.Manufacture
					end
				else
					DevName = row.DevName
				end
			end

			clients_MAC = row.ConnType..";"..clients_MAC
			data = DevName.."("..DevMac..")"..";"..data
		end

		if apply then
			--filter on/of
			local MACfilter_ON = luci.http.formvalue("MACfilter_ON")
			--filter action
			local filter_act = luci.http.formvalue("filter_act")

--			local count = luci.http.formvalue("count")
			local MacAddrs_val = luci.http.formvalue("MacAddrs")

			if MacAddrs_val == "" then
				MacAddrs_val = "None"
			end

			sys.exec("/bin/WiFi_GUI_ctrl macfilter24G "..MACfilter_ON.." "..filter_act.." '"..MacAddrs_val.."'")
		end

		local show_val=sys.exec("/bin/WiFi_GUI_ctrl macfilter24G_get_val")
		local val_list=NEW_split(show_val,"<;;>")

		luci.template.render("expert_configuration/wlanmacfilter",{
												data=data,
												clients_MAC=clients_MAC,
												Macaddress=val_list[1],
												ssid=val_list[2],
												MacFilter_enable=val_list[3],
												MacFilter_Action=val_list[4],
												})
	-- else
	--     local select_ap = luci.http.formvalue("ap_select")
	--     local connect_type = ""

	--     db:busy_timeout(5000)

	-- 	for row in db:nrows("SELECT * FROM Device") do
	-- 		if row.DevMac ~= "" and row.DevMac then
	-- 			DevMac = row.DevMac
	-- 		else
	-- 			DevMac = row.ALMac
	-- 		end

	-- 		if row.IP then
	-- 			if row.DevName == nil then
	-- 				if row.Manufacture == nil then
	-- 					DevName = "Unknown"
	-- 				else
	-- 					DevName = row.Manufacture
	-- 				end
	-- 			else
	-- 				DevName = row.DevName
	-- 			end
	-- 		end
	-- 			connect_type = row.ConnType..";"..connect_type
	-- 			data = DevName.."("..DevMac..")"..";"..data
	-- 	end

	-- 	if not select_ap then
	-- 		select_ap="0"
	-- 	end

	-- 	filter="general"..select_ap

	-- 	if apply then
	-- 		--filter on/of
	-- 		local MACfilter_ON = luci.http.formvalue("MACfilter_ON")
	-- 		local count = luci.http.formvalue("count")
	-- 		MACfilter_ON_old = uci:get("wireless_macfilter", filter,"mac_state")
	-- 		if not (MACfilter_ON == MACfilter_ON_old) then
	-- 			changed = 1
	-- 			uci:set("wireless_macfilter", filter,"mac_state", MACfilter_ON)
	-- 		end
	-- 		--filter action
	-- 		local filter_act = luci.http.formvalue("filter_act")
	-- 		filter_act_old = uci:get("wireless_macfilter", filter,"filter_action")
	-- 		if not (filter_act == filter_act_old) then
	-- 			changed = 1
	-- 			uci:set("wireless_macfilter", filter,"filter_action", filter_act)
	-- 		end

	-- 		--mac address
	-- 		local Mac_field
	-- 		local MacAddr_old
	-- 		local Mac_field
	-- 		local MacAddr

	-- 		for i=1,32 do
	-- 			Mac_field="MacAddr"..i
	-- 			MacAddr="00:00:00:00:00:00"
	-- 			uci:set("wireless_macfilter", filter, Mac_field, MacAddr)
	-- 			uci:commit("wireless_macfilter")
	-- 		end


	-- 		for i=1,count do
	-- 			Mac_field="MacAddr"..i
	-- --			MacAddr_old = uci:get("wireless_macfilter", filter, Mac_field)
	-- 			MacAddr = luci.http.formvalue(Mac_field)

	-- --			if not ( MacAddr == MacAddr_old ) then
	-- 				changed = 1
	-- 				uci:set("wireless_macfilter", filter, Mac_field, MacAddr)
	-- --			end
	-- 		end

	-- 		--new value need to be saved
	-- 		if (changed == 1) then
	-- 			local iface_reset="ath"..select_ap
	-- 			local iface
	-- 			local iface_filter
	-- 			for i=0,3 do
	-- 				iface="ath"..i
	-- 				iface_filter="general"..i
	-- 				if (iface == iface_reset) then
	-- 					uci:set("wireless_macfilter", iface_filter, "reset", "1")
	-- 				else
	-- 					uci:set("wireless_macfilter", iface_filter, "reset", "0")
	-- 				end
	-- 			end
	-- 			uci:commit("wireless_macfilter")
	-- 			uci:apply("wireless_macfilter")
	-- 		end
	-- 		if (MACfilter_ON == "1") then
	-- 			uci:set("wps","wps","enabled","0")
	-- 			uci:commit("wps")
	-- 			sys.exec("echo wifi0 >/tmp/WirelessDev")
	-- 			uci:apply("wireless")
	-- 		end
	-- 	end
	-- 	luci.template.render("expert_configuration/wlanmacfilter",{filter_iface=filter, ap=select_ap,data=data,connect_type=connect_type})
	-- end
end

function wlan_advanced()
	local apply = luci.http.formvalue("sysSubmit")

--	local product_name = uci:get("system","main","product_name")

--	if (product_name == "NBG6817" or product_name == "NBG6617") then
		if apply then
			--rts_Threshold
			local rts_Threshold = luci.http.formvalue("rts_Threshold")
			local rts_Threshold_val = "2345"
			if rts_Threshold then
				rts_Threshold_val = rts_Threshold
			end

			--fr_threshold
			local fr_threshold = luci.http.formvalue("fr_threshold")
			local fr_threshold_val = "2345"
			if fr_threshold then
				fr_threshold_val = fr_threshold
			end

			--Intra-BSS Traffic
			local IntraBSS_state = luci.http.formvalue("IntraBSS_state")
			local IntraBSS_state_val = "0"
			if IntraBSS_state then
				IntraBSS_state_val = IntraBSS_state
			end

			--tx power
			local txPower = luci.http.formvalue("TxPower_value")
			local txPower_val = "100"
			if txPower then
				txPower_val = txPower
			end

			--wmm QoS
			local wmm_enable = luci.http.formvalue("WMM_QoS")
			local wmm_enable_val = "WMM"
			if (wmm_enable == "1" or wmm_enable == "0") then
				wmm_enable_val = wmm_enable
			end

			sys.exec("/bin/WiFi_GUI_ctrl advanced24G "..rts_Threshold_val.." "..fr_threshold_val.." "..IntraBSS_state_val.." "..txPower_val.." "..wmm_enable_val)
		end

		local show_val=sys.exec("/bin/WiFi_GUI_ctrl advanced24G_get_val")
		local val_list=NEW_split(show_val,"<;;>")

		luci.template.render("expert_configuration/wlanadvanced",{
										rts_frag_WMM_choice = val_list[1],
										rts_Threshold = val_list[2],
										fr_threshold = val_list[3],
										WMM_QoS = val_list[4],
										IntraBSS = val_list[5],
										TxPower = val_list[6],
										})
	-- else
	-- 	local changed = 0
	-- 	local RTS_Set
	-- 	local Frag_Set
	-- 	local WMM_Choose
	-- 	local wireless_mode = uci:get("wireless", "wifi0", "hwmode")
	--     if ( wireless_mode == "11gn" or  wireless_mode == "11n" or wireless_mode == "11bgn" ) then
	--         uci:set("wireless", "ath0", "rts",2346)
	-- 		uci:set("wireless", "ath0", "frag",2346)
	-- 		uci:set("wireless", "ath0", "wmm",1)

	--         uci:commit("wireless")
	--         RTS_Set="disabled"
	-- 		Frag_Set="disabled"
	-- 		WMM_Choose="disabled"
	--     end

	-- 	if apply then
	-- --rts_Threshold
	-- 		local rts_Threshold = luci.http.formvalue("rts_Threshold")
	-- 		local rts_Threshold_old = uci:get("wireless", "ath0","rts")
	-- 		if not (rts_Threshold) then
	-- 			changed = 1
	-- 			uci:set("wireless", "ath0","rts", "2345")
	-- 		else
	-- 			if not (rts_Threshold == rts_Threshold_old) then
	-- 			changed = 1
	-- 			uci:set("wireless", "ath0","rts", rts_Threshold)
	-- 			end
	-- 		end
	-- --fr_threshold
	-- 		local fr_threshold = luci.http.formvalue("fr_threshold")
	-- 		local fr_threshold_old = uci:get("wireless", "ath0","frag")
	-- 		if not (fr_threshold) then
	-- 			changed = 1
	-- 			uci:set("wireless", "ath0","frag", "2354")
	-- 		else
	-- 			if not (fr_threshold == fr_threshold_old) then
	-- 			changed = 1
	-- 			uci:set("wireless", "ath0","frag", fr_threshold)
	-- 			end
	-- 		end
	-- --Intra-BSS Traffic
	-- 		local IntraBSS_state = luci.http.formvalue("IntraBSS_state")
	-- 		local IntraBSS_state_old = uci:get("wireless", "ath0","IntraBSS")
	-- 		if not (IntraBSS_state) then
	-- 			changed = 1
	-- 			uci:set("wireless", "ath0","IntraBSS", "0")
	-- 		else
	-- 			if not (IntraBSS_state == IntraBSS_state_old) then
	-- 			changed = 1
	-- 			uci:set("wireless", "ath0","IntraBSS", IntraBSS_state)
	-- 			end
	-- 		end
	-- --tx power
	-- 		local txPower = luci.http.formvalue("TxPower_value")
	-- 		local txPower_old = uci:get("wireless", "wifi0", "txpower")
	-- 		if not (txPower) then
	-- 			changed = 1
	-- 			uci:set("wireless", "wifi0", "txpower","100")
	-- 		else
	-- 			if not (txPower == txPower_old) then
	-- 			changed = 1
	-- 			uci:set("wireless", "wifi0", "txpower",txPower)
	-- 			end
	-- 		end

	-- --wmm QoS
	-- 		local wmm_enable = luci.http.formvalue("WMM_QoS")

	-- 		if (wmm_enable == "1") then
	-- 			uci:set("wireless", "ath0","wmm", wmm_enable)
	-- 			changed = 1
	-- 		elseif (wmm_enable == "0") then
	-- 			uci:set("wireless", "ath0","wmm", wmm_enable)
	-- 			changed = 1
	-- 		end

	-- 		if (changed == 1) then
	-- 			uci:commit("wireless")
	-- 			sys.exec("echo wifi0 >/tmp/WirelessDev")
	-- 			uci:apply("wireless")
	-- 		end
	-- 	end
	-- 	luci.template.render("expert_configuration/wlanadvanced",{rts_set=RTS_Set, frag_set=Frag_Set, wmm_choice=WMM_Choose})
	-- end
end

function wlan_qos()
	local apply = luci.http.formvalue("sysSubmit")
	local wireless_mode = uci:get("wireless", "wifi0", "hwmode")
	local WMM_Choose

	if ( wireless_mode == "11gn" or  wireless_mode == "11n" or wireless_mode == "11bgn" ) then
		uci:set("wireless", "ath0", "wmm",1)
		uci:commit("wireless")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		WMM_Choose="disabled"
	end

	if apply then
		local wmm_enable = luci.http.formvalue("WMM_QoS")

		if (wmm_enable == "1") then
			uci:set("wireless", "ath0","wmm", wmm_enable)
		elseif (wmm_enable == "0") then
			uci:set("wireless", "ath0","wmm", wmm_enable)
		end

		sys.exec("echo wifi0 >/tmp/WirelessDev")
		uci:commit("wireless")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("wireless")
	end

	luci.template.render("expert_configuration/wlanqos", {wmm_choice=WMM_Choose})
end

function wlanatf()
	local apply = luci.http.formvalue("apply")

	if apply then
		local atfenable = luci.http.formvalue("atfState")

		sys.exec("/bin/WiFi_GUI_ctrl wifiATF_Apply "..atfenable)
	end

	local show_val=sys.exec("/bin/WiFi_GUI_ctrl wifiATF_get_val")
	local val_list=NEW_split(show_val,"<;;>")

	luci.template.render("expert_configuration/wlanatf",{
								atfEnabled = val_list[1],
								})
end

function wlan_wps()
	require("luci.model.uci")
	local apply = luci.http.formvalue("sysSubmit")

	local iface_select = luci.http.formvalue("band")
	if (iface_select == "5G") then
		iface_select_val = "5G"
	else
		iface_select_val = "24G"
	end

	local genPin = luci.http.formvalue("Generate")
	local genPin_val = "None"
	if genPin then
		genPin_val = "genPin"
	end

	local enable_wps_btn = luci.http.formvalue("wps_button")
	local enable_wps_btn_val = "NONE"
	if enable_wps_btn then
		enable_wps_btn_val = "enable"
	end

	local enable_wps_pin = luci.http.formvalue("wps_pin")
	local enable_wps_pin_val = "NONE"
	local pincode = "NONE"
	if enable_wps_pin then
		enable_wps_pin_val = "enable"
		pincode = luci.http.formvalue("wps_pincode")
		if ( string.find(pincode, "-") or string.find(pincode, " ")) then
			pincode = string.sub(pincode,1,4)..string.sub(pincode,6,9)
		end
	end

	local releaseConf = luci.http.formvalue("Release")
	local releaseConf_val = "NONE"
	if releaseConf then
		releaseConf_val = "enable"
	end

	if apply then
		local wps_enable = luci.http.formvalue("wps_function")
		local pincode_choice = luci.http.formvalue("pincode_function")
		local pincode_choice_val = "None"
		if pincode_choice then
			pincode_choice_val = pincode_choice
		end

		sys.exec("/bin/WiFi_GUI_ctrl wps_Apply "..iface_select_val.." "..wps_enable.." "..pincode_choice_val)
	end
		local show_val=sys.exec("/bin/WiFi_GUI_ctrl wps_get_val "..iface_select_val.." "..genPin_val.." "..enable_wps_btn_val.." "..enable_wps_pin_val.." "..pincode.." "..releaseConf_val)
		local val_list=NEW_split(show_val,"<;;>")

		wps_btn_pin_status = val_list[5]

		if (wps_btn_pin_status ~= "1") then
			if enable_wps_btn or enable_wps_pin then
				wps_btn_pin_status = "3"
				for i=1,125 do
					sys.exec("sleep 1")
					if io.open( "/tmp/pbc_overlap", "r" ) then
						wps_btn_pin_status = "2"
						break;
					end

					if io.open( "/tmp/wps_success", "r" ) then
						wps_btn_pin_status = "4"
						break;
					end

					if io.open( "/tmp/wps_timeout", "r" ) then
						wps_btn_pin_status = "3"
						break;
					end
				end
			end
		end

		luci.template.render("expert_configuration/wlanwps",{
									iface_select = iface_select_val,
									WPS_set = val_list[1],
									WPS_Enabled = val_list[2],
									WPS_PinEnable = val_list[3],
									WPS_PinNum = val_list[4],
									wps_btn_pin_status = wps_btn_pin_status,
									ConfigStatus = val_list[6],
									SSID = val_list[7],
									RadioMode = val_list[8],
									SecureMode = val_list[9],
									})
	-- else

	-- 	local releaseConf = luci.http.formvalue("Release")
	-- 	local genPin = luci.http.formvalue("Generate")
	-- 	local pincode = uci:get("wps","wps","appin")
	-- 	local wps_enable = uci:get("wps","wps","enabled")
	-- 	local wps_choice = luci.http.formvalue("wps_function")
	-- 	local pincode_enable = uci:get("wps","wps","PinEnable")
	-- 	local pincode_choice = luci.http.formvalue("pincode_function")
	-- 	local wps_set
	-- 	local pincode_set
	-- 	local wps_change
	-- 	local wps_chk -- +
	-- --	local configured -- -
	-- 	local apssid
	-- 	local radiomode
	-- 	local authmode
	-- 	local encryptype
	-- 	local securemode
	-- 	local config_status
	-- --	local configfile -- -
	-- 	local wps_enable_choose
	-- 	local security_mode
	-- 	local WPAPSKCompatible_24G = uci.get("wireless", "ath0", "WPAPSKCompatible")
	--     local WPACompatible_24G = uci.get("wireless", "ath0", "WPACompatible")
	-- 	local hstapd_cli = "hostapd_cli -p /tmp/run/hostapd-wifi0/ -i ath0 " -- +
	-- 	local wireless_disabled = uci:get("wireless", "wifi0","disabled")

	-- 	if ( wireless_disabled=="1" or wireless_disabled==nil ) then
	-- 		wireless_disabled=true
	-- 	else
	-- 		wireless_disabled=false
	-- 	end

	-- 	security_mode=uci:get("wireless","ath0","auth")

	-- 	if( security_mode=="WEPAUTO" or security_mode=="SHARED" or security_mode=="WPA" or security_mode=="WPA2" ) then
	-- 		wps_enable_choose="disabled"
	-- 	end

	-- 	if releaseConf then
	-- 		uci:set("wps","wps","conf",0)
	-- 		uci:commit("wps")
	-- --		sys.exec("iwpriv ra0 set WscConfStatus=1")    -
	-- 		sys.exec("echo wifi0 >/tmp/WirelessDev")
	-- 		uci:apply("wireless")  -- +
	-- 		-- Re-generate the pin code when release configuration
	-- 		if(pincode_enable=="1") then
	-- 			pincode=sys.exec(hstapd_cli .. "wps_ap_pin random" )
	-- 			uci:set("wps","wps","appin",pincode)
	-- 			uci:commit("wps")
	-- 		end
	-- 		sys.exec("wps ath0 on")
	-- 	end

	-- --	sys.exec("wps_api ra0 1 > /tmp/wps_config")  -
	-- 	sys.exec(hstapd_cli .. "get_config" .. "" ..  "> /tmp/wps_config")
	-- 	local configfile = io.open("/tmp/wps_config", "r")
	-- --	configured = configfile:read("*line") -
	--     local tmp = configfile:read("*all")
	-- 	configfile:close()

	-- 	local configured = tmp:match("wps_state=(%a+)")

	-- 	--Get the configuration information
	-- 	if ( configured == "configured" ) then
	-- 		uci:set("wps","wps","conf",1)
	-- 		uci:commit("wps")

	-- 		apssid =  uci:get("wireless","ath0","ssid")
	-- 		radiomode = uci:get("wireless","wifi0","hwmode")
	-- 		radiomode = "802."..radiomode
	-- 		authmode = uci:get("wireless","ath0","encryption")

	-- 		if not apssid then
	-- 			apssid=luci.sys.exec("cat /tmp/tmpSSID24G")
	-- 		end

	-- 		if authmode == "WPAPSK" then
	-- 			securemode="WPA-PSK"
	-- 		elseif authmode == "WPA2PSK" then
	-- 		-- add by darren 2012.03.07
	--                         if WPAPSKCompatible_24G == "0" then
	--                                 securemode="WPA2-PSK"
	--                         elseif WPAPSKCompatible_24G == "1" then
	--                                 securemode="WPA-PSK / WPA2-PSK"
	--                         end
	--                 --
	-- 		elseif authmode == "WEPAUTO" or authmode == "SHARED" then
	-- 			securemode="WEP"
	-- 		elseif authmode == "NONE" then
	-- 			securemode="No Security"
	-- 		elseif authmode == "WPAPSKWPA2PSK" then
	-- 			securemode="WPA2-PSK"

	-- 		-- add by darren 2012.03.07
	--                 elseif authmode == "WPA2" then
	--                         if WPACompatible_24G == "0" then
	--                                 securemode=authmode
	--                         elseif WPACompatible_24G == "1" then
	--                                 securemode="WPA / WPA2"
	--                         end
	--                 --
	-- 		else
	-- 			securemode=authmode
	-- 		end

	-- 		config_status="Configured"
	-- 	else
	-- 		config_status="Unconfigured"
	-- 	end
	-- 	--Generate a new vendor pin code
	-- 	if genPin then
	-- 		pincode=sys.exec(hstapd_cli .. "wps_ap_pin random" )
	-- 		uci:set("wps","wps","appin",pincode)
	-- 		uci:commit("wps")
	-- 		sys.exec("wps ath0 on")
	-- 	end
	-- 	--Variable "wps_set" will be used in the GUI
	-- 	if (wps_enable == "1") then
	-- 		wps_set="enabled"
	-- 	elseif (wps_enable == "0") then
	-- 		wps_set="disabled"
	-- 	end

	-- 	--Variable "pincode_set" will be used in the GUI
	--         if (pincode_enable == "1") then
	--                 pincode_set="enabled"
	--         elseif (pincode_enable == "0") then
	--                 pincode_set="disabled"
	--         end


	-- 	if apply then

	-- 		--when WPS button Disable -> Enable, pincode_choice will be "NULL"
	-- 		if (wps_choice == "1") then
	-- 			if (wps_enable == "0") then --From disable wps to enable wps
	-- 				wps_chk="1"
	-- 				if (pincode_enable == "1") then --PIN-code enable
	--                                 pincode_enable=1
	--                                 pincode_set="enabled"
	-- 								wps_change = true

	--                 elseif (pincode_enable == "0") then --PIN-code disable
	-- 								pincode_enable=0
	-- 								pincode_set="disabled"
	-- 								wps_change = true
	-- 				end
	-- 			elseif(wps_enable == "1") then
	-- 				if (pincode_choice == "1") then
	--                      if (pincode_enable == "0") then --From disable PIN-code to enable PIN-code
	--                         pincode_enable=1
	--                         pincode_set="enabled"
	-- 						wps_change = true
	--                      end
	--                 elseif (pincode_choice == "0") then --From enable PIN-code to disable PIN-code
	--                      if (pincode_enable == "1") then
	-- 					    pincode_enable=0
	-- 						pincode_set="disabled"
	-- 						wps_change = true
	-- 					end
	--                  end

	-- 			end

	-- 			if wps_change then
	-- 				wps_enable=1
	--               	wps_set="enabled"
	-- 				uci:set("wps","wps", "PinEnable", pincode_enable)
	--         	    uci:set("wps","wps", "enabled", wps_enable)
	--                 uci:commit("wps")
	-- 				if (wps_chk == "1") then
	-- 					sys.exec("echo wifi0 >/tmp/WirelessDev")
	-- 					uci:apply("wireless")
	--                 end
	-- 			end

	-- 			sys.exec("wps ath0 on")

	-- 		elseif (wps_choice == "0") then --From enable wps to disable wps
	-- 			if (wps_enable == "1") then
	--                 wps_chk="1"
	--             end
	-- 			wps_enable=0
	-- 			wps_set="disabled"

	-- 			uci:set("wps","wps", "PinEnable", pincode_enable)
	--             uci:set("wps","wps", "enabled", wps_enable)
	--         	uci:commit("wps")

	-- 			if (wps_chk == "1") then
	-- 				sys.exec("echo wifi0 >/tmp/WirelessDev")
	-- 				uci:apply("wireless")
	--             end

	-- 			sys.exec("wps ath0 off")

	-- 		end
	-- 		sys.exec("/sbin/zyxel_led_ctrl all")

	-- 	end
	-- ----WPSSTATION
	-- 	local wps_enable = uci:get("wps","wps","enabled")
	-- 	local enable_wps_btn = luci.http.formvalue("wps_button")
	-- 	local enable_wps_pin = luci.http.formvalue("wps_pin")
	-- 	local configured = uci:get("wps","wps","conf")
	-- 	local valid = 1
	-- 	local hstapd_cli = "hostapd_cli -p /tmp/run/hostapd-wifi0/ -i ath0 "
	-- 	--Variable "wps_set" will be used in the GUI
	-- 	if (wps_enable == "1") then
	-- 		wps_set="enabled"
	-- 	elseif (wps_enable == "0") then
	-- 		wps_set="disabled"
	-- 	end

	-- --	if (configured == "1") then
	-- --		config_status = "conf"
	-- --	else
	-- --		config_status = "unconf"
	-- --	end

	-- 	local fd
	-- 	if enable_wps_btn then
	-- 		sys.exec("zyxel_WPS_ctrl WPS24G_GUI")

	-- 		for i=1,120 do
	-- 			sys.exec("sleep 1")
	-- 			if io.open( "/tmp/pbc_overlap", "r" ) then
	-- 				valid = 2
	-- 				break;
	-- 			end
	-- 			if io.open( "/tmp/wps_success", "r" ) then
	-- 				valid = 4
	-- 				break;
	-- 			end
	-- 			if io.open( "/tmp/wps_timeout", "r" ) then
	-- 				valid = 3
	-- 				break;
	-- 			end
	-- 		end

	-- 		luci.template.render("expert_configuration/wlanwps",{WPS_Enabled = wps_set, pin_valid = valid,
	-- 															AP_PIN = pincode,
	-- 															SSID = apssid,
	-- 															RadioMode = radiomode,
	-- 															SecureMode = securemode,
	-- 															ConfigStatus = config_status,
	-- 															WPS_Enabled_Choose = wps_enable_choose,
	-- 															PINCode_Enabled = pincode_set,
	-- 															Wireless_Disabled = wireless_disabled})
	-- 		return
	-- 	end

	-- 	if enable_wps_pin then
	-- 		local pincode
	-- 		local pin_verify
	-- 		pincode = luci.http.formvalue("wps_pincode")
	-- 		if ( string.find(pincode, "-") or string.find(pincode, " ")) then
	-- 			pincode = string.sub(pincode,1,4)..string.sub(pincode,6,9)
	-- 		end
	-- 		pin_verify = sys.exec(hstapd_cli .. "wps_check_pin " .. pincode)
	-- 		if ( pin_verify == pincode ) then
	-- 			chk_led = uci:get("system","led","on")
	-- 			sys.exec("rm /tmp/pbc_overlap /tmp/wps_success /tmp/wps_connect_timeout")
	-- 			sys.exec("killall -9 wps")
	-- 			fd = io.popen("wps ath0 on wps_pin ".. pincode .. " &")
	-- 			sys.exec("zyxel_led_ctrl WPS24G "..chk_led.." ")

	-- 			for i=1,125 do
	-- 				sys.exec("sleep 1")
	-- 				if io.open( "/tmp/pbc_overlap", "r" ) then
	-- 					break;
	-- 				end
	-- 				if io.open( "/tmp/wps_success", "r" ) then
	-- 					break;
	-- 				end
	-- 				if io.open( "/tmp/wps_connect_timeout", "r" ) then
	-- 					break;
	-- 				end
	-- 			end

	-- 			wps_conf = sys.exec("hostapd_cli -p /tmp/run/hostapd-wifi0/ -i ath0 get_config |grep wps_state")

	-- 			if string.match(wps_conf, "wps_state=not configured") then
	-- 				uci:set("wps","wps","conf",0)
	-- 			else
	-- 				uci:set("wps","wps","conf",1)
	-- 			end

	-- 			uci:commit("wps")
	-- 			sys.exec("killall wps")
	-- 			sys.exec("zyxel_led_ctrl WPS24G 0")
	-- 		else
	-- 			luci.template.render("expert_configuration/wlanwps",{WPS_Enabled = wps_set, pin_valid = 0,
	-- 																SSID = apssid,
	-- 																RadioMode = radiomode,
	-- 																SecureMode = securemode,
	-- 																ConfigStatus = config_status,
	-- 																WPS_Enabled_Choose = wps_enable_choose,
	-- 																PINCode_Enabled = pincode_set,
	-- 																Wireless_Disabled = wireless_disabled})
	-- 			return
	-- 		end
	-- 	end
	-- ----WPSSTATION
	-- 	luci.template.render("expert_configuration/wlanwps", {AP_PIN = pincode,
	-- 								SSID = apssid,
	-- 								RadioMode = radiomode,
	-- 								SecureMode = securemode,
	-- 								ConfigStatus = config_status,
	-- 								WPS_Enabled = wps_set,
	-- 								WPS_Enabled_Choose = wps_enable_choose,
	-- 								PINCode_Enabled = pincode_set,
	-- 								pin_valid = 1,
	-- 								Wireless_Disabled = wireless_disabled})
	-- end
end

function wlanwpsstation()
	local wps_enable = uci:get("wps","wps","enabled")
	local wps_set
	local enable_wps_btn = luci.http.formvalue("wps_button")
	local enable_wps_pin = luci.http.formvalue("wps_pin")
	local configured = uci:get("wps","wps","conf")
	local config_status
	local valid = 1
	local hstapd_cli = "hostapd_cli -p /tmp/run/hostapd-wifi0/ -i ath0 "
	--Variable "wps_set" will be used in the GUI
	if (wps_enable == "1") then
		wps_set="enabled"
	elseif (wps_enable == "0") then
		wps_set="disabled"
	end

--	if (configured == "1") then
--		config_status = "conf"
--	else
--		config_status = "unconf"
--	end

	local fd
	if enable_wps_btn then
		sys.exec("killall -9 wps")
		fd = io.popen("wps ath0 on wps_btn &")
		sys.exec("rm /tmp/pbc_overlap")
		sys.exec("rm /tmp/wps_success")
		sys.exec("rm /tmp/wps_timeout")
		for i=1,120 do
			sys.exec("sleep 1")
			if io.open( "/tmp/pbc_overlap", "r" ) then
				valid = 2
				sys.exec("killall wps")
				sys.exec("led_ctrl WiFi_2G off && sleep 10 && led_ctrl WiFi_2G on &")
				sys.exec("rm /tmp/wps_link_success")
				break;
			end

			if io.open( "/tmp/wps_success", "r" ) then
				valid = 4
				sys.exec("killall wps")
				sys.exec("led_ctrl WiFi_2G off && sleep 10 && led_ctrl WiFi_2G on &")
				sys.exec("rm /tmp/wps_link_success")
				break;
			end

			if io.open( "/tmp/wps_timeout", "r" ) then
				valid = 3
				sys.exec("killall wps")
				sys.exec("led_ctrl WiFi_2G off && sleep 10 && led_ctrl WiFi_2G on &")
				sys.exec("rm /tmp/wps_link_success")
				break;
			end
		end
		luci.template.render("expert_configuration/wlanwpsstation",{WPS_Enabled = wps_set, pin_valid = valid})
		return
	end

	if enable_wps_pin then
		local pincode
		local pin_verify
		pincode = luci.http.formvalue("wps_pincode")
		if ( string.find(pincode, "-") or string.find(pincode, " ")) then
			pincode = string.sub(pincode,1,4)..string.sub(pincode,6,9)
		end

		pin_verify = sys.exec(hstapd_cli .. "wps_check_pin " .. pincode)
		if ( pin_verify == pincode ) then
			sys.exec("killall -9 wps")
			fd = io.popen("w ".. pincode .. " &")
		else
			luci.template.render("expert_configuration/wlanwpsstation",{WPS_Enabled = wps_set, pin_valid = 0})
			return
		end
	end

	luci.template.render("expert_configuration/wlanwpsstation",{WPS_Enabled = wps_set, pin_valid = 1})
end

function wlanscheduling()
	local product_name = uci:get("system", "main", "product_name")
	local apply = luci.http.formvalue("sysSubmit")

	if apply then
		local enabled = luci.http.formvalue("WLanSchRadio")
		local sun = luci.http.formvalue("t0")
		local mon = luci.http.formvalue("t1")
		local tue = luci.http.formvalue("t2")
		local wed = luci.http.formvalue("t3")
		local thu = luci.http.formvalue("t4")
		local fri = luci.http.formvalue("t5")
		local sat = luci.http.formvalue("t6")

		sys.exec("/bin/WiFi_GUI_ctrl wifi_schedule_Apply 24G "..enabled.." "..sun.." "..mon.." "..tue.." "..wed.." "..thu.." "..fri.." "..sat)
	end

	local show_val=sys.exec("/bin/WiFi_GUI_ctrl wifi_schedule 24G")
	local val_list=NEW_split(show_val,"<;;>")

	luci.template.render("expert_configuration/wlanscheduling",{
						ENABLED = val_list[1],
						SUN = val_list[2],
						MON = val_list[3],
						TUE = val_list[4],
						WED = val_list[5],
						THU = val_list[6],
						FRI = val_list[7],
						SAT = val_list[8]
						})
end

--Wireless client
function wlan_apcli_wisp()
	local apply = luci.http.formvalue("apply")

	if apply then
		local ApCliSsid = luci.http.formvalue("apcli_ssid")
		local ApCliBssid = luci.http.formvalue("apcli_bssid")
		local ApCliAuthMode = luci.http.formvalue("apcli_mode")
		local ApCliWepEncry = luci.http.formvalue("wep_encry")
		local ApCliKeyType = luci.http.formvalue("WEPKey_Code")
		local ApCliDefaultKeyId = luci.http.formvalue("DefWEPKey")
		local ApCliKey1Str = luci.http.formvalue("apcli_key1")
		local ApCliKey2Str = luci.http.formvalue("apcli_key2")
		local ApCliKey3Str = luci.http.formvalue("apcli_key3")
		local ApCliKey4Str = luci.http.formvalue("apcli_key4")
		local ApClicipher = luci.http.formvalue("cipher")
		local ApCliWPAPSK = luci.http.formvalue("apcli_wpapsk")
		local ApCliWepMethod = luci.http.formvalue("auth_method")
		local passphrase = luci.http.formvalue("wep_passphrase")
		local auth_method = luci.http.formvalue("auth_method")

		uci:set("wireless_client", "general", "ApCliSsid", ApCliSsid)
		uci:set("wireless_client", "general", "ApCliBssid", ApCliBssid)
		uci:set("wireless_client", "general", "ApCliAuthMode", ApCliAuthMode)

		if (ApCliAuthMode == "SHARED") then
			uci:set("wireless_client", "general", "ApCliKeyType", ApCliKeyType)
			uci:set("wireless_client", "general", "ApCliDefaultKeyId", ApCliDefaultKeyId)
			uci:set("wireless_client", "general", "ApCliEncrypType", "WEP")
			uci:set("wireless_client", "general", "ApCliWepMethod", ApCliWepMethod)

			if ApCliKey1Str then
				uci:set("wireless_client", "general", "ApCliKey1Str", ApCliKey1Str)
			end
			if ApCliKey2Str then
				uci:set("wireless_client", "general", "ApCliKey2Str", ApCliKey2Str)
			end
			if ApCliKey3Str then
				uci:set("wireless_client", "general", "ApCliKey3Str", ApCliKey3Str)
			end
			if ApCliKey4Str then
				uci:set("wireless_client", "general", "ApCliKey4Str", ApCliKey4Str)
			end
		elseif (ApCliAuthMode == "OPEN") then
			uci:set("wireless_client", "general", "ApCliEncrypType", "NONE")
		else
			if ApClicipher == "0" then
				uci:set("wireless_client", "general", "ApCliEncrypType", "TKIP")
			else
				uci:set("wireless_client", "general", "ApCliEncrypType", "AES")
			end

			uci:set("wireless_client", "general", "ApCliWPAPSK", ApCliWPAPSK)
		end

		--ChannelID
		local Apcli_channel = luci.http.formvalue("apcli_channel")
		local Channel_ID_old = uci:get("wireless", "ra0","channel",Channel_ID)

		if not(Apcli_channel)then
			Apcli_channel = Channel_ID_old
		end

		if not(Apcli_channel == Channel_ID_old) then
			uci:set("wireless", "ra0","channel",Apcli_channel)
		end

		uci:set("wireless", "ra0","AutoChannelSelect","0")

		uci:commit("wireless")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:commit("wireless_client")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("wireless_client")
	end

	local file = io.open("/var/countrycode", "r")
	local temp = file:read("*all")
	file:close()

	local code = temp:match("([0-9a-fA-F]+)")
	local region = country_code_table[code:gsub("[a-fA-F]", string.upper)]

	luci.template.render("expert_configuration/wlan_apcli_wisp",{channels = channelRange[region[1]]})

end

function wlan_apcli_wisp_ur_site_survey()

	local apply = luci.http.formvalue("survey_apply")

	if apply then
		local ssid = luci.http.formvalue("site_ssid")
		--local signal = luci.http.formvalue("site_signal")
		local channel = luci.http.formvalue("site_channel")
		local auth = luci.http.formvalue("site_auth")
		local encry = luci.http.formvalue("site_encry")
		local bssid = luci.http.formvalue("site_bssid")
		local nt = luci.http.formvalue("site_nt")
		local network_type
		local auth_selected
		local encry_selected

		if (nt == "In") then
			network_type = "1"
		elseif (nt == "Ad") then
			network_type = "0"
		else
			network_type = "1"
		end

		if auth:find("WPA2PSK") then
			auth_selected = "WPA2PSK"
		elseif auth:find("WPAPSK") then
			auth_selected = "WPAPSK"
		else
			auth_selected = "OPEN"
		end

		if encry:find("TKIP") then
			encry_selected = "TKIP"
		elseif encry:find("AES") then
			encry_selected = "AES"
		elseif encry:find("WEP") then
			encry_selected = "WEP"
		else
			encry_selected = "NONE"
		end

		local url = luci.dispatcher.build_url("expert","configuration","network","wlan","wlan_apcli_wisp")
		luci.http.redirect(url .. "?" .. "site_ssid=" .. luci.http.protocol.urlencode(ssid) .. "&site_network_type=" .. network_type  .. "&site_channel=" .. channel .. "&site_auth=" .. auth_selected .. "&site_encry=" .. encry_selected .. "&site_bssid=" .. bssid .. "&site_survey=1")

		return
	end

	luci.template.render("expert_configuration/wlan_apcli_wisp_ur_site_survey")
end

function wlan_apcli_wisp5G()
	luci.template.render("expert_configuration/wlan_apcli_wisp5G")
end

function wlan_apcli_wisp_ur_site_survey5G()
	luci.template.render("expert_configuration/wlan_apcli_wisp_ur_site_survey5G")
end
--Wireless client 2.4G end

--Wireless 5G
function wlan_general_5G()
	local apply = luci.http.formvalue("sysSubmit")
	local wps_enable = uci:get("wps5G","wps","enabled")
	local autoChannl = luci.http.formvalue("autoChannl")
	local channels

	local product_name = uci:get("system","main","product_name")

--	if (product_name == "NBG6817" or product_name == "NBG6617") then
		if apply then
			--SSID
			local SSID = luci.http.formvalue("SSID_value")
			--radioON
			local Wireless_enable = luci.http.formvalue("ssid_state")
			--HideSSID
			local chk_hidden = luci.http.formvalue("Hide_SSID")
			wireless_hidden = "1"
			if not (chk_hidden)then
				wireless_hidden = "0"
			end

			--ChannelID
			local Channel_ID = luci.http.formvalue("Channel_ID_index")
			--AutoChSelect
			local Auto_Channel = luci.http.formvalue("Auto_Channel")
			--ChannelWidth
			local Channel_Width = luci.http.formvalue("ChWidth_select")
			--WirelessMode
			local Wireless_Mode = luci.http.formvalue("Mode_select")

			--SecurityMode
			local security_mode = luci.http.formvalue("security_value")
			local security_mode_val = "NULL"
			if( security_mode == "NONE") then
				security_mode_val = security_mode
			elseif( security_mode == "WEP")then
				local EncrypAuto_shared = luci.http.formvalue("auth_method")
				local wep_passphrase = luci.http.formvalue("wep_passphrase")
				local WEP64_128 = luci.http.formvalue("WEP64_128")
				local WEPKey_Code = luci.http.formvalue("WEPKey_Code")
				local DefWEPKey = luci.http.formvalue("DefWEPKey")
				local wepkey1 = luci.http.formvalue("wep_key_1")
				local wepkey2 = luci.http.formvalue("wep_key_2")
				local wepkey3 = luci.http.formvalue("wep_key_3")
				local wepkey4 = luci.http.formvalue("wep_key_4")

				local EncrypAuto_shared_val = "EncrypAuto_shared"
				if EncrypAuto_shared then
					EncrypAuto_shared_val = EncrypAuto_shared
				end

				local wep_passphrase_val = "wep_passphrase"
				if wep_passphrase then
					wep_passphrase_val = wep_passphrase
				end

				local WEP64_128_val = "WEP64_128"
				if WEP64_128 == "0" or WEP64_128 == "1" then
					WEP64_128_val = WEP64_128
				end

				local WEPKey_Code_val = "WEPKey_Code"
				if WEPKey_Code == "0" or WEPKey_Code == "1" then
					WEPKey_Code_val = WEPKey_Code
				end

				local DefWEPKey_val = "DefWEPKey"
				if DefWEPKey then
					DefWEPKey_val = DefWEPKey
				end

				local wepkey1_val = "wepkey1"
				if wepkey1 then
					wepkey1_val = wepkey1
				end

				local wepkey2_val = "wepkey2"
				if wepkey2 then
					wepkey2_val = wepkey2
				end

				local wepkey3_val = "wepkey3"
				if wepkey3 then
					wepkey3_val = wepkey3
				end

				local wepkey4_val = "wepkey4"
				if wepkey4 then
					wepkey4_val = wepkey4
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s", security_mode, EncrypAuto_shared_val, wep_passphrase_val, WEP64_128_val, WEPKey_Code_val, DefWEPKey_val, wepkey1_val, wepkey2_val, wepkey3_val, wepkey4_val)
			elseif(security_mode == "WPA")then
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
				local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
				local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
				local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")

				local RekeyInterval_val = "3600"
				if RekeyInterval then
					RekeyInterval_val = RekeyInterval
				end

				local RadiusServerIP_val = "192.168.2.3"
				if RadiusServerIP then
					RadiusServerIP_val = RadiusServerIP
				end

				local RadiusServerPort_val = "1812"
				if RadiusServerPort then
					RadiusServerPort_val = RadiusServerPort
				end

				local RadiusServerSecret_val = "ralink"
				if RadiusServerSecret then
					RadiusServerSecret_val = RadiusServerSecret
				end

				local RadiusServerSessionTimeout_val = "0"
				if (RadiusServerSessionTimeout == "") then
					RadiusServerSessionTimeout_val = RadiusServerSessionTimeout
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s", security_mode, RekeyInterval_val, RadiusServerIP_val, RadiusServerPort_val, RadiusServerSecret_val, RadiusServerSessionTimeout_val)
			elseif(security_mode == "WPAPSK")then
				local WPAPSKkey = luci.http.formvalue("PSKey")
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")

				local WPAPSKkey_val = "WPAPSKkey"
				if WPAPSKkey then
					WPAPSKkey_val = WPAPSKkey
				end

				local RekeyInterval_val = "3600"
				if RekeyInterval then
					RekeyInterval_val = RekeyInterval
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s", security_mode, WPAPSKkey_val, RekeyInterval_val)
			elseif(security_mode == "WPA2")then
				local WPACompatible = luci.http.formvalue("wpa_compatible")
				local wpa2_pmf = luci.http.formvalue("wpa2_pmf")
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				local PMKCachePeriod = luci.http.formvalue("PMKCachePeriod")
				local PreAuthentication = luci.http.formvalue("PreAuthentication")
				local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
				local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
				local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
				local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")

				local WPACompatible_val = "0"
				if WPACompatible then
					WPACompatible_val = WPACompatible
				end

				local wpa2_pmf_val = "0"
				if wpa2_pmf then
					wpa2_pmf_val = wpa2_pmf
				end

				local RekeyInterval_val = "3600"
				if RekeyInterval then
					RekeyInterval_val = RekeyInterval
				end

				local PMKCachePeriod_val = "10"
				if (PMKCachePeriod == "") then
					PMKCachePeriod_val = PMKCachePeriod
				end

				local PreAuthentication_val = "0"
				if PreAuthentication then
					PreAuthentication_val = PreAuthentication
				end

				local RadiusServerIP_val = "192.168.2.3"
				if RadiusServerIP then
					RadiusServerIP_val = RadiusServerIP
				end

				local RadiusServerPort_val = "1812"
				if (RadiusServerPort == "") then
					RadiusServerPort_val = RadiusServerPort
				end

				local RadiusServerSecret_val = "ralink"
				if RadiusServerSecret then
					RadiusServerSecret_val = RadiusServerSecret
				end

				local RadiusServerSessionTimeout_val = "0"
				if RadiusServerSessionTimeout then
					RadiusServerSessionTimeout_val = RadiusServerSessionTimeout
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s", security_mode, WPACompatible_val, wpa2_pmf_val, RekeyInterval_val, PMKCachePeriod_val, PreAuthentication_val, RadiusServerIP_val, RadiusServerPort_val, RadiusServerSecret_val, RadiusServerSessionTimeout_val)
			elseif(security_mode=="WPA2PSK")then
				local WPAPSKkey = luci.http.formvalue("PSKey")
				local WPAPSKCompatible = luci.http.formvalue("wpapsk_compatible")
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				local wpa2psk_pmf = luci.http.formvalue("wpa2psk_pmf")

				local WPAPSKkey_val = "WPAPSKkey"
				if WPAPSKkey then
					WPAPSKkey_val = WPAPSKkey
				end

				local wpa2psk_pmf_val = "0"
				if wpa2psk_pmf then
					wpa2psk_pmf_val = wpa2psk_pmf
				end

				local RekeyInterval_val = "3600"
				if RekeyInterval then
					RekeyInterval_val = RekeyInterval
				end

				local WPAPSKCompatible_val = "0"
				if WPAPSKCompatible then
					WPAPSKCompatible_val = WPAPSKCompatible
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s<;;>%s<;;>%s", security_mode, WPAPSKkey_val, WPAPSKCompatible_val, RekeyInterval_val, wpa2psk_pmf_val)
			end

			sys.exec("/bin/WiFi_GUI_ctrl main_5G '"..SSID.."' "..Wireless_enable.." "..wireless_hidden.." "..Channel_ID.." "..Auto_Channel.." "..Channel_Width.." "..Wireless_Mode.." '"..security_mode_val.."'")
		end

		if autoChannl then
			country_code=sys.exec("/bin/WiFi_GUI_ctrl country_code")
			country_code_string = country_code:gsub("[a-fA-F]", string.upper)
			if (product_name == "NBG6817" or product_name == "NBG6617") then
				country_code_string = string.format("%s_QCA", country_code_string)
			end

			region = country_code_table[country_code_string]
			
			channel_width5G_number = 4
			if autoChannl:match("20") then
				channel_width5G_number = 2
			elseif autoChannl:match("40") then
				channel_width5G_number = 3
			end

			channels = channelRange5G[region[channel_width5G_number]]

			luci.http.write(channels)
			return
		end

		local show_val=sys.exec("/bin/WiFi_GUI_ctrl main_5G_get_val")

--		sys.exec("echo '"..show_val.."' > /dev/console")
		local val_list=NEW_split(show_val,"<;;>")

		country_code_string = val_list[19]:gsub("[a-fA-F]", string.upper)
		if (product_name == "NBG6817" or product_name == "NBG6617") then
			country_code_string = string.format("%s_QCA", country_code_string)
		end

		local region = country_code_table[country_code_string]

		local dfs_show="1"
		if val_list[19]:match("[fF][fF]") or val_list[19]:match("[cC][eE]") or val_list[19]:match("[eE][eE]") then
			dfs_show="0"
		end

		channel_width5G_number = 4
		if val_list[6]:match("20") then
			channel_width5G_number = 2
		elseif val_list[6]:match("40") then
			channel_width5G_number = 3
		end

		luci.template.render("expert_configuration/wlan5G", {
							product_name = product_name,
							wireless_enable = val_list[1],
							ssid = val_list[2],
							hide_ssid = val_list[3],
							Auto_Channel = val_list[4],
							wireless_channel = val_list[5],
							select_channel = val_list[21],
							bandwidth =val_list[6],
							mode = val_list[7],
							security = val_list[8],
							auth = val_list[9],
							wps_enabled = val_list[10],
							WPAPSKCompatible = val_list[11],
							chk_PMF = val_list[12],
							psk = val_list[13],
							keyRenewalInterval = val_list[14],
							RadiusServerIP = val_list[15],
							RadiusServerPort = val_list[16],
							RadiusServerSecret = val_list[17],
							RadiusServerSessionTimeout = val_list[18],
							dfs_show = dfs_show,
							dfs = val_list[20],
							country_code = val_list[19],
							channels = channelRange5G[region[channel_width5G_number]],
							WPACompatible = val_list[22],
							})

	-- else
	-- 	if apply then
	-- 		sys.exec("echo wifi0 > /tmp/wifi5G_macfilter_Apply")
	-- 		sys.exec("echo wifi0 > /tmp/wifi5G_Apply")

	-- 		sys.exec("kill $(ps | grep 'watch -tn 5 wps_conf_5G' | grep 'grep' -v | awk '{print $1}')")
	-- 	--SSID
	-- 		local SSID = luci.http.formvalue("SSID_value")
	-- 		local SSID_old = uci:get("wireless", "ath10","ssid")
	-- 		if not (SSID == SSID_old)then
	-- --			SSID = checkInjection(SSID)
	-- 			if SSID ~= false then
	-- 				uci:set("wireless", "ath10","ssid",SSID)
	-- 			end
	-- 		end--SSID
	-- 	--radioON
	-- 		local Wireless_enable = luci.http.formvalue("ssid_state")
	-- 		local Wireless_enable_old = uci:get("wireless", "wifi1","disabled")
	-- 		if not(Wireless_enable == Wireless_enable_old)then
	-- 			uci:set("wireless", "wifi1","disabled",Wireless_enable)
	-- 			uci:set("wireless", "ath10","disabled",Wireless_enable)
	-- 		end--radioON
	-- 	--HideSSID
	-- 		local wireless_hidden = luci.http.formvalue("Hide_SSID")
	-- 		local wireless_hidden_old = uci:get("wireless", "ath10","hidden")
	-- 		if not (wireless_hidden)then
	-- 			wireless_hidden = "0"
	-- 		else
	-- 			wireless_hidden = "1"
	-- 		end

	-- 		if not(wireless_hidden == wireless_hidden_old)then
	-- 			uci:set("wireless", "ath10","hidden",wireless_hidden)
	-- 		end
	-- 	--DFS
	-- 		--[[local dfs = luci.http.formvalue("DFS")
	-- 		if dfs then
	-- 			dfs=1
	-- 		else
	-- 			dfs=0
	-- 		end
	-- 		uci:set("wireless", "ath10","DFS",dfs)]]--
	-- 	--ChannelID
	-- 		local Channel_ID = luci.http.formvalue("Channel_ID_index")
	-- 		local Channel_ID_old = uci:get("wireless", "wifi1","channel")
	-- 		if not(Channel_ID)then
	-- 			Channel_ID = Channel_ID_old
	-- 		end
	-- 		if not(Channel_ID == Channel_ID_old) then
	-- 			uci:set("wireless", "wifi1","channel",Channel_ID)
	-- 		end
	-- 	--AutoChSelect
	-- 		local Auto_Channel = luci.http.formvalue("Auto_Channel")
	-- 		local Auto_Channel_old = uci:get("wireless", "wifi1","AutoChannelSelect")
	-- 		-- if not(Auto_Channel)then
	-- 			-- Auto_Channel = 0
	-- 		-- else
	-- 			-- Auto_Channel = 1
	-- 		-- end
	-- 		if not(Auto_Channel == Auto_Channel_old) then
	-- 			uci:set("wireless", "wifi1","AutoChannelSelect",Auto_Channel)
	-- 			if (Auto_Channel==1) then
	-- 				uci:set("wireless", "wifi1", "channel", "auto")
	-- 			end
	-- 			if (Wireless_enable=="1") then
	-- 				uci:set("wireless", "wifi1", "channel", "40")
	-- 			end
	-- 		end
	--         --ChannelWidth
	-- 		local Channel_Index = uci:get("wireless", "wifi1","channel")
	-- 		local Channel_Width = luci.http.formvalue("ChWidth_select")
	-- 		if ( Channel_Width == "80" and  Channel_Index == "132" ) then
	-- 			uci:set("wireless", "wifi1","channel_width", 40)
	-- 		elseif ( Channel_Width == "80" and  Channel_Index == "136" ) then
	-- 			uci:set("wireless", "wifi1","channel_width", 40)
	-- 		elseif ( Channel_Width == "80" and  Channel_Index == "140" ) then
	-- 			uci:set("wireless", "wifi1","channel_width", 20)
	-- 		elseif ( Channel_Width == "80" and  Channel_Index == "165" ) then
	--                         uci:set("wireless", "wifi1","channel_width", 20)
	-- 		elseif ( Channel_Width == "40" and  Channel_Index == "140" ) then
	-- 			uci:set("wireless", "wifi1","channel_width", 20)
	-- 		elseif ( Channel_Width == "40" and  Channel_Index == "165" ) then
	-- 			uci:set("wireless", "wifi1","channel_width", 20)
	-- 		else
	-- 			uci:set("wireless", "wifi1","channel_width", Channel_Width)
	-- 		end
	--         --WirelessMode
	-- 		local Wireless_Mode = luci.http.formvalue("Mode_select")
	-- 		uci:set("wireless", "wifi1","hwmode", Wireless_Mode)
	-- 		--if set 802.11n or 802.11ac default enable wmm
	-- 		if ( Wireless_Mode == "11an" or  Wireless_Mode == "11ac" ) then
	-- 			uci:set("wireless", "ath10", "wmm",1)
	-- 		end
	-- 	--SecurityMode
	-- 		local security_mode = luci.http.formvalue("security_value")
	-- 		if (security_mode) then
	-- 			--No security
	-- 			if( security_mode == "NONE") then
	-- 				uci:set("wireless", "wifi1","auth","OPEN")
	-- 				uci:set("wireless", "ath10","auth","NONE")
	-- 				uci:set("wireless", "ath10","encryption","NONE")
	-- 			end

	-- 			--WEP
	-- 			if( security_mode == "WEP")then
	-- 				local EncrypAuto_shared = luci.http.formvalue("auth_method")
	-- --				uci:set("wireless", "rai0","encryption","WEP")
	-- 				if (EncrypAuto_shared)	then
	-- 					if(EncrypAuto_shared == "WEPAUTO")then
	-- 						uci:set("wireless", "ath10","encryption","wep-mixed")
	-- 						uci:set("wireless", "ath10","auth",EncrypAuto_shared)
	-- 					elseif(EncrypAuto_shared == "SHARED") then
	-- 						uci:set("wireless", "ath10","encryption","wep-shared")
	-- 						uci:set("wireless", "ath10","auth",EncrypAuto_shared)
	-- 					end
	-- 				end
	-- 				local wep_passphrase = luci.http.formvalue("wep_passphrase")
	-- 				if not (wep_passphrase) then
	-- 					uci:set("wireless", "ath10","PassPhrase","")
	-- 				else
	-- 					uci:set("wireless", "ath10","PassPhrase",wep_passphrase)
	-- 				end
	-- 				--64-128bit
	-- 				local WEP64_128 = luci.http.formvalue("WEP64_128")
	-- 				if (WEP64_128)then
	-- 					if(WEP64_128 == "0")then--[[64-bit]]--
	-- 						uci:set("wireless", "ath10","wepencryp128", WEP64_128)
	-- 					elseif(WEP64_128 == "1") then--[[128-bit]]--
	-- 						uci:set("wireless", "ath10","wepencryp128", WEP64_128)
	-- 					end
	-- 				end
	-- 				--ASCIIHEX
	-- 				local WEPKey_Code = luci.http.formvalue("WEPKey_Code")
	-- 				if (WEPKey_Code == "1")then--[[HEx]]--
	-- 					uci:set("wireless", "ath10","keytype", "1")
	-- 				elseif (WEPKey_Code == "0") then--[[ASCII]]--
	-- 					uci:set("wireless", "ath10","keytype", "0")
	-- 				end
	-- 				--keyindex
	-- 				local DefWEPKey = luci.http.formvalue("DefWEPKey")
	-- 				if (DefWEPKey)then
	-- 					uci:set("wireless", "ath10","key", DefWEPKey)
	-- 				end
	-- 				--WEP key value
	--                 local wepkey
	--                 local key_name
	--                 for i=1,4 do
	--                     wepkey = luci.http.formvalue("wep_key_"..i)
	--                     key_name="key"..i
	--                     if ( wepkey ) then
	--                         uci:set("wireless", "ath10", key_name, wepkey)
	--                     else
	-- 						uci:set("wireless", "ath10", key_name, "")
	-- 					end
	-- 				end
	-- 			end

	-- 			--WPA
	-- 			if (security_mode == "WPA")then
	-- 				uci:set("wireless", "ath10","auth","WPA")
	-- 				uci:set("wireless", "ath10","encryption","WPA")

	-- 				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
	-- 				if (RekeyInterval == "") then
	-- 					uci:set("wireless", "ath10","RekeyInterval", "3600")
	-- 				else
	-- 					uci:set("wireless", "ath10","RekeyInterval", RekeyInterval)
	-- 				end
	-- 				--[[
	-- 				local PMKCachePeriod = luci.http.formvalue("PMKCachePeriod")
	-- 				if (PMKCachePeriod == "") then
	-- 					uci:set("wireless", "ath10","PMKCachePeriod", "10")
	-- 				else
	-- 					uci:set("wireless", "ath10","PMKCachePeriod", PMKCachePeriod)
	-- 				end
	-- 				]]--
	-- 				local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
	-- 				if (RadiusServerIP == "") then
	-- 					uci:set("wireless", "ath10","RADIUS_Server", "192.168.2.3")
	-- 				else
	-- 					uci:set("wireless", "ath10","RADIUS_Server", RadiusServerIP)
	-- 				end

	-- 				local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
	-- 				if (RadiusServerPort == "") then
	-- 					uci:set("wireless", "ath10","RADIUS_Port", "1812")
	-- 				else
	-- 					uci:set("wireless", "ath10","RADIUS_Port", RadiusServerPort)
	-- 				end

	-- 				local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
	-- 				if (RadiusServerSecret == "") then
	-- 					uci:set("wireless", "ath10","RADIUS_Key", "ralink")
	-- 				else
	-- 					uci:set("wireless", "ath10","RADIUS_Key", RadiusServerSecret)
	-- 				end

	-- 				local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")
	-- 				if (RadiusServerSessionTimeout == "") then
	-- 					uci:set("wireless", "ath10","session_timeout_interval", "0")
	-- 				else
	-- 					uci:set("wireless", "ath10","session_timeout_interval", RadiusServerSessionTimeout)
	-- 				end
	-- 				--[[
	-- 				local PreAuthentication = luci.http.formvalue("PreAuthentication")
	-- 				if (PreAuthentication == "") then
	-- 					uci:set("wireless", "ath10","PreAuth", "0")
	-- 				else
	-- 					uci:set("wireless", "ath10","PreAuth", PreAuthentication)
	-- 				end
	-- 				]]--
	-- 			end

	-- 			--WPAPSK
	-- 			if(security_mode == "WPAPSK")then
	-- 				uci:set("wireless", "ath10","auth","WPAPSK")
	-- 				uci:set("wireless", "ath10","encryption","WPAPSK")
	-- 				local WPAPSKkey = luci.http.formvalue("PSKey")
	-- 				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
	-- 				if (WPAPSKkey == "") then
	-- 					uci:set("wireless", "ath10","WPAPSKkey", "")
	-- 				else
	-- 					uci:set("wireless", "ath10","WPAPSKkey", WPAPSKkey)
	-- 				end
	-- 				if not(RekeyInterval) then
	-- 					uci:set("wireless", "ath10","RekeyInterval", "3600")
	-- 				else
	-- 					uci:set("wireless", "ath10","RekeyInterval", RekeyInterval)
	-- 				end
	-- 			end

	-- 			--WPA2
	-- 			if (security_mode == "WPA2")then
	-- 				uci:set("wireless", "ath10","auth","WPA2")
	-- 				uci:set("wireless", "ath10","encryption","WPA2")
	-- 				local WPACompatible = luci.http.formvalue("wpa_compatible")
	-- 				if not (WPACompatible) then
	-- 					uci:set("wireless", "ath10","WPACompatible", "0")
	-- 				else
	-- 					uci:set("wireless", "ath10","WPACompatible", WPACompatible)
	-- 				end

	-- 				local wpa2_pmf = luci.http.formvalue("wpa2_pmf")
	-- 				if not (wpa2_pmf) then
	-- 					uci:set("wireless", "ath10","PMF", "0")
	-- 				else
	-- 					uci:set("wireless", "ath10","PMF", wpa2_pmf)
	-- 				end

	-- 				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
	-- 				if (RekeyInterval == "") then
	-- 					uci:set("wireless", "ath10","RekeyInterval", "3600")
	-- 				else
	-- 					uci:set("wireless", "ath10","RekeyInterval", RekeyInterval)
	-- 				end

	-- 				local PMKCachePeriod = luci.http.formvalue("PMKCachePeriod")
	-- 				if (PMKCachePeriod == "") then
	-- 					uci:set("wireless", "ath10","PMKCachePeriod", "10")
	-- 				else
	-- 					uci:set("wireless", "ath10","PMKCachePeriod", PMKCachePeriod)
	-- 				end
	-- 				local PreAuthentication = luci.http.formvalue("PreAuthentication")
	-- 				if (PreAuthentication == "") then
	-- 					uci:set("wireless", "ath10","PreAuth", "0")
	-- 				else
	-- 					uci:set("wireless", "ath10","PreAuth", PreAuthentication)
	-- 				end
	-- 				local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
	-- 				if (RadiusServerIP == "") then
	-- 					uci:set("wireless", "ath10","RADIUS_Server", "192.168.2.3")
	-- 				else
	-- 					uci:set("wireless", "ath10","RADIUS_Server", RadiusServerIP)
	-- 				end

	-- 				local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
	-- 				if (RadiusServerPort == "") then
	-- 					uci:set("wireless", "ath10","RADIUS_Port", "1812")
	-- 				else
	-- 					uci:set("wireless", "ath10","RADIUS_Port", RadiusServerPort)
	-- 				end

	-- 				local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
	-- 				if (RadiusServerSecret == "") then
	-- 					uci:set("wireless", "ath10","RADIUS_Key", "ralink")
	-- 				else
	-- 					uci:set("wireless", "ath10","RADIUS_Key", RadiusServerSecret)
	-- 				end

	-- 				local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")
	-- 				if (RadiusServerSessionTimeout == "") then
	-- 					uci:set("wireless", "ath10","session_timeout_interval", "0")
	-- 				else
	-- 					uci:set("wireless", "ath10","session_timeout_interval", RadiusServerSessionTimeout)
	-- 				end

	-- 			end

	-- 			--WPA2PSK
	-- 			if(security_mode=="WPA2PSK")then
	-- 				uci:set("wireless", "ath10","auth","WPA2PSK")
	-- 				uci:set("wireless", "ath10","encryption","WPA2PSK")
	-- 				local WPAPSKkey = luci.http.formvalue("PSKey")
	-- 				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
	-- 				local WPAPSKCompatible = luci.http.formvalue("wpapsk_compatible")
	-- 				if (WPAPSKkey == "") then
	-- 					uci:set("wireless", "ath10","WPAPSKkey", "")
	-- 				else
	-- 					uci:set("wireless", "ath10","WPAPSKkey", WPAPSKkey)
	-- 				end

	-- 				local wpa2psk_pmf = luci.http.formvalue("wpa2psk_pmf")
	-- 				if not (wpa2psk_pmf) then
	-- 					uci:set("wireless", "ath10","PMF", "0")
	-- 				else
	-- 					uci:set("wireless", "ath10","PMF", wpa2psk_pmf)
	-- 				end

	-- 				if (RekeyInterval == "") then
	-- 					uci:set("wireless", "ath10","RekeyInterval", "3600")
	-- 				else
	-- 					uci:set("wireless", "ath10","RekeyInterval", RekeyInterval)
	-- 				end
	-- 				if not (WPAPSKCompatible) then
	-- 					uci:set("wireless", "ath10","WPAPSKCompatible", "0")
	-- 				else
	-- 					uci:set("wireless", "ath10","WPAPSKCompatible", WPAPSKCompatible)
	-- 				end
	-- 			end
	-- 		end

	-- 		uci:set("wps5G","wps","conf","1")
	--                 uci:commit("wps5G")

	-- 		uci:commit("wireless")
	-- 		sys.exec("echo wifi1 >/tmp/WirelessDev")
	-- 		uci:apply("wireless")

	-- 	end --end apply




	-- 	if (wps_enable == "1") then
	-- 		wps=1
	-- 	else
	-- 		wps=0
	-- 	end

	-- 	tmppsk=sys.exec("cat /tmp/tmppsk")

	-- 	local file = io.open("/var/countrycode", "r")
	-- 	local temp = file:read("*all")
	-- 	file:close()

	-- 	local show_dfs="1"
	-- 	if temp:match("[fF][fF]") then
	-- 		show_dfs="0"
	-- 	elseif temp:match("[cC][eE]") then
	--         show_dfs="0"
	-- 	elseif temp:match("[eE][eE]") then
	--         show_dfs="0"
	-- 	end

	-- 	local code = temp:match("([0-9a-fA-F]+)")
	-- 	local region = country_code_table[code:gsub("[a-fA-F]", string.upper)]

	-- 	if autoChannl then
	-- 			channel_width5G_number = 4
	-- 		if autoChannl:match("20") then
	-- 			channel_width5G_number = 2
	-- 		elseif autoChannl:match("40") then
	-- 			channel_width5G_number = 3
	-- 		end

	-- 		channels = channelRange5G[region[channel_width5G_number]]

	-- 		luci.http.write(channels)
	-- 		return
	-- 	end

	-- 	local chk_file = io.open("/tmp/wifi5G_channel_width", "r")
	-- 	local chk_channel_width
	-- 	if chk_file then
	-- 		chk_channel_width = chk_file:read("*all")
	-- 		chk_file:close()
	-- 	else
	-- 		chk_channel_width = "Null"
	-- 	end

	-- 	channel_width5G_number = 4
	-- 	if chk_channel_width:match("20") then
	-- 		channel_width5G_number = 2
	-- 	elseif chk_channel_width:match("40") then
	-- 		channel_width5G_number = 3
	-- 	end

	-- 	luci.template.render("expert_configuration/wlan5G", {wps_enabled = wps, psk = tmppsk, channels = channelRange5G[region[channel_width5G_number]], dfs_show=show_dfs})
	-- end
end

function wlan_multissid5G()
	-- NBG6817 GUI --
--	local product_name = uci:get("system","main","product_name")

--	if (product_name == "NBG6817" or product_name == "NBG6617") then
		local Apply=luci.http.formvalue("time_apply")
		if Apply then
			local iface=luci.http.formvalue("iface")
			local time=luci.http.formvalue("time")
			-- sys.exec("echo --------------------"..iface.." 5G "..time..' > /dev/console')
			sys.exec("/bin/guestWifiTimer.sh add_rule "..iface.." 5G "..time)
		end

		local show_val=sys.exec("/bin/WiFi_GUI_ctrl GuestWlan5G_get_val")

		local val_list=NEW_split(show_val,"<;;>")

		luci.template.render("expert_configuration/wlan_multissid5G", {wireless_disable = val_list[1],
							guest1 = val_list[2],
							guest2 = val_list[3],
							guest3 = val_list[4]})
	-- else
 --        security = {"","",""}
 --        local iface
	-- 	local Wireless_enable
	-- 	local cfgfile="wireless"
	-- 	local apply = luci.http.formvalue("sysSubmit")

 --        for i=1,3 do
 --                iface="ath1"..i
 --                security[i]=uci.get(cfgfile,iface,"auth")

 --                if security[i] == "WPAPSK" then
 --                        security[i]="WPA-PSK"
 --                elseif security[i] == "WPA2PSK" then
 --                        security[i]="WPA2-PSK"
 --                elseif security[i] == "WEPAUTO" or security[i] == "SHARED" then
 --                        security[i]="WEP"
 --                elseif security[i] == "OPEN" then
 --                        security[i]="No Security"
 --                end
 --        end

 --        luci.template.render("expert_configuration/wlan_multissid5G", { security1 = security[1], security2 = security[2], security3 = security[3]})
	-- end
end

function multiple_ssid5G()
	require("luci.model.uci")
	local apply = luci.http.formvalue("sysSubmit")
	local interface = luci.http.formvalue("interface")

--	local product_name = uci:get("system","main","product_name")

--	if (product_name == "NBG6817" or product_name == "NBG6617") then
		if apply then
			local Wireless_disable = luci.http.formvalue("ssid_state")
			local Wireless_disable_val = "1"
			if Wireless_disable then
				Wireless_disable_val = "0"		--enable
			end

			--SSID
			local SSID = luci.http.formvalue("SSID_value")

			--HideSSID
			local chk_hidden = luci.http.formvalue("Hide_SSID")
			wireless_hidden = "1"
			if not (chk_hidden)then
				wireless_hidden = "0"
			end

			--Intra BSS
			local chk_intra_bss = luci.http.formvalue("Intra_BSS")
			intra_bss = "1"
	        if not (chk_intra_bss) then
				intra_bss = "0"
			end

			--WMM QoS
			local chk_wmm_qos = luci.http.formvalue("WMM_QoS")
			wmm_qos = "1"
			if not (chk_wmm_qos) then
				wmm_qos = "0"
			end

			--Guest WLAN
			local chk_band_manage = luci.http.formvalue("guest_wlan_bandwidth")
			local max_band = luci.http.formvalue("max_bandwidth")
			band_manage = "1"
			if not (chk_band_manage) then
				band_manage = "0"
			end

			--SecurityMode
			local security_mode = luci.http.formvalue("security_value")
			local security_mode_val = "NULL"
			if( security_mode == "NONE") then
				security_mode_val = security_mode
			elseif( security_mode == "WEP")then
				local EncrypAuto_shared = luci.http.formvalue("auth_method")
				local wep_passphrase = luci.http.formvalue("wep_passphrase")
				local WEP64_128 = luci.http.formvalue("WEP64_128")
				local WEPKey_Code = luci.http.formvalue("WEPKey_Code")
				local DefWEPKey = luci.http.formvalue("DefWEPKey")
				local wepkey1 = luci.http.formvalue("wep_key_1")
				local wepkey2 = luci.http.formvalue("wep_key_2")
				local wepkey3 = luci.http.formvalue("wep_key_3")
				local wepkey4 = luci.http.formvalue("wep_key_4")

				local EncrypAuto_shared_val = "EncrypAuto_shared"
				if EncrypAuto_shared then
					EncrypAuto_shared_val = EncrypAuto_shared
				end

				local wep_passphrase_val = "wep_passphrase"
				if wep_passphrase then
					wep_passphrase_val = wep_passphrase
				end

				local WEP64_128_val = "WEP64_128"
				if WEP64_128 == "0" or WEP64_128 == "1" then
					WEP64_128_val = WEP64_128
				end

				local WEPKey_Code_val = "WEPKey_Code"
				if WEPKey_Code == "0" or WEPKey_Code == "1" then
					WEPKey_Code_val = WEPKey_Code
				end

				local DefWEPKey_val = "DefWEPKey"
				if DefWEPKey then
					DefWEPKey_val = DefWEPKey
				end

				local wepkey1_val = "wepkey1"
				if wepkey1 then
					wepkey1_val = wepkey1
				end

				local wepkey2_val = "wepkey2"
				if wepkey2 then
					wepkey2_val = wepkey2
				end

				local wepkey3_val = "wepkey3"
				if wepkey3 then
					wepkey3_val = wepkey3
				end

				local wepkey4_val = "wepkey4"
				if wepkey4 then
					wepkey4_val = wepkey4
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s", security_mode, EncrypAuto_shared_val, wep_passphrase_val, WEP64_128_val, WEPKey_Code_val, DefWEPKey_val, wepkey1_val, wepkey2_val, wepkey3_val, wepkey4_val)
			elseif(security_mode == "WPA")then
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
				local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
				local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
				local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")

				local RekeyInterval_val = "3600"
				if RekeyInterval then
					RekeyInterval_val = RekeyInterval
				end

				local RadiusServerIP_val = "192.168.2.3"
				if RadiusServerIP then
					RadiusServerIP_val = RadiusServerIP
				end

				local RadiusServerPort_val = "1812"
				if RadiusServerPort then
					RadiusServerPort_val = RadiusServerPort
				end

				local RadiusServerSecret_val = "ralink"
				if RadiusServerSecret then
					RadiusServerSecret_val = RadiusServerSecret
				end

				local RadiusServerSessionTimeout_val = "0"
				if (RadiusServerSessionTimeout == "") then
					RadiusServerSessionTimeout_val = RadiusServerSessionTimeout
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s", security_mode, RekeyInterval_val, RadiusServerIP_val, RadiusServerPort_val, RadiusServerSecret_val, RadiusServerSessionTimeout_val)
			elseif(security_mode == "WPAPSK")then
				local WPAPSKkey = luci.http.formvalue("PSKey")
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")

				local WPAPSKkey_val = "WPAPSKkey"
				if WPAPSKkey then
					WPAPSKkey_val = WPAPSKkey
				end

				local RekeyInterval_val = "3600"
				if RekeyInterval then
					RekeyInterval_val = RekeyInterval
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s", security_mode, WPAPSKkey_val, RekeyInterval_val)
			elseif(security_mode == "WPA2")then
				local WPACompatible = luci.http.formvalue("wpa_compatible")
				local wpa2_pmf = luci.http.formvalue("wpa2_pmf")
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				local PMKCachePeriod = luci.http.formvalue("PMKCachePeriod")
				local PreAuthentication = luci.http.formvalue("PreAuthentication")
				local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
				local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
				local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
				local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")

				local WPACompatible_val = "0"
				if WPACompatible then
					WPACompatible_val = WPACompatible
				end

				local wpa2_pmf_val = "0"
				if wpa2_pmf then
					wpa2_pmf_val = wpa2_pmf
				end

				local RekeyInterval_val = "3600"
				if RekeyInterval then
					RekeyInterval_val = RekeyInterval
				end

				local PMKCachePeriod_val = "10"
				if (PMKCachePeriod == "") then
					PMKCachePeriod_val = PMKCachePeriod
				end

				local PreAuthentication_val = "0"
				if PreAuthentication then
					PreAuthentication_val = PreAuthentication
				end

				local RadiusServerIP_val = "192.168.2.3"
				if RadiusServerIP then
					RadiusServerIP_val = RadiusServerIP
				end

				local RadiusServerPort_val = "1812"
				if (RadiusServerPort == "") then
					RadiusServerPort_val = RadiusServerPort
				end

				local RadiusServerSecret_val = "ralink"
				if RadiusServerSecret then
					RadiusServerSecret_val = RadiusServerSecret
				end

				local RadiusServerSessionTimeout_val = "0"
				if RadiusServerSessionTimeout then
					RadiusServerSessionTimeout_val = RadiusServerSessionTimeout
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s<;;>%s", security_mode, WPACompatible_val, wpa2_pmf_val, RekeyInterval_val, PMKCachePeriod_val, PreAuthentication_val, RadiusServerIP_val, RadiusServerPort_val, RadiusServerSecret_val, RadiusServerSessionTimeout_val)
			elseif(security_mode=="WPA2PSK")then
				local WPAPSKkey = luci.http.formvalue("PSKey")
				local WPAPSKCompatible = luci.http.formvalue("wpapsk_compatible")
				local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
				local wpa2psk_pmf = luci.http.formvalue("wpa2psk_pmf")

				local WPAPSKkey_val = "WPAPSKkey"
				if WPAPSKkey then
					WPAPSKkey_val = WPAPSKkey
				end

				local wpa2psk_pmf_val = "0"
				if wpa2psk_pmf then
					wpa2psk_pmf_val = wpa2psk_pmf
				end

				local RekeyInterval_val = "3600"
				if RekeyInterval then
					RekeyInterval_val = RekeyInterval
				end

				local WPAPSKCompatible_val = "0"
				if WPAPSKCompatible then
					WPAPSKCompatible_val = WPAPSKCompatible
				end

				security_mode_val = string.format("%s<;;>%s<;;>%s<;;>%s<;;>%s", security_mode, WPAPSKkey_val, WPAPSKCompatible_val, RekeyInterval_val, wpa2psk_pmf_val)
			end

			sys.exec("/bin/WiFi_GUI_ctrl GuestWlan5G_edit '"..interface.."' "..Wireless_disable_val.." '"..SSID.."' "..wireless_hidden.." "..intra_bss.." "..wmm_qos.." "..band_manage.." '"..max_band.."' '"..security_mode_val.."'")

			local show_val=sys.exec("/bin/WiFi_GUI_ctrl GuestWlan5G_get_val")
			local val_list=NEW_split(show_val,"<;;>")

			luci.template.render("expert_configuration/wlan_multissid5G", {wireless_disable = val_list[1],
							guest1 = val_list[2],
							guest2 = val_list[3],
							guest3 = val_list[4]})
			return
		end

		local show_val=sys.exec("/bin/WiFi_GUI_ctrl GuestWlan5G_edit_get_val '"..interface.."'")
		local val_list=NEW_split(show_val,"<;;>")

		luci.template.render("expert_configuration/multissid_edit5G",{ifacename=val_list[1],
							wireless_enable = val_list[2],
							ssid = val_list[3],
							hide_ssid = val_list[4],
							IntraBSS = val_list[5],
							wmm = val_list[6],
							wmm_choice = val_list[7],
							enabel_bandwidth = val_list[8],
							guest_max_bandwidth = val_list[9],
							auth = val_list[10],
							security = val_list[11],
							wps_enabled = val_list[12],
							WPAPSKCompatible = val_list[13],
							chk_PMF = val_list[14],
							psk = val_list[15],
							keyRenewalInterval = val_list[16],
							RadiusServerIP = val_list[17],
							RadiusServerPort = val_list[18],
							RadiusServerSecret = val_list[19],
							RadiusServerSessionTimeout = val_list[20],
							WPACompatible = val_list[21],
							})

	-- else
	-- 	security = {"","",""}
	-- 	local iface
	-- 	local cfgfile="wireless"
	-- 	local wireless_mode = uci:get("wireless", "wifi1", "hwmode")
	-- 	local WMM_Choose

	--         if ( wireless_mode == "11an" or wireless_mode == "11ac" ) then
	--             uci:set("wireless", "ath11", "wmm",1)
	-- 			uci:set("wireless", "ath12", "wmm",1)
	-- 			uci:set("wireless", "ath13", "wmm",1)
	--             uci:commit("wireless")
	--             WMM_Choose="disabled"
	--         end

	-- 	if interface == "1" then
	-- 		iface="ath11"
	-- 	elseif interface == "2" then
	-- 		iface="ath12"
	-- 	elseif interface == "3" then
	-- 		iface="ath13"
	-- 	else
	-- 		iface=interface
	-- 	end

	-- 	if apply then
	-- 		sys.exec("echo "..iface.." > /tmp/wifi5G_Apply")
	-- 		--SSID
	-- 		local SSID = luci.http.formvalue("SSID_value")

	-- --		SSID = checkInjection(SSID)
	-- 		if SSID ~= false then
	-- 			uci:set(cfgfile, iface, "ssid", SSID)
	-- 		end

	-- 		--Active
	-- 		local Wireless_enable = luci.http.formvalue("ssid_state")
	-- 		if Wireless_enable then
	-- 			uci:set(cfgfile, iface, "disabled", 0)
	-- 		else
	-- 			uci:set(cfgfile, iface, "disabled", 1)
	-- 		end
	-- 		--HideSSID
	-- 		local wireless_hidden = luci.http.formvalue("Hide_SSID")
	-- 		if not (wireless_hidden)then
	-- 			uci:set(cfgfile, iface, "hidden", 0)
	-- 		else
	-- 			uci:set(cfgfile, iface, "hidden", 1)
	-- 		end
	-- 		--Intra BSS
	--         local intra_bss = luci.http.formvalue("Intra_BSS")
	-- 		if not (intra_bss) then
	-- 			uci:set(cfgfile, iface, "IntraBSS", 0)
	-- 		else
	-- 			uci:set(cfgfile, iface, "IntraBSS", 1)
	-- 		end
	-- 		--WMM QoS
	-- 		local wmm_qos = luci.http.formvalue("WMM_QoS")

	-- 		if ( wireless_mode == "11an" ) then
	-- 			uci:set(cfgfile, iface, "wmm", 1)
	-- 		else
	-- 			if not (wmm_qos) then
	-- 				uci:set(cfgfile, iface, "wmm", 0)
	-- 			else
	-- 				uci:set(cfgfile, iface, "wmm", 1)
	-- 			end
	-- 		end

	-- 		--5G Guest WLAN
	-- 		local band_manage = luci.http.formvalue("guest_wlan_bandwidth")
	-- 		local max_band = luci.http.formvalue("max_bandwidth")
	-- 		if band_manage then
	-- 			uci:set(cfgfile, iface, "guest_bandwidth_enable", 1)
	-- 		else
	-- 			uci:set(cfgfile, iface, "guest_bandwidth_enable", 0)
	-- 		end
	-- 		uci:set(cfgfile, iface, "guest_max_bandwidth", max_band)

	-- 		--SecurityMode
	-- 		local security_mode = luci.http.formvalue("security_value")
	-- 		if (security_mode) then
	-- 			--No security
	-- 			if( security_mode == "NONE") then
	-- 				uci:set(cfgfile, iface, "auth", "OPEN")
	-- 				uci:set(cfgfile, iface, "encryption", "NONE")
	-- 			end

	-- 			--WEP
	-- 			if( security_mode == "WEP")then
	-- 				local EncrypAuto_shared = luci.http.formvalue("auth_method")
	-- 				uci:set(cfgfile, iface,"encryption","WEP")
	-- 				if (EncrypAuto_shared)	then
	-- 					if(EncrypAuto_shared == "WEPAUTO")then
	-- 						uci:set(cfgfile, iface,"encryption","wep-mixed")
	-- 						uci:set(cfgfile, iface,"auth",EncrypAuto_shared)
	-- 					elseif(EncrypAuto_shared == "SHARED") then
	-- 						uci:set(cfgfile, iface,"encryption","wep-shared")
	-- 						uci:set(cfgfile, iface,"auth",EncrypAuto_shared)
	-- 					end
	-- 				end

	-- 				local wep_passphrase = luci.http.formvalue("wep_passphrase")
	-- 				if not (wep_passphrase) then
	-- 					uci:set(cfgfile, iface, "PassPhrase","")
	-- 				else
	-- 					uci:set(cfgfile, iface, "PassPhrase",wep_passphrase)
	-- 				end

	-- 				--64-128bit
	-- 				local WEP64_128 = luci.http.formvalue("WEP64_128")
	-- 				if (WEP64_128)then
	-- 					if(WEP64_128 == "0")then--[[64-bit]]--
	-- 						uci:set(cfgfile, iface, "wepencryp128", WEP64_128)
	-- 					else
	-- 						uci:set(cfgfile, iface, "wepencryp128", WEP64_128)
	-- 					end
	-- 				end

	-- 				--ASCIIHEX
	-- 				local WEPKey_Code = luci.http.formvalue("WEPKey_Code")
	-- 				if (WEPKey_Code == "1")then--[[HEx]]--
	-- 					uci:set(cfgfile, iface, "keytype", "1")
	-- 				elseif (WEPKey_Code == "0") then--[[ASCII]]--
	-- 						uci:set(cfgfile, iface, "keytype", "0")
	-- 				end
	-- 				--keyindex
	-- 				local DefWEPKey = luci.http.formvalue("DefWEPKey")
	-- 				if (DefWEPKey)then
	-- 					uci:set(cfgfile, iface, "key", DefWEPKey)
	-- 				end

	-- 				--WEP key value
	-- 				local wepkey
	-- 				local key_name
	-- 				for i=1,4 do
	-- 					wepkey = luci.http.formvalue("wep_key_"..i)
	-- 					key_name="key"..i
	-- 					if ( wepkey ) then
	-- 						uci:set(cfgfile, iface, key_name, wepkey)
	-- 					else
	-- 						uci:set(cfgfile, iface, key_name, "")
	-- 					end
	-- 				end
	-- 			end --End WEP

	-- 			--WPA
	--                         if (security_mode == "WPA")then
	--                         	uci:set(cfgfile, iface, "auth","WPA")
	--                                 uci:set(cfgfile, iface, "encryption","WPA")

	--                                 local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
	--                                 if (RekeyInterval == "") then
	--                                         uci:set(cfgfile, iface, "RekeyInterval", "3600")
	--                                 else
	--                                         uci:set(cfgfile, iface, "RekeyInterval", RekeyInterval)
	--                                 end

	--                                 local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
	--                                 if (RadiusServerIP == "") then
	--                                 	uci:set(cfgfile, iface, "RADIUS_Server", "192.168.2.3")
	--                                 else
	--                                         uci:set(cfgfile, iface, "RADIUS_Server", RadiusServerIP)
	--                                 end

	--                                 local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
	--                                 if (RadiusServerPort == "") then
	--                                 	uci:set(cfgfile, iface, "RADIUS_Port", "1812")
	--                                 else
	--                                         uci:set(cfgfile, iface, "RADIUS_Port", RadiusServerPort)
	--                                 end

	--                                 local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
	--                                 if (RadiusServerSecret == "") then
	--                                 	uci:set(cfgfile, iface, "RADIUS_Key", "ralink")
	--                                 else
	--                                         uci:set(cfgfile, iface, "RADIUS_Key", RadiusServerSecret)
	--                                 end

	--                                 local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")
	--                                 if (RadiusServerSessionTimeout == "" or RadiusServerSessionTimeout == nil) then
	--                                         uci:set(cfgfile, iface, "session_timeout_interval", "0")
	--                                 else
	--                                         uci:set(cfgfile, iface, "session_timeout_interval", RadiusServerSessionTimeout)
	--                                 end
	--                 	end --End WPA

	--                         --WPAPSK
	--                         if(security_mode == "WPAPSK")then
	--                         	uci:set(cfgfile, iface, "auth", "WPAPSK")
	--                                 uci:set(cfgfile, iface, "encryption", "WPAPSK")
	--                                 local WPAPSKkey = luci.http.formvalue("PSKey")
	--                                 local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
	--                                 if (WPAPSKkey == "") then
	--                                 	uci:set(cfgfile, iface, "WPAPSKkey", "")
	--                                 else
	--                                 	uci:set(cfgfile, iface, "WPAPSKkey", WPAPSKkey)
	--                                 end
	--                                 if not(RekeyInterval) then
	--                                 	uci:set(cfgfile, iface, "RekeyInterval", "3600")
	--                                 else
	--                                         uci:set(cfgfile, iface, "RekeyInterval", RekeyInterval)
	--                                 end
	--                 	end --End WPAPSK

	--                 --WPA2
	--                 if (security_mode == "WPA2")then
	--                         uci:set(cfgfile, iface, "auth", "WPA2")
	--                         uci:set(cfgfile, iface, "encryption", "WPA2")
	--                         local WPACompatible = luci.http.formvalue("wpa_compatible")
	--                         if not (WPACompatible) then
	--                         	uci:set(cfgfile, iface, "WPACompatible", "0")
	--                         else
	--                             uci:set(cfgfile, iface, "WPACompatible", WPACompatible)
	--                         end

	--                         local wpa2_pmf = luci.http.formvalue("wpa2_pmf")
	--                         if not (wpa2_pmf) then
	--                         	uci:set(cfgfile, iface, "PMF", "0")
	--                         else
	--                             uci:set(cfgfile, iface, "PMF", wpa2_pmf)
	--                         end

	-- 						local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
	--                         if (RekeyInterval == "") then
	--                                 uci:set(cfgfile, iface, "RekeyInterval", "3600")
	--                         else
	--                                 uci:set(cfgfile, iface, "RekeyInterval", RekeyInterval)
	--                         end

	--                         local PMKCachePeriod = luci.http.formvalue("PMKCachePeriod")
	--                         if (PMKCachePeriod == "") then
	--                                 uci:set(cfgfile, iface, "PMKCachePeriod", "10")
	--                         else
	--                                 uci:set(cfgfile, iface, "PMKCachePeriod", PMKCachePeriod)
	--                         end
	--                         local PreAuthentication = luci.http.formvalue("PreAuthentication")
	--                         if (PreAuthentication == "") then
	--                                 uci:set(cfgfile, iface, "PreAuth", "0")
	--                         else
	--                                 uci:set(cfgfile, iface, "PreAuth", PreAuthentication)
	--                         end
	--                         local RadiusServerIP = luci.http.formvalue("RadiusServerIP")
	--                         if (RadiusServerIP == "") then
	--                                 uci:set(cfgfile, iface, "RADIUS_Server", "192.168.2.3")
	--                         else
	--                                 uci:set(cfgfile, iface, "RADIUS_Server", RadiusServerIP)
	--                         end

	--                         local RadiusServerPort = luci.http.formvalue("RadiusServerPort")
	--                         if (RadiusServerPort == "") then
	--                                 uci:set(cfgfile, iface, "RADIUS_Port", "1812")
	--                         else
	--                                 uci:set(cfgfile, iface, "RADIUS_Port", RadiusServerPort)
	--                         end
	--                         local RadiusServerSecret = luci.http.formvalue("RadiusServerSecret")
	--                         if (RadiusServerSecret == "") then
	--                                 uci:set(cfgfile, iface, "RADIUS_Key", "ralink")
	--                         else
	--                                 uci:set(cfgfile, iface, "RADIUS_Key", RadiusServerSecret)
	--                         end

	--                         local RadiusServerSessionTimeout = luci.http.formvalue("RadiusServerSessionTimeout")
	--                         if (RadiusServerSessionTimeout == "" or RadiusServerSessionTimeout == nil) then
	--                                 uci:set(cfgfile, iface, "session_timeout_interval", "0")
	--                         else
	--                                 uci:set(cfgfile, iface, "session_timeout_interval", RadiusServerSessionTimeout)
	--                         end
	--         	end --End WPA2

	--                     --WPA2PSK
	--                     if(security_mode=="WPA2PSK")then
	--                     	uci:set(cfgfile, iface, "auth", "WPA2PSK")
	--                     	uci:set(cfgfile, iface, "encryption", "WPA2PSK")
	--                             local WPAPSKkey = luci.http.formvalue("PSKey")
	--                             local WPAPSKCompatible = luci.http.formvalue("wpapsk_compatible")
	--                             local RekeyInterval = luci.http.formvalue("keyRenewalInterval")
	--                             if (WPAPSKkey == "") then
	--                             	uci:set(cfgfile, iface, "WPAPSKkey", "")
	--                             else
	--                                     uci:set(cfgfile, iface, "WPAPSKkey", WPAPSKkey)
	--                             end

	--                             local wpa2psk_pmf = luci.http.formvalue("wpa2psk_pmf")
	-- 	                        if not (wpa2psk_pmf) then
	-- 	                        	uci:set(cfgfile, iface, "PMF", "0")
	-- 	                        else
	-- 	                            uci:set(cfgfile, iface, "PMF", wpa2psk_pmf)
	-- 	                        end

	--                             if (RekeyInterval == "") then
	--                                     uci:set(cfgfile, iface, "RekeyInterval", "3600")
	--                             else
	--                                     uci:set(cfgfile, iface, "RekeyInterval", RekeyInterval)
	--                             end
	--                             if not (WPAPSKCompatible) then
	--                                     uci:set(cfgfile, iface, "WPAPSKCompatible", "0")
	--                             else
	--                                     uci:set(cfgfile, iface, "WPAPSKCompatible", WPAPSKCompatible)
	--                             end
	--             	end --End WPA2PSK
	-- 		end

	-- 		sys.exec("echo "..iface.." >> /tmp/moreAP5G")
	-- 		sys.exec("echo wifi1 >/tmp/WirelessDev")
	-- 		uci:commit(cfgfile)
	-- 		uci:apply(cfgfile)

	-- 		for i=1,3 do
	--                 	iface="ath1"..i
	--                 	security[i]=uci.get(cfgfile,iface,"auth")

	--                 	if security[i] == "WPAPSK" then
	--                 	        security[i]="WPA-PSK"
	--                 	elseif security[i] == "WPA2PSK" then
	--                 	        security[i]="WPA2-PSK"
	--                 	elseif security[i] == "WEPAUTO" or security[i] == "SHARED" then
	--                 	        security[i]="WEP"
	--                 	elseif security[i] == "OPEN" then
	--                 	        security[i]="No Security"
	--                 	end
	-- 		end

	-- 		luci.template.render("expert_configuration/wlan_multissid5G", { security1 = security[1], security2 = security[2], security3 = security[3]})
	-- 		return
	-- 	end --End Apply

	-- 	tmppsk=sys.exec("cat /tmp/tmppsk")

	-- 	luci.template.render("expert_configuration/multissid_edit5G",{ifacename=iface, psk = tmppsk, wmm_choice=WMM_Choose})
	-- end
end

function wlanmacfilter_5G()
		local sqlite3 = require("lsqlite3")
		local db = sqlite3.open( "/tmp/netprobe.db" )
		local apply = luci.http.formvalue("sysSubmit")
		local changed = 0
		local filter
		local data = ""
		local DevMac = ""
		local DevName = ""

	-- NBG6817 GUI --
--	local product_name = uci:get("system","main","product_name")

--	if (product_name == "NBG6817" or product_name == "NBG6617") then
		local clients_MAC = ""
		db:busy_timeout(5000)

		for row in db:nrows("SELECT * FROM Device where [Alive]=1 OR ([Alive]=0 AND [nNotAlive] <= 2); ") do
			if row.DevMac ~= "" and row.DevMac then
				DevMac = row.DevMac
			else
				DevMac = row.ALMac
			end

			if row.IP then
				if row.DevName == nil then
					if row.Manufacture == nil then
						DevName = "Unknown"
					else
						DevName = row.Manufacture
					end
				else
					DevName = row.DevName
				end
			end

			clients_MAC = row.ConnType..";"..clients_MAC
			data = DevName.."("..DevMac..")"..";"..data
		end

		if apply then
			--filter on/of
			local MACfilter_ON = luci.http.formvalue("MACfilter_ON")
			--filter action
			local filter_act = luci.http.formvalue("filter_act")

--			local count = luci.http.formvalue("count")
			local MacAddrs_val = luci.http.formvalue("MacAddrs")

			if MacAddrs_val == "" then
				MacAddrs_val = "None"
			end

			sys.exec("/bin/WiFi_GUI_ctrl macfilter5G "..MACfilter_ON.." "..filter_act.." '"..MacAddrs_val.."'")
		end

		local show_val=sys.exec("/bin/WiFi_GUI_ctrl macfilter5G_get_val")
		local val_list=NEW_split(show_val,"<;;>")

		luci.template.render("expert_configuration/wlanmacfilter5G",{
								data=data,
								clients_MAC=clients_MAC,
								Macaddress=val_list[1],
								ssid=val_list[2],
								MacFilter_enable=val_list[3],
								MacFilter_Action=val_list[4],
								})

	-- else
	-- 	local connect_type = ""
	-- 	local select_ap = luci.http.formvalue("ap_select")

	-- 	for row in db:nrows("SELECT * FROM Device") do

	-- 		if row.DevMac ~= "" and row.DevMac then
	-- 			DevMac = row.DevMac
	-- 		else
	-- 			DevMac = row.ALMac
	-- 		end

	-- 		if row.IP then
	-- 			if row.DevName == nil then
	-- 				if row.Manufacture == nil then
	-- 					DevName = "Unknown"
	-- 				else
	-- 					DevName = row.Manufacture
	-- 				end
	-- 			else
	-- 				DevName = row.DevName
	-- 			end
	-- 		end
	-- 		connect_type = row.ConnType..";"..connect_type
	-- 		data = DevName.."("..DevMac..")"..";"..data
	--     end

	-- 	if not select_ap then
	-- 		select_ap="0"
	-- 	end

	-- 	filter="general"..select_ap

	-- 	if apply then
	-- 		--filter on/of
	-- 		local MACfilter_ON = luci.http.formvalue("MACfilter_ON")
	-- 		local count = luci.http.formvalue("count")
	-- 		MACfilter_ON_old = uci:get("wireless5G_macfilter", filter, "mac_state")
	-- 		if not (MACfilter_ON == MACfilter_ON_old) then
	-- 			changed = 1
	-- 			uci:set("wireless5G_macfilter", filter, "mac_state", MACfilter_ON)
	-- 		end
	-- 		--filter action
	-- 		local filter_act = luci.http.formvalue("filter_act")
	-- 		filter_act_old = uci:get("wireless5G_macfilter", filter, "filter_action")
	-- 		if not (filter_act == filter_act_old) then
	-- 			changed = 1
	-- 			uci:set("wireless5G_macfilter", filter, "filter_action", filter_act)
	-- 		end

	-- 		--mac address
	-- 		local MacAddr
	-- 		local Mac_field
	-- 		local MacAddr_old

	-- 		for i=1,32 do
	-- 			Mac_field="MacAddr"..i
	-- 			MacAddr="00:00:00:00:00:00"
	-- 			uci:set("wireless5G_macfilter", filter, Mac_field, MacAddr)
	-- 			uci:commit("wireless5G_macfilter")
	-- 		end

	-- 		for i=1,count do
	-- 			Mac_field="MacAddr"..i
	-- --			MacAddr_old = uci:get("wireless5G_macfilter", filter, Mac_field)
	-- 			MacAddr = luci.http.formvalue(Mac_field)
	-- --			if not ( MacAddr == MacAddr_old ) then

	-- 				changed = 1
	-- 				uci:set("wireless5G_macfilter", filter, Mac_field, MacAddr)
	-- --			end
	-- 		end

	-- 		--new value need to be saved
	-- --		if (changed == 1) then
	-- 			local iface_reset="ath1"..select_ap
	-- 			local iface
	-- 			local iface_filter
	-- 			for i=0,3 do
	-- 				iface="ath1"..i
	-- 				iface_filter="general"..i
	-- 				if (iface == iface_reset) then
	-- 					uci:set("wireless5G_macfilter", iface_filter, "reset", "1")
	-- 				else
	-- 					uci:set("wireless5G_macfilter", iface_filter, "reset", "0")
	-- 				end
	-- 			end
	-- 			sys.exec("echo wifi0 > /tmp/wifi5G_macfilter_Apply")
	-- 			uci:commit("wireless5G_macfilter")
	-- 			uci:apply("wireless5G_macfilter")
	-- --		end
	-- 		if (MACfilter_ON == "1") then
	-- 			uci:set("wps5G","wps","enabled","0")
	-- 			uci:commit("wps5G")
	-- 			sys.exec("echo wifi0 > /tmp/wifi5G_macfilter_Apply")
	-- 			sys.exec("echo wifi1 >/tmp/WirelessDev")
	-- 			uci:apply("wireless")
	-- 		end
	-- 	end
	-- 	luci.template.render("expert_configuration/wlanmacfilter5G",{filter_iface=filter, ap=select_ap,data=data,connect_type=connect_type})
	-- end
end

function wlan_advanced_5G()
	local apply = luci.http.formvalue("sysSubmit")

--	local product_name = uci:get("system","main","product_name")

--	if (product_name == "NBG6817" or product_name == "NBG6617") then
		if apply then
			--rts_Threshold
			local rts_Threshold = luci.http.formvalue("rts_Threshold")
			local rts_Threshold_val = "2345"
			if rts_Threshold then
				rts_Threshold_val = rts_Threshold
			end

			--fr_threshold
			local fr_threshold = luci.http.formvalue("fr_threshold")
			local fr_threshold_val = "2345"
			if fr_threshold then
				fr_threshold_val = fr_threshold
			end

			--Intra-BSS Traffic
			local IntraBSS_state = luci.http.formvalue("IntraBSS_state")
			local IntraBSS_state_val = "0"
			if IntraBSS_state then
				IntraBSS_state_val = IntraBSS_state
			end

			--tx power
			local txPower = luci.http.formvalue("TxPower_value")
			local txPower_val = "100"
			if txPower then
				txPower_val = txPower
			end

			--wmm QoS
			local wmm_enable = luci.http.formvalue("WMM_QoS")
			local wmm_enable_val = "WMM"
			if (wmm_enable == "1" or wmm_enable == "0") then
				wmm_enable_val = wmm_enable
			end

			sys.exec("/bin/WiFi_GUI_ctrl advanced5G "..rts_Threshold_val.." "..fr_threshold_val.." "..IntraBSS_state_val.." "..txPower_val.." "..wmm_enable_val)
		end

		local show_val=sys.exec("/bin/WiFi_GUI_ctrl advanced5G_get_val")
		local val_list=NEW_split(show_val,"<;;>")

		luci.template.render("expert_configuration/wlanadvanced5G",{
										rts_frag_WMM_choice = val_list[1],
										rts_Threshold = val_list[2],
										fr_threshold = val_list[3],
										WMM_QoS = val_list[4],
										IntraBSS = val_list[5],
										TxPower = val_list[6],
										})
	-- else
	-- 	local changed = 0
	-- 	local wireless_mode = uci:get("wireless", "wifi1", "hwmode")
	-- 	local RTS_Set
	-- 	local Frag_Set
	-- 	local WMM_Choose

	-- 	if ( wireless_mode == "11an" or  wireless_mode == "11ac" ) then
	-- 		uci:set("wireless", "ath10", "rts",2346)
	-- 		uci:set("wireless", "ath10", "frag",2346)
	-- 		uci:set("wireless", "ath10", "wmm",1)

	-- 		uci:commit("wireless")
	-- 		RTS_Set="disabled"
	-- 		Frag_Set="disabled"
	-- 		WMM_Choose="disabled"
	-- 	end

	-- 	if apply then
	-- --rts_Threshold
	-- 		local rts_Threshold = luci.http.formvalue("rts_Threshold")
	-- 		local rts_Threshold_old = uci:get("wireless", "ath10","rts")
	-- 		if not (rts_Threshold) then
	-- 			changed = 1
	-- 			uci:set("wireless", "ath10","rts", "2354")
	-- 		else
	-- 			if not (rts_Threshold == rts_Threshold_old) then
	-- 			changed = 1
	-- 			uci:set("wireless", "ath10","rts", rts_Threshold)
	-- 			end
	-- 		end
	-- --fr_threshold
	-- 		local fr_threshold = luci.http.formvalue("fr_threshold")
	-- 		local fr_threshold_old = uci:get("wireless", "ath10","frag")
	-- 		if not (fr_threshold) then
	-- 			changed = 1
	-- 			uci:set("wireless", "ath10","frag", "2354")
	-- 		else
	-- 			if not (fr_threshold == fr_threshold_old) then
	-- 			changed = 1
	-- 			uci:set("wireless", "ath10","frag", fr_threshold)
	-- 			end
	-- 		end
	-- --Intra-BSS Traffic
	-- 		local IntraBSS_state = luci.http.formvalue("IntraBSS_state")
	-- 		local IntraBSS_state_old = uci:get("wireless", "ath10","IntraBSS")
	-- 		if not (IntraBSS_state) then
	-- 			changed = 1
	-- 			uci:set("wireless", "ath10","IntraBSS", "0")
	-- 		else
	-- 			if not (IntraBSS_state == IntraBSS_state_old) then
	-- 			changed = 1
	-- 			uci:set("wireless", "ath10","IntraBSS", IntraBSS_state)
	-- 			end
	-- 		end
	-- --tx power
	-- 		local txPower = luci.http.formvalue("TxPower_value")
	-- 		local txPower_old = uci:get("wireless", "wifi1", "txpower")
	-- 		if not (txPower) then
	-- 			changed = 1
	-- 			uci:set("wireless", "wifi1", "txpower","100")
	-- 		else
	-- 			if not (txPower == txPower_old) then
	-- 			changed = 1
	-- 			uci:set("wireless", "wifi1", "txpower",txPower)
	-- 			end
	-- 		end

	-- --wmm QoS
	-- 		local wmm_enable = luci.http.formvalue("WMM_QoS")
	-- 		if (wmm_enable == "1") then
	-- 			uci:set("wireless", "ath10","wmm", wmm_enable)
	-- 			changed = 1
	-- 		elseif (wmm_enable == "0") then
	-- 			uci:set("wireless", "ath10","wmm", wmm_enable)
	-- 			changed = 1
	-- 		end

	-- 		if (changed == 1) then
	-- 			uci:commit("wireless")
	-- 			sys.exec("echo wifi1 >/tmp/WirelessDev")
	-- 			uci:apply("wireless")
	-- 		end
	-- 	end

	-- 	luci.template.render("expert_configuration/wlanadvanced5G",{rts_set=RTS_Set, frag_set=Frag_Set, wmm_choice=WMM_Choose})
	-- end
end

function wlan_qos_5G()
	local apply = luci.http.formvalue("sysSubmit")
	local wireless_mode = uci:get("wireless", "wifi1", "hwmode")
	local WMM_Choose

	if ( wireless_mode == "11an" or wireless_mode == "11ac"  ) then
		uci:set("wireless", "ath10", "wmm",1)
		uci:commit("wireless")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		WMM_Choose="disabled"
	end

	if apply then
		local wmm_enable = luci.http.formvalue("WMM_QoS")
		if (wmm_enable == "1") then
			uci:set("wireless", "ath10","wmm", wmm_enable)
		elseif (wmm_enable == "0") then
			uci:set("wireless", "ath10","wmm", wmm_enable)
		end
		uci:commit("wireless")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		sys.exec("echo wifi1 >/tmp/WirelessDev")
		uci:apply("wireless")
	end

	luci.template.render("expert_configuration/wlanqos5G", {wmm_choice=WMM_Choose})
end

-- function wlan_wps_5G()
-- 	require("luci.model.uci")
-- 	local releaseConf = luci.http.formvalue("Release")
-- 	local genPin = luci.http.formvalue("Generate")
-- 	local pincode = uci:get("wps5G","wps","appin")
-- 	local apply = luci.http.formvalue("sysSubmit")
-- 	local wps_enable = uci:get("wps5G","wps","enabled")
-- 	local wps_choice = luci.http.formvalue("wps_function")
-- 	local wps_set
-- 	local pincode_enable = uci:get("wps5G","wps","PinEnable")
-- 	local pincode_choice = luci.http.formvalue("pincode_function")
-- 	local pincode_set
-- 	local wps_change
-- 	local wps_chk -- +
-- 	local configured
-- 	--	local configured -- -
-- 	local apssid
-- 	local radiomode
-- 	local securemode
-- 	local config_status
-- 	local configfile
-- 	local wps_enable_choose
-- 	local security_mode
-- 	local authmode
-- 	local WPAPSKCompatible_5G = uci.get("wireless", "ath10", "WPAPSKCompatible")
--     local WPACompatible_5G = uci.get("wireless", "ath10", "WPACompatible")
-- 	local hstapd_cli = "hostapd_cli -p /tmp/run/hostapd-wifi1/ -i ath10 " -- +

-- 	local wireless5g_disabled = uci:get("wireless", "wifi1","disabled")

-- 	if ( wireless5g_disabled=="1" or wireless5g_disabled==nil ) then
-- 		wireless5g_disabled=true
-- 	else
-- 		wireless5g_disabled=false
-- 	end

-- 	security_mode=uci:get("wireless","ath10","auth")

-- 	if( security_mode=="WEPAUTO" or security_mode=="SHARED" or security_mode=="WPA" or security_mode=="WPA2" ) then
-- 		wps_enable_choose="disabled"
-- 	end

-- 	if releaseConf then
-- 		uci:set("wps5G","wps","conf",0)
-- 		uci:commit("wps5G")
-- 		sys.exec("qcsapi_sockrpc --host 223.254.253.252 set_wps_configured_state wifi0 1")
-- 		sys.exec("echo wifi1 >/tmp/WirelessDev")
-- 		uci:apply("wireless")

-- 		sys.exec("wps5G ath10 on")
-- 	end

-- 	sys.exec("qcsapi_sockrpc --host 223.254.253.252 get_wps_configured_state wifi0 > /tmp/wps5G_config")
-- 	configfile = io.open("/tmp/wps5G_config", "r")
-- 	configured = configfile:read("*line")
-- 	configfile:close()

-- 	if ( configured == "configured" ) then

-- 		uci:set("wps5G","wps","conf",1)
-- 		uci:commit("wps5G")

-- 		apssid = uci:get("wireless","ath10","ssid")
-- 		radiomode = uci:get("wireless","wifi1","hwmode")
-- 		radiomode = "802."..radiomode
-- 		authmode = uci:get("wireless","ath10","encryption")

-- 		if not apssid then
-- 			apssid=luci.sys.exec("cat /tmp/tmpSSID5G")
-- 		end

-- 		if authmode == "WPAPSK" then
-- 			securemode="WPA-PSK"
-- 		elseif authmode == "WPA2PSK" then
-- 		-- add by darren 2012.03.07
-- 			if WPAPSKCompatible_5G == "0" then
-- 				securemode="WPA2-PSK"
-- 			elseif WPAPSKCompatible_5G == "1" then
-- 				securemode="WPA-PSK / WPA2-PSK"
-- 			end
--                 --
-- 		elseif authmode == "WEPAUTO" or authmode == "SHARED" then
-- 			securemode="WEP"
-- 		elseif authmode == "NONE" then
-- 			securemode="No Security"
-- 		elseif authmode == "WPAPSKWPA2PSK" then
-- 			securemode="WPA2-PSK"
-- 		-- add by darren 2012.03.07
-- 		elseif authmode == "WPA2" then
-- 			if WPACompatible_5G == "0" then
-- 				securemode=authmode
-- 			elseif WPACompatible_5G == "1" then
-- 				securemode="WPA / WPA2"
-- 			end
--                 --
-- 		else
-- 			securemode=authmode
-- 		end

-- 		config_status="Configured"
-- 	else
-- 		config_status="Unconfigured"
-- 	end
-- 	--Generate a new vendor pin code
-- 	if genPin then
-- 		pincode=sys.exec("qcsapi_sockrpc --host 223.254.253.252 get_wps_ap_pin wifi0 1")
-- 		uci:set("wps5G","wps","appin",pincode)
-- 		uci:commit("wps5G")
-- 		sys.exec("wps5G ath10 on")
-- 	end
-- 	--Variable "wps_set" will be used in the GUI
-- 	if (wps_enable == "1") then
-- 		wps_set="enabled"
-- 	elseif (wps_enable == "0") then
-- 		wps_set="disabled"
-- 	end

-- 	--Variable "pincode_set" will be used in the GUI
--         if (pincode_enable == "1") then
--                 pincode_set="enabled"
--         elseif (pincode_enable == "0") then
--                 pincode_set="disabled"
--         end

-- 	if apply then


-- 		if (wps_choice == "1") then
-- 			if (wps_enable == "0") then --From disable wps to enable wps
-- 				wps_chk="1"
-- 				if (pincode_enable == "1") then
-- 					pincode_enable=1
-- 					pincode_set="enabled"
-- 					wps_change = true

-- 				elseif (pincode_enable == "0") then --PIN-code disable
-- 					incode_enable=0
-- 					pincode_set="disabled"
-- 					wps_change = true
-- 				end
-- 			elseif(wps_enable == "1") then
-- 				if (pincode_choice == "1") then
-- 					if (pincode_enable == "0") then --From disable PIN-code to enable PIN-code
-- 						pincode_enable=1
-- 						pincode_set="enabled"
-- 						wps_change = true
-- 					end
-- 				elseif (pincode_choice == "0") then --From enable PIN-code to disable PIN-code
-- 					if (pincode_enable == "1") then
-- 						pincode_enable=0
-- 						pincode_set="disabled"
-- 						wps_change = true
-- 					end
-- 				end
-- 			end

-- 			if wps_change then
-- 				wps_enable=1
-- 				wps_set="enabled"
-- 				uci:set("wps5G","wps", "PinEnable", pincode_enable)
-- 				uci:set("wps5G","wps", "enabled", wps_enable)
-- 				uci:commit("wps5G")
-- 				if (wps_chk == "1") then
-- 					sys.exec("qcsapi_sockrpc --host 223.254.253.252 set_wps_configured_state wifi0 2")
--                 end
-- 			end

-- 			sys.exec("wps5G ath10 on")

-- 		elseif (wps_choice == "0") then --From enable wps to disable wps
-- 			if (wps_enable == "1") then
--                 		wps_chk="1"
--             		end
-- 			wps_enable=0
-- 			wps_set="disabled"
-- 			uci:set("wps5G","wps", "PinEnable", pincode_enable)
-- 			uci:set("wps5G","wps", "enabled", wps_enable)
-- 			uci:commit("wps5G")
-- 			if (wps_chk == "1") then
-- 				sys.exec("qcsapi_sockrpc --host 223.254.253.252 set_wps_configured_state wifi0 0")
--             end
-- 			sys.exec("wps5G ath10 off")
-- 		end
-- 		sys.exec("/sbin/zyxel_led_ctrl all")
-- 	end
-- ---WPSSTATION5G
-- 	local wps_enable = uci:get("wps5G","wps","enabled")
-- 	local enable_wps_btn = luci.http.formvalue("wps_button")
-- 	local enable_wps_pin = luci.http.formvalue("wps_pin")
-- 	local PinWords_invalid = luci.http.formvalue("PinWords_invalid")
-- 	local valid = 1
-- 	local hstapd_cli = "hostapd_cli -p /tmp/run/hostapd-wifi1/ -i ath10 "
-- 	--Variable "wps_set" will be used in the GUI
-- 	if (wps_enable == "1") then
-- 		wps_set="enabled"
-- 	elseif (wps_enable == "0") then
-- 		wps_set="disabled"
-- 	end

-- --	if (configured == "1") then
-- --		config_status = "conf"
-- --	else
-- --		config_status = "unconf"
-- --	end

-- 	local fd
-- 	if enable_wps_btn then
-- 		sys.exec("zyxel_WPS_ctrl WPS5G_GUI")

-- 		for i=1,120 do
-- 			if io.open( "/tmp/pbc_overlap", "r" ) then
-- 				valid = 2
-- 				break;
-- 			end
-- 			if io.open( "/tmp/wps_success", "r" ) then
-- 				valid = 4
-- 				break;
-- 			end
-- 			if io.open( "/tmp/wps_timeout", "r" ) then
-- 				valid = 3
-- 				break;
-- 			end
-- 		end

-- 		luci.template.render("expert_configuration/wlanwps5G",{AP_PIN = pincode,
-- 								SSID = apssid,
-- 								RadioMode = radiomode,
-- 								SecureMode = securemode,
-- 								ConfigStatus = config_status,
-- 								WPS_Enabled_Choose = wps_enable_choose,
-- 								PINCode5G_Enabled = pincode_set,
-- 								WPS_Enabled = wps_set, pin_valid = valid,
-- 								Wireless5G_Disabled = wireless5g_disabled})
-- 		return
-- 	end

-- 	if enable_wps_pin then
-- 		local pincode
-- 		local pin_verify
-- 		pincode = luci.http.formvalue("wps_pincode")
-- 		if ( string.find(pincode, "-") or string.find(pincode, " ")) then
-- 			pincode = string.sub(pincode,1,4)..string.sub(pincode,6,9)
-- 		end



-- 		chk_led = uci:get("system","led","on")
-- 		if pincode ~= "" then
-- 			sys.exec("rm /tmp/pbc_overlap /tmp/wps_success /tmp/wps_timeout /tmp/wps5g_status")
-- 			chk_key = sys.exec("qcsapi_sockrpc --host 223.254.253.252 registrar_report_pin wifi0 " .. pincode)

-- 			if string.match(chk_key, "complete") then
-- 				sys.exec("zyxel_led_ctrl WPS5G "..chk_led.." ")

-- 				for i=1,120 do
-- 					sys.exec("qcsapi_sockrpc --host 223.254.253.252 get_wps_state wifi0>/tmp/wps5g_status")
-- 					sys.exec("sleep 1")

-- 					local file = io.open("/tmp/wps5g_status", "r")
-- 					local temp = file:read("*all")
-- 					file:close()

-- 					if temp:match("WPS_TIMEOUT") then
-- 						sys.exec("echo 1>/tmp/wps_timeout")
-- 					elseif temp:match("WPS_SUCCESS") then
-- 						sys.exec("echo 1>/tmp/wps_success")
-- 					elseif temp:match("WPS_OVERLAP") then
-- 						sys.exec("echo 1>/tmp/pbc_overlap")
-- 					end

-- 					if io.open( "/tmp/pbc_overlap", "r" ) then
-- 						sys.exec("killall wps5G")
-- 						break;
-- 					end
-- 					if io.open( "/tmp/wps_success", "r" ) then
-- 						sys.exec("killall wps5G")
-- 						break;
-- 					end
-- 					if io.open( "/tmp/wps_timeout", "r" ) then
-- 						sys.exec("killall wps5G")
-- 						break;
-- 					end
-- 				end
-- 				wps_conf = sys.exec("qcsapi_sockrpc --host 223.254.253.252 get_wps_configured_state wifi0")

-- 				if string.match(wps_conf, "not configured") then
-- 					sys.exec("qcsapi_sockrpc --host 223.254.253.252 set_wps_configured_state wifi0 1")
-- 					uci:set("wps5G","wps","conf",0)
-- 				else
-- 					sys.exec("qcsapi_sockrpc --host 223.254.253.252 set_wps_configured_state wifi0 2")
-- 					uci:set("wps5G","wps","conf",1)
-- 				end

-- 				uci:commit("wps5G")
-- 				sys.exec("zyxel_led_ctrl WPS5G 0")

-- 			else
-- 				luci.template.render("expert_configuration/wlanwps5G",{
-- 									SSID = apssid,
-- 									RadioMode = radiomode,
-- 									SecureMode = securemode,
-- 									ConfigStatus = config_status,
-- 									WPS_Enabled_Choose = wps_enable_choose,
-- 									PINCode5G_Enabled = pincode_set,
-- 									WPS_Enabled = wps_set, pin_valid = 0,
-- 									Wireless5G_Disabled = wireless5g_disabled})
-- 				return
-- 			end
-- 		end
-- 	end

-- ---WPSSTATION5G
-- 	luci.template.render("expert_configuration/wlanwps5G", {AP_PIN = pincode,
-- 								SSID = apssid,
-- 								RadioMode = radiomode,
-- 								SecureMode = securemode,
-- 								ConfigStatus = config_status,
-- 								WPS_Enabled_Choose = wps_enable_choose,
-- 								PINCode5G_Enabled = pincode_set,
-- 								WPS_Enabled = wps_set,
-- 								pin_valid = 1,
-- 								Wireless5G_Disabled = wireless5g_disabled})
-- end

function wlanwpsstation_5G()
	local wps_enable = uci:get("wps5G","wps","enabled")
	local wps_set
	local enable_wps_btn = luci.http.formvalue("wps_button")
	local enable_wps_pin = luci.http.formvalue("wps_pin")
	local PinWords_invalid = luci.http.formvalue("PinWords_invalid")
	local configured = uci:get("wps5G","wps","conf")
	local config_status
	local valid = 1
	local hstapd_cli = "hostapd_cli -p /tmp/run/hostapd-wifi1/ -i ath10 "
	--Variable "wps_set" will be used in the GUI

	if (wps_enable == "1") then
		wps_set="enabled"
	elseif (wps_enable == "0") then
		wps_set="disabled"
	end

--	if (configured == "1") then
--		config_status = "conf"
--	else
--		config_status = "unconf"
--	end

	local fd
	if enable_wps_btn then
		sys.exec("killall -9 wps5G")
		fd = io.popen("wps5G ath10 on wps_btn &")
		sys.exec("rm /tmp/pbc_overlap")
		sys.exec("rm /tmp/wps_success")
		sys.exec("rm /tmp/wps_timeout")

		for i=1,120 do
			sys.exec("sleep 1")
			if io.open( "/tmp/pbc_overlap", "r" ) then
				valid = 2
				sys.exec("killall wps5G")
				sys.exec("led_ctrl WPS off && sleep 10 && led_ctrl WPS on &")
				sys.exec("rm /tmp/wps_link_success")
				break;
			end

			if io.open( "/tmp/wps_success", "r" ) then
				valid = 4
				sys.exec("killall wps5G")
				sys.exec("led_ctrl WPS off && sleep 10 && led_ctrl WPS on &")
				sys.exec("rm /tmp/wps_link_success")
				break;
			end

			if io.open( "/tmp/wps_timeout", "r" ) then
				valid = 3
				sys.exec("killall wps5G")
				sys.exec("led_ctrl WPS off && sleep 10 && led_ctrl WPS on &")
				sys.exec("rm /tmp/wps_link_success")
				break;
			end
		end

		luci.template.render("expert_configuration/wlanwpsstation5G",{WPS_Enabled = wps_set, pin_valid = valid})
		return
	end

	if enable_wps_pin then
		local pincode
		local pin_verify
		pincode = luci.http.formvalue("wps_pincode")

		if ( string.find(pincode, "-") or string.find(pincode, " ")) then
			pincode = string.sub(pincode,1,4)..string.sub(pincode,6,9)
		end

		pin_verify = sys.exec(hstapd_cli .. "wps_check_pin " .. pincode)

		if ( pin_verify == pincode ) then
			sys.exec("killall -9 wps5G")
			fd = io.popen("wps5G ath10 on wps_pin ".. pincode .. " &")
		else
			luci.template.render("expert_configuration/wlanwpsstation5G",{WPS_Enabled = wps_set, pin_valid = 0})
			return
		end
	end

	luci.template.render("expert_configuration/wlanwpsstation5G",{WPS_Enabled = wps_set, pin_valid = 1})
end

function wlanscheduling_5G()
	local product_name = uci:get("system", "main", "product_name")
	local apply = luci.http.formvalue("sysSubmit")

	if apply then
		local enabled = luci.http.formvalue("WLanSch5GRadio")
		local sun = luci.http.formvalue("t0")
		local mon = luci.http.formvalue("t1")
		local tue = luci.http.formvalue("t2")
		local wed = luci.http.formvalue("t3")
		local thu = luci.http.formvalue("t4")
		local fri = luci.http.formvalue("t5")
		local sat = luci.http.formvalue("t6")

		sys.exec("/bin/WiFi_GUI_ctrl wifi_schedule_Apply 5G "..enabled.." "..sun.." "..mon.." "..tue.." "..wed.." "..thu.." "..fri.." "..sat)
	end

	local show_val=sys.exec("/bin/WiFi_GUI_ctrl wifi_schedule 5G")
	local val_list=NEW_split(show_val,"<;;>")

	luci.template.render("expert_configuration/wlanscheduling5G",{
							ENABLED = val_list[1],
							SUN = val_list[2],
							MON = val_list[3],
							TUE = val_list[4],
							WED = val_list[5],
							THU = val_list[6],
							FRI = val_list[7],
							SAT = val_list[8]
							})
end
--sendoh

--benson vpn
function action_vpn()
	local apply = luci.http.formvalue("sysSubmit")
	local netbios_allow = luci.http.formvalue("IPSecPassThrough")

	if apply then
		if not netbios_allow then
			netbios_allow="disable"
		else
			netbios_allow="enable"
		end

		uci:set("ipsec_new","general",'netbiosAllow',netbios_allow)
		uci:commit("ipsec_new")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("ipsec_new")
	end

	luci.template.render("expert_configuration/vpn")
end

function action_samonitor()
	local remote_gw_ip
	local rule_status = {"","","","",""}
	local roadwarrior = {"0","0","0","0","0"}
	local record_number
	local rules
	local key_mode

	--for roadwarrior case
	record_number = luci.sys.exec("racoonctl show-sa isakmp | wc -l | awk '{printf $1}'")
	record_number = tonumber(record_number)
	record_number = record_number - 1

	for i=1,5 do
		rules="rule"..i
		key_mode = uci:get("ipsec", rules, "keyMode")
		remote_gw_ip = uci:get("ipsec", rules, "remote_gw_ip")
		if key_mode == "IKE" then
			if remote_gw_ip then
				if remote_gw_ip == "0.0.0.0" then
					roadwarrior[i]="1"
				else
					rule_status[i] = luci.sys.exec("racoonctl show-sa isakmp | grep -c "..remote_gw_ip)
					if ( rule_status[i] == "" ) then
						rule_status[i]="0"
					else
						--not roadwarrior case
						record_number = record_number - 1
					end
				end
			else
				rule_status[i]="0"
			end
		else
			rule_status[i]="0"
		end
	end

	--temporary method
	for i=1,5 do
		if roadwarrior[i] == "1" then
			if record_number == 0 then
				rule_status[i]="0"
			else
				rule_status[i]="1"
			end
		end
	end

	luci.template.render("expert_configuration/samonitor", {status_r1 = rule_status[1],
								status_r2 = rule_status[2],
								status_r3 = rule_status[3],
								status_r4 = rule_status[4],
								status_r5 = rule_status[5]})
end

function action_vpnEdit()
	local apply = luci.http.formvalue("sysSubmit")
	local rules = luci.http.formvalue("rules")
	local edit = luci.http.formvalue("edit")
	local delete = luci.http.formvalue("delete")

	if apply then
		local statusEnable = luci.http.formvalue("ssid_state")
		local IPSecKeepAlive = luci.http.formvalue("IPSecKeepAlive")

		if not IPSecKeepAlive then
			IPSecKeepAlive="off"
		end
		local IPSecNatTraversal = luci.http.formvalue("IPSecNatTraversal")

		if not IPSecNatTraversal then
			IPSecNatTraversal="off"
		end

		local s1 = luci.http.formvalue("keyModeSelect")
		local keyModeSelect

		if s1 == "00000000" then
			 keyModeSelect="IKE"
		else
			 keyModeSelect="manual"
		end

		local LocalAddrType = luci.http.formvalue("LocalAddressTypeSelect")
		local RemoteAddrType = luci.http.formvalue("RemoteAddressTypeSelect")
		local IPSecSourceAddrStart = luci.http.formvalue("IPSecSourceAddrStart")
		local IPSecSourceAddrMask = luci.http.formvalue("IPSecSourceAddrMask")
		local IPSecDestAddrStart = luci.http.formvalue("IPSecDestAddrStart")
		local IPSecDestAddrMask = luci.http.formvalue("IPSecDestAddrMask")
		local localPublicIP = luci.http.formvalue("localPublicIP")
		local s2 = luci.http.formvalue("localContentSelect")
		local localContentSelect

		if s2 == "00000000" then
			localContentSelect="address"
		elseif s2 == "00000001" then
			localContentSelect="fqdn"
		else
			localContentSelect="user_fqdn"
		end

		local localContent = luci.http.formvalue("localContent")
		local remotePublicIP = luci.http.formvalue("remotePublicIP")
		local s3 = luci.http.formvalue("remoteContentSelect")
		local remoteContentSelect

		if s3 == "00000000" then
			 remoteContentSelect="address"
		elseif s3 == "00000001" then
			 remoteContentSelect="fqdn"
		else
			 remoteContentSelect="user_fqdn"
		end

		local remoteContent = luci.http.formvalue("remoteContent")
		local IPSecPreSharedKey = luci.http.formvalue("IPSecPreSharedKey")
		local s8 = luci.http.formvalue("modeSelect")
		local modeSelect

		if s8 == "00000000" then
			modeSelect="main"
		elseif s8 == "00000001" then
			modeSelect="aggressive"
		else
			modeSelect="main, aggressive"
		end

		local authKey = luci.http.formvalue("authKey")
		local IPSecSPI = luci.http.formvalue("IPSecSPI")
		local s6 = luci.http.formvalue("encapAlgSelect")
		local encapAlgSelect

		if s6 == "00000000" then
			 encapAlgSelect="des-cbc"
		else
			 encapAlgSelect="3des-cbc"
		end

		local encrypKey = luci.http.formvalue("encrypKey")
		local s7 = luci.http.formvalue("authAlgSelect")
		local authAlgSelect

		if s7 == "00000000" then
			 authAlgSelect="hmac-md5"
		else
			 authAlgSelect="hmac-sha1"
		end

		local authKey = luci.http.formvalue("authKey")
		local saLifeTime = luci.http.formvalue("saLifeTime")
		local s9 = luci.http.formvalue("keyGroup")
		local keyGroup

		if s9 == "00000000" then
			 keyGroup="modp768"
		else
			 keyGroup="modp1024"
		end

		local s4 = luci.http.formvalue("encapModeSelect")
		local encapModeSelect

		if s4 == "00000000" then
			 encapModeSelect="tunnel"
		else
			 encapModeSelect="transport"
		end

		local s5 = luci.http.formvalue("protocolSelect")
		local protocolSelect

		if s5 == "00000000" then
			 protocolSelect="esp"
		else
			 protocolSelect="ah"
		end

		local s10 = luci.http.formvalue("encapAlgSelect2")
		local encapAlgSelect2

		if s10 == "00000000" then
			 encapAlgSelect2="des-cbc"
		else
			 encapAlgSelect2="3des-cbc"
		end

		local s11 = luci.http.formvalue("authAlgSelect2")
		local authAlgSelect2

		if s11 == "00000000" then
			 authAlgSelect2="hmac-md5"
		else
			 authAlgSelect2="hmac-sha1"
		end

		local saLifeTime2 = luci.http.formvalue("saLifeTime2")
		local s11 = luci.http.formvalue("keyGroup2")
		local keyGroup2

		if s11 == "00000000" then
			keyGroup2="modp768"
		else
			keyGroup2="modp1024"
		end

		uci:set("ipsec",rules,"ipsec")

		if LocalAddrType == "1" then
			uci:set("ipsec",rules,"LocalAddrType","1")
			uci:set("ipsec",rules,'localNetMask',IPSecSourceAddrMask)
		else
			uci:set("ipsec",rules,"LocalAddrType","0")
			uci:set("ipsec",rules,'localNetMask',"255.255.255.255")
		end

		if RemoteAddrType == "1" then
			uci:set("ipsec",rules,"RemoteAddrType","1")
			uci:set("ipsec",rules,"peerNetMask",IPSecDestAddrMask)
		else
			uci:set("ipsec",rules,"RemoteAddrType","0")
			uci:set("ipsec",rules,"peerNetMask","255.255.255.255")
		end

		uci:set("ipsec",rules,'statusEnable',statusEnable)
		uci:set("ipsec",rules,'KeepAlive',IPSecKeepAlive)
		uci:set("ipsec",rules,'NatTraversal',IPSecNatTraversal)
		uci:set("ipsec",rules,'keyMode',keyModeSelect)
		uci:set("ipsec",rules,'localIP',IPSecSourceAddrStart)
		--uci:set("ipsec",rules,'localNetMask',IPSecSourceAddrMask)
		uci:set("ipsec",rules,'peerIP',IPSecDestAddrStart)
		--uci:set("ipsec",rules,'peerNetMask',IPSecDestAddrMask)
		uci:set("ipsec",rules,'localGwIP',localPublicIP)
		uci:set("ipsec",rules,'my_identifier_type',localContentSelect)
		uci:set("ipsec",rules,'my_identifier',localContent)
		uci:set("ipsec",rules,'remoteGwIP',remotePublicIP)
		uci:set("ipsec",rules,'peers_identifier_type',remoteContentSelect)
		uci:set("ipsec",rules,'peers_identifier',remoteContent)
		uci:set("ipsec",rules,'preSharedKey',IPSecPreSharedKey)
		uci:set("ipsec",rules,'mode',modeSelect)
		uci:set("ipsec",rules,'spi',IPSecSPI)
		uci:set("ipsec",rules,'enAlgo',encapAlgSelect)
		uci:set("ipsec",rules,'enKey',encrypKey)
		uci:set("ipsec",rules,'authAlgo',authAlgSelect)
		uci:set("ipsec",rules,'authKey',authKey)
		uci:set("ipsec",rules,'lifeTime',saLifeTime)
		uci:set("ipsec",rules,'keyGroup',keyGroup)
		uci:set("ipsec",rules,'enMode',encapModeSelect)
		uci:set("ipsec",rules,'protocol',protocolSelect)
		uci:set("ipsec",rules,'enAlgo2',encapAlgSelect2)
		uci:set("ipsec",rules,'authAlgo2',authAlgSelect2)
		uci:set("ipsec",rules,'lifeTime2',saLifeTime2)
		uci:set("ipsec",rules,'keyGroup2',keyGroup2)
		uci:commit("ipsec")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("ipsec")

		luci.template.render("expert_configuration/vpn")
		return
	end --end apply

	if edit then
		local rules = edit
		local stEnable = uci:get("ipsec",rules,'statusEnable')
		local KeepAlive = uci:get("ipsec",rules,'KeepAlive')
		local NatTraversal = uci:get("ipsec",rules,'NatTraversal')
		local keyMode = uci:get("ipsec",rules,'keyMode')
		local localIP = uci:get("ipsec",rules,'localIP')
		local localNetMask = uci:get("ipsec",rules,'localNetMask')
		local peerIP = uci:get("ipsec",rules,'peerIP')
		local peerNetMask = uci:get("ipsec",rules,'peerNetMask')
		local localGwIP = uci:get("ipsec",rules,'localGwIP')
		local my_identifier_type = uci:get("ipsec",rules,'my_identifier_type')
		local my_identifier = uci:get("ipsec",rules,'my_identifier')
		local remoteGwIP = uci:get("ipsec",rules,'remoteGwIP')
		local peers_identifier_type = uci:get("ipsec",rules,'peers_identifier_type')
		local peers_identifier = uci:get("ipsec",rules,'peers_identifier')
		local preSharedKey = uci:get("ipsec",rules,'preSharedKey')
		local mode = uci:get("ipsec",rules,'mode')
		local spi = uci:get("ipsec",rules,'spi')
		local enAlgo = uci:get("ipsec",rules,'enAlgo')
		local enKeyy = uci:get("ipsec",rules,'enKey')
		local authAlgo = uci:get("ipsec",rules,'authAlgo')
		local authKeyy = uci:get("ipsec",rules,'authKey')
		local lifeTime = uci:get("ipsec",rules,'lifeTime')
		local keyyGroup = uci:get("ipsec",rules,'keyGroup')
		local enMode = uci:get("ipsec",rules,'enMode')
		local protocol = uci:get("ipsec",rules,'protocol')
		local enAlgo2 = uci:get("ipsec",rules,'enAlgo2')
		local authAlgo2 = uci:get("ipsec",rules,'authAlgo2')
		local lifeTime2 = uci:get("ipsec",rules,'lifeTime2')
		local keyyGroup2 = uci:get("ipsec",rules,'keyGroup2')
		local url = luci.dispatcher.build_url("expert","configuration","security","vpn","vpn_edit")
		local paramStr = ""

		if stEnable then 	paramStr=paramStr .. "&stEnable=" .. stEnable end
		if KeepAlive then 	paramStr=paramStr .. "&KeepAlive=" .. KeepAlive end
		if NatTraversal then 	paramStr=paramStr .. "&NatTraversal=" .. NatTraversal end
		if keyMode then 	paramStr=paramStr .. "&keyMode=" .. keyMode end
		if localIP then 	paramStr=paramStr .. "&localIP=" .. localIP end
		if localNetMask then 	paramStr=paramStr .. "&localNetMask=" .. localNetMask end
		if peerIP then 	paramStr=paramStr .. "&peerIP=" .. peerIP end
		if peerNetMask then 	paramStr=paramStr .. "&peerNetMask=" .. peerNetMask end
		if localGwIP then 	paramStr=paramStr .. "&localGwIP=" .. localGwIP end
		if my_identifier_type then 	paramStr=paramStr .. "&my_identifier_type=" .. my_identifier_type end
		if my_identifier then 	paramStr=paramStr .. "&my_identifier=" .. my_identifier end
		if remoteGwIP then 	paramStr=paramStr .. "&remoteGwIP=" .. remoteGwIP end
		if peers_identifier_type then 	paramStr=paramStr .. "&peers_identifier_type=" .. peers_identifier_type end
		if peers_identifier then 	paramStr=paramStr .. "&peers_identifier=" .. peers_identifier end
		if preSharedKey then 	paramStr=paramStr .. "&preSharedKey=" .. preSharedKey end
		if mode then 	paramStr=paramStr .. "&mode=" .. mode end
		if spi then 	paramStr=paramStr .. "&spi=" .. spi end
		if enAlgo then 	paramStr=paramStr .. "&enAlgo=" .. enAlgo end
		if enKeyy then 	paramStr=paramStr .. "&enKeyy=" .. enKeyy end
		if authAlgo then 	paramStr=paramStr .. "&authAlgo=" .. authAlgo end
		if authKeyy then 	paramStr=paramStr .. "&authKeyy=" .. authKeyy end
		if lifeTime then 	paramStr=paramStr .. "&lifeTime=" .. lifeTime end
		if keyyGroup then 	paramStr=paramStr .. "&keyyGroup=" .. keyyGroup end
		if enMode then 	paramStr=paramStr .. "&enMode=" .. enMode end
		if protocol then 	paramStr=paramStr .. "&protocol=" .. protocol end
		if enAlgo2 then 	paramStr=paramStr .. "&enAlgo2=" .. enAlgo2 end
		if authAlgo2 then 	paramStr=paramStr .. "&authAlgo2=" .. authAlgo2 end
		if lifeTime2 then 	paramStr=paramStr .. "&lifeTime2=" .. lifeTime2 end
		if keyyGroup2 then 	paramStr=paramStr .. "&keyyGroup2=" .. keyyGroup2 end

		luci.http.redirect(url .. "?" .. "rules=" .. rules  .. paramStr)
		return
	end --end edit

	if delete then
		local rules2 = delete

		uci:delete("ipsec", rules2)
		uci:commit("ipsec")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("ipsec")

		luci.template.render("expert_configuration/vpn")
		return
	end

	luci.template.render("expert_configuration/vpn_edit")
end
--benson vpn

function action_qos()
	apply = luci.http.formvalue("apply")

	if apply then
		local qosEnable = luci.http.formvalue("qosEnable")
		uci:set("qos","general","enable",qosEnable)

		if qosEnable == "0" then
			uci:set("qos","general","game_enable",qosEnable)
		end

		uci:commit("qos")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("qos")
	end

	luci.template.render("expert_configuration/qos")
	return
end

function NEW_split(str,sep)
	local array = {}
	list = string.split(str, sep)

	for _, val in ipairs(list) do
	 	table.insert(array, val)
	end

    return array
end

function split(str, c)
	a = string.find(str, c)
	str = string.gsub(str, c, "", 1)
	aCount = 0
	start = 1
	array = {}
	last = 0

	while a do
		array[aCount] = string.sub(str, start, a - 1)
		start = a
		a = string.find(str, c)

		str = string.gsub(str, c, "", 1)
		aCount = aCount + 1
	end

	return array
end

function action_qos_AppEdit()
		apply_edit_AdvSet = luci.http.formvalue("apply_edit_AdvSet")

		if apply_edit_AdvSet == "0" then
			apply_edit_AdvSet = "app_policy_0"
		elseif apply_edit_AdvSet == "1" then
			apply_edit_AdvSet = "app_policy_1"
		elseif apply_edit_AdvSet == "2" then
			apply_edit_AdvSet = "app_policy_2"
		elseif apply_edit_AdvSet == "3" then
			apply_edit_AdvSet = "app_policy_3"
		elseif apply_edit_AdvSet == "4" then
			apply_edit_AdvSet = "app_policy_4"
		elseif apply_edit_AdvSet == "5" then
			apply_edit_AdvSet = "app_policy_5"
		elseif apply_edit_AdvSet == "6" then
			apply_edit_AdvSet = "app_policy_6"
		elseif apply_edit_AdvSet == "7" then
			apply_edit_AdvSet = "app_policy_7"
		elseif apply_edit_AdvSet == "8" then
			apply_edit_AdvSet = "app_policy_8"
		elseif apply_edit_AdvSet == "9" then
			apply_edit_AdvSet = "app_policy_9"
		else
			apply_edit_AdvSet = "app_policy_10"
		end

		if apply_edit_AdvSet == "app_policy_0" or apply_edit_AdvSet == "app_policy_1" or apply_edit_AdvSet == "app_policy_2" or apply_edit_AdvSet == "app_policy_9" then
			local Bandwidth_enable1 = luci.http.formvalue("Bandwidth_enable1")
			local Bandwidth_enable2 = luci.http.formvalue("Bandwidth_enable2")
			local Bandwidth_enable3 = luci.http.formvalue("Bandwidth_enable3")
			local Bandwidth_enable4 = luci.http.formvalue("Bandwidth_enable4")

			if Bandwidth_enable1 ~= "1" then
				Bandwidth_enable1 = "0"
			end

			if Bandwidth_enable2 ~= "1" then
				Bandwidth_enable2 = "0"
			end

			if Bandwidth_enable3 ~= "1" then
				Bandwidth_enable3 = "0"
			end			

			if Bandwidth_enable4 ~= "1" then
				Bandwidth_enable4 = "0"
			end

			local Bandwidth_select1 = luci.http.formvalue("Bandwidth_select1")
			local Bandwidth_value1 = luci.http.formvalue("Bandwidth_value1")

			local Bandwidth_select2 = luci.http.formvalue("Bandwidth_select2")
			local Bandwidth_value2 = luci.http.formvalue("Bandwidth_value2")

			local Bandwidth_select3 = luci.http.formvalue("Bandwidth_select3")
			local Bandwidth_value3 = luci.http.formvalue("Bandwidth_value3")

			local Bandwidth_select4 = luci.http.formvalue("Bandwidth_select4")
			local Bandwidth_value4 = luci.http.formvalue("Bandwidth_value4")

			uci:set("qos",apply_edit_AdvSet,"lan_tcp_enable",Bandwidth_enable1)
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_min",Bandwidth_select1)
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_bw",Bandwidth_value1)

			uci:set("qos",apply_edit_AdvSet,"lan_udp_enable",Bandwidth_enable2)
			uci:set("qos",apply_edit_AdvSet,"lan_udp_min",Bandwidth_select2)
			uci:set("qos",apply_edit_AdvSet,"lan_udp_bw",Bandwidth_value2)

			uci:set("qos",apply_edit_AdvSet,"wan_tcp_enable",Bandwidth_enable3)
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_min",Bandwidth_select3)
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_bw",Bandwidth_value3)

			uci:set("qos",apply_edit_AdvSet,"wan_udp_enable",Bandwidth_enable4)
			uci:set("qos",apply_edit_AdvSet,"wan_udp_min",Bandwidth_select4)
			uci:set("qos",apply_edit_AdvSet,"wan_udp_bw",Bandwidth_value4)
		else
			local Bandwidth_enable1 = luci.http.formvalue("Bandwidth_enable1")
			local Bandwidth_enable2 = luci.http.formvalue("Bandwidth_enable2")

			if Bandwidth_enable1 ~= "1" then
				Bandwidth_enable1 = "0"
			end

			if Bandwidth_enable2 ~= "1" then
				Bandwidth_enable2 = "0"
			end

			local Bandwidth_select1 = luci.http.formvalue("Bandwidth_select1")
			local Bandwidth_value1 = luci.http.formvalue("Bandwidth_value1")

			local Bandwidth_select2 = luci.http.formvalue("Bandwidth_select2")
			local Bandwidth_value2 = luci.http.formvalue("Bandwidth_value2")

			uci:set("qos",apply_edit_AdvSet,"lan_tcp_enable",Bandwidth_enable1)
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_min",Bandwidth_select1)
			uci:set("qos",apply_edit_AdvSet,"lan_tcp_bw",Bandwidth_value1)

			uci:set("qos",apply_edit_AdvSet,"wan_tcp_enable",Bandwidth_enable2)
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_min",Bandwidth_select2)
			uci:set("qos",apply_edit_AdvSet,"wan_tcp_bw",Bandwidth_value2)
		end

		uci:commit("qos")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("qos")
		luci.template.render("expert_configuration/qos_adv")
end

function action_qos_CfgEdit()
		apply_edit = luci.http.formvalue("apply_edit")

		local bwSelect = luci.http.formvalue("bwSelect")
	    local bwValue = luci.http.formvalue("bwValue")
		local srcAddrStart = luci.http.formvalue("srcAddrStart")
		local srcAddrEnd = luci.http.formvalue("srcAddrEnd")
		local srcPort = luci.http.formvalue("srcPort")
		local dstAddrStart = luci.http.formvalue("dstAddrStart")
		local dstAddrEnd = luci.http.formvalue("dstAddrEnd")
		local dstPort = luci.http.formvalue("dstPort")
		local proto = luci.http.formvalue("proto")

		uci:set("qos",apply_edit,"reserve_bw",bwSelect)
		uci:set("qos",apply_edit,"bw_value",bwValue)
		uci:set("qos",apply_edit,"inipaddr_start",srcAddrStart)
		uci:set("qos",apply_edit,"inipaddr_end",srcAddrEnd)
		uci:set("qos",apply_edit,"inport",srcPort)
		uci:set("qos",apply_edit,"outipaddr_start",dstAddrStart)
		uci:set("qos",apply_edit,"outipaddr_end",dstAddrEnd)
		uci:set("qos",apply_edit,"outport",dstPort)
		uci:set("qos",apply_edit,"proto",proto)

		local to_intf = uci:get("qos",apply_edit,"to_intf")

		if to_intf == "lan" then
			uci:set("qos",apply_edit,"bw_towan",0)
			uci:set("qos",apply_edit,"bw_tolan",bwValue)
		else
			uci:set("qos",apply_edit,"bw_tolan",0)
			uci:set("qos",apply_edit,"bw_towan",bwValue)
		end

		uci:commit("qos")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("qos")
		luci.template.render("expert_configuration/qos_adv")
end

function action_qos_adv()
	apply = luci.http.formvalue("apply")
	edit = luci.http.formvalue("edit")
	delete = luci.http.formvalue("delete")
	edit_AdvSet = luci.http.formvalue("edit_AdvSet")

	if apply then
		local upShapeRate = luci.http.formvalue("UploadBandwidth_value")
		local downShapeRate = luci.http.formvalue("DownloadBandwidth_value")

		local appPrio1 = luci.http.formvalue("appPrio1")
		local appPrio2 = luci.http.formvalue("appPrio2")
		local appPrio3 = luci.http.formvalue("appPrio3")
		local appPrio4 = luci.http.formvalue("appPrio4")
		local appPrio5 = luci.http.formvalue("appPrio5")
		local appPrio6 = luci.http.formvalue("appPrio6")		

		local appEnable1_1 = luci.http.formvalue("appEnable1_1")
		if appEnable1_1 ~= "1" then
			appEnable1_1 = "0"
		end

		local appEnable1_2 = luci.http.formvalue("appEnable1_2")
		if appEnable1_2 ~= "1" then
			appEnable1_2 = "0"
		end

		local appEnable1_3 = luci.http.formvalue("appEnable1_3")
		if appEnable1_3 ~= "1" then
			appEnable1_3 = "0"
		end

		local appEnable1_4 = luci.http.formvalue("appEnable1_4")
		if appEnable1_4 ~= "1" then
			appEnable1_4 = "0"
		end

		local appEnable2 = luci.http.formvalue("appEnable2")
		if appEnable2 ~= "1" then
			appEnable2 = "0"
		end

		local appEnable3 = luci.http.formvalue("appEnable3")
		if appEnable3 ~= "1" then
			appEnable3 = "0"
		end

		local appEnable4 = luci.http.formvalue("appEnable4")
		if appEnable4 ~= "1" then
			appEnable4 = "0"
		end

		local appEnable5_1 = luci.http.formvalue("appEnable5_1")
		if appEnable5_1 ~= "1" then
			appEnable5_1 = "0"
		end

		local appEnable5_2 = luci.http.formvalue("appEnable5_2")
		if appEnable5_2 ~= "1" then
			appEnable5_2 = "0"
		end

		local appEnable5_3 = luci.http.formvalue("appEnable5_3")
		if appEnable5_3 ~= "1" then
			appEnable5_3 = "0"
		end
		
		local appEnable6 = luci.http.formvalue("appEnable6")
		if appEnable6 ~= "1" then
			appEnable6 = "0"
		end

		if upShapeRate ~= "" then
			uci:set("qos","shaper", "port_rate_eth0", upShapeRate)
		else
			uci:set("qos","shaper", "port_rate_eth0", 0)
		end

		if downShapeRate ~= "" then
			uci:set("qos","shaper", "port_rate_lan", downShapeRate)
		else
			uci:set("qos","shaper", "port_rate_lan", 0)
		end

		uci:set("qos","app_policy_0","prio",appPrio1)
		uci:set("qos","app_policy_1","prio",appPrio1)
		uci:set("qos","app_policy_2","prio",appPrio1)
		uci:set("qos","app_policy_3","prio",appPrio1)

		uci:set("qos","app_policy_4","prio",appPrio2)
		uci:set("qos","app_policy_5","prio",appPrio3)
		uci:set("qos","app_policy_6","prio",appPrio4)

		uci:set("qos","app_policy_7","prio",appPrio5)
		uci:set("qos","app_policy_8","prio",appPrio5)
		uci:set("qos","app_policy_9","prio",appPrio5)

		uci:set("qos","app_policy_10","prio",appPrio6)

		uci:set("qos","app_policy_0","enable", appEnable1_1)
		uci:set("qos","app_policy_1","enable", appEnable1_2)
		uci:set("qos","app_policy_2","enable", appEnable1_3)
		uci:set("qos","app_policy_3","enable", appEnable1_4)
		uci:set("qos","app_policy_4","enable", appEnable2)
		uci:set("qos","app_policy_5","enable", appEnable3)
		uci:set("qos","app_policy_6","enable", appEnable4)
		uci:set("qos","app_policy_7","enable", appEnable5_1)
		uci:set("qos","app_policy_8","enable", appEnable5_2)
		uci:set("qos","app_policy_9","enable", appEnable5_3)
		uci:set("qos","app_policy_10","enable", appEnable6)

		for i=1,8 do

			userEnable_field="userEnable" .. i
			userEnable = luci.http.formvalue(userEnable_field)
			if userEnable ~= "1" then
				userEnable = "0"
			end

			uci:set("qos","eg_policy_" .. i,"enable",userEnable)
			
			userName_field="userName" .. i
			userName = luci.http.formvalue(userName_field)

			uci:set("qos","eg_policy_" .. i,"name",userName)

			userDir_field="userDir" .. i
			userDir = luci.http.formvalue(userDir_field)

			if userDir == "lan" then
				local value = uci:get("qos","eg_policy_" .. i,"bw_value")
				uci:set("qos","eg_policy_" .. i,"bw_towan",0)
				uci:set("qos","eg_policy_" .. i,"bw_tolan",value)
			else
				local value = uci:get("qos","eg_policy_" .. i,"bw_value")
				uci:set("qos","eg_policy_" .. i,"bw_tolan",0)
				uci:set("qos","eg_policy_" .. i,"bw_towan",value)
			end

			uci:set("qos","eg_policy_" .. i,"to_intf",userDir)
			
			userCategory_field="userPrio" .. i
			local userCategory = luci.http.formvalue(userCategory_field)

			if userCategory == "Game Console" then
				local prio = uci:get("qos","app_policy_0" ,"prio")
				uci:set("qos","eg_policy_" .. i,"prio",prio)
			elseif userCategory == "VoIP" then
				local prio = uci:get("qos","app_policy_4" ,"prio")
				uci:set("qos","eg_policy_" .. i,"prio",prio)
			elseif userCategory == "P2P/FTP" then
				local prio = uci:get("qos","app_policy_7" ,"prio")
				uci:set("qos","eg_policy_" .. i,"prio",prio)
			elseif userCategory == "Web Surfing" then
				local prio = uci:get("qos","app_policy_6" ,"prio")
				uci:set("qos","eg_policy_" .. i,"prio",prio)
			elseif userCategory == "Instant Messanger" then
				local prio = uci:get("qos","app_policy_5" ,"prio")
				uci:set("qos","eg_policy_" .. i,"prio",prio)
			else
				local prio = uci:get("qos","app_policy_10" ,"prio")
				uci:set("qos","eg_policy_" .. i,"prio",prio)
			end
			
			uci:set("qos","eg_policy_" .. i,"apptype",userCategory)
		end

		uci:commit("qos")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("qos")

		luci.template.render("expert_configuration/qos_adv")
	elseif edit then
		local edits

		if edit == "1" then
			edits = "eg_policy_1"
			userEnable = luci.http.formvalue("userEnable1")

			if userEnable ~= "undefined1" then
				userEnable = "0"
			else
				userEnable = "1"
			end

			userDir = luci.http.formvalue("userDir1")
			userName = luci.http.formvalue("userName1")
			userPrio = luci.http.formvalue("userPrio1")
		elseif edit == "2" then
			edits = "eg_policy_2"
			userEnable = luci.http.formvalue("userEnable2")

			if userEnable ~= "undefined1" then
				userEnable = "0"
			else
				userEnable = "1"
			end

			userDir = luci.http.formvalue("userDir2")
			userName = luci.http.formvalue("userName2")
			userPrio = luci.http.formvalue("userPrio2")
		elseif edit == "3" then
			edits = "eg_policy_3"
			userEnable = luci.http.formvalue("userEnable3")

			if userEnable ~= "undefined1" then
				userEnable = "0"
			else
				userEnable = "1"
			end

			userDir = luci.http.formvalue("userDir3")
			userName = luci.http.formvalue("userName3")
			userPrio = luci.http.formvalue("userPrio3")
		elseif edit == "4" then
			edits = "eg_policy_4"		
			userEnable = luci.http.formvalue("userEnable4")

			if userEnable ~= "undefined1" then
				userEnable = "0"
			else
				userEnable = "1"
			end

			userDir = luci.http.formvalue("userDir4")
			userName = luci.http.formvalue("userName4")
			userPrio = luci.http.formvalue("userPrio4")
		elseif edit == "5" then
			edits = "eg_policy_5"		
			userEnable = luci.http.formvalue("userEnable5")

			if userEnable ~= "undefined1" then
				userEnable = "0"
			else
				userEnable = "1"
			end			

			userDir = luci.http.formvalue("userDir5")
			userName = luci.http.formvalue("userName5")
			userPrio = luci.http.formvalue("userPrio5")
		elseif edit == "6" then
			edits = "eg_policy_6"		
			userEnable = luci.http.formvalue("userEnable6")

			if userEnable ~= "undefined1" then
				userEnable = "0"
			else
				userEnable = "1"
			end

			userDir = luci.http.formvalue("userDir6")
			userName = luci.http.formvalue("userName6")
			userPrio = luci.http.formvalue("userPrio6")
		elseif edit == "7" then
			edits = "eg_policy_7"		
			userEnable = luci.http.formvalue("userEnable7")

			if userEnable ~= "undefined1" then
				userEnable = "0"
			else
				userEnable = "1"
			end

			userDir = luci.http.formvalue("userDir7")
			userName = luci.http.formvalue("userName7")
			userPrio = luci.http.formvalue("userPrio7")
		else
			edits = "eg_policy_8"		
			userEnable = luci.http.formvalue("userEnable8")

			if userEnable ~= "undefined1" then
				userEnable = "0"
			else
				userEnable = "1"
			end

			userDir = luci.http.formvalue("userDir8")
			userName = luci.http.formvalue("userName8")
			userPrio = luci.http.formvalue("userPrio8")
		end

		uci:set("qos",edits,"enable", userEnable)
		uci:set("qos",edits,"to_intf", userDir)
		uci:set("qos",edits,"name", userName)
		uci:set("qos",edits,"apptype", userPrio)
		uci:commit("qos")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem

		local ruleBwSelect = uci:get("qos",edits,"reserve_bw")
		local ruleBwValue = uci:get("qos",edits,"bw_value")
		local ruleName = uci:get("qos",edits,"name")
		local ruleEnable = uci:get("qos",edits,"enable")
		local ruleSrcStart = uci:get("qos",edits,"inipaddr_start")
		local ruleSrcEnd = uci:get("qos",edits,"inipaddr_end")
		local ruleSrcPort = uci:get("qos",edits,"inport")
		local ruleDstStart = uci:get("qos",edits,"outipaddr_start")
		local ruleDstEnd = uci:get("qos",edits,"outipaddr_end")
		local ruleDstPort = uci:get("qos",edits,"outport")
		local ruleProto = uci:get("qos",edits,"proto")

		local LANsum = 0
		local WANsum = 0

		upstream = uci:get("qos","shaper","port_rate_eth0")
		downstream = uci:get("qos","shaper","port_rate_lan")

		my_enable=uci:get("qos",edits,"enable")
		my_value=uci:get("qos",edits,"bw_value")
		my_intf=uci:get("qos",edits,"to_intf")
		my_reserve=uci:get("qos",edits,"reserve_bw")

		if my_intf == "lan" then
		   my_intfs = "0"
		else
		   my_intfs = "1"
		end

		for i = 0, 10 do
			enable=uci:get("qos","app_policy_" .. i,"enable")

			lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
			lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
			wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
			wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")

			lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
			lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
			wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
			wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")

			lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
			lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
			wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
			wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

			if enable == "1" then

				if lan_tcp_enable == "1" then

					if lan_tcp_min == "1" then
						LANsum = LANsum + lan_tcp_bw
					end

				end

				if lan_udp_enable == "1" then

					if lan_udp_min == "1" then
						LANsum = LANsum + lan_udp_bw
					end

				end

				if wan_tcp_enable == "1" then

					if wan_tcp_min == "1" then
						WANsum = WANsum + wan_tcp_bw
					end

				end

				if wan_udp_enable == "1" then

					if wan_udp_min == "1" then
						WANsum = WANsum + wan_udp_bw
					end

				end

			end

		end

		for i = 1, 8 do
			enable=uci:get("qos","eg_policy_" .. i,"enable")
			value=uci:get("qos","eg_policy_" .. i,"bw_value")
			intf=uci:get("qos","eg_policy_" .. i,"to_intf")
			reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")

			if	enable == "1" then

				if intf == "wan" then

					if reserve == "2" then
						WANsum = WANsum + value
					end

				else

					if reserve == "2" then
						LANsum = LANsum + value
					end

				end

			end

		end

		if	my_enable == "1" then

			if my_intf == "wan" then

				if my_reserve == "2" then
					WANsum = WANsum - my_value
				end

			else

				if my_reserve == "2" then
					LANsum = LANsum - my_value
				end

			end

		end

		luci.template.render("expert_configuration/qos_cfg_edit", {
			My_enable = my_enable,
			My_intf = my_intfs,
			WAN_sum = WANsum,
			LAN_sum = LANsum,
			upstream_value = upstream,
			downstream_value = downstream,
			section_name = edits,
			rule_bw_Select = ruleBwSelect,
			rule_bw_value = ruleBwValue,
			rule_name = ruleName,
			rule_enable = ruleEnable,
			rule_src_start = ruleSrcStart,
			rule_src_end = ruleSrcEnd,
			rule_src_port = ruleSrcPort,
			rule_dst_start = ruleDstStart,
			rule_dst_end = ruleDstEnd,
			rule_dst_port = ruleDstPort,
			rule_proto = ruleProto
		})

	elseif delete then
		uci:set("qos",delete,"name","")
		uci:set("qos",delete,"enable",0)
		uci:set("qos",delete,"reserve_bw",2)
		uci:set("qos",delete,"bw_value",10)
		uci:set("qos",delete,"inipaddr_start","0.0.0.0")
		uci:set("qos",delete,"inipaddr_end","0.0.0.0")
		uci:set("qos",delete,"inport",0)
		uci:set("qos",delete,"outipaddr_start","0.0.0.0")
		uci:set("qos",delete,"outipaddr_end","0.0.0.0")
		uci:set("qos",delete,"outport",0)
		uci:set("qos",delete,"apptype","Game Console")
		uci:set("qos",delete,"to_intf","lan")
		uci:set("qos",delete,"proto","")
		uci:set("qos",delete,"prio",1)

		uci:commit("qos")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("qos")
		luci.template.render("expert_configuration/qos_adv")
	elseif edit_AdvSet then
        local section
		local appEnable
		local appPrio
		local upstream
		local downstream
		local edit_AdvSets

		if edit_AdvSet == "0" then
			section = "0"
			edit_AdvSets = "app_policy_0"
			appPrio = luci.http.formvalue("appPrio1")
			appEnable = luci.http.formvalue("appEnable1_1")

			if appEnable ~= "1" then
				appEnable = "0"
			end

			uci:set("qos","app_policy_0","prio",appPrio)
		elseif edit_AdvSet == "1" then
			section = "1"
			edit_AdvSets = "app_policy_1"
			appPrio = luci.http.formvalue("appPrio1")
			appEnable = luci.http.formvalue("appEnable1_2")

			if appEnable ~= "1" then
				appEnable = "0"
			end

			uci:set("qos","app_policy_1","prio",appPrio)
		elseif edit_AdvSet == "2" then
			section = "2"
			edit_AdvSets = "app_policy_2"
			appPrio = luci.http.formvalue("appPrio1")
			appEnable = luci.http.formvalue("appEnable1_3")

			if appEnable ~= "1" then
				appEnable = "0"
			end

			uci:set("qos","app_policy_2","prio",appPrio)
		elseif edit_AdvSet == "3" then
			section = "3"
			edit_AdvSets = "app_policy_3"
			appPrio = luci.http.formvalue("appPrio1")
			appEnable = luci.http.formvalue("appEnable1_4")

			if appEnable ~= "1" then
				appEnable = "0"
			end

			uci:set("qos","app_policy_3","prio",appPrio)
		elseif edit_AdvSet == "4" then
			section = "4"
			appPrio = luci.http.formvalue("appPrio2")
			edit_AdvSets = "app_policy_4"
			appEnable = luci.http.formvalue("appEnable2")

			if appEnable ~= "1" then
				appEnable = "0"
			end

			uci:set("qos","app_policy_4","prio",appPrio)
		elseif edit_AdvSet == "5" then
			section = "5"
			edit_AdvSets = "app_policy_5"
			appPrio = luci.http.formvalue("appPrio3")
			appEnable = luci.http.formvalue("appEnable3")

			if appEnable ~= "1" then
				appEnable = "0"
			end

			uci:set("qos","app_policy_5","prio",appPrio)
		elseif edit_AdvSet == "6" then
			section = "6"
			edit_AdvSets = "app_policy_6"
			appPrio = luci.http.formvalue("appPrio4")
			appEnable = luci.http.formvalue("appEnable4")

			if appEnable ~= "1" then
				appEnable = "0"
			end

			uci:set("qos","app_policy_6","prio",appPrio)
		elseif edit_AdvSet == "7" then
			section = "7"
			edit_AdvSets = "app_policy_7"
			appPrio = luci.http.formvalue("appPrio5")
			appEnable = luci.http.formvalue("appEnable5_1")

			if appEnable ~= "1" then
				appEnable = "0"
			end

			uci:set("qos","app_policy_7","prio",appPrio)
		elseif edit_AdvSet == "8" then
			section = "8"
			edit_AdvSets = "app_policy_8"
			appPrio = luci.http.formvalue("appPrio5")
			appEnable = luci.http.formvalue("appEnable5_2")

			if appEnable ~= "1" then
				appEnable = "0"
			end

			uci:set("qos","app_policy_8","prio",appPrio)
		elseif edit_AdvSet == "9" then
			section = "9"
			edit_AdvSets = "app_policy_9"
			appPrio = luci.http.formvalue("appPrio5")
			appEnable = luci.http.formvalue("appEnable5_3")

			if appEnable ~= "1" then
				appEnable = "0"
			end

			uci:set("qos","app_policy_9","prio",appPrio)
		else
			section = "10"
			edit_AdvSets = "app_policy_10"
			appPrio = luci.http.formvalue("appPrio6")
			appEnable = luci.http.formvalue("appEnable6")

			if appEnable ~= "1" then
				appEnable = "0"
			end

			uci:set("qos","app_policy_10","prio",appPrio)
		end

		local prios
		local userCategorys
		
		for i=1,8 do
			userCategorys = uci:get("qos","eg_policy_" .. i ,"apptype")

			if userCategorys == "Game Console" then
				prios = uci:get("qos","app_policy_0" ,"prio")
				uci:set("qos","eg_policy_" .. i,"prio",prios)
			elseif userCategorys == "VoIP" then
				prios = uci:get("qos","app_policy_4" ,"prio")
				uci:set("qos","eg_policy_" .. i,"prio",prios)
			elseif userCategorys == "P2P/FTP" then
				prios = uci:get("qos","app_policy_7" ,"prio")
				uci:set("qos","eg_policy_" .. i,"prio",prios)
			elseif userCategorys == "Web Surfing" then
				prios = uci:get("qos","app_policy_6" ,"prio")
				uci:set("qos","eg_policy_" .. i,"prio",prios)
			elseif userCategorys == "Instant Messanger" then
				prios = uci:get("qos","app_policy_5" ,"prio")
				uci:set("qos","eg_policy_" .. i,"prio",prios)
			else
				prios = uci:get("qos","app_policy_10" ,"prio")
				uci:set("qos","eg_policy_" .. i,"prio",prios)
			end
		end
		
		uci:set("qos",edit_AdvSets,"enable", appEnable)
		uci:commit("qos")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		
		upstream = uci:get("qos","shaper","port_rate_eth0")
		downstream = uci:get("qos","shaper","port_rate_lan")

		if "app_policy_0" == edit_AdvSets then

			local AdvSetEnable1 = uci:get("qos",edit_AdvSets,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSets,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSets,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSets,"lan_udp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSets,"lan_udp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSets,"lan_udp_bw")

			local AdvSetEnable3 = uci:get("qos",edit_AdvSets,"wan_tcp_enable")
			local AdvSetbandwidth3 = uci:get("qos",edit_AdvSets,"wan_tcp_min")
			local AdvSetbandwidthvalue3 = uci:get("qos",edit_AdvSets,"wan_tcp_bw")

			local AdvSetEnable4 = uci:get("qos",edit_AdvSets,"wan_udp_enable")
			local AdvSetbandwidth4 = uci:get("qos",edit_AdvSets,"wan_udp_min")
			local AdvSetbandwidthvalue4 = uci:get("qos",edit_AdvSets,"wan_udp_bw")

			local LANsum = 0
			local WANsum = 0

			my_enable=uci:get("qos","app_policy_0","enable")

			my_lan_tcp_enable=uci:get("qos","app_policy_0","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_0","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_0","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_0","wan_udp_enable")

			my_lan_tcp_min=uci:get("qos","app_policy_0","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_0","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_0","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_0","wan_udp_min")

			my_lan_tcp_bw=uci:get("qos","app_policy_0","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_0","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_0","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_0","wan_udp_bw")

			for i = 0, 10 do

				enable=uci:get("qos","app_policy_" .. i,"enable")

				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")

				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")

				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then

					if lan_tcp_enable == "1" then

						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end

					end

					if lan_udp_enable == "1" then

						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end

					end

					if wan_tcp_enable == "1" then

						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end

					end

					if wan_udp_enable == "1" then

						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end

					end

				end

			end

			for i = 1, 8 do

				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")

				if	enable == "1" then

					if intf == "wan" then

						if reserve == "2" then
							WANsum = WANsum + value
						end

					else

						if reserve == "2" then
							LANsum = LANsum + value
						end

					end

				end

			end

			if my_enable == "1" then

				if my_lan_tcp_enable == "1" then

					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end

				end

				if my_lan_udp_enable == "1" then

					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end

				end

				if my_wan_tcp_enable == "1" then

					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end

				end

				if my_wan_udp_enable == "1" then

					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end

				end

			end

			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
				AdvSet_enable3 = AdvSetEnable3,
				AdvSet_bandwidth3 = AdvSetbandwidth3,
				AdvSet_bandwidthvalue3 = AdvSetbandwidthvalue3,
				AdvSet_enable4 = AdvSetEnable4,
				AdvSet_bandwidth4 = AdvSetbandwidth4,
				AdvSet_bandwidthvalue4 = AdvSetbandwidthvalue4
			})

		elseif "app_policy_1" == edit_AdvSets then

			local AdvSetEnable1 = uci:get("qos",edit_AdvSets,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSets,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSets,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSets,"lan_udp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSets,"lan_udp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSets,"lan_udp_bw")

			local AdvSetEnable3 = uci:get("qos",edit_AdvSets,"wan_tcp_enable")
			local AdvSetbandwidth3 = uci:get("qos",edit_AdvSets,"wan_tcp_min")
			local AdvSetbandwidthvalue3 = uci:get("qos",edit_AdvSets,"wan_tcp_bw")

			local AdvSetEnable4 = uci:get("qos",edit_AdvSets,"wan_udp_enable")
			local AdvSetbandwidth4 = uci:get("qos",edit_AdvSets,"wan_udp_min")
			local AdvSetbandwidthvalue4 = uci:get("qos",edit_AdvSets,"wan_udp_bw")

			local LANsum = 0
			local WANsum = 0

			my_enable=uci:get("qos","app_policy_1","enable")

			my_lan_tcp_enable=uci:get("qos","app_policy_1","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_1","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_1","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_1","wan_udp_enable")

			my_lan_tcp_min=uci:get("qos","app_policy_1","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_1","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_1","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_1","wan_udp_min")

			my_lan_tcp_bw=uci:get("qos","app_policy_1","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_1","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_1","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_1","wan_udp_bw")

			for i = 0, 10 do

				enable=uci:get("qos","app_policy_" .. i,"enable")

				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")

				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")

				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then

					if lan_tcp_enable == "1" then

						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end

					end

					if lan_udp_enable == "1" then

						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end

					end

					if wan_tcp_enable == "1" then

						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end

					end

					if wan_udp_enable == "1" then

						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end

					end

				end

			end

			for i = 1, 8 do

				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")

				if	enable == "1" then

					if intf == "wan" then

						if reserve == "2" then
							WANsum = WANsum + value
						end

					else

						if reserve == "2" then
							LANsum = LANsum + value
						end

					end

				end

			end

			if my_enable == "1" then

				if my_lan_tcp_enable == "1" then

					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end

				end

				if my_lan_udp_enable == "1" then

					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end

				end

				if my_wan_tcp_enable == "1" then

					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end

				end

				if my_wan_udp_enable == "1" then

					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end

				end

			end

			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
				AdvSet_enable3 = AdvSetEnable3,
				AdvSet_bandwidth3 = AdvSetbandwidth3,
				AdvSet_bandwidthvalue3 = AdvSetbandwidthvalue3,
				AdvSet_enable4 = AdvSetEnable4,
				AdvSet_bandwidth4 = AdvSetbandwidth4,
				AdvSet_bandwidthvalue4 = AdvSetbandwidthvalue4
			})

		elseif "app_policy_2" == edit_AdvSets then

			local AdvSetEnable1 = uci:get("qos",edit_AdvSets,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSets,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSets,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSets,"lan_udp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSets,"lan_udp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSets,"lan_udp_bw")

			local AdvSetEnable3 = uci:get("qos",edit_AdvSets,"wan_tcp_enable")
			local AdvSetbandwidth3 = uci:get("qos",edit_AdvSets,"wan_tcp_min")
			local AdvSetbandwidthvalue3 = uci:get("qos",edit_AdvSets,"wan_tcp_bw")

			local AdvSetEnable4 = uci:get("qos",edit_AdvSets,"wan_udp_enable")
			local AdvSetbandwidth4 = uci:get("qos",edit_AdvSets,"wan_udp_min")
			local AdvSetbandwidthvalue4 = uci:get("qos",edit_AdvSets,"wan_udp_bw")

			local LANsum = 0
			local WANsum = 0

			my_enable=uci:get("qos","app_policy_2","enable")

			my_lan_tcp_enable=uci:get("qos","app_policy_2","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_2","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_2","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_2","wan_udp_enable")

			my_lan_tcp_min=uci:get("qos","app_policy_2","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_2","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_2","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_2","wan_udp_min")

			my_lan_tcp_bw=uci:get("qos","app_policy_2","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_2","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_2","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_2","wan_udp_bw")

			for i = 0, 10 do

				enable=uci:get("qos","app_policy_" .. i,"enable")

				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")

				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")

				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then

					if lan_tcp_enable == "1" then

						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end

					end

					if lan_udp_enable == "1" then

						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end

					end

					if wan_tcp_enable == "1" then

						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end

					end

					if wan_udp_enable == "1" then

						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end

					end

				end

			end

			for i = 1, 8 do

				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")

				if	enable == "1" then

					if intf == "wan" then

						if reserve == "2" then
							WANsum = WANsum + value
						end

					else

						if reserve == "2" then
							LANsum = LANsum + value
						end

					end

				end

			end

			if my_enable == "1" then

				if my_lan_tcp_enable == "1" then

					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end

				end

				if my_lan_udp_enable == "1" then

					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end

				end

				if my_wan_tcp_enable == "1" then

					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end

				end

				if my_wan_udp_enable == "1" then

					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end

				end

			end

			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
				AdvSet_enable3 = AdvSetEnable3,
				AdvSet_bandwidth3 = AdvSetbandwidth3,
				AdvSet_bandwidthvalue3 = AdvSetbandwidthvalue3,
				AdvSet_enable4 = AdvSetEnable4,
				AdvSet_bandwidth4 = AdvSetbandwidth4,
				AdvSet_bandwidthvalue4 = AdvSetbandwidthvalue4
			})

		elseif "app_policy_3" == edit_AdvSets then

			local AdvSetEnable1 = uci:get("qos",edit_AdvSets,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSets,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSets,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSets,"wan_tcp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSets,"wan_tcp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSets,"wan_tcp_bw")

			local LANsum = 0
			local WANsum = 0

			my_enable=uci:get("qos","app_policy_3","enable")

			my_lan_tcp_enable=uci:get("qos","app_policy_3","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_3","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_3","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_3","wan_udp_enable")

			my_lan_tcp_min=uci:get("qos","app_policy_3","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_3","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_3","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_3","wan_udp_min")

			my_lan_tcp_bw=uci:get("qos","app_policy_3","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_3","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_3","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_3","wan_udp_bw")

			for i = 0, 10 do

				enable=uci:get("qos","app_policy_" .. i,"enable")

				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")

				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")

				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then

					if lan_tcp_enable == "1" then

						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end

					end

					if lan_udp_enable == "1" then

						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end

					end

					if wan_tcp_enable == "1" then

						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end

					end

					if wan_udp_enable == "1" then

						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end

					end

				end

			end

			for i = 1, 8 do

				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")

				if	enable == "1" then

					if intf == "wan" then

						if reserve == "2" then
							WANsum = WANsum + value
						end

					else

						if reserve == "2" then
							LANsum = LANsum + value
						end

					end

				end

			end

			if my_enable == "1" then

				if my_lan_tcp_enable == "1" then

					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end

				end

				if my_lan_udp_enable == "1" then

					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end

				end

				if my_wan_tcp_enable == "1" then

					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end

				end

				if my_wan_udp_enable == "1" then

					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end

				end

			end

			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
			})

		elseif "app_policy_4" == edit_AdvSets then

			local AdvSetEnable1 = uci:get("qos",edit_AdvSets,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSets,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSets,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSets,"wan_tcp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSets,"wan_tcp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSets,"wan_tcp_bw")

			local LANsum = 0
			local WANsum = 0

			my_enable=uci:get("qos","app_policy_4","enable")

			my_lan_tcp_enable=uci:get("qos","app_policy_4","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_4","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_4","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_4","wan_udp_enable")

			my_lan_tcp_min=uci:get("qos","app_policy_4","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_4","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_4","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_4","wan_udp_min")

			my_lan_tcp_bw=uci:get("qos","app_policy_4","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_4","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_4","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_4","wan_udp_bw")

			for i = 0, 10 do
				enable=uci:get("qos","app_policy_" .. i,"enable")

				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")

				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")

				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then

					if lan_tcp_enable == "1" then

						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end

					end

					if lan_udp_enable == "1" then

						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end

					end

					if wan_tcp_enable == "1" then

						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end

					end

					if wan_udp_enable == "1" then

						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end

					end

				end

			end

			for i = 1, 8 do
				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")

				if	enable == "1" then

					if intf == "wan" then

						if reserve == "2" then
							WANsum = WANsum + value
						end

					else

						if reserve == "2" then
							LANsum = LANsum + value
						end

					end

				end

			end

			if my_enable == "1" then

				if my_lan_tcp_enable == "1" then

					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end

				end

				if my_lan_udp_enable == "1" then

					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end

				end

				if my_wan_tcp_enable == "1" then

					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end

				end

				if my_wan_udp_enable == "1" then

					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end

				end

			end

			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
			})

		elseif "app_policy_5" == edit_AdvSets then
			local AdvSetEnable1 = uci:get("qos",edit_AdvSets,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSets,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSets,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSets,"wan_tcp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSets,"wan_tcp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSets,"wan_tcp_bw")

			local LANsum = 0
			local WANsum = 0

			my_enable=uci:get("qos","app_policy_5","enable")

			my_lan_tcp_enable=uci:get("qos","app_policy_5","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_5","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_5","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_5","wan_udp_enable")

			my_lan_tcp_min=uci:get("qos","app_policy_5","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_5","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_5","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_5","wan_udp_min")

			my_lan_tcp_bw=uci:get("qos","app_policy_5","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_5","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_5","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_5","wan_udp_bw")

			for i = 0, 10 do
				enable=uci:get("qos","app_policy_" .. i,"enable")

				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")

				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")

				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then

					if lan_tcp_enable == "1" then

						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end

					end

					if lan_udp_enable == "1" then

						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end

					end

					if wan_tcp_enable == "1" then

						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end

					end

					if wan_udp_enable == "1" then

						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end

					end

				end

			end

			for i = 1, 8 do
				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")

				if	enable == "1" then

					if intf == "wan" then

						if reserve == "2" then
							WANsum = WANsum + value
						end

					else

						if reserve == "2" then
							LANsum = LANsum + value
						end

					end

				end

			end

			if my_enable == "1" then

				if my_lan_tcp_enable == "1" then

					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end

				end

				if my_lan_udp_enable == "1" then

					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end

				end

				if my_wan_tcp_enable == "1" then

					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end

				end

				if my_wan_udp_enable == "1" then

					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end

				end

			end

			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
			})

		elseif "app_policy_6" == edit_AdvSets then
			local AdvSetEnable1 = uci:get("qos",edit_AdvSets,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSets,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSets,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSets,"wan_tcp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSets,"wan_tcp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSets,"wan_tcp_bw")

			local LANsum = 0
			local WANsum = 0

			my_enable=uci:get("qos","app_policy_6","enable")

			my_lan_tcp_enable=uci:get("qos","app_policy_6","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_6","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_6","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_6","wan_udp_enable")

			my_lan_tcp_min=uci:get("qos","app_policy_6","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_6","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_6","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_6","wan_udp_min")

			my_lan_tcp_bw=uci:get("qos","app_policy_6","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_6","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_6","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_6","wan_udp_bw")

			for i = 0, 10 do
				enable=uci:get("qos","app_policy_" .. i,"enable")

				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")

				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")

				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then

					if lan_tcp_enable == "1" then

						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end

					end

					if lan_udp_enable == "1" then

						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end

					end

					if wan_tcp_enable == "1" then

						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end

					end

					if wan_udp_enable == "1" then

						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end

					end

				end

			end

			for i = 1, 8 do
				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")

				if	enable == "1" then

					if intf == "wan" then

						if reserve == "2" then
							WANsum = WANsum + value
						end

					else

						if reserve == "2" then
							LANsum = LANsum + value
						end

					end

				end

			end

			if my_enable == "1" then

				if my_lan_tcp_enable == "1" then

					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end

				end

				if my_lan_udp_enable == "1" then

					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end

				end

				if my_wan_tcp_enable == "1" then

					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end

				end

				if my_wan_udp_enable == "1" then

					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end

				end

			end

			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
			})

		elseif "app_policy_7" == edit_AdvSets then
			local AdvSetEnable1 = uci:get("qos",edit_AdvSets,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSets,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSets,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSets,"wan_tcp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSets,"wan_tcp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSets,"wan_tcp_bw")

			local LANsum = 0
			local WANsum = 0

			my_enable=uci:get("qos","app_policy_7","enable")

			my_lan_tcp_enable=uci:get("qos","app_policy_7","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_7","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_7","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_7","wan_udp_enable")

			my_lan_tcp_min=uci:get("qos","app_policy_7","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_7","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_7","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_7","wan_udp_min")

			my_lan_tcp_bw=uci:get("qos","app_policy_7","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_7","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_7","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_7","wan_udp_bw")

			for i = 0, 10 do
				enable=uci:get("qos","app_policy_" .. i,"enable")

				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")

				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")

				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then

					if lan_tcp_enable == "1" then

						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end

					end

					if lan_udp_enable == "1" then

						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end

					end

					if wan_tcp_enable == "1" then

						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end

					end

					if wan_udp_enable == "1" then

						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end

					end

				end

			end

			for i = 1, 8 do
				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")

				if	enable == "1" then

					if intf == "wan" then

						if reserve == "2" then
							WANsum = WANsum + value
						end

					else

						if reserve == "2" then
							LANsum = LANsum + value
						end

					end

				end

			end

			if my_enable == "1" then

				if my_lan_tcp_enable == "1" then

					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end

				end

				if my_lan_udp_enable == "1" then

					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end

				end

				if my_wan_tcp_enable == "1" then

					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end

				end

				if my_wan_udp_enable == "1" then

					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end

				end

			end

			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
			})

		elseif "app_policy_8" == edit_AdvSets then
			local AdvSetEnable1 = uci:get("qos",edit_AdvSets,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSets,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSets,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSets,"wan_tcp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSets,"wan_tcp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSets,"wan_tcp_bw")

			local LANsum = 0
			local WANsum = 0

			my_enable=uci:get("qos","app_policy_0","enable")

			my_lan_tcp_enable=uci:get("qos","app_policy_8","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_8","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_8","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_8","wan_udp_enable")

			my_lan_tcp_min=uci:get("qos","app_policy_8","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_8","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_8","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_8","wan_udp_min")

			my_lan_tcp_bw=uci:get("qos","app_policy_8","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_8","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_8","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_8","wan_udp_bw")

			for i = 0, 10 do
				enable=uci:get("qos","app_policy_" .. i,"enable")

				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")

				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")

				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then

					if lan_tcp_enable == "1" then

						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end

					end

					if lan_udp_enable == "1" then

						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end

					end

					if wan_tcp_enable == "1" then

						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end

					end

					if wan_udp_enable == "1" then

						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end

					end

				end

			end

			for i = 1, 8 do
				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")

				if	enable == "1" then

					if intf == "wan" then

						if reserve == "2" then
							WANsum = WANsum + value
						end

					else

						if reserve == "2" then
							LANsum = LANsum + value
						end

					end

				end

			end

			if my_enable == "1" then

				if my_lan_tcp_enable == "1" then

					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end

				end

				if my_lan_udp_enable == "1" then

					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end

				end

				if my_wan_tcp_enable == "1" then

					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end

				end

				if my_wan_udp_enable == "1" then

					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end

				end

			end

			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
			})

		elseif "app_policy_9" == edit_AdvSets then
			local AdvSetEnable1 = uci:get("qos",edit_AdvSets,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSets,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSets,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSets,"lan_udp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSets,"lan_udp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSets,"lan_udp_bw")

			local AdvSetEnable3 = uci:get("qos",edit_AdvSets,"wan_tcp_enable")
			local AdvSetbandwidth3 = uci:get("qos",edit_AdvSets,"wan_tcp_min")
			local AdvSetbandwidthvalue3 = uci:get("qos",edit_AdvSets,"wan_tcp_bw")

			local AdvSetEnable4 = uci:get("qos",edit_AdvSets,"wan_udp_enable")
			local AdvSetbandwidth4 = uci:get("qos",edit_AdvSets,"wan_udp_min")
			local AdvSetbandwidthvalue4 = uci:get("qos",edit_AdvSets,"wan_udp_bw")

			local LANsum = 0
			local WANsum = 0

			my_enable=uci:get("qos","app_policy_9","enable")

			my_lan_tcp_enable=uci:get("qos","app_policy_9","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_9","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_9","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_9","wan_udp_enable")

			my_lan_tcp_min=uci:get("qos","app_policy_9","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_9","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_9","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_9","wan_udp_min")

			my_lan_tcp_bw=uci:get("qos","app_policy_9","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_9","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_9","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_9","wan_udp_bw")

			for i = 0, 10 do
				enable=uci:get("qos","app_policy_" .. i,"enable")

				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")

				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")

				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then

					if lan_tcp_enable == "1" then

						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end

					end

					if lan_udp_enable == "1" then

						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end

					end

					if wan_tcp_enable == "1" then

						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end

					end

					if wan_udp_enable == "1" then

						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end

					end

				end

			end

			for i = 1, 8 do
				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")

				if	enable == "1" then

					if intf == "wan" then

						if reserve == "2" then
							WANsum = WANsum + value
						end

					else

						if reserve == "2" then
							LANsum = LANsum + value
						end

					end

				end

			end

			if my_enable == "1" then

				if my_lan_tcp_enable == "1" then

					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end

				end

				if my_lan_udp_enable == "1" then

					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end

				end

				if my_wan_tcp_enable == "1" then

					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end

				end

				if my_wan_udp_enable == "1" then

					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end

				end

			end

			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
				AdvSet_enable3 = AdvSetEnable3,
				AdvSet_bandwidth3 = AdvSetbandwidth3,
				AdvSet_bandwidthvalue3 = AdvSetbandwidthvalue3,
				AdvSet_enable4 = AdvSetEnable4,
				AdvSet_bandwidth4 = AdvSetbandwidth4,
				AdvSet_bandwidthvalue4 = AdvSetbandwidthvalue4
			})

		else
			local AdvSetEnable1 = uci:get("qos",edit_AdvSets,"lan_tcp_enable")
			local AdvSetbandwidth1 = uci:get("qos",edit_AdvSets,"lan_tcp_min")
			local AdvSetbandwidthvalue1 = uci:get("qos",edit_AdvSets,"lan_tcp_bw")

			local AdvSetEnable2 = uci:get("qos",edit_AdvSets,"wan_tcp_enable")
			local AdvSetbandwidth2 = uci:get("qos",edit_AdvSets,"wan_tcp_min")
			local AdvSetbandwidthvalue2 = uci:get("qos",edit_AdvSets,"wan_tcp_bw")

			local LANsum = 0
			local WANsum = 0

			my_enable=uci:get("qos","app_policy_10","enable")

			my_lan_tcp_enable=uci:get("qos","app_policy_10","lan_tcp_enable")
			my_lan_udp_enable=uci:get("qos","app_policy_10","lan_udp_enable")
			my_wan_tcp_enable=uci:get("qos","app_policy_10","wan_tcp_enable")
			my_wan_udp_enable=uci:get("qos","app_policy_10","wan_udp_enable")

			my_lan_tcp_min=uci:get("qos","app_policy_10","lan_tcp_min")
			my_lan_udp_min=uci:get("qos","app_policy_10","lan_udp_min")
			my_wan_tcp_min=uci:get("qos","app_policy_10","wan_tcp_min")
			my_wan_udp_min=uci:get("qos","app_policy_10","wan_udp_min")

			my_lan_tcp_bw=uci:get("qos","app_policy_10","lan_tcp_bw")
			my_lan_udp_bw=uci:get("qos","app_policy_10","lan_udp_bw")
			my_wan_tcp_bw=uci:get("qos","app_policy_10","wan_tcp_bw")
			my_wan_udp_bw=uci:get("qos","app_policy_10","wan_udp_bw")

			for i = 0, 10 do
				enable=uci:get("qos","app_policy_" .. i,"enable")

				lan_tcp_enable=uci:get("qos","app_policy_" .. i,"lan_tcp_enable")
				lan_udp_enable=uci:get("qos","app_policy_" .. i,"lan_udp_enable")
				wan_tcp_enable=uci:get("qos","app_policy_" .. i,"wan_tcp_enable")
				wan_udp_enable=uci:get("qos","app_policy_" .. i,"wan_udp_enable")

				lan_tcp_min=uci:get("qos","app_policy_" .. i,"lan_tcp_min")
				lan_udp_min=uci:get("qos","app_policy_" .. i,"lan_udp_min")
				wan_tcp_min=uci:get("qos","app_policy_" .. i,"wan_tcp_min")
				wan_udp_min=uci:get("qos","app_policy_" .. i,"wan_udp_min")

				lan_tcp_bw=uci:get("qos","app_policy_" .. i,"lan_tcp_bw")
				lan_udp_bw=uci:get("qos","app_policy_" .. i,"lan_udp_bw")
				wan_tcp_bw=uci:get("qos","app_policy_" .. i,"wan_tcp_bw")
				wan_udp_bw=uci:get("qos","app_policy_" .. i,"wan_udp_bw")

				if enable == "1" then

					if lan_tcp_enable == "1" then

						if lan_tcp_min == "1" then
							LANsum = LANsum + lan_tcp_bw
						end

					end

					if lan_udp_enable == "1" then

						if lan_udp_min == "1" then
							LANsum = LANsum + lan_udp_bw
						end

					end

					if wan_tcp_enable == "1" then

						if wan_tcp_min == "1" then
							WANsum = WANsum + wan_tcp_bw
						end

					end

					if wan_udp_enable == "1" then

						if wan_udp_min == "1" then
							WANsum = WANsum + wan_udp_bw
						end

					end

				end

			end

			for i = 1, 8 do
				enable=uci:get("qos","eg_policy_" .. i,"enable")
				value=uci:get("qos","eg_policy_" .. i,"bw_value")
				intf=uci:get("qos","eg_policy_" .. i,"to_intf")
				reserve=uci:get("qos","eg_policy_" .. i,"reserve_bw")

				if	enable == "1" then

					if intf == "wan" then

						if reserve == "2" then
							WANsum = WANsum + value
						end

					else

						if reserve == "2" then
							LANsum = LANsum + value
						end

					end

				end

			end

			if my_enable == "1" then

				if my_lan_tcp_enable == "1" then

					if my_lan_tcp_min == "1" then
						LANsum = LANsum - my_lan_tcp_bw
					end

				end

				if my_lan_udp_enable == "1" then

					if my_lan_udp_min == "1" then
						LANsum = LANsum - my_lan_udp_bw
					end

				end

				if my_wan_tcp_enable == "1" then

					if my_wan_tcp_min == "1" then
						WANsum = WANsum - my_wan_tcp_bw
					end

				end

				if my_wan_udp_enable == "1" then

					if my_wan_udp_min == "1" then
						WANsum = WANsum - my_wan_udp_bw
					end

				end

			end

			luci.template.render("expert_configuration/qos_app_edit",{
				WAN_sum = WANsum,
				LAN_sum = LANsum,
				upstream_value = upstream,
				downstream_value = downstream,
				section_name = section,
				AdvSet_enable1 = AdvSetEnable1,
				AdvSet_bandwidth1 = AdvSetbandwidth1,
				AdvSet_bandwidthvalue1 = AdvSetbandwidthvalue1,
				AdvSet_enable2 = AdvSetEnable2,
				AdvSet_bandwidth2 = AdvSetbandwidth2,
				AdvSet_bandwidthvalue2 = AdvSetbandwidthvalue2,
			})

		end


	else
		luci.template.render("expert_configuration/qos_adv")
	end

end

function streamboost_fxbandwidth()
	apply = luci.http.formvalue("apply")

	if apply then
		local StreamboostEnable = luci.http.formvalue("StreamboostEnable")
		--local StreamboostAuto = luci.http.formvalue("StreamboostAuto")
		local StreamboostAutoUpdate = luci.http.formvalue("StreamboostAutoUpdate")

		local StreamboostUpLimit = luci.http.formvalue("StreamboostUp")
		local StreamboostDownLimit = luci.http.formvalue("StreamboostDown")

		uci:set("appflow","tccontroller","enable_streamboost",StreamboostEnable)
		--uci:set("appflow","tccontroller","enable_auto",StreamboostAuto)
		uci:set("appflow", "tccontroller", "uplimit", StreamboostUpLimit * math.pow(10, 6) / 8.0)
		uci:set("appflow", "tccontroller", "downlimit", StreamboostDownLimit * math.pow(10, 6) / 8.0)
		uci:set("appflow", "tccontroller","auto_update", StreamboostAutoUpdate)

		uci:commit("appflow")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("appflow")
	end

	local uplimit_test = uci:get("appflow", "tccontroller", "uplimit")
	local downlimit_test = uci:get("appflow", "tccontroller", "downlimit")

	luci.template.render("expert_configuration/streamboost_fxbandwidth", {uplimit = uplimit_test * 8.0 / math.pow(10, 6), downlimit = downlimit_test * 8.0 / math.pow(10, 6)})
end

function Dec2Hex(nValue)
	local string = require("string")
	if type(nValue) == "string" then
		nValue = tonumber(nValue)
	end
	nHexVal = string.format("%X", nValue);  -- %X returns uppercase hex, %x gives lowercase letters
	sHexVal = nHexVal..""
	return sHexVal
end

function action_wol()
	local wolApply = luci.http.formvalue("wol_apply")
	local wolStart = luci.http.formvalue("wol_start")
	local mac = luci.http.formvalue("host_mac")
	local tmp = sys.exec("ifconfig br-lan | awk '/Bcast/{print $3}'")
	local lanBcast = tmp:match("Bcast:(%d+.%d+.%d+.%d+)")
	if not mac then
		mac = ""
	end

	if wolApply then
		local wolWanEnable = luci.http.formvalue("wol_wan_enable")
		local wolPort = luci.http.formvalue("wol_port")

		if not wolPort then
			wolPort = 9
		end

		if not ( "0" == wolWanEnable ) then
			uci:set("wol", "main", "enabled", 1)
		else
			uci:set("wol", "main", "enabled", 0)
		end

		if string.match(wolPort, "(%d+)") then
			wolPort = string.match(wolPort, "(%d+)")
			uci:set("wol", "main", "port", wolPort)
		end

		if string.match(mac, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)") then
			mac = string.match(mac, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)")
			uci:set("wol", "wol", "mac", mac)
		end

		uci:set("wol", "main", "broadcast", lanBcast)

		-- default we save mac addrerss but don't apply wol
		uci:set("wol", "wol", "enabled", "0")
		uci:commit("wol")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("wol")
	end

	if wolStart then
		wolStart = checkInjection(wolStart)
		if wolStart ~= false then
			uci:set("wol", "wol", "enabled", wolStart)
		end

		if string.match(mac, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)") then
			mac = string.match(mac, "(%w%w:%w%w:%w%w:%w%w:%w%w:%w%w)")
			uci:set("wol", "wol", "mac", mac)
		end

		uci:set("wol", "wol", "broadcast", lanBcast)
		uci:commit("wol")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("wol")
	end

	local sqlite3 = require("lsqlite3")
	local db = sqlite3.open( "/tmp/netprobe.db" )
	local data = ""
	local DevMac = ""
	local DevName = ""

	db:busy_timeout(5000)

	for row in db:nrows("SELECT * FROM Device where [Alive]=1 OR ([Alive]=0 AND [nNotAlive] <= 2); ") do
		while true do
			if row.DevMac then
				DevMac = row.DevMac
			else
				break
			end

			if row.DevName == nil then
				if row.Manufacture == nil then
					DevName = "Unknown"
				else
					DevName = row.Manufacture
				end
			else
				DevName = row.DevName
			end

			data = string.format("%s=%s;%s", DevName, DevMac, data)
			break
		end
	end

	luci.template.render("expert_configuration/wol",{data=data})
end

function action_dlna()
	local apply = luci.http.formvalue("apply")
	local rescan = luci.http.formvalue("rescan")

	if apply then
		local enabled = luci.http.formvalue("dlnaEnable")
		local usb1Photo = luci.http.formvalue("usb1Photo")
		local usb1Music = luci.http.formvalue("usb1Music")
		local usb1Video = luci.http.formvalue("usb1Video")
		local usb2Photo = luci.http.formvalue("usb2Photo")
		local usb2Music = luci.http.formvalue("usb2Music")
		local usb2Video = luci.http.formvalue("usb2Video")

		if enabled == "1" then
			uci:set("dlna", "main", "enabled", "1")
		else
			uci:set("dlna", "main", "enabled", "0")
		end

		if not usb1Photo then usb1Photo=0 end
		if not usb1Music then usb1Music=0 end
		if not usb1Video then usb1Video=0 end
		if not usb2Photo then usb2Photo=0 end
		if not usb2Music then usb2Music=0 end
		if not usb2Video then usb2Video=0 end

		uci:set("dlna", "main", "usb1_photo", usb1Photo )
		uci:set("dlna", "main", "usb1_music", usb1Music )
		uci:set("dlna", "main", "usb1_video", usb1Video )
		uci:set("dlna", "main", "usb2_photo", usb2Photo )
		uci:set("dlna", "main", "usb2_music", usb2Music )
		uci:set("dlna", "main", "usb2_video", usb2Video )

		uci:commit("dlna")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("dlna")
	end

	if rescan then
		sys.exec("wget http://127.0.0.1:9191/rpc/rescan > /tmp/dlnarescan")
	end

	local usb_status=sys.exec("/sbin/system_status.sh get_status usb")
	luci.template.render("expert_configuration/dlna",{usb_status=usb_status})
end

function action_mail()
	local apply = luci.http.formvalue("apply")
	local add = luci.http.formvalue("add")
	sys.exec("touch /etc/config/sendmail")

	if apply then
		local server = luci.http.formvalue("MailServerAddress")
		local port = luci.http.formvalue("MailServerPort")
		local username = luci.http.formvalue("AuthenticationUsername")
		local password = luci.http.formvalue("AuthenticationPassword")
		local account = luci.http.formvalue("AccountEmailAddress")

		uci:set("sendmail", "mail_server_setup", "sendmail")
		uci:set("sendmail", "mail_server_setup", "server", server)
		uci:set("sendmail", "mail_server_setup", "port", port)
		uci:set("sendmail", "mail_server_setup", "username", username)
		uci:set("sendmail", "mail_server_setup", "password", password)
		uci:set("sendmail", "mail_server_setup", "account", account)

		uci:commit("sendmail")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("sendmail")
	end

	if add then
		local email = luci.http.formvalue("Email")

		local emails_count = uci:get("sendmail", "mail_server_setup", "emails_count")
		if not emails_count then
			emails_count = 0
		end

		emails_count = emails_count+1
		local send_to = "send_to_"..emails_count
		uci:set("sendmail", send_to, "sendmail")
		uci:set("sendmail", send_to, "email", email)
		uci:set("sendmail", "mail_server_setup", "sendmail")
		uci:set("sendmail", "mail_server_setup", "emails_count", emails_count)

		uci:save("sendmail")
		uci:commit("sendmail")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("sendmail")
	end

	luci.template.render("expert_configuration/send_mail")
end

function action_mail_edit()
	local apply = luci.http.formvalue("apply")
	local edit = luci.http.formvalue("edit")
	local remove = luci.http.formvalue("remove")

	if apply then
		local sendto = luci.http.formvalue("Sendto")
		local email = luci.http.formvalue("Email")

		uci:set("sendmail", sendto, "email", email)

		uci:commit("sendmail")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("sendmail")

		local url = luci.dispatcher.build_url("expert", "configuration", "security","ParentalControl","ParentalMonitor")
		luci.http.redirect(url)
		return
	end

	if edit then
		local sendto = edit
		local email = uci:get("sendmail", sendto, "email")
		local url = luci.dispatcher.build_url("expert", "configuration", "management", "send_mail", "mail_edit")

		luci.http.redirect(url .. "?" .. "sendto=" .. sendto .. "&email=" .. email )
		return
	end

	if remove then
		local del_sendto = remove
		local rul_num = tonumber(string.match(del_sendto,"%d+"))
		local cur_num = rul_num
		uci:delete("sendmail", del_sendto)

		local emails_count = uci:get("sendmail","mail_server_setup", "emails_count")
		local num = emails_count-cur_num

		for i=num,1,-1 do
			local rules = "send_to_"..cur_num+1
			local new_rule = "send_to_"..cur_num
			local old_data = {}
			old_data=uci:get_all("sendmail", rules)

			if old_data then
				uci:set("sendmail", new_rule, "sendmail")
				uci:tset("sendmail", new_rule, old_data)

				uci:delete("sendmail", rules)
				uci:commit("sendmail")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				cur_num =cur_num+1
			end
		end
		uci:set("sendmail", "mail_server_setup", "emails_count", emails_count-1)
		uci:commit("sendmail")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("sendmail")

		local url = luci.dispatcher.build_url("expert", "configuration", "security","ParentalControl","ParentalMonitor")
		luci.http.redirect(url)
	end


	luci.template.render("expert_configuration/send_mail_edit")
end

function action_samba()
	local product_name = uci:get("system", "main", "product_name")
	apply = luci.http.formvalue("apply")

	if apply then
		local enable = luci.http.formvalue("sambaEnable")
		local name = luci.http.formvalue("sambaName")
		local workgroup = luci.http.formvalue("sambaWorkgroup")
		local description = luci.http.formvalue("sambaDescription")
		local mode = luci.http.formvalue("mode")

		if enable == "0" then
			enable = "0"
			uci:set("samba", "general", "enable", enable)
		else
			enable = "1"
			uci:set("samba", "general", "enable", enable)
		
			name = checkInjection(name)
			if name ~= false then
				uci:set("samba", "general", "name", name)
			end

			workgroup = checkInjection(workgroup)
			if workgroup ~= false then
				uci:set("samba", "general", "workgroup", workgroup)
			end

			description = checkInjection(description)
			if description ~= false then
				uci:set("samba", "general", "description", description)
			end
		end
		
		uci:set("samba", "general", "easymode", mode)

		if mode == "0" then
			local userEnable
			local userEnable_field
			local userName
			local userName_field
			local userPasswd
			local userPasswd_field
			local usb1
			local usb1_field
			local usb2
			local usb2_field

			local check_password
			local word
			local sum

			for i=1,5 do
				userEnable_field="userEnable"..i
				userEnable = luci.http.formvalue(userEnable_field)
				if not (userEnable)then
				userEnable = "0"
				else
				userEnable = "1"
				end

				userName_field="userName"..i
				userName = luci.http.formvalue(userName_field)
				userPasswd_field="userPasswd"..i
				userPasswd = luci.http.formvalue(userPasswd_field)

				check_password = uci:get("samba","user" .. i,"sum")
				if not( check_password == nil ) then
					if ( check_password == userPasswd ) then
						userPasswd = uci:get("samba","user" .. i,"passwd")
					end
				end
				word = string.len( userPasswd ) - 1
				sum = math.pow(10,word)

				userName = checkInjection(userName)
				userPasswd = checkInjection(userPasswd)
				if userName ~= false and userPasswd ~= false then
					usb1_field="userUSB1" .. i
					usb1 = luci.http.formvalue(usb1_field)
					if not (usb1)then
						usb1 = "0"
						uci:set("samba", "user" .. i, "usb1", usb1)
					else
						uci:set("samba", "user" .. i, "usb1", usb1)
					end

					usb2_field="userUSB2" .. i
					usb2 = luci.http.formvalue(usb2_field)
					if not (usb2)then
						usb2 = "0"
						uci:set("samba", "user" .. i, "usb2", usb2)
					else
						uci:set("samba", "user" .. i, "usb2", usb2)
					end

					uci:set("samba", "user" .. i, "enable", userEnable)
					uci:set("samba", "user" .. i, "name", userName)
					uci:set("samba", "user" .. i, "passwd", userPasswd)
					if ( word > -1 ) then
						uci:set("samba", "user" .. i, "sum", sum)
					else
						uci:set("samba", "user" .. i, "sum", "")
					end
				end
			end
		end

		uci:commit("samba")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		sys.exec("echo samba > /tmp/USB_app_control")
		uci:apply("samba")
	end

	local usb_status=sys.exec("/sbin/system_status.sh get_status usb")
	luci.template.render("expert_configuration/samba",{usb_status=usb_status})
end


function action_ftp()
	apply = luci.http.formvalue("apply")

	if apply then

		local enabled = luci.http.formvalue("ftpEnable")
		if enabled == "0" then
			enabled = "0"
		else
			enabled = "1"
		end

		local httpPort = luci.http.formvalue("httpPort")
		local max_connection = luci.http.formvalue("max_connection")
		local interface = luci.http.formvalue("interface")

		--add ftp start--------------------------------

		uci:set("proftpd", "global", "enable", enabled)
		uci:set("proftpd", "global", "port", httpPort)
		uci:set("proftpd", "global", "max_connection", max_connection)
		uci:set("proftpd", "global", "interface", interface)

		local userEnable
		local userEnable_field
		local userName
		local userName_field
		local userPasswd
		local userPasswd_field
		local usb1
		local usb1_field
		local usb2
		local usb2_field
		local upValue
		local upValue_field
		local downValue
		local downValue_field

		local check_password
		local word
		local sum

		for i=1,5 do
			userEnable_field="userEnable"..i
			userEnable = luci.http.formvalue(userEnable_field)
			if not (userEnable)then
			userEnable = "0"
			else
			userEnable = "1"
			end

			userName_field="userName"..i
			userName = luci.http.formvalue(userName_field)
			userPasswd_field="userPasswd"..i
			userPasswd = luci.http.formvalue(userPasswd_field)
			usb1_field="usb1_types"..i
			usb1 = luci.http.formvalue(usb1_field)
			usb2_field="usb2_types"..i
			usb2 = luci.http.formvalue(usb2_field)
			upValue_field="upValue"..i
			upValue = luci.http.formvalue(upValue_field)
			downValue_field="downValue"..i
			downValue = luci.http.formvalue(downValue_field)

			check_password = uci:get("proftpd","profile" .. i,"sum")
			if not( check_password == nil ) then
				if ( check_password == userPasswd ) then
					userPasswd = uci:get("proftpd","profile" .. i,"password")
				end
			end

			word = string.len( userPasswd ) - 1
			sum = math.pow(10,word)

			uci:set("proftpd","profile" .. i,"enable", userEnable)
			uci:set("proftpd","profile" .. i,"name",userName)
			uci:set("proftpd","profile" .. i,"password",userPasswd)

			if ( word > -1 ) then
				uci:set("proftpd","profile" .. i,"sum",sum)
			else
				uci:set("proftpd","profile" .. i,"sum","")
			end

			uci:set("proftpd","profile" .. i,"usb1_rw",usb1)
			uci:set("proftpd","profile" .. i,"usb2_rw",usb2)
			uci:set("proftpd","profile" .. i,"uplo_speed",upValue)
			uci:set("proftpd","profile" .. i,"downlo_speed",downValue)
		end

		uci:commit("proftpd")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		sys.exec("echo proftpd > /tmp/USB_app_control")
		uci:apply("proftpd")
		--uci:apply("qos")

	end

	local usb_status=sys.exec("/sbin/system_status.sh get_status usb")
	luci.template.render("expert_configuration/ftp",{usb_status=usb_status})
end

function action_oneconnect()
	local apply = luci.http.formvalue("apply")

	if apply then
		local enabled = luci.http.formvalue("OneState")
		local old_enabled = uci:get("wireless", "ath0", "AP_autoconfig")
		local system_mode = uci:get("system", "main", "system_mode")

		if old_enabled ~= enabled then
			if "1" == enabled then
				if system_mode == "1" then
					sys.exec("/usr/sbin/zy1905App 4 0 3 3")
				else
					sys.exec("/usr/sbin/zy1905App 4 1 3 3")
				end
				uci:set("wireless", "ath0", "AP_autoconfig", "1")
				uci:set("wireless", "ath10", "AP_autoconfig", "1")
			else
				if system_mode == "1" then
					sys.exec("/usr/sbin/zy1905App 4 0 0 0")
				else
					sys.exec("/usr/sbin/zy1905App 4 1 0 0")
				end
				uci:set("wireless", "ath0", "AP_autoconfig", "0")
				uci:set("wireless", "ath10", "AP_autoconfig", "0")
			end
		end

		uci:commit("wireless")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
	end

	luci.template.render("expert_configuration/oneconnect")
end
function checkInjection(str)

        if nil ~= string.match(str,"'") then
			return false
        end

        if nil ~= string.match(str,"-") then
			return false
        end

        if nil ~= string.match(str,"<") then
			return false
        end

        if nil ~= string.match(str,">") then
			return false
        end

        return str
end

-- check enable value from GUI, only can input 0 or 1
function checkEnable(str)
	if str == "0" then
		return str
	elseif str == "1" then
		return str
	else
		return false
	end
end
