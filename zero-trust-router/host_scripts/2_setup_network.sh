#!/bin/bash
# Configure LAN bridge and VLAN 99 for zero-trust router lab
# This creates isolated network segments for security testing

set -e

echo "=== Zero-Trust Router Lab: Network Setup ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Configuration
BRIDGE_NAME="br-lab"
VLAN_ID="99"
VLAN_IFACE="${BRIDGE_NAME}.${VLAN_ID}"
BRIDGE_IP="192.168.99.1"
BRIDGE_NETMASK="255.255.255.0"
BRIDGE_NETWORK="192.168.99.0/24"

echo "Creating bridge interface: $BRIDGE_NAME"

# Load 8021q module for VLAN support
modprobe 8021q || true
echo "8021q" >> /etc/modules-load.d/vlan.conf 2>/dev/null || true

# Create bridge if it doesn't exist
if ! ip link show $BRIDGE_NAME &> /dev/null; then
    ip link add name $BRIDGE_NAME type bridge
    echo "Bridge $BRIDGE_NAME created"
else
    echo "Bridge $BRIDGE_NAME already exists"
fi

# Configure bridge
ip link set $BRIDGE_NAME up
ip addr flush dev $BRIDGE_NAME 2>/dev/null || true
# Use direct CIDR notation for clarity
ip addr add ${BRIDGE_IP}/24 dev $BRIDGE_NAME

# Create VLAN 99 on bridge (isolation VLAN for zero-trust)
echo "Creating VLAN $VLAN_ID for isolation..."
if ! ip link show $VLAN_IFACE &> /dev/null; then
    ip link add link $BRIDGE_NAME name $VLAN_IFACE type vlan id $VLAN_ID
    echo "VLAN interface $VLAN_IFACE created"
else
    echo "VLAN interface $VLAN_IFACE already exists"
fi

ip link set $VLAN_IFACE up

# Configure iptables for isolation and security
echo "Configuring firewall rules..."

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf 2>/dev/null || true

# Default policies - deny all, allow specific
iptables -N LAB_FORWARD 2>/dev/null || iptables -F LAB_FORWARD
iptables -N LAB_INPUT 2>/dev/null || iptables -F LAB_INPUT

# Allow established connections
iptables -A LAB_FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A LAB_INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow traffic within the lab network
iptables -A LAB_FORWARD -s $BRIDGE_NETWORK -d $BRIDGE_NETWORK -j ACCEPT
iptables -A LAB_INPUT -i $BRIDGE_NAME -s $BRIDGE_NETWORK -j ACCEPT

# Allow DNS and DHCP
iptables -A LAB_INPUT -i $BRIDGE_NAME -p udp --dport 53 -j ACCEPT
iptables -A LAB_INPUT -i $BRIDGE_NAME -p tcp --dport 53 -j ACCEPT
iptables -A LAB_INPUT -i $BRIDGE_NAME -p udp --dport 67:68 -j ACCEPT

# Block VLAN 99 from accessing other networks (isolation)
iptables -A LAB_FORWARD -i $VLAN_IFACE -j DROP

# Apply rules
iptables -I FORWARD -j LAB_FORWARD
iptables -I INPUT -j LAB_INPUT

# Setup dnsmasq for DHCP/DNS (if not already running)
if ! pgrep -x dnsmasq &> /dev/null; then
    echo "Starting dnsmasq for DHCP/DNS..."
    cat > /etc/dnsmasq.d/lab.conf <<EOF
# Zero-Trust Lab Configuration
interface=$BRIDGE_NAME
dhcp-range=192.168.99.10,192.168.99.250,12h
dhcp-option=option:router,192.168.99.1
dhcp-option=option:dns-server,192.168.99.1
no-resolv
server=8.8.8.8
server=8.8.4.4
bind-interfaces
EOF
    
    systemctl restart dnsmasq || dnsmasq -C /etc/dnsmasq.d/lab.conf &
fi

echo ""
echo "=== Network Configuration Complete ==="
echo "Bridge: $BRIDGE_NAME (${BRIDGE_IP})"
echo "VLAN 99: $VLAN_IFACE (isolation VLAN)"
echo "Network: $BRIDGE_NETWORK"
echo ""
echo "Network is ready for zero-trust router VM."
echo "Next step: Run 3_run_vm.sh to launch OpenWrt VM."
