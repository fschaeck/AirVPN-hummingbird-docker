#!/bin/sh

##### First of all reset the network
/usr/bin/hummingbird --recover-network &> /dev/null

network_lock=$(echo " $@" |grep -oE '\s(--network-lock(\s+|=)|-N\s+)\S+' |sed -nE '$s/^ *[^= ]+[= ]*//p')
case "$network_lock" in
    iptables)
        # Resetting the containers iptables firewall
        iptables_reset="#
*raw
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
*mangle
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
COMMIT
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
"
        echo "Resetting iptables legacy"
        echo "$iptables_reset" |iptables-legacy-restore ||echo "failed..."
        echo "Resetting ip6tables legacy"
        echo "$iptables_reset" |ip6tables-legacy-restore ||echo "failed..."
        echo "Resetting iptables"
        echo "$iptables_reset" |iptables-restore ||echo "failed..."
        echo "Resetting ip6tables"
        echo "$iptables_reset" |ip6tables-restore ||echo "failed..."
        ;;
    pf) 
        echo "Resetting pf firewall not yet implemented"
        ;;
    nftables)
        echo "Resetting nftables firewall not yet implemented"
        ;;
    on)
        echo "Don't know which firewall to reset... No reset done!"
        ;;
    *)
        ;;
esac


##### And now start the hummingbird client

/usr/bin/hummingbird  "$@" 2>&1 | tee -a airvpn-hummingbird.log

