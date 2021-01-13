# ar-ipwhitelist

<p align="center">
    <img alt="preview gif" src="https://github.com/sh-sh-dev/ar-ipwhitelist/raw/main/preview.gif">
</p>

This project modifies your firewall configuration to allow Arvancloud's CDN network access to your server.

Also, The bash script can be scheduled to update firewall rules automatically.

## How to use

Just run the script and select your firewall from the list
```sh
Select a firewall to add IPs:
   1) UFW
   2) CSF
   3) firewalld
Firewall: [YOUR INPUT]
```

Also, you can pass the firewall name in arguments:
```sh
src/ar-whitelister.sh ufw
``` 

### Auto-update

You can create a cronjob to update the rules automatically.

Examples:

* Update UFW rules every 6 hours
```sh
0 */6 * * * /path/to/ar-whitelister.sh ufw >/dev/null 2>&1
```

* Update CSF rules every day at 1:00
```sh
0 1 * * * /path/to/ar-whitelister.sh csf >/dev/null 2>&1
```

## Supported firewalls

These firewalls are supported currently:

* UFW
* CSF
* firewalld

### How to add more firewalls

If you use a firewall that is not listed here, you can:
* Create an issue
* Send a pull request
