#!/bin/sh

rm /etc/airvpn/hummingbird.lock &> /dev/null
/usr/bin/hummingbird --recover-network &> /dev/null

/usr/bin/hummingbird  "$@" 2>&1 | tee -a airvpn-hummingbird.log
