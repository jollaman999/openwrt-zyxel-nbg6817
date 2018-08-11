--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: index.lua 4040 2009-01-16 12:35:25Z Cyrus $
]]--
module("luci.controller.easy.easy", package.seeall)
local sys = require("luci.sys")
local uci = require("luci.model.uci").cursor()

function index()
	
	local root = node()
	if not root.lock then
		root.target = alias("easy")
		root.index = true
	end
	
	local page   = node("easy")
	page.target  = alias("easy", "networkmap")
	page.title   = "Easy Mode"
	page.sysauth = "root"
	page.sysauth_authenticator = "htmlauth"
	page.order   = 10
	page.index = true

	local page   = node("easy", "chkLang")
	page.target  = call("action_chkLang")
	page.title   = "Check Language"
	page.order   = 101

	local page   = node("easy", "passWarning")
	page.target  = call("action_chgPwd")
	page.title   = "Change Password"
	page.order   = 11
	
	local page   = node("easy", "agreement")
	page.target  = call("action_agreement")
	page.title   = "Agreement"
	page.order   = 12
	
	local page   = node("easy", "passWarning", "easy_streamboost_fxnode")
	page.target  = template("easy_streamboost_fxnode")
	page.title   = "Streamboost node"
	page.order   = 12
	
	local page   = node("easy", "networkmap")
	page.target  = call("action_networkmap")
	page.title   = "Network Map"
	page.order   = 13
		
	local page   = node("easy", "networkmap", "easy_streamboost_fxnode")
	page.target  = template("easy_streamboost_fxnode")
	page.title   = "Streamboost node"
	page.order   = 13	
	
	local page   = node("easy", "game")
	page.target  = template("easy_game/game")
	page.title   = "Game Engine"
	page.order   = 14
	
	local page   = node("easy", "pwsaving")
	page.target  = call("action_wifi_schedule")
	page.title   = "Power Saving"
	page.order   = 15
	
	entry({"easy", "ctfilter"}, call("action_ctfilter"), "Parental Control", 16)
	entry({"easy", "ntfilter"}, template("easy_ctfilter/parental_notification"), "Parental Notification", 16)
	entry({"easy", "ctfilter_frame"}, template("easy_ctfilter/parental_control_frame"), "Parental Control", 161)
	entry({"easy", "internet"}, call("action_internet"), "Internet Set", 17)
	entry({"easy", "firewall"}, template("easy_firewall/firewall"), "Firewall", 18)	
	entry({"easy", "gwlan"}, call("action_guest_wireless"), "Guest Wireless Security", 191)
	entry({"easy", "gwlan_frame"}, template("easy_wireless/guest_wireless_frame"), "Guest Wireless Security", 192)
	entry({"easy", "wlan"}, call("action_wireless"), "Wireless Security", 19)
	entry({"easy", "wlan_frame"}, template("easy_wireless/wifi"), "Wireless Security", 193)
	entry({"easy", "logout"}, call("action_logout"), "Log Out", 20)
	entry({"easy", "about"}, call("action_about"), "About", 21)
	
	entry({"easy", "scannetwork"}, call("action_scan_network"), "Scan Network", 21)
	entry({"easy", "easysetting"}, template("easy_set"), "Easy Setting", 22)
	entry({"easy", "easysetapply"}, call("action_easy_set_apply"), "Easy Setting", 23)

	local page   = node("easy", "eaZy123")
	page.target  = call("action_eaZy123_flag")
	page.title   = "eaZy123"
	page.order   = 24

	local page   = node("easy", "eaZy123", "genie_error1")
    page.target  = template("genie_error1")
    page.title   = "eaZy123"
    page.order   = 241

    local page   = node("easy", "eaZy123", "genie_error2")
    page.target  = template("genie_error2")
    page.title   = "eaZy123"
    page.order   = 242

	local page   = node("easy", "eaZy123", "genie2")
    page.target  = call("action_eaZy123_setting")	
	page.title   = "eaZy123"
	page.order   = 25

	local page   = node("easy", "eaZy123", "genie3")
    page.target  = call("action_eaZy123_apply_init")
    page.title   = "eaZy123"
    page.order   = 26
  
    local page   = node("easy", "eaZy123", "genie4")
    page.target  = call("action_eaZy123_internet_apply")
    page.title   = "eaZy123"
    page.order   = 27

    local page   = node("easy", "eaZy123", "genie4_error1")
    page.target  = template("genie4_error1")
    page.title   = "eaZy123"
    page.order   = 28

    local page   = node("easy", "eaZy123", "genie4_error2")
    page.target  = template("genie4_error2")
    page.title   = "eaZy123"
    page.order   = 28

    local page   = node("easy", "eaZy123", "genie4_1")
    page.target  = call("action_eaZy123_wireless_apply_init")
    page.title   = "eaZy123"
    page.order   = 29

    local page   = node("easy", "eaZy123", "genie5")
    page.target  = call("action_eaZy123_wireless_apply")
    page.title   = "eaZy123"
    page.order   = 30

    local page   = node("easy", "networkmap_devicetype")
    page.target  = call("action_devicetype")	
    page.title   = "action_devicetype"
    page.order   = 31
	
    local page   = node("easy", "networkmap_connectiontype")
    page.target  = call("action_connectiontype")	
    page.title   = "action_connectiontype"
    page.order   = 32

end

function action_logout()
	local dsp = require "luci.dispatcher"
	local sauth = require "luci.sauth"
	if dsp.context.authsession then
		sauth.kill(dsp.context.authsession)
		dsp.context.urltoken.stok = nil
	end

	luci.http.header("Set-Cookie", "sysauth=; path=" .. dsp.build_url())

	luci.http.redirect(luci.dispatcher.build_url())

end

function action_about()
	
	local newFw = io.open("/tmp/newfirmware","r")
	local fw = newFw:read("*line")
	if fw == "newfirmware" then
		fw = "1"
	else	
		fw = "0"
	end
	
	luci.template.render("easy_control/about",{newFw=fw})
end

function action_chkLang()
	local lang = luci.http.formvalue("lang")
--	sys.exec("echo -------"..lang.." > /dev/console")
	uci:set("system","main","language",lang)
	uci:commit("system")
	sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
	
	action_logout()
end

-- After login, pop the change password page. Darren, 2012/01/02 
function action_chgPwd()
        local apply = luci.http.formvalue("apply")
        local ignore = luci.http.formvalue("ignore")
		local sys_op_mode = uci:get("system","main","system_mode")
		local eaZy123 = uci:get("system","main","eaZy123")
		
        if apply then

			local new_password = luci.http.formvalue("NEWpassword")
			uci:set("system","main","pwd",new_password)
			uci:commit("system")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			uci:apply("system")	   

			action_logout()
        elseif ignore then
			if sys_op_mode == "1" then	
				if not eaZy123 then
					
					action_eaZy123_flag();
					
				else
					action_networkmap();
				end
			else
				action_networkmap();
				
			end

        else
			luci.template.render("passWarning")
        end

end

function action_agreement()

		local agreement = uci:get("system","main","agreement")
		
		if not agreement then
		
		    uci:set("system","main","agreement","1")	
			uci:commit("system")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			uci:apply("system")
			luci.template.render("agreement")
			
		else
		
			local apply = luci.http.formvalue("apply")
			
			if apply then
			
				local StreamboostAutoUpdate = luci.http.formvalue("StreamboostAutoUpdate")
			
				uci:set("appflow", "tccontroller","auto_update", StreamboostAutoUpdate)		
			
				uci:commit("appflow")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				uci:apply("appflow")
			end
			 
			action_networkmap();
		end	
	
end

function action_networkmap()
		-- remove cache
		local file = io.open( "/tmp/firmware_version", "r" )
		local fw_ver = file:read("*line")
		file:close()
		
		
		local fd = io.open("/tmp/system_config_old")
		
			if fd then
				sys.exec("rm /tmp/easy123_chk")
				sys.exec("cp /tmp/system_config_old /etc/config/system")
