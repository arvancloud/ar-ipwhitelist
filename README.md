# ArvanCloud IP white-list

![logo](.github/logo.svg)

This project modifies your firewall configuration to allow ArvanCloud's CDN network access to your server.

You can also schedule this script to update the firewall rules automatically.

## How to use

Just run the script and select your firewall from the list:

```bash
Select a firewall to add IPs:
   1) UFW
   2) CSF
   3) firewalld
   4) iptables
   5) ipset+iptables
   6) nftables
Firewall: [YOUR INPUT]
```

Also, you can pass the firewall's name in arguments:

```bash
src/ar-whitelister.sh ufw
```

### Auto-update

You can create a cronjob to update the rules automatically.

Examples:

* Update UFW rules every 6 hours

```bash
0 */6 * * * /path/to/ar-whitelister.sh ufw >/dev/null 2>&1
```

* Update CSF rules every day at 1:00

```bash
0 1 * * * /path/to/ar-whitelister.sh csf >/dev/null 2>&1
```

## Supported firewalls

We currently support these firewalls:

* UFW
* CSF
* firewalld
* iptables
* ipset+iptables
* nftables

### How to add more firewalls

If you use a firewall that is not listed here, you can:

* Create an issue
* Send a pull request
