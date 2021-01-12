#!/usr/bin/env bash

# root access needed
if [[ $EUID -ne 0 ]]; then
  echo "This script needs to be run with superuser privileges."
  exit 1
fi

# Use the first argument or Ask the user to select firewall
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

# Process user input
case "$option" in
1 | ufw)
  if [ ! -x "$(command -v ufw)" ]; then
    echo "ufw is not installed."
    exit 1
  fi

  for IP in ${IPs}; do
    sudo ufw allow from "$IP" to any
  done
  ;;
2 | csf)
  if [ ! -x "$(command -v csf)" ]; then
    echo "csf is not installed."
    exit 1
  fi

  for IP in ${IPs}; do
    sudo csf -a "$IP"
  done
  sudo csf -r
  ;;
*)
  echo "The selected firewall is not valid."
  exit 1
  ;;
esac

echo "DONE"
