#!/bin/bash

curl https://www.arvancloud.com/fa/ips.txt > ip.list

ALLOW_IP_FILE=$1

#allow ip in csf
while IFS= read -r IP;
do
    echo $IP >> $ALLOW_IP_FILE
done < ip.list

csf -r

rm -f ip.list