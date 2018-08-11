--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: index.lua 4040 2009-01-16 12:35:25Z Cyrus $
]]--
module("luci.controller.expert.status", package.seeall)
local uci = require("luci.model.uci").cursor()
local sys = require("luci.sys")

function index()
	
	local root = node()
	if not root.target then
		root.target = alias("expert")
		root.index = true
	end
	
	local page   = node("expert")
	page.target  = alias("expert", "status")
	page.title   = "Expert Mode"
	page.sysauth = "root"
	page.sysauth_authenticator = "htmlauth"
	page.order   = 10
	page.index	 = true
	
	local page   = node("expert", "status")
        page.target = call("action_status")
	page.title   = "Status"
	page.ignoreindex = true
	page.order   = 10

	local page  = node("expert", "status", "menu_status")
	page.target = call("action_menu_status")
	page.title  = "Status"
	page.order  = 20        

	local page  = node("expert", "status", "system_status")
	page.target = call("action_dashboard")
	page.title  = "Status"
	page.order  = 30        
	

	entry({"expert", "top"}, call("action_top"))
	entry({"expert", "under"}, template("under"))
	entry({"expert", "path"}, template("path"))
	
	entry({"expert", "leftmonitor"}, template("leftmonitor"))
	entry({"expert", "leftconfig"}, template("leftconfig"))
	entry({"expert", "leftmaintenance"}, template("leftmaintenance"))
end

function action_top()

		local fw_ver
		if io.open( "/tmp/firmware_version", "r" ) then
			file3 = io.open( "/tmp/firmware_version", "r" )
			fw_ver = file3:read("*line")
			file3:close()
		else
			fw_ver = "TEST_FW_VERSION"
		end	
		
        luci.template.render("top",{fw_ver = fw_ver})
end


function action_status()

        luci.template.render("expert_configuration/status")
end

function action_menu_status()

        local streamboost_status=sys.exec("/sbin/system_status.sh get_status streamboost")
		luci.template.render("expert_configuration/menu_status",{streamboost_status=streamboost_status})
end

