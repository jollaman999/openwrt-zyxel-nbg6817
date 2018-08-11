#!/bin/sh
get_status(){
  local appliaction=$2
  local return_value=$(cat /tmp/$2_status)
  echo -n $return_value
}

case $1 in
  get_status )
    get_status "$@"
  ;;
esac