--				sys.exec("cp /tmp/network_config_old /etc/config/network")
--				sys.exec("cp /tmp/wireless_config_old /etc/config/wireless")
				
				sys.exec("rm /tmp/system_config_old")
				sys.exec("rm /tmp/network_config_old")
				sys.exec("rm /tmp/wireless_config_old")
			end
			
			local sys_op_mode = uci:get("system","main","system_mode")
			if sys_op_mode == "1" then
				local agreement = uci:get("system","main","agreement")
				if not agreement then
					uci:set("system","main","agreement","1")	
					uci:commit("system")
					sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
					uci:apply("system")
				luci.template.render("agreement")
				return
				end
			end

		
		local sqlite3 = require("lsqlite3")
		local db = sqlite3.open( "/tmp/netprobe.db" )
		local SignalStrength = "" 
		local ConnType = "" 
		local HostType = "" 
		local DevName = ""
		local i = 0
		local checkfw = luci.http.formvalue("checkFw")
		local click = luci.http.formvalue("click")
		local info = luci.http.formvalue("info")
		local rname = luci.http.formvalue("rename")
		local block = luci.http.formvalue("block")
		local unblock = luci.http.formvalue("unblock")
		local page = luci.http.formvalue("page")
		local DevMac = ""
		local DevIP = ""
		local DevType = ""
		local OSType = "Unknown"
		local data = ""
		local anum
		local choiceIcon
		local choiceName 
		local blocklist = ""
		local file
		local temp
		
		-- sys.exec("ping 8.8.8.8 -c 1 | grep time > /var/connect_internet")
		
		local f = io.open("/var/connect_internet","r")
		local internet_status
		if f then
			internet_status = f:read("*line")
			f:close()
		end

		if page then
			page = (page - 1)*28
		end
			
		if checkfw then
			local newFwfile = io.open("/tmp/newfirmware","r")
			local old_timestamp = uci:get("system","main","timestamp")
			local timestamp = luci.http.formvalue("timestamp")
			local t = 0
			if old_timestamp == nil then
				old_timestamp = 0
			end
			
			t = (timestamp - old_timestamp)/1000 - 38400
			if (t > 0) or (newFwfile == nil) then
					uci:set("system","main","timestamp",timestamp)	
					uci:commit("system")
					sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			
					sys.exec("get_online_info")
					local online_file = io.open("/tmp/get_online_info", "r")
					
					if online_file then
						ret = online_file:read("*line")
						online_file:close()
					end
					
					local fw_version,fw_name,fw_release_date,fw_release_note,fw_size = nil
					if ( ret == "success" ) then
							
						local fw_info = io.open("/tmp/fw_online_info", "r")
						if fw_info then
							fw_name=fw_info:read("*line")
							fw_version=fw_info:read("*line")
							fw_release_date=fw_info:read("*line")
							fw_release_note=fw_info:read("*line")
							fw_size=fw_info:read("*line")					
						end
						fw_info:close()
					end
						

					if ( fw_ver ~= fw_version ) and (fw_version ~= nil) then
						sys.exec("echo newfirmware > /tmp/newfirmware")
					else
						sys.exec("echo nonewfirmware > /tmp/newfirmware")
					end
					
				
			end
			
			
			newFwfile = io.open("/tmp/newfirmware","r")
			local newFw = "0"
			if newFwfile then
				newFw = newFwfile:read("*line")
				if newFw == "newfirmware" then
					newFw = "1"
				else
					newFw = "0"
				end	
			end
			newFwfile:close()
			data="checkfw;"..newFw
			luci.http.write(data)
			
			return
			
		elseif rname then
			local uptable = ""
			choiceName = luci.http.protocol.urldecode(luci.http.formvalue("choiceName"))
			choiceIcon = luci.http.formvalue("choiceIcon")
			rname = rname+page 
			for row in db:nrows("SELECT * FROM Device where [Alive]=1 OR ([Alive]=0 AND [nNotAlive] <= 2) limit "..rname..",1") do
				if row.DevMac ~= "" and row.DevMac then			
					DevMac = row.DevMac
				else
					DevMac = row.ALMac
				end
			end
			
			if choiceIcon == "null" then
				sys.exec("netmap_update -m "..DevMac.." -n '"..choiceName.."' ")
			else
				if choiceIcon == "Client" then
					choiceIcon = "1"
				elseif choiceIcon == "Laptop" then
					choiceIcon = "2"
				elseif choiceIcon == "AP" then
					choiceIcon = "3"
				elseif choiceIcon == "NAS" then
					choiceIcon = "4"
				elseif choiceIcon == "Power_Line" then
					choiceIcon = "5"
				elseif choiceIcon == "Repeater" then
					choiceIcon = "6"
				elseif choiceIcon == "Smart_Phone" then
					choiceIcon = "7"
				elseif choiceIcon == "Camera" then
					choiceIcon = "8"
				elseif choiceIcon == "Tablet" then
					choiceIcon = "9"
				elseif choiceIcon == "Router" then
					choiceIcon = "10"
				elseif choiceIcon == "Watch" then
					choiceIcon = "11"
				elseif choiceIcon == "Game" then
					choiceIcon = "12"
				end
			
				sys.exec("netmap_update -m "..DevMac.." -n '"..choiceName.."' -t "..choiceIcon.." ")
				uptable = [[UPDATE Device set HostType=']] ..choiceIcon.. [[' where DevMac=']] ..DevMac.. [['or ALMac=']] ..DevMac.. [[']]
				db:exec( uptable )
	
			end
			
			uptable = [[UPDATE Device set DevName=']] ..choiceName.. [[' where DevMac=']] ..DevMac.. [['or ALMac=']] ..DevMac.. [[']]
			db:exec( uptable )
			
			luci.http.status(200,'')
			return
			
		elseif info then
			
			db = sqlite3.open( "/tmp/GUInetprobe.db" )
			info = info+page
			for row in db:nrows("SELECT * FROM Device where [Alive]=1 OR ([Alive]=0 AND [nNotAlive] <= 2) limit "..info..",1") do
				DevMac = row.DevMac
				
				if row.IP then			
					DevIP = row.IP
				else
					DevIP = "0.0.0.0"
				end
				
				if row.OSType then			
					OSType = row.OSType
				end
				
				if row.DevMac ~= "" and row.DevMac then			
					DevMac = row.DevMac
				else
					DevMac = row.ALMac
				end
			end
			data = "info;"..DevMac..";"..DevIP..";"..OSType
			
			luci.http.write(data)
			return
		
		elseif block then
			block = block+page
			db = sqlite3.open( "/tmp/GUInetprobe.db" )
			for row in db:nrows("SELECT * FROM Device where [Alive]=1 OR ([Alive]=0 AND [nNotAlive] <= 2) limit "..block..",1") do
				if row.DevMac ~= "" and row.DevMac then				
					DevMac = row.DevMac
				else
					DevMac = row.ALMac
				end
			end

			luci.http.status(200,'')
			
			local srvName="app_service"		
			local dip_address="0.0.0.0"
			local sip_address="0.0.0.0"
			
						
			-----firewall-----
			local enabled = 1		
			
			if dFromPort=="" then
				if not dToPort=="" then
					dFromPort=dToPort
				end
			end
							
			local fw_type = "in"
			local wan = 0
			local lan = 0
			local fw_time = "always"
			local target = "DROP"
					
			local rules_count = uci:get("firewall","general","rules_count")
			local NextRulePos = uci:get("firewall","general","NextRulePos")
			
			rules_count = rules_count+1
			NextRulePos = NextRulePos+3
			
			local rules = "rule"..rules_count
			local services = "service"..rules_count
			
			
			uci:set("firewall",rules,"firewall")
			uci:set("firewall",rules,"StatusEnable",enabled)
			uci:set("firewall",rules,"CurPos",rules_count)
			uci:set("firewall",rules,"type",fw_type)
			uci:set("firewall",rules,"service",services)
			uci:set("firewall",rules,"name",srvName)
			uci:set("firewall",rules,"protocol","TCP")
			uci:set("firewall",rules,"mac_address",DevMac)
			uci:set("firewall",rules,"wan",wan)
			uci:set("firewall",rules,"src_ip",sip_address)
			uci:set("firewall",rules,"local",lan)
			uci:set("firewall",rules,"dst_ip",dip_address)
			uci:set("firewall",rules,"time",fw_time)
			uci:set("firewall",rules,"target",target)
			uci:set("firewall",rules,"delete","0")

			rules_count = rules_count+1
			rules = "rule"..rules_count
			uci:set("firewall",rules,"firewall")
			uci:set("firewall",rules,"StatusEnable",enabled)
			uci:set("firewall",rules,"CurPos",rules_count)
			uci:set("firewall",rules,"type",fw_type)
			uci:set("firewall",rules,"service",services)
			uci:set("firewall",rules,"name",srvName)
			uci:set("firewall",rules,"protocol","UDP")
			uci:set("firewall",rules,"mac_address",DevMac)
			uci:set("firewall",rules,"wan",wan)
			uci:set("firewall",rules,"src_ip",sip_address)
			uci:set("firewall",rules,"local",lan)
			uci:set("firewall",rules,"dst_ip",dip_address)
			uci:set("firewall",rules,"time",fw_time)
			uci:set("firewall",rules,"target",target)
			uci:set("firewall",rules,"delete","0")

			rules_count = rules_count+1
			rules = "rule"..rules_count
			uci:set("firewall",rules,"firewall")
			uci:set("firewall",rules,"StatusEnable",enabled)
			uci:set("firewall",rules,"CurPos",rules_count)
			uci:set("firewall",rules,"type",fw_type)
			uci:set("firewall",rules,"service",services)
			uci:set("firewall",rules,"name",srvName)
			uci:set("firewall",rules,"protocol","ICMP")
			uci:set("firewall",rules,"mac_address",DevMac)
			uci:set("firewall",rules,"wan",wan)
			uci:set("firewall",rules,"src_ip",sip_address)
			uci:set("firewall",rules,"local",lan)
			uci:set("firewall",rules,"dst_ip",dip_address)
			uci:set("firewall",rules,"time",fw_time)
			uci:set("firewall",rules,"target",target)	
			uci:set("firewall",rules,"delete","0")			

			uci:set("firewall","general","rules_count",rules_count)
			uci:set("firewall","general","NextRulePos",NextRulePos)
			
			uci:commit("firewall")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			uci:apply("firewall")
			
			return
			
		elseif unblock then 
			unblock = unblock+page
			db = sqlite3.open( "/tmp/GUInetprobe.db" )
			for row in db:nrows("SELECT * FROM Device where [Alive]=1 OR ([Alive]=0 AND [nNotAlive] <= 2) limit "..unblock..",1") do
				if row.DevMac ~= "" and row.DevMac then		
					DevMac = row.DevMac
				else
					DevMac = row.ALMac
				end
			end
			
			luci.http.status(200,'')
			
			local rules_count = uci:get("firewall","general","rules_count")
			local StatusEnable, name, tmp_mac, rule_idx
			local del_rule
			
			for i=1,rules_count do						
				StatusEnable = uci:get("firewall", "rule"..i,"StatusEnable")
				name = uci:get("firewall", "rule"..i,"name")
				tmp_mac = uci:get("firewall", "rule"..i,"mac_address")
				
				if StatusEnable == "1"  then 									
					if DevMac == tmp_mac then
						
						rule_idx = i
						del_rule ="rule"..rule_idx
						uci:set("firewall",del_rule,"delete","1")
										
					end									
				end								
			end

				uci:commit("firewall")
				sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
				uci:apply("firewall")
				
			return
			
		elseif click then
			
			local rules_count = uci:get("firewall","general","rules_count")
			
			for row in db:nrows("SELECT * FROM Device where [Alive]=1 OR ([Alive]=0 AND [nNotAlive] <= 2) limit "..page..",28") do
				-- blocklist
				block = "0"
				for i=1,rules_count do						
					StatusEnable = uci:get("firewall", "rule"..i,"StatusEnable")
					name = uci:get("firewall", "rule"..i,"name")
					tmp_mac = uci:get("firewall", "rule"..i,"mac_address")
					
					if StatusEnable == "1" and name == "app_service" then 									
						if row.DevMac == tmp_mac then
							block = "1"
							break
						end									
					end								
				end
			
				
				blocklist=blocklist..block..","
				
				-- device name & connection Type
				ConnType=ConnType..row.ConnType..","
				if row.DevName == nil then
					DevName=DevName.."Unknown,"
				else
					DevName=DevName..row.DevName..","
				end
				
				i = i + 1
			end
				
			if internet_status then
				internet_status = 1
			else
				internet_status = 0
			end
			
			for rownum in db:urows("SELECT count(*) FROM Device where [Alive]=1 OR ([Alive]=0 AND [nNotAlive] <= 2); ") do
				anum = rownum
			end
			data = "click;"..i..";"..ConnType..";"..DevName..";"..internet_status..";"..anum..";"..blocklist
			luci.http.prepare_content("text/plain")
			luci.http.write(data)
			
			return
			
		else
			
			db:busy_timeout(5000)

			-- number of devices
			for rownum in db:urows("SELECT count(*) FROM Device where [Alive]=1 OR ([Alive]=0 AND [nNotAlive] <= 2); ") do
				anum = rownum
			end
			
			local rules_count = uci:get("firewall","general","rules_count")
			for row in db:nrows("SELECT * FROM Device where [Alive]=1 OR ([Alive]=0 AND [nNotAlive] <= 2) limit 0,28") do
				
				if row.HostType then
					HostType=HostType..row.HostType..","
				else
					HostType=HostType.."-1,"
				end	
				
				if row.SignalStrength then
					SignalStrength=SignalStrength..row.SignalStrength..","
				else
					SignalStrength=SignalStrength.."null,"
				end
				
				ConnType=ConnType..row.ConnType..","
				DevType=DevType..row.DevType..","
				
				-- blocklist
				block = "0"
				for i=1,rules_count do						
					StatusEnable = uci:get("firewall", "rule"..i,"StatusEnable")
					name = uci:get("firewall", "rule"..i,"name")
					tmp_mac = uci:get("firewall", "rule"..i,"mac_address")
					
					if StatusEnable == "1" and name == "app_service" then 
					
						if row.DevMac == tmp_mac or row.ALMac == tmp_mac then
						
							block = "1"
							break
						end									
					end
				end

				blocklist=blocklist..block..","
				
				-- namelist
				if row.DevName == nil then
					if row.Manufacture == nil then
						DevName=DevName.."Unknown,"
					else	
						DevName=DevName..row.Manufacture..","
					end	
				else
					DevName=DevName..row.DevName..","
				end
					
				
			end
			
			

			
	
	local led_status = luci.http.formvalue("led_status")
	local wifi_status = luci.http.formvalue("wifi_status")
	local Streamboost_status = luci.http.formvalue("Streamboost_status")
	local guestwifi_status = luci.http.formvalue("guestwifi_status")
	local parentalCtrl_status = luci.http.formvalue("parentalCtrl_status")

	
	
	if led_status then
		local LEDon = luci.http.formvalue("led_on")

		uci:set("system","led","on",LEDon)
		uci:commit("system")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("system")

		sys.exec("zyxel_led_ctrl all")
	end

	if wifi_status then
		local WiFion = luci.http.formvalue("wifi_on")

		uci:set("wireless","wifi","on",WiFion)
		uci:commit("wireless")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("wireless")

		if WiFion == "0" then
			sys.exec("/sbin/wifi down")
		end
	end
	
	if Streamboost_status then
		local Parental_Notification = luci.http.formvalue("Parental_Notification")

		uci:set("parental_monitor","general","enable",Parental_Notification)
		uci:commit("parental_monitor")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("parental_monitor")

	end

	if guestwifi_status then
		local GuestWiFion = luci.http.formvalue("guestwifi_on")

		local product_name = uci:get("system","main","product_name")
		local chk_iface = uci:get("wireless","iface","wifi5G")

		DEV24G_iface="ath3"		
		DEV5G_iface="ath13"

		if (chk_iface == "wifi0") then
			DEV24G_iface="ath13"		
			DEV5G_iface="ath3"
		end

		uci:set("wireless", "ath3","disabled",GuestWiFion)
		uci:set("wireless", "ath13","disabled",GuestWiFion)
		uci:commit("wireless")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		sys.exec("echo "..DEV24G_iface.." > /tmp/wifi24G_Apply")
		sys.exec("echo "..DEV5G_iface.." > /tmp/wifi5G_Apply")
		uci:apply("wireless")
	end

	if parentalCtrl_status then
		local ParentalCtrlon = luci.http.formvalue("parentalCtrl_on")

		uci:set("parental_ex","general","enable",ParentalCtrlon)
		uci:commit("parental_ex")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("parental_ex")
	end
	
			sys.exec("cp /tmp/netprobe.db /tmp/GUInetprobe.db")
		end
	
	if(anum>252) then
		anum=252
	end
	
	luci.template.render("networkmap",{DDevName=DevName,DevType=DevType,HostType=HostType,CConnType=ConnType,internet_status=internet_status,anum=anum,blocklist=blocklist,newFw=newFw,fw_ver=fw_ver,SignalStrength=SignalStrength})

