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
    echo "+------------------------------------------------------------------+"
    echo "|     _    ______     ___    _   _    ____ _     ___  _   _ ____   |"
    echo "|    / \  |  _ \ \   / / \  | \ | |  / ___| |   / _ \| | | |  _ \  |"
    echo "|   / _ \ | |_) \ \ / / _ \ |  \| | | |   | |  | | | | | | | | | | |"
    echo "|  / ___ \|  _ < \ V / ___ \| |\  | | |___| |__| |_| | |_| | |_| | |"
    echo "| /_/   \_\_| \_\ \_/_/   \_\_| \_|  \____|_____\___/ \___/|____/  |"
    echo "+------------------------------------------------------------------+"
    echo -e "\033[0m"

    echo "Arvan Cloud IP White List"
    echo ""

    if [[ $1 == "setup" ]]; then
        echo "setup: Setup firewall to allow only Arvan Cloud IPs."
        echo ""
        echo "Usage: $0 setup --param=value ..."
        echo ""
        echo "Parameters:"
        echo -e " --firewall|-f\t\tFirewall name. (default=ufw) (possible values= ufw)"
        echo -e " --ports|-p\t\tAllow only specific ports. (Default=80,443)"
    else
        echo "Usage: $0 COMMAND"
        echo ""
        echo "Commands:"
        echo -e " setup\t\t Setup firewall to allow CDN only IPs."
    fi
    echo ""

    exit 0
}

# Setup UFW firewall.
setUfw()
{
    local ips=$1

    # Check ufw is installed
    if [ ! -x "$(command -v ufw)" ]; then
        abort "ufw firewall is not installed."
    fi

    echo "Starting setup ufw firewall."

    # Enable ufw if is disabled
    if [ $(ufw status|grep -qw inactive) ]; then
        yes | ufw enable > /dev/null
    fi

    ufw default deny incoming > /dev/null
    ufw allow 22 > /dev/null

    for ip in $ips; do
        ufw allow from $ip port $ports proto tcp comment 'Arvan Cloud IP' > /dev/null
        ufw allow from $ip port $ports proto udp comment 'Arvan Cloud IP' > /dev/null
    done

    ufw reload > /dev/null

    echo "ufw configured successfully."
    exit 0
}

# Setup firewall
setup()
{
    firewall="ufw"
    ports="80,443"
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

    ips=""
    if [ -x "$(command -v curl)" ]; then
        ips=$(curl -s $ips_url)
    elif [ -x "$(command -v wget)" ]; then
        ips=$(wget -q -O - $ips_url)
    else
        abort "curl or wget is required to run this script."
    fi

    case $firewall in
    ufw)
        setUfw "$ips"
        ;;
    *)
        abort $"Unsupported Firewall.\nSupported Firewalls:\n * ufw"
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
