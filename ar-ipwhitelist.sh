#!/bin/bash

ips_url="https://www.arvancloud.com/fa/ips.txt"

# Show an error message and exit.
abort()
{
    echo -e "\033[0;31mERROR: $1\033[0m"
    exit 1
}

# Show help message.
help()
{
    echo -e "\033[1;36m"
    echo "+-------------------------------------------------------------------+"
    echo "|     _    ______     ___    _   _     ____ _     ___  _   _ ____   |"
    echo "|    / \  |  _ \ \   / / \  | \ | |   / ___| |   / _ \| | | |  _ \  |"
    echo "|   / _ \ | |_) \ \ / / _ \ |  \| |  | |   | |  | | | | | | | | | | |"
    echo "|  / ___ \|  _ < \ V / ___ \| |\  |  | |___| |__| |_| | |_| | |_| | |"
    echo "| /_/   \_\_| \_\ \_/_/   \_\_| \_|   \____|_____\___/ \___/|____/  |"
    echo "+-------------------------------------------------------------------+"
    echo -e "\033[0m"

    echo "Arvan Cloud IP White List"
    echo ""

    if [[ $1 == "setup" ]]; then
        echo "setup: Setup firewall to allow Arvan Cloud CDN IPs only."
        echo ""
        echo "Usage: $0 setup --param=value ..."
        echo ""
        echo "Parameters:"
        echo -e " --firewall|-f\t\tFirewall name. (Default=ufw) (Supported=ufw,csf,vmmanager)"
        echo -e " --ports|-p\t\tAllowed ports[Just for ufw]. (Default=80,443)"
    else
        echo "Usage: $0 COMMAND"
        echo ""
        echo "Commands:"
        echo -e " setup\t\t Setup firewall to allow CDN IPs only."
    fi
    echo ""

    exit 0
}

# Setup UFW firewall.
setupUfw()
{
    local ips=$1
    local ports=$2

    # Check ufw is installed
    if [ ! -x "$(command -v ufw)" ]; then
        abort "ufw firewall is not installed."
    fi

    echo "Configuring ufw firewall started."

    # Enable ufw if is disabled
    if ufw status | grep -qw 'inactive'; then
        echo "ufw is disabled. enabling ufw..."
        yes | ufw enable > /dev/null || true
    fi

    ufw default deny incoming > /dev/null
    ufw allow 22 > /dev/null

    for ip in $ips; do
        ufw allow from $ip to any port $ports proto tcp comment 'Arvan Cloud IP' > /dev/null
        ufw allow from $ip to any port $ports proto udp comment 'Arvan Cloud IP' > /dev/null
    done

    ufw reload > /dev/null

    echo "ufw configured successfully."
    exit 0
}

# Setup CSF firewall.
setupCsf()
{
    local ips=$1
    local ports=$2

    ports="${ports/:/_}"

    # Check csf is installed
    if [ ! -x "$(command -v csf)" ]; then
        abort "csf firewall is not installed."
    fi

    echo "Configuring csf firewall started."

    sed -i '/##start-arvan-ip/,/##end-arvan-ip/d' /etc/csf/csf.allow
    sed -i '/##start-arvan-ip/,/##end-arvan-ip/d' /etc/csf/csf.ignore

    echo "##start-arvan-ip" >> /etc/csf/csf.allow
    echo "##start-arvan-ip" >> /etc/csf/csf.ignore
    for ip in $ips; do
        echo "tcp|in|d=$ports|s=$ip # Arvan Cloud IP" >> /etc/csf/csf.allow
        echo "udp|in|d=$ports|s=$ip # Arvan Cloud IP" >> /etc/csf/csf.allow
        echo "$ip # Arvan Cloud IP" >> /etc/csf/csf.ignore
    done
    echo "##end-arvan-ip" >> /etc/csf/csf.allow
    echo "##end-arvan-ip" >> /etc/csf/csf.ignore

    csf -r > /dev/null

    echo "csf configured successfully."
    exit 0
}

# Setup VMManager firewall.
setupVMManger()
{
    local ips=$1
    local ports=$2

    # TODO!
}

# Setup firewall
setup()
{
    local firewall="ufw"
    local ports="80,443"

    while [ $# -gt 0 ]; do
        case "$1" in
        --help* | -h*)
            help "setup"
            ;;
        --firewall* | -f*)
            if [[ "$1" != *=* ]]; then shift; fi
            firewall="${1#*=}"
            ;;
        --ports* | -p*)
            if [[ "$1" != *=* ]]; then shift; fi
            ports="${1#*=}"
            ;;
        *)
            abort "Invalid parameters."
            ;;
        esac
        shift
    done

    local ips=""
    if [ -x "$(command -v curl)" ]; then
        ips=$(curl -s $ips_url)
    elif [ -x "$(command -v wget)" ]; then
        ips=$(wget -q -O - $ips_url)
    else
        abort "curl or wget is required to run this script."
    fi

    case $firewall in
    ufw)
        setupUfw "$ips" "$ports"
        ;;
    csf)
        setupCsf "$ips" "$ports"
        ;;
    vmmanger)
        setupVMManger "$ips" "$ports"
        ;;
    *)
        abort $"Unsupported Firewall.\nSupported Firewalls:\n * ufw\n * csf\n * vmmanger"
        ;;
    esac
}

main()
{
    set -e
    set -o pipefail

    if [ $1 ]; then
        case "$1" in
        setup)
            shift
            setup $@
            ;;
        --help | -h | --version | -v)
            help
            ;;
        *)
            abort "Invalid Command."
            ;;
        esac
    else
        abort "Not enough arguments.\n\nUse $0 --help for more information."
    fi
}

main "$@"