end

function action_scan_network()
	sys.exec("lltd.sh")
	sys.exec("ping 168.95.1.1 -c 1 > /var/ping_internet")
	return 1
end

function action_easy_set_apply()
	local job = luci.http.formvalue("easy_set_button_job")
	local mode = luci.http.formvalue("easy_set_button_mode")
	
	if job and mode then
		if job == "1" then
			uci:set("qos","general","game_enable",mode)			
			uci:commit("qos")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			--uci:apply("qos")
		elseif job == "2" then
			wifi_select = uci:get("system","main","power_saving_select")
			if wifi_select == "2.4G" then
				cfg = "wifi_schedule"
			else
				cfg = "wifi_schedule5G"
			end
			if mode == "1" then
				uci:set(cfg,"wlan","enabled","enable")
			else
				uci:set(cfg,"wlan","enabled","disable")
			end
			uci:commit(cfg)
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			uci:apply(cfg)
		elseif job == "3" then
			uci:set("parental","general","enable",mode)
			uci:commit("parental")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			uci:apply("parental")
		elseif job == "4" then
			uci:set("firewall","general","dos_enable",mode)
			uci:commit("firewall")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			uci:apply("firewall")
		elseif job == "5" then			
			uci:set("appflow","tccontroller","enable_streamboost",mode)		
			if mode == "0" then
				uci:set("appflow","tccontroller","enable_streamboost",mode)
			end
			uci:commit("appflow")
			sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
			uci:apply("appflow")
		elseif job == "6" then
			uci:set("wireless","ath0","disabled",mode)
		else
			return 
		end
	end
	
	luci.template.render("networkmap")
end

function action_ctfilter()
	sys.exec("touch /tmp/parental_bonus")
	local keywords = luci.http.formvalue("url_str")
	if keywords then
		uci:set("parental_ex","keyword","keywords",keywords)
		uci:commit("parental_ex")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply("parental_ex")
	end
	
	luci.template.render("easy_ctfilter/parental_control")
end

