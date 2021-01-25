#!/usr/bin/env bash

# Show an error and exit
abort() {
  echo "$1"
  exit 1
}

# root access needed
if [[ $EUID -ne 0 ]]; then
  abort "This script needs to be run with superuser privileges."
fi

# Use the first argument or Ask the user to select firewall
if [[ -z $1 ]]; then
  echo "Select a firewall to add IPs:"
  echo "   1) UFW"
  echo "   2) CSF"
  echo "   3) firewalld"
  read -r -p "Firewall: " option
else
  option=$1
fi

clear

IPsLink="https://www.arvancloud.com/fa/ips.txt"

echo "Downloading Arvancloud IPs list..."

if [ -x "$(command -v curl)" ]; then
  IPs=$(curl -s ${IPsLink})
elif [ -x "$(command -v wget)" ]; then
  IPs=$(wget -q -O - ${IPsLink})
else
  abort "curl or wget is required to run this script."
fi
clear

echo "Adding IPs to the selected Firewall"

# Process user input
case "$option" in
1 | ufw)
  if [[ ! -x "$(command -v ufw)" ]]; then
    abort "ufw is not installed."
  fi

  for IP in ${IPs}; do
    sudo ufw allow from "$IP" to any
  done
  sudo ufw reload
  ;;
2 | csf)
  if [[ ! -x "$(command -v csf)" ]]; then
    abort "csf is not installed."
  fi

  for IP in ${IPs}; do
    sudo csf -a "$IP"
  done
  sudo csf -r
  ;;
3 | firewalld)
  if [[ ! -x "$(command -v firewall-cmd)" ]]; then
    abort "firewalld is not installed."
  fi

  for IP in ${IPs}; do
    sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address='"$IP"' port port=80 protocol="tcp" accept'
    sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address='"$IP"' port port=443 protocol="tcp" accept'
  done
  sudo firewall-cmd --reload
  ;;
*)
  abort "The selected firewall is not valid."
  ;;
esac

echo -e "\033[0;32mDONE"
