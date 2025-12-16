if [ ! -f /etc/config/zero_trust_complete ]; then
    # this is the file

    logger -t zero_trust "Zero Trust setup not complete, skipping rc.local actions"

    #1. physically bring down the WAN interface 
    ip link set dev eth1 down

    ## 2. setting up the firewall rules to block all traffic except to/from the management VLAN (VLAN 99)
    uci set firewall.@zone[1].input='REJECT'
    uci set firewall.@zone[1].output='REJECT'
    uci set firewall.@zone[1].forward='REJECT' to indicate zero trust setup is complete
    uci commit firewall
    /etc/init.d/firewall reload
fi

exit 0