function action_internet()
	local apply = luci.http.formvalue("apply")
	
	if apply then
	
		-- lock dns check, and it will be unlock after updating dns in update_sys_dns
		sys.exec("echo 1 > /var/update_dns_lock")
		local wan_proto = uci:get("network","wan","proto")
		sys.exec("echo "..wan_proto.." > /tmp/old_wan_proto")
	
        local connection_type = luci.http.formvalue("connectionType")                				

        if connection_type == "PPPOE" then

			local pppoeUser = luci.http.formvalue("pppoeUser")
			local pppoePass = luci.http.formvalue("pppoePass")
			local pppoeIdleTime = luci.http.formvalue("pppoeIdleTime")
			local pppoeWanIpAddr = luci.http.formvalue("pppoeWanIpAddr")
					
			if not pppoeIdleTime then
				pppoeIdleTime=""
			end
					
			if not pppoeWanIpAddr then
				pppoeWanIpAddr=""
			end					
            	uci:set("network","wan","proto","pppoe")
           		uci:set("network","wan","username",pppoeUser)
            	uci:set("network","wan","password",pppoePass)
				uci:set("network","wan","demand",pppoeIdleTime)
				uci:set("network","wan","pppoeWanIpAddr",pppoeWanIpAddr)

		elseif connection_type == "PPTP" then
		
			local pptpUser = luci.http.formvalue("pptpUser")
			local pptpPass = luci.http.formvalue("pptpPass")
			local pptp_serverIp = luci.http.formvalue("pptp_serverIp")
			local pptpWanIpAddr = luci.http.formvalue("pptpWanIpAddr")
			local pptp_config_ip = luci.http.formvalue("pptp_config_ip")
			local pptp_staticIp = luci.http.formvalue("pptp_staticIp")
			local pptp_staticNetmask = luci.http.formvalue("pptp_staticNetmask")
			local pptp_staticGateway = luci.http.formvalue("pptp_staticGateway")

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
			uci:set("network","vpn","interface")
			
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
			uci:set("network","vpn","pptp_Nailedup",pptpNailedup)
			uci:set("network","vpn","pptp_demand",pptpIdleTime)
			uci:set("network","vpn","pptp_serverip",pptp_serverIp)
			uci:set("network","vpn","pptpWanIPMode","1")
			uci:set("network","vpn","pptpWanIpAddr",pptpWanIpAddr)
			
		else			
			local WAN_IP_Auto = luci.http.formvalue("WAN_IP_Auto")
			local Fixed_staticIp = luci.http.formvalue("staticIp")
			local Fixed_staticNetmask = luci.http.formvalue("staticNetmask")
			local Fixed_staticGateway = luci.http.formvalue("staticGateway")
					
			if WAN_IP_Auto == "1" then
				uci:set("network","wan","proto","dhcp")
            else
				uci:set("network","wan","proto","static")
				uci:set("network","wan","ipaddr",Fixed_staticIp)
				uci:set("network","wan","netmask",Fixed_staticNetmask)
				uci:set("network","wan","gateway",Fixed_staticGateway)
            end
		end
			
		uci:set("network","general","config_section","wan")	
		uci:commit("network")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
        uci:apply("network")
				
	end
	
	luci.template.render("easy_internet/internet")
	
end

function action_wireless()
	require("luci.model.uci")
	local apply = luci.http.formvalue("apply")

--	local product_name = uci:get("system","main","product_name")

--	if (product_name == "NBG6817" or product_name == "NBG6617") then
		if apply then
			local wlanRadio = luci.http.formvalue("wlanRadio")
			local wlanPwd = luci.http.formvalue("wlanPwd")
			local wlanSSID = luci.http.formvalue("wlanSSID")
			local wlanSec = luci.http.formvalue("wlanSec")

			sys.exec("/bin/WiFi_GUI_ctrl easyMOD_main_wifi "..wlanRadio.." "..wlanSSID.." "..wlanPwd.." "..wlanSec)

			luci.http.redirect(
	                luci.dispatcher.build_url("easy", "networkmap")
	        )
		end

		local show_val=sys.exec("/bin/WiFi_GUI_ctrl easyMOD_main_wifi_get_val")
		local val_list=NEW_split(show_val,"<;;>")

		luci.template.render("easy_wireless/wireless_security", {
			SSID = val_list[1],
			SSID_5G = val_list[2],
			pwd = val_list[3],
			pwd_5G = val_list[4],
			security = val_list[5],
			security_5G = val_list[6],
		})
	-- else

	-- 	if apply then
	-- 		local wlanRadio = luci.http.formvalue("wlanRadio")
			
	-- 		if wlanRadio == "both" then  --both, 2.4G, 5G
	-- 			names = {'2.4G', '5G'}
	-- 			for nameCount = 1, 2 do
	--   				action_wireless_fun(names[nameCount])
	-- 			end
	-- 		else
	-- 			action_wireless_fun(wlanRadio)
	-- 		end

	-- 		luci.http.redirect(
	--                 luci.dispatcher.build_url("easy", "networkmap")
	--         )
	-- 	end
		
	-- 	luci.template.render("easy_wireless/wireless_security", {
	-- 		SSID = uci:get("wireless","ath0","ssid"),
	-- 		security = uci:get("wireless","ath0","auth"),
	-- 		pwd = uci:get("wireless","ath0","WPAPSKkey"),
	-- 		SSID_5G = uci:get("wireless","ath10","ssid"),
	-- 		security_5G = uci:get("wireless","ath10","auth"),
	-- 		pwd_5G = uci:get("wireless","ath10","WPAPSKkey")
	-- 	})
	-- end

end

function action_wireless_fun(wlanRadio)
	require("luci.model.uci")
	local wpscfg="wps"
	local config_status

	local cfg
	local section
	local wlanPwd = luci.http.formvalue("wlanPwd")
	local wlanSSID = luci.http.formvalue("wlanSSID")
	local wlanSec = luci.http.formvalue("wlanSec")
		
	if wlanRadio == "2.4G" then
		sys.exec("kill $(ps | grep 'watch -tn 1 wps_conf_24G' | grep 'grep' -v | awk '{print $1}')")
		sys.exec("echo wifi0 > /tmp/WirelessDev")
		sys.exec("echo ath0 > /tmp/wifi24G_Apply")
		cfg = "wireless"
		section = "ath0"
		wpscfg = "wps"
	elseif wlanRadio == "5G" then
		sys.exec("kill $(ps | grep 'watch -tn 5 wps_conf_5G' | grep 'grep' -v | awk '{print $1}')")
		sys.exec("echo wifi1 > /tmp/WirelessDev")
		sys.exec("echo wifi0 > /tmp/wifi5G_Apply") --5G ath10
		cfg = "wireless"
		section = "ath10"
		wpscfg = "wps5G"
	end

--	wlanSSID = checkInjection(wlanSSID)
	if wlanSSID ~= false then
		uci:set(cfg,section,"ssid",wlanSSID)
	end

	if wlanSec == "none" then
		if section == "ath0" then
			uci:set("wireless", "wifi0","auth","OPEN") 
		end
		if section == "ath10" then
			uci:set("wireless", "wifi1","auth","OPEN") 
		end
		uci:set(cfg,section,"auth","NONE")
		uci:set(cfg,section,"encryption","NONE")
	elseif wlanSec == "WPA-PSK" then
		uci:set(cfg,section,"auth","WPAPSK")
		uci:set(cfg,section,"encryption","WPAPSK")
			
		wlanPwd = checkInjection(wlanPwd)
		if wlanPwd  ~= false then
			uci:set(cfg,section,"WPAPSKkey", wlanPwd)
		end
	elseif wlanSec == "WPA2-PSK" then
		uci:set(cfg,section,"auth","WPA2PSK")
		uci:set(cfg,section,"encryption","WPA2PSK")
			
		wlanPwd = checkInjection(wlanPwd)
		if wlanPwd  ~= false then
			uci:set(cfg,section,"WPAPSKkey", wlanPwd)
		end
	end
		
	uci:commit(cfg)
	sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
	uci:apply(cfg)
		
	--Set wps conf with 1 here, the WPS status will be configured when you
	--execute "wps ath0/ath10 on"	
	uci:set(wpscfg,"wps","conf","1")
	uci:commit(wpscfg)
		
	local wps_enable = uci:get(wpscfg,"wps","enabled")

	if (wps_enable == "1") then
		sys.exec("wps "..section.." on")
	else
		sys.exec("iwpriv "..section.." set WscConfStatus=2")
	end
end


function action_guest_wireless()
	require("luci.model.uci")
	local apply = luci.http.formvalue("apply")

--	local product_name = uci:get("system","main","product_name")

