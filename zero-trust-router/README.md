# Zero-Trust Router Lab

A security-focused networking lab that implements zero-trust principles through automated router lockdown using OpenWrt and QEMU.

## 🔒 Zero-Trust Security Features

This lab implements comprehensive security measures based on zero-trust principles:

### Network Security
- **Default Deny Policy**: All traffic is blocked by default; only explicitly allowed connections are permitted
- **VLAN 99 Isolation**: Dedicated isolation VLAN for quarantined/untrusted devices
- **Micro-segmentation**: Network traffic is strictly controlled between zones
- **Rate Limiting**: Protection against DDoS and flood attacks

### Service Hardening
- **Telnet Disabled**: Removed insecure remote access protocol
- **UPnP Disabled**: Eliminated automatic port forwarding vulnerability
- **WPS Disabled**: Removed WiFi Protected Setup security risk
- **SSH Hardening**: Non-standard port (2222), key-based authentication only
- **Web Interface**: HTTPS-only on non-standard ports (8080/8443)

### Protocol Security
- **DNSSEC Enabled**: DNS response validation
- **Secure DNS**: Cloudflare DNS (1.1.1.1) with fallback
- **IPv6 Disabled**: Reduced attack surface (optional)
- **Source Routing Disabled**: Prevents routing manipulation
- **ICMP Rate Limiting**: Controlled ping responses

### Access Control
- **MAC Filtering Framework**: Optional MAC address whitelisting
- **Password Requirements**: Enforced strong passwords (12+ chars for admin, 16+ for WiFi)
- **Encryption**: WPA2/WPA3 for wireless with CCMP/SAE

### Monitoring & Logging
- **Comprehensive Logging**: All security events logged
- **Remote Syslog**: Centralized log collection
- **Dropped Packet Logging**: Rate-limited security event tracking

## 📁 Project Structure

```
zero-trust-router/
├── host_scripts/
│   ├── 1_install_tools.sh      # Install QEMU, bridge utilities
│   ├── 2_setup_network.sh      # Configure LAN bridge and VLAN 99
│   └── 3_run_vm.sh             # Launch OpenWrt VM
├── router_config/
│   ├── etc/
│   │   └── rc.local            # Automated lockdown script
│   └── www_provision/
│       ├── index.html          # Setup web interface
│       └── cgi-bin/
│           └── setup           # Configuration CGI script
├── deploy_to_router.sh         # Deploy configuration to router
└── README.md                   # This file
```

## 🚀 Quick Start

### Prerequisites
- Linux host system (Ubuntu 20.04+ recommended)
- Sudo/root access
- At least 2GB free RAM
- 10GB free disk space

### Step 1: Install Tools
Install QEMU, KVM, and networking utilities:

```bash
cd zero-trust-router
sudo ./host_scripts/1_install_tools.sh
```

This installs:
- QEMU/KVM for virtualization
- Bridge utilities for network configuration
- Additional tools (wget, curl, tcpdump, dnsmasq)

### Step 2: Setup Network
Configure the host network with bridge and VLAN:

```bash
sudo ./host_scripts/2_setup_network.sh
```

This creates:
- Bridge interface `br-lab` (192.168.99.1/24)
- VLAN 99 for isolation (`br-lab.99`)
- Firewall rules for network segmentation
- DHCP/DNS services via dnsmasq

### Step 3: Launch Router VM
Start the OpenWrt virtual router:

```bash
sudo ./host_scripts/3_run_vm.sh
```

This will:
- Download OpenWrt image (if not present)
- Convert to qcow2 format
- Create TAP interface
- Launch QEMU VM with proper networking

The VM runs in the background. Connection info:
- Default OpenWrt IP: `192.168.1.1`
- Or DHCP assigned: `192.168.99.x`

### Step 4: Deploy Zero-Trust Configuration
Deploy the security configuration to the router:

```bash
./deploy_to_router.sh
```

Or specify custom router IP:
```bash
ROUTER_IP=192.168.1.1 ./deploy_to_router.sh
```

The script will:
1. Copy security scripts to router
2. Deploy web provisioning interface
3. Offer to reboot router

### Step 5: Complete Setup via Web Interface
After deployment, access the provisioning interface:

```
http://192.168.1.1:8080
```

Configure:
- Admin password (minimum 12 characters)
- WiFi SSID and password (minimum 16 characters)
- Trusted device MAC addresses
- Security level (Maximum/High/Medium)

## 🎯 Usage Scenarios

### 1. Security Research & Training
Use the lab to:
- Study zero-trust networking principles
- Test firewall configurations
- Practice incident response
- Learn OpenWrt security features

### 2. Network Segmentation Testing
Experiment with:
- VLAN isolation
- Traffic filtering
- Zone-based security
- Micro-segmentation

### 3. IoT Device Quarantine
- Place untrusted IoT devices in VLAN 99
- Test device behavior in isolation
- Analyze network traffic patterns
- Implement selective access controls

### 4. Router Hardening Education
Learn how to:
- Disable insecure services
- Configure secure protocols
- Implement defense-in-depth
- Monitor security events

## 🔧 Advanced Configuration

### Custom Security Levels

Edit `/etc/rc.local` on the router to customize security rules:

