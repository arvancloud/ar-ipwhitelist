#!/usr/bin/env bash

# color codes
green='\033[0;32m'
red='\033[0;31m'
yellow='\033[0;33m'
cyan='\033[0;36m'
reset='\033[0m'

# Show an error and exit
abort() {
  echo -e "${red}--X $1 ${reset}"
  exit 1
}

info() {
  echo -e "${cyan}--> $1 ${reset}"
}

warn() {
  echo -e "${yellow}--! $1 ${reset}"
}

success() {
  echo -e "${green}--:) $1 ${reset}"
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
  echo "   5) ipset+iptables"
  echo "   6) nftables"
  read -r -p "Firewall: " option
else
  option=$1
fi

clear

info "Downloading Arvancloud IPs list..."

IPsLink="https://www.arvancloud.ir/fa/ips.txt"
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

info "Adding IPs to the selected Firewall"

# Process user input
case "$option" in
1 | ufw)
  if [[ ! -x "$(command -v ufw)" ]]; then
    abort "ufw is not installed."
  fi

  warn "Delete old arvancloud rules if exist"

  ufw show added | awk '/arvancloud/{ gsub("ufw","ufw delete",$0); system($0)}'

  info "Adding new arvancloud rules"

  for IP in ${IPs}; do
    sudo ufw allow from "$IP" to any comment "arvancloud"
  done
  sudo ufw reload
  ;;
2 | csf)
  if [[ ! -x "$(command -v csf)" ]]; then
    abort "csf is not installed."
  fi

  warn "Delete old arvancloud rules if exist"

  awk '!/arvancloud/' /etc/csf/csf.allow > csf.t && mv csf.t /etc/csf/csf.allow

  info "Adding new arvancloud rules"

  for IP in ${IPs}; do
    sudo csf -a "$IP"
  done
  sudo csf -r
  ;;
3 | firewalld)
  if [[ ! -x "$(command -v firewall-cmd)" ]]; then
    abort "firewalld is not installed."
  fi

  warn "Delete old arvancloud zone if exist"

  if [[ $(sudo firewall-cmd --permanent --list-all-zones | grep arvancloud) ]]; then sudo firewall-cmd --permanent --delete-zone=arvancloud; fi
  sudo firewall-cmd --permanent --new-zone=arvancloud

  info "Adding new arvancloud zone"

  for IP in ${IPs}; do
    sudo firewall-cmd --permanent --zone=arvancloud --add-rich-rule='rule family="ipv4" source address='"$IP"' port port=80 protocol="tcp" accept'
    sudo firewall-cmd --permanent --zone=arvancloud --add-rich-rule='rule family="ipv4" source address='"$IP"' port port=443 protocol="tcp" accept'
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
  sudo ipset list | grep -q "arvancloud-ipset" ; greprc=$?
  if [[ "$greprc" -eq 0 ]]; then
    sudo iptables -D INPUT -m set --match-set arvancloud-ipset src -j ACCEPT 2>/dev/null
    sleep 0.5
    sudo ipset destroy arvancloud-ipset
  fi

  ipset create arvancloud-ipset hash:net
  for IP in ${IPs}; do
    ipset add arvancloud-ipset "$IP"
  done
  sudo iptables -nvL | grep -q "arvancloud-ipset"; exitcode=$?
  if [[ "$exitcode" -eq 1 ]]; then
    sudo iptables -I INPUT -m set --match-set arvancloud-ipset src -j ACCEPT
  fi
  ;;
6 | nftables)
  if [[ ! -x "$(command -v nft)" ]]; then
    abort "nftables is not installed."
  fi
  # create filter table
  nft add table inet filter
  # create a chain for arvancloud
  sudo nft add chain inet filter arvancloud '{ type filter hook input priority 0; }'
  # concat all IPs to a string and remove blank line and separate with comma
  IPsString=$(echo "$IPs" | tr '\n' ',' | sed 's/,$//')
  sudo nft insert rule inet filter arvancloud counter ip saddr "{ $IPsString }" accept
  ;;
*)
  abort "The selected firewall is not valid."
  ;;
esac

success "\nDONE!"