--	if (product_name == "NBG6817" or product_name == "NBG6617") then
		if apply then
			local wlanRadio = luci.http.formvalue("wlanRadio")
			local wlanPwd = luci.http.formvalue("wlanPwd")
			local wlanSSID = luci.http.formvalue("wlanSSID")
			local wlanSec = luci.http.formvalue("wlanSec")

			sys.exec("/bin/WiFi_GUI_ctrl easyMOD_guest_wifi "..wlanRadio.." "..wlanSSID.." "..wlanPwd.." "..wlanSec)

			luci.http.redirect(
	                luci.dispatcher.build_url("easy", "networkmap")
	        )
		end

		local show_val=sys.exec("/bin/WiFi_GUI_ctrl easyMOD_guest_wifi_get_val")
		local val_list=NEW_split(show_val,"<;;>")

		luci.template.render("easy_wireless/guest_wireless_security", {
			SSID = val_list[1],
			SSID_5G = val_list[2],
			pwd = val_list[3],
			pwd_5G = val_list[4],
			security = val_list[5],
			security_5G = val_list[6],
		})
	-- else
	-- 	local wlanRadio = luci.http.formvalue("wlanRadio")
	-- 	local wpscfg="wps"
	-- 	local config_status
	-- 	local valid_pin="1"

	-- 	if apply then
		
	-- 		local cfg
	-- 		local section
	-- 		local wlanPwd = luci.http.formvalue("wlanPwd")
	-- 		local wlanSSID = luci.http.formvalue("wlanSSID")
	-- 		local wlanSec = luci.http.formvalue("wlanSec")

	-- 		if wlanRadio == "2.4G" then
	-- 			sys.exec("kill $(ps | grep 'watch -tn 1 wps_conf_24G' | grep 'grep' -v | awk '{print $1}')")
	-- 			sys.exec("echo wifi0 > /tmp/WirelessDev")
	-- 			sys.exec("echo ath3 > /tmp/wifi24G_Apply")
	-- 			cfg = "wireless"
	-- 			section = "ath3"
	-- 			wpscfg = "wps"
	-- 		elseif wlanRadio == "5G" then
	-- 			sys.exec("kill $(ps | grep 'watch -tn 5 wps_conf_5G' | grep 'grep' -v | awk '{print $1}')")
	-- 			sys.exec("echo wifi1 > /tmp/WirelessDev")
	-- 			sys.exec("echo ath13 > /tmp/wifi5G_Apply")
	-- 			cfg = "wireless"
	-- 			section = "ath13"
	-- 			wpscfg = "wps5G"
	-- 		end

	-- 		if wlanSSID ~= false then
	-- 			uci:set(cfg,section,"ssid",wlanSSID)
	-- 		end

	-- 		if wlanSec == "none" then
	-- 			if section == "ath3" then
	-- 				uci:set("wireless", "wifi0","auth","OPEN") 
	-- 			end
	-- 			if section == "ath13" then
	-- 				uci:set("wireless", "wifi1","auth","OPEN") 
	-- 			end
	-- 			uci:set(cfg,section,"auth","OPEN")
	-- 			uci:set(cfg,section,"encryption","NONE")
	-- 		elseif wlanSec == "WPA-PSK" then
	-- 			uci:set(cfg,section,"auth","WPAPSK")
	-- 			uci:set(cfg,section,"encryption","WPAPSK")
				
	-- 			wlanPwd = checkInjection(wlanPwd)
	-- 			if wlanPwd  ~= false then
	-- 				uci:set(cfg,section,"WPAPSKkey", wlanPwd)
	-- 			end
	-- 		elseif wlanSec == "WPA2-PSK" then
	-- 			uci:set(cfg,section,"auth","WPA2PSK")
	-- 			uci:set(cfg,section,"encryption","WPA2PSK")
				
	-- 			wlanPwd = checkInjection(wlanPwd)
	-- 			if wlanPwd  ~= false then
	-- 				uci:set(cfg,section,"WPAPSKkey", wlanPwd)
	-- 			end
	-- 		end
			
	-- 		uci:commit(cfg)
	-- 		uci:apply(cfg)
			
	-- 		--Set wps conf with 1 here, the WPS status will be configured when you
	-- 		--execute "wps ath0/ath10 on"	
	-- 		uci:set(wpscfg,"wps","conf","1")
	-- 		uci:commit(wpscfg)
			
	-- 		local wps_enable = uci:get(wpscfg,"wps","enabled")

	-- 		if (wps_enable == "1") then
	-- 			sys.exec("wps "..section.." on")
	-- 		else
	-- 			sys.exec("iwpriv "..section.." set WscConfStatus=2")
	-- 		end

	-- 		luci.http.redirect(
	--                 luci.dispatcher.build_url("easy", "networkmap")
	--         )
			
	-- 	end

	-- 	local iface
	-- 	if wlanRadio then
	-- 		if wlanRadio == "2.4G" then
	-- 			iface = "ath3"
	-- 			wpscfg = "wps"
	-- 		elseif wlanRadio == "5G" then
	-- 			iface = "ath13"
	-- 			wpscfg = "wps5G"   
	-- 		end
	-- 	end
		
	-- 	luci.template.render("easy_wireless/guest_wireless_security", {
	-- 		SSID = uci:get("wireless","ath3","ssid"),
	-- 		security = uci:get("wireless","ath3","auth"),
	-- 		pwd = uci:get("wireless","ath3","WPAPSKkey"),
	-- 		SSID_5G = uci:get("wireless","ath13","ssid"),
	-- 		security_5G = uci:get("wireless","ath13","auth"),
	-- 		pwd_5G = uci:get("wireless","ath13","WPAPSKkey"),
	-- 		AP_PIN = uci:get(wpscfg,"wps","appin"),
	-- 		pin_valid = valid_pin
	-- 	})
	-- end
end

