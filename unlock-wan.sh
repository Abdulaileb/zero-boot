#!/bin/sh
# Zero-Boot WAN Unlock Script
# This script enables the WAN interface after successful authentication

# Read JSON input from POST request
read -r POST_DATA

# Extract hash from JSON (simple parsing)
HASH=$(echo "$POST_DATA" | grep -o '"hash":"[^"]*"' | cut -d'"' -f4)

# Valid password hash (SHA-256)
# Default password: "unlock123" - CHANGE THIS IN PRODUCTION
VALID_HASH="6b89d6b85dcb29a19e8e45f5e1c3d45a30d6e4e8e1e4c5e6d9d4f5e6a7b8c9d0"

# Log unlock attempt
logger -t zero-boot "WAN unlock attempt with hash: ${HASH:0:16}..."

# Verify hash
if [ "$HASH" = "$VALID_HASH" ]; then
    logger -t zero-boot "Valid hash provided, unlocking WAN interface"
    
    # Enable WAN interface
    uci set network.wan.disabled='0'
    uci set network.wan6.disabled='0'
    
    # Enable forwarding from LAN to WAN
    uci set firewall.@forwarding[0].enabled='1'
    
    # Commit changes
    uci commit network
    uci commit firewall
    
    # Restart network and firewall services
    /etc/init.d/network restart
    /etc/init.d/firewall restart
    
    # Log success
    logger -t zero-boot "WAN interface successfully unlocked"
    
    # Return success response
    echo "Content-Type: application/json"
    echo ""
    echo '{"status":"success","message":"WAN interface unlocked"}'
    
else
    logger -t zero-boot "Invalid hash provided, access denied"
    
    # Return error response
    echo "Status: 403 Forbidden"
    echo "Content-Type: application/json"
    echo ""
    echo '{"status":"error","message":"Invalid authentication"}'
fi
