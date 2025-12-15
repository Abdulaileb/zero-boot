# Zero-Boot 🛡️

A security-focused router configuration system that implements automatic lockdown to manage and mitigate risks posed by consumer routers.

## Overview

Zero-Boot redesigns consumer router behavior by implementing a **security-first approach**:

- **🔒 Automatic Lockdown**: Router boots with WAN disabled by default
- **🌐 Trap Interface**: Web-based unlock mechanism with password hash verification  
- **🛡️ Network Isolation**: VLAN segmentation for enhanced security
- **🚀 Automated Deployment**: Single script to push configuration to router

## Why Zero-Boot?

Consumer routers are often the weakest link in home network security. Zero-Boot addresses this by:

1. **Preventing unauthorized access**: WAN is disabled until explicitly unlocked
2. **Reducing attack surface**: Network isolation via VLANs limits lateral movement
3. **Requiring authentication**: Secure password-based unlock mechanism
4. **Easy deployment**: Automated script handles all configuration

## Quick Start

```bash
# Clone repository
git clone https://github.com/Abdulaileb/zero-boot.git
cd zero-boot

# Generate secure password hash
chmod +x deploy.sh
./deploy.sh --generate-hash "your-secure-password"

# Update password hash in trap-interface.html and unlock-wan.sh
# Then deploy to your router
./deploy.sh --router-ip 192.168.1.1 --user root
```

After deployment:
1. Open `http://192.168.1.1` in your browser
2. Enter your password to unlock WAN
3. Internet access will be enabled

## Architecture

### Security Layers

```
┌─────────────────────────────────────┐
│     Trap Interface (Web UI)         │
│   Password Hash Authentication      │
├─────────────────────────────────────┤
│      Network Segmentation           │
│   VLANs: Management, Guest, Quarantine │
├─────────────────────────────────────┤
│       WAN Lockdown                  │
│   Disabled by Default on Boot       │
└─────────────────────────────────────┘
```

### Components

- **router-config.uci**: OpenWrt configuration with WAN disabled and VLAN setup
- **trap-interface.html**: Modern web UI for authentication
- **unlock-wan.sh**: CGI script for WAN unlock
- **deploy.sh**: Automated deployment tool

## Features

### Automatic Lockdown
Router boots with WAN interface completely disabled, preventing any outbound internet access until authenticated.

### Trap Interface  
Clean, modern web interface that:
- Uses SHA-256 password hashing
- Provides real-time feedback
- Logs all authentication attempts
- Auto-redirects after successful unlock

### Network Isolation
VLAN configuration with three zones:
- **VLAN 1**: Management network (secure)
- **VLAN 10**: Guest network (isolated)  
- **VLAN 99**: Quarantine zone (restricted)

### Automated Deployment
Single command deployment with:
- Prerequisite checking
- Automatic backups
- Configuration validation
- Service restart

## Documentation

- **[Setup Guide](SETUP.md)**: Comprehensive setup and configuration instructions
- **[Security Guide](SECURITY.md)**: Security best practices and threat model
- **[Architecture](ARCHITECTURE.md)**: Detailed technical architecture

## Requirements

### Router
- OpenWrt or LEDE firmware
- Minimum 8MB flash
- SSH access enabled
- uhttpd web server

### Client
- SSH/SCP client
- Bash shell
- Network access to router

## Security Considerations

⚠️ **IMPORTANT**: This is a defense-in-depth security measure, not a complete security solution.

- Change the default password immediately
- Use strong, unique passwords (16+ characters)
- Keep OpenWrt firmware updated  
- Monitor unlock logs regularly
- Consider additional security layers (VPN, IDS, etc.)

## Contributing

Contributions welcome! Please read our contributing guidelines and submit pull requests.

## License

See [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/Abdulaileb/zero-boot/issues)
- **Documentation**: [Wiki](https://github.com/Abdulaileb/zero-boot/wiki)

## Disclaimer

This software is provided as-is for educational and security research purposes. Always test in a safe environment before production deployment. The authors are not responsible for any misuse or damage. 