function action_wifi_schedule()
	local cfg
	local apply = luci.http.formvalue("apply")
	local days = {"Everyday","Mon","Tue","Wed","Thu","Fri","Sat","Sun"}
	
	if apply then
		local radio = luci.http.formvalue("wlanRadio")
		
		if radio == "2.4G" then
			cfg = "wifi_schedule"
		else
			cfg = "wifi_schedule5G"
		end
		
		uci:set("system","main","power_saving_select",radio)
		uci:commit("system")
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		
		for i, name in ipairs(days) do
			local prefixStr = "WLanSch" .. tonumber(i)-1
			local token = string.lower(name:sub(1, 1)) .. name:sub(2, #name)
			
			uci:set(cfg, token, "status_onoff", luci.http.formvalue(prefixStr .. "Radio"))
			uci:set(cfg, token, "start_hour",   luci.http.formvalue(prefixStr .. "StartHour"))
			uci:set(cfg, token, "start_min",    luci.http.formvalue(prefixStr .. "StartMin"))
			uci:set(cfg, token, "end_hour",     luci.http.formvalue(prefixStr .. "EndHour"))
			uci:set(cfg, token, "end_min",      luci.http.formvalue(prefixStr .. "EndMin"))

			if "1" == luci.http.formvalue(prefixStr .. "Enabled") then
				uci:set(cfg, token, "enabled", "1")
			else
				uci:set(cfg, token, "enabled", "0")
			end
		end
		
		uci:commit(cfg)
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
		uci:apply(cfg)
	end
	
	local wifi = {}
	local wifi5G = {}
	local wlan_radio = uci:get("system","main","power_saving_select")
	
	for i,v in ipairs(days) do
		local token = string.lower( v:sub( 1, 1 ) ) .. v:sub( 2, #v )

		wifi[i] = {status=uci:get("wifi_schedule",token,"status_onoff"),
					enabled=uci:get("wifi_schedule",token,"enabled"),
					start_hour=uci:get("wifi_schedule",token,"start_hour"),
					start_min=uci:get("wifi_schedule",token,"start_min"),
					end_hour=uci:get("wifi_schedule",token,"end_hour"),
					end_min=uci:get("wifi_schedule",token,"end_min")}
		wifi5G[i] = {status=uci:get("wifi_schedule5G",token,"status_onoff"),
					enabled=uci:get("wifi_schedule5G",token,"enabled"),
					start_hour=uci:get("wifi_schedule5G",token,"start_hour"),
					start_min=uci:get("wifi_schedule5G",token,"start_min"),
					end_hour=uci:get("wifi_schedule5G",token,"end_hour"),
					end_min=uci:get("wifi_schedule5G",token,"end_min")}
	end
	
	luci.template.render("easy_pwsave/power_saving", {
		wifi_radio = wlan_radio,
		wifi_sch = wifi,
		wifi5G_sch = wifi5G
	})
end

-- Modification for eaZy123 error, NBG6816, WenHsiang, 2011/12/28
function action_eaZy123_flag()
	uci:set("system","main","eaZy123","1")		
	uci:commit("system")
	sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
	uci:apply("web-redirect")

	luci.template.render("genie")
end

function action_eaZy123_setting()
	local wanif = uci:get("network","wan","ifname")
	local proto_type = uci:get("network","wan","proto")
                                                                           
	wanInfo_cmd=luci.sys.exec("ifconfig '"..wanif.."'")                                
	wan_ip=string.match(wanInfo_cmd,"inet addr:(%d+.%d+.%d+.%d+)")                     
	if (not wan_ip and proto_type == "dhcp")then
		proto_type = "pppoe"                                                                          
	end

--	local product_name = uci:get("system","main","product_name")

--	if (product_name == "NBG6817" or product_name == "NBG6617") then

		local show_val=sys.exec("/bin/WiFi_GUI_ctrl easy123_wifi_get_val")
		local val_list=NEW_split(show_val,"<;;>")
		local pptp_status=sys.exec("/sbin/system_status.sh get_status pptp")

	    if pptp_status == "NotSupport" then
	    	luci.template.render("genie2_without_pptp", {
			proto_select = proto_type,
			SSID = val_list[1],
			pwd = val_list[2],
			SSID_5G = val_list[3],
			pwd_5G = val_list[4],
			pptp_status=pptp_status
		})
	    else
	    	luci.template.render("genie2", {
			proto_select = proto_type,
			SSID = val_list[1],
			pwd = val_list[2],
			SSID_5G = val_list[3],
			pwd_5G = val_list[4],
			pptp_status=pptp_status
		})
	    end
	-- else
	-- 	local ssid_24G = uci:get("wireless","ath0","ssid")
	-- 	local pwd_24G = uci:get("wireless","ath0","WPAPSKkey")
	-- 	local ssid_5G = uci:get("wireless","ath10","ssid")
	-- 	local pwd_5G = uci:get("wireless","ath10","WPAPSKkey")
	-- 	local def_pwd

	-- 	if (not pwd_24G or not pwd_5G) then
	--         local def_file
	-- 		def_file = io.open("/tmp/tmppsk","r")
	-- 		def_pwd = def_file:read("*line")
	-- 		def_file:close()
	-- 	end

	-- 	if not ssid_24G then
	-- 		ssid_24G=luci.sys.exec("cat /tmp/tmpSSID24G")
	-- 	end

	-- 	if not ssid_5G then
	-- 		ssid_5G=luci.sys.exec("cat /tmp/tmpSSID5G")
	-- 	end

	-- 	if not pwd_24G then
	-- 		pwd_24G = def_pwd
	-- 	end

	-- 	if not pwd_5G then
	-- 		pwd_5G = def_pwd
	-- 	end

	-- 	luci.template.render("genie2", {
	-- 		proto_select = proto_type,
	-- 		SSID = ssid_24G,
	-- 		pwd = pwd_24G,
	-- 		SSID_5G = ssid_5G,
	-- 		pwd_5G = pwd_5G
	-- 	})
	-- end
end

function action_eaZy123_apply_init()
	local f = io.open('/tmp/easy123_chk')
	if not f then  -- f == nil, file not exists
		sys.exec("echo -n > /tmp/easy123_chk")
		sys.exec("cp /etc/config/system /tmp/system_config_old")
		sys.exec("cp /etc/config/network /tmp/network_config_old")
		sys.exec("cp /etc/config/wireless /tmp/wireless_config_old")
	end

	local apply = luci.http.formvalue("apply")

	if apply then
		eaZy123_internet_setting()
		eaZy123_wireless_setting()
	end
	luci.template.render("genie3")
end

function eaZy123_internet_setting()
	-- lock dns check, and it will be unlock after updating dns in update_sys_dns
	sys.exec("echo 1 > /var/update_dns_lock")
	local wan_proto = uci:get("network","wan","proto")
	sys.exec("echo "..wan_proto.." > /tmp/old_wan_proto")

	local connection_type = luci.http.formvalue("connectionType")

	if connection_type == "pppoe" then
		local pppoeUser = luci.http.formvalue("pppoeUSER")
		local pppoePass = luci.http.formvalue("pppoePASSWORD")
		local pppoeWanIpAddr = luci.http.formvalue("pppoeIP")
		local pppoeIdleTime=""
					
		if not pppoeWanIpAddr then
			pppoeWanIpAddr=""
		end
					
		uci:set("network","wan","proto","pppoe")
		uci:set("network","wan","v6_proto","pppoe")
		uci:set("network","wan","username",pppoeUser)
		uci:set("network","wan","password",pppoePass)
		uci:set("network","wan","demand",pppoeIdleTime)
		uci:set("network","wan","pppoeWanIpAddr",pppoeWanIpAddr)
		uci:set("network","wan","wan_mac_status","0")
		uci:set("network","wan","mtu","1492")

	elseif connection_type == "pptp" then
		
		local pptpUSER = luci.http.formvalue("pptpUSER")
		local pptpPASSWORD = luci.http.formvalue("pptpPASSWORD")
		local pptpServerIP = luci.http.formvalue("pptpServerIP")
		local pptpRadio = luci.http.formvalue("pptpRadio")
					
		uci:set("network","wan","proto","pptp")
		uci:set("network","wan","v6_proto","pptp")
		uci:set("network","vpn","interface")
			
		if pptpRadio == "dhcp" then
			uci:set("network","vpn","proto","dhcp")
		else
			local pptpIP = luci.http.formvalue("pptpIP")
			local pptpSUBNET = luci.http.formvalue("pptpSUBNET")
			local pptpGATEWAY = luci.http.formvalue("pptpGATEWAY")
			uci:set("network","vpn","proto","static")
			uci:set("network","wan","ipaddr",pptpIP)
			uci:set("network","wan","netmask",pptpSUBNET)
			uci:set("network","wan","gateway",pptpGATEWAY)
		end
			
		uci:set("network","vpn","pptp_username",pptpUSER)
		uci:set("network","vpn","pptp_password",pptpPASSWORD)
		uci:set("network","vpn","pptp_Nailedup","1")
		uci:set("network","vpn","pptp_serverip",pptpServerIP)
		uci:set("network","vpn","pptpWanIPMode","1")
		uci:set("network","vpn","pptp_Encryption","Auto")
			
	elseif connection_type == "dhcp" then
		uci:set("network","wan","proto","dhcp")
		uci:set("network","wan","v6_proto","dhcp")

	elseif connection_type == "static" then
		local staticIp = luci.http.formvalue("staticIP")
		local staticNetmask = luci.http.formvalue("staticSUBNET")
		local staticGateway = luci.http.formvalue("staticGATEWAY")
		local staticDNS = luci.http.formvalue("staticDNS")

		uci:set("network","wan","proto","static")
		uci:set("network","wan","v6_proto","static")
		uci:set("network","wan","ipaddr",staticIp)
		uci:set("network","wan","netmask",staticNetmask)
		uci:set("network","wan","gateway",staticGateway)
		uci:set("network","wan","dns1","USER,"..staticDNS)
	end

	uci:set("network","wan","ipv4","1")
	uci:set("network","wan","ipv6","0")
	uci:set("network","wan","ipv6Enable","0")
	uci:set("network","wan","IP_version","IPv4_Only")
	uci:set("network","general","config_section","wan")	
	uci:commit("network")
	sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
end

function eaZy123_wireless_setting()
	sys.exec("kill $(ps | grep 'watch -tn 1 wps_conf_24G' | grep 'grep' -v | awk '{print $1}')")
	--For NBG6817 NBG6617
	sys.exec("kill $(ps | grep 'watch -tn 1 wps_conf_5G' | grep 'grep' -v | awk '{print $1}')")
	--For NBG6816 NBG6615
	sys.exec("kill $(ps | grep 'watch -tn 5 wps_conf_5G' | grep 'grep' -v | awk '{print $1}')")

	local wireless_type = luci.http.formvalue("5gedit")
	local wifiSSID = luci.http.formvalue("wifiSSID")
	local wifiPASSWORD = luci.http.formvalue("wifiPASSWORD")
	local wifiSSID5G = luci.http.formvalue("wifiSSID5G")
	local wifiPASSWORD5G = luci.http.formvalue("wifiPASSWORD5G")

	local product_name = uci:get("system","main","product_name")

	if (product_name == "NBG6817" or product_name == "NBG6617") then
		sys.exec("/bin/WiFi_GUI_ctrl easy123_wifi '"..wifiSSID.."' '"..wifiPASSWORD.."' '"..wifiSSID5G.."' '"..wifiPASSWORD5G.."'")
	else
		local cfg = "wireless"
		local section = "ath0"
		local section5g = "ath10"

		--set 2.4G
		uci:set(cfg,section,"ssid",wifiSSID)		
		uci:set(cfg,section,"WPAPSKkey",wifiPASSWORD)

		--set 5G
		uci:set(cfg,section5g,"ssid",wifiSSID5G)		
		uci:set(cfg,section5g,"WPAPSKkey",wifiPASSWORD5G)

		uci:commit(cfg)
		sys.exec("/bin/sync")  -- This command is for emmc and ext4 filesystem
	end
end

function action_eaZy123_internet_apply()
	sys.exec("rm /tmp/chk_eas123Status")
	sys.exec("echo eas123_wanSet > /tmp/chk_eas123Status")
	
	uci:apply("network")

	local wanif = "eth0"
	local wan_proto = uci:get("network","wan","proto")
	if wan_proto == "pppoe" then
		wanif = "pppoe-wan"
	else
		wanif = "eth0"
	end

	for i = 1,12 do                                                                            
		wanInfo_cmd=luci.sys.exec("ifconfig '"..wanif.."'")                                
		wan_ip=string.match(wanInfo_cmd,"inet addr:(%d+.%d+.%d+.%d+)")                     
		if wan_ip then                                                                     
			break                                                                      
		end                                                                                
		sys.exec("sleep 1")                                                                
	end
	
	if wan_ip then
		for i = 1,5 do  --5*2=10s
			sys.exec("ping 168.95.1.1 -c 1 -w 2 > /var/ping_internet") -- Wait for DHCP server, so the delay of 5 seconds is necessary!
			statusInternetcheck = luci.sys.internet_check()
			if statusInternetcheck ~= nil then
				break
			end
		end

		if statusInternetcheck then
--[[
			local product_name = uci:get("system","main","product_name")

			if (product_name == "NBG6817" or product_name == "NBG6617") then

				local show_val=sys.exec("/bin/WiFi_GUI_ctrl easy123_wifi_get_val")
				local val_list=NEW_split(show_val,"<;;>")

				luci.template.render("genie4", {
					SSID = val_list[1],
					PASSWORD = val_list[2],
					SSID_5G = val_list[3],
					PASSWORD_5G = val_list[4],
				})
			else
				luci.template.render("genie4", {
					SSID = uci:get("wireless","ath0","ssid"),
					PASSWORD = uci:get("wireless","ath0","WPAPSKkey"),
					SSID_5G = uci:get("wireless","ath10","ssid"),
					PASSWORD_5G = uci:get("wireless","ath10","WPAPSKkey")
				})
			end
]]--
			sys.exec("echo eas123_wanSet_ok > /tmp/chk_eas123Status")
			action_eaZy123_wireless_apply_init()
		else
			sys.exec("echo -n eas123_wanSet_fail > /tmp/chk_eas123Status")
			luci.template.render("genie4_error2")
		end
	else
		sys.exec("echo -n eas123_wanSet_fail > /tmp/chk_eas123Status")
		luci.template.render("genie4_error1")
	end
end

function action_eaZy123_wireless_apply_init()
	local product_name = uci:get("system","main","product_name")

	if (product_name == "NBG6817" or product_name == "NBG6617") then
		local show_val=sys.exec("/bin/WiFi_GUI_ctrl easy123_wifi_get_val")
		local val_list=NEW_split(show_val,"<;;>")

		luci.template.render("genie4", {
			SSID = val_list[1],
			PASSWORD = val_list[2],
			SSID_5G = val_list[3],
			PASSWORD_5G = val_list[4],
		})
	else
		luci.template.render("genie4", {
			SSID = uci:get("wireless","ath0","ssid"),
			PASSWORD = uci:get("wireless","ath0","WPAPSKkey"),
			SSID_5G = uci:get("wireless","ath10","ssid"),
			PASSWORD_5G = uci:get("wireless","ath10","WPAPSKkey")
		})
	end
end

function action_eaZy123_wireless_apply()
	local chk_status_file = io.open("/tmp/chk_eas123Status", "r")
	local chk_status = "OK"		
	if chk_status_file then
		chk_status = chk_status_file:read("*line")
		chk_status_file:close()
	end
	sys.exec("rm /tmp/easy123_chk")
	sys.exec("rm /tmp/system_config_old")
	sys.exec("rm /tmp/network_config_old")
	sys.exec("rm /tmp/wireless_config_old")
	sys.exec("rm /tmp/chk_eas123Status")

	uci:apply("wireless")

	if ( chk_status == "eas123_wanSet_fail" ) then
		action_networkmap()
	else
		local product_name = uci:get("system","main","product_name")

		if (product_name == "NBG6817" or product_name == "NBG6617") then

			local show_val=sys.exec("/bin/WiFi_GUI_ctrl easy123_wifi_get_val")
			local val_list=NEW_split(show_val,"<;;>")

			luci.template.render("genie5", {
				SSID = val_list[1],
				PASSWORD = val_list[2],
				SSID_5G = val_list[3],
				PASSWORD_5G = val_list[4],
			})
		else
			luci.template.render("genie5", {
				SSID = uci:get("wireless","ath0","ssid"),
				PASSWORD = uci:get("wireless","ath0","WPAPSKkey"),
				SSID_5G = uci:get("wireless","ath10","ssid"),
				PASSWORD_5G = uci:get("wireless","ath10","WPAPSKkey")
			})
		end
	end
end

--[[
function action_wan_internet_connection()
    local genie3_apply = luci.http.formvalue("genie3_apply")

    if genie3_apply then
   	
		-- lock dns check, and it will be unlock after updating dns in update_sys_dns
		sys.exec("echo 1 > /var/update_dns_lock")
		local wan_proto = uci:get("network","wan","proto")
		sys.exec("echo "..wan_proto.." > /tmp/old_wan_proto")
	
        local connection_type = luci.http.formvalue("connectionType")                				

        if connection_type == "PPPOE" then
			local pppoeUser = luci.http.formvalue("pppoeUser")
			local pppoePass = luci.http.formvalue("pppoePass")
			local pppoeIdleTime = luci.http.formvalue("pppoeIdleTime")
			local pppoeWanIpAddr = luci.http.formvalue("pppoeWanIpAddr")
					
			if not pppoeIdleTime then
				pppoeIdleTime=""
			end
					
			if not pppoeWanIpAddr then
				pppoeWanIpAddr=""
			end
					
      uci:set("network","wan","proto","pppoe")
      uci:set("network","wan","username",pppoeUser)
      uci:set("network","wan","password",pppoePass)
			uci:set("network","wan","demand",pppoeIdleTime)
			uci:set("network","wan","pppoeWanIpAddr",pppoeWanIpAddr)

		elseif connection_type == "PPTP" then
		
			local pptpUser = luci.http.formvalue("pptpUser")
			local pptpPass = luci.http.formvalue("pptpPass")
			local pptp_serverIp = luci.http.formvalue("pptp_serverIp")
			local pptpWanIpAddr = luci.http.formvalue("pptpWanIpAddr")
			local pptp_config_ip = luci.http.formvalue("pptp_config_ip")
			local pptp_staticIp = luci.http.formvalue("pptp_staticIp")
			local pptp_staticNetmask = luci.http.formvalue("pptp_staticNetmask")
			local pptp_staticGateway = luci.http.formvalue("pptp_staticGateway")

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
			uci:set("network","vpn","interface")
			
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
			uci:set("network","vpn","pptp_Nailedup",pptpNailedup)
			uci:set("network","vpn","pptp_demand",pptpIdleTime)
			uci:set("network","vpn","pptp_serverip",pptp_serverIp)
			uci:set("network","vpn","pptpWanIPMode","1")
			uci:set("network","vpn","pptpWanIpAddr",pptpWanIpAddr)
			
		else
			local WAN_IP_Auto = luci.http.formvalue("WAN_IP_Auto")
			local Fixed_staticIp = luci.http.formvalue("staticIp")
			local Fixed_staticNetmask = luci.http.formvalue("staticNetmask")
			local Fixed_staticGateway = luci.http.formvalue("staticGateway")
			local Server_dns1Type       = luci.http.formvalue("dns1Type")
			local Server_staticPriDns   = luci.http.formvalue("staticPriDns")
			local Server_dns2Type       = luci.http.formvalue("dns2Type")
			local Server_staticSecDns   = luci.http.formvalue("staticSecDns")
	
			if Server_dns1Type~="USER" or Server_staticPriDns == "0.0.0.0" or not Server_staticPriDns then
				Server_staticPriDns=""
				if string.match(Server_dns1Type, "(%a+)") then
					Server_dns1Type = string.match(Server_dns1Type, "(%a+)")
					uci:set("network","wan","dns1",Server_dns1Type ..",".. Server_staticPriDns)
				end
			elseif string.match(Server_dns1Type, "(%a+)") and string.match(Server_staticPriDns, "(%d+.%d+.%d+.%d+)") then
				Server_dns1Type = string.match(Server_dns1Type, "(%a+)")
				Server_staticPriDns = string.match(Server_staticPriDns, "(%d+.%d+.%d+.%d+)")
				uci:set("network","wan","dns1",Server_dns1Type ..",".. Server_staticPriDns)
			end
						
			if Server_dns2Type~="USER" or Server_staticSecDns == "0.0.0.0" or not Server_staticSecDns then
				Server_staticSecDns=""
				if string.match(Server_dns2Type, "(%a+)") then
					Server_dns2Type = string.match(Server_dns2Type, "(%a+)")
					uci:set("network","wan","dns2",Server_dns2Type ..",".. Server_staticSecDns)
				end
			elseif string.match(Server_dns2Type, "(%a+)") and string.match(Server_staticSecDns, "(%d+.%d+.%d+.%d+)") then
				Server_dns2Type = string.match(Server_dns2Type, "(%a+)")
				Server_staticSecDns = string.match(Server_staticSecDns, "(%d+.%d+.%d+.%d+)")
				uci:set("network","wan","dns2",Server_dns2Type ..",".. Server_staticSecDns)
			end
					
			if WAN_IP_Auto == "1" then
				uci:set("network","wan","proto","dhcp")
            else
				uci:set("network","wan","proto","static")
				if string.match(Fixed_staticIp, "(%d+.%d+.%d+.%d+)") then
					Fixed_staticIp = string.match(Fixed_staticIp, "(%d+.%d+.%d+.%d+)")
					uci:set("network","wan","ipaddr",Fixed_staticIp)
				end
				if string.match(Fixed_staticNetmask, "(%d+.%d+.%d+.%d+)") then
					Fixed_staticNetmask = string.match(Fixed_staticNetmask, "(%d+.%d+.%d+.%d+)")
					uci:set("network","wan","netmask",Fixed_staticNetmask)
				end
				if string.match(Fixed_staticGateway, "(%d+.%d+.%d+.%d+)") then
					Fixed_staticGateway = string.match(Fixed_staticGateway, "(%d+.%d+.%d+.%d+)")
					uci:set("network","wan","gateway",Fixed_staticGateway)
				end
            end      
		end
		
--		sys.exec("rm /tmp/chk_eas123Status")
--		sys.exec("kill $(ps | grep '/bin/easy123_wifi_watch' | grep 'grep' -v | awk '{print $1}')")
--		sys.exec("echo eas123_wanSet > /tmp/chk_eas123Status")
		uci:set("network","general","config_section","wan")	
		uci:commit("network")	
--        uci:apply("network")
		
		
	end

    luci.template.render("genie4", {
		SSID = uci:get("wireless","ath0","ssid"),
		security = uci:get("wireless","ath0","auth"),
		pwd = uci:get("wireless","ath0","WPAPSKkey"),
		SSID_5G = uci:get("wireless","ath10","ssid"),
		security_5G = uci:get("wireless","ath10","auth"),
		pwd_5G = uci:get("wireless","ath10","WPAPSKkey")
	})
end

function action_password()
        local genie2_apply = luci.http.formvalue("genie2_apply")

        if genie2_apply then

           local new_password = luci.http.formvalue("new_password")

           uci:set("system","main","pwd",new_password)

--           sys.exec("echo eas123_routerPWD > /tmp/chk_eas123Status")
           uci:commit("system") 
--           uci:apply("system") 

        end

        local wanif = uci:get("network","wan","ifname")
        local wan_proto = uci:get("network","wan","proto")
        local wanInfo_cmd=luci.sys.exec("ifconfig '"..wanif.."'")
        local wan_ip=string.match(wanInfo_cmd,"inet addr:(%d+.%d+.%d+.%d+)")

        if wan_ip and wan_proto == "dhcp" then
        	luci.template.render("genie4", {
				SSID = uci:get("wireless","ath0","ssid"),
				security = uci:get("wireless","ath0","auth"),
				pwd = uci:get("wireless","ath0","WPAPSKkey"),
				SSID_5G = uci:get("wireless","ath10","ssid"),
				security_5G = uci:get("wireless","ath10","auth"),
				pwd_5G = uci:get("wireless","ath10","WPAPSKkey")
			})

        else

        	luci.template.render("genie3")

        end

end

function action_completion()
	local genie4_apply = luci.http.formvalue("genie4_apply")
	
	local wlanRadio = luci.http.formvalue("wlanRadio")
	sys.exec("echo wlanRadio="..wlanRadio.." >> /tmp/easy123_value")
	--local wps_enable = uci:get("wps","wps","enabled")
	--local wps5G_enable = uci:get("wps5G","wps","enabled")


	if genie4_apply then
		local cfg
		local section
		local wlanPwd = luci.http.formvalue("wlanPwd")
		local wlanSSID = luci.http.formvalue("wlanSSID")
		local wlanSec = luci.http.formvalue("wlanSec")
		local wlanPwd5G 
		local wlanSSID5 
		local wlanSec5G 
		if wlanRadio == "both" then
			 wlanPwd5G = luci.http.formvalue("wlanPwd")
			 wlanSSID5 = luci.http.formvalue("wlanSSID")
			 wlanSec5G = luci.http.formvalue("wlanSec")
		else
			 wlanPwd5G = luci.http.formvalue("wlanPwd5G")
			 wlanSSID5 = luci.http.formvalue("wlanSSID5G")
			 wlanSec5G = luci.http.formvalue("wlanSec5G")
		end
		
		sys.exec("kill $(ps | grep 'watch -tn 1 wps_conf_24G' | grep 'grep' -v | awk '{print $1}')")
 		sys.exec("kill $(ps | grep 'watch -tn 5 wps_conf_5G' | grep 'grep' -v | awk '{print $1}')")
		cfg = "wireless"
		section = "ath0"
		wpscfg = "wps"
		section5g = "ath10"
		wpscfg5g = "wps5G"

		--set 2.4G
		wlanSSID = checkInjection(wlanSSID)
		if wlanSSID ~= false then
			uci:set(cfg,section,"ssid",wlanSSID)		
		end
		
		if wlanSec == "none" then
			uci:set(cfg,section,"auth","OPEN")
			uci:set(cfg,section,"encryption","NONE")			
		elseif wlanSec == "WPA-PSK" then
			uci:set(cfg,section,"auth","WPAPSK")
			uci:set(cfg,section,"encryption","WPAPSK")

			wlanPwd = checkInjection(wlanPwd)
			if wlanPwd  ~= false then
				uci:set(cfg,section,"WPAPSKkey", wlanPwd)			
			end

		elseif wlanSec == "WPA2-PSK" then
			uci:set(cfg,section,"auth","WPA2PSK")
			uci:set(cfg,section,"encryption","WPA2PSK")

			wlanPwd = checkInjection(wlanPwd)
			if wlanPwd  ~= false then
				uci:set(cfg,section,"WPAPSKkey", wlanPwd)
			end
		end

		--set 5G

		wlanSSID5 = checkInjection(wlanSSID5)
			if wlanSSID5 ~= false then
				uci:set(cfg,section5g,"ssid",wlanSSID5)		
			end
		
			if wlanSec5G == "none" then
				uci:set(cfg,section5g,"auth","OPEN")
				uci:set(cfg,section5g,"encryption","NONE")			
			elseif wlanSec5G == "WPA-PSK" then
				uci:set(cfg,section5g,"auth","WPAPSK")
				uci:set(cfg,section5g,"encryption","WPAPSK")

				wlanPwd5G = checkInjection(wlanPwd5G)
				if wlanPwd5G  ~= false then
					uci:set(cfg,section5g,"WPAPSKkey", wlanPwd5G)			
				end

			elseif wlanSec5G == "WPA2-PSK" then
				uci:set(cfg,section5g,"auth","WPA2PSK")
				uci:set(cfg,section5g,"encryption","WPA2PSK")

				wlanPwd5G = checkInjection(wlanPwd5G)
				if wlanPwd5G  ~= false then
					uci:set(cfg,section5g,"WPAPSKkey", wlanPwd5G)
				end
			end

		
--		sys.exec("echo eas123_wifiDone > /tmp/chk_eas123Status")
		uci:commit(cfg)
--		uci:apply(cfg)
		--WPS function
		--Set wps conf with 1 here, the WPS status will be configured when you
		--execute "wps ath0 on"
		uci:set(wpscfg,"wps","conf","1")
		uci:commit(wpscfg)
		uci:set(wpscfg5g,"wps","conf","1")
		uci:commit(wpscfg5g)		

		--if wlanRadio == "2.4G" then
			--if (wps_enable == "1") then
                        	--sys.exec("wps ath0 on")
                	--else
                        	--sys.exec("iwpriv ath0 set WscConfStatus=2")
                	--end			
		--elseif wlanRadio == "5G" then
			--if (wps5G_enable == "1") then
                        	--sys.exec("wps ath10 on")
                	--else
                        	--sys.exec("iwpriv ath10 set WscConfStatus=2")
                	--end	
		--end 
               
	end
	
	luci.template.render("genie5")
end

function easy123_over()
	sys.exec("rm /tmp/chk_eas123Status")
	sys.exec("kill $(ps | grep '/bin/easy123_wifi_watch' | grep 'grep' -v | awk '{print $1}')")
	sys.exec("echo eas123_wanSet > /tmp/chk_eas123Status")

	uci:apply("network")
	local wanif = "eth0"
	local wan_proto = uci:get("network","wan","proto")
	if wan_proto == "pppoe" then
		wanif = "pppoe-wan"
	else
		wanif = "eth0"
	end

	for i = 1,12 do                                                                            
		wanInfo_cmd=luci.sys.exec("ifconfig '"..wanif.."'")                                
		wan_ip=string.match(wanInfo_cmd,"inet addr:(%d+.%d+.%d+.%d+)")                     
		if wan_ip then                                                                     
			break                                                                      
		end                                                                                
		sys.exec("sleep 1")                                                                
	end
	
	if wan_ip then
		for i = 1,5 do  --5*2=10s
			sys.exec("ping 168.95.1.1 -c 1 -w 2 > /var/ping_internet") -- Wait for DHCP server, so the delay of 5 seconds is necessary!
			statusInternetcheck = luci.sys.internet_check()
			if statusInternetcheck ~= nil then
				break
			end
		end

		if statusInternetcheck then
			sys.exec("echo eas123_routerPWD > /tmp/chk_eas123Status")
			uci:apply("system")
			luci.template.render("genie6")
			return
		else
			luci.template.render("genie5_error3")
			return
		end
	else
		luci.template.render("genie5_error2")
		return
	end

end

function easy123_over2()
	sys.exec("rm /tmp/easy123_chk")
	sys.exec("rm /tmp/system_config_old")
	sys.exec("rm /tmp/network_config_old")
	sys.exec("rm /tmp/wireless_config_old")

	sys.exec("echo eas123_wifiDone > /tmp/chk_eas123Status")
	uci:apply("wireless")
	luci.template.render("genie7")
--	action_logout()
end
]]--

function action_devicetype()
	sys.exec("ping 8.8.8.8 -c 1 | grep time > /var/connect_internet")
	luci.template.render("networkmap", {typesort = 1})
end	

function action_connectiontype()
	sys.exec("ping 8.8.8.8 -c 1 | grep time > /var/connect_internet")
	luci.template.render("networkmap", {typesort = 2})
end

function NEW_split(str,sep)
	local array = {}
	list = string.split(str, sep)
	for _, val in ipairs(list) do
		table.insert(array, val) 
	end
    return array
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
