#!/bin/bash

curl https://www.arvancloud.com/fa/ips.txt > ip.list

#allow ip in ufw
while IFS= read -r IP;
do
    ufw allow from $IP
done < ip.list

rm -f ip.list