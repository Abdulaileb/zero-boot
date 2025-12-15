#!/bin/bash
# Deploy zero-trust configuration to OpenWrt router
# This script copies the security configuration to the running router VM

set -e

echo "=== Zero-Trust Router: Deployment Script ==="

# Configuration
ROUTER_IP="${ROUTER_IP:-192.168.1.1}"
ROUTER_PORT="${ROUTER_PORT:-22}"
ROUTER_USER="${ROUTER_USER:-root}"
CONFIG_DIR="router_config"

# Check if configuration directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    echo "ERROR: Configuration directory '$CONFIG_DIR' not found!"
    exit 1
fi

# Function to check if router is reachable
check_router() {
    echo "Checking router connectivity..."
    if ping -c 1 -W 2 $ROUTER_IP &> /dev/null; then
        echo "✓ Router is reachable at $ROUTER_IP"
        return 0
    else
        echo "✗ Router is not reachable at $ROUTER_IP"
        return 1
    fi
}

# Function to copy files via SCP
copy_files() {
    local src=$1
    local dst=$2
    
    echo "Copying $src to router..."
    # WARNING: StrictHostKeyChecking=no disables host key verification
    # This is acceptable for lab environments but should not be used in production
    # For production use, properly manage SSH known_hosts file
    echo "  (Using relaxed SSH settings for lab environment)"
    scp -P $ROUTER_PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -r "$src" ${ROUTER_USER}@${ROUTER_IP}:"$dst" 2>&1 | grep -v "Warning: Permanently added"
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully copied $src"
        return 0
    else
        echo "✗ Failed to copy $src"
        return 1
    fi
}

# Function to execute command on router
exec_remote() {
    local cmd=$1
    
    # Using relaxed SSH settings for lab environment (not recommended for production)
    ssh -p $ROUTER_PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        ${ROUTER_USER}@${ROUTER_IP} "$cmd" 2>&1 | grep -v "Warning: Permanently added"
}

# Main deployment process
main() {
    echo ""
    echo "Router IP: $ROUTER_IP"
    echo "SSH Port: $ROUTER_PORT"
    echo "User: $ROUTER_USER"
    echo ""
    
    # Check connectivity
    if ! check_router; then
        echo ""
        echo "Router not reachable. Trying alternate IP..."
        ROUTER_IP="192.168.99.2"
        if ! check_router; then
            echo ""
            echo "Unable to connect to router. Please check:"
            echo "  1. Router VM is running (check with: ps aux | grep qemu)"
            echo "  2. Network bridge is configured (run: 2_setup_network.sh)"
            echo "  3. Router IP is correct (try: 192.168.1.1 or 192.168.99.2)"
            echo ""
            echo "To specify a different IP, run:"
            echo "  ROUTER_IP=<ip> ./deploy_to_router.sh"
            exit 1
        fi
    fi
    
    echo ""
    echo "=== Starting Deployment ==="
    echo ""
    
    # Create directories on router
    echo "Creating directories on router..."
    exec_remote "mkdir -p /etc/config.backup && mkdir -p /www_provision/cgi-bin"
    
    # Backup existing configuration
    echo "Backing up existing configuration..."
    exec_remote "cp /etc/rc.local /etc/config.backup/rc.local.bak 2>/dev/null || true"
    
    # Deploy rc.local (startup script with zero-trust lockdown)
    echo ""
    echo "Deploying zero-trust lockdown script..."
    copy_files "$CONFIG_DIR/etc/rc.local" "/etc/"
    exec_remote "chmod +x /etc/rc.local"
    
    # Deploy provisioning web interface
    echo ""
    echo "Deploying provisioning web interface..."
    copy_files "$CONFIG_DIR/www_provision/index.html" "/www_provision/"
    copy_files "$CONFIG_DIR/www_provision/cgi-bin/setup" "/www_provision/cgi-bin/"
    exec_remote "chmod +x /www_provision/cgi-bin/setup"
    
    # Configure web server to serve provisioning interface
    echo ""
    echo "Configuring web server..."
    exec_remote "uci set uhttpd.main.home='/www_provision' && uci commit uhttpd && /etc/init.d/uhttpd restart"
    
    # Make rc.local execute on next boot
    exec_remote "chmod +x /etc/rc.local"
    
    echo ""
    echo "=== Deployment Complete ==="
    echo ""
    echo "The zero-trust configuration has been deployed to the router."
    echo ""
    echo "Options:"
    echo "  1. Reboot router now to apply changes: "
    echo "     ssh -p $ROUTER_PORT ${ROUTER_USER}@${ROUTER_IP} 'reboot'"
    echo ""
    echo "  2. Or execute lockdown script manually:"
    echo "     ssh -p $ROUTER_PORT ${ROUTER_USER}@${ROUTER_IP} '/etc/rc.local'"
    echo ""
    echo "  3. Access provisioning interface:"
    echo "     http://${ROUTER_IP}:8080 (or https://${ROUTER_IP}:8443)"
    echo ""
    
    read -p "Would you like to reboot the router now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Rebooting router..."
        exec_remote "reboot" || true
        echo "Router is rebooting. Wait 30-60 seconds before reconnecting."
    else
        echo "Remember to reboot the router to apply all changes."
    fi
}

# Run main function
main

exit 0
