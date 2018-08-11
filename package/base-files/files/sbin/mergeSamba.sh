#!/bin/sh
local mode=0    # 0 -> easyMode, 1 -> advanceMode

init_general(){
  local sys_samba_general_enable=$(uci get system.general.enable)
  local samba_general_name=$(uci get samba.general.name)
  local samba_general_workgroup=$(uci get samba.general.workgroup)
  local samba_general_description=$(uci get samba.general.description)
  local samba_general_charset=$(uci get samba.general.charset)

  echo -e "\n" >> /tmp/newsamba
  echo -e "config samba general" >> /tmp/newsamba
  echo -e "\toption enable '$sys_samba_general_enable'" >> /tmp/newsamba
  if [ "$mode" == "0" ];then
    echo -e "\toption easymode '1'" >> /tmp/newsamba
  else
    echo -e "\toption easymode '0'" >> /tmp/newsamba
  fi
  echo -e "\toption name '$samba_general_name'" >> /tmp/newsamba
  echo -e "\toption workgroup '$samba_general_workgroup'" >> /tmp/newsamba
  echo -e "\toption description '$samba_general_description'" >> /tmp/newsamba
  echo -e "\toption charset '$samba_general_charset'" >> /tmp/newsamba
}

init_user(){
  for number in 1 2 3 4 5
  do
    local enable=$(uci get system.samba_user_$number.enable)
    local name=$(uci get system.samba_user_$number.name)
    local passwd=$(uci get system.samba_user_$number.passwd)
    local sum=$(uci get system.samba_user_$number.sum)
    local enable_usb1=$(uci get system.samba_user_$number.enable_usb1)
    local enable_usb2=$(uci get system.samba_user_$number.enable_usb2)
    local sys_samba_usb1_types=$(uci get system.general.usb1_types)
    local sys_samba_usb2_types=$(uci get system.general.usb2_types)

    echo -e "\n" >> /tmp/newsamba
    echo -e "config sambauser 'user$number'" >> /tmp/newsamba
    echo -e "\toption enable '$enable'" >> /tmp/newsamba
    echo -e "\toption name '$name'" >> /tmp/newsamba
    echo -e "\toption passwd '$passwd'" >> /tmp/newsamba
    echo -e "\toption sum '$sum'" >> /tmp/newsamba

    ## check mode
    if [ "$mode" == "0" ];then
      if [ -n "$name" ] && [ "$enable" == "1" ];then
        if [ "$enable_usb1" == "1" ] || [ "$enable_usb2" == "1" ];then
          mode=1
        fi
      fi
    fi

    ## check usb1 type
    if [ "$enable_usb1" == "1" ];then
      if [ "$sys_samba_usb1_types" == "0" ];then
        echo -e "\toption usb1 '1'" >> /tmp/newsamba
      else
        echo -e "\toption usb1 '2'" >> /tmp/newsamba
      fi
    else
      echo -e "\toption usb1 '0'" >> /tmp/newsamba
    fi

    ## check usb2 type
    if [ "$enable_usb2" == "1" ];then
      if [ "$sys_samba_usb2_types" == "0" ];then
        echo -e "\toption usb2 '1'" >> /tmp/newsamba
      else
        echo -e "\toption usb2 '2'" >> /tmp/newsamba
      fi
    else
      echo -e "\toption usb2 '0'" >> /tmp/newsamba
    fi
  done
}

init(){
  rm /tmp/newsamba

  # merge data model
  init_user
  init_general
  mv /etc/config/samba /etc/config/samba_old
  mv /tmp/newsamba /etc/config/samba
  rm /tmp/newsamba

  # # merge new script
  # mv /etc/init.d/samba /etc/init.d/samba_old
  # mv /etc/init.d/newsamba /etc/init.d/samba
  # rm /etc/init.d/newsamba
}

case $1 in
  init)
    init "$@"
    ;;
esac