function action_dashboard()

	local refreshInteval  = luci.http.formvalue("refreshInteval")
	
	if refreshInteval then
		local file2 = io.open( "/tmp/refresh", "w" )
        	file2:write(refreshInteval)
        	file2:close()
        	local url = luci.dispatcher.build_url("expert","status","system_status")
        	luci.http.redirect(url)
        	return
   	end

	local file3
	local fw_ver
	if io.open( "/tmp/firmware_version", "r" ) then
		file3 = io.open( "/tmp/firmware_version", "r" )
		fw_ver = file3:read("*line")
		file3:close()
	else
		fw_ver = "TEST_FW_VERSION"
	end

	local chk_iface = uci:get("wireless","iface","wifi5G")
	DEV24G="wifi0"
	DEV5G="wifi1"
	DEV24G_FIRSTNAME="ath0"		
	DEV5G_FIRSTNAME="ath10"

	if (chk_iface == "wifi0") then
		DEV24G="wifi1"
		DEV5G="wifi0"
		DEV24G_FIRSTNAME="ath10"		
		DEV5G_FIRSTNAME="ath0"
	end	

	local security_24G
	local security_5G
	local security24G = uci.get("wireless",DEV24G_FIRSTNAME,"encryption")
	local security5G = uci.get("wireless",DEV5G_FIRSTNAME,"encryption")
	--read WPA-PSK Compatible value
	local WPAPSKCompatible_24G = uci.get("wireless", DEV24G_FIRSTNAME, "WPAPSKCompatible")
	local WPAPSKCompatible_5G = uci.get("wireless", DEV5G_FIRSTNAME, "WPAPSKCompatible")
	--read WPA Compatible value
	local WPACompatible_24G = uci.get("wireless", DEV24G_FIRSTNAME, "WPACompatible")
	local WPACompatible_5G = uci.get("wireless", DEV5G_FIRSTNAME, "WPACompatible")


	if security24G == "WPAPSK" then
		security_24G="WPA-PSK"
	elseif security24G == "WPA2PSK" then
      -- add by darren 2012.03.07
                if WPAPSKCompatible_24G == "0" then
                        security_24G="WPA2-PSK"
                elseif WPAPSKCompatible_24G == "1" then
                        security_24G="WPA-PSK / WPA2-PSK"
                end
      --
	elseif security24G == "WEPAUTO" or security24G == "SHARED" then
		security_24G="WEP"
	elseif security24G == "OPEN" then
		security_24G="No Security"
      -- add by darren 2012.03.07
        elseif security24G == "WPA2" then
                if WPACompatible_24G == "0" then
                        security_24G=security24G
                elseif WPACompatible_24G == "1" then
                        security_24G="WPA / WPA2"
                end
      --
	else
		security_24G=security24G
	end

        if security5G == "WPAPSK" then
                security_5G="WPA-PSK"
        elseif security5G == "WPA2PSK" then
      -- add by darren 2012.03.07
                if WPAPSKCompatible_5G == "0" then
                        security_5G="WPA2-PSK"
                elseif WPAPSKCompatible_5G == "1" then
                        security_5G="WPA-PSK / WPA2-PSK"
                end
      -- 
        elseif security5G == "WEPAUTO" or security5G == "SHARED" then
                security_5G="WEP"
        elseif security5G == "OPEN" then
                security_5G="No Security"
      -- add by darren 2012.03.07
	elseif security5G == "WPA2" then
		if WPACompatible_5G == "0" then
			security_5G=security5G
		elseif WPACompatible_5G == "1" then
			security_5G="WPA / WPA2"
		end
      --
	else
                security_5G=security5G
        end

	local mode_24G
	local mode_5G
	local bitRate_24G
	local bitRate_5G
	local width_24G
	local width_5G

	mode_24G = uci.get("wireless", DEV24G, "hwmode")
	mode_5G = uci.get("wireless", DEV5G, "hwmode")
	width_24G = uci.get("wireless", DEV24G_FIRSTNAME, "channel_width")
	width_5G = uci.get("wireless", DEV5G_FIRSTNAME, "channel_width")

	if mode_24G == "11b" then
		bitRate_24G = "11M"
	elseif  mode_24G == "11g" or mode_24G == "11bg" then
		bitRate_24G = "54M"
	else
		if width_24G == "20" then
			bitRate_24G = "216.7M"
		else
			bitRate_24G = "450M"
		end
	end

        if mode_5G == "11a" then
                bitRate_5G = "54M"
        else
                if width_5G == "20" then
                        bitRate_5G = "216.7M"
                else
                        bitRate_5G = "450M"
                end
        end

	--IPv6
	local v6_proto = uci:get("network","wan","v6_proto")
	local wan_ipv6_iface
	local wan_ipv6_addr=""
	local lan_ipv6_addr=""
	local wan6rd_ipv6_addr=""
	local wan6rd_border_router_ip=""
	
	if v6_proto == "pppoe" or v6_proto == "dhcp" or v6_proto == "static" then
		--wan_ipv6_iface = sys.exec("ifconfig tun")
                wan_ipv6_iface = sys.exec("ifconfig pppoe-wan")
		if wan_ipv6_iface ~= "" then
			wan_ipv6_addr = sys.exec("ifconfig pppoe-wan | awk '/Global/{print $3}'")
		else
			wan_ipv6_iface = sys.exec("ifconfig eth0")
			if wan_ipv6_iface ~= "" then
				wan_ipv6_addr = sys.exec("ifconfig eth0 | awk '/Global/{print $3}'")
			end
		end

		lan_ipv6_addr = sys.exec("ifconfig br-lan | awk '/Global/{print $3}'")
		wan6rd_ipv6_addr = sys.exec("ifconfig 6rd-wan6rd | awk '/Global/{print $3}' | sed 's/\\\/.*$/\\\/64/g'")
		--wan6rd_border_router_ip = sys.exec("ifconfig 6rd-wan6rd | awk '/Compat/{print $3}'")
		wan6rd_border_router_ip = uci:get("network","wan6rd","peeraddr")

		-- if wan6rd_border_router_ip then
			-- wan6rd_border_router_ip = wan6rd_border_router_ip:match("::(%d+.%d+.%d+.%d+)/%d+")
			-- if wan6rd_border_router_ip then
			-- else
				-- sys.exec("echo 'have NO border_router_ip' >> /tmp/6rderrlog")
			-- end
		-- else
			-- sys.exec("echo 'have NO Compat' >> /tmp/6rderrlog")
		-- end
		if not wan6rd_border_router_ip then
			sys.exec("echo 'have NO border_router_ip' >> /tmp/6rderrlog")
		end
	end

	wan6to4_ipv6_addr = sys.exec("ifconfig 6to4-wan6to4 | awk '/Global/{print $3}'")
	wan6in4_ipv6_addr = sys.exec("ifconfig 6in4-wan6in4 | awk '/Global/{print $3}'")
	linkLocalEnable = uci:get("network","general","linkLocalOnly")	
	if linkLocalEnable == "1" then
		wan_ipv6_addr_linklocal = sys.exec("ifconfig eth0 | awk '/Scope:Link/{print $3}'")
		lan_ipv6_addr_linklocal = sys.exec("ifconfig br-lan | awk '/Scope:Link/{print $3}'")
	end

	if wan_ipv6_addr == "" then
		if wan6to4_ipv6_addr ~= "" then
			wan_ipv6_addr = wan6to4_ipv6_addr
		elseif wan6in4_ipv6_addr ~= "" then
			wan_ipv6_addr = wan6in4_ipv6_addr
		elseif linkLocalEnable == "1" then
			wan_ipv6_addr = wan_ipv6_addr_linklocal
			lan_ipv6_addr = lan_ipv6_addr_linklocal
		end	
	end

 	luci.template.render("expert_status/dashboard",{firmware_version = fw_ver,
							security_24g = security_24G,
							security_5g = security_5G,
							rate24G = bitRate_24G,
							rate5G = bitRate_5G,
							wan_addr_v6 = wan_ipv6_addr,
							lan_addr_v6 = lan_ipv6_addr,
							wan6rd_addr_v6 = wan6rd_ipv6_addr,
							border_router_ip = wan6rd_border_router_ip})

end
