#!/bin/bash
# Launch OpenWrt VM for zero-trust router lab
# This script starts the router VM with proper network configuration

set -e

echo "=== Zero-Trust Router Lab: Launching OpenWrt VM ==="

# Configuration
BRIDGE_NAME="br-lab"
VM_NAME="zero-trust-router"
VM_MEMORY="512"
VM_CORES="2"
OPENWRT_IMG="openwrt-x86-64-generic-ext4-combined.img"
OPENWRT_URL="https://downloads.openwrt.org/releases/23.05.2/targets/x86/64/openwrt-23.05.2-x86-64-generic-ext4-combined.img.gz"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Check if bridge exists
if ! ip link show $BRIDGE_NAME &> /dev/null; then
    echo "ERROR: Bridge $BRIDGE_NAME not found!"
    echo "Please run 2_setup_network.sh first."
    exit 1
fi

# Download OpenWrt image if not present
if [ ! -f "$OPENWRT_IMG" ]; then
    echo "OpenWrt image not found. Downloading..."
    wget -O openwrt.img.gz "$OPENWRT_URL"
    gunzip openwrt.img.gz
    mv openwrt.img "$OPENWRT_IMG"
    echo "OpenWrt image downloaded and extracted."
fi

# Convert to qcow2 for better performance (if not already done)
QCOW2_IMG="${OPENWRT_IMG%.img}.qcow2"
if [ ! -f "$QCOW2_IMG" ]; then
    echo "Converting image to qcow2 format..."
    qemu-img convert -f raw -O qcow2 "$OPENWRT_IMG" "$QCOW2_IMG"
    qemu-img resize "$QCOW2_IMG" 1G
fi

# Create TAP interface for VM
TAP_IFACE="tap-${VM_NAME}"
if ! ip link show $TAP_IFACE &> /dev/null; then
    echo "Creating TAP interface: $TAP_IFACE"
    # When running as root, omit the user parameter for better compatibility
    ip tuntap add dev $TAP_IFACE mode tap
    ip link set $TAP_IFACE up
    brctl addif $BRIDGE_NAME $TAP_IFACE
fi

# Check if VM is already running
if pgrep -f "qemu.*$QCOW2_IMG" &> /dev/null; then
    echo "VM appears to be already running!"
    echo "Process:"
    pgrep -af "qemu.*$QCOW2_IMG"
    read -p "Kill existing VM and restart? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pkill -f "qemu.*$QCOW2_IMG"
        sleep 2
    else
        echo "Exiting. VM is already running."
        exit 0
    fi
fi

# Launch VM
echo "Starting OpenWrt VM..."
echo "VM Name: $VM_NAME"
echo "Memory: ${VM_MEMORY}MB"
echo "Cores: $VM_CORES"
echo "Network: $TAP_IFACE -> $BRIDGE_NAME"
echo ""

# Create log directory
mkdir -p logs

# Start QEMU with proper network configuration
qemu-system-x86_64 \
    -name "$VM_NAME" \
    -m "$VM_MEMORY" \
    -smp "$VM_CORES" \
    -drive file="$QCOW2_IMG",if=virtio \
    -netdev tap,id=lan,ifname=$TAP_IFACE,script=no,downscript=no \
    -device virtio-net-pci,netdev=lan,mac=52:54:00:12:34:56 \
    -nographic \
    -serial mon:stdio \
    2>&1 | tee logs/vm-${VM_NAME}.log &

VM_PID=$!
echo "VM started with PID: $VM_PID"
echo ""
echo "=== Connection Information ==="
echo "Router IP: 192.168.99.2 (will be assigned via DHCP)"
echo "Or use default OpenWrt: 192.168.1.1"
echo ""
echo "To connect to VM console: screen /dev/pts/X (check with 'ps aux | grep qemu')"
echo "To stop VM: kill $VM_PID"
echo ""
echo "After VM boots, deploy zero-trust configuration with: ./deploy_to_router.sh"
echo ""
echo "=== VM Log ==="
echo "Logs are being written to: logs/vm-${VM_NAME}.log"
echo "VM is running in background. Use 'fg' to bring to foreground."
