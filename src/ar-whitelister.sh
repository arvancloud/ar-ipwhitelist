#!/usr/bin/env bash

# root access needed
if [[ $EUID -ne 0 ]]; then
  echo "You need to run this as root"
  exit 1
fi

if [[ -z $1 ]]; then
  echo "Select a firewall to add IPs:"
  echo "   1) ufw"
  echo "   2) csf"
  read -r -p "Firewall: " option
else
  option=$1
fi

clear
echo "Downloading Arvancloud IPs list..."
IPs=$(curl -s https://www.arvancloud.com/fa/ips.txt)
clear

case "$option" in
1 | ufw)
  for IP in ${IPs}; do
    sudo ufw allow from "$IP" to any
  done
  ;;
2 | csf)
  for IP in ${IPs}; do
    sudo csf -a "$IP"
  done
  sudo csf -r
  ;;
*)
  echo "The selected firewall is not valid"
  exit 1
  ;;
esac

echo "DONE"
