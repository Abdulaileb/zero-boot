#!/bin/bash
# Install QEMU and bridge utilities for zero-trust router lab
# This script prepares the host system to run OpenWrt VMs

set -e

echo "=== Zero-Trust Router Lab: Installing Tools ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Detect package manager
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt-get"
    UPDATE_CMD="apt-get update"
    INSTALL_CMD="apt-get install -y"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    UPDATE_CMD="dnf check-update || true"
    INSTALL_CMD="dnf install -y"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    UPDATE_CMD="yum check-update || true"
    INSTALL_CMD="yum install -y"
else
    echo "Unsupported package manager. Please install packages manually."
    exit 1
fi

echo "Using package manager: $PKG_MANAGER"

# Update package lists
echo "Updating package lists..."
$UPDATE_CMD

# Install QEMU and KVM
echo "Installing QEMU and virtualization tools..."
if [ "$PKG_MANAGER" = "apt-get" ]; then
    $INSTALL_CMD qemu-system-x86 qemu-utils qemu-kvm libvirt-daemon-system
elif [ "$PKG_MANAGER" = "dnf" ] || [ "$PKG_MANAGER" = "yum" ]; then
    $INSTALL_CMD qemu-kvm qemu-img libvirt virt-install
fi

# Install bridge utilities
echo "Installing network bridge utilities..."
if [ "$PKG_MANAGER" = "apt-get" ]; then
    $INSTALL_CMD bridge-utils vlan iproute2 iptables
elif [ "$PKG_MANAGER" = "dnf" ] || [ "$PKG_MANAGER" = "yum" ]; then
    $INSTALL_CMD bridge-utils iproute iptables
fi

# Install additional networking tools
echo "Installing additional networking tools..."
$INSTALL_CMD wget curl tcpdump dnsmasq

# Verify installations
echo ""
echo "=== Verification ==="
qemu-system-x86_64 --version | head -n1
brctl --version 2>&1 | head -n1 || echo "brctl: installed"
ip -V
iptables --version

# Enable and start libvirt if available
if command -v systemctl &> /dev/null && systemctl list-unit-files | grep -q libvirtd; then
    echo "Enabling libvirt service..."
    systemctl enable libvirtd
    systemctl start libvirtd || true
fi

echo ""
echo "=== Installation Complete ==="
echo "QEMU and bridge utilities are now installed."
echo "Next step: Run 2_setup_network.sh to configure the network."
