# KANT - Klipper Assistant Navigation and Troubleshooting (WIP)

"You can't? KANT can"

A comprehensive utility to assist with Klipper 3D printer configuration and setup. KANT provides an interactive menu-driven interface to help you configure your printer quickly and correctly.

Please keep in mind this is work in progress. Please make sure to post issues. 

## Version 1.3.0

**Last Updated:** 2025-10-12
**Author:** ss1gohan13

## Features Overview

KANT has evolved into a comprehensive interactive menu system with 7 main categories:

### 🔧 **1. Install Klipper Macros**
- **Standard Klipper Macros** - Complete macro suite with web interface configuration
- **A Better Print_Start Macro** - Advanced start sequence with KAMP integration
- **A Better End Print Macro** - Enhanced end print functionality

### ⚙️ **2. Hardware Configuration Utilities**
- **MCU ID Management** - Detect, configure, and update MCU serial IDs and CAN bus UUIDs
- **CAN Bus Support** - Complete CAN bus device scanning and configuration
- **Official Klipper Configurations** - Browse and download official example configs
- **Stepper Driver Configuration** - Complete stepper motor and TMC driver setup
- **Firmware Retraction** - Add firmware retraction support
- **Force Move Configuration** - Enable manual motor movement
- **Eddy NG Integration** - Enable tap functionality and rapid bed mesh scanning

### 🚀 **3. Additional Features & Extensions**
- **KAMP Installation** - Klipper Adaptive Meshing and Purging
- **Numpy for ADXL** - Install numpy for input shaping measurements
- **Crowsnest** - Webcam streaming solution
- **Moonraker-Timelapse** - Timelapse functionality
- **PID Tuning Assistant** - Guided hotend PID calibration
- **E-Steps Calibration Helper** - Step-by-step extruder calibration

### 💾 **4. Backup Management**
- **List All Backups** - View all configuration backups with details
- **Restore from Backup** - Select and restore any previous configuration
- **Clean Old Backups** - Remove backups older than specified days

### 🔍 **5. Diagnostics & Troubleshooting**
- **Klipper Status Check** - Service status and health monitoring
- **Log Viewer** - View recent logs and filter for errors
- **Configuration Verification** - Validate setup and includes
- **Full System Diagnostics** - Comprehensive system health check

### 📦 **6. Software Management**
Organized into specialized subcategories:

- #### **Core Software**
  - Kiauh installation and management
  - System updates

- #### **LED & Visual Effects**
  - Klipper LED Effects installation/management
  - Status monitoring

- #### **Input Shaping & Analysis**
  - Shake&Tune installation for advanced resonance analysis
  - ADXL345 support

- #### **Driver & Hardware Tuning**
  - TMC Autotune for optimal stepper performance
  - Hardware optimization

- #### **Touchscreen Interface**
  - KlipperScreen installation and configuration
  - Touch interface management

- #### **Probe Systems**
  - Beacon probe support
  - Cartographer probe integration
  - Eddy-NG probe system
  - Multi-probe compatibility

- #### **Calibration Tools**
  - Auto Z Calibration
  - Advanced calibration utilities

- #### **CANBUS**
  - **Guided CANBUS Setup** - Partial automated setup process
  - Kernel compatibility checking
  - Network service configuration
  - Advanced troubleshooting options

### 🗑️ **7. Uninstall**
- Safe removal with configuration restoration
- Automatic backup before uninstall

## Installation

### Quick Start
```bash
git clone https://github.com/ss1gohan13/KANT.git
cd KANT
./installer.sh
```

### Command Line Options
```bash
./installer.sh [OPTIONS]

Options:
  -c <path>    Specify custom config path (default: ~/printer_data/config)
  -s <name>    Specify Klipper service name (default: klipper)
  -u           Uninstall mode
  -l           Linear mode (skip interactive menu)
  -h           Show help message
```

## Usage

### Interactive Menu Mode (Default)

When you run `./installer.sh`, you'll see the main menu:

```
===============================================================================
    Klipper Assistant Navigation and Troubleshooting (KANT) v1.3.0
===============================================================================

MAIN MENU
1) Install Klipper Macros
2) Hardware Configuration Utilities  
3) Additional Features & Extensions
4) Backup Management
5) Diagnostics & Troubleshooting
6) Software Management
7) Uninstall
0) Exit
```

### Key Features Explained

#### **Enhanced MCU Configuration**
- Automatically detects serial, USB, and CAN bus MCUs
- Shows currently configured MCUs in printer.cfg
- Supports multiple MCU configurations
- Safe backup before any changes

#### **Comprehensive Stepper Configuration**
- Visual position calculation assistance
- Endstop and homing configuration
- Complete TMC driver setup
- Safety validation and confirmation

#### **Advanced CAN Bus Setup**
- Automated system compatibility checking  
- Network service configuration
- Hardware verification guidance
- Advanced troubleshooting options
- TX queue length optimization

#### **Eddy NG Integration**
- Automatic tapping functionality
- Rapid bed mesh scanning (Method=rapid_scan)
- Enhanced gantry leveling with retry tolerance
- Fine adjustment passes for precision

## Configuration Files

KANT works with your Klipper configuration directory:

- **printer.cfg** - Main configuration (updated by KANT)
- **macros.cfg** - Macro definitions
- **backup/** - Automatic configuration backups
- **KAMP/** - Adaptive meshing configuration (if installed)

## Macro Suite

KANT includes a comprehensive macro collection:

### **Essential Macros**
- **START_PRINT** - Comprehensive start sequence with bed leveling and purge line
- **END_PRINT** - Safe end sequence with part presentation  
- **PAUSE/RESUME/CANCEL_PRINT** - Print control with state management
- **LOAD_FILAMENT/UNLOAD_FILAMENT** - Automated filament handling

### **Advanced Macros**
- **GANTRY_LEVELING** - Enhanced QGL/Z_TILT with Eddy NG support
- **BED_MESH_CALIBRATE** - Adaptive meshing with KAMP integration
- **G29** - Bed mesh alias with rapid scanning support

## Hardware Compatibility

### **Supported MCUs**
- Serial MCUs (USB connection)
- CAN bus MCUs with UUID detection
- Multiple MCU configurations
- Automatic ID detection and configuration

### **Probe Systems**
- Beacon probes
- Cartographer probes  
- Eddy NG probes
- Traditional endstops and BLTouch

### **Stepper Drivers**
- TMC2209/TMC2226 with UART
- Complete driver configuration
- StealthChop and SpreadCycle support
- Sensorless homing support

## Advanced Features

### **Backup System**
- Automatic timestamped backups before any changes
- Selective restore capabilities
- Backup cleanup with configurable retention
- Multiple file type support

### **Software Management**
- Modular plugin installation system
- Status monitoring for all components
- Safe installation/removal procedures
- Dependency management

### **Diagnostics**
- Real-time service monitoring
- Log analysis and error detection
- Configuration validation
- System health reporting

## Safety Features

- **Automatic Backups** - Created before any configuration changes
- **Confirmation Prompts** - User confirmation for destructive operations
- **Service Management** - Safe Klipper stop/start procedures
- **Rollback Capability** - Easy restoration of previous configurations
- **Non-destructive Operations** - Original configs preserved

## Requirements

- Klipper 3D printer firmware installed
- Bash shell (Linux/Unix environment)
- Basic command-line tools: `grep`, `sed`, `tar`, `curl`
- Optional: `iproute2` package for CAN bus support
- Optional: Git for additional component installations

## Troubleshooting

### **Common Issues**

#### **No MCU devices found**
- Ensure MCU is connected via USB
- Check permissions to access `/dev/serial/by-id/`
- Try running with `sudo` if needed

#### **CAN interface not found**
- Verify CAN kernel modules: `lsmod | grep can`
- Check interface status: `ip link show can0`
- Install required tools: `sudo apt-get install iproute2`

#### **Macro not working**
- Verify include in printer.cfg: `[include macros.cfg]`
- Check for syntax errors: `RESTART` in Klipper console
- Review Klipper logs for error details

#### **Service Issues**
- Check Klipper service: `sudo systemctl status klipper`
- Review logs: `sudo journalctl -u klipper -n 50`
- Verify configuration syntax

### **Diagnostic Commands**

Use KANT's built-in diagnostics (Menu → 5) or run these manually:

```bash
# Check service status
sudo systemctl status klipper

# View recent logs  
sudo journalctl -u klipper -n 50

# Verify configuration
klippy ~/printer_data/config/printer.cfg

# Check disk space
df -h /

# View system info
uname -a
```

## File Structure

```
KANT/
├── installer.sh         # Main installer and menu system
├── README.md            # This documentation
└── LICENSE              # GPL v3.0 License
```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

### **Development Guidelines**
- Follow existing code style and structure
- Test changes thoroughly before submitting
- Update documentation for new features
- Maintain backward compatibility where possible

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Support & Community

- **Issues & Questions**: [GitHub Issues](https://github.com/ss1gohan13/KANT/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/ss1gohan13/KANT/discussions)
- **Documentation**: This README and inline help

## Changelog

### **Version 1.3.0**
- ##Public release
- gramical/spelling corrections/updates on github

### **Version 1.2.0**
- Complete interactive menu system
- Enhanced hardware configuration tools
- Comprehensive software management
- Advanced CAN bus setup with guided configuration
- Improved backup and restore functionality
- Full diagnostic suite
- Modular plugin architecture
- Enhanced Eddy NG integration
- Stepper configuration wizard
- Official Klipper config browser

### **Previous Versions**
- v1.1.x: Basic macro installation and configuration
- v1.0.x: Initial release with core functionality

---

**Note**: KANT modifies your Klipper configuration files. While it creates automatic backups, always ensure you have additional backups of your working configuration before making changes.

## Quick Reference

### **Most Common Tasks**
1. **Install Basic Macros**: Menu → 1 → 1
2. **Configure MCU**: Menu → 2 → 1  
3. **Check System Health**: Menu → 5 → 4
4. **Install Print Start Macro**: Menu → 1 → 2
5. **Setup CAN Bus**: Menu → 6 → 8 → 1
6. **Backup Configuration**: Menu → 4 → 1

For detailed instructions on any feature, navigate through the interactive menu system or refer to the relevant section in this documentation.
