# zero-boot
A redesign on consumer routers to manage the risk they're posing

## Projects

### Zero-Trust Router Lab
A comprehensive security-focused networking lab that implements zero-trust principles through automated router lockdown using OpenWrt and QEMU.

**Location:** `zero-trust-router/`

**Features:**
- Automated router hardening with zero-trust security principles
- Virtualized OpenWrt environment using QEMU/KVM
- Network segmentation with VLAN 99 isolation zone
- Disabled insecure services (Telnet, UPnP, WPS)
- SSH hardening, DNSSEC, WPA2/WPA3 encryption
- Web-based provisioning interface
- Comprehensive security logging and monitoring

**Quick Start:**
```bash
cd zero-trust-router
sudo ./host_scripts/1_install_tools.sh
sudo ./host_scripts/2_setup_network.sh
sudo ./host_scripts/3_run_vm.sh
./deploy_to_router.sh
```

See [zero-trust-router/README.md](zero-trust-router/README.md) for detailed documentation.