**Maximum Security** (Default):
- MAC filtering enabled
- Strict firewall rules
- All services locked down
- Isolation VLAN enforced

**High Security**:
- Standard zero-trust configuration
- Key-based SSH only
- Secure protocols enforced
- Logging enabled

**Medium Security**:
- Balanced approach
- Some convenience features enabled
- Basic protection maintained

### Manual Lockdown Execution

SSH to router and execute:
```bash
ssh -p 2222 root@192.168.1.1
/etc/rc.local
```

### Adding Trusted Devices

Via web interface or manually:
```bash
ssh -p 2222 root@192.168.1.1
echo "AA:BB:CC:DD:EE:FF" >> /etc/mac_whitelist
uci add firewall rule
uci set firewall.@rule[-1].name="Allow_Device"
uci set firewall.@rule[-1].src_mac="AA:BB:CC:DD:EE:FF"
uci set firewall.@rule[-1].target="ACCEPT"
uci commit firewall
/etc/init.d/firewall restart
```

### Monitoring Logs

View security logs:
```bash
ssh -p 2222 root@192.168.1.1
cat /var/log/zero-trust-lockdown.log
logread | grep -i drop
```

## 🧪 Testing & Verification

### Verify Security Features

```bash
# Check disabled services
ssh -p 2222 root@192.168.1.1 "ps | grep -E '(telnet|upnp)'"

# Verify firewall rules
ssh -p 2222 root@192.168.1.1 "iptables -L -n -v"

# Check VLAN configuration
ssh -p 2222 root@192.168.1.1 "ip link show"

# Test isolation VLAN
# From isolated device, try to ping other networks (should fail)
```

### Security Audit

```bash
# Check for default passwords
# Verify encryption settings
# Review firewall logs
# Test external access (should be blocked)
```

## 🛡️ Security Best Practices

1. **Change Default Passwords**: Always use strong, unique passwords
2. **Enable Key-Based SSH**: Disable password authentication
3. **Regular Updates**: Keep OpenWrt and packages updated
4. **Monitor Logs**: Review security logs regularly
5. **Limit Access**: Use MAC filtering and VLANs
6. **Backup Configuration**: Save working configurations
7. **Test Changes**: Verify security measures after changes

## 📊 Network Topology

```
┌─────────────────────────────────────────────────┐
│ Host System                                      │
│                                                  │
│  ┌────────────────────────────────────────┐    │
│  │ br-lab Bridge (192.168.99.1/24)        │    │
│  │                                         │    │
│  │  ├─ tap-zero-trust-router              │    │
│  │  └─ br-lab.99 (VLAN 99 - Isolation)    │    │
│  └──────────────┬──────────────────────────┘    │
│                 │                               │
│  ┌──────────────▼──────────────────────────┐    │
│  │ QEMU VM - OpenWrt Router               │    │
│  │                                         │    │
│  │  LAN: 192.168.1.1/24                   │    │
│  │  Isolation: VLAN 99                    │    │
│  │                                         │    │
│  │  Services:                              │    │
│  │  - SSH (port 2222)                     │    │
│  │  - HTTPS (port 8443)                   │    │
│  │  - DHCP/DNS                            │    │
│  └─────────────────────────────────────────┘    │
│                                                  │
└─────────────────────────────────────────────────┘
```

## 🐛 Troubleshooting

### Router VM Won't Start
- Check if KVM is enabled: `lsmod | grep kvm`
- Verify bridge exists: `ip link show br-lab`
- Check for port conflicts: `netstat -tlnp | grep 192.168.99.1`

### Can't Connect to Router
- Verify VM is running: `ps aux | grep qemu`
- Check router IP: Try both `192.168.1.1` and `192.168.99.2`
- Test connectivity: `ping 192.168.1.1`
- Check firewall: `iptables -L -n`

### Deployment Fails
- Verify SSH access: `ssh -p 22 root@192.168.1.1`
- Check network connectivity to router
- Ensure router has enough space: `df -h`

### Web Interface Not Accessible
- Check uhttpd service: `ssh -p 2222 root@192.168.1.1 "/etc/init.d/uhttpd status"`
- Verify port: Try both HTTP (8080) and HTTPS (8443)
- Check firewall rules

## 📚 Learning Resources

- [OpenWrt Documentation](https://openwrt.org/docs/start)
- [Zero Trust Architecture (NIST)](https://www.nist.gov/publications/zero-trust-architecture)
- [Network Segmentation Best Practices](https://www.cisecurity.org/)
- [QEMU Network Configuration](https://wiki.qemu.org/Documentation/Networking)

## 🤝 Contributing

This is an educational lab environment. Contributions are welcome:
- Enhanced security features
- Additional test scenarios
- Documentation improvements
- Bug fixes

## ⚠️ Disclaimer

This lab is for **educational and research purposes only**. 
- Do not deploy to production networks without proper testing
- Always have backup access to your systems
- Test in isolated environments first
- Understand the security implications of all changes

## 📄 License

See LICENSE file in the repository root.

## 🔗 Related Projects

- [OpenWrt](https://openwrt.org/) - Linux-based router firmware
- [QEMU](https://www.qemu.org/) - Hardware virtualization
- [Zero-Boot](https://github.com/Abdulaileb/zero-boot) - Parent project

---

**Built for cybersecurity education and zero-trust networking research.**
