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
  echo "   4) iptables"
  read -r -p "Firewall: " option
else
  option=$1
fi

clear

echo "Downloading Arvancloud IPs list..."

IPsLink="https://www.arvancloud.com/fa/ips.txt"
IPsFile=$(mktemp /tmp/ar-ips.XXXXXX)
# Delete the temp file if the script stopped for any reason
trap 'rm -f ${IPsFile}' 0 2 3 15

if [[ -x "$(command -v curl)" ]]; then
  downloadStatus=$(curl "${IPsLink}" -o "${IPsFile}" -L -s -w "%{http_code}\n")
elif [[ -x "$(command -v wget)" ]]; then
  downloadStatus=$(wget "${IPsLink}" -O "${IPsFile}" --server-response 2>&1 | awk '/^  HTTP/{print $2}' | tail -n1)
else
  abort "curl or wget is required to run this script."
fi

if [[ "$downloadStatus" -ne 200 ]]; then
  abort "Downloading the IP list wasn't successful. status code: ${downloadStatus}"
else
  IPs=$(cat "$IPsFile")
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
4 | iptables)
  if [[ ! -x "$(command -v iptables)" ]]; then
    abort "iptables is not installed."
  fi

  for IP in ${IPs}; do
    sudo iptables -A INPUT -s "$IP" -j ACCEPT
  done
  ;;

5 | ipset)
  if [[ ! -x "$(command -v ipset)" ]]; then
    abort "ipset is not installed."
  fi
  if [[ ! -x "$(command -v iptables)" ]]; then
    abort "iptables is not installed."
  fi
  sudo ipset list | grep -q "arvancloud-ipset" ; greprc=$
  if [[ "$greprc" -eq 0 ]]; then
    sudo ipset destroy arvancloud-ipset
  fi

  ipset create arvancloud-ipset hash:net
  for IP in ${IPs}; do
    ipset add arvancloud-ipset "$IP"
  done
  sudo iptables -C INPUT -m set --match-set arvancloud-ipset src -j ACCEPT || sudo iptables -A INPUT -m set --match-set arvancloud-ipset src -j ACCEPT
  ;;
*)
  abort "The selected firewall is not valid."
  ;;
esac

echo -e "\033[0;32mDONE"
